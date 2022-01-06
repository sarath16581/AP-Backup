({
    init: function(cmp){
        var action = cmp.get('c.getUserDisplayName');

        action.setParams({
            userId: cmp.get('v.userId')
            });
        action.setStorable();
        action.setCallback(this, function(response) {
                var state = response.getState(),
                    resVal = response.getReturnValue();

                if (state === 'SUCCESS') {
                    cmp.set('v.displayName', resVal);
                }
            });

        $A.enqueueAction(action);
    }
})