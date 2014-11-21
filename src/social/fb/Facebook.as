package social.fb
{
	import social.social;
	

	public class Facebook extends AbsFacebook
	{
		public function Facebook(permissions:Array, apiVersion:String=null, castObjects:Boolean=true)
		{
			
			super("Facebook", permissions, apiVersion, castObjects);
			
		}
	}
}