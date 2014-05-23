package propEditors
{
	import com.bit101.components.Label;
	import com.bit101.components.Text;
	import com.bit101.components.VBox;
	
	import flash.display.DisplayObject;
	
	import social.desc.ArgDesc;
	
	public class BasePropEditor extends VBox implements IPropEditor
	{
		private var _label:Label;
		private var _description:Text;
		private var _arg:ArgDesc;
		
		public function BasePropEditor(doDesc:Boolean)
		{
			super();
			
			_label = new Label(this);
			_label.width = 250;
			
			if(doDesc){
				_description = new Text(this);
				_description.width = 250;
			}
		}
		
		public function get display():DisplayObject
		{
			return this;
		}
		
		public function setArg(arg:ArgDesc):void
		{
			_arg = arg;
			_label.text = arg.name;
			if(_description){
				_description.text = arg.desc;
				_description.height = _description.textField.textHeight + 10;
			}
		}
		
		public function validate():Boolean
		{
			return _arg.optional || hasValue();
		}
		
		public function hasValue():Boolean
		{
			return true;
		}
		
		public function getValue():*
		{
			return null;
		}
	}
}