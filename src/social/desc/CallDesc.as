package social.desc
{
	import social.core.IUrlProvider;

	public class CallDesc
	{
		public var gatewayId:String;
		public var callId:String;
		public var args:Vector.<ArgDesc>;
		public var desc:String;
		public var url:IUrlProvider;
		public var protocol:String;
		public var resultHandler:Function;
		public var availableState:String;
		
		public function CallDesc(gatewayId:String, callId:String, availableState:String, args:Array, url:IUrlProvider, desc:String, resultHandler:Function, protocol:String)
		{
			this.gatewayId = gatewayId;
			this.callId = callId;
			this.availableState = availableState;
			this.args = Vector.<ArgDesc>(args);
			this.url = url;
			this.desc = desc;
			this.protocol = protocol;
			this.resultHandler = resultHandler;
		}
	}
}