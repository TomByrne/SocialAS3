package social.web
{
	import org.osflash.signals.Signal;

	public interface IWebView
	{
		function get loadComplete():Signal;
		
		function showView(url:String):void;
		function hideView():void;
		
		function get location():String;
	}
}