package social.web
{
	import flash.display.Stage;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.media.StageWebView;
	
	import org.osflash.signals.Signal;

	public class StageWebViewProxy implements IWebView
	{
		public function get loadComplete():Signal{
			if(!_loadComplete)_loadComplete = new Signal();
			return _loadComplete;
		}
		
		public function get location():String{
			return _webView.location;
		}
		
		public function get viewPort():Rectangle{
			return _webView.viewPort;
		}
		public function set viewPort(value:Rectangle):void{
			_webView.viewPort = value;
		}
		
		private var _stage:Stage;
		private var _webView:StageWebView;
		private var _loadComplete:Signal;
		
		public function StageWebViewProxy(stage:Stage, viewPort:Rectangle=null){
			_stage = stage;
			_webView = new StageWebView();
			if(viewPort)this.viewPort = viewPort;
			
			_webView.addEventListener( Event.COMPLETE, onLoadSuccess );
			_webView.addEventListener(ErrorEvent.ERROR, onLoadError);
		}
		
		protected function onLoadError(event:ErrorEvent):void{
			_loadComplete.dispatch(null, true);
		}
		
		protected function onLoadSuccess(event:Event):void{
			_loadComplete.dispatch(true, null);
		}
		
		public function showView(url:String):void{
			_webView.loadURL(url);
			_webView.stage = _stage;
		}
		public function hideView():void{
			_webView.stage = null;
			_webView.loadString("<html></html>"); // clears the view for reuse
		}
	}
}