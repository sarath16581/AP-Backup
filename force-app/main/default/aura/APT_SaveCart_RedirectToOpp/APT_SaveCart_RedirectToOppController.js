({
	doInit: function (component, event, helper) {
		let saveOppProductPageRef = component.get("v.pageReference");
		var recordId = saveOppProductPageRef.state.c__oppId;
		component.set("v.recordId", recordId);
	}
})