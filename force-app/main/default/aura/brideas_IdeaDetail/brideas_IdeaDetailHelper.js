({
    retrieveItem: function(cmp, callback) {
        var action = cmp.get("c.getIdea");

        cmp.set('v.listLoading', true);
        action.setParams({ recordId : cmp.get("v.recordId")});

        action.setCallback(this, function(response){
            var state = response.getState(),
                idea = response.getReturnValue();

            if (state === 'SUCCESS') {

                cmp.set("v.item", idea);

                if (typeof idea.Categories === 'string' && idea.Categories !== '') {
                    cmp.set('v.Categories', idea.Categories.replace(new RegExp(';', 'g'), ' | '));
                }

                if (typeof idea.Votes === 'object') {
                    cmp.set('v.voteStatus', idea.Votes[0].Type);
                } else {
                    cmp.set('v.voteStatus', 'undefined');
                }

                if (typeof callback === 'function') {
                    callback();
                }
            } else {
                //TODO: handle error
            }

            cmp.set('v.listLoading', false);
        });

        $A.enqueueAction(action);
    },

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

    addVote: function (cmp, callback) {
        var action = cmp.get('c.addVote');

        action.setParams({
            ideaId: cmp.get('v.item.item.Id')
        });

        action.setCallback(this, function(response){
            var state = response.getState(),
                respVal = response.getReturnValue();

            if (state === "SUCCESS") {
                if (typeof callback === 'function') {
                    callback(respVal);
                }
            } else {
                //TODO: handle error
            }
        });

        $A.enqueueAction(action);
    },

    getStatus: function (cmp, callback) {
        var action = cmp.get('c.getStatus');

        action.setParams({
            ideaId: cmp.get('v.item.item.Id')
        });

        action.setCallback(this, function(response){
            var state = response.getState(),
                respVal = response.getReturnValue();

            if (state === 'SUCCESS' && typeof callback === 'function') {
                callback(respVal);
            }
        });

        $A.enqueueAction(action);
    },

    loadMerged: function(cmp) {
        var action = cmp.get('c.getMergedIdeas');

        action.setParams({
            parentId: cmp.get('v.item.item.Id')
        });

        action.setCallback(this, function(response){
            var state = response.getState(),
                respVal = response.getReturnValue();

            if (state === "SUCCESS") {
                cmp.set('v.mergedIdeas', respVal);
            }
        });

        $A.enqueueAction(action);
    },

    updateCommentsNumber: function(cmp) {
        var action = cmp.get('c.getIdeaCommentsNumber');

        action.setParams({
            ideaId: cmp.get('v.item.item.Id')
        });

        action.setCallback(this, function(response){
            var state = response.getState(),
                respVal = response.getReturnValue();

            if (state === 'SUCCESS') {
                cmp.set('v.item.NumComments', respVal);
            }
        });

        $A.enqueueAction(action);
    },

    retrieveStatusColor: function (cmp) {
        var action = cmp.get('c.getStatusColor');

        action.setParams({
            status: cmp.get('v.item.item.Status')
        });

        action.setCallback(this, function(response){
            var state = response.getState(),
                respVal = response.getReturnValue();

            if (state === 'SUCCESS' && respVal) {
                cmp.set('v.item.statusColor', respVal);
            }
        });

        $A.enqueueAction(action);
    },

    flagIdea: function (cmp) {
        var action = cmp.get('c.setFlagOnIdea');

        action.setParams({'IdeaId' : cmp.get('v.item.item.Id')});
        action.setCallback(this, function(resp) {
            var state = resp.getState(),
                respVal = resp.getReturnValue();

            if (state === 'SUCCESS' || respVal === true) {
                cmp.set('v.item.flagged', true);
            } else {
                //TODO: handle error
            }
        });

        $A.enqueueAction(action);
    },

    parseUrlHash: function() {
        var varsObj = {},
            hashArr = [],
            keyVal = [];

        if (location.hash !== null && location.hash.length > 0) {
            hashArr = location.hash.replace('#/', '').replace('#', '').split('&');

            for (var i = 0; i < hashArr.length; i+=1) {
                keyVal = hashArr[i].split("=");

                if (keyVal.length === 2) {
                    varsObj[keyVal[0]] = keyVal[1];
                } else if (i === 0 && keyVal.length === 1 && keyVal[0].length >= 16) {
                    varsObj.id = keyVal[0];
                } else {
                    varsObj[keyVal[0]] = '';
                }
            }
        }

        return varsObj;
    }
})