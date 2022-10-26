({
    doInit : function(cmp, event, helper) {
        window.scrollTo(0,0);
        helper.buildDataAnalytics(cmp, event, helper);
    },

    nextButtonClicked : function(cmp, event, helper) {
        event.preventDefault();
        $A.enqueueAction(cmp.get('v.nextButtonAction'));
    },

    goBack: function (cmp, event, helper) {
        helper.gotoPrevPage(cmp);
    },

    onRender: function (cmp, event, helper) {
        if (cmp.get('v.checkInputsOnRender')) {
            helper.checkAllInputs(cmp, false);
            cmp.set('v.checkInputsOnRender', false);
        }
    },

    setAnalyticsListener: function(component, event, helper) {  
        window.AP_ANALYTICS_HELPER.listen();
    }
})