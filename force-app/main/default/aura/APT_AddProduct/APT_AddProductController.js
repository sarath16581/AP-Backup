({
	doInit: function(component, event, helper) {
		var urlParam = component.get("v.pageReference");
		if(urlParam !=null){
			var recordId = urlParam.state.c__recordId;
			component.set("v.recordId", recordId);
		}

	}
})