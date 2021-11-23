/**
* @description Webservice to provision the BSP community user for the requested contact
* Called by Camunda, to activate the BSP community user for the requested contact.
* Need to validate the Contact and User first
* Custom Metadatatype :   ResourceAPI__mdt
* /api/1.0/bam/bsp/provision (contact id in Request Body)
* @author Lija Jawahar
* @date 2019-05-13
* @group Merchant Portal
* @tags BAM, Merchant Portal, BSP, Self service
* @domain Merchant Portal
* @changelog
* 2019-06-02 - nathan franklin - Added a more robust return response capability.
* 2019-06-04 - lija jawahar - Added Async response to Camunda.
* 2019-07-18 - nathan franklin - Added signup source for custom welcome email template for BSP
* 2020-04-22 - nathan franklin - Added the ability to onboard a MPB user to BSP and removed the need for BSP Community User profile to be applied
*/
public with sharing class ResourceBamBspProvisionV1 extends ResourceAPIService.IApi {

    // Salesforce ID from request.Body
    public static String requestContactId;

    // request ID from request.Body
    public static String requestId;

    // Salesforce EOR request ID
    public static String eorRequestId;


    /**
     * Handle the provisioning request for BSP
     * Camunda is expecting a 204 response here which equates to an acknowledgement that the request has been received
     * After that Camunda will then expect an asynchronous response to notify that the provisioning process has been completed successfully.
     *
     * There is 1 exception to this scenario, and that is if we can't extract the Camunda requestId from the payload received, then we return a 500 response with the message Malformed Request
     */
    public override ResourceAPIService.IResourceResponse post() {

        BspProvisioningApiAsyncResourceResponse response;

        try {
            // check to make sure the logged in user has access to be able to make these calls
            if(!BAMUserUtility.currentUserHasBAMApiAccess()){
                return new BspProvisioningApiAcknowledgementResponse(true);
            } else {

                // In case on multiple validation error , need to pass all errors.
                List<String> errors = new List<String>();

                //Contact ID and primaryBilling account sourced from the JSON body
                Map<String, Object> results = null;
                Map<String, Object> contactAttributes = null;
                Map<String, Object> requestAttributes = null;
                Map<String, Object> applicationAttributes = null;
                String primaryBillingAccount = '';
                User requestedUser = null;

                // catch an errors with parsing the body
                try {
                    system.debug(RestContext.request.requestBody.toString());
                    results = (Map<String, Object>) JSON.deserializeUntyped(RestContext.request.requestBody.toString());
                    contactAttributes = (Map<String, Object>)results.get('contact');
                    requestAttributes = (Map<String, Object>)results.get('request');
                    applicationAttributes = (Map<String, Object>)requestAttributes.get('application');

                    if(contactAttributes == null) contactAttributes = new Map<String, Object>();
                    if(requestAttributes == null) requestAttributes = new Map<String, Object>();
                    if(applicationAttributes == null) applicationAttributes = new Map<String, Object>();

                    eorRequestId = String.valueOf(requestAttributes.get('id'));
                    requestContactId  = String.valueOf(contactAttributes.get('id'));
                    requestId = String.valueOf(results.get('id'));
                    primaryBillingAccount = String.valueOf(applicationAttributes.get('primaryBillingAccount'));
                    system.debug(primaryBillingAccount +':: '+requestId);
                } catch(Exception ex) {} // do nothing

                if (String.isEmpty(requestId)) {
                    // since we can't reconcile this request back to an originating requestId, we end the flow now with a synchronous feedback
                    return new BspProvisioningApiAcknowledgementResponse(true);
                }

                // catch any 'provisioning' system errors.
                // these will be fed back via the asycnhronous feedback loop
                try {
                    if (!String.isEmpty(requestContactId)) {
                        // retrieve the user details
                        requestedUser = BAMUserUtility.retrieveContactUserDetail(requestContactId);
                        System.debug('RequestedUser ::' + requestedUser);

                        //validate the contact that was passed in to ensure a BSP account can be provisioned against it.
                        errors.addAll(ResourceBamBspValidationV1.validateUser(requestedUser, primaryBillingAccount));
                    } else {
                        errors.add(Label.BAMBSP_User_Record_Not_Found); //
                    }

                    // if there are errors then we need to feed these back via an asynchronous response (the synchronous response will still return a 204 acknowledgement)
                    if (errors.isEmpty()) {
                        // update the existing user details
                        provisionBspUser(requestedUser);

                        response = new BspProvisioningApiAsyncResourceResponse(200, 'Fulfilled', requestId);
                    } else {
                        response = new BspProvisioningApiAsyncResourceResponse(500, 'Error', requestId, '500', String.join(errors, '\n'));
                    }
                } catch(Exception ex) {
                    response = new BspProvisioningApiAsyncResourceResponse(500, 'Error', requestId, '500', ex.getMessage());
                }
            }

        } catch(Exception e) {
            return new BspProvisioningApiAcknowledgementResponse(true);
        }

        // based on the Asynchronous response we have built above (BspProvisioningApiAsyncResourceResponse),
        // we queue the actual callout to be completed in a future to allow this acknowledgement to complete first
        sendProvisioningResponseToCamunda(eorRequestId, response.serialize());

        // if we got to this point then we need to send a 204 acknowledgement back to camunda to acknowledge that the request has been received
        return new BspProvisioningApiAcknowledgementResponse();
    }

    /**
     * Provision a user so they can access BSP
     * BSP Users can either have a profile of BSP Community User or the special bsp access permission set
     */
    public static void provisionBspUser(User customer){

        //        // Query BSP community profile
        //        Profile bspProfile = [
        //                SELECT Id, Name
        //                FROM Profile
        //                WHERE Name= :BspConstants.BSP_COMMUNITY_PROFILE_NAME
        //                LIMIT 1
        //        ];

        Boolean canUpdateUser = false;

        if(!customer.BSPSignupMerchantPortal__c) {
            // This is used in the BSP welcome email to redirect the user to Merchant Portal login rather than the BSP login page.
            customer.BSPSignupMerchantPortal__c = true;
            canUpdateUser = true;
        }

        // Update 2020-05-03, rather than applying the BSP Community User profile, the existing profile can remain and the BSP Community Access permission set will be applied
        //        if(BAMUserUtility.MERCHANT_PORTAL_PROFILE_NAME.equalsIgnoreCase(customer.Profile.Name)) {
        //            customer.ProfileId = bspProfile.Id;
        //            canUpdateUser = true;
        //        }

        // Note, this may need to be reviewed in the scenario where the user has an inactive MPB account
        // Since we are not changing the users profile and only applying the BSP permission set, this would mean that they would also get access to MPB community too
        // Given the off-boarding process of MPB, there shouldn't be any issues with this though
        if(!customer.IsActive){
            customer.IsActive = true;
            canUpdateUser = true;
        }

        if(canUpdateUser) {
            update customer;
        }

        // add the special bsp permission set access to them if it doesn't already exist
        List<PermissionSetAssignment> assignments = [Select Id From PermissionSetAssignment
                                                        Where PermissionSet.Name = :BspConstants.BSP_COMMUNITY_PERMISSIONSET_NAME
                                                        And AssigneeId = :customer.Id];
        if(assignments.isEmpty()) {
            Id permissionSetId = [Select Id From PermissionSet Where Name = :BspConstants.BSP_COMMUNITY_PERMISSIONSET_NAME].Id;

            PermissionSetAssignment assignment = new PermissionSetAssignment(AssigneeId = customer.Id, PermissionSetId = permissionSetId);
            insert assignment;
        }
    }

    @future(callout=true)
    public static void sendProvisioningResponseToCamunda(String requestId, String request) {
        try {

            //System.debug('Sending Provisioning Response - Request:: ' + request);

            // Send Asynchronous response to Camunda after provisioning
            HttpResponse response = BAMIntegrationUtility.postRequest('BAM_PROVISION_RESPONSE', request);

            if(response.getStatusCode() != 204) {
                System.debug(response.getBody());

                String body = response.getBody();
                if(String.isEmpty(body)) body = 'no body';

                // Capture the errors and attach it to the External Onboarding request
                Attachment attach=new Attachment();
                attach.name = 'provision response error';
                attach.body = Blob.valueOf(body);
                attach.parentId = requestId;
                insert attach;
            }

        } catch (exception exp){
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), 'BAM BSP Provisioning API',
                    ResourceBamBspProvisionV1.class.getName(), 'send Async Response To Camunda',
                    null, LoggingLevel.ERROR);
        }
    }

    public class BspProvisioningApiAsyncResourceResponse extends ResourceAPIService.IResourceResponse {

        public BspProvisioningApiAsyncResourceResponse(Integer responseCode, String status, String id) {
            this(responseCode, status, id, '', '');
        }

        public BspProvisioningApiAsyncResourceResponse(Integer responseCode, String status, String id, String errorCode, String errorMessage) {
            output.put('status', status);

            if(!String.isEmpty(id)) {
                output.put('id', id);
            }

            if(!String.isEmpty(errorCode)) {
                output.put('errorCode', errorCode);
            }

            if(!String.isEmpty(errorMessage)) {
                output.put('errorMessage', errorMessage);
            }

            this.responseCode = responseCode;
        }
    }

    public class BspProvisioningApiAcknowledgementResponse extends ResourceAPIService.IResourceResponse {

        public BspProvisioningApiAcknowledgementResponse() {
            this(false);
        }

        public BspProvisioningApiAcknowledgementResponse(Boolean isMalformed) {
            if(isMalformed) {
                this.responseCode = 500;
                output.put('message', Label.BAMBSP_Malformed_Request);
            } else {
                this.responseCode = 204;
            }
        }

        //Returns serialize result in JSON format
        public override String serialize() {
            if(output.keySet().isEmpty()) {
                return '';
            } else {
                return JSON.serializePretty(output);
            }
        }
    }


}