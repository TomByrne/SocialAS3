package social.gateway
{
	import social.core.IUrlProvider;
	import social.web.IWebView;

	public interface IGateway
	{
		function setWebView( webView:IWebView ):void;
		function doRequest( urlProvider:IUrlProvider, args:Object, protocol:String, onComplete:Function=null ):void;
		function buildUrl( urlProvider:IUrlProvider, args:Object, protocol:String ):String;
	}
}