//small tracker, tracks you and logs to console
/* jslint
	esversion:6
*/
(function(window){
	[
		'click',
		'mousedown',
		'mouseup'
	].forEach( function(type){
		window.addEventListener(type, tracker, true);
	});
	let clickEvents = [];

	function tracker(evt){
		//console.log(evt)
		let clickEvent = {
			'target': getQuerySelector(evt.target),
			'time': Date.now(),
			'eventType': evt.type
		};
		clickEvents.push(clickEvent);

		console.log(clickEvent);
	}

	function siblingPosition(node) {
		let i = 1;
		while((node = node.previousSibling)){
			if(node.nodeType == 1){
				i+= 1;
			}
		}
		return i;
	}

	function getQuerySelector(node) {
		if(node.id){
			return "#" + node.id;
		}
		if(node.nodeName == "BODY"){
			return "body";
		}
		let position = siblingPosition(node);
		return (getQuerySelector(node.parentNode) + ">:nth-child("+ position +")");
	}
})(window);
