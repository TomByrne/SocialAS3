package social.dropbox.vo
{
	public class User
	{
		public var id:int;
		public var email:String;
		public var referralLink:String;
		public var displayName:String;
		public var country:String;
		public var team:Team;
		
		// Array of file extensions, e.g. [".bmp", ".cr2", ".gif"]
		public var allowedFileTypes:Array;
		
		// The user's used quota outside of shared folders (bytes).
		public var quotaNormal:int;
		
		// The user's used quota in shared folders (bytes)
		public var quotaShared:int;
		
		// The user's used quota in datastores (bytes)
		public var quotaDatastores:int;
		
		// The user's total quota allocation (bytes)
		public var quota:int;
		
		public function User()
		{
		}
	}
}