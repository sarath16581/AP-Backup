({
    /* Function to set the common variables initially */
    initCommonVars: function(cmp){
    	var commonVars = cmp.get('v.commonVars');

    	if (!commonVars) {
            commonVars = {};
		}

    	commonVars.userInfo = {};
        commonVars.communityName = cmp.get('v.communityName');

        cmp.set('v.commonVars', commonVars);
	},
    
    /* Function to retrieve the user info initially */
	retrieveUserInfo: function(cmp) {
		var action = cmp.get('c.getUserInfo'),
            commonVars = cmp.get('v.commonVars');

        action.setCallback(this, function(response) {
				var state = response.getState(),
					resVal = response.getReturnValue();

				if (state === 'SUCCESS') {
					cmp.set('v.userInfo', resVal);
                    commonVars.userInfo = resVal;
                    cmp.set('v.commonVars', commonVars);
                }
        	});

        $A.enqueueAction(action);
	},
    
    /* Function to retrieve and parse the url filter parameters initially */
    parseUrlHash: function() {
		var varsObj = {},
			hashArr = [],
			keyVal = [];
        /*Below code is added for Communities Home Page Top Idea changes.
        To determine the source as ideasTopFeatured component on   
        Home Page and to differentiate the existing logic for getting 
        the filter Category and Status parameter and sending it to the 
        backend to fetch the search results.*/
        var result = '';
        var uri = window.location.href;
        var uri_dec = decodeURIComponent(uri);
        if(uri_dec != null){
          result = uri_dec.match(/topIdeaOnHomePage/gi);  
        }
        //Navigation is through ideasTopFeatured on Home Page.
        if(result != null && result == 'topIdeaOnHomePage'){
            hashArr = uri_dec.split('#');
            for (var i = 0; i < hashArr.length; i+=1) {
                keyVal = hashArr[i].split("=");

				if (keyVal.length === 2) {
					varsObj[keyVal[0]] = keyVal[1];
				} else if (i === 0 && keyVal.length === 1 && keyVal[0].length >= 16) {
					varsObj.id = keyVal[0];
				}
            }
         return varsObj;
            
        }else{
        //Existing logic
		if (location.hash !== null && location.hash.length > 0) {
            
            hashArr = location.hash.replace('#/', '').replace('#', '').split('&');
            for (var i = 0; i < hashArr.length; i+=1) {
                keyVal = hashArr[i].split("=");

				if (keyVal.length === 2) {
					varsObj[keyVal[0]] = keyVal[1];
				} else if (i === 0 && keyVal.length === 1 && keyVal[0].length >= 16) {
					varsObj.id = keyVal[0];
				}
            }
        }

		return varsObj;
        }
	}
})