({
    doInit: function (cmp, event, helper) {
        var action = cmp.get('c.getIdeas');

        action.setParams({
            ideasNumber: cmp.get('v.ideasNumber'),
            pageName: cmp.get('v.pageName')
        });

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS') {
                cmp.set('v.wrapper', response.getReturnValue());
            }
        });

        $A.enqueueAction(action);
    }
})