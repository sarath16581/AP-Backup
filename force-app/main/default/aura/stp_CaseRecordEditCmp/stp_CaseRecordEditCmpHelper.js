/**
    *   2020.10.28 madhuri.awasthi@auspost.com.au REQ2310520 - Changed the mode of the error from Sticky to dismisble and 
    * 															handled error message createNewCase method
    */
({
    /**
    *   Create a new case .
    *   Invoke a consignment search, if the Consignment number is passed in
    */
    onCaseSubmit: function(component, event, helper ,fields){
        var consignmentNumber = component.find('consignmentNumber').get('v.value');
        var loader = component.get('v.loadingSpinner');
        if(consignmentNumber){
            AP_LIGHTNING_UTILS.helperPromise(component, helper, {}, helper.makeConsignmentCallout)
                .then($A.getCallback(function(result) {
                    loader[0].startWait();
                }))
                .catch($A.getCallback(function(result) {
                    // stop spinner for search result data table
                    loader[0].stopWait();
                    helper.showMyToast(component, helper, 'error', result);
                }));
        }
        helper.createNewCase(component, event, helper ,fields, consignmentNumber);
    },

    /**
    * Saving the case and Link the case to the consignment mentioned
    *
    */
    createNewCase: function(component, event, helper ,fields, consignmentNumber){
        console.log(JSON.stringify(fields));
        var params = {
            recordData : JSON.stringify(fields),
            'consignmentNo': consignmentNumber
        };

        var callBack = function (response) {
            // set case number and the status
            component.set('v.caseNumber', response);
            component.set('v.saved', true);

            // notification of success
            helper.showMyToast(component, helper, 'Success', "Case  "+response+" is created successfully.");
        };

        var errCallBack = function(result) {
            //var errors = result.getError();
            console.log('ERROR:  stp_caseRecordEditForm : createNewCase()', result);
           // if (errors) {
              helper.showMyToast(component, helper, 'error', result[0].message);
           // } else {
            //    helper.showMyToast(component, helper, 'error', 'Unknown error');
           // }
        };

        var loader = component.get('v.loadingSpinner');
        AP_LIGHTNING_UTILS.invokeController(component, "createNewCase", params, callBack, errCallBack, false, loader[0]);
    },

    /**
    * Callout to update the consignment search
    */
    makeConsignmentCallout: function(component, helper, paramObj, resolve, reject){
        var consignmentNumber = component.find('consignmentNumber').get('v.value');
        if(consignmentNumber){
            var callback = function(result) {
            if (result == null) {
                reject('Error Consignment Search returned not payload');
            } else if (result.hasOwnProperty('error') && result.error != null) {
                // raise error
                reject(result.error);
            } else {
                resolve(result);
            }

            // let's fire the async call to get the consignment detail, on call of this method will reach out to .NET
            // service and the .NET service come back to Salesforce and update the relevent consignment details along with event messages,
            // then we access the event messages with the getPOD method in this controller and to display them in the portal page.
            var consumerSrchEvt = $A.get("e.c:AsynchApexContinuationRequest");
            consumerSrchEvt.setParams({
                className: "ImageConsignmentSearch",
                methodName: "searchConsignment",
                methodParams: [consignmentNumber],
                callback: callback
            });
            consumerSrchEvt.fire();
            }
        }
    },


    /**
    *   Display message on UI
    *   Usage :
    *   hlpr.showMyToast(component,hlpr,'info', 'test messaging toast info');
    *   hlpr.showMyToast(component,hlpr,'error', 'test messaging toast error');
    *   hlpr.showMyToast(component,hlpr,'success', 'test messaging toast success');
    *   hlpr.showMyToast(component,hlpr,'warning', 'test messaging toast warning');
    */
    showMyToast: function(component, helper, type, message) {
     var toastEvent = $A.get("e.force:showToast");
     var mode = 'dismissible';
     if (type == 'error' || type == 'warning') {
         mode = 'dismissible';
     }
     toastEvent.setParams({
         type: type,
         mode: mode,
         message: message
     });
     toastEvent.fire();
    }

})