/**************************************************
Description:  Utility class for parcel send onboarding, this will provide validation, data preperation to
support the core functionality, this will allow the controller class to stay clean

History:
--------------------------------------------------
2019-03-19  hasantha.liyanage@auspost.com.au Created
2019-08-01  hasantha.liyanage@auspost.com.au Modified - PSO-BAM uplift
2019-11-26  gunith.devasurendra@auspost.com.au Fixed multiple contacts of same email address but different Orgs can be on-boarded (INC1499790)
**************************************************/

public without sharing class pso_ParcelSendOnboarding {

    public static String STATUS_NONE = 'Not Provisioned'; //Not sent for provisioning is not listed here as this is a logical value
    public static String STATUS_PENDING = 'Pending Response'; //Request sent but pending response
    public static String STATUS_PARTIAL = 'Partially Provisioned'; //Auth rules are being changed while status is "Pending response"
    public static String STATUS_SUCCESS = 'Provisioned'; //Response received with success
    public static String STATUS_ERROR = 'Provisioning Error'; //Response received with error
    public static String ROLE_ORG = 'Customer'; //Organisation Role
    public static String VALIDATE_NOT_ELIGIBLE = 'NOT ELIGIBLE'; //Validation failed
    public static List<String> SOURCE_SYSTEMS = new List<String> {'TEAM', 'SAP ERP'};

    /**
     * This method validates and check the eligibility for make the Onboarding request
     * validation criteria are as below;
     * VALIDATE 1: organisation Role is Customer, otherwise not eligible
     * VALIDATE 2: Active Contact Application, Contact Role, Linked Entity
     * VALIDATE 3: TEAM and SAP Billing accounts only
     * VALIDATE 4: if any Billing account name is 40 chars or less, otherwise not eligible
     * VALIDATE 5: if any Billing account is not marked for deletion, otherwise not eligible
     * VALIDATE 6: validation against related external onboarding requests get the stored onboarding request if found a one, otherwise create new
     * VALIDATE 7: is active contact
     * VALIDATE 8: has an email address
     * VALIDATE 9: found an External Onboarding Request for the object
     * VALIDATE 10: cNumber already available against the email provided
     * NOTE : any records with Delete pending or deactivation pending , status=inactive, deleted are excluded from validation
     * @param result
     * @param contactId
     */
    public static Response validate(String contactId) {
        system.debug('validate() contactId '+contactId);
        contactId = contactId.left(15);
        try {

            List<StatusResult> results = new List<StatusResult>();
            // get the full contact details by ID
            Contact contact = [SELECT Id, Account.Name, Account.Role_Type_Roll_Up__c, email, Status__c, AccountId, OID_ID__c FROM Contact WHERE Id = :contactId];
            //VALIDATE 7: is active contact?
            if (!'Active'.equals(contact.Status__c)) {
                results.add( new StatusResult(VALIDATE_NOT_ELIGIBLE, 'Contact is not active'));
            }

            //VALIDATE 8: has an email address
            if (String.isEmpty(contact.email)) {
                results.add( new StatusResult(VALIDATE_NOT_ELIGIBLE, 'Contact email address should NOT be empty'));
            } else if (!validateEmail(contact.email)) {
                //VALIDATE 9: should have valid email address
                results.add( new StatusResult(VALIDATE_NOT_ELIGIBLE, 'Contact email address CANNOT contain special characters'));
            } else if(contact.email.length() > 50 || contact.email.length() < 5) {
                //VALIDATE 10 : number of characters limit
                results.add( new StatusResult(VALIDATE_NOT_ELIGIBLE, 'Contact email address cannot be more than 50 or less than 5 characters'));
            } else if(String.isEmpty(contact.OID_ID__c)) {
                //VALIDATE 10: cNumber already available against the email provided
                String cNumber;
                if(!Test.isRunningTest()) {
                    // calling external service to grab the c Number generated with the email address from the contact record
                    cNumber = LDAP_UserAccount_v1.queryUserAccount('', contact.email);
                }

                // if there is a cNumber already available check for the same contact records of same account locally with the retrieved cNumber
                if (!String.isBlank(cNumber)) {
                    List<Contact> contactsInSameOrgWithSameCNumber = [SELECT Id FROM Contact WHERE OID_ID__c =: cNumber AND AccountId =: contact.AccountId];
                    if(contactsInSameOrgWithSameCNumber.size() > 1) {
                        results.add(new StatusResult(VALIDATE_NOT_ELIGIBLE, 'Contact already exists with same Email and a C Number ' + cNumber));
                    }
                }
            }

            //VALIDATE 1: organisation Role is Customer, otherwise not eligible
            if (!ROLE_ORG.equals(contact.Account.Role_Type_Roll_Up__c)) {
                results.add( new StatusResult(VALIDATE_NOT_ELIGIBLE, 'Organisation Role should be ' + ROLE_ORG +' (NOT '+contact.Account.Role_Type_Roll_Up__c+')'));
            }

            // base supports multiple contacts
            pso_base.initialise(new List<String> {contactId}, true, false, true, false, false);
            // START ---- PSO - uplift
            // get the application by name, there could be less than 20 applications maximum configured in here,
            // we can user the name "Parcel Send" to identify the application here as these components are written
            // specifically for PSO
            List<BAMApplication__c> applications = pso_base.applications;

            // no active applications
            if(applications == null || applications.isEmpty()) {
                results.add( new StatusResult(VALIDATE_NOT_ELIGIBLE, 'No Active Applications found!'));
            }

            // find the contact roles related to the application where the contact role is active for the particular contact.
            Map<Id,BAMContactRole__c> contactRoles = pso_base.contactRoles;

            // no active Contact Roles
            if(contactRoles == null || contactRoles.isEmpty()) {
                results.add( new StatusResult(VALIDATE_NOT_ELIGIBLE, 'No Active Contact Roles found!'));
            }

            // Identify the related billing accounts via BAM contact roles, we pass the contact id for the application
            List<BAMContactApplication__c> contactApplications = pso_base.contactApplications;

            // no active Contact Applications
            if(contactApplications == null || contactApplications.isEmpty()) {
                results.add( new StatusResult(VALIDATE_NOT_ELIGIBLE, 'No Active Contact Applications found!'));
            }

            // now we know which application contact has access to and their roles, let's find the billing account related to the contact
            // linked entity is between contact role and billing account, so we grab the LinkedEntities via found contact roles.
            List<BAMLinkedEntity__c> linkedEntities = pso_base.linkedEntities;

            // no active Linked Entities
            if(linkedEntities == null || linkedEntities.isEmpty()) {
                results.add( new StatusResult(VALIDATE_NOT_ELIGIBLE, 'No Linked Entities found!'));
            }

            // Linked entity has the related billing accounts, let's collect all the billing accounts here
            List<Billing_Account__c> relatedBillingAccounts = pso_base.relatedBillingAccounts;

            // no active Billing Accounts
            if(relatedBillingAccounts == null || relatedBillingAccounts.isEmpty()) {
                results.add( new StatusResult(VALIDATE_NOT_ELIGIBLE, 'No related Billing Accounts found!'));
            }

            // validation check for all the related billing accounts
            for(Billing_Account__c billingAccount : relatedBillingAccounts) {
                // VALIDATE 7: TEAM and SAP Billing accounts only, What if the auth rule is manager, there's no billing accounts for managers
                if (!SOURCE_SYSTEMS.contains(billingAccount.Source_System__c)) {
                    results.add( new StatusResult(VALIDATE_NOT_ELIGIBLE, 'Source system is not ' + String.join(SOURCE_SYSTEMS, ' OR ') + '!'));
                }

                // if the billing account is AP and the MLID is blank, throw the error
                if(SOURCE_SYSTEMS[1].equals(billingAccount.Source_System__c) && String.isEmpty(billingAccount.MLID__c)) {
                    results.add(new StatusResult(VALIDATE_NOT_ELIGIBLE, 'AP Billing Account '+billingAccount.LEGACY_ID__c+ ' should have an MLID'));
                }

                String billingAccountName = billingAccount.Name;
                // VALIDATE 4: if any Billing account name is 40 chars or less
                if (String.isEmpty(billingAccountName) || billingAccountName.length() > 40) {
                    if(String.isEmpty(billingAccountName)) {
                        results.add(new StatusResult(VALIDATE_NOT_ELIGIBLE, 'Billing account name is blank'));
                    } else {
                        results.add(new StatusResult(VALIDATE_NOT_ELIGIBLE, 'Billing account ' + billingAccountName + ' is more than 40 chars!'));
                    }
                }

                // VALIDATE 5: if any Billing account is not marked for deletion
                if (billingAccount.SAP_marked_for_deletion__c) {
                    results.add( new StatusResult(VALIDATE_NOT_ELIGIBLE, 'Billing account ' + billingAccountName + ' is marked for deletion!'));
                }
            }

            // VALIDATE 6: validation against related external onboarding requests get the stored onboarding request if found a one, otherwise create new
            List<BAMExternalOnboardingRequest__c> onboardingRequests = pso_ParcelSendOnboarding.getAllExternalOnboardingRequests( new List<String> {contactId});

            BAMExternalOnboardingRequest__c onboardingRequest;
            // no onboarding requests found
            if (onboardingRequests.size() > 0) {
                Boolean isAuthRuleIssue = false;
                onboardingRequest = onboardingRequests.get(0);
                pso_base.initialise(new List<String> {contactId}, false, true);
                //auth rule modified/added inactivate after the initial request sent
                // we will check whether the rules are updated after a request is being in progress
                // if there is a validation check fails with Auth rues, lets not check for the external Onboarding Requests
                String changeMessage = pso_Base.isModifiedAfterSubmit(onboardingRequest.Request_Date__c);
                if( changeMessage !='' && onboardingRequest.Status__c == 'Success') {
                    results.add( new StatusResult(STATUS_PARTIAL, changeMessage+' has been modified for this provisioned contact, You might need to resend for provisioning'));
                    isAuthRuleIssue = true;
                }

                if(!isAuthRuleIssue) {
                    // VALIDATE 8: successful status found
                    if (onboardingRequest.Status__c == 'Success') {
                        results.add(new StatusResult(STATUS_SUCCESS, 'Onboarding Request successful'));
                    }
                    // VALIDATE 9: found an External Onboarding Request for the object
                    if (onboardingRequest.Status__c == 'Pending') {

                        // started but not fulfilled
                        if (onboardingRequest.CSSOStartedDateTime__c != null && onboardingRequest.CSSOFulfilledDateTime__c == null) {
                            results.add(new StatusResult(STATUS_PENDING, 'CSSO Email Sent to Customer'));
                        } else {
                            results.add(new StatusResult(STATUS_PENDING, 'Onboarding Request in progress for this customer'));
                        }
                    }

                    // VALIDATE 10: existing failed Onboarding request found
                    if (onboardingRequest.Status__c == 'Error') {
                        String responseText = '';
                        String summary = '';
                        String detail = '';
                        // if the response text is written by the Camunda response, we will try to get a message out of it for user
                        if(String.isNotEmpty(onboardingRequest.Response_Payload__c)) {
                            responseText = onboardingRequest.Response_Payload__c;
                            summary = responseText.substringBefore(':');
                            detail = responseText.substringAfter(':');
                        }

                        results.add(new StatusResult(STATUS_ERROR, 'Previous onboarding Request failed', summary, detail));
                    }
                }
            }
            system.debug('results results '+results);
            // parse the results
            return getFinalResult(results);

        } catch (Exception ex) {
            //Throw any other exceptions to lightning component as AuraHandled exceptions
            system.debug('[pso_parcelSendOnboarding] : validate() exception = ' + ex.getStackTraceString() + ' Error message ' + ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * Decide the final status to display,
     * response instance is to store the final result response after the above validations
     * response will contain "StatusResults" which allows us to store the validation failure reason messages
     *
     * @param results
     *
     * @return Response: prepared response record
     */
    public static Response getFinalResult(List<StatusResult> results) {
        try {
            Response response = new Response();

            // no failed validations found, in this case the button will be clickable and the onboarding request is ready to send
            if(results.size() <= 0) {
                results.add(new StatusResult(STATUS_NONE, ''));
                response.isSuccess = true;
                response.Status = STATUS_NONE;
                response.disabled = false;
            } else {
                // go through all the validation errors
                for(StatusResult res :results) {
                    // check for external validations : there could only be one type of status error partial pending
                    if(STATUS_ERROR.equals(res.Status) || STATUS_PARTIAL.equals(res.Status) || STATUS_PENDING.equals(res.Status) || STATUS_SUCCESS.equals(res.Status)) {
                        response.isSuccess = false;
                        response.Status = res.Status;
                        response.disabled = false;
                        response.message = '';
                        // disable if the external request is in progress or completed successfully
                        if(STATUS_PENDING.equals(res.Status) || STATUS_SUCCESS.equals(res.Status)) {
                            response.disabled = true;
                        }
                        break;
                        // internal validation failed
                    } else if(VALIDATE_NOT_ELIGIBLE.equals(res.Status)) {
                        response.isSuccess = false;
                        response.Status = res.Status;
                        response.disabled = true;
                        break;
                    }
                }
            }

            response.StatusResults = results;

            system.debug('getFinalResult getFinalResult :'+response);
            return response;
        } catch (Exception ex) {
            //Throw any other exceptions to lightning component as AuraHandled exceptions
            system.debug('[pso_parcelSendOnboarding] : validate() exception = ' + ex.getStackTraceString() + ' Error message ' + ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
    }
    /**
     *  prepare and pass for onboarding requests for the contacts passed
     *
     * @param contactIds
     */
    public static Boolean createExternalOnboardingRequest(List<String> contactIds) {
        try{
            // retrieve existing external onboarding requests for the contacts
            List<BAMExternalOnboardingRequest__c> externalRequestsFound = pso_ParcelSendOnboarding.getAllExternalOnboardingRequests(contactIds);
            List<BAMExternalOnboardingRequest__c> externalRequestsForUpdate = new List<BAMExternalOnboardingRequest__c>();

            //prepare update/new records to upsert
            for(String contact : contactIds) {
                BAMExternalOnboardingRequest__c externalOnboardingRequest;
                for (BAMExternalOnboardingRequest__c eor : externalRequestsFound) {
                    // if there are records which are not completed, pull them and update for a new request
                    // past success records needs to be ignored and create a new request
                    if (contact == eor.Contact__c && eor.Status__c != 'Success') {
                        externalOnboardingRequest = eor;
                        break;
                    }
                }

                // there is no existing onboarding requests being sent before
                if(externalOnboardingRequest == null) {
                    externalOnboardingRequest = new BAMExternalOnboardingRequest__c();
                }
                // prepare the external request
                externalOnboardingRequest.Contact__c = contact;
                externalOnboardingRequest.Request_Date__c = System.Now();
                externalOnboardingRequest.Response_Payload__c = '';
                externalOnboardingRequest.Status__c = 'Pending'; // set the status to pending
                externalOnboardingRequest.RecordTypeId = Schema.SObjectType.BAMExternalOnboardingRequest__c.getRecordTypeInfosByDeveloperName().get('PS').getRecordTypeId();
                externalRequestsForUpdate.add(externalOnboardingRequest);
            }

            List<Database.UpsertResult> upsertResults = Database.Upsert(externalRequestsForUpdate, true);

            // check for the successful save
            Boolean saveSuccess = true;
            for (Database.UpsertResult upsertResult :upsertResults) {
                if(!upsertResult.isSuccess()) {
                    saveSuccess = false ;
                    break;
                }
            }

            return saveSuccess;


        } catch (Exception ex) {
            //Throw any other exceptions to lightning component as AuraHandled exceptions
            system.debug('[pso_parcelSendOnboarding] : sendRequest() exception = ' + ex.getStackTraceString() + ' Error message ' + ex.getMessage());
            throw ex;
        }
    }

    /**
     * Prepare the Json string and call the Camunda endpoint to begin the onboarding process
     *
     * @param externalRequests
     */
    public static String prepareAndCalloutRequest(List<String> contactIds) {
        try {

            // get the saved record
            List<BAMExternalOnboardingRequest__c> savedExternalOnboardingRequests = pso_ParcelSendOnboarding.getExternalOnboardingRequests(contactIds, new List<String> {'Error','Pending'});

            // base supports multiple contacts
            pso_base.initialise(contactIds, true, false);
            // query auth rules for the contact
            Map<Id, List<Billing_Account__c>> billingAccountsByContact = pso_Base.getRelatedBillingAccountsByContact();

            // prepare the json string
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
            gen.writeFieldName('contacts'); // highest level
            gen.writeStartArray();

            for(BAMExternalOnboardingRequest__c savedRequest : savedExternalOnboardingRequests) {
                List<Billing_Account__c> billingAccounts = billingAccountsByContact.get(savedRequest.Contact__c);
                gen.writeStartObject();
                gen.writeStringField('order-number', savedRequest.Id); // second level
                gen.writeFieldName('account-manager'); // second level

                gen.writeStartObject(); // start members of account-manager
                gen.writeStringField('last-name', UserInfo.getFirstName());
                gen.writeStringField('first-name', UserInfo.getLastName());
                gen.writeStringField('email-address', UserInfo.getUserEmail() );
                gen.writeEndObject(); // end members of account-manager

                gen.writeFieldName('contact'); // second level
                gen.writeStartObject(); // start members of contact
                gen.writeStringField('id', savedRequest.Contact__c);
                gen.writeStringField('last-name', savedRequest.Contact__r.LastName);
                gen.writeStringField('first-name', getValue(savedRequest.Contact__r.FirstName));
                gen.writeStringField('email-address', getValue(savedRequest.Contact__r.Email));
                gen.writeStringField('apbcn', getValue(savedRequest.Contact__r.Account.LEGACY_ID__c));
                gen.writeStringField('apcn', getValue(savedRequest.Contact__r.APCN__C));
                gen.writeStringField('cnumber', getValue(savedRequest.Contact__r.OID_ID__c));
                gen.writeEndObject(); // end members of contact

                gen.writeFieldName('account-numbers'); // second level
                gen.writeStartArray();
                for(Billing_Account__c billingAccount : billingAccounts){ // billing accounts
                    gen.writeStartObject();
                    gen.writeStringField('account-id', billingAccount.LEGACY_ID__c);
                    gen.writeStringField('mlid', getValue(billingAccount.MLID__c));
                    gen.writeEndObject();
                }
                gen.writeEndArray();
                gen.writeEndObject();
            }

            gen.writeEndArray();
            gen.writeEndObject();
            String jsonData = gen.getAsString();

            return jsonData;

        } catch (Exception ex) {
            //Throw any other exceptions to lightning component as AuraHandled exceptions
            system.debug('[pso_parcelSendOnboarding] : prepareAndCalloutRequest() exception = ' + ex.getStackTraceString() + ' Error message ' + ex.getMessage());
            throw ex;
        }
    }

    /**
     * Utility method to retrieve the latest not completed ExternalOnboardingRequest__c record
     *
     * @param contactId
     *
     * @return latest ExternalOnboardingRequest__c record
     */
    public static List<BAMExternalOnboardingRequest__c> getAllExternalOnboardingRequests(List<String> contactIds) {
        return getExternalOnboardingRequests(contactIds, new List<String> {'Error','Pending','Success'});
    }

    /**
     * retrieve external onboarding requests by contact ids and statuses
     *
     * @param contactIds
     * @param statuses
     *
     * @return List<ExternalOnboardingRequest__c>
     */
    public static List<BAMExternalOnboardingRequest__c> getExternalOnboardingRequests(List<String> contactIds, List<String> statuses) {

        String queryString = ' ' +
                ' SELECT  Id, Request_Date__c, Status__c, Contact__c, LastModifiedDate, Response_Payload__c, Response_Date__c, Contact__r.LastName, Contact__r.FirstName, '+
                '         Contact__r.Email, Contact__r.Account.LEGACY_ID__c, Contact__r.APCN__C, Contact__r.OID_ID__c, '+
                '         Contact__r.Account.Owner.FirstName, Contact__r.Account.Owner.LastName, Contact__r.Account.Owner.Email, CSSOStartedDateTime__c, CSSOFulfilledDateTime__c  '+
                ' FROM    BAMExternalOnboardingRequest__c '+
                ' WHERE   Contact__c =: contactIds '+
                ' AND     RecordType.DeveloperName = \'PS\' '+
                ' AND1      '+
                ' ORDER BY LastModifiedDate desc ';

        if(statuses != null && !statuses.isEmpty()) {
            queryString = queryString.replace('AND1','AND Status__c IN (\'' + String.join(statuses, '\',\'') + '\') ');
        } else {
            queryString = queryString.replace('AND1',' ');
        }


        return Database.query(queryString);
    }

    /**
     * parse null values
     *
     * @param value
     *
     * @return
     */
    private static String getValue(String value){
        return String.isEmpty(value) ? '' : value;
    }


    //Simply validates if the email is in the x@x.x format. It doesn't validate if 'x' contains only allowable characters.
    public static Boolean validateEmail(String email) {
        if (String.isNotBlank(email)) {
            return Pattern.matches('^[A-Za-z0-9-_]+(\\.[A-Za-z0-9-_]+)*@[A-Za-z0-9-_]+(\\.[A-Za-z0-9-_]+)*(\\.[a-z]{2,8})$', email);
        }

        return false;
    }

    /**
     * Main Response passed to aura
     */
    public class Response {
        @AuraEnabled  public Boolean disabled { get; set; }
        @AuraEnabled  public Boolean isSuccess { get; set; }
        @AuraEnabled  public String Status { get; set; }
        @AuraEnabled  public String message { get; set; }
        @AuraEnabled  public List<StatusResult> StatusResults { get; set; }
        public Response() {
        }

        public Response(string Status, Boolean isSuccess) {
            this.isSuccess = isSuccess;
            this.Status = Status;
        }
    }

    /**
     * Child record of the Main Response "Response" class,
     * this is to store all the validation failure results as a list in the main response
     */
    public class StatusResult {
        @AuraEnabled  public string status { get; set; }
        @AuraEnabled  public string message { get; set; }
        @AuraEnabled  public string errorSummary { get; set; }
        @AuraEnabled  public string errorDescription { get; set; }

        public StatusResult(string status, String message) {
            this.status = status;
            this.Message = Message;
        }

        public StatusResult(string status, String message, String errorSummary, String errorDescription) {
            this.status = status;
            this.message = message;
            this.errorSummary = errorSummary;
            this.errorDescription = errorDescription;
        }
    }

}