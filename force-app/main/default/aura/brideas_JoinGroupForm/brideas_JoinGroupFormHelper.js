({
    retrieveSurveyUrl: function(cmp) {
        var action = cmp.get('c.getSurveyURL');

        action.setCallback(this, function(resp) {
            var state = resp.getState(),
                resVal = resp.getReturnValue();

            if (state === 'SUCCESS') {
                cmp.set('v.targetURL', resVal);
            }
        });

        $A.enqueueAction(action);
    }
})