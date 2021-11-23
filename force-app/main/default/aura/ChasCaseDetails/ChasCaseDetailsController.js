({
	handleCase : function(cmp, event, helper) {
    	var newStatus = event.getParam("value").Enquiry_Status__c;
    	var colour = cmp.get('v.colourMap')[newStatus];
    	cmp.set('v.statusColour', colour);		
	},

	reloadCase : function(cmp, event, helper) {
		cmp.find('forceRecordCmp').reloadRecord();
	}
})