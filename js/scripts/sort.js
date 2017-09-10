/* jslint
	esversion: 6
*/

// sorts a table for some website
(function sort(){
	let list = Array.prototype.slice.call(document.querySelectorAll(".list-item"));
	list = list.sort((a, b)=>{
		let strA = a.firstElementChild.firstElementChild.firstElementChild.nextSibling.textContent.split("(")[1];
		let strB = b.firstElementChild.firstElementChild.firstElementChild.nextSibling.textContent.split("(")[1];
		if(!strA){
			console.log(strA);
			console.log(strB);
			if(!strB){
				return 0;
			}
			return strB.localeCompare(strA);
		}
		return strA.localeCompare(strB);
	});

	for(let listElement of list){
		listElement.parentNode.appendChild(listElement);
	}
})();

