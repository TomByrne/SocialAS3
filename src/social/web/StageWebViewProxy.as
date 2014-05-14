package social.web
{
	import flash.display.Stage;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.LocationChangeEvent;
	import flash.geom.Rectangle;
	import flash.media.StageWebView;
	
	import org.osflash.signals.Signal;

	public class StageWebViewProxy implements IWebView
	{
		public function get loadComplete():Signal{
			if(!_loadComplete)_loadComplete = new Signal();
			return _loadComplete;
		}
		public function get locationChanged():Signal{
			if(!_locationChanged)_locationChanged = new Signal();
			return _locationChanged;
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
		
		public function get stage():Stage{
			return _stage;
		}
		public function set stage(value:Stage):void{
			_stage = value;
			if(_webView.stage)_webView.stage = value;
		}
		
		private var _stage:Stage;
		private var _webView:StageWebView;
		private var _loadComplete:Signal;
		private var _locationChanged:Signal;
		private var _pendingShow:Boolean;
		private var _ignoreChanges:Boolean;
		
		public function StageWebViewProxy(stage:Stage=null, viewPort:Rectangle=null){
			_stage = stage;
			_webView = new StageWebView();
			if(viewPort)this.viewPort = viewPort;
			
			_webView.addEventListener( Event.COMPLETE, onLoadSuccess );
			_webView.addEventListener(ErrorEvent.ERROR, onLoadError);
			_webView.addEventListener(LocationChangeEvent.LOCATION_CHANGE, onLocationChange);
		}
		
		protected function onLocationChange(event:LocationChangeEvent):void
		{
			if(_ignoreChanges)return;
			
			if(_locationChanged)_locationChanged.dispatch();
		}
		
		protected function onLoadError(event:ErrorEvent):void{
			if(_ignoreChanges)return;
			
			_loadComplete.dispatch(null, true);
		}
		
		protected function onLoadSuccess(event:Event):void{
			if(_ignoreChanges)return;
			
			if(_pendingShow){
				_pendingShow = false;
				_webView.stage = _stage;
			}
			_loadComplete.dispatch(true, null);
		}
		
		public function showView(url:String, showImmediately:Boolean):void{
			_webView.loadURL(url);
			if(showImmediately)_webView.stage = _stage;
			else _pendingShow = true;
		}
		public function hideView():void{
			_webView.stage = null;
			_ignoreChanges = true;
			_webView.loadString("<html></html>"); // clears the view for reuse
			_ignoreChanges = false;
		}
	}
}