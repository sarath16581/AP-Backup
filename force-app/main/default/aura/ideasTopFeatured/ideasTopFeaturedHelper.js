({
    /* Function to limit the body text content on Top Featured Idea component initially */
    cutText: function (text, maxLengthParam) {
		var resultText,
			lastWordPos,
			maxLength = parseInt(maxLengthParam, 10);

		if (typeof text !== 'string' || maxLength < 1) {
			return '';
		}

		if (text.length <= maxLength) {
			return text;
		}

		resultText = text.substr(0, maxLength);
		lastWordPos = resultText.lastIndexOf(' ');

		if (lastWordPos > 0) {
			resultText = resultText.substr(0, lastWordPos);
		}

		return resultText;
	},
    
    /* Function to retrieve User Info initially */
    retrieveUserInfo: function(cmp) {
        var action = cmp.get('c.getUserInfo');

        action.setCallback(this, function(response) {
            var state = response.getState(),
                resVal = response.getReturnValue();

            if (state === 'SUCCESS') {
                cmp.set('v.userInfo', resVal);
            }
        });

        $A.enqueueAction(action);
    },
    
    /* Function to add vote on click of vote */
    addVote: function (cmp, dataEle, callback) {
		var action = cmp.get('c.addVote');
        
		action.setParams({
            ideaId: cmp.get('v.wrapper')[dataEle].item.Id
        	});

        action.setCallback(this, function(response){
				var state = response.getState(),
					respVal = response.getReturnValue();

				if (state === "SUCCESS") {
					if (typeof callback === 'function') {
						callback(respVal);
					}
				} else {
                    console.log('Failed:');
				}
        	});

        $A.enqueueAction(action);
	}
})