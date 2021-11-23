/**************************************************
 Description:  Parcel Send Onboarding Helper

 History:
 --------------------------------------------------
 2019-03-20  hasantha.liyanage@auspost.com.au Created

 **************************************************/
({
    /**
     * ge the initial status of the contact, this is to inform the user that, the particular contact is eligible,
     * or already provisioned or the one that sent being failed.
     *
     * also retrieves the information use to validate the contact and display to the user
     *
     * @param component
     * @param helper
     */
    getStatusAndShowResult: function(component, helper) {
        var params = {
            contactId: component.get('v.contactId')
        };

        var callBack = function(result) {
            component.set('v.statusResponse', result);

            if(result) {
                // set the status of the onboarding request
                component.set('v.status', result.Status);
                // get the information to display on the UI
                helper.getContact(component,helper);
                helper.getRelatedRecordsByContact(component,helper);
            }
        };

        var errCallBack = function(result) {
            helper.showMessage(component,'Error occurred while retrieving status', 'error');
            console.log("ERROR: pso_parcelSendOnboardingHelper.getStatus() ",result);
        }

        var loader = component.find('loader');
        window.AP_LIGHTNING_UTILS.invokeController(component, "getStatus", params, callBack, errCallBack, false, loader);
    },

    /**
     * Create a new External Onboarding record
     *
     * @param component
     * @param helper
     * @param paramObj
     * @param resolve
     * @param reject
     */
    createOnboardingRecord: function(component, helper, paramObj, resolve, reject) {
        var contactId = component.get('v.contactId');
        if (contactId) {
            var params = {
                contactId: contactId
            };
            var callBack = function(rslt) {
                resolve(rslt);
            };

            var errCallBack = function(rslt) {
                helper.showMessage(component,'Error: Creating External Onboarding Request failed', 'error');
                reject(rslt);
            }
            var loader = component.find('loader');
            window.AP_LIGHTNING_UTILS.invokeController(component, "createOnboardingRequest", params, callBack, errCallBack, false, loader);
        }
    },

    /**
     * get the onboarding status of the contact,
     * apex controller method getStatus, access the
     *
     * @param component
     * @param helper
     * @param paramObj
     * @param resolve
     * @param reject
     */
    getStatus: function(component, helper, paramObj, resolve, reject) {
        var contactId = component.get('v.contactId');
        if (contactId) {
            var params = {
                contactId: contactId
            };
            var callBack = function(rslt) {
                resolve(rslt);
            };

            var errCallBack = function(rslt) {
                helper.showMessage(component,'Error: Validation failed', 'error');
                reject(rslt);
            }
            var loader = component.find('loader');
            window.AP_LIGHTNING_UTILS.invokeController(component, "getStatus", params, callBack, errCallBack, false, loader);
        }
    },

    /**
     * retieve the contact for more details to display on the UI
     *
     * @param component
     * @param helper
     */
    getContact: function(component,helper) {
        var params = {
            contactId: component.get('v.contactId')
        };
        var callBack = function(rslt) {
            component.set('v.contact', rslt);
        };

        var errCallBack = function(rslt) {
            console.log('ERROR:  pso_parcelSendOnboardinghHelper : contact()', rslt);
            helper.showMessage(component,'Error: retrieve Contact failed', 'error');
        }
        var loader =  component.find('loader');
        AP_LIGHTNING_UTILS.invokeController(component, "getContact", params, callBack, errCallBack, false, loader);
    },

    /**
     * THis methods os to call tje Camunda endpoint, before calling Camunda;
     * get status method will check whether any criteria has been changed while the page is opened, THen
     * this will create a new onboarding request record, then the sendOnboardingRequest method will retrieve the saved
     * External Onboarding Request record and prepare and send the request to Camunda
     *
     * @param component
     * @param helper
     */
    doOnboard: function(component, helper) {
        window.AP_LIGHTNING_UTILS.helperPromise(component, helper, {}, helper.getStatus)
            .then($A.getCallback(function(result) {
                // if an eligible contact or the contact is partially provisioned or Provisioning Errored
                if(result.isSuccess || result.Status == 'Partially Provisioned' || result.Status == 'Provisioning Error'){
                    // on success status check
                    window.AP_LIGHTNING_UTILS.helperPromise(component, helper, {}, helper.createOnboardingRecord)
                        .then($A.getCallback(function (result2) {
                            if(result2.isSuccess) {
                                // on success External Onboarding record creation
                                console.log('in doOnboard() createOnboardingRecord ', result2);

                                var callBack = function (result3) {
                                    if (result3 == null) {
                                        console.log('Error : doOnboard returned not payload');
                                        helper.showMessage(component,'Error : doOnboard returned not payload', 'error');
                                    } else if (result3.hasOwnProperty('errorMapLst') && result3.errorMapLst != null) {
                                        // raise error
                                        console.log('Error: doOnboard returned failed', result3);
                                        helper.showMessage(component,'Error: doOnboard returned failed', 'error');
                                    } else {
                                        // on successful Camunda call
                                        helper.getStatusAndShowResult(component, helper);
                                        helper.showMessage(component,'Success: Requested Onboarding Process, Successfully Submitted!', 'success');
                                        console.log('doOnboard : result', result3);
                                    }
                                };

                                helper.sendOnboardingRequest(component, helper, callBack);
                            } else {
                                console.log( 'error', 'Unable to create External Onboarding Record!');
                                helper.showMessage(component,'Unable to create External Onboarding Record!', 'error');
                            }

                        })).catch($A.getCallback(function (result2) {
                        console.log( 'error', result2);
                        helper.showMessage(component,result2, 'error');
                    }));
                } else {
                    helper.showMessage(component,'Unable to retrieve Status! May be this contact is not eligible to onboard any more, please refresh the page and try again!', 'error');
                    console.log( 'error', 'Unable to retrieve Status!', result);
                }
            })).catch($A.getCallback(function(result) {
                console.log( 'error', result);
            }));
    },

    /**
     * Callout to camunda,
     * this requires to avoid @auraEnabled methods as the endpoint call uses Continuation for the callout,
     * event fired in the method goes through the Asynch Framework
     *
     * @param component
     * @param helper
     * @param callBack
     */
    sendOnboardingRequest : function(component,helper, callBack){
        var contReqEvt = $A.get("e.c:AsynchApexContinuationRequest");

        contReqEvt.setParams({
            className : "pso_IAsynchApexContinuationImpl",
            methodName: "sendOnboardingRequest",
            methodParams : [component.get('v.contactId')],
            useAsynchCallout : true,
            callback : callBack
        });
        contReqEvt.fire();
    },

    getRelatedRecordsByContact: function(component) {
        var params = {
            contactId: component.get('v.contactId')
        };

        var callBack = function(rslt) {
            component.set('v.displayRecords', rslt);
        };

        var errCallBack = function(rslt) {
            console.log('ERROR:  pso_parcelSendOnboardinghHelper : getRelatedRecordsByContact()', rslt);
            helper.showMessage(component,'Error: retrieve all records failed', 'error');
        }
        var loader =  component.find('loader');
        AP_LIGHTNING_UTILS.invokeController(component, "getRelatedRecordsByContact", params, callBack, errCallBack, false, loader);
    },

    /**
     * Show messages on the page, lightning toast is not supported in classic,
     * this will invoke a method in MessagePannel component
     *
     * @param component
     * @param msgText
     * @param msgType
     */
    showMessage : function(component, msgText, msgType) {
        var messages = component.find("messages");
        messages.showMessage(msgText,msgType);

    },

})