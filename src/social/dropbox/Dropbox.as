package social.dropbox
{
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.media.StageWebView;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	
	import org.osflash.signals.Signal;
	
	import social.instagram.data.DataParser;
	import social.core.IUrlProvider;
	import social.auth.oauth2.OAuth2;
	import social.auth.TokenSaver;
	import social.core.UrlProvider;
	import social.gateway.jsonRest.JsonRest;
	import social.util.StateObject;
	import social.util.closure;

	public class Dropbox
	{
		
		private static const URL_CLIENT_ID				:String		= "${clientId}";
		private static const URL_REDIRECT_URL			:String		= "${redirectUrl}";
		private static const URL_PERMISSIONS			:String		= "${permissions}";
		
		public static const STATE_UNAUTHENTICATED		:String		= "stateUnauthenticated";
		public static const STATE_AUTHENTICATING		:String		= "stateAuthenticaing";
		public static const STATE_AUTHENTICATED			:String		= "stateAuthenticated";
		
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
		
		public function Dropbox() {
			_onUser = JsonRest.createParser(DataParser.parseUser);
			_onUsers = JsonRest.createParser(DataParser.parseUserArray);
			_onPhoto = JsonRest.createParser(DataParser.parsePhoto);
			_onPhotos = JsonRest.createParser(DataParser.parsePhotoArray);
			_onLocation = JsonRest.createParser(DataParser.parseLocation);
			_onLocations = JsonRest.createParser(DataParser.parseLocationArray);
			_onTag = JsonRest.createParser(DataParser.parseTag);
			_onTags = JsonRest.createParser(DataParser.parseTagArray);
			
			_stateObj = new StateObject([STATE_UNAUTHENTICATED, STATE_AUTHENTICATING, STATE_AUTHENTICATED], STATE_UNAUTHENTICATED);
			
			_oauthUrl = new UrlProvider(true, "https://api.instagram.com/oauth/authorize/?client_id="+URL_CLIENT_ID+"&redirect_uri="+URL_REDIRECT_URL+"&response_type=token&scope="+URL_PERMISSIONS+"");
			_oauthUrl.setupArrayToken(URL_PERMISSIONS, "+", ["basic","comments","relationships","likes"]);
			_oauthUrl.setToken(URL_CLIENT_ID, "");
			_oauthUrl.setToken(URL_REDIRECT_URL, "");
			
			_callUrl = new UrlProvider(true, API_URL+JsonRest.URL_ENDPOINT+"?access_token="+JsonRest.URL_ACCESS_TOKEN);
			
			_logoutUrl = new UrlProvider(true, "https://instagram.com/"+JsonRest.URL_ENDPOINT);
			
			_oauth = new OAuth2(_oauthUrl);
			_oauth.accessTokenChanged.add(onTokenChanged);
			manageSession = true;
			
			_jsonRest = new JsonRest(_oauth);
			
		}
		
		private function onTokenChanged():void
		{
			if(_oauth.accessToken){
				_stateObj.state = STATE_AUTHENTICATED;
			}else{
				_stateObj.state = STATE_UNAUTHENTICATED;
			}
			
		}
		
		private function onLogout(success:String, fail:*, onComplete:Function):void
		{
			_stateObj.state = STATE_UNAUTHENTICATED;
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
				_stateObj.state = STATE_AUTHENTICATED;
				if(onComplete!=null)onComplete(accessToken, null);
			}else{
				_stateObj.state = STATE_UNAUTHENTICATED;
				if(onComplete!=null)onComplete(null, {});
			}
		}
		
		
		public function authorise():void{
			_stateObj.state = STATE_AUTHENTICATING;
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
		
		public function getFeed( min:int=-1, max:int=-1, onComplete:Function=null):void
		{
			_jsonRest.requestData( _callUrl, "users/self/feed/", "GET", {max_id:max, min_id:min}, closure(_onPhotos, [onComplete], true) );
		}
		
	}
}