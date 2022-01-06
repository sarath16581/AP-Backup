({
    validateComponent : function(component) {
        var valid = true;
        
        if (component.isValid()) {
            valid =  ( component.get("v.chatButtontId") != undefined && component.get("v.chatButtontId") != '')
            || ( component.get("v.endpoint") != undefined && component.get("v.endpoint") != '')
            || ( component.get("v.deploymentId") != undefined && component.get("v.deploymentId") != '')
            || ( component.get("v.organizationId") != undefined && component.get("v.organizationId") != '' )  
        }
        return valid;
    },
    
    setLiveAgentConfigProperties : function(component, resolve, reject){
        var action = component.get("c.getLiveAgetSettings");
        action.setStorable();
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var returnObj = JSON.parse((JSON.stringify(response.getReturnValue())));
                component.set("v.chatButtontId", returnObj["LiveAgentButtonId__c"]);
                component.set("v.endpoint", returnObj["LiveAgentInit__c"]);
                component.set("v.deploymentId", returnObj["LiveAgentDeploymentId__c"]);
                component.set("v.organizationId", returnObj["LiveAgentOrgId__c"]);
                resolve();
            }
        });
        $A.enqueueAction(action);
    },
    
    helperFunctionAsPromise : function(component, helperFunction) {
        return new Promise($A.getCallback(function(resolve, reject) {
            helperFunction(component, resolve, reject);
        }));
    },
    
    bindLiveAgent : function (component,data){
        //custom handler for online/offline update
        function updateLiveAgentButton(component) {
            
            if (component.isValid()) {
                var onlineBtn = document.getElementById('btONline');//component.find("btONline");
                var offlineBtn = document.getElementById('btOFFline');//component.find("btOFFline");
                
                if((typeof onlineBtn != "undefined") && (typeof offlineBtn != "undefined")){
                    
                    if (component.get("v.isLiveAgentOnline")== true){
                        $A.util.removeClass(onlineBtn, "toggle");
                        $A.util.addClass(offlineBtn, "toggle");
                    }else{
                        $A.util.removeClass(offlineBtn, "toggle");
                        $A.util.addClass(onlineBtn, "toggle");
                    }
                }
            }
        }
        
        component.set("v.isLiveAgentOnline",false);
        var chatBtn    = data.chatButtontId;
        liveagent.addButtonEventHandler(chatBtn, function(e) {
            console.log(component.get("v.isLiveAgentOnline"));
            if (e == liveagent.BUTTON_EVENT.BUTTON_AVAILABLE) {
                component.set("v.isLiveAgentOnline",true);
            } else if (e == liveagent.BUTTON_EVENT.BUTTON_UNAVAILABLE) {
                component.set("v.isLiveAgentOnline",false);
            }
            if (component.get("v.previousIsLiveAgentOnline") == null){
                component.set("v.previousIsLiveAgentOnline",false);
            }else {
                component.set("v.previousIsLiveAgentOnline",component.get("v.isLiveAgentOnline"));
            }

            updateLiveAgentButton(component);
        });
        
        //Initialise liveagent
        liveagent.init( data.LA_chatServerURL, data.LA_deploymentId,  data.organizationId);
    },
    
    // Check if user has access to AP Billing Accounts or StarTrack
    checkAPBillingAccountAccess : function (component, resolve, reject){
        var action = component.get("c.hasAPBillingAccounts");
        action.setStorable();
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                if(response.getReturnValue()){
                    component.set("v.hasAPBillingAccountsAccess", response.getReturnValue());
                }
                resolve();
            }
        });
        $A.enqueueAction(action);
    }
})