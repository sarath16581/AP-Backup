/**
 *
 * History :
 * --------------------------------------------------
 * 2019-08-30 hasantha.liyanage@auspost.com.au Modified : searchTrackingNumberService function to accept few params and cleanup commented lines
 * 2020-02-12 gunith.devasurendra@auspost.com.au Added support for 
 * 2020-07-06 : Hara Sahoo : Change made for roll out of Safe Drop feature on Missing Items form
 *                           Modified the searchTrackingNumberService() for safedrop and non safedrop flows.
 * 2020-10-09 : Hara Sahoo : Removed code to allow the safedrop flow to be unrestrictive of any states.
 * 2023-11-20 - Nathan Franklin - Adding a tactical reCAPTCHA implementation to assist with reducing botnet attack vectors (INC2251557)
 */

({
	onRender: function (component, event, helper){ 
        document.dispatchEvent(new CustomEvent("grecaptchaRender", { "detail" : { element: 'recaptchaCheckbox'} }));
    },

    /* Added Init function on 29/10/2018 for parsing and setting 
    the Tracking Id passed from App view to the Missing Items form. */
    doInit: function(cmp, event, helper) {

		document.addEventListener("grecaptchaVerified", $A.getCallback(function(e) {
			cmp.set('v.articleTrackingCaptchaEmptyError', false);
            cmp.set('v.articleTrackingCaptchaToken', e.detail.response);
        }));
        
        document.addEventListener("grecaptchaExpired", $A.getCallback(function() {
            cmp.set('v.articleTrackingCaptchaToken', '');
        })); 


        var agentString = "";
        //Get the user agent string.
        agentString = navigator.userAgent;
        //Checking the user agent string for iOS or Android.
        // Commenting the below User Agent check so Tracking ID can be parsed as and when sent through
        /* if(agentString == 'com.auspost.mobile.ios' || agentString == 'com.auspost.mobile.android'){ */
        //Call the helper method to parse the url.
        var urlVars = helper.parseUrlParam();
        //Get the Tracking Id parameter.
        var trackingId = urlVars.trackingId;
        //Get the DPID
        var dpID = urlVars.dpId;
        if(!$A.util.isEmpty(dpID) || !$A.util.isUndefined(dpID))
        {
            cmp.set('v.dpidFromUrl',dpID);
        }
        if(!$A.util.isEmpty(trackingId) || !$A.util.isUndefined(trackingId))
        {
            //Emptying all the wizard Data
            cmp.set('v.wizardData', {});
            //Prepopulate the tracking Id, derived from the query parms in the url
            cmp.set('v.wizardData.trackingId',trackingId);
            cmp.set('v.trackingIdFromUrl',trackingId);
        }
        //Check if the back button is pressed
        var baseUrl = window.location.href;
        if(baseUrl.includes("#"))
        {
            cmp.set("v.isFromBackButton", true);
        }
        //Auto progress the consignment search if it is from a direct link and not from the back button
        if(! cmp.get("v.isFromBackButton") && (!$A.util.isEmpty(trackingId) || !$A.util.isUndefined(trackingId)))
        {
            cmp.set('v.displaySpinner', true);
            helper.callTrackingNumberService(cmp, event, helper);
        }
    },
    navNextPage : function(cmp, event, helper) {
        if(cmp.get("v.showCallerType")) {
            var isValid = helper.checkAllInputs(cmp, true);
            if (isValid) {
                var recipientOrSender = cmp.get("v.wizardData.selectedRadio1");
                if(recipientOrSender) {
                    cmp.set('v.wizardData.recipientOrSenderCallerType', recipientOrSender);
                }
                helper.gotoNextPage(cmp);
            } else {
                helper.showErrorSummary(cmp)
            }
        }
    },
    searchTrackingNumberService : function(cmp, event, helper) {
        helper.callTrackingNumberService(cmp, event, helper);
    },
    onchange: function(cmp, event, helper) {
        cmp.set('v.error500', false);
        helper.validateTrackingNumber(cmp.find("ChasTrackingId"), true);
        // setting the values on change event for the fields
        var fieldName = event.getParam("name");
        if (fieldName === 'recipientOrSenderRadioButtons') {
            helper.setRadioName(cmp, 'v.recipientOrSenderRadioGroup', 'v.wizardData.selectedRadio1', 'v.wizardData.selectedRadio1Name');
        }
    },
    navToLearnMore:function(cmp,event,helper){
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "https://auspost.com.au/help-and-support/answers?s=000003988"
        });
        urlEvent.fire();
    },
    displaymyPostLoginForm : function (cmp, event, helper) {
        helper.storeEncryPtWizardDataAndNavigateToMyPost(cmp);
    },
    isSelected: function(cmp, event, helper) {
      var isSelected = event.getParam('articleSelected');
      var articleId = event.getParam('articleId');

      var articles = cmp.get('v.wizardData.articles');
      articles.find(item => item.articleId == articleId).isSelected = isSelected;

      cmp.set('v.wizardData.articles', articles);
    },
    selectionMade : function (cmp, event, helper) {
      var articles = cmp.get('v.wizardData.articles');
      //console.log(JSON.stringify(articles));
      var isItemSelected = articles.find(item => item.isSelected == true);
        if (!($A.util.isUndefined(isItemSelected))) {
         // console.log(selectedItem);
          helper.handleMultiSelection(cmp, event, helper);
        } else {
          cmp.set('v.showSelectionError', true);
        }
      },
      goBack: function (cmp, event, helper) {
        //Check the base url of the page, this is to ascertain users getting directed from a direct link
        var baseUrl = window.location.href;
        if(baseUrl.includes("trackingId"))
        {
            baseUrl = baseUrl + '#';
            window.location.href = window.location.href + '#';
        }
        cmp.set('v.isMultipleArticles', false);
        cmp.set('v.showSelectionError', false);
        helper.gotoPrevPage(cmp);
    },

    pushInteractionAnalytics: function (cmp, helper) {
        // calling the analytics API methods for trackingtype = "site-interact"
        window.AP_ANALYTICS_HELPER.analyticsTrackInteraction(
            "site-interact",
            "form:" + cmp.get("v.pageTitle"),
            "item details:missing item:before edd alert:contact us by phone"
        );
    }
})