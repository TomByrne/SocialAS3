package social.util
{
	import flash.utils.Dictionary;
	
	import org.osflash.signals.Signal;

	public class StateObject
	{
		private var _state:String;
		private var _stateIndex:int = -1;
		private var _states:Vector.<String>;
		private var _queueMap:Dictionary = new Dictionary();
		private var _stateChanged:Signal;
		
		public function get stateChanged():Signal{
			return _stateChanged;
		}
		
		public function get state():String{
			return _state;
		}
		public function set state(value:String):void{
			stateIndex = _states.indexOf(value);
		}
		
		public function get stateIndex():int{
			return _stateIndex;
		}
		public function set stateIndex(value:int):void{
			if(_stateIndex==value)return;
			
			_stateIndex = value;
			_state = _states[value];
			
			var calls:Array = _queueMap[_state];
			if(calls){
				for each(var pendingCall:PendingCall in calls){
					pendingCall.meth.apply(null, pendingCall.params);
				}
				delete _queueMap[_state];
			}
			
			_stateChanged.dispatch();
		}
		
		public function StateObject(states:Array, initial:String = null)
		{
			_states = Vector.<String>(states);
			_stateChanged = new Signal();
			this.state = initial;
		}
		
		public function queue(state:String, meth:Function, params:Array=null):void{
			if(_state==state){
				meth.apply(null, params);
				return;
			}
			var pendingCall:PendingCall = new PendingCall(meth, params);
			var calls:Array = _queueMap[state];
			if(!calls){
				_queueMap[state] = [pendingCall];
			}else{
				calls.push(pendingCall);
			}
		}
		public function clearQueued(state:String = null):void{
			if(state){
				delete _queueMap[state];
			}else{
				_queueMap = new Dictionary();
			}
		}
	}
}
class PendingCall{
	public var meth:Function;
	public var params:Array;
	
	public function PendingCall(meth:Function, params:Array){
		this.meth = meth;
		this.params = params;
	}
}