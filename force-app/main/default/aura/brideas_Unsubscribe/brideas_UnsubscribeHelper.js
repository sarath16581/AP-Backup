({
    unsubscribeFromIdea: function(cmp, ideaId) {
        var action = cmp.get('c.unsubscribe');

        action.setParams({
            ideaId: ideaId
        });

        action.setCallback(this, function(response){
            var state = response.getState(),
                resVal = response.getReturnValue();

            if (state === 'SUCCESS' && resVal === true) {
                cmp.set('v.msg', 'You have been successfully unsubscribed from idea');
            } else {
                cmp.set('v.msg', 'Sorry. The request was unsuccessful');
            }
        });

        $A.enqueueAction(action);
    },

    unsubscribeFromAll: function(cmp) {
        var action = cmp.get('c.unsubscribeAll');

        action.setCallback(this, function(response){
            var state = response.getState(),
                resVal = response.getReturnValue();

            if (state === 'SUCCESS' && resVal === true) {
                cmp.set('v.msg', 'You have been successfully unsubscribed from all ideas');
            } else {
                cmp.set('v.msg', 'Sorry. The request was unsuccessful');
            }
        });

        $A.enqueueAction(action);
    }
})