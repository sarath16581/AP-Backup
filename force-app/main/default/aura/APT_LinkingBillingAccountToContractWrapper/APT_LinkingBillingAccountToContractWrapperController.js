({
	doInit: function(cmp, evt, helper) {
		console.log('aura: init');
        var myPageRef = cmp.get("v.pageReference");
        var recordId = myPageRef.state.c__recordId;
        cmp.set("v.recordId", recordId);
	},
    onPageReferenceChanged: function(cmp, event, helper) {
        $A.get('e.force:refreshView').fire(); //refresh cache
    }
})