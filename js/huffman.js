Object.prototype.swap = function(a,b){
	var x = this[a];
	this[a] = this[b];
	this[b] = x;
	return this;
};
Object.prototype.turn = function(){
	var out = {}, obj = this;
	Object.keys(obj).forEach(function(k){ out[obj[k]] = k; });
	return out;
};
Array.prototype.countDistinct = function(){
	var ret = {};
	this.forEach(function(e){
		if(!ret[e]){ ret[e]=1 }
		else{ ret[e]++ } });
	return ret;
}
String.prototype.huffmanCode = function(){
	var count = this.split("").countDistinct(),
		out = {},
		stuff = [];

	Object.keys(count).forEach(function(k){ stuff.push([count[k], [k]]) });

	for(var j = 0, l = stuff.length-1; j < l; j++){ // heapsort
		for(var i = ~~((stuff.length-j)/2) ; i >= 0; i--){
			if( stuff[i*2 + 1+j] && stuff[i+j][0] > stuff[i*2 + 1+j][0] ){ stuff.swap(i+j, i*2 + 1+j); }
			if( stuff[i*2 + 2+j] && stuff[i+j][0] > stuff[i*2 + 2+j][0] ){ stuff.swap(i+j, i*2 + 2+j); }
		}
	}

	while(stuff.length > 1){
		var one = stuff.shift(),
			two = stuff.shift(),
			num = function(d){return function(e){
				if(!out[e]){ out[e] = d }
				else{ out[e] = d+out[e] }
			}};

		one[1].forEach(num("0"));
		two[1].forEach(num("1"));

		one[0] += two[0];
		one[1] = one[1].concat(two[1]);

		stuff.push(one);
		for(var j = 0, l = stuff.length-1; j < l; j++){ // heapsort
			for(var i = ~~((stuff.length-j)/2) ; i >= 0; i--){
				if( stuff[i*2 + 1+j] && stuff[i+j][0] > stuff[i*2 + 1+j][0] ){ stuff.swap(i+j, i*2 + 1+j); }
				if( stuff[i*2 + 2+j] && stuff[i+j][0] > stuff[i*2 + 2+j][0] ){ stuff.swap(i+j, i*2 + 2+j); }
			}
		}
	}
	return out;
}
function HuffmanEncode(coding, string){
	var pre = "",
		out = "",
		b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".split("");
	string.split("").forEach(function(e){
		if(coding[e]){ pre += coding[e]; }
		else{ pre += "?"; }
	});
	for(var i = 0, l = ~~(pre.length/6 +1); i < l; i++){
		out += b64[parseInt(pre.substr(i*6, 6), 2)];
//		console.log( pre.substr(i*6, 6) +": "+ parseInt(pre.substr(i*6, 6), 2) +" = "+ b64[parseInt(pre.substr(i*6, 6), 2)]);
	}
	return out;
}
function HuffmanDecode(coding, string){
	var pre = "",
		out = ""+string, //makes string modifiyable
		coding = coding.turn(),
		b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".split(""),
		i,
		match;

	for(var i = 0, l = out.length-1; i < l; i++){
		pre += (b64.indexOf(out[i]) +64 ).toString(2).substr(1);
	}
	pre += b64.indexOf(out[out.length-1]).toString(2);

//	console.log(pre);
	out = "";
	i = 0;
	while(pre.length > 0){
		i++;
		if(match = coding[pre.substr(0, i)]){
//			console.log(match +": "+ pre.substr(0, i));
			out += match;
			pre = pre.substr(i);
			i = 0;
		}
		if(i>500){ break; }
	}
	return out;
}