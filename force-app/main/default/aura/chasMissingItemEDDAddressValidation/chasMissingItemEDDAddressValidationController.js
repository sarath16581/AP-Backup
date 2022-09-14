/**
 * @author Hasantha Liyanage
 * @date 2022-08-10
 * @group Chas
 * @tag EDD service
 * @tag DDS-11627
 * @domain Help & Support
 * @description calculated EDD service estimate tests
 * @changelog
 * 2022-08-10 - Hasantha Liyanage - Created
 */

({
    init: function (cmp, event, helper) {
        var baseUrl = window.location.href;
        if(baseUrl.includes("#"))
        {
            cmp.set("v.isFromBackButton", true);
        }
    },
    checkOverride : function(cmp, event, helper) {
        var overriden = event.getParam('selected');
        cmp.set("v.isOverriden",overriden);
        //push analytics for 'helpsupport-form-navigate'
        helper.pushAnalytics(cmp, "MANUAL_ADDRESS_ENTRY");
        //Click tracking - push analytics for site-interact
        window.AP_ANALYTICS_HELPER.analyticsTrackInteraction(
            'site-interact',
            'form:' + cmp.get('v.pageTitle'),
            'item details: ' + 'item details:address:enter address manually'
        );
    },
    getSelectedAddress : function(cmp, event, helper) {
        var streetAddress = event.getParam('address');
        cmp.set("v.selectedAddress",streetAddress.address);
        cmp.set("v.dpid",streetAddress.delpointId);
        //set the address strings into indiviual line items
        cmp.set("v.wizardData.recipientAddressLine1",streetAddress.addressLine);
        cmp.set("v.wizardData.recipientAddressLine2",streetAddress.addressLine3);
        cmp.set("v.wizardData.recipientCity",streetAddress.city);
        cmp.set("v.wizardData.recipientState",streetAddress.state);
        cmp.set("v.wizardData.recipientPostcode",streetAddress.postcode);

        if(streetAddress)
        {
            //set the wizard data with the selected address
            cmp.set('v.wizardData.correctDeliveryAddress', cmp.get('v.selectedAddress'));
            cmp.set('v.wizardData.recipientDeliveryAddress', cmp.get('v.selectedAddress'));
            //push analytics for site-interact
            window.AP_ANALYTICS_HELPER.analyticsTrackInteraction(
                'site-interact',
                'form:' + cmp.get('v.pageTitle'),
                'item details: ' + 'address:selected'
            );
        }
    },

    getShowError:function(cmp, event, helper) {
        helper.getShowError(cmp, event, helper);
    },

    getOverrideAddress : function(cmp, event, helper) {
        helper.getOverrideAddress(cmp, event, helper);
    },

    getAddressTyped:function(cmp, event, helper) {
        helper.getAddressTyped(cmp, event, helper);
    },

    callRedirectService: function (cmp, event, helper) {
        helper.redirectService(cmp, event, helper);
    },

    manualEntryFlow: function (cmp, event, helper) {
        //Click tracking - push analytics for site-interact
        window.AP_ANALYTICS_HELPER.analyticsTrackInteraction(
            "site-interact",
            "form:" + cmp.get("v.pageTitle"),
            "item details: " + "address manual:continue"
        );
        /*Manual address entry flow:
            1.Check if address is manually entered
            2.If address format is valid, navigate to the chasMissingItemWPage02 screen (non-safedrop flow)
            */
        var overriden = cmp.get("v.isOverriden");
        if (overriden) {
            var formValid = helper.checkManualAddressisValid(cmp, event, helper);
            if (formValid) {
                helper.gotoNextPage(cmp, "chasMissingItemWPage02");
            }
        }
    },
    goBackHandler: function (cmp, event, helper) {
        //Check the base url of the page, this is to ascertain users getting directed from a direct link
        var baseUrl = window.location.href;
        if (baseUrl.includes("trackingId")) {
            window.location.href = window.location.href + "#";
        }
        //cmp.set("v.wizardData.correctDeliveryAddress",null);
        helper.gotoPrevPage(cmp);
        //push analytics for site-interact
        window.AP_ANALYTICS_HELPER.analyticsTrackInteraction(
            "site-interact",
            "form:" + cmp.get("v.pageTitle"),
            "item details: " + "address:back"
        );
        if (cmp.get("v.isOverriden")) {
            //push analytics for site-interact
            window.AP_ANALYTICS_HELPER.analyticsTrackInteraction(
                "site-interact",
                "form:" + cmp.get("v.pageTitle"),
                "item details: " + "address manual:back"
            );
        }
    },
});
