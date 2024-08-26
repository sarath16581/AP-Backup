({
    init: function(cmp, event, helper) {
        //Call the helper method to parse the url.
        var urlVars = helper.parseUrlParam();
        //Get the DPID
        var dpidFromUrl = urlVars.dpId;
        cmp.set('v.dpidFromUrl',dpidFromUrl);
        var correctDeliveryAddress = cmp.get('v.wizardData.correctDeliveryAddress');
        var dpidFromOneTrackService = cmp.get("v.wizardData.dpid");
        //Check if the back button is pressed
        var baseUrl = window.location.href;
        if(baseUrl.includes("#"))
        {
            cmp.set("v.isFromBackButton", true);
        }
        //Auto progress the AME search if it is from a direct link and not from the back button
        if(!cmp.get("v.isFromBackButton") && (!$A.util.isEmpty(dpidFromUrl) || !$A.util.isUndefined(dpidFromUrl)) )
        {
            //Match the dpids returned from the url to that from the consignment service
            if (dpidFromUrl == dpidFromOneTrackService)
            {
                cmp.set("v.addressMatched",'Match');
                $A.enqueueAction(cmp.get('c.getAMEAddressFromDPID'));
                cmp.set('v.displaySpinner', true);
            }
        }
        
    },
    getAMEAddressFromDPID : function(cmp,event,helper) {
        var DPID = cmp.get("v.dpidFromUrl");
        var action = cmp.get("c.getAMEAddressString");
        action.setParams({
            "dpid": DPID
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var returnObj =  JSON.parse(response.getReturnValue());
                cmp.set("v.wizardData.correctDeliveryAddress", returnObj[0].singleLine);
                if(cmp.get("v.wizardData.hasQualifiedForSafeDropFlow"))
                {
                    //set the address strings into indiviual line items
                    cmp.set("v.wizardData.recipientAddressLine1",returnObj[0].semiStructured.addressLines[0]);
                    cmp.set("v.wizardData.recipientAddressLine2",returnObj[0].semiStructured.addressLines[1]);
                    cmp.set("v.wizardData.recipientCity",returnObj[0].semiStructured.locality);
                    cmp.set("v.wizardData.recipientState",returnObj[0].semiStructured.state);
                    cmp.set("v.wizardData.recipientPostcode",returnObj[0].semiStructured.postcode);
                }
                cmp.set("v.wizardData.dpidFromUrl",cmp.get("v.dpidFromUrl"));
                var correctDeliveryAddress = cmp.get('v.wizardData.correctDeliveryAddress');
                if(!$A.util.isEmpty(correctDeliveryAddress) || !$A.util.isUndefined(correctDeliveryAddress))
                {
                    cmp.set("v.selectedAddress",correctDeliveryAddress);
                    helper.redirectService(cmp,event,helper);
                    
                }
            }
            else if (state === "INCOMPLETE") {
                cmp.set('v.displaySpinner', false);
            }
                else if (state === "ERROR") {
                    cmp.set('v.displaySpinner', false);
                    cmp.set('v.error500', true);
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
        });
        // Enqueue action that returns a continuation
        $A.enqueueAction(action);
    },
    
    goForward: function (cmp, event, helper) {
        
        //Check if the dpid matches, or MRS is applied
        var addressMatch = cmp.get("v.addressMatched");
        if(addressMatch == 'noMatch')
        {
            cmp.set('v.wizardData.hasCustomerSeenSafeDrop', 'false');
            // decide network eligibility and set the isEligibleForMyNetworkAssignment flag
            helper.checkNetworkEligibility(cmp,event,helper);
            
            
            var isValid = helper.checkAllInputs(cmp, true);
            //-- If all validations are completed then move to next screen
            if(isValid){
                helper.gotoNextPage(cmp,'chasMissingItemAddressMismatchForm');
            } else {
                helper.showErrorSummary(cmp);
            }
            
        } 
        
        //If the addresses match , navigate to chasMissingItemForm screen
        else {
            cmp.set('v.wizardData.hasCustomerSeenSafeDrop', 'true');
            // decide network eligibility and set the isEligibleForMyNetworkAssignment flag
            helper.checkNetworkEligibility(cmp,event,helper);
            helper.gotoNextPage(cmp,'chasMissingItemForm');
            //push analytics for site-interact
            window.AP_ANALYTICS_HELPER.analyticsTrackInteraction(
                'site-interact',
                'form:' + cmp.get('v.pageTitle'),
                'item details: ' + 'safe drop:continue'
            );
        }
        
        
        
    },
    
    goBackHandler: function (cmp, event, helper) {
        //Check the base url of the page, this is to ascertain users getting directed from a direct link
        var baseUrl = window.location.href;
        if(baseUrl.includes("trackingId"))
        {
            window.location.href = window.location.href + '#';
        }
        //cmp.set("v.wizardData.correctDeliveryAddress",null);
        helper.gotoPrevPage(cmp);
        //push analytics for site-interact
        window.AP_ANALYTICS_HELPER.analyticsTrackInteraction(
            'site-interact',
            'form:' + cmp.get('v.pageTitle'),
            'item details: ' + 'address:back'
        );
        if(cmp.get("v.isOverriden"))
        {
            //push analytics for site-interact
            window.AP_ANALYTICS_HELPER.analyticsTrackInteraction(
                'site-interact',
                'form:' + cmp.get('v.pageTitle'),
                'item details: ' + 'address manual:back'
            );
        }
    },
    download : function (cmp, event, helper){
        helper.fileDownload(cmp);
        //Click tracking - push analytics for site-interact
        window.AP_ANALYTICS_HELPER.analyticsTrackInteraction(
            'site-interact',
            'form:' + cmp.get('v.pageTitle'),
            'item details: ' + 'safe drop:download photo'
        );
    },
    toggle : function(cmp, event, helper) {
        var position = cmp.get("v.rotate");
        if(position == 'down')
        {
            cmp.set("v.rotate",'top');
        }
        
        if(position == 'top')
        {
            cmp.set("v.rotate",'left');
        }
        if(position == 'left')
        {
            cmp.set("v.rotate",'right');
        }
        if(position == 'right')
        {
            cmp.set("v.rotate",'down');
        }
        //Click tracking - push analytics for site-interact
        window.AP_ANALYTICS_HELPER.analyticsTrackInteraction(
            'site-interact',
            'form:' + cmp.get('v.pageTitle'),
            'item details: ' + 'safe drop:rotate photo'
        );
        
    },
    onchange: function (cmp, event, helper) {
        var srcCmp = event.getSource();
        var fieldName = event.getParam("name");
        if (fieldName === 'recipientOrSenderRadioButtons') {
            helper.setRadioName(cmp, 'v.recipientOrSenderRadioGroup', 'v.wizardData.selectedRadio1', 'v.wizardData.selectedRadio1Name');
        }
        helper.checkInputs([srcCmp], true);
        cmp.set('v.checkInputsOnRender', true);
    },
    getOverrideAddress : function(cmp, event, helper) {
        helper.getOverrideAddress(cmp, event, helper);
    },
    getSelectedAddress : function(cmp, event, helper) {
        helper.getSelectedAddress(cmp, event, helper);
        //Click tracking - push analytics for site-interact
        /*window.AP_ANALYTICS_HELPER.analyticsTrackInteraction(
            'site-interact',
            'form:' + cmp.get('v.pageTitle'),
            'item details: ' + 'address:selected'
        );*/
    },
    getAddressTyped:function(cmp, event, helper) {
        helper.getAddressTyped(cmp, event, helper);
    },
    getShowError:function(cmp, event, helper) {
        helper.getShowError(cmp, event, helper);
    },
    checkOverride : function(cmp, event, helper) {
        var overriden = event.getParam('selected');
        cmp.set("v.isOverriden",overriden);
        //push analytics for 'helpsupport-form-navigate'
        helper.pushAnalytics(cmp, "item details:address manual");
        //Click tracking - push analytics for site-interact
        window.AP_ANALYTICS_HELPER.analyticsTrackInteraction(
            'site-interact',
            'form:' + cmp.get('v.pageTitle'),
            'item details: ' + 'item details:address:enter address manually'
        );
    },
    manualEntryFlow : function(cmp,event,helper) {
        //Click tracking - push analytics for site-interact
        window.AP_ANALYTICS_HELPER.analyticsTrackInteraction(
            'site-interact',
            'form:' + cmp.get('v.pageTitle'),
            'item details: ' + 'address manual:continue'
        );
        /*Manual address entry flow:
        1.Check if address is manually entered
        2.If address format is valid, navigate to the chasMissingItemWPage02 screen (non-safedrop flow)
        */
        var overriden =  cmp.get("v.isOverriden");
        if(overriden)
        {
            var formValid = helper.checkManualAddressisValid(cmp, event, helper);
            if(formValid)
            {
                
                helper.gotoNextPage(cmp, 'chasMissingItemWPage02');
            }
        }
    },
    callRedirectService : function(cmp,event,helper) {
        helper.redirectService(cmp,event,helper);
    },
    requestSurvey : function(cmp,event,helper) {
        //Click tracking - push analytics for site-interact
        window.AP_ANALYTICS_HELPER.analyticsTrackInteraction(
            'site-interact',
            'form:' + cmp.get('v.pageTitle'),
            'item details: ' + 'safe drop:no it helped'
        );
        cmp.set("v.didItHelp", true);
        //push analytics for 'helpsupport-form-navigate' for self-help
        helper.pushAnalytics(cmp,'item details:safe drop:it helped');
    }
    
    
})