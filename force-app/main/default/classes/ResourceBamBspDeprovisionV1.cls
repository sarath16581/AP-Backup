/**
* @description Webservice to De-provision the BSP community user for the requested contact
* Called by Camunda, to de-activate the BSP community user for the requested contact.
* Need to validate the whether the User is in BSP community before removing access
* Custom Metadatatype :   ResourceAPI__mdt
* /api/1.0/bam/bsp/deprovision (contact id in Request Body)
* @author Lija Jawahar
* @date 2019-05-13
* @group Merchant Portal
* @tags BAM, Merchant Portal, BSP, Self service
* @domain Merchant Portal
* @changelog
* 2019-06-02  	nathan.franklin@auspost.com.au  Added a more robust return response capability
* 2019-06-14  	nathan.franklin@auspost.com.au  Added callouts for asynchronous response to Camunda
* 2020-04-22 - nathan franklin - Added the ability to offboard an MPB user from BSP
*/
public with sharing class ResourceBamBspDeprovisionV1 extends ResourceAPIService.IApi{

    // Salesforce ID from request.Body
    public static String requestContactId;

    // request ID from request.Body
    public static String requestId;

    // Salesforce EOR request ID
    public static String eorRequestId;

    /**
     * Handle the deprovisioning request for BSP
     * Camunda is expecting a 204 response here which equates to an acknowledgement that the request has been received
     * After that Camunda will then expect an asynchronous response to notify that the deprovisioning process has been completed successfully.
     *
     * There is 1 exception to this scenario, and that is if we can't extract the Camunda requestId from the payload received, then we return a 500 response with the message Malformed Request
     */
    public override ResourceAPIService.IResourceResponse post() {

        BspDeprovisioningApiAsyncResourceResponse response;

        try {
            // check to make sure the logged in user has access to be able to make these calls
            if(!BAMUserUtility.currentUserHasBAMApiAccess()){
                return new BspDeprovisioningApiAcknowledgementResponse(true);
            } else {

                // In case on multiple validation error , need to pass all errors.
                List<String> errors = new List<String>();

                //Contact ID and primaryBilling account sourced from the JSON body
                Map<String, Object> results = null;
                Map<String, Object> contactAttributes = null;
                Map<String, Object> requestAttributes = null;
                User requestedUser = null;

                // catch an errors with parsing the body
                try {
                    results = (Map<String, Object>) JSON.deserializeUntyped(RestContext.request.requestBody.toString());
                    contactAttributes = (Map<String, Object>)results.get('contact');
                    requestAttributes = (Map<String, Object>)results.get('request');

                    if(contactAttributes == null) contactAttributes = new Map<String, Object>();
                    if(requestAttributes == null) requestAttributes = new Map<String, Object>();

                    eorRequestId = String.valueOf(requestAttributes.get('id'));
                    requestContactId  = String.valueOf(contactAttributes.get('id'));
                    requestId = String.valueOf(results.get('id'));
                } catch(Exception ex) {} // do nothing

                if (String.isEmpty(requestId)) {
                    // since we can't reconcile this request back to an originating requestId, we end the flow now with a synchronous feedback
                    return new BspDeprovisioningApiAcknowledgementResponse(true);
                }

                // catch any 'deprovisioning' system errors.
                // these will be fed back via the asycnhronous feedback loop
                try {
                    if (!String.isEmpty(requestContactId)) {
                        // retrieve the user details
                        requestedUser = BAMUserUtility.retrieveContactUserDetail(requestContactId);
                        System.debug('requestedUser' + requestedUser);
                    } else {
                        errors.add(Label.BAMBSP_User_Record_Not_Found);
                    }

                    // if there are errors then we need to feed these back via an asynchronous response (the synchronous response will still return a 204 acknowledgement)
                    if (errors.isEmpty()) {
                        // update the existing user details
                        // remove the BSP profile and revert their access back to a Merchant Portal
                        deprovisionBspUser(requestedUser);

                        response = new BspDeprovisioningApiAsyncResourceResponse(200, 'Fulfilled', requestId);
                    } else {
                        response = new BspDeprovisioningApiAsyncResourceResponse(500, 'Error', requestId, '500', String.join(errors, '\n'));
                    }
                } catch(Exception ex) {
                    response = new BspDeprovisioningApiAsyncResourceResponse(500, 'Error', requestId, '500', ex.getMessage());
                }
            }

        } catch(Exception e) {
            return new BspDeprovisioningApiAcknowledgementResponse(true);
        }

        // based on the Asynchronous response we have built above (BspDeprovisioningApiAsyncResourceResponse), we queue the actual callout to be completed in a future to allow this acknowledgement to complete first
        sendDeprovisioningResponseToCamunda(eorRequestId, response.serialize());

        // if we got to this point then we need to send a 204 acknowledgement back to camunda to acknowledge that the request has been received
        return new BspDeprovisioningApiAcknowledgementResponse();
    }

    // De-provisioning BSP users only involve profile change- Merchant Portal Community User, User will remain active.
    public static void deprovisionBspUser(User customer) {
        // Query Business Portal Community community profile
        Profile profileMap = [
                SELECT Id, Name
                FROM Profile
                WHERE Name = :BAMUserUtility.MERCHANT_PORTAL_PROFILE_NAME
                LIMIT 1
        ];

        Boolean canUpdateUser = false;

        if(BspConstants.BSP_COMMUNITY_PROFILE_NAME.equalsIgnoreCase(customer.Profile.Name)) {
            customer.ProfileId = profileMap.Id;
            canUpdateUser = true;
        }

        if(canUpdateUser) {
            update customer;
        }

        // Also, as a part of the deprovisioning process, if the permission set has been applied then we need to remove it
        List<PermissionSetAssignment> assignments = [Select Id From PermissionSetAssignment
                                                        Where PermissionSet.Name = :BspConstants.BSP_COMMUNITY_PERMISSIONSET_NAME
                                                        And AssigneeId = :customer.Id];
        if(!assignments.isEmpty()) {
            delete assignments;
        }
    }

    @future(callout=true)
    public static void sendDeprovisioningResponseToCamunda(String requestId, String request) {
        try {
            System.debug('Sending Deprovisioning Response: ' + request);

            HttpResponse response = BAMIntegrationUtility.postRequest('BAM_DEPROVISION_RESPONSE', request);

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

    public class BspDeprovisioningApiAsyncResourceResponse extends ResourceAPIService.IResourceResponse {

        public BspDeprovisioningApiAsyncResourceResponse(Integer responseCode, String status, String id) {
            this(responseCode, status, id, '', '');
        }

        public BspDeprovisioningApiAsyncResourceResponse(Integer responseCode, String status, String id, String errorCode, String errorMessage) {
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

    public class BspDeprovisioningApiAcknowledgementResponse extends ResourceAPIService.IResourceResponse {

        public BspDeprovisioningApiAcknowledgementResponse() {
            this(false);
        }

        public BspDeprovisioningApiAcknowledgementResponse(Boolean isMalformed) {
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