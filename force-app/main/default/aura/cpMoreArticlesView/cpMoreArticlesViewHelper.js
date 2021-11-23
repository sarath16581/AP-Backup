({
	fetchMoreArticles : function(component) {
        var pageSize = component.get("v.cppageSize");
		var action = component.get("c.getMoreArticles");
        action.setParams({
            "articleId" : component.get("v.recordId"),
            "noOfRecordsTofetch" : pageSize 
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.KnowledgeArticles", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
	}
})