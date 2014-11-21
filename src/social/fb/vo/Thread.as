package social.fb.vo
{
	public class Thread
	{
		public var id:String;
		public var createdTime:Date;
		public var updatedTime:Date;
		public var to:Vector.<User>;
		public var comments:Vector.<Comment>;
		public var unread:int;
		public var unseen:int;
		
		
		public function Thread()
		{
		}
		
		public function set toArr(value:Array):void{
			to = Vector.<User>(value);
		}
		
		public function set commentsArr(value:Array):void{
			comments = Vector.<Comment>(value);
		}
	}
}