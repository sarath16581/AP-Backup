({
	doInit: function(cmp) {
		var myPageRef = cmp.get("v.pageReference");
		cmp.set("v.existingContractId", myPageRef.state.c__existingContractId);
		cmp.set("v.currentStatus", myPageRef.state.c__currentStatus);
		cmp.set("v.proposalId", myPageRef.state.c__proposalId);
		cmp.set("v.isST", myPageRef.state.c__isST);
		cmp.set("v.isManualContract", myPageRef.state.c__isManualContract);
	},
	onPageReferenceChanged: function() {
		$A.get('e.force:refreshView').fire(); //refresh cache
	}
})