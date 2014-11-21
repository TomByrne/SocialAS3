package propEditors
{
	import com.bit101.components.InputText;
	
	import social.desc.ArgDesc;

	public class DefaultPropEditor extends BasePropEditor
	{
		private var _input:InputText;
		
		
		public function DefaultPropEditor()
		{
			super(true);
			
			_input = new InputText(this);
			_input.width = 250;
		}
		
		override public function setArg(arg:ArgDesc):void
		{
			super.setArg(arg);
			
			_input.text = arg.def;
		}
		
		override public function hasValue():Boolean
		{
			return _input.text.length>0;
		}
		
		override public function getValue():*
		{
			return _input.text;
		}
	}
}