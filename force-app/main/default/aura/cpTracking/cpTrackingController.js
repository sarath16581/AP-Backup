({
	getInput: function(cmp, evt) {
		var mytrackingnumber = cmp.find("trackingnumber").get("v.value");
		var urlEvent = $A.get("e.force:navigateToURL");
		urlEvent.setParams({
			"url": 'https://auspost.com.au/parcels-mail/track.html#/track?id=' + mytrackingnumber
		});
		urlEvent.fire();
	},
	enterTrack: function(component, event, helper) {
		console.log(event.getParams().keyCode);
		if (event.getParams().keyCode == 13) {
			var mytrackingnumber = component.find("trackingnumber").get("v.value");
            var urlEvent = $A.get("e.force:navigateToURL");
			urlEvent.setParams({
				"url": 'https://auspost.com.au/parcels-mail/track.html#/track?id=' + mytrackingnumber
			});
			urlEvent.fire();
		}
	}
})