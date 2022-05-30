/*
* * 2022-04-12 thang.nguyen231@auspost.com.au DDS-10262: add Delete account enquiry type for Id, documents and accounts section
* * Modified by Hasantha Liyanage - 30/05/2022 DDS-10809: - Accessibility categories - Preselect functionality on product & services
*/
({
    afterRender: function (cmp, helper) {
        this.superAfterRender();
        var BASE_URL = window.location.href;
        //DDS-10262: add Delete account enquiry type for Id, documents and accounts section
        if(cmp.get('v.authUserData.isUserAuthenticated')) {
            var idDocumentsAccountsEnquiryTypeList = cmp.get("v.idDocumentsAccountsEnquiryTypes");
            idDocumentsAccountsEnquiryTypeList.unshift({'label':'Delete MyPost account', value:'Delete MyPost account'});
            cmp.set("v.idDocumentsAccountsEnquiryTypes",idDocumentsAccountsEnquiryTypeList);

            // if the url is directing to account deletion page with a parameter, let's auto select the ID, documents & accounts
            // auto select only for the first redirect, once if user select something else and proceed need to reflect the same when click on 'Go Back'
            if(BASE_URL.includes("accountdeletion") && $A.util.isEmpty(cmp.get("v.wizardData.selectedRadio1"))) {
                cmp.set("v.wizardData.selectedRadio1", "thirdRadio");
                cmp.set("v.wizardData.selectedRadio1Name", 'ID, documents & accounts');
                cmp.set("v.wizardData.idDocumentsAccountsEnquiryType",'Delete MyPost account');

            }
        }

        if(BASE_URL.includes("accessibilitydelivery") && $A.util.isEmpty(cmp.get("v.wizardData.selectedRadio1"))) {
            cmp.set("v.wizardData.selectedRadio1", "tenthRadio");
            cmp.set("v.wizardData.selectedRadio1Name", 'Accessibility or disability');
            cmp.set("v.wizardData.accessibilityIssueType",'deliveryRadio');
        }
    }
})