package social.auth.oauth2
{
	import org.osflash.signals.Signal;
	
	import social.auth.IAuth;
	import social.core.IUrlProvider;
	import social.gateway.IGateway;
	import social.web.IWebView;
	
	
	public class OAuth2 implements IAuth, IGateway
	{
		public static const URL_ACCESS_TOKEN			:String		= "${accessToken}";
		public static const TOKEN_SEARCHER				:RegExp		= /access_token=([\d\w\.\-_]*)/;
		public static const ERROR_SEARCHER				:RegExp		= /error=([\d\w\.\-_]*)/;
		
		public function get accessTokenChanged():Signal{
			if(!_accessTokenChanged)_accessTokenChanged = new Signal();
			return _accessTokenChanged;
		}
		
		private var _urlProvider			:IUrlProvider;
		
		private var _tokenSearcher			:RegExp;
		private var _errorSearcher			:RegExp;
		private var _accessToken			:String;
		private var _accessTokenChanged		:Signal;
		
		private var _webView				:IWebView;
		
		private var _urlScopeChecker		:Function;
		
		private var _pendingAuth			:Boolean;
		private var _onCompletes			:Array;
		private var _tokenTested			:Boolean;
		private var _showImmediately:Boolean;
		
		
		public function OAuth2(urlScopeChecker:Function, tokenSearcher:RegExp=null, errorSearcher:RegExp=null)
		{
			_urlScopeChecker = urlScopeChecker;
			_tokenSearcher = tokenSearcher || TOKEN_SEARCHER;
			_errorSearcher = errorSearcher || ERROR_SEARCHER;
			_onCompletes = [];
		}
		public function setWebView(webView:IWebView):void{
			_webView = webView;
		}
		public function buildUrl( urlProvider:IUrlProvider, args:Object, protocol:String ):String{
			return urlProvider.url;
		}
		public function doRequest( urlProvider:IUrlProvider, args:Object, protocol:String, onComplete:Function=null ):void
		{
			if(onComplete!=null)_onCompletes.push(onComplete);
			
			if(_urlProvider){
				_urlProvider.urlChanged.remove(onUrlChanged);
			}
			_urlProvider = urlProvider;
			_urlProvider.urlChanged.add(onUrlChanged);
			
			authenticate(args.showImmediately!=false);
			
		}
		
		private function onUrlChanged():void
		{
			authenticate(false); 
		}
		
		/**
		 * 
		 * 
		 */		
		private function authenticate(showImmediately:Boolean):void
		{
			if(!_webView || !_urlProvider || _pendingAuth)return;
			
			var url:String = _urlProvider.url
			if(!url)return;
			
			_pendingAuth = true;
			_showImmediately = showImmediately;
			
			trace("oauth2 - "+url);
			_webView.loadComplete.add(onLoadComplete);
			_webView.locationChanged.add(onLocationChanged);
			_webView.showView(url, showImmediately);
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
		
		private function callComplete(success:*, fail:*):void
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
			if(success){
				checkLocation();
			}else{
				cancelAuth();
			}
		}
		
		private function onLocationChanged(cancelHandler:Function):void
		{
			checkLocation(cancelHandler);
		}
		
		private function checkLocation(cancelHandler:Function=null):void
		{
			if(!_pendingAuth)return;
			
			var location:String = _webView.location;
			var newToken:String;
			var res:Object = _tokenSearcher.exec(location);
			if(res){
				newToken = res[1];
			}
			if ( newToken )
			{
				_tokenTested = true;
				_accessToken = newToken;
				if(_accessTokenChanged)_accessTokenChanged.dispatch();
				cleanupAuth();
				callComplete(true, null);
			}else{
				res = _errorSearcher.exec(location);
				
				if(res || _urlScopeChecker==null){
					cancelAuth();
				}
				else if(!_urlScopeChecker(location)){
					if(cancelHandler!=null){
						cancelHandler();
					}else{
						if(!_showImmediately){
							_webView.hideView();
						}
						_webView.showView(_urlProvider.url, _showImmediately);
					}
				}
			}
		}
		
		private function cleanupAuth():void
		{
			_webView.loadComplete.remove(onLoadComplete);
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