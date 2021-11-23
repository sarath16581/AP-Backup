({
    toggle : function(cmp, event, helper) {
        cmp.set('v.open', !cmp.get('v.open'));
        var vx = cmp.get("v.selectedIssue");
        var selectedIssue = cmp.get('v.label');

        var selectedIssueTypeEvt = cmp.getEvent("chasSelectedIssueType"); 

        selectedIssueTypeEvt.setParams({
            selectedIssue: selectedIssue
        }).fire();
	}
})