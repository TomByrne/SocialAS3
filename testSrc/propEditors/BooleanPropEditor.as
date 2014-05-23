package propEditors
{
	import com.bit101.components.CheckBox;
	
	import flash.events.Event;
	
	import social.desc.ArgDesc;

	public class BooleanPropEditor extends BasePropEditor
	{
		private var _checkBox:CheckBox;
		private var _isTouched:Boolean;
		
		
		public function BooleanPropEditor()
		{
			super(false);
			
			_checkBox = new CheckBox(this, 0, 0, "", onSelectChanged);
			_checkBox.width = 250;
		}
		
		private function onSelectChanged(e:Event):void
		{
			_isTouched = true;
		}
		
		override public function setArg(arg:ArgDesc):void
		{
			super.setArg(arg);
			
			_checkBox.label = arg.desc;
			
			if(arg.def!=null){
				_isTouched = true;
				_checkBox.selected = arg.def;
			}else{
				_checkBox.selected = false;
				_isTouched = false;
			}
		}
		
		override public function hasValue():Boolean
		{
			return _isTouched;
		}
		
		override public function getValue():*
		{
			return _checkBox.selected;
		}
	}
}