/**************************************************
Description:  Parcel send onboarding controller, is to consumed by the lightn ing component in lightning out VF page

History:
--------------------------------------------------
2019-03-09  hasantha.liyanage@auspost.com.au Created
2019-08-09  hasantha.liyanage@auspost.com.au Modified, according to PSO-BAM uplift
**************************************************/
public without sharing class pso_ParcelSendOnboardingController {
    public Contact contact { get; set; }


    public pso_parcelSendOnboardingController(ApexPages.StandardController stdController) {
        contact = (Contact)stdController.getRecord();
    }

    /**
     * Read the contact by ID, this involves read through a field set,
     * at the moment UI is not dynamicaly rendered.
     *
     * @param contactId
     *
     * @return
     */
    @auraEnabled
    public static Object getContact(String contactId) {
        String query = 'SELECT ';
        for(Schema.FieldSetMember f : getContactFields()) {
            query += f.getFieldPath() + ', ';
        }
        query += 'Id FROM Contact WHERE Id = :contactId LIMIT 1';

        system.debug('CONTACT QUERY '+query);
        List<Contact> obj = Database.query(query);
        //contact =  obj.size() > 0 ? obj[0] : null;
        return obj.size() > 0 ? obj[0] : null;
    }

    /**
     * grab the field set for the Contact Fields to Display on UI
     *
     * @return
     */
    public static List<Schema.FieldSetMember> getContactFields() {
        return SObjectType.Contact.FieldSets.ExternalOnboardingContactDetails.getFields();
    }

    /**
     * This method is to perform the eligibility to enable the button
     *
     * @param contactId
     *
     * @return
     */
    @AuraEnabled
    public static pso_ParcelSendOnboarding.Response getStatus(String contactId) {
        try {
            system.debug('pso_ParcelSendOnboarding getStatus == '+contactId);
            return pso_ParcelSendOnboarding.validate(contactId);

        } catch (Exception ex) {
            //Throw any other exceptions to lightning component as AuraHandled exceptions
            system.debug('[pso_parcelSendOnboardingController] : getStatus() exception = ' + ex.getStackTraceString() + ' Error message ' + ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * transfer all the data to be displayed on the UI, this includes;
     * applications, ContactApplications, ContactRoles, LikedEntities, groups, groupBillingAccounts,
     * and all the billing accounts related to contact
     *
     * @param contactId
     *
     * @return DisplayRecordsResponse, custom type to Transfer Data
     */
    @AuraEnabled
    public static DisplayRecordsResponse getRelatedRecordsByContact(String contactId) {
        try {
            pso_base.initialise(new List<String> {contactId}, false, false);

            DisplayRecordsResponse response = new DisplayRecordsResponse();
            response.applications = pso_base.applications;
            response.contactApplications = pso_base.contactApplications;
            response.contactRoles = pso_Base.contactRoles.values();
            response.linkedEntities = pso_base.linkedEntities;
            response.groups = pso_base.groups;
            response.groupBillingAccounts = pso_base.groupBillingAccounts;
            response.billingAccounts = pso_base.relatedBillingAccounts;

            return response;

        } catch (Exception ex) {
            //Throw any other exceptions to lightning component as AuraHandled exceptions
            system.debug('[pso_parcelSendOnboardingController] : getAuthRulesByContact() exception = ' + ex.getStackTraceString() + ' Error message ' + ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * Create an ExternalOnboardingRequest__c Record
     *
     * @param contactId
     *
     * @return
     */
    @AuraEnabled
    public static pso_ParcelSendOnboarding.Response createOnboardingRequest(String contactId) {
        try {
            List<String> contactIds = new List<String>{contactId};
            if(pso_ParcelSendOnboarding.createExternalOnboardingRequest(contactIds)){
                return new pso_ParcelSendOnboarding.Response('SUCCESS', true);
            }

            return new pso_ParcelSendOnboarding.Response('SUCCESS', false);
        } catch (Exception ex) {
            //Throw any other exceptions to lightning component as AuraHandled exceptions
            system.debug('[pso_parcelSendOnboardingController] : createOnboardingRequest() exception = ' + ex.getStackTraceString() + ' Error message ' + ex.getMessage());
            throw new AuraHandledException(ex.getMessage());
        }
    }


    /**
     * DTO for Response
     */
    public class StatusResponse {
        @AuraEnabled public string OnboardingStatus { get; set; }
        @AuraEnabled public string Status { get; set; }
        @AuraEnabled public string Message  { get; set; }
        @AuraEnabled public boolean Success  { get; set; }

        public StatusResponse() {
        }

        public StatusResponse(string Status, string OnboardingStatus, String Message) {
            this.Status = Status;
            this.OnboardingStatus = OnboardingStatus;
            this.Message = Message;
        }
        public StatusResponse(string Status, string Message) {
            this.Status = Status;
            this.Message = Message;
        }
    }

    /**
     * DTO for the records to be displayed to the user.
     */
    public class DisplayRecordsResponse {
        @AuraEnabled public List<BAMApplication__c> applications  { get; set; }
        @AuraEnabled public List<BAMContactApplication__c> contactApplications { get; set; }
        @AuraEnabled public List<BAMContactRole__c> contactRoles { get; set; }
        @AuraEnabled public List<BAMLinkedEntity__c> linkedEntities { get; set; }
        @AuraEnabled public List<BAMGroup__c> groups { get; set; }
        @AuraEnabled public List<BAMGroupBillingAccount__c> groupBillingAccounts { get; set; }
        @AuraEnabled public List<Billing_Account__c> billingAccounts { get; set; }

    }

}