/**
 * @description Aura wrapper to navigate to Opportunity Revenue 
 * This aura wrapper is required to be put in an url action as LWC is not addressable
 * @author Ken McGuire
 * @date 2024-02-06
 * @group Controller
 * @changelog
 * 2024-02-06- Ken McGuire - Created
 * 
 */
({
	onPageReferenceChange: function(cmp) {
		let myPageRef = cmp.get("v.pageReference");
		let id = myPageRef.state.c__oppId;
		cmp.set("v.recordId", id);
	}
});