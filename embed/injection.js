var commProt;
var commDelimit;

var setupComm = function(protocol, delimiter){
	commProt = protocol;
	commDelimit = delimiter;
}
var _callAir = function(method, args){
	if(!commProt)return;

	var call = commProt+method+commDelimit+[].join.apply(args, [commDelimit]);
	window.location.href = call;
}
var redirectConsole = function(){

	try{
		if(!console){
			console = {};
		}
	}catch(e){
		console = {};
	}
	console.log = function(){
		_callAir("console.log", arguments);
	}
}
var redirectErrors = function(includeErrors){

	function handler(evt) {
		_callAir("window.onerror", [evt]);
	}


	function addErrorHandler(win, handler){
	  	/*if(win.addEventListener!=null){
			win.addEventListener('error', handler);
		}*/
		win.onerror = handler;
		for(var i=0; i<win.frames.length; i++){
			addErrorHandler(win.frames[i], handler);
		}
	}


	/*function removeErrorHandler(win, handler){
	  	if(win.removeEventListener!=null){
	  		win.removeEventListener('error', handler);
	  	}
		for(var i=0; i<win.frames.length; i++){
			removeErrorHandler(win.frames[i], handler);
		}
	}*/

	setTimeout(function(){
		//removeErrorHandler(window, handler);
		addErrorHandler(window, handler);
	}, 1000);

	addErrorHandler(window, handler);
}