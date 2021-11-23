({
    loadTemplate: function(component, event, helper) {
        var action = component.get("c.getFieldWrapList");
        action.setParams({
            "objectAPIName": component.get("v.objectName"),
            "recordTypeId": component.get("v.RecordTypeId"),
            "recordId": component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            component.set("v.fieldValueMapping", response.getReturnValue());
        });
        $A.enqueueAction(action);

        var action1 = component.get("c.getServiceNowInstanceURL");
        action1.setCallback(this, function(response) {
            component.set("v.instanceURL", response.getReturnValue());
        });
        $A.enqueueAction(action1);
    },
    cancel: function(component, event, helper) {
        var isSF1 = typeof sforce !== 'undefined';
        console.log('sforce ' + isSF1);

        if (isSF1) {
            if (sforce.internal != undefined) {
                var action = component.get("c.getObjectPrefix");
                var objectPrefix = '';
                action.setParams({
                    "objectName": component.get("v.objectName")
                });
                action.setCallback(this, function(response) {
                    objectPrefix = response.getReturnValue();
                    if (objectPrefix != '') {
                        window.open('/' + objectPrefix + '/o', '_self');
                    }
                });
                $A.enqueueAction(action);
            } else if (sforce.one != undefined) {
                sforce.one.navigateToURL('#/sObject/' + component.get("v.objectName") + '/home');
            }
        } else {
            var action = component.get("c.getObjectPrefix");
            var objectPrefix = '';
            action.setParams({
                "objectName": component.get("v.objectName")
            });
            action.setCallback(this, function(response) {
                objectPrefix = response.getReturnValue();
                if (objectPrefix != '') {
                    window.open('/' + objectPrefix + '/o', '_self');
                }
            });
            $A.enqueueAction(action);
        }
    },
    edit: function(component, event, helper) {
        var isSF1 = typeof sforce !== 'undefined';
        if (isSF1) {
            if (sforce.internal != undefined) {
                window.open('/' + component.get("v.recordId") + '/e', '_self');
            } else if (sforce.one != undefined) {
                sforce.one.navigateToURL('#/sObject/' + component.get("v.recordId") + '/edit');
            }
        } else {
            window.open('/' + component.get("v.recordId") + '/e', '_self');
        }
    },
    handleClick: function(component, event, helper) {

    }
})