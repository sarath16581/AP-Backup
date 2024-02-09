({
	onPageReferenceChange: function(cmp, evt, helper) {
		var myPageRef = cmp.get("v.pageReference");
		var id = myPageRef.state.c__id;
		cmp.set("v.id", id);
		
		var redirect = myPageRef.state.c__redirect;
		cmp.set("v.redirect", redirect);
	}
})