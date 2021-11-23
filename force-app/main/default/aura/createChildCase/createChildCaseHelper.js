({
    /* Function to retrieve the target record types based on source record type. */
	getRecordTypes : function(component, event, helper) {
        // let's start the spinner
        var loader = component.find('loader');
        //Set the source record type parameter.
        var params = {
            sourceRecordTypeId : component.get('v.parentCase').RecordTypeId
        };

        // everything went well, let the user see it
        var callbackSuccess = function(response){
            component.set("v.recordTypePicklist", response);
        };
        // something went wrong, let the user know
        var callbackFail = function(response){
            console.log('error '+response[0].message);
            helper.showMessage(component, event, helper, response[0].message, 'Error', 'error');
        };

        // invoke the apex controller method getChildRecordTypes
        AP_LIGHTNING_UTILS.invokeController(component, 'getChildRecordTypes', params, callbackSuccess, callbackFail, false, loader);

    },

    /* Function to insert and create a child case for Service Delivery. */
    createChildCase : function(component, event, helper, fields) {
        component.set("v.displayEditForm", false);
        // let's start the spinner
        var loader = component.find('loader');
        //Set the source and target record type, fields and parent Id parameters.
        var params = {
            recordData: JSON.stringify(fields),
            sourceRecordTypeId: component.get('v.parentCase').RecordTypeId,
            targetRecordTypeId: component.get('v.selectedRecordType'),
            parentId: component.get('v.recordId'),
            selectedDocsAndAttachmentIds : component.get('v.selectedDocsAndAttachments')
        };

        // everything went well, let the user see it
        var callbackSuccess = function(response){
            // set case number and the status
            component.set('v.caseNum', response);
            // notification of success
            helper.showMessage(component, event, helper, "Child case "+component.get('v.caseNum')+" is created successfully.", 'Success', 'success');
            // refresh the console view : WARNING: might need to find a way to refresh just the related cases,
            $A.get('e.force:refreshView').fire();
            
        };

        // something went wrong, let the user know
        //response.getErros()[0].message
        var callbackFail = function(response){
            helper.showMessage(component, event, helper, response[0].message, 'Error', 'error');
        };

        // invoke the apex controller method getFieldSetForSave, this will read the fieldset for the case
        AP_LIGHTNING_UTILS.invokeController(component, 'createChildCase', params, callbackSuccess, callbackFail, false, loader);

    },

    /* Function to validate mandatory fields before creating a child case*/
    validateFields : function(component, event, fields) {
        var errorMessage = '';
        var fieldSetList = component.get('v.fieldSetList');

        //Loop through the field set fields.
        for (var i = 0; i < fieldSetList.length; i++) {

            //Check if the field is required or not.
            if(fieldSetList[i].required){
                fieldSetList[i].message = '';
                if(fields[fieldSetList[i].fieldPath] === null || fields[fieldSetList[i].fieldPath] === ''){
                    errorMessage += fieldSetList[i].label+', ';
                    //Set the validation message for the field.
                    fieldSetList[i].message = fieldSetList[i].label +' is required';
                }
            }
        }
        //Set the field set.
        component.set('v.fieldSetList', fieldSetList);
        return errorMessage;
    },

    // utility method to show toast messages
    showMessage : function(component, event, helper, msgText, title, type){
        var toast = $A.get("e.force:showToast");
        //Set the parameters.
        toast.setParams({
            title : title,
            message: msgText,
            duration: ' 1000',
            type: type,
            mode: 'dismissible'
        });
        toast.fire();
    },

    // Load attachments related to the parent case by passing record Id
    loadAttachments : function(component, event, helper){
        var loadAttachmentsFromApex = component.get('c.getAttachmentList');
        loadAttachmentsFromApex.setParams({
            "parentCaseId" : component.get("v.recordId")
        });
        loadAttachmentsFromApex.setCallback(this, function(response){
            var state = response.getState();
            if(state == 'SUCCESS'){
                component.set("v.attachmentList",response.getReturnValue());
            }
            else if(state == 'ERROR'){
                console.log('error '+response.getError()[0].message);
                helper.showMessage(component, event, helper, response.getError()[0].message, 'Error', 'error');
            }
        });
        $A.enqueueAction(loadAttachmentsFromApex);
    },

    // Load documents/files related to the parent case by passing record Id
    loaddocuments : function(component, event, helper){
        var loaddocumentsFromApex = component.get('c.getDocumentList');
        loaddocumentsFromApex.setParams({
            "parentCaseId" : component.get("v.recordId")
        });
        loaddocumentsFromApex.setCallback(this, function(response){
            var state = response.getState();
            if(state == 'SUCCESS'){
                component.set("v.documentList",response.getReturnValue());
            }
            else if(state == 'ERROR'){
                console.log('error '+response.getError()[0].message);
                helper.showMessage(component, event, helper, response.getError()[0].message, 'Error', 'error');
            }
        });
        $A.enqueueAction(loaddocumentsFromApex);
    },

    //check if sharing of file and attachments are enabled for the selected record types
    sharefileandAttachmentCheck : function(component, event, helper){
        var action = component.get('c.checkFileAndAttachmentSharing');
        action.setParams({
            sourceRecordTypeId : component.get('v.parentCase').RecordTypeId,
            targetRecordTypeId : component.get('v.selectedRecordType')
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state == 'SUCCESS'){
                component.set("v.shareFileAndAttachment",response.getReturnValue());
            }
            else if(state == 'ERROR'){
                console.log('error '+response.getError()[0].message);
                helper.showMessage(component, event, helper, response.getError()[0].message, 'Error', 'error');
            }
        });
        $A.enqueueAction(action);
    }
})