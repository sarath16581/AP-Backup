({
    doInit: function (cmp, event, helper) {
        var idea = cmp.get('v.item.item'),
            shortBody = helper.cutText(idea.Body, 300);

        cmp.set('v.routeInput', {recordId: idea.Id});
        cmp.set('v.shortBody', shortBody);

        if (typeof idea.Categories === 'string' && idea.Categories !== '') {
            cmp.set('v.Categories', idea.Categories.replace(new RegExp(';', 'g'), ' | '));
        }

        if (idea.isNew) {
            cmp.set('v.isCreated', true);
        }
    },

    openIdea: function (cmp) {
        var navEvt = $A.get('e.force:navigateToSObject');
        navEvt.setParams({'recordId': cmp.get('v.item.item.Id')});
        navEvt.fire();
    },

    openIdeaAddComment: function (cmp, event) {
        var authorizationMessage = $A.get('$Label.c.msgAuthorizationRequired');
        var action = cmp.get('c.getUserTypeInfo');
        
        action.setCallback(this, function(response) {
            var respVal = response.getReturnValue();
            if (respVal === 'auth_required') {
                var errEvt = cmp.getEvent('ideasErrorEvent');
                errEvt.setParams({'type': 'auth_required', 'message': authorizationMessage});
                errEvt.fire();
            }else{
                var urlEvent = $A.get('e.force:navigateToURL');
                urlEvent.setParams({'url': '/idea/' + cmp.get('v.item.item.Id') + '#commentadd', 'isredirect': false});
                urlEvent.fire();
            }
        });
        $A.enqueueAction(action);
        
    },

    openIdeaComments: function (cmp, event) {
        var urlEvent = $A.get('e.force:navigateToURL');
        urlEvent.setParams({'url': '/idea/' + cmp.get('v.item.item.Id') + '#comments', 'isredirect': false});
        urlEvent.fire();
    },

    vote: function (cmp, event, helper) {
        var authorizationMessage = $A.get('$Label.c.msgAuthorizationRequired'); 

        helper.addVote(cmp, function (newVoteTotal) {
            if (newVoteTotal !== 'error' && newVoteTotal !== 'auth_required') {
                cmp.set('v.item.votesNum', newVoteTotal);
                cmp.set('v.item.voteStatus', 'voted');

                helper.getStatus(cmp, function (newStatus) {
                    cmp.set('v.item.item.Status', newStatus);
                    helper.updateStatusColor(cmp);
                });

            } else if (newVoteTotal === 'auth_required') {
                var errEvt = cmp.getEvent('ideasErrorEvent');
                errEvt.setParams({'type': 'auth_required', 'message': authorizationMessage});
                errEvt.fire();
            } else {
                //TODO: handle error
            }
        });
    },

    flag: function (cmp, evt, helper) {
        helper.flagIdea(cmp);
    }

})