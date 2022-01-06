({
	loadVotes: function (cmp) {
		var action = cmp.get('c.getIdeaVotes');

		action.setParams({
            ideaId: cmp.get('v.ideaId')
        	});

		action.setCallback(this, function(response){
				var state = response.getState(),
					responseData = response.getReturnValue();

				if (state === "SUCCESS") {
					cmp.set('v.votesList', responseData);
				}
			});

		$A.enqueueAction(action);
	}
})