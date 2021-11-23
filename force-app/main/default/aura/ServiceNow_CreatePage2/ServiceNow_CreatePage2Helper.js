({
    validationhelper: function(component, event, helper) {
        var hasError = false;
        var fieldValueMapping = component.get("v.fieldValueMapping");
        for (var i = 0; i < fieldValueMapping.length; i++) {
            for (var j = 0; j < fieldValueMapping[i].layoutRows.length; j++) {
                for (var k = 0; k < fieldValueMapping[i].layoutRows[j].layoutItems.length; k++) {
                    for (var l = 0; l < fieldValueMapping[i].layoutRows[j].layoutItems[k].layoutComponents.length; l++) {
                        if (fieldValueMapping[i].layoutRows[j].layoutItems[k].layoutComponents[l].details != null) {
                            var renderAs = fieldValueMapping[i].layoutRows[j].layoutItems[k].layoutComponents[l].details.renderAs;
                            var dataType = fieldValueMapping[i].layoutRows[j].layoutItems[k].layoutComponents[l].details.dateValue;
                            var required = fieldValueMapping[i].layoutRows[j].layoutItems[k].layoutComponents[l].details.required;
                            if (required) {
                                var inputElement = document.getElementById(fieldValueMapping[i].layoutRows[j].layoutItems[k].layoutComponents[l].details.name);
                                var inputElementSpan = document.getElementById(fieldValueMapping[i].layoutRows[j].layoutItems[k].layoutComponents[l].details.name + '--span');
                                var fieldValue = fieldValueMapping[i].layoutRows[j].layoutItems[k].layoutComponents[l].details.value;
                                var inputElementId = fieldValueMapping[i].layoutRows[j].layoutItems[k].layoutComponents[l].details.name + '--input';
                                if (renderAs == 'Lookup') {

                                } else {
                                    if (fieldValue == null || fieldValue == '' || fieldValue == undefined) {
                                        $A.util.addClass(inputElement, 'slds-has-error');
                                        inputElementSpan.innerHTML = 'Please fill out ' + fieldValueMapping[i].layoutRows[j].layoutItems[k].layoutComponents[l].details.label;
                                        hasError = true;
                                    } else {
                                        $A.util.removeClass(inputElement, 'slds-has-error');
                                        inputElementSpan.innerHTML = '';
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return hasError;
    },
    saveCaseHelper: function(component, event, helper) {
        component.set("v.Spinner", true);
        var action = component.get("c.save");
        action.setParams({
            "fieldMappingString": JSON.stringify(component.get("v.fieldValueMapping")),
            "salesforceId": component.get("v.selRecId"),
            "salesforceBillingAccount": component.get("v.selRecLabelForBillingAccount"),
            "recordId": component.get("v.recordId"),
            "objectAPIName": component.get("v.objectName")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.recordId", response.getReturnValue());
                var isSF1 = typeof sforce !== 'undefined';
                if (isSF1) {
                    console.log('isSF1 ' + JSON.stringify(sforce));
                    component.set("v.Spinner", false);
                    if (sforce.internal != undefined) {
                        window.open('/' + component.get("v.recordId"), '_self');
                    } else if (sforce.one != undefined) {
                        sforce.one.navigateToURL('#/sObject/' + component.get("v.recordId") + '/view');
                    }
                } else {
                    component.set("v.Spinner", false);
                    window.open('/' + component.get("v.recordId"), '_self');
                }
            } else if (state === "ERROR") {
                component.set("v.Spinner", false);
                component.set("v.errorString", response.getError()[0].message);
                component.set("v.displayError", true);
            }

        });
        $A.enqueueAction(action);
    }
})