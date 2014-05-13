package social.core
{
	import org.osflash.signals.Signal;
	
	public class UrlProxy implements IUrlProvider
	{
		
		public function get urlProvider():IUrlProvider
		{
			return _urlProvider;
		}
		
		public function set urlProvider(value:IUrlProvider):void
		{
			if(_urlProvider == value)return;
			
			if(_urlProvider){
				_urlProvider.urlChanged.remove(onUrlChanged);
			}
			_urlProvider = value;
			if(_urlProvider){
				_urlProvider.urlChanged.add(onUrlChanged);
			}else{
				_url = null;
			}
			onUrlChanged();
		}
		
		private var _urlProvider:IUrlProvider;
		private var _urlInvalid:Boolean;
		private var _urlChanged:Signal;
		private var _url:String;
		private var _values:Object;
		
		
		public function UrlProxy(urlProvider:IUrlProvider=null)
		{
			_urlChanged = new Signal();
			_values = {};
			this.urlProvider = urlProvider;
		}

		public function get urlChanged():Signal
		{
			return _urlChanged;
		}
		
		public function get url():String
		{
			if(_urlInvalid && _urlProvider){
				_url = _urlProvider.url;
				
				for(var prop:String in _values){
					_url = _url.replace(prop, _values[prop]);
				}
			}
			return _url;
		}
		
		private function onUrlChanged():void
		{
			_urlInvalid = true;
			_urlChanged.dispatch();
		}
		
		public function setToken(key:String, value:String):void
		{
			if(_values[key] == value)return;
			
			_values[key] = value;
			onUrlChanged();
		}
	}
}