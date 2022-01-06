({
    flag: function (cmp) {
        var action = cmp.get('c.setFlagOnIdeaComment');

        action.setParams({
				'commentId' : cmp.get('v.comment.ideaComment.Id')
        });
        action.setCallback(this, function(resp) {
            var state = resp.getState(),
                respVal = resp.getReturnValue();

            if (state === 'SUCCESS' || respVal === true) {
                cmp.set('v.comment.Flagged', true);
            } else {
                //TODO: handle error
            }
        });

        $A.enqueueAction(action);
    }
})