/**
 * Created by nmain on 31/10/2017.
 * 2020-11-23 hara.sahoo@auspost.com.au Special handling for 403 response code for missing item form
 * 2022-05-19 mahesh.parvathaneni@auspost.com.au DDS-7472: When consignment API returns 404, show the warning message
 * 2022-08-04 Hasantha Liyanage - DDS-11626: before edd
 * 2022-09-12 mahesh.parvathaneni@auspost.com.au DDS-12166: Added analytics for invalid tracking number error
 * 2023-11-20 - Nathan Franklin - Adding a tactical reCAPTCHA implementation to assist with reducing botnet attack vectors (INC2251557)
 */
 ({
    callTrackingNumberService : function(cmp, event, helper) {
        //helper.gotoNextPage(cmp,'chasMissingItemWPage02');
        // Disable button actions if still loading.
        if (cmp.get('v.isLoading')) return;
        // make Spinner attribute true for display loading spinner 
        cmp.set("v.isLoading", true);
		cmp.set('v.articleTrackingCaptchaEmptyError', false);
        cmp.set('v.error500', false);

        //-- checking if Tracking Number is entered
        var isTrackingNumEntered = helper.validateTrackingNumber(cmp.find("ChasTrackingId"), true);
        if (isTrackingNumEntered ) {
           if (cmp.get('v.wizardData.trackingId') != cmp.get('v.wizardData.pretrackingId')) {

				let controllerMethod = 'c.searchTrackingNumber';
				let trackingParams = {trackingNumber: cmp.get("v.wizardData.trackingId")}
				const authUserData = cmp.get('v.authUserData');
				// force the user to enter a captcha value if they aren't logged in
				if(!authUserData || !authUserData.isUserAuthenticated) {

					controllerMethod = 'c.searchTrackingNumberWithCaptcha';

					const captchaToken = cmp.get('v.articleTrackingCaptchaToken');
					trackingParams.captchaToken = captchaToken;
					
					if(!captchaToken) {
						cmp.set('v.articleTrackingCaptchaEmptyError', true);
						cmp.set('v.isLoading', false);
						return;
					}
		
				}

				//-- Trcking number is changed, so make a server call
				cmp.set("v.showInvalidWithinEDDMessage", false)
				cmp.set("v.showInvalidMessage", false);
				cmp.set("v.showCallerType",false);
				cmp.set("v.wizardData.hasQualifiedForLateFlow",false);
				cmp.set('v.wizardData.skipDeflectionPage', false);

                var action = cmp.get(controllerMethod);
                action.setParams(trackingParams);
                action.setCallback(this, function(response) {

					// means the user will need to reverify 
					cmp.set('v.articleTrackingCaptchaToken', '');

                    var state = response.getState();
                    var trackingNumInputCmp = cmp.find("ChasTrackingId");
                    
                    if (state === "SUCCESS") {
                        var trackingId = cmp.get("v.wizardData.trackingId");
                        //-- Emptying all the wizard Data
                        cmp.set('v.wizardData', {});
                        //--Setting Tracking Number again
                        cmp.set('v.wizardData.trackingId',trackingId);
                        var returnObj =  JSON.parse((JSON.stringify(response.getReturnValue())));
                        // DDS-7977: pass attributes from wrapper object to wizard data
                        cmp.set('v.wizardData.allArticlesSuccessful', returnObj["allArticlesSuccessed"]);
                        cmp.set('v.wizardData.articles', returnObj["trackingNumberDetails"]);
                        cmp.set('v.wizardData.isEligibleForMultipleArticleSelection', returnObj["isEligibleForMultipleArticleSelection"]);

                        let isEligibleForMultipleArticleSelection = returnObj["isEligibleForMultipleArticleSelection"];
                        if (!$A.util.isEmpty(isEligibleForMultipleArticleSelection)
                            && !$A.util.isUndefined(isEligibleForMultipleArticleSelection)
                            && isEligibleForMultipleArticleSelection == false
                            && !$A.util.isUndefined(returnObj["trackingNumberDetails"])){
                            let lArticle = returnObj["trackingNumberDetails"][0];
                            //-- dummy set
                            cmp.set('v.wizardData.eddStatus','xxxxxxxx');  //-- If not setting this then EDD passed deflection is not showing next time search(if used closed this manually before)
                            cmp.set('v.wizardData.senderOrRecipientType', lArticle["itemType"]);
                            cmp.set('v.wizardData.parcelOrLetter', lArticle["articleType"]);
                            cmp.set('v.wizardData.eddStatus', lArticle["eddStatus"]);
                            cmp.set('v.wizardData.dpid', lArticle["dpid"]);
                            cmp.set('v.wizardData.articleId', lArticle["articleId"]);
                            cmp.set('v.wizardData.duplicateCase', lArticle["duplicateCase"]);
                            cmp.set('v.wizardData.isReturnToSender', lArticle["isReturnToSender"]);
                            cmp.set('v.wizardData.isRedirectApplied', lArticle["isRedirectApplied"]);
                            cmp.set('v.wizardData.hasSignature', lArticle["hasSignature"]);
                            cmp.set('v.wizardData.safedropDelivered', lArticle["safedropDelivered"]);
                            cmp.set('v.wizardData.enqSubtype', lArticle["enqSubtype"]);
                            cmp.set('v.wizardData.wcid', lArticle["wcid"]);
                            cmp.set('v.wizardData.latestEventLocation', lArticle["latestEventLocation"]);
                            cmp.set('v.wizardData.latestEventLocationMessage', lArticle["latestEventLocationMessage"]);
                            cmp.set('v.wizardData.trackingNumSerachStatusCode', lArticle["trackingNumSerachStatusCode"]);
                            cmp.set('v.wizardData.trackStatusValue', lArticle["trackStatusValue"]);
                            cmp.set('v.wizardData.deliveredByDateOrEDD', lArticle["deliveredByDateOrEDD"]);
                            cmp.set('v.wizardData.deliveredByDateFrom', lArticle["deliveredByDateFrom"]);
                            cmp.set('v.wizardData.deliveredByDateTo', lArticle["deliveredByDateTo"]);
                            cmp.set('v.wizardData.deliveredByDateToUntil', lArticle["deliveredByDateToUntil"]);
                            cmp.set('v.wizardData.isEnquiryDateWithinEDDPlusBusinessdays', lArticle["isEnquiryDateWithinEDDPlusBusinessdays"]);
                            cmp.set('v.wizardData.isEnquiryDatePastEDDPlusBusinessdays', lArticle["isEnquiryDatePastEDDPlusBusinessdays"]);
                            cmp.set('v.wizardData.isEnquiryDateWithinEDD', lArticle["isEnquiryDateWithinEDD"]);
                            cmp.set('v.wizardData.deliveredByDatePlusBusinessDays', lArticle["deliveredByDatePlusBusinessDays"]);
                            //cmp.set('v.wizardData.deliveredByDateFormatted', returnObj["deliveredByDateFormatted"]);
                            cmp.set('v.wizardData.isEligibleForMyNetworkAssignment', lArticle["isEligibleForMyNetworkAssignment"]);
                            cmp.set('v.wizardData.latestDeliveredScanWcid', lArticle["latestDeliveredScanWcid"]!= null?lArticle["latestDeliveredScanWcid"]:lArticle["previousDeliveredScanWcid"] );
                            cmp.set('v.wizardData.isNoEddReturned', lArticle["isNoEddReturned"]);
                            cmp.set('v.wizardData.isEDDEstimated', lArticle["isEDDEstimated"]);
                        } else {
                            cmp.set('v.wizardData.trackingNumSerachStatusCode', returnObj["trackingNumSerachStatusCode"]);
                        }

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
                            //Show Invalid Message
                            cmp.set("v.showInvalidMessage", true);
                            //push analytics for invalid tracking number
                            helper.pushAnalytics(cmp, "ITEM_DETAILS_ERROR");
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
                            if(returnObj["isEligibleForMultipleArticleSelection"]) {
                                cmp.set('v.isMultipleArticles', true);
                                cmp.set("v.isLoading", false);
                            } else if(cmp.get("v.wizardData.eddStatus") === 'ON_TIME'){
                                // when the EDD returned is greater than today, we should not allow the user to raise a case in LOMI form
                                cmp.set("v.showInvalidWithinEDDMessage", true);
                                cmp.set("v.isLoading", false);
                                cmp.set('v.eddDisplayDate',helper.getEDDDateString(cmp, event, helper));
                                helper.pushAnalytics(cmp, 'BEFORE_EDD_ERROR');
                                return;
                            } else if(cmp.get("v.wizardData.eddStatus") === 'NO_EDD'){
                                cmp.set("v.wizardData.hasQualifiedForNoEDDFlow",true);
                                helper.gotoNextPage(cmp,'chasMissingItemEDDAddressValidation');
                            } else if(cmp.get("v.wizardData.eddStatus") === 'LATE'){
                                cmp.set("v.wizardData.hasQualifiedForLateFlow",true);
                                cmp.set('v.wizardData.skipDeflectionPage', true);
                                cmp.set("v.showCallerType",true);
                                cmp.set("v.isLoading", false);
                            }
                            //safedrop flow - checks for SAFE_DROP, RTS Scan event, DPid, inflight redirection before presenting address validations screen
                        else if(cmp.get('v.wizardData.eddStatus') == 'SAFE_DROP' && cmp.get('v.wizardData.isReturnToSender') == false && !$A.util.isEmpty(dpidFromOneTrackService) && !isRedirectApplied )
                            {
                                helper.gotoNextPage(cmp,'chasMissingItemAddressValidation');
                                cmp.set("v.wizardData.hasQualifiedForSafeDropFlow","true");
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
            }
              else {
              //-- No change in tracking number
              if (cmp.get("v.wizardData.isEligibleForMultipleArticleSelection")) {
                  cmp.set('v.isMultipleArticles', true);
                  cmp.set("v.isLoading", false);
              } else if (cmp.get("v.wizardData.hasQualifiedForSafeDropFlow")){
                 helper.gotoNextPage(cmp,'chasMissingItemAddressValidation');
              } else if(cmp.get("v.wizardData.hasQualifiedForNoEDDFlow")){
                   helper.gotoNextPage(cmp,'chasMissingItemEDDAddressValidation');
               } else if(cmp.get("v.wizardData.hasQualifiedForLateFlow")){
                  cmp.set("v.showCallerType",true);
                  cmp.set("v.isLoading", false);
                  cmp.set('v.wizardData.skipDeflectionPage', true);
              } else if (cmp.get("v.showInvalidMessage")) {
                let invalidBspCmp = cmp.find("invalidBsp");
                if ($A.util.hasClass(invalidBspCmp, "slds-hide")) {
                    $A.util.removeClass(invalidBspCmp, "slds-hide");
                    $A.util.addClass(invalidBspCmp, "slds-show");
                }
                cmp.set("v.isLoading", false);
              }
              else if(cmp.get("v.showInvalidWithinEDDMessage")){
                  let invalidEddCmp = cmp.find("invalidEdd");
                  if ($A.util.hasClass(invalidEddCmp, "slds-hide")) {
                      $A.util.removeClass(invalidEddCmp, "slds-hide");
                      $A.util.addClass(invalidEddCmp, "slds-show");
                  }
                  cmp.set("v.isLoading", false);
              } else {
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
	},

	handleMultiSelection: function(cmp, event, helper) {
        cmp.set('v.showSelectionError', false);
	    cmp.set("v.isLoading", true);
        let lSelectedArticles = cmp.get('v.wizardData.articles').filter(item => item.isSelected == true);
        //check statuses of selected articles, guide the flow based on that
        let firstSelectedItem = lSelectedArticles[0];
        let lStatuses = new Set(lSelectedArticles.map(item => item.trackStatusValue));
        //if all articles are of the same status, show deflection page
        if (lStatuses.size == 1){
            cmp.set('v.wizardData.skipDeflectionPage', false);
            //if multiple articles are selected, all are delivered, check for safe drops and send user to delivered deflection unless all are safe dropped
            if(lStatuses.values().next().value == 'Delivered' && lSelectedArticles.length > 1) {
                let lFirstFullyDelivered = lSelectedArticles.find(item => item.eddStatus != 'SAFE_DROP');
                //if there is at least 1 not safe dropped article, send the user down delivered journey
                if (lFirstFullyDelivered) {
                    firstSelectedItem = lFirstFullyDelivered;
                }
            }
            }
        //if statuses are different, skip deflection page
        else {
            cmp.set('v.wizardData.skipDeflectionPage', true);
        }
        cmp.set('v.wizardData.senderOrRecipientType', firstSelectedItem["itemType"]);
        cmp.set('v.wizardData.parcelOrLetter', firstSelectedItem["articleType"]);
        cmp.set('v.wizardData.eddStatus', firstSelectedItem["eddStatus"]);
        cmp.set('v.wizardData.dpid', firstSelectedItem["dpid"]);
        cmp.set('v.wizardData.articleId', firstSelectedItem["articleId"]);
        cmp.set('v.wizardData.duplicateCase', firstSelectedItem["duplicateCase"]);
        cmp.set('v.wizardData.isReturnToSender', firstSelectedItem["isReturnToSender"]);
        cmp.set('v.wizardData.isRedirectApplied', firstSelectedItem["isRedirectApplied"]);
        cmp.set('v.wizardData.hasSignature', firstSelectedItem["hasSignature"]);
        cmp.set('v.wizardData.safedropDelivered', firstSelectedItem["safedropDelivered"]);
        cmp.set('v.wizardData.enqSubtype', firstSelectedItem["enqSubtype"]);
        cmp.set('v.wizardData.wcid', firstSelectedItem["wcid"]);
        cmp.set('v.wizardData.latestEventLocation', firstSelectedItem["latestEventLocation"]);
        cmp.set('v.wizardData.latestEventLocationMessage', firstSelectedItem["latestEventLocationMessage"]);
        cmp.set('v.wizardData.trackingNumSerachStatusCode', firstSelectedItem["trackingNumSerachStatusCode"]);
        cmp.set('v.wizardData.trackStatusValue', firstSelectedItem["trackStatusValue"]);
        cmp.set('v.wizardData.deliveredByDateOrEDD', firstSelectedItem["deliveredByDateOrEDD"]);
        cmp.set('v.wizardData.deliveredByDateFrom', firstSelectedItem["deliveredByDateFrom"]);
        cmp.set('v.wizardData.deliveredByDateTo', firstSelectedItem["deliveredByDateTo"]);
        cmp.set('v.wizardData.deliveredByDateToUntil', firstSelectedItem["deliveredByDateToUntil"]);
        cmp.set('v.wizardData.isEnquiryDateWithinEDDPlusBusinessdays', firstSelectedItem["isEnquiryDateWithinEDDPlusBusinessdays"]);
        cmp.set('v.wizardData.isEnquiryDatePastEDDPlusBusinessdays', firstSelectedItem["isEnquiryDatePastEDDPlusBusinessdays"]);
        cmp.set('v.wizardData.isEnquiryDateWithinEDD', firstSelectedItem["isEnquiryDateWithinEDD"]);
        cmp.set('v.wizardData.deliveredByDatePlusBusinessDays', firstSelectedItem["deliveredByDatePlusBusinessDays"]);
        //cmp.set('v.wizardData.deliveredByDateFormatted', returnObj["deliveredByDateFormatted"]);
        cmp.set('v.wizardData.isEligibleForMyNetworkAssignment', firstSelectedItem["isEligibleForMyNetworkAssignment"]);
        cmp.set('v.wizardData.latestDeliveredScanWcid', firstSelectedItem["latestDeliveredScanWcid"]!= null?firstSelectedItem["latestDeliveredScanWcid"]:firstSelectedItem["previousDeliveredScanWcid"] );
        cmp.set('v.wizardData.isNoEddReturned', firstSelectedItem["isNoEddReturned"]);
        cmp.set('v.wizardData.isEDDEstimated', firstSelectedItem["isEDDEstimated"]);
        if (lSelectedArticles.length == 1 && firstSelectedItem["eddStatus"] == 'SAFE_DROP' && firstSelectedItem["isReturnToSender"] == false && !$A.util.isEmpty(firstSelectedItem["dpid"]) && !firstSelectedItem["isRedirectApplied"]){
            helper.gotoNextPage(cmp,'chasMissingItemAddressValidation');
            cmp.set("v.isLoading", false);
            cmp.set("v.wizardData.hasQualifiedForSafeDropFlow","true");
        }
        else {
	        helper.gotoNextPage(cmp);
	        cmp.set("v.isLoading", false);
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
             disDate = ' ' + eddFromDate.toLocaleString("en-US", {weekday: 'short'}) + ' ' + eddFromDate.toLocaleString("en-US", {day: 'numeric'})  + (eddFromDate.getMonth() !== eddToDate.getMonth() ? ' ' +eddFromDate.toLocaleString("en-US", {month:'long'}) : '')
                 + ' - ' + eddToDate.toLocaleString("en-US", {weekday: 'short'}) + ' ' + eddToDate.toLocaleString("en-US", {day: 'numeric'}) + ' ' +eddToDate.toLocaleString("en-US", {month:'long'});
         } else {
             // format for weekday day month eg:Tue 16 August
             const eddDeliveredByDate = new Date(cmp.get('v.wizardData.deliveredByDateOrEDD'));
             disDate = ' ' + eddDeliveredByDate.toLocaleString("en-US", {weekday: 'short'}) + ' ' + eddDeliveredByDate.toLocaleString("en-US", {day: 'numeric'}) + ' ' +eddDeliveredByDate.toLocaleString("en-US", {month:'long'});
         };
         return disDate;
     },

     /**
      * push analytics
      */
     pushAnalytics : function(cmp, stepKey) {
         let analyticsObject = {};
        // building the analytics params object
         // setting the common attributes
         analyticsObject.form = {};
         analyticsObject.form.name = 'form:' + cmp.get('v.pageTitle');
         analyticsObject.form.product = cmp.get('v.wizardData.trackingId');
         analyticsObject.form.step = "item details";
         analyticsObject.form.stage = 'start';
         let trackingType = 'helpsupport-form-navigate';

         if(stepKey === "BEFORE_EDD_ERROR" && cmp.get('v.wizardData.eddStatus') != '') {
             // setting before edd specific attributes
             analyticsObject.form.error = 'before EDD -parcel is on track to be delivered';
         } else  if(stepKey === "ITEM_DETAILS_ERROR" && cmp.get('v.wizardData.eddStatus') != '') {
             // setting item details error specific attributes
             analyticsObject.form.error = 'invalid tracking number';
         }

         console.log('ANALYTICS sending .. '+analyticsObject);

         // calling the analytics API methods
         window.AP_ANALYTICS_HELPER.trackByObject({
             trackingType: trackingType,
             componentAttributes: analyticsObject
         });
     },

     validateRadioButtons: function(cmp, showError) {
         return this.validateNotNull(cmp, showError, "Choose an option");
     },
     validationMap: function() {
         return {
             'recipientOrSenderRadioButtons': this.validateRadioButtons,
         };
     },
     checkAllInputs: function(cmp, showError) {
         var allInputs = this.asArray(cmp.find('chasInput'));
         var isValid = this.checkEachInput(cmp, allInputs, showError);
         this.updateErrorSummary(cmp, allInputs);
         /* Commented below code on 4/10/2018 for International Missing Item Changes.
            When user enters International tracking number and selects Recipient, next button is enabled to proceed further. */
         /*if(cmp.get('v.wizardData.senderOrRecipientType') === 'International' && cmp.get('v.wizardData.selectedRadio1Name') === 'Recipient'){
             isValid = false;
         }*/

         if(isValid){
             cmp.set('v.formValid', true);
         }else{
             cmp.set('v.formValid', false);
         }
         return isValid;
     },
     checkEachInput: function(cmp, inputs, showError) {
         var validationMap = this.validationMap();
         var isValid = true;
         for (var i=0; i<inputs.length; i++) {
             var inputCmp = inputs[i];
             var inputName = inputCmp.get('v.name');
             var inputRequired = inputCmp.get('v.required');
             var validationFunction = validationMap[inputName];
             if (validationFunction) validationFunction.bind(this)(inputCmp, showError);
             var inputError = inputCmp.get('v.error');
             isValid = isValid && !inputError && (!inputRequired || (inputError === null && inputRequired));
         }

         return isValid;
     },

     updateErrorSummary: function(cmp, allInputs) {
         var errors = [];
         for (var i=0; i<allInputs.length; i++) {
             var inputCmp = allInputs[i];
             var inputName = inputCmp.get('v.name');
             var inputLabel = inputCmp.get('v.label');
             var inputError = inputCmp.get('v.error');

             for (var j=0; j<errors; j++) {
                 if (errors[j].name === inputName) {
                     errors.splice(j, 1);
                     break;
                 }
             }
             if (inputError) {
                 errors.push({name: inputName, label: inputLabel, error: inputError});
             }
         }

         cmp.set('v.errors', errors);
     },
})