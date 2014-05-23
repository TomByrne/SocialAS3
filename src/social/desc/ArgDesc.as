package social.desc
{
	public class ArgDesc
	{
		public var desc:String;
		public var name:String;
		public var optional:Boolean;
		public var def:*;
		public var type:Class;
		
		public function ArgDesc(name:String, desc:String, optional:Boolean, def:*, type:Class=null)
		{
			this.desc = desc;
			this.name = name;
			this.optional = optional;
			this.def = def;
			this.type = type;
		}
	}
}