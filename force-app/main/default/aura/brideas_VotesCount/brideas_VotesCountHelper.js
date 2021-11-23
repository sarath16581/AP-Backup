({
    loadVotesNumber: function(cmp){
        var action = cmp.get('c.getIdeaVotesCount');

        action.setParams({
            ideaId: cmp.get('v.ideaId')
        });

        action.setCallback(this, function(response){
            var state = response.getState(),
                responseData = response.getReturnValue();

            if (state === "SUCCESS") {
                cmp.set('v.votesCount', responseData);
            }
        });

        $A.enqueueAction(action);
    }
})