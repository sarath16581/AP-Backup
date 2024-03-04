/**
 * @description Aura wrapper to navigate to bulk edit screen
 * This aura wrapper is required to be put in an url action as LWC is not addressable
 * @author Harry Wang
 * @date 2023-05-09
 * @group Controller
 * @changelog
 * 2023-05-09 - Harry Wang - Created
 * 2023-10-17 - Bharat Patel - Updated onPageReferenceChange(), related to STP-9640 implementation
   2024-02-15 - Ken McGuire, Added link to revenue report 
*/
({
	onPageReferenceChange: function(cmp) {
		let myPageRef = cmp.get("v.pageReference");
		let id = myPageRef.state.c__oppId;
		cmp.set("v.recordId", id);
				
		let proposalID = myPageRef.state.c__proposalId;
		cmp.set("v.proposalId", proposalID);

		let isST = myPageRef.state.c__isST;
		cmp.set("v.isST", isST);

		let isManualContract = myPageRef.state.c__isManualContract == undefined ? 'No': myPageRef.state.c__isManualContract;
		cmp.set("v.isManualContract", isManualContract);

		let isAmend = myPageRef.state.c__isAmend  == undefined ? 'No': myPageRef.state.c__isAmend;
		cmp.set("v.isAmend", isAmend);

		let isRenew = myPageRef.state.c__isRenew == undefined ? 'No': myPageRef.state.c__isRenew;
		cmp.set("v.isManualContract", isRenew);
	},
	openRevenueReport : function(component, event, helper) {
		var oppId = component.get("v.recordId"); // Get the Opportunity Id
		var url = "/lightning/cmp/c__opcNavToRevenueReport?c__oppId=" + oppId;
		
		// Open the Aura component in a new tab
		window.open(url, '_blank');
	}
});