package
{
	import com.bit101.components.CheckBox;
	import com.bit101.components.ComboBox;
	import com.bit101.components.Component;
	import com.bit101.components.HBox;
	import com.bit101.components.InputText;
	import com.bit101.components.Label;
	import com.bit101.components.PushButton;
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
	
	import social.core.Platform;
	import social.desc.ArgDesc;
	import social.desc.CallDesc;
	import social.dropbox.DropboxPlatform;
	import social.instagram.InstagramPlatform;
	import social.util.closure;
	import social.web.StageWebViewProxy;
	
	[SWF(width='1200', height='800', backgroundColor='#ffffff', frameRate='30')]
	public class TestAPI extends Sprite
	{
		
		
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
		private var _callFields:Dictionary;
		
		private var _selectedPlatform:Platform;
		private var _selectedCall:CallDesc;
		
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
			
			var dropbox:DropboxPlatform	= new DropboxPlatform();
			dropbox.setProp(InstagramPlatform.URL_CLIENT_ID, "56je6nzxitw1avr");
			dropbox.setProp(InstagramPlatform.URL_REDIRECT_URL, "https://devdevelopversion.whitechimagine.com/imagine/app_instagram_redirect.php");
			addPlatform(dropbox);
			
			var instagram:InstagramPlatform	= new InstagramPlatform();
			instagram.setProp(InstagramPlatform.URL_CLIENT_ID, "15a5469e6d284a6eb592391718ac0fe1");
			instagram.setProp(InstagramPlatform.URL_REDIRECT_URL, "http://devdevelopversion.whitechimagine.com/imagine/app_instagram_redirect.php?userGroupID=7");
			addPlatform(instagram);
			
			_platformCombo = new ComboBox(_platformCol, 0, 0, "Platform", _platforms);
			_platformCombo.addEventListener(Event.SELECT, onPlatformSelected);
			_platformCombo.selectedIndex = 0;
			_platformCombo.width = 250;
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
			_callFields = new Dictionary();
			
			var textArea:TextArea = new TextArea(_callCont, 0,0, call.desc);
			textArea.width = 250;
			textArea.editable = false;
			
			var args:Vector.<ArgDesc> = _selectedCall.args;
			for each(var arg:ArgDesc in args){
				var row:HBox = new HBox(_callCont);
				var nameLabel:Label = new Label(row, 0, 0, arg.name+(arg.optional?"":"*"));
				
				var descLabel:Label = new Label(row, 0, 0, " - "+arg.desc);
				descLabel.alpha = 0.5;
				
				var input:InputText = new InputText(_callCont, 0,0, arg.def);
				input.width = 250;
				
				_callFields[arg] = input;
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
				var input:InputText = _callFields[arg];
				if(!arg.optional && input.text.length==0){
					input.opaqueBackground = 0xff0000;
					failed = true;
				}else{
					input.opaqueBackground = null;
				}
				if(input.text.length){
					argVals[arg.name] = input.text;
					text += ("\n  - "+arg.name+" = "+input.text);
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