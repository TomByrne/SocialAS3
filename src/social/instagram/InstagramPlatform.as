package social.instagram
{
	import flash.display.Stage;
	import flash.media.StageWebView;
	
	import social.auth.oauth2.OAuth2;
	import social.core.IUrlProvider;
	import social.core.Platform;
	import social.core.PlatformState;
	import social.core.UrlProvider;
	import social.desc.ArgDesc;
	import social.desc.PropDesc;
	import social.gateway.jsonRest.JsonRest;
	import social.vo.Location;
	import social.vo.Photo;
	import social.vo.PhotoSize;
	import social.vo.Tag;
	import social.vo.User;
	import social.web.StageWebViewProxy;

	public class InstagramPlatform extends Platform
	{
		public static const URL_CLIENT_ID				:String		= "${clientId}";
		public static const URL_REDIRECT_URL			:String		= "${redirectUrl}";
		private static const URL_PERMISSIONS			:String		= "${permissions}";
		
		private static const GATEWAY_OAUTH				:String		= "oauth";
		private static const GATEWAY_JSON				:String		= "json";
		
		public static const CALL_AUTH					:String		= "auth";
		public static const CALL_LOGOUT					:String		= "logout";
		
		public static const CALL_GET_FEED				:String		= "getFeed";
		public static const CALL_GET_USER				:String		= "getUser";
		public static const CALL_USER_SEARCH			:String		= "userSearch";
		public static const CALL_GET_SELF				:String		= "getSelf";
		public static const CALL_GET_SELF_RECENT		:String		= "getSelfRecent";
		public static const CALL_GET_SELF_LIKED			:String		= "getSelfLiked";
		public static const CALL_GET_USER_RECENT		:String		= "getUserRecent";
		
		public static const CALL_GET_PHOTO				:String		= "getPhoto";
		public static const CALL_PHOTO_SEARCH			:String		= "photoSearch";
		public static const CALL_GET_POPULAR_PHOTOS		:String		= "getPopularPhotos";
		public static const CALL_GET_PHOTO_LIKES		:String		= "getPhotoLikes";
		
		public static const CALL_GET_LOCATION			:String		= "getLocation";
		public static const CALL_GET_LOCATION_RECENT	:String		= "getLocationRecent";
		public static const CALL_LOCATION_SEARCH		:String		= "locationSearch"
			;
		public static const CALL_GET_TAG				:String		= "getTag";
		public static const CALL_GET_TAG_RECENT			:String		= "getTagRecent";
		public static const CALL_TAG_SEARCH				:String		= "tagSearch";
		
		public static const CALL_GET_GEOGRAPHIES_RECENT	:String		= "getGeographiesRecent";
		
		protected static const AUTH_URL:String = "https://api.instagram.com/oauth/authorize/?client_id="+URL_CLIENT_ID+"&redirect_uri="+URL_REDIRECT_URL+"&response_type=token&scope="+URL_PERMISSIONS;
		protected static const API_URL:String = "https://api.instagram.com/v1/"+JsonRest.URL_ENDPOINT+"?access_token="+OAuth2.URL_ACCESS_TOKEN;
		protected static const LOGOUT_URL:String = "https://instagram.com/"+JsonRest.URL_ENDPOINT;
		
		private var _oauthUrl:UrlProvider;
		private var _callUrl:UrlProvider;
		private var _logoutUrl:UrlProvider;
		
		private var _oauth:OAuth2;
		private var _jsonRest:JsonRest;
		private var _webView:StageWebViewProxy;
		
		public function InstagramPlatform(){
			
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
			
			var onUser:Function = JsonRest.createHandler(parseUser);
			var onUsers:Function = JsonRest.createHandler(JsonRest.createArrParser(parseUser));
			var onPhoto:Function = JsonRest.createHandler(parsePhoto);
			var onPhotos:Function = JsonRest.createHandler(JsonRest.createArrParser(parsePhoto));
			var onLocation:Function = JsonRest.createHandler(parseLocation);
			var onLocations:Function = JsonRest.createHandler(JsonRest.createArrParser(parseLocation));
			var onTag:Function = JsonRest.createHandler(parseTag);
			var onTags:Function = JsonRest.createHandler(parseTags);
			
			
			_oauthUrl = new UrlProvider(true, AUTH_URL);
			_oauthUrl.setupArrayToken(URL_PERMISSIONS, "+", ["basic","comments","relationships","likes"]);
			_oauthUrl.setToken(URL_CLIENT_ID, "");
			_oauthUrl.setToken(URL_REDIRECT_URL, "");
			
			_callUrl = new UrlProvider(true, API_URL);
			_logoutUrl = new UrlProvider(true, LOGOUT_URL);
			
			_oauth = new OAuth2(checkAuthUrl, "access_token");
			_oauth.accessTokenChanged.add(onTokenChanged);
			super("Instagram_v1", _oauth);
			
			addGateway(GATEWAY_OAUTH, _oauth);
			
			_jsonRest = new JsonRest(_oauth);
			addGateway(GATEWAY_JSON, _jsonRest);
			
			addProp(URL_CLIENT_ID, "Instagram application client ID", false);
			addProp(URL_REDIRECT_URL, "Instagram application redirect URL", false);
			
			var userId:ArgDesc 			= a("userID", "User to retrieve");
			var locationId:ArgDesc 		= a("locID", "Location to retrieve");
			var tagId:ArgDesc 			= a("tagID", "Tag to retrieve");
			var searchQuery:ArgDesc 	= a("q", "Search query");
			var minId:ArgDesc 			= a("min_id", "Return media later than this min_id", true);
			var maxId:ArgDesc 			= a("max_id", "Return media earlier than this max_id", true);
			var minTime:ArgDesc 		= a("min_timestamp", "Return media after this UNIX timestamp", true);
			var maxTime:ArgDesc 		= a("max_timestamp", "Return media before this UNIX timestamp", true);
			var count:ArgDesc 			= a("count", "Count of media to return", true);
			
			addCall(GATEWAY_OAUTH, CALL_AUTH, [], _oauthUrl, "Checks whether session can be revived.", null, {doAuth:true});
			addEndpointCall(GATEWAY_JSON, CALL_LOGOUT, "accounts/logout/", [], _logoutUrl, "Deauthenticate user");
			
			addEndpointCall(GATEWAY_JSON, CALL_GET_FEED, "users/self/feed/", [count, minId, maxId], _callUrl, "Get current user's feed.", onPhotos);
			addEndpointCall(GATEWAY_JSON, CALL_GET_USER, "users/${userID}/", [userId], _callUrl, "Gets a user's info.", onUser);
			addEndpointCall(GATEWAY_JSON, CALL_USER_SEARCH, "users/search/", [searchQuery], _callUrl, "Search for users.", onUsers);
			addEndpointCall(GATEWAY_JSON, CALL_GET_SELF, "users/self/", [], _callUrl, "Get current user info.", onUser);
			addEndpointCall(GATEWAY_JSON, CALL_GET_SELF_RECENT, "users/self/media/recent/", [minId, maxId, minTime, maxTime], _callUrl, "Get current users recent photos.", onPhotos);
			addEndpointCall(GATEWAY_JSON, CALL_GET_USER_RECENT, "users/${userID}/media/recent/", [userId, minId, maxId, minTime, maxTime], _callUrl, "Get users recent photos.", onPhotos);
			addEndpointCall(GATEWAY_JSON, CALL_GET_SELF_LIKED, "users/self/media/liked/", [], _callUrl, "See the authenticated user's list of media they've liked.", onPhotos);
			
			addEndpointCall(GATEWAY_JSON, CALL_GET_PHOTO, "media/${photoID}/", [a("photoID", "Photo to retrieve")], _callUrl, "Get a photo's info.", onPhoto);
			addEndpointCall(GATEWAY_JSON, CALL_PHOTO_SEARCH, "media/search/", [searchQuery], _callUrl, "Search for photos.", onPhotos);
			addEndpointCall(GATEWAY_JSON, CALL_GET_POPULAR_PHOTOS, "media/popular/", [], _callUrl, "Get popular photos.", onPhotos);
			addEndpointCall(GATEWAY_JSON, CALL_GET_PHOTO_LIKES, "media/${photoID}/likes", [], _callUrl, "Get users who have liked this media.", onUsers);
			
			addEndpointCall(GATEWAY_JSON, CALL_GET_LOCATION, "locations/${locID}/", [locationId], _callUrl, "Get location's info.", onLocation);
			addEndpointCall(GATEWAY_JSON, CALL_GET_LOCATION_RECENT, "locations/${locID}/media/recent/", [locationId, minId, maxId, minTime, maxTime], _callUrl, "Get recent photos from location.", onPhotos);
			addEndpointCall(GATEWAY_JSON, CALL_LOCATION_SEARCH, "locations/search/", [
				a("lat", "Latitude of the center search coordinate. If used, lng is required"),
				a("lng", "Longitude of the center search coordinate. If used, lat is required."),
				a("distance", "Default is 1000m (distance=1000), max distance is 5000"),
				a("foursquare_id", "Returns a location mapped off of a foursquare v1 api location id. If used, you are not required to use lat and lng. Note that this method is deprecated; you should use the new foursquare IDs with V2 of their API.")
			], _callUrl, "Search for locations.", onLocations);
			
			addEndpointCall(GATEWAY_JSON, CALL_GET_TAG, "tags/${tagID}/", [tagId], _callUrl, "Get tag's info.", onTag);
			addEndpointCall(GATEWAY_JSON, CALL_GET_TAG_RECENT, "tags/${tagID}/media/recent/", [tagId, minId, maxId], _callUrl, "Get recent photos from tag.", onPhotos);
			addEndpointCall(GATEWAY_JSON, CALL_TAG_SEARCH, "tags/search/", [searchQuery], _callUrl, "Search for tags.", onTags);
			
			addEndpointCall(GATEWAY_JSON, CALL_GET_GEOGRAPHIES_RECENT, "geographies/${geoID}/media/recent/", [a("geoID", "Geography to search"), count, minId], _callUrl, "Get recent photos from geography.", onPhotos);
		}
		
		override public function setProp(name:String, value:*):void{
			super.setProp(name, value);
			_oauthUrl.setToken(name, value);
			_callUrl.setToken(name, value);
			_logoutUrl.setToken(name, value);
		}
		
		protected function addEndpointCall(gatewayId:String, callId:String, endPoint:String, args:Array, url:IUrlProvider, desc:String = null, resultHandler:Function=null, urlTokens:Object=null, protocol:String=null):void
		{
			if(!urlTokens)urlTokens = {};
			urlTokens[JsonRest.URL_ENDPOINT] = endPoint;
			addCall(gatewayId, callId, args, _callUrl, desc, resultHandler, urlTokens, protocol);
		}
		
		private function onTokenChanged():void
		{
			_oauthUrl.setToken(OAuth2.URL_ACCESS_TOKEN, _oauth.accessToken);
			_callUrl.setToken(OAuth2.URL_ACCESS_TOKEN, _oauth.accessToken);
			_logoutUrl.setToken(OAuth2.URL_ACCESS_TOKEN, _oauth.accessToken);
		}
		
		private function checkAuthUrl(url:String):Boolean{
			return (
				url.indexOf("instagram.com/accounts/login")!=-1 ||
				url.indexOf("instagram.com/accounts/password")!=-1 ||
				url.indexOf("instagram.com/oauth")!=-1
			);
		}
	}
}