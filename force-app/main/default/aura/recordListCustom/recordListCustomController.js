({
    doInit: function(cmp) {
		cmp.set("v.calculatedListView", cmp.get("v.listViewAPIName")); 
		
		var mobileListView = cmp.get("v.mobileListViewAPIName");
		console.log(mobileListView);
		if (mobileListView && document.documentElement.clientWidth < 1280) {
			cmp.set("v.calculatedListView", mobileListView); 
		}
	}
})