({
    /* Function to retrieve and set the User Info, Idea details initially */
    doInit: function (cmp, event, helper) {
        var action = cmp.get('c.getTopFeaturedIdeas');

        action.setParams({
            ideasNumber: cmp.get('v.ideasNumber'),
            pageName: cmp.get('v.pageName'),
            orderBy: cmp.get('v.orderBy')
        });

        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS') {
                cmp.set('v.wrapper', response.getReturnValue());
                var idea = cmp.get('v.wrapper');
                var ideaList = [];
                for(var i = 0; i < idea.length; i++){
                    var shortBody = helper.cutText(idea[i].item.Body, 300);
                    var ideaId = idea[i].item.Id;
                    var ideaMap = {'ideaId' : ideaId, 'shortBody' : shortBody};
                    ideaList.push(ideaMap);
                }
                cmp.set('v.shortBodyList',ideaList);
              
            }
        });

        $A.enqueueAction(action);
        
        var baseURL = $A.get("$Site").siteUrlPrefix;
        
        cmp.set('v.baseURL', baseURL);
        
        helper.retrieveUserInfo(cmp);
    },
    
    /* Function to check user authorization and open Idea details page to add comments */
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
                var target = event.target;
                var dataEle = target.getAttribute("data-selected-Index");
                var urlEvent = $A.get('e.force:navigateToURL');
                urlEvent.setParams({'url': '/idea/' + cmp.get('v.wrapper')[dataEle].item.Id + '#commentadd', 'isredirect': false});
                urlEvent.fire();
            }
        });
        $A.enqueueAction(action);
    },
    
    /* Function to open Idea details page to view comments */
    openIdeaComments: function (cmp, event) {
        var target = event.target;
        var dataEle = target.getAttribute("data-selected-Index");
        var urlEvent = $A.get('e.force:navigateToURL');
        urlEvent.setParams({'url': '/idea/' + cmp.get('v.wrapper')[dataEle].item.Id + '#comments', 'isredirect': false});
        urlEvent.fire();
    },
    
    /* Function to check user authorization to add vote */
    vote: function (cmp, event, helper) {
        var authorizationMessage = $A.get('$Label.c.msgAuthorizationRequired'); 
        var target = event.target;
        var dataEle = target.getAttribute("data-selected-Index");
 
        helper.addVote(cmp,dataEle, function (newVoteTotal) {
            var wrapper = cmp.get("v.wrapper");
            if (newVoteTotal !== 'error' && newVoteTotal !== 'auth_required') {
                var itemWrap = wrapper[dataEle];
                itemWrap.votesNum = newVoteTotal;
                itemWrap.voteStatus = 'voted';
                wrapper[dataEle] = itemWrap;
                cmp.set('v.wrapper', wrapper);

            } else if (newVoteTotal === 'auth_required') {
                var errEvt = cmp.getEvent('ideasErrorEvent');
                errEvt.setParams({'type': 'auth_required', 'message': authorizationMessage});
                errEvt.fire();
            } else {
                console.log('Error Retrieved: ' +newVoteTotal);
            }
        });
    },
    
    /* Function to navigate to login page based on user authorization */
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