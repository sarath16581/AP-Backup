({
    // Helper method to show success message.Check 'ClearMessages' method as well.
    success : function(component, title, message) {
        component.set('v.message', {'title': title, 'text': message, 'severity':'confirm', 'closable': true });
    },

    // Helper method to show error message.Check 'ClearMessages' method as well.
    error: function(component, title, message){
        component.set('v.message', {'title': title, 'text': message, 'severity':'error', 'closable': true });
    },

    // Helper method to navigate to SObject
    navigateToSObject: function(component, recordId){
        $A.get("e.force:navigateToSObject").setParams({
            "recordId":  recordId
        }).fire();
    },

    // Helper method to navigate to a any URL.
    navigateToURL : function (component, url) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": url
        });
        urlEvent.fire();
    },

        // Helper method to navigate to a any URL.
    navigateToTopic : function (component, topicId, topicName) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": '/topic/' + topicId + '/' + topicName
        });
        urlEvent.fire();
    },


    // Helper method to show warning message. Check 'ClearMessages' method as well.
    warn: function(component, title, message){
        component.set('v.message', {'title': title, 'text': message, 'severity':'warn', 'closable': true });
    },

    // Helper method to clear any messages.
    clearMessages: function(component) {
        component.set('v.message', null);
    },
    executeApex : function(component, actionName, params, onsuccess, onerror) {
        console.log('In Execute Apex: ' + actionName);
        var action = component.get(actionName);
        console.log(action);
        if(params !=null){
            action.setParams(params);
        }
        var self = this;
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log(state);
            if (state === "SUCCESS") {
                if(onsuccess){
                    onsuccess(response);
                }
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                console.log(errors);
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        self.error(component, 'ActionError', 'Error executing ' + actionName + ': ' + errors[0].message);
                    } else {

                    }
                } else {
                    self.error(component, 'ActionError', 'Error executing ' + actionName);
                }
                if(onerror){
                    onerror();
                }
            }
        });
        $A.enqueueAction(action);
    },
    log: function(component, message){
        if(component.get("v.debugMode")){
            console.log(message);
        }
    },
    launchSocialShareDialog: function(component, recordId, url){
        console.log('In Show Modal: ' + recordId);
        this.showModal(component, "Share", "c:SS_uiSocialShare", {'recordId': recordId, 'url': url});

    },
    showModal: function(component, title, componentName, componentParams){
       	var modalEvent = $A.get("e.c:SS_uiModalShowEvent");
        modalEvent.setParams({ "title" : title, "componentName": componentName, "componentParams" : componentParams});
        modalEvent.fire();
    },
    gplusShare: function(component,url){
        if(url == null || url ==''){
            url = window.location.href;
        }
        window.open( "https://plus.google.com/share?url=" + encodeURI(url));
    },
    linkedinShare: function(component,url, title){
        if(url == null || url ==''){
            url = window.location.href;
        }
        if(title == null || title == ''){
            title =  document.title;
        }
        window.open("http://www.linkedin.com/shareArticle?url=" + encodeURI(url) + "&title=" +title);
    },

    twitterShare: function(component,url, text){
        if(url == null || url ==''){
            url = window.location.href;
        }
        if(text == null || text == ''){
            text =  document.title;
        }
        window.open("http://twitter.com/share?url="+ encodeURI(url) + "&text=" + text);
    },

    fbShare: function(component,url){
        if(url == null || url ==''){
            url = window.location.href;
        }
        window.open("http://www.facebook.com/sharer/sharer.php?u=" + encodeURI(url));
    }
})