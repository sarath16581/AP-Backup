({
    doInit: function(cmp) {
        var action = cmp.get('c.getRelatedIdeasToIdea');

        action.setParams({
            currentIdea: cmp.get('v.currentIdea')
        });

        action.setStorable();

        action.setCallback(this, function(response){
            var state = response.getState(),
                returnVal = response.getReturnValue();

            if (state === 'SUCCESS') {
                cmp.set('v.relatedIdeas', returnVal);
            }
        });

        $A.enqueueAction(action);
    },

    openIdea: function(cmp, event) {
        var navEvt = $A.get('e.force:navigateToSObject');
        navEvt.setParams({'recordId': event.target.id});
        navEvt.fire();
    }
})