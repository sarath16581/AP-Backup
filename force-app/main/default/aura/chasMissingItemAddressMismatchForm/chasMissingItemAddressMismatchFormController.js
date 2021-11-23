({
    goForward: function (cmp, event, helper) {
        var isSenderOrReceiver = cmp.get("v.wizardData.selectedRadio1Name");
        if(isSenderOrReceiver == 'Sender')
        {
            //Click tracking - push analytics for site-interact
            window.AP_ANALYTICS_HELPER.analyticsTrackInteraction(
                'site-interact',
                'form:' + cmp.get('v.pageTitle'),
                'item details: ' + 'address not match:sender:continue'
            ); 
        }
        if(isSenderOrReceiver == 'Recipient')
        {
            //Click tracking - push analytics for site-interact
            window.AP_ANALYTICS_HELPER.analyticsTrackInteraction(
                'site-interact',
                'form:' + cmp.get('v.pageTitle'),
                'item details: ' + 'address not match:recipient:continue'
            ); 
        }
        helper.gotoNextPage(cmp);
    },
    goBackHandler: function (cmp, event, helper) {
        var isSenderOrReceiver = cmp.get("v.wizardData.selectedRadio1Name");
        if(isSenderOrReceiver == 'Sender')
        {
            //Click tracking - push analytics for site-interact
            window.AP_ANALYTICS_HELPER.analyticsTrackInteraction(
                'site-interact',
                'form:' + cmp.get('v.pageTitle'),
                'item details: ' + 'address not match:sender:back'
            ); 
        }
        if(isSenderOrReceiver == 'Recipient')
        {
            //Click tracking - push analytics for site-interact
            window.AP_ANALYTICS_HELPER.analyticsTrackInteraction(
                'site-interact',
                'form:' + cmp.get('v.pageTitle'),
                'item details: ' + 'address not match:recipient:back'
            ); 
        }
        helper.gotoPrevPage(cmp);
    },
    init: function(cmp, event, helper) {
        var isSenderOrReceiver = cmp.get("v.wizardData.selectedRadio1Name");
        if(isSenderOrReceiver == 'Sender')
        {
            helper.pushAnalytics(cmp,'address:not match:sender');
        }
        if(isSenderOrReceiver == 'Recipient')
        {
            helper.pushAnalytics(cmp,'item details:address:not match:recipient');
        }
    }
})