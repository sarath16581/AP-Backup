/**
 * Created by nmain on 31/10/2017.
 * 2020-11-23 hara.sahoo@auspost.com.au Special handling for 403 response code for missing item form
 */
 ({   
    callTrackingNumberService : function(cmp, event, helper) {
        //helper.gotoNextPage(cmp,'chasMissingItemWPage02');
        // Disable button actions if still loading.
        if (cmp.get('v.isLoading')) return;
        // make Spinner attribute true for display loading spinner 
        cmp.set("v.isLoading", true);
        cmp.set('v.error500', false);
        
        //-- checking if Tracking Number is entered
        var isTrackingNumEntered = helper.validateTrackingNumber(cmp.find("ChasTrackingId"), true);
        
        if (isTrackingNumEntered ) {
            if (cmp.get('v.wizardData.trackingId') != cmp.get('v.wizardData.pretrackingId')) {
                //-- Trcking number is changed, so make a server call
                
                var action = cmp.get("c.searchTrackingNumber");
                action.setParams({ "trackingNumber" : cmp.get("v.wizardData.trackingId") });
                
                action.setCallback(this, function(response) {
                    var state = response.getState();
                    var trackingNumInputCmp = cmp.find("ChasTrackingId");
                    
                    if (state === "SUCCESS") {
                        var trackingId = cmp.get("v.wizardData.trackingId");
                        //-- Emptying all the wizard Data
                        cmp.set('v.wizardData', {});
                        //--Setting Tracking Number again
                        cmp.set('v.wizardData.trackingId',trackingId);
                        var returnObj =  JSON.parse((JSON.stringify(response.getReturnValue())));
                        //-- dummy set
                        cmp.set('v.wizardData.eddStatus','xxxxxxxx');  //-- If not setting this then EDD passed deflection is not showing next time search(if used closed this manually before) 
                        cmp.set('v.wizardData.senderOrRecipientType', returnObj["itemType"]);
                        cmp.set('v.wizardData.parcelOrLetter', returnObj["articleType"]);
                        cmp.set('v.wizardData.eddStatus', returnObj["eddStatus"]);
                        cmp.set('v.wizardData.dpid', returnObj["dpid"]);
                        cmp.set('v.wizardData.articleId', returnObj["articleId"]);
                        cmp.set('v.wizardData.duplicateCase', returnObj["duplicateCase"]);
                        cmp.set('v.wizardData.isReturnToSender', returnObj["isReturnToSender"]);
                        cmp.set('v.wizardData.isRedirectApplied', returnObj["isRedirectApplied"]);
                        cmp.set('v.wizardData.hasSignature', returnObj["hasSignature"]);
                        cmp.set('v.wizardData.safedropDelivered', returnObj["safedropDelivered"]);
                        cmp.set('v.wizardData.enqSubtype', returnObj["enqSubtype"]);
                        cmp.set('v.wizardData.wcid', returnObj["wcid"]);
                        cmp.set('v.wizardData.latestEventLocation', returnObj["latestEventLocation"]);
                        cmp.set('v.wizardData.latestEventLocationMessage', returnObj["latestEventLocationMessage"]);
                        cmp.set('v.wizardData.trackingNumSerachStatusCode', returnObj["trackingNumSerachStatusCode"]);
                        cmp.set('v.wizardData.trackStatusValue', returnObj["trackStatusValue"]);
                        cmp.set('v.wizardData.deliveredByDateOrEDD', returnObj["deliveredByDateOrEDD"]);
                        cmp.set('v.wizardData.deliveredByDateFrom', returnObj["deliveredByDateFrom"]);
                        cmp.set('v.wizardData.deliveredByDateTo', returnObj["deliveredByDateTo"]);
                        cmp.set('v.wizardData.deliveredByDateToUntil', returnObj["deliveredByDateToUntil"]);
                        cmp.set('v.wizardData.isEnquiryDateWithinEDDPlusBusinessdays', returnObj["isEnquiryDateWithinEDDPlusBusinessdays"]);
                        cmp.set('v.wizardData.isEnquiryDatePastEDDPlusBusinessdays', returnObj["isEnquiryDatePastEDDPlusBusinessdays"]);
                        cmp.set('v.wizardData.isEnquiryDateWithinEDD', returnObj["isEnquiryDateWithinEDD"]);
                        cmp.set('v.wizardData.deliveredByDatePlusBusinessDays', returnObj["deliveredByDatePlusBusinessDays"]);
                        //cmp.set('v.wizardData.deliveredByDateFormatted', returnObj["deliveredByDateFormatted"]);
                        cmp.set('v.wizardData.isEligibleForMyNetworkAssignment', returnObj["isEligibleForMyNetworkAssignment"]);
                        cmp.set('v.wizardData.latestDeliveredScanWcid', returnObj["latestDeliveredScanWcid"]!= null?returnObj["latestDeliveredScanWcid"]:returnObj["previousDeliveredScanWcid"] );
                        cmp.set('v.wizardData.isNoEddReturned', returnObj["isNoEddReturned"]);
                        cmp.set('v.wizardData.isEDDEstimated', returnObj["isEDDEstimated"]);
                        
                        if (returnObj["trackingNumSerachStatusCode"] == 400) {
                            //trackingNumInputCmp.set("v.error", "Unconfirmed tracking number. It may be incorrect, or not in our system yet.");
                            // trackingNumInputCmp.set("v.error", "Unconfirmed tracking number. It may be incorrect, or not in our system yet. <a target='_blank' href='https://auspost.com.au/help-and-support/answers?s=000003988'><u>Learn more</u></a>");
                            trackingNumInputCmp.set("v.error", "Unconfirmed number. It may be incorrect, or not in our system yet.");
                            cmp.set('v.error400', true);
                        } 
                        //Special handling for response code 403
                        else if(returnObj["trackingNumSerachStatusCode"] == 403) {
                            helper.gotoNextPage(cmp);
                        }
                        else if(returnObj["trackingNumSerachStatusCode"] == 404) {
                            /* Commented and Added below code on 3/10/2018 for International Missing Item Changes.
                               To Remove blocker when tracking number is not trackable for international parcels. */  
                            //trackingNumInputCmp.set("v.error", "Sorry, trackingID is not trackable");
                            //Set the Tracking Number
                            cmp.set('v.wizardData.pretrackingId',trackingId);
                            //Set the Item Type as 'International'
                            // DDS-5488: When consignment API returns 404, route the cases to domestic queue
                            cmp.set('v.wizardData.senderOrRecipientType', "Domestic");
                            //Proceed to next page
                            helper.gotoNextPage(cmp);
                            return;                            
                        }
                          else if(returnObj["trackingNumSerachStatusCode"] == 500) {
                            cmp.set('v.error500', true);
                            
                        } else if(returnObj["trackingNumSerachStatusCode"]== 200) {
                            //-- Check EDD is not passed, if yes Display message and not allow user to proceed
                            //if (returnObj["eddStatus"] != 'dateNotPassed') {
                            cmp.set('v.wizardData.pretrackingId',trackingId);
                            // get the dpid from the response and do a null check
                            var dpidFromOneTrackService = cmp.get("v.wizardData.dpid");
                            // get the boolean for inflight redirection
                            var isRedirectApplied = cmp.get("v.wizardData.isRedirectApplied");
                            
                            //safedrop flow - checks for SAFE_DROP, RTS Scan event, DPid, inflight redirection before presenting address validations screen
                            if(returnObj["eddStatus"] == 'SAFE_DROP' && returnObj["isReturnToSender"] == false && !$A.util.isEmpty(dpidFromOneTrackService) && !isRedirectApplied )
                            {
                                helper.gotoNextPage(cmp,'chasMissingItemAddressValidation');
                                cmp.set("v.wizardData.hasQualifiedForSafeDropFlow",true);
                                /*2020-10-09 - Code removed - as safedrop is now rolledout to nation-wide*/
                                //If the delivered location includes NSW, only then navigate to the safedrop flow- this is a temporary solution and needs to be refactored later
                                /*var deliveredLocation = cmp.get("v.wizardData.latestEventLocation");
                                if(!$A.util.isEmpty(deliveredLocation))
                                {
                                    var deliveredLocation = deliveredLocation.toUpperCase();
                                    if(deliveredLocation.includes(" NSW") || deliveredLocation.includes("NSW ") || deliveredLocation.includes(" ACT") || deliveredLocation.includes("ACT "))
                                    {
                                        helper.gotoNextPage(cmp,'chasMissingItemAddressValidation');
                                    }
                                    // for all other states, other than NSW and ACT, take them to non-safedrop flow
                                    else
                                    {
                                        helper.gotoNextPage(cmp);
                                    }
                                }
                                else
                                {
                                    helper.gotoNextPage(cmp);
                                }*/
                            }
                            //else navigate to non-safedrop flow
                            else
                            {
                                helper.gotoNextPage(cmp);
                            }
                            
                            return;
                            
                        } else {
                            //-- Diff status code put some generic Error
                            cmp.set('v.error500', true);
                        }
                        
                    } else if (state === "INCOMPLETE") {
                        // do something
                    } else if (state === "ERROR") {
                        var errors = response.getError();
                        if (errors) {
                            if (errors[0] && errors[0].message) {
                                console.log("Error message: " + errors[0].message);
                            }
                        } else {
                            console.log("Unknown error");
                        }
                        cmp.set('v.error500', true);
                    }
                    cmp.set("v.isLoading", false);
                    
                });
                
                $A.enqueueAction(action);
            } /* Commented - not relevant- 12/01/2021
               else {
                //-- No change in tracking number
                helper.gotoNextPage(cmp);
            }*/
            //-- No change in tracking number, no need to make a callout, proceed based on the previous stored values
            else {
                if(cmp.get("v.wizardData.hasQualifiedForSafeDropFlow"))
                {
                    helper.gotoNextPage(cmp,'chasMissingItemAddressValidation');
                } else 
                {
                    helper.gotoNextPage(cmp);
                }
            }
            
        } else {
            cmp.set("v.isLoading", false);
        }
    },
   /* validateFormAndShowErrors: function(component){
        console.log('validateFormAndShowErrors........');
        var showOrHideAllFieldVlidationError =  component.get('v.showOrHideAllFieldVlidationError');
        console.log('showOrHideAllFieldVlidationError='+showOrHideAllFieldVlidationError);
        var isValid = true;
        
        var trackingId = component.find("trackingId");
        console.log('trackingId='+trackingId);
        var trackingIdLabel = 'Tracking Number';//trackingId.get("v.label");
        var trackingIdVal = trackingId.get("v.value");
        console.log('trackingIdVal='+trackingIdVal);
        if(( (!trackingIdVal || trackingIdVal.trim().length === 0 ))){
            if(showOrHideAllFieldVlidationError){
                trackingId.set("v.errors", [{message:"Enter a valid tracking number"}]);
            }
            isValid = false;
            
        }else{
            if(showOrHideAllFieldVlidationError){
                trackingId.set("v.errors", null);
            }
        }
        
        //-- validating tracking number Ststus
        var trackingNumStatucCode = component.get('v.wizardData.trackingNumSValStatusCode');
        if( trackingNumStatucCode== 404  || trackingNumStatucCode == 400 || trackingNumStatucCode == 500){
            isValid =false;
            if( trackingNumStatucCode== 400){
                 trackingId.set("v.errors", [{message:"Sorry trackingID is an invalid number"}]); 
            }else if( trackingNumStatucCode== 404){
                trackingId.set("v.errors", [{message:"Sorry trackingID is not trackable"}]); 
            }else if( trackingNumStatucCode== 500){
                trackingId.set("v.errors", [{message:"Whoops, something's gone wrong"}]); 
            }
          
        }else{
             trackingId.set("v.errors", null);
        }
        
        console.log('isValid='+isValid);
        if(isValid){
            component.set('v.enableOrDisableNextBtnVal', 'Enable');
        }else{
            component.set('v.enableOrDisableNextBtnVal', 'Disable');
        }
        return isValid;
    } */
    /* Added below function on 29/10/2018 for parsing the 
    Tracking Id passed from App view to the Missing Items form. */
    parseUrlParam: function() {
		var varsObj = {},
			arr = [],
			keyVal = [];
        //Fetch the trackingId parameter appended after query string.
		if (location.search !== null) {
            //Replace '?' with blank and split by '&'
            arr = location.search.replace('?/', '').replace('?', '').split('&');
            //Looping through the parameters.
            for (var i = 0; i < arr.length; i+=1) {
                //Split by '=' and get the value.
                keyVal = arr[i].split("=");
				if (keyVal.length === 2) {
					varsObj[keyVal[0]] = keyVal[1];
				}
            }
        }
		return varsObj; 
	}
})