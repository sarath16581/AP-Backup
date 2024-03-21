({
	onPageReferenceChange: function(cmp, evt, helper) {
		var myPageRef = cmp.get("v.pageReference");
		var id = myPageRef.state.c__id;
		cmp.set("v.id", id);
	},
	ok : function(cmp, evt, helper)
	{
		var navEvt = $A.get("e.force:navigateToSObject");
		navEvt.setParams({"recordId": cmp.get("v.id")});
		navEvt.fire();
	},
})