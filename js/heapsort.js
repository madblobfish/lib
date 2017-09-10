function Radix(a){
	var arr = a ? a : [];
	this.out = function(){return arr};
	this.set = function(a){return arr=a};
	this.join = function(a){return arr.join(a)};
	this.toString = function(){return arr.join()};
	this.sort = function(){
		var max = Math.max.apply(null, arr),
			len = ~~Math.log10(max) +1,
			temp,
			keys;
		for (var i = len - 1; i >= 0; i--) {
			temp = {};
			for(var j = 0; j < arr.length; j++){
				var x = ~~(arr[j]/Math.pow(10,len-i-1))%10;
				if(temp[x] == undefined){ temp[x] = [arr[j]] }
				else{ temp[x].push(arr[j]) }
			};
			keys = Object.keys(temp);
			arr = [];
			for(var k = 0; k < keys.length; k++){
				for (var j = 0; j < temp[keys[k]].length; j++) {
					arr.push(temp[keys[k]][j])
				};
			};
		};
		return arr;
	};
};
Radix.test = function(){
	var temp = new Radix([11,21,61,54,99,11,9,2]);
	if(temp.sort().join() !== "2,9,11,11,21,54,61,99"){return false;}
	if(temp.sort().join() !== "2,9,11,11,21,54,61,99"){return false;}
	return true;
};


function Heap(a){
	var arr = a ? a : [];
	// inplace heapsort on Array
	this.out = function(){return arr};
	this.set = function(a){return arr=a};
	this.join = function(a){return arr.join(a)};
	this.toString = function(){return arr.join()};
	this.heapify = function(start){
		var start = start ? start : 0;
		for(var i = ~~((arr.length-start)/2) ; i >= 0; i--){
			if( arr[i+start] > arr[i*2+1+start] ){ this.swap(i+start, i*2+1+start); }
			if( arr[i+start] > arr[i*2+2+start] ){ this.swap(i+start, i*2+2+start); }
		};
		return arr;
	};
	this.swap = function(x,y){var temp = arr[x]; arr[x] = arr[y]; arr[y] = temp;return arr;};
	this.sort = function(){
		for(var i = 0, l = arr.length-1; i < l; i++){
			this.heapify(i);
		};
		return arr;
	};
};
Heap.test = function(){
	var test = new Heap([1,2,3,7,255,13]);
	// sort() modifies the array therefore test is not the same the second time
	if(test.sort().join(',') !== '1,2,3,7,13,255'){ return false }
	if(test.sort().join(',') !== '1,2,3,7,13,255'){ return false }
	return true;
};

// Array.prototype implementation
Array.prototype.swap = function(a,b){
	var x = this[a];
	this[a] = this[b];
	this[b] = x;
	console.log('swap '+a+" & "+b);
	return this;
};
Array.prototype.heapSort = function(){
	for(var j = 0, l = this.length-1; j < l; j++){
		for(var i = ~~((this.length-j)/2) ; i >= 0; i--){
			if( this[i+j] > this[i*2 + 1+j] ){ this.swap(i+j, i*2 + 1+j); }
			if( this[i+j] > this[i*2 + 2+j] ){ this.swap(i+j, i*2 + 2+j); }
		};
	};
	return this;
};
Array.prototype.heapSort = function(){
	for(var j = 0, l = this.length-1; j < l; j++){
		var len = ~~((this.length-j)/2);
		if( len%2 ){ //ungerade
			for(var i = len ; i >= 0; i--){
				console.log( (i+j) + ': ' + (i*2 + 1+j) + " & " + (i*2 + 2+j) );
				if(i == len){
					if( this[i+j] > this[i*2 + 1+j]){ this.swap(i+j, i*2 + 1+j) }
				}else{
					if( this[i+j] > this[i*2 + 1+j] && this[i*2 + 1+j] <= this[i*2 + 2+j] ){ this.swap(i+j, i*2 + 1+j); }
					else if( this[i+j] > this[i*2 + 2+j] ){ this.swap(i+j, i*2 + 2+j); }
				}
			};
		}else{ //gerade
			for(var i = len ; i >= 0; i--){
				console.log( (i+j) + ': ' + (i*2 + 1+j) + " & " + (i*2 + 2+j) );
				if( this[i+j] > this[i*2 + 1+j] && this[i*2 + 1+j] <= this[i*2 + 2+j] ){ this.swap(i+j, i*2 + 1+j); }
				else if( this[i+j] > this[i*2 + 2+j] ){ this.swap(i+j, i*2 + 2+j); }
			};
		}
		console.log(this);
		console.log(j);
	};
	return this;
};