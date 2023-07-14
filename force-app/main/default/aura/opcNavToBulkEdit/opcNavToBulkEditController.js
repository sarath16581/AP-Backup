/**
 * @description Aura wrapper to navigate to bulk edit screen
 * This aura wrapper is required to be put in an url action as LWC is not addressable
 * @author Harry Wang
 * @date 2023-05-09
 * @group Controller
 * @changelog
 * 2023-05-09 - Harry Wang - Created
 */
({
	onPageReferenceChange: function(cmp) {
		let myPageRef = cmp.get("v.pageReference");
		let id = myPageRef.state.c__oppId;
		cmp.set("v.recordId", id);
	}
});