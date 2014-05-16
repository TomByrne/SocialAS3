package social.dropbox
{
	import org.osflash.signals.Signal;
	
	import social.util.closure;
	import social.web.IWebView;

	public class Dropbox
	{
		public static const FORMAT_JPEG:String = "jpeg";
		public static const FORMAT_PNG:String = "png";
		
		public static const ROOT_DROPBOX:String		= "dropbox";
		public static const ROOT_SANDBOX:String		= "sandbox";
		
		public static const SIZE_XS:String = "xs";
		public static const SIZE_S :String = "s";
		public static const SIZE_M :String = "m";
		public static const SIZE_L :String = "l";
		public static const SIZE_XL:String = "xl";
		
		public function get manageSession():Boolean
		{
			return _platform.manageSession;
		}
		public function set manageSession(value:Boolean):void
		{
			_platform.manageSession = value;
		}
		
		public function get accessToken():String
		{
			return _platform.accessToken;
		}
		public function set accessToken(value:String):void
		{
			_platform.accessToken = value;
		}
		
		public function get stateChanged():Signal{
			return _platform.stateChanged;
		}
		public function get state():String{
			return _platform.state;
		}
		
		
		private var _platform:DropboxPlatform
		
		public function Dropbox()
		{
			_platform = new DropboxPlatform();
		}
		public function setWebView(webView:IWebView):void{
			_platform.setWebView(webView);
		}
		
		public function init(clientId:String, redirectUrl:String):void
		{
			_platform.setProp(DropboxPlatform.URL_CLIENT_ID, clientId);
			_platform.setProp(DropboxPlatform.URL_REDIRECT_URL, redirectUrl);
		}
		public function authenticate(showImmediately:Boolean = true, onComplete:Function=null):void
		{
			_platform.doCall(DropboxPlatform.CALL_AUTH, {showImmediately:showImmediately}, onComplete);
		}
		public function cancelAuth():void{
			_platform.cancelAuth();
		}
		public function logout(onComplete:Function=null):void{
			_platform.doCall(DropboxPlatform.CALL_LOGOUT, {}, onComplete);
		}
		
		public function getSelf( onComplete:Function=null):void{
			_platform.doCall(DropboxPlatform.CALL_GET_SELF, {}, onComplete);
		}
		
		public function getFile( filePath:String, root:String = ROOT_DROPBOX, onComplete:Function=null):void{
			_platform.doCall(DropboxPlatform.CALL_GET_FILE, {filePath:filePath, root:root}, onComplete);
		}
		
		public function getMetadata( filePath:String, root:String = ROOT_DROPBOX, fileLimit:int = 10000, hash:String=null, list:Boolean=true, includeDeleted:Boolean=false, rev:String=null, includeMediaInfo:Boolean=false, onComplete:Function=null):void{
			_platform.doCall(DropboxPlatform.CALL_GET_METADATA, {filePath:filePath, root:root, file_limit:fileLimit, hash:hash, list:list, include_deleted:includeDeleted, rev:rev, include_media_info:includeMediaInfo}, onComplete);
		}
		
		public function getDelta( cursor:String=null, pathPrefix:String=null, includeMediaInfo:Boolean=false, onComplete:Function=null):void{
			_platform.doCall(DropboxPlatform.CALL_DELTA, {cursor:cursor, path_prefix:pathPrefix, include_media_info:includeMediaInfo}, onComplete);
		}
		
		public function getLongpollDelta( cursor:String, timeout:int = 30, onComplete:Function=null):void{
			_platform.doCall(DropboxPlatform.CALL_LONGPOLL_DELTA, {cursor:cursor, timeout:timeout}, onComplete);
		}
		
		public function getRevisions( filePath:String, root:String = ROOT_DROPBOX, revLimit:int=10, onComplete:Function=null):void{
			_platform.doCall(DropboxPlatform.CALL_GET_REVISIONS, {filePath:filePath, root:root, rev_limit:revLimit}, onComplete);
		}
		
		public function restore( filePath:String, rev:String, root:String = ROOT_DROPBOX, onComplete:Function=null):void{
			_platform.doCall(DropboxPlatform.CALL_RESTORE, {filePath:filePath, root:root}, onComplete);
		}
		
		public function search( query:String, filePath:String="", root:String = ROOT_DROPBOX, fileLimit:int = 1000, includeDeleted:Boolean=false, onComplete:Function=null):void{
			_platform.doCall(DropboxPlatform.CALL_SEARCH, {query:query, filePath:filePath, root:root, file_limit:fileLimit, include_deleted:includeDeleted}, onComplete);
		}
		
		public function getShareLink( filePath:String, root:String = ROOT_DROPBOX, shortUrl:Boolean = true, onComplete:Function=null):void{
			_platform.doCall(DropboxPlatform.CALL_GET_SHARE_LINK, {filePath:filePath, root:root, short_url:shortUrl}, onComplete);
		}
		
		public function getCopyRef( filePath:String, root:String = ROOT_DROPBOX, onComplete:Function=null):void{
			_platform.doCall(DropboxPlatform.CALL_GET_COPY_REF, {filePath:filePath, root:root}, onComplete);
		}
		
		public function getThumbnails( filePath:String, root:String = ROOT_DROPBOX, format:String = FORMAT_JPEG, size:String = SIZE_S, onComplete:Function=null):void{
			_platform.doCall(DropboxPlatform.CALL_GET_THUMBNAILS, {filePath:filePath, root:root, format:format, size:size}, onComplete);
		}
		
		public function multiSearch( queries:Array, filePath:String="", root:String = ROOT_DROPBOX, fileLimit:int = 1000, includeDeleted:Boolean=false, onComplete:Function=null):void{
			var calls:Array = [];
			for(var i:int=0; i<queries.length; ++i){
				calls.push({id:DropboxPlatform.CALL_SEARCH, args:{query:queries[i], filePath:filePath, root:root, file_limit:fileLimit, include_deleted:includeDeleted}});
			}
			_platform.doMultiCall(calls, closure(onMultiSearch, [onComplete], true));
		}
		private function onMultiSearch(results:Array, onComplete:Function):void{
			var successes:Array = [];
			for each(var resObj:Object in results){
				if(resObj.success){
					successes = successes.concat(resObj.success);
				}else{
					if(onComplete!=null){
						onComplete(null, true);
						return;
					}
				}
			}
			onComplete(successes, null);
		}
		
		
		public function getThumbnailUrl(filePath:String, root:String = ROOT_DROPBOX, format:String = FORMAT_JPEG, size:String = SIZE_S):String{
			return _platform.getCallUrl(DropboxPlatform.CALL_GET_THUMBNAILS, {filePath:filePath, root:root, format:format, size:size});
		}
		public function getFileUrl(filePath:String, root:String = ROOT_DROPBOX, format:String = FORMAT_JPEG, size:String = SIZE_S):String{
			return _platform.getCallUrl(DropboxPlatform.CALL_GET_FILE, {filePath:filePath, root:root});
		}
	}
}