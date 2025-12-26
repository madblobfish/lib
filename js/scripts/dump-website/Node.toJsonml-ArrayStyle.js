Node.prototype.toJsonml = function(){
	if(Object instanceof(DocumentType)){
		return "";
	}

	var x = [];
	const content = 0;
	const attributes = 1;
	for(let node of this.childNodes){
		x.push(node.toJsonml());
	}
	var out = [];
	if(x.length > 0){
		out[content] = x
	}
	if(this.attributes && this.attributes.length > 0){
		out[attributes] = this.attributes.toObject()
	}
	if(this.nodeName == "#comment" || this.nodeName == "#text"){
		out[content] = this.textContent
	}
	return [this.localName || this.nodeName, out]
}
NamedNodeMap.prototype.toObject = function(){
	var out = {};
	for(var i = 0; i < this.length; i++){
		out[this[i].name] = this[i].value;
	}
	return out;
};
document.toJsonml().toSource()