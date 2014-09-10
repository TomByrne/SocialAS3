package social.gateway
{
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	
	import social.core.IUrlProvider;
	import social.web.IWebView;
	
	public class WebViewGateway implements IGateway
	{
		private var _pending:Boolean;
		private var _webView:IWebView;
		private var _onComplete:Function;
		
		public function WebViewGateway()
		{
		}
		
		public function setWebView(webView:IWebView):void
		{
			_webView = webView;
		}
		
		public function doRequest(urlProvider:IUrlProvider, args:Object, protocol:String, onComplete:Function=null):void
		{
			if(_pending){
				throw new Error("WebViewGateway can only process one request at a time");
			}
			
			_onComplete = onComplete;
			
			var prop:String;
			var val:*;
			
			var url:String = urlProvider.url;
			for ( prop in args )
			{
				val = args[prop]; 
				var token:String = "${"+prop+"}";
				if(url.indexOf(token)!=-1){
					url = url.replace(token, val);
					val = null;
				}
				if(val==null || val==-1 || (typeof(val)=="number" && isNaN(val))){
					delete args[prop];
				}
			}
			
			if ( protocol == "POST" )
			{
				throw new Error("WebViewGateway cannot send POST variables");
				
			}else{
				if ( args )
				{
					var params:String = "";
					
					for ( prop in args )
					{
						params += "&"+prop+"="+args[prop]; 
					}
					
					url += params;
				}
			}
			
			
			_pending = true;
			_webView.loadComplete.add(onLoadComplete);
			_webView.load(url, true);
			//_webView.shown = true;
		}
		
		private function onLoadComplete( success:*, fail:Boolean ):void
		{
			_webView.loadComplete.remove(onLoadComplete);
			_pending = false;
			_onComplete(success, fail);
		}
		
		public function buildUrl(urlProvider:IUrlProvider, args:Object, protocol:String):String
		{
			return null;
		}
	}
}