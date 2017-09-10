Node.prototype.toJsonml = function(){
	var x = [];
	for(let node of this.childNodes){
		x.push(node.toJsonml());
	}
	var out = {
		"c": x,
		"a": this.attributes ? this.attributes.toObject() : '{}'
	};
	if(this.nodeName == "#text" || this.nodeName == "#comment"){
		out.c = this.textContent;
	}
	return {[this.nodeType || this.nodeName]: out}
}
NamedNodeMap.prototype.toObject = function(){
	var out = {};
	for(var i = 0; i < this.length; i++){
		out[this[i].name] = this[i].value;
	}
	return out;
};
document.toJsonml().toSource()
