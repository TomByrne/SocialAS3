package
{
	import com.bit101.components.CheckBox;
	import com.bit101.components.ComboBox;
	import com.bit101.components.Component;
	import com.bit101.components.HBox;
	import com.bit101.components.PushButton;
	import com.bit101.components.Text;
	import com.bit101.components.TextArea;
	import com.bit101.components.VBox;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.text.TextFormat;
	import flash.utils.Dictionary;
	import flash.utils.describeType;
	import flash.utils.getQualifiedClassName;
	
	import propEditors.BooleanPropEditor;
	import propEditors.DefaultPropEditor;
	import propEditors.IPropEditor;
	
	import social.core.Platform;
	import social.desc.ArgDesc;
	import social.desc.CallDesc;
	import social.dropbox.DropboxPlatform;
	import social.fb.FacebookPermissions;
	import social.fb.FacebookPlatform;
	import social.instagram.InstagramPlatform;
	import social.util.closure;
	import social.web.StageWebViewProxy;
	
	[SWF(width='1200', height='800', backgroundColor='#ffffff', frameRate='30')]
	public class TestAPI extends Sprite
	{
		
		static private const DEFAULT_EDITOR:Class = DefaultPropEditor;
		static private var EDITOR_MAP:Dictionary;{
			EDITOR_MAP = new Dictionary();
			EDITOR_MAP[String]		= DefaultPropEditor;
			EDITOR_MAP[Boolean]		= BooleanPropEditor;
		}
		
		
		private var _platforms:Array;
		private var _mainCont:HBox;
		private var _platformCol:Component;
		private var _platformCont:VBox;
		private var _callCont:VBox;
		private var _resultCont:VBox;
		private var _results:TextArea;
		private var _webView:StageWebViewProxy;
		private var _platformCombo:ComboBox;
		private var _autoClear:CheckBox;
		
		
		private var _callButtons:Dictionary;
		private var _callEditors:Dictionary;
		
		private var _selectedPlatform:Platform;
		private var _selectedCall:CallDesc;
		private var _cancelAuthButton:PushButton;
		
		public function TestAPI()
		{
			_platforms = [];
			
			_webView = new StageWebViewProxy(stage, new Rectangle(0,20,stage.stageWidth, stage.stageHeight-20));
			
			_mainCont = new HBox(this, 0, 0);
			
			_resultCont = new VBox(_mainCont);
			
			var buttonRow:HBox = new HBox(_resultCont);
			new PushButton(buttonRow, 0, 0, "Clear", onClearResult);
			_autoClear = new CheckBox(buttonRow, 0, 0, "Always clear on execute");
			
			_results = new TextArea(_resultCont);
			_results.setSize(400, stage.stageHeight - 30);
			
			_resultCont.setSize(400, stage.stageHeight);
			
			_platformCol = new Component(_mainCont);
			_platformCol.setSize(260, stage.stageHeight);
			
			_platformCont = new VBox(_platformCol, 0, 30);
			
			_callCont = new VBox(_mainCont, 0, 30);
			
			var facebook:FacebookPlatform	= new FacebookPlatform([FacebookPermissions.user_about_me, FacebookPermissions.user_photos, FacebookPermissions.read_mailbox]);
			facebook.setProp(FacebookPlatform.URL_CLIENT_ID, "262050547226244");
			facebook.setProp(FacebookPlatform.URL_REDIRECT_URL, "https://devdevelopversion.whitechimagine.com/imagine/app_instagram_redirect.php");
			addPlatform(facebook);
			
			var dropbox:DropboxPlatform	= new DropboxPlatform();
			dropbox.setProp(DropboxPlatform.URL_CLIENT_ID, "56je6nzxitw1avr");
			dropbox.setProp(DropboxPlatform.URL_REDIRECT_URL, "https://devdevelopversion.whitechimagine.com/imagine/app_instagram_redirect.php");
			addPlatform(dropbox);
			
			var instagram:InstagramPlatform	= new InstagramPlatform();
			instagram.setProp(InstagramPlatform.URL_CLIENT_ID, "15a5469e6d284a6eb592391718ac0fe1");
			instagram.setProp(InstagramPlatform.URL_REDIRECT_URL, "http://devdevelopversion.whitechimagine.com/imagine/app_instagram_redirect.php?userGroupID=7");
			addPlatform(instagram);
			
			var platformHeader:HBox = new HBox(_platformCol);
			
			_platformCombo = new ComboBox(platformHeader, 0, 0, "Platform", _platforms);
			_platformCombo.addEventListener(Event.SELECT, onPlatformSelected);
			_platformCombo.selectedIndex = 0;
			_platformCombo.width = 170;
			
			_cancelAuthButton = new PushButton(platformHeader, 0, 0, "Cancel Auth", onCancelAuthClick);
			_cancelAuthButton.width = 75;
		}
		
		private function onCancelAuthClick(e:Event):void
		{
			_selectedPlatform.cancelAuth();
		}
		
		private function onClearResult(e:Event):void
		{
			_results.text = "";
		}
		
		protected function onPlatformSelected(event:Event):void
		{
			while(_platformCont.numChildren){
				_platformCont.removeChildAt(0);
			}
			if(_selectedPlatform){
				_selectedPlatform.stateChanged.remove(onStateChanged);
			}
			
			_callButtons = new Dictionary();
			_selectedPlatform = _platformCombo.selectedItem as Platform;
			_selectedPlatform.stateChanged.add(onStateChanged);
			var calls:Vector.<CallDesc> = _selectedPlatform.calls;
			for each(var call:CallDesc in calls){
				var button:PushButton = new PushButton(_platformCont, 0, 0, call.callId, closure(onCallSelected, [call]));
				button.width = 250;
				button.enabled = (call.availableState==_selectedPlatform.state);
				_callButtons[call.callId] = button;
			}
		}
		
		private function onStateChanged():void
		{
			var calls:Vector.<CallDesc> = _selectedPlatform.calls;
			for each(var call:CallDesc in calls){
				var button:PushButton = _callButtons[call.callId];
				button.enabled = (call.availableState==_selectedPlatform.state);
			}
		}
		
		private function onCallSelected(call:CallDesc):void
		{
			while(_callCont.numChildren){
				_callCont.removeChildAt(0);
			}
			
			_selectedCall = call;
			_callEditors = new Dictionary();
			
			var textArea:Text = new Text(_callCont, 0,0, call.desc);
			textArea.width = 250;
			textArea.editable = false;
			textArea.height = textArea.textField.textHeight + 10;
			
			var args:Vector.<ArgDesc> = _selectedCall.args;
			for each(var arg:ArgDesc in args){
				var editorType:Class;
				if(arg.type)editorType = EDITOR_MAP[arg.type];
				if(!editorType)editorType = DEFAULT_EDITOR;
				
				var editor:IPropEditor = new editorType();
				editor.setArg(arg);
				_callEditors[arg] = editor;
				
				_callCont.addChild(editor.display);
			}
			var button:PushButton = new PushButton(_callCont, 0, 0, "Execute", closure(onCallExecuted, [call]));
		}
		
		private function onCallExecuted(call:CallDesc):void
		{
			if(_autoClear.selected){
				_results.textField.text = " ";
			}
			setResultColour(0x666666);
			var text:String;
			if(_results.textField.text.length)text = ("\n\n");
			else text = "";
			text += ("------------------DO CALL---------------");
			text += ("\n"+call.callId);
			
			var args:Vector.<ArgDesc> = _selectedCall.args;
			var failed:Boolean;
			var argVals:Object = {};
			for each(var arg:ArgDesc in args){
				var editor:IPropEditor = _callEditors[arg];
				if(!editor.validate()){
					failed = true;
				}
				if(editor.hasValue()){
					var value:* = editor.getValue();
					argVals[arg.name] = value;
					text += ("\n  - "+arg.name+" = "+value);
				}
			}
			if(failed)return;
			
			_results.textField.appendText(text);
			
			_selectedPlatform.doCall(call.callId, argVals, onResult);
		}
		
		private function addPlatform(platform:Platform):void
		{
			_platforms.push(platform);
			platform.setWebView(_webView);
		}
		
		
		private function onResult(success:*, fail:*):void
		{
			_results.textField.appendText("\n\n");
			if(success){
				setResultColour(0);
				_results.textField.appendText("------------------SUCCESS---------------");
				_results.textField.appendText("\n"+stringify(success));
			}else{
				setResultColour(0xbb0000);
				_results.textField.appendText("------------------FAILURE---------------");
				_results.textField.appendText("\n"+stringify(fail));
			}
			_results.textField.scrollV = _results.textField.maxScrollV;
		}
		
		private function setResultColour(colour:Number):void
		{
			var format:TextFormat = _results.textField.defaultTextFormat;
			format.color = colour;
			_results.textField.defaultTextFormat = format;
		}
		
		private function stringify(obj:*, tabs:String = "", done:Dictionary=null):String
		{
			if(obj is Date)return obj.toString();
			
			if(!done)done = new Dictionary();
			if(typeof(obj)=="object"){
				done[obj] = true;
				var type:String = getQualifiedClassName(obj);
				var ret:String = type;
				for(var i:String in obj){
					var value:* = obj[i];
					if(done[value])continue;
					ret += "\n"+tabs+" "+i+" = "+stringify(value, tabs+"\t", done);
				}
				var goDeep:Boolean = !(obj is DisplayObject);
				
				var description:XML = describeType(obj);
				for each (var a:XML in description.*.((localName()=="variable" || localName()=="accessor") && (!attribute("access").length() || @access.toString()!="writeonly"))){
					i = a.@name;
					try{
						value = obj[i];
						if(done[value])continue;
						ret += "\n"+tabs+" "+i+" = "+(goDeep?stringify(value, tabs+"\t", done):value.toString());
					}catch(e:Error){}
				}
				
				return ret;
			}else{
				return String(obj);
			}
		}
	}
}