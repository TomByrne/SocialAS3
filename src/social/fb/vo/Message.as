package social.fb.vo
{
	public class Message
	{
		public var id:String;
		public var createdTime:Date;
		public var from:User;
		public var message:String;
		public var to:Vector.<User>;
		
		
		public function Message()
		{
		}
		
		public function set toArr(value:Array):void{
			to = Vector.<User>(value);
		}
	}
}