({
    retrieveIdeasCount: function(cmp) {
        var action = cmp.get('c.getIdeasCountForUser');

        action.setParams({
            userId: cmp.get('v.recordId')
        });

        action.setStorable();

        action.setCallback(this, function(response){
            var state = response.getState(),
                respVal = response.getReturnValue();

            if (state === 'SUCCESS') {
                cmp.set('v.ideasNumber', respVal);
            }
        });

        $A.enqueueAction(action);
    },

    retrieveIdeaCommentsCount: function(cmp) {
        var action = cmp.get('c.getIdeaCommentsCountForUser');

        action.setParams({
            userId: cmp.get('v.recordId')
        });

        action.setStorable();

        action.setCallback(this, function(response){
            var state = response.getState(),
                respVal = response.getReturnValue();

            if (state === 'SUCCESS') {
                cmp.set('v.ideaCommentsNumber', respVal);
            }
        });

        $A.enqueueAction(action);
    },

    retrieveVotesCount: function(cmp) {
        var action = cmp.get('c.getIdeaVotesCountForUser');

        action.setParams({
            userId: cmp.get('v.recordId')
        });

        action.setStorable();

        action.setCallback(this, function(response){
            var state = response.getState(),
                respVal = response.getReturnValue();

            if (state === 'SUCCESS') {
                cmp.set('v.votesNumber', respVal);
            }
        });

        $A.enqueueAction(action);
    }
})