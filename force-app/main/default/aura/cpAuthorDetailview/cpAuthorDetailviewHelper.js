({
	fetchAuthorDetails : function(component) {
		var action = component.get("c.GetUserProfileDetails");
        action.setParams({
            "articleId" : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.AuthorDetail", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
	}
})