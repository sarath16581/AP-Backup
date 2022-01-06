({
	loadComments: function (component) {
		var action = component.get('c.getIdeaComments'),
			listItems = component.get('v.commentsList'),
			nextLoadedItem = component.get('v.nextComment'),
			moreBtn = component.find('commentsListShowMore'),
			lastLoadedCommentDate = '',
			queryLimit = 5;

		component.set('v.loading', true);

		if (nextLoadedItem) {
			lastLoadedCommentDate = nextLoadedItem.ideaComment.CreatedDate;
		} else {
			queryLimit+=1;
		}

        action.setParams({
            ideaId: component.get('v.ideaId'),
			queryLimit: queryLimit,
			orderDir: component.get('v.orderDir'),
			fromDatetime: lastLoadedCommentDate
        	});

        action.setCallback(this, function(response){
				var state = response.getState(),
					responseData = response.getReturnValue();

				if (state === "SUCCESS") {
					if (nextLoadedItem) {
						listItems.push(nextLoadedItem);
						nextLoadedItem = null;
						component.set('v.nextComment', null);
					}

					for (var i = 0; i < responseData.length; i+=1) {
						listItems.push(responseData[i]);
					}

					if (responseData.length === queryLimit) {
						nextLoadedItem = listItems.pop();
						component.set('v.nextComment', nextLoadedItem);
					}

					component.set('v.commentsList', listItems);
					component.set('v.loading', false);

					if (nextLoadedItem) {
						$A.util.removeClass(moreBtn, 'slds-hide');
					}
				}
        	});

        $A.enqueueAction(action);
		$A.util.addClass(moreBtn, 'slds-hide');
	},

	reloadComments: function (cmp) {
		cmp.set('v.commentsList', []);
		cmp.set('v.nextComment', null);
		this.loadComments(cmp);
	},

    getUserType: function (cmp) {
        var action = cmp.get('c.getUserInfo');
        action.setCallback(this, function(response) {
            var state = response.getState();

            if (state === "SUCCESS") {
                cmp.set('v.userType', response.getReturnValue().Type);
            }
        });
        $A.enqueueAction(action);
    },

	postComment:  function (cmp, commentText) {
		var action = cmp.get('c.saveComment');

		if (cmp.get('v.isSaving') === true) return;

		cmp.set('v.isSaving', true);
        cmp.set('v.errorMessage', '');

		action.setParams({
				ideaId: cmp.get('v.ideaId'),
				message: commentText
        	});

		action.setCallback(this, function(response){
				var state = response.getState(),
					responseData = response.getReturnValue(),
					listItems = cmp.get('v.commentsList'),
                    updateEvent = cmp.getEvent('updateCommentsNumber');

            	cmp.set('v.isSaving', false);

				if (state === 'SUCCESS') {
					listItems.unshift(responseData);
					cmp.set('v.commentsList', listItems);
					cmp.set('v.showCommentForm', false);

                    updateEvent.fire();
				} else if (state === 'ERROR') {
                    var errors = response.getError();

                    if (errors) {
                        cmp.set('v.errorMessage', errors[0].message);
                    } else {
                        cmp.set('v.errorMessage', 'Unknown error');
					}
				} else {
                    cmp.set('v.errorMessage', 'Please try again');
				}
			});

		$A.enqueueAction(action);
	}
})