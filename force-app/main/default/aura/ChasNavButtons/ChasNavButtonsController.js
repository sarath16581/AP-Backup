({
    nextClicked : function(cmp, event, helper) {
        event.preventDefault();
        $A.enqueueAction(cmp.get('v.nextAction'));
    },

    handleSpinner : function(cmp, event, helper) {
        if (cmp.get('v.loading')) {
            var submitBtn = cmp.find("nextButton");
            submitBtn.set('v.label', "Sending...");
            $A.util.removeClass(submitBtn, 'disabled-false');
            $A.util.addClass(submitBtn, 'disabled-true');
            $A.util.addClass(submitBtn, 'loading-true');
        }
    }
})