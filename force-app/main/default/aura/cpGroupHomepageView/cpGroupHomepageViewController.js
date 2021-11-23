({
	doInit : function(component, event, helper) {
        var pageSize = component.get("v.cppageSize");
        var groupVisibility = component.get("v.cpGroupVisibility");
		helper.fetchChatterGroups(component, pageSize, groupVisibility);
	},
    
    viewMore : function(component, event, helper) {
        var conversationPageId = component.get("v.cpConversationPageId");
        console.log('from Group Home page conversation Page Id==>'+conversationPageId);
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": "/group/CollaborationGroup/00B90000004PBOdEAO"
        });
        urlEvent.fire();
	},
})