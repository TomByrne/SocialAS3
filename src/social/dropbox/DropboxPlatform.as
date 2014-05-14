package social.dropbox
{
	import social.auth.oauth2.OAuth2;
	import social.core.IUrlProvider;
	import social.core.Platform;
	import social.core.PlatformState;
	import social.core.UrlProvider;
	import social.desc.ArgDesc;
	import social.dropbox.vo.Delta;
	import social.dropbox.vo.DeltaEntry;
	import social.dropbox.vo.DirMetadata;
	import social.dropbox.vo.FileMetadata;
	import social.dropbox.vo.LongPoll;
	import social.dropbox.vo.PhotoMetadata;
	import social.dropbox.vo.Team;
	import social.dropbox.vo.User;
	import social.dropbox.vo.VideoMetadata;
	import social.gateway.jsonRest.JsonRest;
	import social.util.DateParser;
	import social.web.StageWebViewProxy;

	public class DropboxPlatform extends Platform
	{
		public static const URL_LOCALE					:String		= "${locale}";
		public static const URL_CLIENT_ID				:String		= "${clientId}";
		public static const URL_REDIRECT_URL			:String		= "${redirectUrl}";
		
		private static const GATEWAY_OAUTH				:String		= "oauth";
		private static const GATEWAY_JSON				:String		= "json";
		
		public static const CALL_AUTH					:String		= "auth";
		public static const CALL_LOGOUT					:String		= "logout";
		
		public static const CALL_GET_SELF				:String		= "getSelf";
		
		public static const CALL_GET_METADATA			:String		= "getMetadata";
		public static const CALL_DELTA					:String		= "getDelta";
		public static const CALL_LONGPOLL_DELTA			:String		= "getLongpollDelta";
		public static const CALL_GET_REVISIONS			:String		= "getRevisions";
		public static const CALL_RESTORE				:String		= "restore";
		public static const CALL_SEARCH					:String		= "search";
		
		
		protected static const AUTH_URL:String = "https://www.dropbox.com/1/oauth2/authorize/?client_id="+URL_CLIENT_ID+"&redirect_uri="+URL_REDIRECT_URL+"&response_type=token&locale="+URL_LOCALE;
		protected static const API_URL:String = "https://api.dropbox.com/1/"+JsonRest.URL_ENDPOINT+"?access_token="+OAuth2.URL_ACCESS_TOKEN+"&locale="+URL_LOCALE;
		protected static const CONTENT_URL:String = "https://api-content.dropbox.com/1/"+JsonRest.URL_ENDPOINT;
		
		private var _oauthUrl:UrlProvider;
		private var _callUrl:UrlProvider;
		private var _contentUrl:UrlProvider;
		
		private var _oauth:OAuth2;
		private var _jsonRest:JsonRest;
		private var _webView:StageWebViewProxy;
		
		public function DropboxPlatform(){
			
			var parseTeam:Function = JsonRest.createParser(Team, null, {"name":"name"});
			
			var parseUser:Function = JsonRest.createParser(User, {"team":parseTeam},
				{"uid":"id", "email":"email", "referral_link":"referralLink", "display_name":"displayName", "country":"country", "team":"team", "allowed_file_types":"allowedFileTypes",
					"quota_info.normal":"quotaNormal", "quota_info.shared":"quotaShared", "quota_info.datastores":"quotaDatastores", "quota_info.quota":"quota"});
			
			var parseDate:Function = DateParser.parser("%a, %d %b %Y %H:%M:%S %z", true);
			
			var dirParsers:Object = {};
			var parseDirMetadata:Function = JsonRest.createParser(DirMetadata, dirParsers, {"hash":"hash", "contents":"contentsArray"});
			
			var parsePhotoMetadata:Function = JsonRest.createParser(PhotoMetadata, {"time_taken":parseDate},
				{"photo_info.lat_long.0":"lat", "photo_info.lat_long.0":"lng", "time_taken":"timeTaken"});
			
			var parseVideoMetadata:Function = JsonRest.createParser(VideoMetadata, {"time_taken":parseDate},
				{"video_info.lat_long.0":"lat", "video_info.lat_long.0":"lng", "time_taken":"timeTaken", "duration":"duration"});
			
			var parseFileMetadata:Function = JsonRest.createConditionalParser({"photo_info":parsePhotoMetadata, "video_info":parseVideoMetadata}, FileMetadata, {"client_mtime":parseDate},
				{"bytes":"bytes", "size":"size", "client_mtime":"clientModified"});
			
			var parseFileSysMetadata:Function = JsonRest.createConditionalParser({"client_mtime":parseFileMetadata}, parseDirMetadata, {"modified":parseDate},
				{"rev":"rev", "thumb_exists":"thumbExists", "modified":"modified", "path":"path", "icon":"icon", "root":"root", "mimeType":"mimeType", "revision":"revision", "is_deleted":"isDeleted"});
			
			var parseFileSysMetadataArr:Function = JsonRest.createArrParser(parseFileSysMetadata);
			dirParsers.contents = parseFileSysMetadataArr;
			
			var parseDeltaEntry:Function = JsonRest.createParser(DeltaEntry, {"1":parseFileSysMetadata},
				{"1":"metadata", "0":"path"});
			
			var parseDelta:Function = JsonRest.createParser(Delta, {"entries":JsonRest.createArrParser(parseDeltaEntry)},
				{"entries":"entriesArray", "reset":"reset", "cursor":"cursor", "has_more":"hasMore"});
			
			
			var parseLongpoll:Function = JsonRest.createParser(LongPoll, null,	{"changes":"changes", "backoff":"backoff"});
			
			
			
			
			
			var onUser:Function = JsonRest.createHandler(parseUser);
			var onUsers:Function = JsonRest.createHandler(JsonRest.createArrParser(parseUser));
			
			var onFileMetadata:Function = JsonRest.createHandler(parseFileSysMetadata);
			var onFileMetadatas:Function = JsonRest.createHandler(parseFileSysMetadataArr);
			var onDelta:Function = JsonRest.createHandler(parseDelta);
			var onLongpoll:Function = JsonRest.createHandler(parseLongpoll);
			
			
			_oauthUrl = new UrlProvider(true, AUTH_URL);
			_callUrl = new UrlProvider(true, API_URL);
			_contentUrl = new UrlProvider(true, CONTENT_URL);
			
			_oauth = new OAuth2(checkAuthUrl, /access_token=([\d\w\.]*)/g);
			_oauth.accessTokenChanged.add(onTokenChanged);
			super("Dropbox_v1", _oauth);
			
			addGateway(GATEWAY_OAUTH, _oauth);
			
			_jsonRest = new JsonRest(_oauth);
			addGateway(GATEWAY_JSON, _jsonRest);
			
			addProp(URL_CLIENT_ID, "Application client ID", false);
			addProp(URL_REDIRECT_URL, "Application redirect URL", false);
			addProp(URL_LOCALE, "Locale", true);
			
			var s1:String = PlatformState.STATE_UNAUTHENTICATED;
			var s2:String = PlatformState.STATE_AUTHENTICATING;
			var s3:String = PlatformState.STATE_AUTHENTICATED;
			
			addCall(GATEWAY_OAUTH, CALL_AUTH, s1, [], _oauthUrl, "Revives session  if possible, otherwise displays login view.", null, {doAuth:true});
			addEndpointCall(GATEWAY_JSON, CALL_LOGOUT, s3, "disable_access_token/", [], _callUrl, "Deauthenticate user", onLogout);
			
			addEndpointCall(GATEWAY_JSON, CALL_GET_SELF, s3, "account/info/", [], _callUrl, "Retrieves information about the user's account.", onUser);
			
			var argRoot:ArgDesc = a("root", "Root file structure - Shold be 'dropbox', 'sandbox', or 'auto'", false, "dropbox" );
			var argFilePath:ArgDesc = a("filePath", "File concerned", true, "" );
			var argIncMediaInf:ArgDesc = a("include_media_info", "If true, each file will include a photo_info dictionary for photos and a video_info dictionary for videos with additional media info.", true, true );
			//addEndpointCall(GATEWAY_JSON, CALL_GET_FILE, s3, "files/${root}/${filePath}", [argRoot, argFilePath], _contentUrl, "Downloads a file.", onUser);
			//addEndpointCall(GATEWAY_JSON, CALL_PUT_FILE, s3, "files_put/${root}/${filePath}", [argRoot, argFilePath], _contentUrl, "Uploads a file.", onUser, null, JsonRest.PROTOCOL_POST);
			addEndpointCall(GATEWAY_JSON, CALL_GET_METADATA, s3, "metadata/${root}/${filePath}", [
				argRoot, argFilePath,
				a("file_limit", "Default is 10,000 (max is 25,000)", true ),
				a("hash", "Providing prior directory hash will return 302 if nothing has changed.", true ),
				a("list", "Should folder contents be included (default is true).", true ),
				a("include_deleted", "Only applicable when list is set. If this parameter is set to true, then contents will include the metadata of deleted children.", true ),
				a("rev", "If you include a particular revision number, then only the metadata for that revision will be returned.", true ),
				argIncMediaInf
			], _callUrl, "Retrieves file and folder metadata.", onFileMetadata);
			
			addEndpointCall(GATEWAY_JSON, CALL_DELTA, s3, "delta", [
				a("cursor", "A string that is used to keep track of your current state.", true ),
				a("path_prefix", "Filters the response to only include entries at or under the specified path.", true ),
				argIncMediaInf
			], _callUrl, "A way of letting you keep up with changes to files and folders in a user's Dropbox. ", onDelta, null, JsonRest.PROTOCOL_POST);
			
			addEndpointCall(GATEWAY_JSON, CALL_LONGPOLL_DELTA, s3, "longpoll_delta", [
				a("cursor", "A string that is used to keep track of your current state." ),
				a("timeout", "An optional integer indicating a timeout, in seconds. The default value is 30 seconds.", true )
			], _callUrl, "A long-poll endpoint to wait for changes on an account. In conjunction with /delta, this call gives you a low-latency way to monitor an account for file changes.", onLongpoll);
			
			addEndpointCall(GATEWAY_JSON, CALL_GET_REVISIONS, s3, "revisions/${root}/${filePath}", [
				argRoot, argFilePath,
				a("rev_limit", "Default is 10. Max is 1,000. Up to this number of recent revisions will be returned.", true )
			], _callUrl, "Obtains metadata for the previous revisions of a file.", onFileMetadatas);
			
			addEndpointCall(GATEWAY_JSON, CALL_RESTORE, s3, "restore/${root}/${filePath}", [
				argRoot, argFilePath,
				a("rev", "The revision of the file to restore." )
			], _callUrl, "Restores a file path to a previous revision.", onFileMetadatas);
			
			addEndpointCall(GATEWAY_JSON, CALL_SEARCH, s3, "search/${root}/${filePath}", [
				argRoot, argFilePath,
				a("query", "The search string. This string is split (on spaces) into individual words. Files and folders will be returned if they contain all words in the search string." ),
				a("file_limit", "The maximum and default value is 1,000. No more than file_limit search results will be returned.", true ),
				a("include_deleted", "If this parameter is set to true, then files and folders that have been deleted will also be included in the search.", true )
			], _callUrl, "Returns metadata for all files and folders whose filename contains the given search string as a substring.", onFileMetadatas);
			
			
			setProp(URL_CLIENT_ID, "");
			setProp(URL_REDIRECT_URL, "");
			setProp(URL_LOCALE, "");
		}
		
		override public function setProp(name:String, value:*):void{
			super.setProp(name, value);
			_oauthUrl.setToken(name, value);
			_callUrl.setToken(name, value);
		}
		
		protected function addEndpointCall(gatewayId:String, callId:String, availableState:String, endPoint:String, args:Array, url:IUrlProvider, desc:String = null, resultHandler:Function=null, urlTokens:Object=null, protocol:String=null):void
		{
			if(!urlTokens)urlTokens = {};
			urlTokens[JsonRest.URL_ENDPOINT] = endPoint;
			addCall(gatewayId, callId, availableState, args, url, desc, resultHandler, urlTokens, protocol); 
		}
		
		private function onTokenChanged():void
		{
			_oauthUrl.setToken(OAuth2.URL_ACCESS_TOKEN, _oauth.accessToken);
			_callUrl.setToken(OAuth2.URL_ACCESS_TOKEN, _oauth.accessToken);
		}
		
		private function checkAuthUrl(url:String):Boolean{
			return (
				url.indexOf("https://www.dropbox.com/1/oauth2/authorize")!=-1
			);
		}
	}
}