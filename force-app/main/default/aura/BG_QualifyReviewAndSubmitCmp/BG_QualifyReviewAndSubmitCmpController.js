({
	doInit : function(cmp, event, helper) {
         //helper.fetchPickListValues(cmp, 'Lead', 'Product__c', 'apiNames', 'v.options') ;
	},
    reportValidity : function(cmp, event, helper) {
        helper.reportAllInValid(cmp, event);
    },
    
    checkValidity: function (cmp, evt, helper) {
        var allValid =  helper.checkAllValid(cmp, evt);
        return allValid;
    },
	
})