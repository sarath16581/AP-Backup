({
	// URL Addressable component which will be used to pass the selected attachment Ids to the specified destination URL
	// Usage example: /lightning/cmp/c__selectAttachmentsAura?c__id={ParentId}&c__redirect=/lightning/r/{SOBJECT}/{RECORDID}/view
	onPageReferenceChange: function(cmp, evt, helper) {
		var myPageRef = cmp.get("v.pageReference");
		var id = myPageRef.state.c__id;
		cmp.set("v.id", id);
		
		var redirect = myPageRef.state.c__redirect;
		cmp.set("v.redirect", redirect);
	}
})