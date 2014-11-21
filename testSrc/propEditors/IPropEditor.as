package propEditors
{
	import flash.display.DisplayObject;
	
	import social.desc.ArgDesc;

	public interface IPropEditor
	{
		function get display():DisplayObject;
		function setArg(arg:ArgDesc):void;
		
		function validate():Boolean;
		function hasValue():Boolean;
		function getValue():*;
	}
}