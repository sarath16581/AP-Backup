/**
* @description Webservice to validate the requested contact has a BAM/BSP active user
* Called by Camunda, to validate the requested contact is active and has active user with the correct profile.
* Custom Metadatatype :       ResourceAPI__mdt
* /api/1.0/bam/bsp/validate (contact id in Request Body)
* @author Lija Jawahar
* @date 2019-05-13
* @group Merchant Portal
* @tags BAM, Merchant Portal, BSP, Self service
* @domain Merchant Portal
* @changelog
* 2019-06-02 - nathan franklin - Added a more robust return response capability
* 2019-06-03 - lija jawahar - Added new format for error responses
* 2019-06-14 - nathan franklin - hardening responses
*/
public with sharing class ResourceBamBspValidationV1 extends ResourceAPIService.IApi{

    /**
     * Handle the provisioning validation request for BSP
     * Camunda is expecting either a 204 response if the validation was successful or a 500 with an error response if the validation failed.
     */
    public override ResourceAPIService.IResourceResponse post() {

        try {
            // check to make sure the logged in user has access to be able to make these calls
            if(!BAMUserUtility.currentUserHasBAMApiAccess()){
                return new BspValidationApiSynchronousResourceResponse(500, 'Error', '500', Label.BAMBSP_No_Access);
            } else {

                // In case on multiple validation error , need to pass all errors.
                List<String> errors = new List<String>();

                String requestContactId;

                //Contact ID and primaryBilling account sourced from the JSON body
                Map<String, Object> results = null;
                Map<String, Object> contactAttributes = null;
                Map<String, Object> requestAttributes = null;
                Map<String, Object> applicationAttributes = null;
                String primaryBillingAccount = '';
                User requestedUser = null;

                // catch an errors with parsing the body
                try {
                    results = (Map<String, Object>) JSON.deserializeUntyped(RestContext.request.requestBody.toString());
                    contactAttributes = (Map<String, Object>)results.get('contact');
                    requestAttributes = (Map<String, Object>)results.get('request');
                    applicationAttributes = (Map<String, Object>)requestAttributes.get('application');

                    if(contactAttributes == null) contactAttributes = new Map<String, Object>();
                    if(requestAttributes == null) requestAttributes = new Map<String, Object>();
                    if(applicationAttributes == null) applicationAttributes = new Map<String, Object>();

                    requestContactId  = String.valueOf(contactAttributes.get('id'));
                    primaryBillingAccount = String.valueOf(applicationAttributes.get('primaryBillingAccount'));
                } catch(Exception ex) {} // do nothing

                // catch any 'validation' system errors.
                try {
                    if (!String.isEmpty(requestContactId)) {

	                    // retrieve the user details
	                    requestedUser = BAMUserUtility.retrieveContactUserDetail(requestContactId);

                        //validate the contact that was passed in to ensure a BSP account can be provisioned against it.
                        errors.addAll(validateUser(requestedUser, primaryBillingAccount));

                    } else {
                        errors.add(Label.BAMBSP_User_Record_Not_Found);
                    }

                    // if there are errors then we need to feed these back via an asynchronous response (the synchronous response will still return a 204 acknowledgement)
                    if (errors.isEmpty()) {
                        return new BspValidationApiSynchronousResourceResponse(204, 'Fulfilled');
                    } else {
                        system.debug(errors);
                        return new BspValidationApiSynchronousResourceResponse(500, 'Error', '500', String.join(errors, '\n'));
                    }
                } catch(Exception ex) {
                    return new BspValidationApiSynchronousResourceResponse(500, 'Error', '500', ex.getMessage());
                }
            }
        } catch(Exception e) {
            return new BspValidationApiSynchronousResourceResponse(500, 'Error', '500', e.getMessage());
        }
    }

    /**
     * validate the User whether contact is active , User type is CSPLitePortal
     *  and belongs either to BSP community user, Merchant Portal User or MPB community
     *  passed in primary billing account not null and it belongs to Contact's account
     */
    public static List<String> validateUser(User matchedUser, String primaryBillingAccount) {
        List<String> errors = new List<String>();

        if(matchedUser == null || matchedUser.ContactId == null) {
            errors.add(Label.BAMBSP_User_Record_Not_Found);
        } else {

            // check whether contact's org has application asset
            if (!bspAssetExists(matchedUser.Contact.AccountId)) {
                errors.add(Label.BAMBSP_Organisation_does_not_have_BSP_Asset);
            }

            // Check no billing account error
            if (primaryBillingAccount == null || Id.valueOf(primaryBillingAccount) != matchedUser.Contact.BillingAccount__c) {
                errors.add(Label.BAMBSP_Primary_Billing_account_validation_Error);
            }

            // Check contact is active and not a person account
            if ('Active'.equalsIgnoreCase(matchedUser.Contact.Status__c) == false || matchedUser.Contact.IsPersonAccount == true) {
                errors.add(Label.BAMBSP_Contact_Not_Active);
            }

            //to provision user must be on  Merchant Portal profile or BSP community profile or MPB community profile
            if (!matchedUser.Profile.Name.equalsIgnoreCase(BspConstants.BSP_COMMUNITY_PROFILE_NAME) &&
                    !matchedUser.Profile.Name.equalsIgnoreCase(BAMUserUtility.MERCHANT_PORTAL_PROFILE_NAME) &&
                    !matchedUser.Profile.Name.equalsIgnoreCase(BspConstants.MPB_COMMUNITY_PROFILE_NAME)) {
                errors.add(Label.BAMBSP_Non_BSP_Profile);
            }

            if (!'CspLitePortal'.equalsIgnoreCase(matchedUser.UserType)) {
                errors.add(Label.BAMBSP_Non_cspLitePortal_User);
            }
        }

        return errors;
    }

    /**
     *  Validate whether the requested contact's Organisation has BSP App Asset
     */
    public static Boolean bspAssetExists(Id accountId){
        return ([Select Count() FROM BAMApplication__c
                    WHERE Status__c = 'Active'
                    AND AppKey__c = 'BSP'
                    AND Product__c IN (Select Product2Id From Asset Where Status = 'Active' And AccountId = :accountId)] > 0);
    }

    public class BspValidationApiSynchronousResourceResponse extends ResourceAPIService.IResourceResponse {

        public BspValidationApiSynchronousResourceResponse(Integer responseCode, String status) {
            this(responseCode, status, '', '');
        }

        public BspValidationApiSynchronousResourceResponse(Integer responseCode, String status, String errorCode, String errorMessage) {
            output.put('status', status);

            if(!String.isEmpty(errorCode)) {
                output.put('code', errorCode);
            }

            if(!String.isEmpty(errorMessage)) {
                output.put('message', errorMessage);
            }

            this.responseCode = responseCode;
        }
    }


}