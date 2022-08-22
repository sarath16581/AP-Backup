/**
 * Created by hasan on 9/08/2022.
 */

({
    redirectService: function (cmp, event, helper) {

        cmp.set('v.showInvalidWithinEDDMessage', false);
        //Check if address selected from the service is valid
        var formValid = helper.validateAddressNotNull(cmp, true);
        if (formValid) {
            cmp.set('v.displaySpinner', true);
            this.getEDDServiceEstimates(cmp, event, helper);
        } else {
            cmp.set("v.inputError", "true");
        }
    },

    checkManualAddressisValid: function (cmp, event, helper) {
        var isValid = true;
        var inputErrors = cmp.get("v.inputErr");
        var inputFieldCount = cmp.get("v.inputFieldCount");
        var overrideAddr = cmp.get("v.overrideAddress");
        var selectedAddr = cmp.get("v.selectedAddress");
        if (inputErrors.length > 0 || inputFieldCount < 4) {
            //isValid = this.updateErrorSummary(cmp,inputErrors);
            isValid = false;
            cmp.set("v.inputFieldError", true);
        } else {
            if (
                ($A.util.isEmpty(overrideAddr) || $A.util.isUndefined(overrideAddr)) &&
                ($A.util.isEmpty(selectedAddr) || $A.util.isUndefined(selectedAddr))
            ) {
                isValid = false;
                cmp.set("v.inputFieldError", true);
            }
        }
        return isValid;
    },
    showSpinner: function (cmp, event, helper) {
        cmp.set("v.isLoading", true);
    },
    getEDDServiceEstimates : function (component,event, helper)
    {
        try {
            component.set("v.isLoading", true);
            // call server method to invoke the EDD service
            var action = component.get("c.getEDDEstimates");
            // set method parameters
            var objParams = {
                'articleId': component.get('v.wizardData.trackingId'), //
                'recipientPostcode': component.get('v.wizardData.recipientPostcode') // post code of selected address
            };
            action.setParams(objParams);

            // server side return
            action.setCallback(this, function (response) {
                let status = response.getState();
                if (status === 'SUCCESS') {
                    var returnObj = JSON.parse((JSON.stringify(response.getReturnValue())));
                    // update the wizard with the response data, else use the previous copy of the wizard data
                    component.set('v.wizardData.deliveredByDateOrEDD', $A.util.isEmpty(returnObj["deliveredByDateOrEDD"]) ? component.get('v.wizardData.deliveredByDateOrEDD') : returnObj["deliveredByDateOrEDD"]);
                    component.set('v.wizardData.deliveredByDateFrom', $A.util.isEmpty(returnObj["deliveredByDateFrom"]) ? component.get('v.wizardData.deliveredByDateFrom') : returnObj["deliveredByDateFrom"]);
                    component.set('v.wizardData.deliveredByDateTo', $A.util.isEmpty(returnObj["deliveredByDateTo"]) ? component.get('v.wizardData.deliveredByDateTo') : returnObj["deliveredByDateTo"]);
                    component.set('v.wizardData.deliveredByDateToUntil', $A.util.isEmpty(returnObj["deliveredByDateToUntil"]) ? component.get('v.wizardData.deliveredByDateToUntil') : returnObj["deliveredByDateToUntil"]);
                    component.set('v.wizardData.isEnquiryDateWithinEDD', $A.util.isEmpty(returnObj["isEnquiryDateWithinEDD"]) ? component.get('v.wizardData.isEnquiryDateWithinEDD') : returnObj["isEnquiryDateWithinEDD"]);
                    component.set('v.wizardData.isEnquiryDateWithinEDDPlusBusinessdays', $A.util.isEmpty(returnObj["isEnquiryDateWithinEDDPlusBusinessdays"]) ? component.get('v.wizardData.isEnquiryDateWithinEDDPlusBusinessdays') : returnObj["isEnquiryDateWithinEDDPlusBusinessdays"]);
                    component.set('v.wizardData.isEnquiryDatePastEDDPlusBusinessdays', $A.util.isEmpty(returnObj["isEnquiryDatePastEDDPlusBusinessdays"]) ? component.get('v.wizardData.isEnquiryDatePastEDDPlusBusinessdays') : returnObj["isEnquiryDatePastEDDPlusBusinessdays"]);
                    component.set('v.wizardData.deliveredByDatePlusBusinessDays', $A.util.isEmpty(returnObj["deliveredByDatePlusBusinessDays"]) ? component.get('v.wizardData.deliveredByDatePlusBusinessDays') : returnObj["deliveredByDatePlusBusinessDays"]);
                    component.set('v.wizardData.isEDDEstimated', $A.util.isEmpty(returnObj["isEDDEstimated"]) ? component.get('v.wizardData.isEDDEstimated') : returnObj["isEDDEstimated"]);
                    component.set('v.wizardData.isNoEddReturned', $A.util.isEmpty(returnObj["isNoEddReturned"]) ? component.get('v.wizardData.isNoEddReturned') : returnObj["isNoEddReturned"]);
                    component.set('v.wizardData.eddStatus', $A.util.isEmpty(returnObj["eddStatus"]) ? component.get('v.wizardData.eddStatus') : returnObj["eddStatus"]);
                    if(!$A.util.isEmpty(component.get('v.wizardData.eddStatus')) && component.get('v.wizardData.eddStatus') === 'ON_TIME') {
                        component.set('v.showInvalidWithinEDDMessage', true);
                        component.set("v.isLoading", false);
                        component.set('v.eddDisplayDate',helper.getEDDDateString(component, event, helper));
                        return;
                    } else {
                        component.set("v.isLoading", false);
                        helper.gotoNextPage(component, "chasMissingItemWPage02");
                    }
                } else if (state === "INCOMPLETE") {
                    component.set('v.displaySpinner', false);
                    component.set("v.isLoading", false);
                    // Enable debugging if required
                } else if (state === "ERROR") {
                    component.set('v.displaySpinner', false);
                    component.set('v.error500', true);
                    component.set("v.isLoading", false);
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " +
                                errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                }
            })

            $A.enqueueAction(action);
        } catch (err) {
            component.set("v.isLoading", false);
            console.log('ERROR EDD service estimates: '+err);
            throw err;
        }
    },
    /**
     * get the EDD date formatted for display
     * If the EDD has a date range show between ranges eg:  Thu 11 - Tue 16 August
     * otherwise show the on date Tue 16 August
     * @param cmp
     * @param event
     * @param helper
     * @returns {string}
     */
    getEDDDateString: function (cmp, event, helper) {
        let disDate = '';
        if (cmp.get('v.wizardData.deliveredByDateTo') != null){
            const eddFromDate = new Date(cmp.get('v.wizardData.deliveredByDateFrom'));
            const eddToDate = new Date(cmp.get('v.wizardData.deliveredByDateTo'));
            // format for weekday day - weekday day month eg: Thu 11 - Tue 16 August
            disDate = ' ' + eddFromDate.toLocaleString("en-US", {weekday: 'short'}) + ' ' + eddFromDate.toLocaleString("en-US", {day: 'numeric'})
                + ' - ' + eddToDate.toLocaleString("en-US", {weekday: 'short'}) + ' ' + eddToDate.toLocaleString("en-US", {day: 'numeric'}) + ' ' +eddToDate.toLocaleString("en-US", {month:'long'});
        } else {
            // format for weekday day month eg:Tue 16 August
            const eddDeliveredByDate = new Date(cmp.get('v.wizardData.deliveredByDateOrEDD'));
            disDate = ' ' + eddDeliveredByDate.toLocaleString("en-US", {weekday: 'short'}) + ' ' + eddDeliveredByDate.toLocaleString("en-US", {day: 'numeric'}) + ' ' +eddDeliveredByDate.toLocaleString("en-US", {month:'long'});
        };
        return disDate;
    },

    getOverrideAddress : function(cmp, event, helper) {
        //reset the selected address variable from the previous search
        cmp.set("v.selectedAddress",'');

        var streetAddress = event.getParam('searchterm');
        // create a empty array to store map keys
        var allInputs = [];
        var addressEntered='';
        var count = 0;
        for (var singlekey in streetAddress) {
            if(streetAddress[singlekey] == '') {
                allInputs.push(singlekey);

            } else {
                //set the address strings into indiviual line items
                cmp.set("v.wizardData.recipientAddressLine1",streetAddress['addressLine1']);
                cmp.set("v.wizardData.recipientAddressLine2",streetAddress['addressLine2']);
                cmp.set("v.wizardData.recipientCity",streetAddress['city']);
                cmp.set("v.wizardData.recipientState",streetAddress['state']);
                cmp.set("v.wizardData.recipientPostcode",streetAddress['postcode']);
                if(streetAddress[singlekey]) {
                    addressEntered = addressEntered + streetAddress[singlekey] + ' ';
                    if(singlekey != 'addressLine2') {
                        count = count + 1;
                    }
                }
            }
        }
        cmp.set("v.inputFieldCount", count);
        cmp.set("v.inputErr",allInputs);
        // set the manual address entered
        if(addressEntered != null && addressEntered !='undefined') {
            //set the wizard data with the override address
            cmp.set("v.overrideAddress",addressEntered);
            cmp.set('v.wizardData.correctDeliveryAddress', addressEntered);
            cmp.set('v.wizardData.recipientDeliveryAddress', addressEntered);

        }
    },

    getShowError : function(cmp, event, helper) {
        var showerror = event.getParam('inputError');
        cmp.set("v.showError",showerror);
    },

    getAddressTyped : function(cmp, event, helper) {
        var streetAddress = event.getParam('searchAddressTerm');
        cmp.set("v.addressTyped",streetAddress);
    },

    pushAnalytics : function(cmp, step) {
        // we expect something to be returned here, if nothing returned means a technical issue
        /*if(cmp.get('v.wizardData.eddStatus') != '') {
            var duplicateCaseText = 'new';
            if(cmp.get('v.wizardData.duplicateCase') != '') {
                duplicateCaseText = 'duplicate';
            }
            var latestEventLocationMessage = cmp.get('v.wizardData.latestEventLocationMessage');
            var alertMessage=cmp.get('v.wizardData.trackStatusValue');
            if(!$A.util.isEmpty(latestEventLocationMessage) || !$A.util.isUndefined(latestEventLocationMessage))
            {
                alertMessage = latestEventLocationMessage;

            }

            var isEligibleForMyNetworkAssignment = cmp.get('v.wizardData.isEligibleForMyNetworkAssignment') ? 'yes' : 'no';

            // building the analytics params object
            var analyticsObject = {
                form: {
                    name: 'form:' + cmp.get('v.pageTitle'),
                    step: step,
                    stage: '',
                    detail: 'article status='+alertMessage+'|case='+duplicateCaseText + '|network eligibility='+isEligibleForMyNetworkAssignment,
                    product: cmp.get('v.wizardData.trackingId')
                }
            };

            // calling the analytics API methods
            window.AP_ANALYTICS_HELPER.trackByObject({
                trackingType: 'helpsupport-form-navigate',
                componentAttributes: analyticsObject
            });

        }*/
    },

})