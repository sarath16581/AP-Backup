/**************************************************
 Description:  Parcel Send Onboarding Helper

 History:
 --------------------------------------------------
 2019-03-19  hasantha.liyanage@auspost.com.au Created

 **************************************************/
({
    doInit : function(component, event, helper) {
        helper.getStatusAndShowResult(component, helper);
    },
    onboard : function(component, event, helper) {
        helper.doOnboard(component, helper);
    },

})