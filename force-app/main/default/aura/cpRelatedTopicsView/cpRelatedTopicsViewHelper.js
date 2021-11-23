({
	fetchRelatedTopics : function(component) {
        var pageSize = component.get("v.cppageSize");
		var action = component.get("c.getrelatedTopics");
        action.setParams({
            "articleId" : component.get("v.recordId"),
            "noOfRecordsTofetch" : pageSize 
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.RelatedTopics", response.getReturnValue());
            }
            if(response.getReturnValue() == null){
                var cmpTarget = component.find('TaggedTopicHeader');
        		$A.util.addClass(cmpTarget, 'slds-hide');
                var hrLine = component.find('TaggedTopicHrLine');
        		$A.util.addClass(hrLine, 'slds-hide');
                
            }
        });
        $A.enqueueAction(action);
	}
})