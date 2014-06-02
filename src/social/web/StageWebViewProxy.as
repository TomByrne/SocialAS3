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
		public function get isLoadingChanged():Signal{
			if(!_isLoadingChanged)_isLoadingChanged = new Signal();
			return _isLoadingChanged;
		}
		public function get isPopulatedChanged():Signal{
			if(!_isPopulatedChanged)_isPopulatedChanged = new Signal();
			return _isPopulatedChanged;
		}
		
		public function get location():String{
			return _location || _webView.location;
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
			if(_webView.stage || (_isPopulated || !_isLoading))_webView.stage = value;
		}
		
		public function get isLoading():Boolean{
			return _isLoading;
		}
		
		public function get isPopulated():Boolean{
			return _isPopulated;
		}
		
		private var _stage:Stage;
		private var _webView:StageWebView;
		private var _isLoading:Boolean;
		private var _ignoreChanges:Boolean;
		private var _isPopulated:Boolean;
		private var _location:String;
		private var _lastEvent:LocationChangeEvent;
		
		private var _loadComplete:Signal;
		private var _locationChanged:Signal;
		private var _isLoadingChanged:Signal;
		private var _isPopulatedChanged:Signal;
		
		public function StageWebViewProxy(stage:Stage=null, viewPort:Rectangle=null){
			_stage = stage;
			_webView = new StageWebView();
			if(viewPort)this.viewPort = viewPort;
			
			_webView.addEventListener( Event.COMPLETE, onLoadSuccess );
			_webView.addEventListener(ErrorEvent.ERROR, onLoadError);
			_webView.addEventListener(LocationChangeEvent.LOCATION_CHANGING, onLocationChange);
		}
		
		protected function onLocationChange(event:LocationChangeEvent):void
		{
			if(_ignoreChanges)return;
			_lastEvent = event;
			_location = event.location;
			if(_locationChanged)_locationChanged.dispatch(cancelLocationChange);
		}
		
		protected function onLoadError(event:ErrorEvent):void{
			if ( null != event.text && event.text.indexOf("NSURLErrorDomain error -999") != -1 )
			{
				/* It's safe to ignore that error because is is
				returned when an asynchronous load is canceled. A Web Kit framework
				delegate will receive this error when it performs a cancel operation on a
				loading resource. Note that an NSURLConnection or NSURLDownload delegate
				will not receive this error if the download is canceled
				*/
				return;
			}
			_location = null;
			if(_ignoreChanges || !_isPopulated)return;
			
			_loadComplete.dispatch(null, true);
		}
		
		protected function onLoadSuccess(event:Event):void{
			_location = null;
			if(_ignoreChanges || !_isPopulated)return;
			if(_isLoading)_webView.stage = stage;
			setIsLoading(false);
			_loadComplete.dispatch(true, null);
		}
		
		public function showView(url:String, showImmediately:Boolean):void{
			_location = null;
			setIsPopulated(true);
			setIsLoading(true);			
			_webView.loadURL(url);
			if(showImmediately)_webView.stage = _stage;
		}
		public function hideView():void{
			_location = null;
			setIsPopulated(false);
			_webView.stage = null;
			setIsLoading(false);
			_ignoreChanges = true;
			_webView.loadString("<html></html>"); // clears the view for reuse
			_ignoreChanges = false;
		}
		
		private function setIsLoading(value:Boolean):void
		{
			if(_isLoading!=value){
				_isLoading = value;
				if(_isLoadingChanged)_isLoadingChanged.dispatch();
			}
		}
		
		private function setIsPopulated(value:Boolean):void
		{
			if(_isPopulated!=value){
				_isPopulated = value;
				if(_isPopulatedChanged)_isPopulatedChanged.dispatch();
			}
		}
		
		private function cancelLocationChange():void{
			if(_lastEvent){
				_lastEvent.preventDefault();
				_lastEvent = null;
			}
		}
	}
}