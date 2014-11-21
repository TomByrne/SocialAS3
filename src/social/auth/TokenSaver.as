package social.auth
{
	import flash.net.SharedObject;

	public class TokenSaver
	{
		public function get active():Boolean{
			return _active;
		}
		public function set active(value:Boolean):void{
			if(_active==value)return;
			_active = value;
			if(_active){
				checkOAuth();
			}else{
				_sharedObject.data.token = null;
				_sharedObject.flush();
				if(_usingSaved){
					_ignoreChanges = true;
					_oauth.accessToken = null;
					_ignoreChanges = false;
				}
				_usingSaved = false;
				_token = null;
			}
		}
		
		private var _usingSaved:Boolean = false;
		private var _active:Boolean = true;
		private var _sharedObject:SharedObject;
		private var _token:String;
		private var _oauth:IAuth;
		private var _ignoreChanges:Boolean;
		
		public function TokenSaver(name:String, oauth:IAuth=null)
		{
			try{
				_sharedObject = SharedObject.getLocal(name);
				_token = _sharedObject.data.token;
			}catch(e:Error){
				trace("Unable to create SharedObject, possibly third-party apps disallowed or allocation full.");
			}
			setOAuth(oauth);
		}
		
		public function setOAuth(oauth:IAuth):void{
			if(_oauth){
				_oauth.accessTokenChanged.remove(onTokenChanged);
			}
			_oauth = oauth;
			if(_oauth){
				_oauth.accessTokenChanged.add(onTokenChanged);
				if(_active){
					checkOAuth();
				}
			}
		}
		
		private function checkOAuth():void
		{
			if(_oauth.accessToken){
				onTokenChanged();
			}else{
				_ignoreChanges = true;
				_usingSaved = true;
				_oauth.accessToken = _token;
				_ignoreChanges = false;
			}
		}
		
		private function onTokenChanged():void
		{
			if(_ignoreChanges || !_active)return;
			
			_usingSaved = false;
			_token = _oauth.accessToken;
			if(_sharedObject){
				_sharedObject.data.token = _token;
				_sharedObject.flush();
			}
		}
	}
}