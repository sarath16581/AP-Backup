({
    reportValidity : function(cmp, event, helper) {
        helper.reportAllInValid(cmp, event);
    },
    
    checkValidity: function (cmp, evt, helper) {
        var allValid =  helper.checkAllValid(cmp, evt);
        return allValid;
    },
    
})