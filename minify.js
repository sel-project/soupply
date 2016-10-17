
function creative(json) {
	var items = json.items;
	for(var i=0; i<items.length; i++) {
		if(items[i].id == undefined || items[i].name == undefined) items.splice(i, 1);
	}
	return JSON.stringify({"items": items});
}

function constants(json) {
	return JSON.stringify({"constants": json.constants});
}