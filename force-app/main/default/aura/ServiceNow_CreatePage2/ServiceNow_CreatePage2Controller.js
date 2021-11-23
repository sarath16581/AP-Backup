({
    loadTemplate: function(component, event, helper) {
        console.log('component.get("v.objectName") ABCDE ', component.get("v.objectName"));

        var isSF1 = typeof sforce !== 'undefined';
        var url_string = window.location;
        var url = new URL(url_string);
        var param_lkid = null; // = url.searchParams.get("lkid");
        var param_lkidLabel = null;
        for (var key of url.searchParams.keys()) {
            if (key.includes('_lkid')) {
                param_lkid = url.searchParams.get(key);
                var param = key.replace('_lkid', '');
                param_lkidLabel = url.searchParams.get(param);
            }
        }
        var action1 = component.get("c.getObjectNameById");
        action1.setParams({
            "recId": param_lkid
        });
        action1.setCallback(this, function(response1) {
            var state1 = response1.getState();
            if (response1.getReturnValue() != null) {
                console.log(' example ' + JSON.stringify(response1.getReturnValue()));
                if (response1.getReturnValue() != null) {

                    console.log('#### response1.getReturnValue()', response1.getReturnValue());
                    if (response1.getReturnValue() == 'Billing_Account__c') {
                        // source for Billing lookup on case
                        component.set("v.selRecLabelForBillingAccount", param_lkidLabel);
                        component.set("v.selRecIdForBillingAccount", param_lkid);
                    } else if (response1.getReturnValue() == 'service_now_case__x') {
                        console.log('#### param_lkid - 111 ', param_lkid);
                        console.log('#### param_lkidLabel', param_lkidLabel);
                        //selRecLabel, selRecId is for lookup ui fields
                        component.set("v.selRecLabel", param_lkidLabel);
                        component.set("v.selRecId", param_lkidLabel);
                    } else {
                        //selRecLabel, selRecId is for lookup ui fields
                        component.set("v.selRecLabel", param_lkidLabel);
                        component.set("v.selRecId", param_lkid);
                    }
                }
            }
            var action = component.get("c.getFieldWrapList");
            action.setParams({
                "objectAPIName": component.get("v.objectName"),
                "recordTypeId": component.get("v.RecordTypeId"),
                "recordId": component.get("v.recordId"),
                "templateId": component.get("v.templateId")
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                component.set("v.fieldValueMapping", response.getReturnValue());
            });
            $A.enqueueAction(action);
        });
        $A.enqueueAction(action1);
    },


    handleClick: function(component, event, helper) {
        component.set("v.errorString", '');
        component.set("v.displayError", false);
        var hasError = helper.validationhelper(component, event, helper);
        window.AP_LIGHTNING_UTILS.getPromiseDelivery(component, "validSelectedRecord", {
            "recordId": component.get("v.selRecId"),
            "objectName": 'Lodgement_Customer_Migration__c'
        }).then($A.getCallback(function(response) {
            console.log('response 1 ', response);
            if (!response && component.get("v.objectName") != 'Service_Now_Case_Comment__x') {
                component.set("v.thirdPartyHasError", true);
            } else {
                component.set("v.thirdPartyHasError", false);
            }
            return window.AP_LIGHTNING_UTILS.getPromiseDelivery(component, "validSelectedRecord", {
                "recordId": component.get("v.selRecIdForBillingAccount"),
                "objectName": 'Billing_Account__c'
            });
        })).then($A.getCallback(function(response) {
            console.log('response 2 ', response);
            if (!response && component.get("v.objectName") != 'Service_Now_Case_Comment__x') {
                component.set("v.billingAccountHasError", true);
            } else {
                component.set("v.billingAccountHasError", false);
            }
            if ((!hasError && !component.get("v.billingAccountHasError") && !component.get("v.thirdPartyHasError"))) {
                helper.saveCaseHelper(component, event, helper);
            }

        }));
    },

    closeModal: function(component, event, helper) {
        component.set("v.openModal", false);
    },
    lookupSearch: function(component, event, helper) {
        component.set("v.searchObject", "");
        component.set("v.openModal", true);
        var lookupFieldAPIName = event.getSource().get('v.alternativeText');
        component.set("v.lookupFieldAPIName", lookupFieldAPIName);
        if (lookupFieldAPIName == 'Billing Account') {
            component.set("v.searchObject", "Billing_Account_Lookup__c");
        }
        else{
            //component.set("v.searchObject", "Lodgement_Customer_Migration__c");
        }
    },
    recSelectedEventAction: function(component, event, helper) {
        component.set("v.openModal", false);
        if (component.get("v.lookupFieldAPIName") == 'Billing Account') {
            component.set("v.selRecLabelForBillingAccount", event.getParam("label"));
            component.set("v.selRecIdForBillingAccount", event.getParam("value"));
        } else {
            component.set("v.selRecLabel", event.getParam("label"));
            component.set("v.selRecId", event.getParam("value"));
        }

    },
    cancel: function(component, event, helper) {
        var url_string = window.location;
        var url = new URL(url_string);
        var param_retURL = url.searchParams.get("retURL");
        console.log('param_retURL '+param_retURL);
        var isSF1 = typeof sforce !== 'undefined';
        if (isSF1) {
            if (sforce.internal != undefined) {
                var action = component.get("c.getObjectPrefix");
                var objectPrefix = '';
                action.setParams({
                    "objectName": component.get("v.objectName")
                });
                action.setCallback(this, function(response) {
                    objectPrefix = response.getReturnValue();
                    if(param_retURL != null){
                         window.open(param_retURL, '_self');
                    }
                    else if (objectPrefix != '') {
                        window.open('/' + objectPrefix + '/o', '_self');
                    }
                });
                $A.enqueueAction(action);
            } else if (sforce.one != undefined) {
                sforce.one.navigateToURL('#/sObject/service_now_case__x/home');
            }

        } else {
            var action = component.get("c.getObjectPrefix");
            var objectPrefix = '';
            action.setParams({
                "objectName": component.get("v.objectName")
            });
            action.setCallback(this, function(response) {
                objectPrefix = response.getReturnValue();
                if(param_retURL != null){
                         window.open(param_retURL, '_self');
                }
                else if (objectPrefix != '') {
                    window.open('/' + objectPrefix + '/o', '_self');
                }
            });
            $A.enqueueAction(action);
        }
    },

    keyPressLookup: function(component, event, helper) {
        if (event.target.id == 'thirdPartyReference') {
            //component.set("v.selRecLabel",event.target.value);
            //component.set("v.selRecId",'');
        } else if (event.target.id == 'billingAccount') {
            //component.set("v.selRecLabelForBillingAccount",event.target.value);
            //component.set("v.selRecIdForBillingAccount",'');
        }
    }
})