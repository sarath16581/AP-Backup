({
    doInit: function(cmp) {
		const maxWidth = 1280; 
		const mobileListView = cmp.get("v.mobileListViewAPIName");
		
		// Default - use the full Desktop list view
		cmp.set("v.calculatedListView", cmp.get("v.listViewAPIName")); 
		
		// If the viewport is < 1280px, use the specified mobile list view 
		if (mobileListView && document.documentElement.clientWidth < maxWidth) {
			cmp.set("v.calculatedListView", mobileListView); 
		}
	}
})