({
    init: function (component, event, helper) {
        
        function liveAgentStart() {
            //timeout to initiate liveAgent
            window.setTimeout(
                $A.getCallback(function () {
                    if (component.isValid()) {
                        var data = {};
                        data.LA_chatServerURL = component.get("v.endpoint");
                        data.LA_deploymentId = component.get("v.deploymentId");
                        data.organizationId = component.get("v.organizationId");
                        data.chatButtontId = component.get("v.chatButtontId");
                       // data.userSessionData = component.get("v.userSessionData");
                        if (component.get("v.contact") != null) {
                            data.contactId = component.get("v.contact").Id;
                            data.contactName = component.get("v.contact").Name;
                        }
                        
                        function initLiveAgent(data) {
                            var self = this;
                            self.data = data;
                            
                            if ((typeof liveagent == "object") && (document.getElementById('btONline') != null)) {
                                clearInterval(interV);
                                helper.bindLiveAgent(component, data);
                            } else {
                                console.log('CTRL  timeout to init live agent');
                            }
                        }
                        //setInterval to initiate liveAgent when liveagent object
                        // is available
                        var interV = setInterval(initLiveAgent, 500, data);
                    } else {
                        console.log('CTRL  component is not valid');
                    }
                }), 100
            );
        }
        
        helper.helperFunctionAsPromise(component, helper.checkAPBillingAccountAccess)
        .then($A.getCallback(function() {
            return helper.helperFunctionAsPromise(component, helper.setLiveAgentConfigProperties)
        })).then(
            $A.getCallback(
                function() {
                    var isValid = helper.validateComponent(component);
                    component.set("v.isInvalidInput", !isValid);
                    if (component.get("v.hasAPBillingAccountsAccess") && isValid) {
                        liveAgentStart();
                        
                        var chatBtn = component.get("v.chatButtontId") + '';
                        //adding liveAgent buttons wo global array
                        if (!window._laq) {
                            window._laq = [];
                        }
                        window._laq.push(function () {
                            liveagent.showWhenOnline(
                                (function (chatBtn) {
                                    return chatBtn;
                                })(chatBtn), document.getElementById('btONline'));
                            liveagent.showWhenOffline(
                                (function (chatBtn) {
                                    return chatBtn;
                                })(chatBtn), document.getElementById('btOFFline'));
                        });
                    }
                }
            )
        );
        
    },
    
    startChat: function (component, event, helper) {
        liveagent.startChat(component.get("v.chatButtontId"));
    },
    
    afterScriptsLoaded: function (component, event, helper) {}
})