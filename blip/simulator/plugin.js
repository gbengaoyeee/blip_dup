(function(document,window,undefined){
	'use strict';
	function lib(){
		var el = arguments[0];
		var options = {};
		var fragment = null;
		var child = null;
		var aux = null;
		var regExps = {
			element: /^<?([a-zA-Z]+)?(?:(?:\sid\=\"|#)([a-zA-Z]+)\"?)?(?:(?:\sclass\=\"|\.)([a-zA-Z\s\.]+)\"?)?>?/,
		};
		try{
			if(arguments.length <= 2){
				if(!Array.isArray(arguments[1]) && typeof arguments[1] != 'string'){
					options = arguments[1];
				}else if(typeof arguments[1] == 'object' && Object.values(arguments[1]).length === 0){
					child = arguments[1];
				}else{
					fragment = arguments[1];
				}
			}else{
				options = arguments[1];
				if(typeof arguments[2] == 'object' && Object.values(arguments[2]).length === 0){
					child = arguments[2];
				}else{
					fragment = arguments[2];
				}
			}
			if (typeof el != 'string'){
				throw (new Error('First parameter must be a string'));
			}
			if (typeof options != 'object' && options !== undefined){
				throw (new Error('Badly declared element options'));
			}		
		}catch(err){
			print(err,3);
		}

		if(el.indexOf('<') != -1 || el.indexOf('#') != -1 || el.indexOf('.') != -1){
			aux = regExps.element.exec(el);
			
			el = aux[1] ? aux[1] : 'div';
			options.id = options.id ? options.id : aux[2] ? aux[2] : "";
			options.class = options.class ? options.class : aux[3] ? aux[3].split('.') : "";;
		}

		options = merge({
			id: "",
			class: "",
			data: {},
			attr: {},
			on:{},
			style:{},
			HTMLValid: false,
		},options);

		var HTMLValidElements = ['div','p','span'];

		if(fragment){
			if(Array.isArray(fragment)){
				var DF = document.createDocumentFragment();
				for(var i = 0; i < fragment.length; i++){
					DF.appendChild(fragment[i]);
				}
			}else{
				var DF = document.createTextNode(fragment);
			}
		}
		//TODO parsear string

		var $el = document.createElement(el);

		if(child){
			$el.appendChild(child);
		}

		if(options.id != "")$el.id = options.id;
		if(options.class != ""){
			if(Array.isArray(options.class)){
				for(var i in options.class){
					$el.classList.add(options.class[i]);
				}
			}else{
				$el.classList.add(options.class);
			}
		}
		if(DF !== undefined) $el.appendChild(DF);
		if(!empty(options.on)) bindEvents($el,options.on);
		if(!empty(options.style)) setStyles($el,options.style);
		if(!empty(options.attr)) setAttributes($el,options.attr);
		if(!empty(options.data)) setData($el,options.data);

		return $el;

	}

	var k = lib;

	function bindEvents($el,evts){
		for(var event in evts){
			$el['on'+event] = evts[event];
		}
	}

	function setStyles($el,styles){
		var final = "";
		for(var style in styles){
			final += style +':'+styles[style]+';';
		}
		$el.setAttribute('style',final);
	}

	function setAttributes($el,attributes){
		for(var attr in attributes){
			$el.setAttribute(attr,attributes[attr]);
		}
	}

	function setData($el,data){
		for(var key in data){
			$el.dataset[key] = data[key];
		}
	}

	function empty(obj){
		if(Object.keys(obj).length === 0) return true;
		else return false;
	}

	function merge(obj1,obj2){
		for(var prop in obj2){
			if(obj1.hasOwnProperty(prop)){
				obj1[prop] = obj2[prop];
			}
		}
		return obj1;
	}

	function print(log,t){
		t = isNaN(t) ? 0 : t;
		switch(t){
			case 0:
				console.log(log);
			return;
			case 1:
				console.info(log);
			return;
			case 2:
				console.warn(log);
			return;
			case 3:
				console.error(log);
			return;
		}
	}

	function mount($mountPoint,$el){
			if(typeof $mountPoint == 'string'){
			$mountPoint = document.querySelector($mountPoint);
		}
		$mountPoint.appendChild($el);
		return $el;
	}

	k.mount = mount;

	window.k = k;

})(document,window)