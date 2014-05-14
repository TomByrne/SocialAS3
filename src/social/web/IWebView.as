package social.web
{
	import org.osflash.signals.Signal;

	public interface IWebView
	{
		function get loadComplete():Signal;
		function get locationChanged():Signal;
		
		function showView(url:String, showImmediately:Boolean):void;
		function hideView():void;
		
		function get location():String;
	}
}