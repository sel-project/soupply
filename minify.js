
function minify(json) {
	function minifyObject(object){
		// removes elements which key starts with two underscore
		for(var property in object) {
			if(object.hasOwnProperty(property)) {
				if(property.startsWith("__")) {
					delete object[property];
				} else if(typeof(object[property]) == "object") {
					object[property] = minifyObject(object[property]);
				}
				//TODO remove empty objects
			}
		}
		return object;
	}
	return JSON.stringify(minifyObject(json));
}
