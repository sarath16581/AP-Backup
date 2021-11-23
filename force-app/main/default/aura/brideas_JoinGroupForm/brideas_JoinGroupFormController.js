({
    init: function(cmp, event, helper){
        cmp.set('v.isVisible', false);
        helper.retrieveSurveyUrl(cmp);
    },

    cancel: function(cmp){
        cmp.set('v.isVisible', false);
    }
})