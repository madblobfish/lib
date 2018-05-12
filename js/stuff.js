// giant collection of functions

Object.prototype[Symbol.iterator] = function*(){
	for(let key in this){
		if (obj.hasOwnProperty(key)) {
			yield { key: key, value: this[key] };
		}
	}
};

function randrep(chars = "äöü"){
	var blah = chars.split("");
	return (i)=>{return i.split("").map((l)=>{
		return blah.indexOf(l) ==-1 ? l : blah[~~(Math.random()*blah.length)];
	}).join("")}
}
function aeiou(bla){return randrep("aeiou")(bla)}
function aeiouäöü(bla){return randrep("äöü")(randrep("aeiou")(bla))}


Uint32Array.prototype.toString = function(){
	var out = "";
	this.forEach(function(e){
		out += String.fromCharCode(e);
	});
	return out;
};

function len(num){return Math.ceil(Math.log(num+1)*Math.LOG10E)}
Object.prototype.swap = function(a,b){
	var x = this[a];
	this[a] = this[b];
	this[b] = x;
	return this;
};
String.prototype.huffmanCode = function(){
	var werte = this.split("").countDistinct(),
		out = {},
		ret = [];

	// toArray()
	Object.keys(werte).forEach(function(key){
		ret.push([werte[key], [key]])
	});
	werte = ret;

	for(var j = 0, l = werte.length-1; j < l; j++){ // heapsort
	for(var i = ~~((werte.length-j)/2) ; i >= 0; i--){
		if( werte[i*2 + 1+j] && werte[i+j][0] > werte[i*2 + 1+j][0] ){ werte.swap(i+j, i*2 + 1+j); }
		if( werte[i*2 + 2+j] && werte[i+j][0] > werte[i*2 + 2+j][0] ){ werte.swap(i+j, i*2 + 2+j); }
	};
	};

	while(werte.length > 1){
		var one = werte.shift(), two = werte.shift();

		one[1].forEach(function(e){
			if(!out[e]){ out[e] = "0" }
			else{ out[e] = "0"+out[e] }
		});
		two[1].forEach(function(e){
			if(!out[e]){ out[e] = "1" }
			else{ out[e] = "1"+out[e] }
		});

		one[0] += two[0];
		one[1] = one[1].concat(two[1]);

		var i = ~~(werte.length/2)

		werte.push(one);
		for(var j = 0, l = werte.length-1; j < l; j++){ // heapsort
		for(var i = ~~((werte.length-j)/2) ; i >= 0; i--){
			if( werte[i*2 + 1+j] && werte[i+j][0] > werte[i*2 + 1+j][0] ){ werte.swap(i+j, i*2 + 1+j); }
			if( werte[i*2 + 2+j] && werte[i+j][0] > werte[i*2 + 2+j][0] ){ werte.swap(i+j, i*2 + 2+j); }
		};
		};
	}
	return out;
}
// not really count distinct but counts the number of occurances
Array.prototype.countDistinct = function(){
	var ret = {};
	this.forEach(function(e){ if(!ret[e]){ ret[e]=1 }else{ ret[e]++ } });
	return ret;
}
Object.prototype.values = function(){
	var ret = [], obj = this;
	Object.keys(obj).forEach(function(key){
		ret.push(obj[key])
	});
	return ret;
}
Object.prototype.equal = function(C){
	var sort = function(o){
		var out = {}, a = [];
		for(var k in o) { if (o.hasOwnProperty(k)) { a.push(k); }	}
		a.sort();
		for(var i = 0; i < a.length; i++){ out[a[i]] = o[a[i]]; }
		return out;
	}
	return JSON.stringify(sort(this)) === JSON.stringify(sort(C));
}
String.prototype.hex2bin = function(){
	var ret = "", length = this.split("").length-1;
	for (var i = 0; i <= length; i++) {
		ret += ( parseInt(this.split("")[length-i],16) + 16 ).toString(2).substr(1);
	};
	return ret;
}
String.prototype.xor = function(that){
	var res = "", length = this.split("").length-1;
	for (var i = 0; i <= length; i++) {
		res += (this.split("")[i] == that.split("")[i]) ? "0" : "1";
	};
	return res;
}
NodeList.prototype.addEventListener = function(t,l){this.forEach(function(e){e.addEventListener(t,l)})};
NodeList.prototype.toArray = function(){
	var arr = [];
	for (var i = 0; i < this.length; i++) {
		arr.push(this[i]);
	};
	return arr;
};
NodeList.prototype.forEach = function(f){for(var i = 0; i < this.length; i++){f(this[i], i, this)}};

HTMLCollection.prototype.last = function(){return this[this.length-1]}
String.prototype.splice = function(n,i){return ( this.substr(0, n) + i + this.substr(n+1) )}
String.prototype.reverse = function(){return this.split("").reverse().join("")}
String.prototype.palindrom = function(){return this==this.reverse()}

Array.prototype.select = function(s){return this.filter(function(e,i){return s & (1<<i)})}
Number.prototype.ldigitsum = function(){return this===0 ? 0 : this%9===0 ? 9 : this%9}
Array.prototype.ldigitsum = function(){return parseInt(this.join("")).ldigitsum()}
// String.prototype.ldigitsum = function(){return parseInt(this).ldigitsum()}
Array.prototype.product = function(){return +this.reduce(function(a,b,i){ return +a + b*(i+1) })}
Number.prototype.product = function(){return this.toString().split("").product()}
Array.prototype.num = function(){return this.reduce(function(a,b){ return a*10 + b })}
Number.prototype.reverse = function(){return parseInt(this.toString().reverse())}
Number.prototype.reduce = function(a){return this.toString().split("").reduce(a)}

function ggt(x,y){
	while( y>1 && x>1 && x != y){
		if(x<y){
			y %= x;
		}else{
			x %= y;
		}
	}
	return (x==1||y==1)? 1 : Math.max(x,y);
}

Number.prototype.numberOfSetBits = function(){
	// works for numbers up to 31bit
	var i = this - ((this >> 1) & 0x55555555);
	i = (i & 0x33333333) + ((i >> 2) & 0x33333333);
	return (((i + (i >> 4)) & 0x0F0F0F0F) * 0x01010101) >> 24;
}

Array.prototype.random = function(){return this[~~(Math.random()*this.length -0.5)]}
NodeList.prototype.random = function(){return this[~~(Math.random()*this.length -0.5)]}
Array.prototype.replace = function(a,b){var x=[];this.forEach(function(e){x.push(e.replace(a,b))});return x;}
