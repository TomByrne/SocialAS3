package social.util
{
	public function closure(meth:Function, params:Array, passArgs:Boolean=false):Function{
		if(passArgs){
			return function(... rest):*{
				var args:Array = rest.concat(params);
				return meth.apply(null, args);
			}
		}else{
			return function():*{
				return meth.apply(null, params);
			}
		}
	}
}