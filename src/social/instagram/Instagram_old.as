package social.instagram 
{
	import flash.display.Stage;
	import flash.media.StageWebView;
	
	import org.osflash.signals.Signal;
	
	import social.auth.oauth2.OAuth2;
	import social.auth.TokenSaver;
	import social.core.UrlProvider;
	import social.core.PlatformState;
	import social.gateway.jsonRest.JsonRest;
	import social.util.StateObject;
	import social.util.closure;
	import social.vo.Location;
	import social.vo.Photo;
	import social.vo.PhotoSize;
	import social.vo.Tag;
	import social.vo.User;
	
	/**
	 * ...
	 * @author pbordachar
	 */
	
	public class Instagram_old
	{
		
		private static const URL_CLIENT_ID				:String		= "${clientId}";
		private static const URL_REDIRECT_URL			:String		= "${redirectUrl}";
		private static const URL_PERMISSIONS			:String		= "${permissions}";
		
		/*public static const PlatformState.STATE_UNAUTHENTICATED		:String		= "stateUnauthenticated";
		public static const PlatformState.STATE_AUTHENTICATING		:String		= "stateAuthenticating";
		public static const PlatformState.STATE_AUTHENTICATED			:String		= "stateAuthenticated";*/
		
		protected static const API_URL:String = "https://api.instagram.com/v1/";
		
		public function get stateChanged():Signal{
			return _stateObj.stateChanged;
		}
		public function get state():String{
			return _stateObj.state;
		}
		
		public function get manageSession():Boolean{
			return _manageSession;
		}
		public function set manageSession(value:Boolean):void{
			if(_manageSession == value)return;
			_manageSession = value;
			if(_manageSession){
				if(!_tokenSaver)_tokenSaver = new TokenSaver("instagram", _oauth);
				_tokenSaver.active = true;
			}else{
				_tokenSaver.active = false;
			}
		}
		
		public function get accessToken():String{
			return _oauth.accessToken;
		}
		public function set accessToken(value:String):void{
			_oauth.accessToken = value;
		}
		
		public function get pendingAuth():Boolean{
			return _oauth.pendingAuth;
		}
		
		private var _oauth:OAuth2;
		private var _jsonRest:JsonRest;
		private var _oauthUrl:UrlProvider;
		private var _callUrl:UrlProvider;
		private var _logoutUrl:UrlProvider;
		private var _stateObj:StateObject;
		private var _manageSession:Boolean;
		private var _tokenSaver:TokenSaver;
		
		private var _onUser:Function;
		private var _onUsers:Function;
		private var _onPhoto:Function;
		private var _onPhotos:Function;
		private var _onLocation:Function;
		private var _onLocations:Function;
		private var _onTag:Function;
		private var _onTags:Function;
		
		public function Instagram_old() {
			
			var parseUser:Function = JsonRest.createParser(User, null,
				{"id":"id", "profile_picture":"photo", "full_name":"fullName", "username":"userName"});
			
			var parsePhotoSize:Function = JsonRest.createParser(PhotoSize, null,
				{"url":"url", "width":"width", "height":"height"});
			var parsePhotoSizes:Function = JsonRest.createArrParser(parsePhotoSize);
			
			var parseLocation:Function = JsonRest.createParser(Location, null,
				{"id":"id", "longitude":"longitude", "latitude":"latitude", "name":"name"});
			
			var parseTag:Function = JsonRest.createParser(Tag, null,
				{"name":"name", "media_count":"count"});
			var parseTags:Function = JsonRest.createArrParser(parseTag);
			
			var parsePhoto:Function = JsonRest.createParser(Photo, {"images":parsePhotoSizes, "user":parseUser, "location":parseLocation},
				{"id":"id", "type":"type", "images":"sizes", "created_time":"creation", "likes":"likes", "user":"user", "location":"location", "tags":"tags"});
			
			_onUser = JsonRest.createHandler(parseUser);
			_onUsers = JsonRest.createHandler(JsonRest.createArrParser(parseUser));
			_onPhoto = JsonRest.createHandler(parsePhoto);
			_onPhotos = JsonRest.createHandler(JsonRest.createArrParser(parsePhoto));
			_onLocation = JsonRest.createHandler(parseLocation);
			_onLocations = JsonRest.createHandler(JsonRest.createArrParser(parseLocation));
			_onTag = JsonRest.createHandler(parseTag);
			_onTags = JsonRest.createHandler(parseTags);
			
			_stateObj = new StateObject([PlatformState.STATE_UNAUTHENTICATED, PlatformState.STATE_AUTHENTICATING, PlatformState.STATE_AUTHENTICATED], PlatformState.STATE_UNAUTHENTICATED);
			
			_oauthUrl = new UrlProvider(true, "https://api.instagram.com/oauth/authorize/?client_id="+URL_CLIENT_ID+"&redirect_uri="+URL_REDIRECT_URL+"&response_type=token&scope="+URL_PERMISSIONS+"");
			_oauthUrl.setupArrayToken(URL_PERMISSIONS, "+", ["basic","comments","relationships","likes"]);
			_oauthUrl.setToken(URL_CLIENT_ID, "");
			_oauthUrl.setToken(URL_REDIRECT_URL, "");
			
			_callUrl = new UrlProvider(true, API_URL+JsonRest.URL_ENDPOINT+"?access_token="+OAuth2.URL_ACCESS_TOKEN);
			
			_logoutUrl = new UrlProvider(true, "https://instagram.com/"+JsonRest.URL_ENDPOINT);
			
			_oauth = new OAuth2(checkAuthUrl, "access_token");
			_oauth.accessTokenChanged.add(onTokenChanged);
			manageSession = true;
			
			_jsonRest = new JsonRest(_oauth);
			
		}
		
		private function onTokenChanged():void
		{
			if(_oauth.accessToken){
				_stateObj.state = PlatformState.STATE_AUTHENTICATED;
			}else{
				_stateObj.state = PlatformState.STATE_UNAUTHENTICATED;
			}
			
		}
		
		private function onLogout(success:String, fail:*, onComplete:Function):void
		{
			_stateObj.state = PlatformState.STATE_UNAUTHENTICATED;
			_oauth.accessToken = null;
			if(fail){
				if(onComplete!=null)onComplete(null, true);
			}else{
				if(onComplete!=null)onComplete(true, null);
			}
		}
		
		public function init(clientId:String, redirectUrl:String, stage:Stage, webView:StageWebView, onComplete:Function = null):void
		{
			_oauthUrl.setToken(URL_CLIENT_ID, clientId);
			_oauthUrl.setToken(URL_REDIRECT_URL, redirectUrl);
			_oauth.init(_oauthUrl, checkAuthUrl, "access_token", stage, webView, closure(onOAuthComplete, [onComplete], true));
		}
		
		private function checkAuthUrl(url:String):Boolean{
			return (
					url.indexOf("instagram.com/accounts/login")!=-1 ||
					url.indexOf("instagram.com/accounts/password")!=-1 ||
					url.indexOf("instagram.com/oauth")!=-1
					);
		}
		
		private function onOAuthComplete(success:*, fail:*, onComplete:Function):void
		{
			if(success){
				_stateObj.state = PlatformState.STATE_AUTHENTICATED;
				if(onComplete!=null)onComplete(accessToken, null);
			}else{
				_stateObj.state = PlatformState.STATE_UNAUTHENTICATED;
				if(onComplete!=null)onComplete(null, {});
			}
		}
		
		
		public function authorise():void{
			_stateObj.state = PlatformState.STATE_AUTHENTICATING;
			_oauth.authorise();
		}
		public function cancelAuth():void{
			_oauth.cancelAuth();
		}
		
		// - - - by scopes
		
		///////////////////////////
		///////  B A S I C  ///////
		///////////////////////////
		
		// GET /accounts/logout
		
		public function logout(onComplete:Function=null):void{
			_jsonRest.requestData( _logoutUrl, "accounts/logout/", "GET", null, closure(onLogout, [onComplete], true) );
		}
		
		// GET /users/self/feed
		
		public function getFeed( count:int = -1, min:int=-1, max:int=-1, onComplete:Function=null):void
		{
			_jsonRest.requestData( _callUrl, "users/self/feed/", {count:count, max_id:max, min_id:min}, null, closure(_onPhotos, [onComplete], true) );
		}
		
		// GET /users/search
		
		public function getUserSearch( search:String, onComplete:Function=null ):void
		{
			_jsonRest.requestData( _callUrl, "users/search/", {q:search}, null, closure(_onUsers, [onComplete], true) );
		}
		
		// GET /users/{user-id}
		
		public function getUser( userID:int, onComplete:Function=null ):void
		{
			_jsonRest.requestData( _callUrl, "users/" + userID + "/", null, null, closure(_onUser, [onComplete], true) );
		}
		
		public function getSelf(onComplete:Function=null):void
		{
			_jsonRest.requestData( _callUrl, "users/self/", null, null, closure(_onUser, [onComplete], true) );
		}
		
		// GET /users/self/media/recent
		
		public function getSelfRecent( maxId:int = -1, minId:int = -1, maxTimestamp:int = -1, minTimestamp:int = -1, onComplete:Function=null ):void
		{
			_jsonRest.requestData( _callUrl, "users/self/media/recent/", {max_id:maxId, min_id:minId, max_timestamp:maxTimestamp, min_timestamp:minTimestamp }, null, closure(_onPhotos, [onComplete], true) );
		}
		
		// GET /users/{user-id}/media/recent
		
		public function getUserRecent( userID:int, maxId:int = -1, minId:int = -1, maxTimestamp:int = -1, minTimestamp:int = -1, onComplete:Function=null ):void
		{
			_jsonRest.requestData( _callUrl, "users/" + userID + "/media/recent/", {max_id:maxId, min_id:minId, max_timestamp:maxTimestamp, min_timestamp:minTimestamp }, null, closure(_onPhotos, [onComplete], true) );
		}
		
		// GET /media/{media-id}
		
		public function getPhoto( photoID:int, onComplete:Function=null ):void
		{
			_jsonRest.requestData( _callUrl, "media/" + photoID + "/", null, null, closure(_onPhoto, [onComplete], true) );
		}
		
		// GET /media/search
		
		public function getPhotoSearch( lat:Number, lon:Number, distance:Number, maxTimestamp:int = -1, minTimestamp:int = -1, onComplete:Function=null ):void
		{
			_jsonRest.requestData( _callUrl, "media/search/", {lat:lat, lng:lon, distance:distance, max_timestamp:maxTimestamp, min_timestamp:minTimestamp}, null, closure(_onPhotos, [onComplete], true) );
		}
		
		// GET /media/popular
		
		public function getPhotoPopular(onComplete:Function=null):void
		{
			_jsonRest.requestData( _callUrl, "media/popular/", null, null, closure(_onPhotos, [onComplete], true) );
		}
		
		// GET /locations/{location-id}
		
		public function getLocation( locId:int, onComplete:Function=null ):void
		{
			_jsonRest.requestData( _callUrl, "locations/" + locId + "/", {}, null, closure(_onLocation, [onComplete], true) );
		}
		
		// GET /locations/{location-id}/media/recent
		
		public function getLocationRecent ( locId:int, maxId:int, minId:int, maxTimestamp:int = -1, minTimestamp:int = -1, onComplete:Function=null ):void
		{
			_jsonRest.requestData( _callUrl, "locations/" + locId + "/media/recent", {max_id:maxId, min_id:minId, max_timestamp:maxTimestamp, min_timestamp:minTimestamp}, null, closure(_onPhotos, [onComplete], true) );
		}
		
		// GET /locations/search
		
		public function getLocationSearch ( lat:Number, lon:Number, distance:Number, foursquareId:int, onComplete:Function=null ):void
		{
			_jsonRest.requestData( _callUrl, "locations/search/", {lat:lat, lng:lon, distance:distance, foursquare_id:foursquareId}, null, closure(_onLocations, [onComplete], true) );
		}
		
		// GET /tags/{tag-name}
		
		public function getTag( tagID:String, onComplete:Function=null ):void
		{
			_jsonRest.requestData( _callUrl, "tags/" + tagID + "/", null, null, closure(_onTag, [onComplete], true) );
		}
		
		// GET /tags/{tag-name}/media/recent
		
		public function getTagRecent( tagID:String, minId:int = -1, maxId:int = -1, onComplete:Function=null ):void
		{
			_jsonRest.requestData( _callUrl, "tags/" + tagID + "/media/recent/", {min_id:minId, max_id:maxId}, null, closure(_onPhotos, [onComplete], true) );
		}
		
		// GET /tags/search
		
		public function getTagSearch( search:String, onComplete:Function=null ):void
		{
			_jsonRest.requestData( _callUrl, "tags/search/", {q:search}, null, closure(_onTags, [onComplete], true) );
		}
		
		// GET /geographies/{id}/media/recent
		
		public function getGeographyRecent( geoId:int, onComplete:Function=null ):void
		{
			_jsonRest.requestData( _callUrl, "geographies/" + geoId + "/media/recent/", null, null, closure(_onPhotos, [onComplete], true) );
		}
		/////////////////////////////////////////
		///////  R E L A T I O N S H I P  ///////
		/////////////////////////////////////////
		
		// ---- scope = relationship
		// GET /users/{user-id}/follows
		// GET /users/{user-id}/followed-by
		// GET /users/self/requested-by
		// GET /users/{user-id}/relationship
		// POST /users/{user-id}/relationship
		
		/////////////////////////////////
		///////  C O M M E N T S  ///////
		/////////////////////////////////
		
		// ---- scope = comments
		// GET /media/{media-id}/comments
		// POST /media/{media-id}/comments
		// DELETE /media/{media-id}/comments/{comment-id}
		
		/////////////////////////
		///////  L I K E  ///////
		/////////////////////////
		
		// ---- scope = like
		// GET /media/{media-id}/likes/
		// POST /media/{media-id}/likes/
		// DELETE /media/{media-id}/likes/
	}

}