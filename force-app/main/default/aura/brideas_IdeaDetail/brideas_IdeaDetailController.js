({
    doInit: function (cmp, event, helper) {
        var urlVars = helper.parseUrlHash();

        if (typeof urlVars.commentadd !== 'undefined') {
            cmp.set('v.showCommentForm', true);
        }

        helper.retrieveUserInfo(cmp);
        helper.retrieveItem(cmp);
        
        var baseURL = $A.get("$Site").siteUrlPrefix;
        cmp.set('v.loginPage', baseURL+'/login');
    },

    vote: function (cmp, event, helper) {
        var authorizationMessage = $A.get('$Label.c.msgAuthorizationRequired');

        helper.addVote(cmp, function(newVoteTotal) {
            if (newVoteTotal !== 'error' && newVoteTotal !== 'auth_required') {
                cmp.set('v.item.votesNum', newVoteTotal);
                cmp.set('v.item.voteStatus', 'voted');

                helper.getStatus(cmp, function(newStatus) {
                    cmp.set('v.item.item.Status', newStatus);
                    helper.retrieveStatusColor(cmp);
                });

            } else if (newVoteTotal === 'auth_required') {
                var errEvt = cmp.getEvent('ideasErrorEvent');
                errEvt.setParams({type:'auth_required', message:authorizationMessage});
                errEvt.fire();
            } else {
                //TODO: handle error
            }
        });
    },

    updateCommentsNumberHandler: function (cmp, event, helper) {
        helper.updateCommentsNumber(cmp);
    },
    /*Below code is commented on 08-08-2018 for Communities Ideas Detail Page for moving the 
      Post idea or Join group button to a new component in the header.*/
    /*openCreateDialog: function(cmp) {
        var userInfo = cmp.get('v.userInfo');
        var authorizationMessage = $A.get('$Label.c.msgAuthorizationRequired');

        if (userInfo && userInfo.Type !== '' && userInfo.Type !== 'Guest') {
            cmp.set('v.showCreateModal', true);
        } else {
            var errEvt = cmp.getEvent('ideasErrorEvent');
            errEvt.setParams({type:'auth_required', message: authorizationMessage});
            errEvt.fire();
        }
    },*/

    closeCreateDialog: function(cmp) {
        cmp.set('v.showCreateModal', false);
    },

    openCommentsForm: function(cmp, event) {
        var authorizationMessage = $A.get('$Label.c.msgAuthorizationRequired');
        var action = cmp.get('c.getUserTypeInfo');
        
        action.setCallback(this, function(response) {
            var respVal = response.getReturnValue();
            if (respVal === 'auth_required') {
                var errEvt = cmp.getEvent('ideasErrorEvent');
                errEvt.setParams({'type': 'auth_required', 'message': authorizationMessage});
                errEvt.fire();
            }else{
                cmp.set('v.showCommentForm', true);
            }
        });
        $A.enqueueAction(action);
    },
    /*Below code is commented on 08-08-2018 for Communities Ideas Detail Page for moving the 
      Post idea or Join group button to a new component in the header.*/
    /*joinIdeasGroup: function(cmp) {
        cmp.set('v.showJoinGroupModal', true);
    },*/

    flag: function (cmp, evt, helper) {
        helper.flagIdea(cmp);
    },

    handleIdeaCreated: function (cmp, event) {
        var newIdea = event.getParam('newIdea'),
            navEvt = $A.get('e.force:navigateToSObject');

        navEvt.setParams({'recordId': newIdea.item.Id});
        navEvt.fire();
    },
    
    handleErrorEvent: function(cmp, event) {
		var errorType = event.getParam('type'),
            message = event.getParam('message'),
            loginUrl = cmp.get('v.loginPage'),
			removeMsg = function() {
					if (cmp.isValid()) {
						cmp.set('v.systemMessage', {type: '', body: ''});
					}
				};
        
		if (errorType === 'auth_required' && (loginUrl && loginUrl !== '')) {
            var hdnLoginBtn = cmp.find('hiddenLoginBtn');

            hdnLoginBtn.getElement().click();

        } else {
            cmp.set('v.systemMessage', {type: 'error', body: message});

            setTimeout($A.getCallback(removeMsg), 5000);
		}
	}
})