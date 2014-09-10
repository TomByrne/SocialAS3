package social.web
{
	import org.osflash.signals.Signal;

	public interface IWebView
	{
		function get loadComplete():Signal;    // -> (success:*, fail:*)
		function get locationChanged():Signal; // -> (cancelHandler:Function)
		
		function get isLoading():Boolean;
		function get isLoadingChanged():Signal;
		
		function get isPopulated():Boolean;
		function get isPopulatedChanged():Signal;
		
		function get shown():Boolean;
		function set shown(value:Boolean):void;
		
		function load(url:String, clearHistory:Boolean = false):void;
		function clearView():void;
		
		function get location():String;
	}
}