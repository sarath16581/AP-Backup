({
    updateValue : function(cmp, event, helper) {
        cmp.set('v.value', event.target.value);
    },

    searchClicked : function(cmp, event, helper) {
        event.preventDefault();
        $A.enqueueAction(cmp.get('v.onclick'));
    }
})