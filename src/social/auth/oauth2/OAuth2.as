package social.auth.oauth2
{
	import flash.display.Stage;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.media.StageWebView;
	import flash.net.URLVariables;
	
	import org.osflash.signals.Signal;
	
	import social.auth.IAuth;
	import social.core.IUrlProvider;
	import social.gateway.IGateway;
	import social.web.IWebView;
	
	
	public class OAuth2 implements IAuth, IGateway
	{
		public static const URL_ACCESS_TOKEN			:String		= "${accessToken}";
		
		public function get accessTokenChanged():Signal{
			if(!_accessTokenChanged)_accessTokenChanged = new Signal();
			return _accessTokenChanged;
		}
		
		private var _urlProvider			:IUrlProvider;
		
		private var _responseVar			:String;
		private var _accessToken			:String;
		private var _accessTokenChanged		:Signal;
		
		private var _webView				:IWebView;
		
		private var _urlScopeChecker:Function;
		
		private var _pendingAuth:Boolean;
		private var _onCompletes:Array;
		private var _tokenTested:Boolean;
		
		
		public function OAuth2(urlScopeChecker:Function, responseVar:String)
		{
			_urlScopeChecker = urlScopeChecker;
			_responseVar = responseVar;
			_onCompletes = [];
		}
		public function setWebView(webView:IWebView):void{
			_webView = webView;
		}
		public function doRequest( urlProvider:IUrlProvider, args:Object, protocol:String, onComplete:Function=null ):void
		{
			if(onComplete!=null)_onCompletes.push(onComplete);
			
			if(_urlProvider){
				_urlProvider.urlChanged.remove(onUrlChanged);
			}
			_urlProvider = urlProvider;
			_urlProvider.urlChanged.add(onUrlChanged);
			
			authenticate();
			
		}
		
		private function onUrlChanged():void
		{
			authenticate(); 
		}
		
		/**
		 * 
		 * 
		 */		
		private function authenticate():void
		{
			if(!_webView || !_urlProvider || _pendingAuth)return;
			
			var url:String = _urlProvider.url
			if(!url)return;
			
			_pendingAuth = true;
			
			_webView.loadComplete.add(onLoadComplete);
			_webView.showView(url);
		}
		public function cancelAuth():void
		{
			if(_accessToken){
				_accessToken = null;
				if(_accessTokenChanged)_accessTokenChanged.dispatch();
			}
			if(!_pendingAuth)return;
			cleanupAuth();
			callComplete(null, true);
		}
		
		private function callComplete(success:Object, fail:Boolean):void
		{
			if(_onCompletes.length){
				for each(var onComplete:Function in _onCompletes){
					onComplete(success, fail);
				}
				_onCompletes = [];
			}
		}
		
		private function onLoadComplete( success:*, fail:Boolean):void
		{
			_webView.loadComplete.remove(onLoadComplete);
			if(success){
				var location:String = _webView.location;
				var newToken:String;
				if(location.indexOf("?")!=-1 && location.indexOf(_responseVar)!=-1){
					var urlVars:URLVariables = new URLVariables(location);
					newToken = urlVars[_responseVar];
				}
				if ( newToken )
				{
					_tokenTested = true;
					_accessToken = newToken;
					if(_accessTokenChanged)_accessTokenChanged.dispatch();
					cleanupAuth();
					callComplete(true, null);
				}
				else if(_urlScopeChecker==null || !_urlScopeChecker(location))
				{
					cancelAuth();
				}
			}else{
				cancelAuth();
			}
		}
		
		private function cleanupAuth():void
		{
			_pendingAuth = false;
			_webView.hideView();
		}
		
		public function markTokenWorks():void
		{
			_tokenTested = true;
		}
			
		public function get accessToken():String
		{
			return _accessToken;
		}
		
		public function set accessToken(value:String):void
		{
			_accessToken = value;
			_tokenTested = false;
			if(_accessTokenChanged)_accessTokenChanged.dispatch();
		}
		
		public function get pendingAuth():Boolean
		{
			return _pendingAuth;
		}
		
		public function get tokenTested():Boolean
		{
			return _tokenTested;
		}
	}
}