package social.instagram
{
	import social.auth.oauth2.OAuth2;
	import social.core.IUrlProvider;
	import social.core.Platform;
	import social.core.PlatformState;
	import social.core.UrlProvider;
	import social.desc.ArgDesc;
	import social.gateway.HttpLoader;
	import social.instagram.vo.Location;
	import social.instagram.vo.Photo;
	import social.instagram.vo.PhotoSize;
	import social.instagram.vo.Tag;
	import social.instagram.vo.User;
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
		protected static const API_URL:String = "https://api.instagram.com/v1/"+HttpLoader.URL_ENDPOINT+"?access_token="+OAuth2.URL_ACCESS_TOKEN;
		protected static const LOGOUT_URL:String = "https://instagram.com/"+HttpLoader.URL_ENDPOINT;
		
		private var _oauthUrl:UrlProvider;
		private var _callUrl:UrlProvider;
		private var _logoutUrl:UrlProvider;
		
		private var _oauth:OAuth2;
		private var _jsonRest:HttpLoader;
		private var _webView:StageWebViewProxy;
		
		public function InstagramPlatform(){
			
			var parseUser:Function = HttpLoader.createParser(User, null,
				{"id":"id", "profile_picture":"photo", "full_name":"fullName", "username":"userName"});
			
			var parsePhotoSize:Function = HttpLoader.createParser(PhotoSize, null,
				{"url":"url", "width":"width", "height":"height"});
			var parsePhotoSizes:Function = HttpLoader.createArrParser(parsePhotoSize);
			
			var parseLocation:Function = HttpLoader.createParser(Location, null,
				{"id":"id", "longitude":"longitude", "latitude":"latitude", "name":"name"});
			
			var parseTag:Function = HttpLoader.createParser(Tag, null,
				{"name":"name", "media_count":"count"});
			var parseTags:Function = HttpLoader.createArrParser(parseTag);
			
			var parsePhoto:Function = HttpLoader.createParser(Photo, {"images":parsePhotoSizes, "user":parseUser, "location":parseLocation},
				{"id":"id", "type":"type", "images":"sizes", "created_time":"creation", "likes":"likes", "user":"user", "location":"location", "tags":"tags"});
			
			var onUser:Function = HttpLoader.createHandler(parseUser, "data");
			var onUsers:Function = HttpLoader.createHandler(HttpLoader.createArrParser(parseUser), "data");
			var onPhoto:Function = HttpLoader.createHandler(parsePhoto, "data");
			var onPhotos:Function = HttpLoader.createHandler(HttpLoader.createArrParser(parsePhoto), "data");
			var onLocation:Function = HttpLoader.createHandler(parseLocation, "data");
			var onLocations:Function = HttpLoader.createHandler(HttpLoader.createArrParser(parseLocation), "data");
			var onTag:Function = HttpLoader.createHandler(parseTag, "data");
			var onTags:Function = HttpLoader.createHandler(parseTags, "data");
			
			
			_oauthUrl = new UrlProvider(true, AUTH_URL);
			_oauthUrl.setupArrayToken(URL_PERMISSIONS, "+", ["basic","comments","relationships","likes"]);
			_oauthUrl.setToken(URL_CLIENT_ID, "");
			_oauthUrl.setToken(URL_REDIRECT_URL, "");
			
			_callUrl = new UrlProvider(true, API_URL);
			_logoutUrl = new UrlProvider(true, LOGOUT_URL);
			
			_oauth = new OAuth2(checkAuthUrl);
			_oauth.accessTokenChanged.add(onTokenChanged);
			super("Instagram_v1", _oauth);
			
			addGateway(GATEWAY_OAUTH, _oauth);
			
			_jsonRest = new HttpLoader(_oauth);
			addGateway(GATEWAY_JSON, _jsonRest);
			
			addProp(URL_CLIENT_ID, "Instagram application client ID", false);
			addProp(URL_REDIRECT_URL, "Instagram application redirect URL", false);
			
			var showImmediately:ArgDesc = a("showImmediately", "Show web view while loading", true, null, Boolean);
			var userId:ArgDesc 			= a("userID", "User to retrieve");
			var locationId:ArgDesc 		= a("locID", "Location to retrieve");
			var tagId:ArgDesc 			= a("tagID", "Tag to retrieve");
			var searchQuery:ArgDesc 	= a("q", "Search query");
			var minId:ArgDesc 			= a("min_id", "Return media later than this min_id", true);
			var maxId:ArgDesc 			= a("max_id", "Return media earlier than this max_id", true);
			var minTime:ArgDesc 		= a("min_timestamp", "Return media after this UNIX timestamp", true);
			var maxTime:ArgDesc 		= a("max_timestamp", "Return media before this UNIX timestamp", true);
			var count:ArgDesc 			= a("count", "Count of media to return", true);
			
			var s1:String = PlatformState.STATE_UNAUTHENTICATED;
			var s2:String = PlatformState.STATE_AUTHENTICATING;
			var s3:String = PlatformState.STATE_AUTHENTICATED;
			
			addCall(GATEWAY_OAUTH, CALL_AUTH, s1, [showImmediately], _oauthUrl, "Revives session  if possible, otherwise displays login view.", null, {doAuth:true});
			addEndpointCall(GATEWAY_JSON, CALL_LOGOUT, s3, "accounts/logout/", [], _logoutUrl, "Deauthenticate user", onLogout);
			
			addEndpointCall(GATEWAY_JSON, CALL_GET_FEED, s3, "users/self/feed/", [count, minId, maxId], _callUrl, "Get current user's feed.", onPhotos);
			addEndpointCall(GATEWAY_JSON, CALL_GET_USER, s3, "users/${userID}/", [userId], _callUrl, "Gets a user's info.", onUser);
			addEndpointCall(GATEWAY_JSON, CALL_USER_SEARCH, s3, "users/search/", [searchQuery], _callUrl, "Search for users.", onUsers);
			addEndpointCall(GATEWAY_JSON, CALL_GET_SELF, s3, "users/self/", [], _callUrl, "Get current user info.", onUser);
			addEndpointCall(GATEWAY_JSON, CALL_GET_SELF_RECENT, s3, "users/self/media/recent/", [minId, maxId, minTime, maxTime], _callUrl, "Get current users recent photos.", onPhotos);
			addEndpointCall(GATEWAY_JSON, CALL_GET_USER_RECENT, s3, "users/${userID}/media/recent/", [userId, minId, maxId, minTime, maxTime], _callUrl, "Get users recent photos.", onPhotos);
			addEndpointCall(GATEWAY_JSON, CALL_GET_SELF_LIKED, s3, "users/self/media/liked/", [], _callUrl, "See the authenticated user's list of media they've liked.", onPhotos);
			
			addEndpointCall(GATEWAY_JSON, CALL_GET_PHOTO, s3, "media/${photoID}/", [a("photoID", "Photo to retrieve")], _callUrl, "Get a photo's info.", onPhoto);
			addEndpointCall(GATEWAY_JSON, CALL_PHOTO_SEARCH, s3, "media/search/", [searchQuery], _callUrl, "Search for photos.", onPhotos);
			addEndpointCall(GATEWAY_JSON, CALL_GET_POPULAR_PHOTOS, s3, "media/popular/", [], _callUrl, "Get popular photos.", onPhotos);
			addEndpointCall(GATEWAY_JSON, CALL_GET_PHOTO_LIKES, s3, "media/${photoID}/likes", [], _callUrl, "Get users who have liked this media.", onUsers);
			
			addEndpointCall(GATEWAY_JSON, CALL_GET_LOCATION, s3, "locations/${locID}/", [locationId], _callUrl, "Get location's info.", onLocation);
			addEndpointCall(GATEWAY_JSON, CALL_GET_LOCATION_RECENT, s3, "locations/${locID}/media/recent/", [locationId, minId, maxId, minTime, maxTime], _callUrl, "Get recent photos from location.", onPhotos);
			addEndpointCall(GATEWAY_JSON, CALL_LOCATION_SEARCH, s3, "locations/search/", [
				a("lat", "Latitude of the center search coordinate. If used, lng is required"),
				a("lng", "Longitude of the center search coordinate. If used, lat is required."),
				a("distance", "Default is 1000m (distance=1000), max distance is 5000"),
				a("foursquare_id", "Returns a location mapped off of a foursquare v1 api location id. If used, you are not required to use lat and lng. Note that this method is deprecated; you should use the new foursquare IDs with V2 of their API.")
			], _callUrl, "Search for locations.", onLocations);
			
			addEndpointCall(GATEWAY_JSON, CALL_GET_TAG, s3, "tags/${tagID}/", [tagId], _callUrl, "Get tag's info.", onTag);
			addEndpointCall(GATEWAY_JSON, CALL_GET_TAG_RECENT, s3, "tags/${tagID}/media/recent/", [tagId, minId, maxId], _callUrl, "Get recent photos from tag.", onPhotos);
			addEndpointCall(GATEWAY_JSON, CALL_TAG_SEARCH, s3, "tags/search/", [searchQuery], _callUrl, "Search for tags.", onTags);
			
			addEndpointCall(GATEWAY_JSON, CALL_GET_GEOGRAPHIES_RECENT, s3, "geographies/${geoID}/media/recent/", [a("geoID", "Geography to search"), count, minId], _callUrl, "Get recent photos from geography.", onPhotos);
		}
		
		override public function setProp(name:String, value:*):void{
			super.setProp(name, value);
			_oauthUrl.setToken(name, value);
			_callUrl.setToken(name, value);
		}
		
		protected function addEndpointCall(gatewayId:String, callId:String, availableState:String, endPoint:String, args:Array, url:IUrlProvider, desc:String = null, resultHandler:Function=null, urlTokens:Object=null, protocol:String=null):void
		{
			if(!urlTokens)urlTokens = {};
			urlTokens[HttpLoader.URL_ENDPOINT] = endPoint;
			addCall(gatewayId, callId, availableState, args, url, desc, resultHandler, urlTokens, protocol); 
		}
		
		private function onTokenChanged():void
		{
			_oauthUrl.setToken(OAuth2.URL_ACCESS_TOKEN, _oauth.accessToken);
			_callUrl.setToken(OAuth2.URL_ACCESS_TOKEN, _oauth.accessToken);
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