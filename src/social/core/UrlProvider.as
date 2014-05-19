package social.core
{
	import flash.utils.Dictionary;
	
	import org.osflash.signals.Signal;
	
	public class UrlProvider implements IUrlProvider
	{
		private var _urlChanged:Signal;
		private var _urlPattern:String;
		private var _isReady:Boolean;
		private var _url:String;
		private var _values:Dictionary;
		private var _arrValues:Dictionary;
		private var _arrSeparators:Dictionary;
		
		
		public function UrlProvider(isReady:Boolean=true, urlPattern:String=null)
		{
			_urlChanged = new Signal();
			_values = new Dictionary();
			_arrValues = new Dictionary();
			_arrSeparators = new Dictionary();
			
			this.isReady = isReady;
			this.urlPattern = urlPattern;
		}
		
		public function get urlChanged():Signal
		{
			return _urlChanged;
		}
		
		public function get url():String
		{
			return _url;
		}
		
		public function get urlPattern():String
		{
			return _urlPattern;
		}
		
		public function set urlPattern(value:String):void
		{
			if(_urlPattern==value)return;
			_urlPattern = value;
			rebuildUrl();
		}
		
		public function get isReady():Boolean
		{
			return _isReady;
		}
		
		public function set isReady(value:Boolean):void
		{
			if(_isReady==value)return;
			_isReady = value;
			rebuildUrl();
		}
		
		public function setToken(id:String, value:String):void{
			_values[id] = value;
			rebuildUrl();
		}
		
		public function setupArrayToken(id:String, separator:String=",", value:Array=null):void{
			_arrValues[id] = value || [];
			_arrSeparators[id] = separator;
			rebuildUrl();
		}
		
		public function addArrayToken(id:String, value:String):void{
			var arr:Array = _arrValues[id];
			arr.push(value);
			rebuildUrl();
		}
		
		public function removeArrayToken(id:String, value:String):void{
			var arr:Array = _arrValues[id];
			arr.splice(arr.indexOf(value), 1);
			rebuildUrl();
		}
		
		private function rebuildUrl():void
		{
			var newUrl:String;
			if(_isReady && _urlPattern){
				newUrl = _urlPattern;
				
				var prop:String;
				var str:String;
				for(prop in _arrValues){
					var arr:Array = _arrValues[prop];
					str = arr.join(_arrSeparators[prop]);
					newUrl = newUrl.replace(prop, str);
				}
				for(prop in _values){
					str = _values[prop];
					newUrl = newUrl.replace(prop, str);
				}
				var firstQ:int = newUrl.indexOf("?");
				var lastQ:int;
				while((lastQ = newUrl.lastIndexOf("?"))!=firstQ){
					newUrl = newUrl.substr(0, lastQ)+"&"+newUrl.substr(lastQ+1);
				}
			}
			if(_url!=newUrl){
				_url = newUrl;
				_urlChanged.dispatch();
			}
		}
	}
}