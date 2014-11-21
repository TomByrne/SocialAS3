package social.auth
{
	import flash.display.Stage;
	import flash.media.StageWebView;
	
	import org.osflash.signals.Signal;

	public interface IAuth
	{
		function get accessTokenChanged():Signal;
		function get accessToken():String;
		function set accessToken(value:String):void;
		
		function get pendingAuth():Boolean;
		
		function markTokenWorks():void;
		function get tokenTested():Boolean;
		
		function cancelAuth():void;
	}
}