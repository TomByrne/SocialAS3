package social.desc
{
	public class PropDesc
	{
		public var name:String;
		public var desc:String;
		public var optional:Boolean;
		public var defaultValue:*;
		public var value:*;
		
		public function PropDesc(name:String, desc:String, optional:Boolean, defaultValue:*=null)
		{
			this.name = name;
			this.desc = desc;
			this.optional = optional;
			this.defaultValue = defaultValue;
		}
	}
}