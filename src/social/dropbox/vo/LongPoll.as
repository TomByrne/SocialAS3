package social.dropbox.vo
{
	public class LongPoll
	{
		public var changes:Boolean;
		public var backoff:int; // secs
		
		public function LongPoll()
		{
		}
	}
}