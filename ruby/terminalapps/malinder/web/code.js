(function(){
// sort oder for states
const states = {
	"seen":5,
	"partly":4,
	"paused":3,
	"want":2,
	"backlog":1,
	"broken":-1,
	"okay":-2,
	"nope":-3,
}
const fav_order = '⭐🩵💩'.split('')
const sort_indicators = {
	"asc":'',
	"desc":'',
	"unsorted":'',
}

let anime = []
let searchKeyUpUpdateTimeout = -1
let mal_input = document.getElementById("nonmal")
let search_input = document.getElementById("regex")
let table = document.getElementById('tbl')

function getSortFields(){
	let list = []
	for(let i = 0; i < 20; i++){
		let elem = document.getElementById('sort-' + i.toString())
		if(!elem){
			break
		}
		list.push(elem)
	}
	return list
}

function loadFilterState(){
	if(document.location.hash.substr(1) == ''){
		return
	}
	try {
		let input = JSON.parse(decodeURI(document.location.hash.substr(1)))
		if(search_input !== document.activeElement){
			search_input.value = input['regex']
		}
		mal_input.checked = input['mal']
		document.querySelectorAll(`#legend input[type="checkbox"]`).forEach((e)=>e.checked = true)
		input['states'].forEach((s)=>{
			document.querySelector(`#legend td.${s} input[type="checkbox"]`).checked = false
		})
		document.querySelectorAll(`th[data-field]`).forEach((e)=>{
			e.children[0].innerText = sort_indicators['unsorted']
		})
		input['sort'].split(',').forEach((s,i)=>{
			if(s == ''){return}
			let elem = document.querySelector(`th[data-field="${s.split('-', 2).at(-1)}"]`)
			elem.children[0].innerText = s.indexOf('-') == -1 ? sort_indicators['desc'] : sort_indicators['asc']
			elem.id = 'sort-' + i
		})
		// console.log('loaded state')
	}catch{
		// failed loading, ignore
		console.log(`loading failed: ${decodeURI(document.location.hash.substr(1))}`)
		document.location.hash = ''
	}
}

function getFilterState(){
	let states = [],
		sort = '',
		regex = search_input.value
		// RegExp(regex, 'i')
	document.querySelectorAll('#legend input[type="checkbox"]').forEach((e)=>{
		e.checked ? [] : states.push(e.parentNode.parentNode.classList[0])
	})
	getSortFields().forEach((e)=>{
		let field = e.getAttribute('data-field')
		if(e.children[0].innerText == sort_indicators['asc']){
			field = '-' + field
		}
		sort += field + ','
	})
	sort = sort.slice(0, -1)
	return {
		mal: mal_input.checked,
		regex,
		sort,
		states
	}
}

function storeFilterState(state = getFilterState()){
	document.location.hash = JSON.stringify(state)
}

function generateTable(state = getFilterState()){
	tmp_anime = [...anime['anime']]
	tmp_anime = tmp_anime.filter((a)=>{
		// console.log(`${a[3]} vs ${state['states'].join(', ')}`); 
		return !!! state['states'].find((s)=>{return a[3].split(',', 2)[0] == s.substr(6)})
	})
	if(state['mal']){
		tmp_anime = tmp_anime.filter((a) => {
			try{
				return a[0].indexOf(',') == '-1'
			}catch{
				return true
			}
		})
	}
	if(state['regex'] != ''){
		// console.log(`regexing: ${state['regex']}`)
		regexp = RegExp(state['regex'], "i")
		tmp_anime = tmp_anime.filter((a) => regexp.test(a[5] ?? '') || regexp.test(a[11] ?? '') || regexp.test(a[12] ?? ''))
		// tmp_anime = tmp_anime.filter(function(a){return regexp.test(a[5] ?? '')});
	}
	console.log(`filtered ${anime['anime'].length - tmp_anime.length} of total: ${anime['anime'].length} (left: ${tmp_anime.length})`)

	if(state['sort'] != ''){
		state['sort'].split(',').reverse().forEach((s)=>{
			// console.log("sortin! " + s)
			let sorts = {
				'state': (a,b)=>{
					a=states[a[3].split(',', 2)[0]],
					b=states[b[3].split(',', 2)[0]];
					return a>b?-1:a<b?1:0
				},
				'name': (a,b)=>{
					a=(a[5]??'').toString(),
					b=(b[5]??'').toString()
					return Math.max(-1,Math.min(1,a.localeCompare(b, 'en', {sensitivity: 'base'})))
				},
				'season': (a,b)=>{
					if(a[1] == b[1]){
						return a[2]>b[2]?1:a[2]<b[2]?-1:0
					}
					return a[1]>b[1]?1:a[1]<b[1]?-1:0
				},
				'rank': (a,b)=>{
					a=a[8] ? parseInt(a[8]) : Infinity,
					b=b[8] ? parseInt(b[8]) : Infinity
					return a<b?-1:a>b?1:0
				},
				'episodes': (a,b)=>{
					a=a[6] ? parseInt(a[6]) : Infinity,
					b=b[6] ? parseInt(b[6]) : Infinity
				    return a<b?-1:a>b?1:0
				},
				'runtime': (a,b)=>{
					ar = a[7] * a[6]
					br = b[7] * b[6]
					return ar>br?-1:ar<br?1:0
				},
				'special': (a,b)=>{
					a = fav_order.indexOf(anime['symbols'][a[0]]?.substr(0, 1))
					b = fav_order.indexOf(anime['symbols'][b[0]]?.substr(0, 1))
					if(a !== -1){a = fav_order.length - a}
					if(b !== -1){b = fav_order.length - b}
				    return a<b?1:a>b?-1:0
				},
			}
			let isreverse = s.indexOf('-') == '-1' ? 1 : -1
			tmp_anime.sort((a,b) => isreverse * sorts[s.split('-', 2).at(-1)](a,b))
		})
	}

	table.innerHTML = "";
	if(tmp_anime.length == 0){
		table.innerHTML = '<tr><td colspan="6" style="text-align:center">Nothing Found, sorry</td></tr>'
		return
	}
	for(var i=0;i<tmp_anime.length;i++){
		let seen=tmp_anime[i][3],
			ep=tmp_anime[i][6],
			tpe=tmp_anime[i][7],
			tr=document.createElement("tr"),
			a=document.createElement("a"),
			td_link=document.createElement("td"),
			td_season=document.createElement("td"),
			td_eps=document.createElement("td"),
			td_time=document.createElement("td"),
			td_rank=document.createElement("td"),
			td_special=document.createElement("td"),
			progress=document.createElement("progress");
			progresslabel=document.createElement("label");

		// tr.id=tmp_anime[i][0];

		let symbol = anime['symbols'][tmp_anime[i][0]]
		if(symbol){
			td_special.innerText = symbol
		}
		tr.appendChild(td_special);

		if(seen){
			state = seen.split(',', 2)[0]
			td_link.classList.add("state-" + state);
		}
		a.href="https://myanimelist.net/anime/" + tmp_anime[i][0];
		if((''+tmp_anime[i][0]).match('imdb,')){
			a.href = "https://www.imdb.com/title/" + tmp_anime[i][0].split(',', 2)[1];
		}
		a.innerText=tmp_anime[i][11] || tmp_anime[i][5];
		if(tmp_anime[i][12]){
			a.innerText += ' / ' + tmp_anime[i][12]
		}
		if(seen&&ep&&seen.split(',', 2)[1]){
			if(!seen.match('\\?|m')){
				progress.innerText=seen.split(',', 2)[1]+" / "+ep;
				progress.value=eval(seen.split(',', 2)[1]);
				progress.max=ep;
				if(progress.value != progress.max){
					a.appendChild(progress)
					progresslabel.innerText = progress.value + "/" + progress.max
					a.appendChild(progresslabel)
				}
			}
		}
		td_link.appendChild(a);
		tr.appendChild(td_link);

		td_season.innerText=(tmp_anime[i][1]|| '-').toString() +' '+ tmp_anime[i][2];
		tr.appendChild(td_season);

		td_rank.innerText=tmp_anime[i][8];
		tr.appendChild(td_rank);

		td_eps.innerText=ep;
		tr.appendChild(td_eps);

		if(tpe&&ep){
			tpe1=(tpe/60)*ep;
			td_time.innerText=tpe1>=300?Math.round(tpe1/60).toFixed(1)+"S":tpe1.toFixed(1)+'m';
			tpe=undefined;
		}
		tr.appendChild(td_time);


		table.appendChild(tr);
	}
}

function inputEventHandler(){
	searchKeyUpUpdateTimeout = -1
	storeFilterState()
}

fetch('/data.json?nocache='+Math.random()).then((r) => r.text()).then((t)=>{
	anime = JSON.parse(t)
	generateTable()
})
loadFilterState()

document.querySelectorAll('th[data-field]').forEach((e)=>{
	e.addEventListener('click', (evt)=>{
		let span = e.children[0],
		    text = span.innerText
		if(text == sort_indicators['asc']){
			span.innerText = sort_indicators['unsorted']
		}else if(text == sort_indicators['desc']){
			span.innerText = sort_indicators['asc']
		}else{
			span.innerText = sort_indicators['desc']
		}

		let list = getSortFields()
		if(e.getAttribute('data-unique') == ''){
			list.forEach((elem)=>{
				if(e != elem){
					elem.children[0].innerText = sort_indicators['unsorted']
					elem.removeAttribute('id')
				}
			})
			list = [e]
		}
		list.unshift(e)
		list = [...new Set(list)]
		list.forEach((elem)=>{elem.removeAttribute('id')})
		if(span.innerText == sort_indicators['unsorted']){
			list.shift()
		}
		for(var i = 0; i < list.length; i++){
			list[i].id = 'sort-' + i
		}
		inputEventHandler()
	})
})

document.querySelectorAll(`#legend input[type="checkbox"]`).forEach((e)=>{
	e.addEventListener("click", inputEventHandler)
})
document.getElementById("nonmal").addEventListener("click", inputEventHandler)
document.getElementById("filter").addEventListener("click", inputEventHandler)
window.addEventListener('hashchange', ()=>{
	loadFilterState()
	generateTable()
})

search_input.addEventListener("search", inputEventHandler)
search_input.addEventListener('keyup', ()=>{
	if(searchKeyUpUpdateTimeout !== -1){
		window.clearTimeout(searchKeyUpUpdateTimeout)
	}
	searchKeyUpUpdateTimeout = window.setTimeout(inputEventHandler, 150)
})

// I'm sorry no eval here
function eval(str){let a = str.split("+", 2); return +a[0] + (a[1]||0)}
})()
