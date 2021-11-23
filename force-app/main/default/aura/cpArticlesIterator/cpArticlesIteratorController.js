({
	doInit : function(component, event, helper) {
        var knowledgeArticleObject = component.get("v.Article");
        component.set('v.routeInput', {recordId: knowledgeArticleObject.Id});
    }
},
    
	redirectToDetailPage : function(component, event, helper) {
        
        var knowledgeArticleObject = component.get("v.Article");
    	var navEvt = $A.get("e.force:navigateToSObject");
    	navEvt.setParams({
     	 "recordId": knowledgeArticleObject.Id
    	});
    	navEvt.fire();
	},
})