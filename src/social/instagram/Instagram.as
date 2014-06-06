package social.instagram
{
	import org.osflash.signals.Signal;
	
	import social.web.IWebView;

	public class Instagram
	{
		
		public function get manageSession():Boolean
		{
			return _platform.manageSession;
		}
		public function set manageSession(value:Boolean):void
		{
			_platform.manageSession = value;
		}
		
		public function get accessToken():String
		{
			return _platform.accessToken;
		}
		public function set accessToken(value:String):void
		{
			_platform.accessToken = value;
		}

		public function get stateChanged():Signal{
			return _platform.stateChanged;
		}
		public function get state():String{
			return _platform.state;
		}
		
		
		private var _platform:InstagramPlatform
		
		public function Instagram()
		{
			_platform = new InstagramPlatform();
		}
		public function setWebView(webView:IWebView):void{
			_platform.setWebView(webView);
		}
		
		public function init(clientId:String, redirectUrl:String):void
		{
			_platform.setProp(InstagramPlatform.URL_CLIENT_ID, clientId);
			_platform.setProp(InstagramPlatform.URL_REDIRECT_URL, redirectUrl);
		}
		public function authenticate(showImmediately:Boolean = true, onComplete:Function=null):void
		{
			_platform.doCall(InstagramPlatform.CALL_AUTH, {showImmediately:showImmediately}, onComplete);
		}
		public function cancelAuth():void{
			_platform.cancelAuth();
		}
		public function logout(onComplete:Function=null):void{
			_platform.doCall(InstagramPlatform.CALL_LOGOUT, {}, onComplete);
		}
		
		public function getFeed( count:int = -1, min:int=-1, max:int=-1, onComplete:Function=null):void{
			_platform.doCall(InstagramPlatform.CALL_GET_FEED, {count:count, max_id:max, min_id:min}, onComplete);
		}
		
		public function userSearch( search:String, count:int = -1, onComplete:Function=null ):void
		{
			_platform.doCall(InstagramPlatform.CALL_USER_SEARCH, {q:search, count:count}, onComplete);
		}
		
		public function getUser( userID:int, onComplete:Function=null ):void
		{
			_platform.doCall(InstagramPlatform.CALL_GET_USER, {userID:userID}, onComplete);
		}
		
		public function getSelf(onComplete:Function=null):void
		{
			_platform.doCall(InstagramPlatform.CALL_GET_SELF, {}, onComplete);
		}
		
		public function getSelfRecent( count:int = -1, maxId:int = -1, minId:int = -1, maxTimestamp:int = -1, minTimestamp:int = -1, onComplete:Function=null ):void
		{
			_platform.doCall(InstagramPlatform.CALL_GET_SELF_RECENT, {count:count, max_id:maxId, min_id:minId, max_timestamp:maxTimestamp, min_timestamp:minTimestamp}, onComplete);
		}
		
		public function getUserRecent( userID:int, count:int = -1, maxId:int = -1, minId:int = -1, maxTimestamp:int = -1, minTimestamp:int = -1, onComplete:Function=null ):void
		{
			_platform.doCall(InstagramPlatform.CALL_GET_USER_RECENT, {userID:userID, count:count, max_id:maxId, min_id:minId, max_timestamp:maxTimestamp, min_timestamp:minTimestamp}, onComplete);
		}
		
		public function getLiked( onComplete:Function=null ):void
		{
			_platform.doCall(InstagramPlatform.CALL_GET_SELF_LIKED, {}, onComplete);
		}
		
		public function getPhoto( photoID:int, onComplete:Function=null ):void
		{
			_platform.doCall(InstagramPlatform.CALL_GET_PHOTO, {photoID:photoID}, onComplete);
		}
		
		public function getPhotoSearch( lat:Number, lon:Number, distance:Number, maxTimestamp:int = -1, minTimestamp:int = -1, onComplete:Function=null ):void
		{
			_platform.doCall(InstagramPlatform.CALL_PHOTO_SEARCH, {lat:lat, lng:lon, distance:distance, max_timestamp:maxTimestamp, min_timestamp:minTimestamp}, onComplete);
		}
		
		public function getPhotoPopular(onComplete:Function=null):void
		{
			_platform.doCall(InstagramPlatform.CALL_GET_POPULAR_PHOTOS, {}, onComplete);
		}
		
		public function getLocation( locID:int, onComplete:Function=null ):void
		{
			_platform.doCall(InstagramPlatform.CALL_GET_LOCATION, {locID:locID}, onComplete);
		}
		
		public function getLocationRecent ( locID:int, maxId:int, minId:int, maxTimestamp:int = -1, minTimestamp:int = -1, onComplete:Function=null ):void
		{
			_platform.doCall(InstagramPlatform.CALL_GET_LOCATION_RECENT, {locID:locID, max_id:maxId, min_id:minId, max_timestamp:maxTimestamp, min_timestamp:minTimestamp}, onComplete);
		}
		
		public function getLocationSearch ( lat:Number, lon:Number, distance:Number, foursquareId:int, onComplete:Function=null ):void
		{
			_platform.doCall(InstagramPlatform.CALL_LOCATION_SEARCH, { lat:lat, lng:lon, distance:distance, foursquare_id:foursquareId }, onComplete);
		}
		
		public function getTag( tagID:String, onComplete:Function=null ):void
		{
			_platform.doCall(InstagramPlatform.CALL_GET_TAG, { tagID:tagID }, onComplete);
		}
		
		public function getTagRecent( tagID:String, minId:int = -1, maxId:int = -1, onComplete:Function=null ):void
		{
			_platform.doCall(InstagramPlatform.CALL_GET_TAG_RECENT, { tagID:tagID, min_id:minId, max_id:maxId }, onComplete);
		}
		
		public function getTagSearch( search:String, onComplete:Function=null ):void
		{
			_platform.doCall(InstagramPlatform.CALL_TAG_SEARCH, { q:search }, onComplete);
		}
		
		public function getGeographyRecent( geoID:int, onComplete:Function=null ):void
		{
			_platform.doCall(InstagramPlatform.CALL_GET_GEOGRAPHIES_RECENT, { geoID:geoID }, onComplete);
		}
	}
}