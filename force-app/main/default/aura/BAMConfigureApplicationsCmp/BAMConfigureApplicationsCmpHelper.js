({
	refreshProductsList: function(component, arrProducts)
	{
		// loop through to set a simple active flag
		for(var i = 0; i < arrProducts.length; ++i)
		{
			var product = arrProducts[i];
			var assets = product.Assets;
			product.active = false;
			if(assets && assets.length > 0)
			{
				product.active = true;
			}
		}
		component.set('v.products', arrProducts);
	}

	, filterContacts:function(component)
	{
		var arrFiltered = component.get('v.allContacts');
		var sSearch = component.get('v.contactSearchString');

		if(sSearch) {
			var objRegex = new RegExp("[^,]*"+ sSearch +"[^,]*", 'ig');
			arrFiltered = arrFiltered.filter(function(item){

				var bMatch = (item.Name && item.Name.match(objRegex)) || (item.Email && item.Email.match(objRegex)) || (item.Phone && item.Phone.match(objRegex)) || (item.CNumber && item.CNumber.match(objRegex));
				return bMatch;
			});

		}
		var arrDefault =[];
		arrFiltered = arrDefault.concat(arrFiltered);

		// clear the selection
		component.set('v.contactId', '');
		component.set('v.contactList', arrFiltered);
	}
})