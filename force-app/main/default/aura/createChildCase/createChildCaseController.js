({
    // define actions to perform on load of component
    onComponentLoad : function(component, event, helper){
        var loadCase = component.get("c.getCaseRecord");
        loadCase.setParams({
            "caseId" : component.get("v.recordId")
        });
        loadCase.setCallback(this, function(response){
            var state = response.getState();
            if(state == 'SUCCESS'){
                component.set("v.parentCase",response.getReturnValue());
                helper.getRecordTypes(component, event, helper);
                helper.loadAttachments(component, event, helper);
                helper.loaddocuments(component, event, helper);
            }
            else if(state == 'ERROR'){
                console.log('error '+response.getError()[0].message);
                helper.showMessage(component, event, helper, response.getError()[0].message, 'Error', 'error');
            }
        });
        $A.enqueueAction(loadCase);
    },

    /* Function to retrieve the fields from the field set based on record type selected. */
    onRecordTypeChange: function(component, event, helper) {
        component.set("v.displayEditForm", false);
        // let's start the spinner
        var loader = component.find('loader');
        //Set the source and target record type parameters.
        var params = {
            sourceRecordTypeId : component.get('v.parentCase').RecordTypeId,
            targetRecordTypeId : component.get('v.selectedRecordType'),
            parentId : component.get('v.recordId')
        };

        // everything went well, let the user see it
        var callbackSuccess = function(response){
            component.set("v.fieldSetList", response);
            component.set("v.displayEditForm", true);
            helper.sharefileandAttachmentCheck(component, event, helper);
        };
        // something went wrong, let the user know
        var callbackFail = function(response){
            console.log('error '+response[0].message);
            helper.showMessage(component, event, helper, response[0].message, 'Error', 'error');
        };

        // invoke the apex controller method getFieldSet, this will read the fieldset for the case
        AP_LIGHTNING_UTILS.invokeController(component, 'getFieldSet', params, callbackSuccess, callbackFail, false, loader);
    },

    /* Function to insert and create a child case for Service Delivery. */
    handleOnSubmit : function(component, event, helper) {
        event.preventDefault();
        var fields = event.getParam("fields");

        //Call the helper function.
        var errorMessage = helper.validateFields(component, event, fields);

        if(errorMessage !== null && errorMessage !== ''){
            helper.showMessage(component, event, helper, 'Please fix the below errors.', 'Error', 'error');
        } else {
            //Call the helper function.
            helper.createChildCase(component, event, helper, fields);
        }
    },

    //method to add/remove selected/unselected attachments and files
    onCheckofAttachmentsAndDocs : function(component, event, helper){
        var docList = component.get("v.selectedDocsAndAttachments");
        if(event.getSource().get("v.value")){
            docList.push(event.getSource().get("v.text"));
        }
        else if(!event.getSource().get("v.value")){
            for(var len = 0; len < docList.length; len++){
                if(docList[len] == event.getSource().get("v.text")){
                    docList.splice(len, 1);
                }
            }
        }
        component.set("v.selectedDocsAndAttachments", docList);
    },

    // method to navigate to record in lightning
    navigate : function(component, event, helper){
        var recordId = event.currentTarget.id;
        var sObectEvent = $A.get("e.force:navigateToSObject");
            sObectEvent .setParams({
            "recordId": recordId
        });
        sObectEvent.fire(); 
    }
})