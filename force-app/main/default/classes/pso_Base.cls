/**
 * Created by hasantha on 26/7/19.
 * Summary : caters the common utility methods to retrieve/prepare and store data to be used in any calling classes
 * once the class is initialised public members of the class will store the data
 *
 * Following objects are the key objects in the new authorisation structure;
 * - BAMApplication__c - the application type (pso, bsp etc.)
 * - BAMContactApplication__c - linking contact with application
 * - BAMContactRole__c - role of the contact in the application
 * - BAMLinkedEntity__c - Which entities are accessible by the contact (accessing the billing accounts)
 *
 * As a final result we seek the billing accounts related to the contact and allow user to send for provisioning
 *
 *
 **/

public without sharing class pso_Base {
    // contact ids are required to call any methods, attributes in this class
    private static List<String> contactIds;
    // unless initialised whenever we access the public attributes it will never re-query data.

    private static boolean isActiveOnly = false;
    private static boolean isAllRows = false;
    private static boolean isConsiderPendingFields = false;
    private static boolean isPendingDelete = false;
    private static boolean isPendingActivate = false;


    private static String buildSOQLFilter(String queryString) {

        // bring only the records with status active
        if (isActiveOnly) {
            queryString = queryString.replace('AND1', ' AND Status__c =  \'Active\' ');
        } else {
            queryString = queryString.replace('AND1', ' ');
        }

        // if asking to consider pending records
        if(isConsiderPendingFields) {
            // consider pending delete field for the SOQL
            if (isPendingDelete) {
                queryString = queryString.replace('AND2', ' AND Pending_Delete__c = true ');
            } else {
                queryString = queryString.replace('AND2', ' AND Pending_Delete__c = false');
            }

            // consider pending Active field for the SOQL
            if (isPendingActivate) {
                queryString = queryString.replace('AND3', ' AND Pending_Deactivation__c = true ');
            } else {
                queryString = queryString.replace('AND3', ' AND Pending_Deactivation__c = false ');
            }
        } else {
            queryString = queryString.replace('AND2', ' ');
            queryString = queryString.replace('AND3', ' ');
        }

        // bring all rows so that we can track changes to a provisioning request with pending status
        if (isAllRows) {
            queryString = queryString.replace('ALLROWS', 'ALL ROWS');
        } else {
            queryString = queryString.replace('ALLROWS', ' ');
        }

        return queryString;
    }

    // BAMApplication__c
    // get the application by name, there could be less than 20 applications maximum configured in here,
    // we can user the name "Parcel Send" to identify the application here as these components are written
    // specifically for PSO
    public static List<BAMApplication__c> applications {
        get {
            system.debug('#PSO applications entry');
            if (applications == null) {

                String queryString = 'SELECT Id, IsDeleted, Status__c, Product__c, AccessUrl__c, AppKey__c, ServiceType__c, ' +
                        ' LaunchApplicationInNewWindow__c, ProvisioningTimeout__c, DeprovisioningTimeout__c, Name , CreatedDate, LastModifiedDate' +
                        ' FROM BAMApplication__c ' +
                        ' WHERE AppKey__c = \'PS\' ' +
                        ' AND1 ' +
                        ' ORDER BY LastModifiedDate desc ' +
                        ' ALLROWS ';

                queryString = buildSOQLFilter(queryString);
                applications = Database.query(queryString);
            }
            return applications;
        }
        set;
    }

    // BAMContactApplication__c
    // Identify the related billing accounts via BAM contact roles, we pass the contact id for the application
    public static List<BAMContactApplication__c> contactApplications {
        get {
            system.debug('#PSO relatedBillingAccounts entry');
            // return empty list if application is not found
            if (applications.isEmpty()) {
                return new List<BAMContactApplication__c>();
            }
            if (contactApplications == null) {

                String applicationId = applications[0].Id;
                String queryString =
                        ' SELECT Id, Name, IsDeleted, LastModifiedDate, Application__c, Contact__c, Application_Name__c, Contact_Name__c, Status__c, '+
                        ' BSPCanViewAllConsignments__c, Pending_Delete__c, Pending_Deactivation__c, UniqueKey__c, AppKey__c , CreatedDate'+
                        ' FROM BAMContactApplication__c '+
                        ' WHERE Application__c = :applicationId '+
                        ' AND Contact__c = :contactIds '+
                        ' AND1 ' + /* status */
                        ' AND2 ' + /* pending delete */
                        ' AND3 ' + /* pending deactivate */
                        ' ORDER BY LastModifiedDate desc ' +
                        ' ALLROWS ';
                queryString = buildSOQLFilter(queryString);
                contactApplications = Database.query(queryString);

            }
            return contactApplications;
        }
        set;
    }

    // BAMContactRole__c
    // find the contact roles related to the application where the contact role is active for the particular contact.
    public static Map<Id, BAMContactRole__c> contactRoles {
        get {
            system.debug('#PSO contactRoles entry');
            // return empty list if application is not found
            if (applications.isEmpty() || contactApplications.isEmpty()) {
                return new Map<Id, BAMContactRole__c>();
            }
            if (contactRoles == null) {

                String queryString =
                                ' SELECT Id, Name, IsDeleted, LastModifiedDate, CreatedDate, ApplicationRole__c, Status__c, Application_Role_Role__c, Application_Role_Access__c, ApplicationName__c, '+
                                ' ContactApplication__c, ContactApplication__r.Name, ContactApplication__r.Contact__c, Contact_Id__c, Contact_Name__c, Application_Id__c, Pending_Delete__c, UniqueKey__c '+
                                ' FROM BAMContactRole__c '+
                                ' WHERE ContactApplication__r.Contact__c = :contactIds '+
                                ' AND ContactApplication__c = :contactApplications '+
                                ' AND1 ' +
                                ' AND2 ' +
                                ' ORDER BY LastModifiedDate desc ' +
                                ' ALLROWS ';


                queryString = buildSOQLFilter(queryString);
                contactRoles = new Map<Id, BAMContactRole__c>(
                        (List<BAMContactRole__c>)Database.query(queryString)
                );

            }
            return contactRoles;
        }
        set;
    }

    // BAMLinkedEntity__c
    // now we know which application contact has access to and their roles, let's find the billing account related to the contact
    // linked entity is between contact role and billing account, so we grab the LinkedEntities via found contact roles.
    public static List<BAMLinkedEntity__c> linkedEntities {
        get {
            system.debug('#PSO linkedEntities entry');
            // return empty list if contact roles not found
            if (contactRoles.isEmpty()) {
                return new List<BAMLinkedEntity__c>();
            }
            if (linkedEntities == null) {

                Set<Id> contactRolesTemp = contactRoles.keySet();
                String queryString =
                        ' SELECT Id, IsDeleted, Name, ContactRole__c, ContactRole__r.Name,  ContactRole__r.Application_Role_Role__c, ContactRole__r.ContactApplication__r.Contact__c, LastModifiedDate, ' +
                        ' BillingAccount__c, BillingAccount__r.Source_System__c, BillingAccount__r.Name,  '+
                        ' BillingAccount__r.MLID__c, BillingAccount__r.LEGACY_ID__c, BillingAccount__r.SAP_marked_for_deletion__c, BillingAccount__r.IsDeleted, '+
                        ' Organisation__c, Group__c, Group__r.Name, Pending_Delete__c, Status__c, UniqueKey__c, BillingAccount__r.LastModifiedDate , BillingAccount__r.CreatedDate , CreatedDate'+
                        ' FROM BAMLinkedEntity__c '+
                        ' WHERE ContactRole__c = :contactRolesTemp '+
                        ' AND1 ' +
                        ' AND2 ' +
                        ' ORDER BY LastModifiedDate desc ' +
                        ' ALLROWS ';

                queryString = buildSOQLFilter(queryString);
                linkedEntities = Database.query(queryString);
            }
            return linkedEntities;
        }
        set;
    }

    // pull all the bam groups
    public static List<BAMGroup__c> groups {
        get {
            system.debug('#PSO groups entry');
            // return empty list if contact roles not found
            if (linkedEntities.isEmpty()) {
                return new List<BAMGroup__c>();
            }
            Set<Id> bamGroupIds = new Set<Id>();
            for (BAMLinkedEntity__c linkedEntity : linkedEntities) {
                bamGroupIds.add(linkedEntity.Group__c);
            }
            if (groups == null) {
                String queryString =
                        ' SELECT Id, IsDeleted, Name, LastModifiedDate, CreatedDate '+
                        ' FROM BAMGroup__c '+
                        ' WHERE Id = :bamGroupIds '+
                        ' AND1 ' +
                        ' ORDER BY LastModifiedDate desc ' +
                        ' ALLROWS ';

                queryString = buildSOQLFilter(queryString);
                groups = Database.query(queryString);
            }
            return groups;
        }
        set;
    }

    // get the billing accounts related
    public static List<BAMGroupBillingAccount__c> groupBillingAccounts {
        get {
            system.debug('#PSO groupBillingAccounts entry');
            // return empty list if contact roles not found
            if (linkedEntities.isEmpty()) {
                return new List<BAMGroupBillingAccount__c>();
            }
            Set<Id> bamGroupIds = new Set<Id>();
            for (BAMLinkedEntity__c linkedEntity : linkedEntities) {
                bamGroupIds.add(linkedEntity.Group__c);
            }
            if (groupBillingAccounts == null) {
                String queryString =
                        ' SELECT Id, IsDeleted, Name, LastModifiedDate, CreatedDate '+
                                ' FROM BAMGroupBillingAccount__c '+
                                ' WHERE Group__c = :bamGroupIds '+
                                ' AND1 ' +
                                ' ORDER BY LastModifiedDate desc ' +
                                ' ALLROWS ';

                queryString = buildSOQLFilter(queryString);
                groupBillingAccounts = Database.query(queryString);
            }
            return groupBillingAccounts;
        }
        set;
    }

    // Linked entity has the related billing accounts, let's collect all the billing accounts here,
    // if the
    public static List<Billing_Account__c> relatedBillingAccounts {
        get {
            system.debug('#PSO relatedBillingAccounts entry');
            // return empty list if no linked entities found
            if (linkedEntities.isEmpty()) {
                return new List<Billing_Account__c>();
            }
            if (relatedBillingAccounts == null) {
                relatedBillingAccounts = new List<Billing_Account__c>();
                // start collecting the groups here when there is no BA's linked found
                Set<Id> bamGroupIds = new Set<Id>();

                for (BAMLinkedEntity__c linkedEntity : linkedEntities) {
                    // there must be a billing account to be eligible to submit a contact to a onboarding process
                    if (linkedEntity.BillingAccount__c != null) {
                        relatedBillingAccounts.add(linkedEntity.BillingAccount__r);
                    } else {
                        // if no billing account found look for a group to fin Billing account allocations
                        bamGroupIds.add(linkedEntity.Group__c);
                    }
                }

                // we need a set to hold the billing account ids to extract them from Group Billing Account and SOQL actual Billing Accounts
                Set<Id> billingAccountIds = new Set<Id>();

                // let's get related Group Billing Accounts by group Ids
                for (BAMGroupBillingAccount__c bamGroupBillingAccount : [
                        SELECT Id, BillingAccount__c
                        FROM BAMGroupBillingAccount__c
                        WHERE Group__c = :bamGroupIds
                        AND Group__r.Status__c = 'Active'
                ]) {
                    billingAccountIds.add(bamGroupBillingAccount.BillingAccount__c);
                }

                // collect the billing account ids to query the related Billing accounts
                relatedBillingAccounts.addAll([
                    SELECT Id, MLID__c, LEGACY_ID__c, Source_System__c, Name, SAP_marked_for_deletion__c, LastModifiedDate, IsDeleted
                    FROM Billing_Account__c
                    WHERE Id = :billingAccountIds
                ]);

            }

            return relatedBillingAccounts;
        }
        set;
    }

    /**
     * get linked entities by contact
     *
     * @return Map<Id, List<BAMLinkedEntity__c>>
     */
    public static Map<Id, List<BAMLinkedEntity__c>> getLinkedEntityByContact() {
        system.debug('#PSO getLinkedEntityByContact entry'+linkedEntities);
        Map<Id, List<BAMLinkedEntity__c>> linkedEntityByContact = new Map<Id, List<BAMLinkedEntity__c>>();
        // no linked entities means return empty
        if(linkedEntities == null || linkedEntities.isEmpty()) {
            return linkedEntityByContact;
        }

        // start filtering the linked entities
        for (BAMLinkedEntity__c bamLinkedEntity : linkedEntities) {
            if (linkedEntityByContact.get(bamLinkedEntity.ContactRole__r.ContactApplication__r.Contact__c) == null) {
                linkedEntityByContact.put(bamLinkedEntity.ContactRole__r.ContactApplication__r.Contact__c, new List<BAMLinkedEntity__c>{
                });
            }
            List<BAMLinkedEntity__c> linkedEntity = linkedEntityByContact.get(bamLinkedEntity.ContactRole__r.ContactApplication__r.Contact__c);
            linkedEntity.add(bamLinkedEntity);
        }
        return linkedEntityByContact;
    }


    /**
     * filter billing accounts retrieved and put them in a contact to billing accounts map,
     * this will especially be used to prepare the request to Camunda
     *
     * @return
     */
    public static Map<Id, List<Billing_Account__c>> getRelatedBillingAccountsByContact() {
        system.debug('#PSO getRelatedBillingAccountsByContact entry');
        Map<Id, List<Billing_Account__c>> relatedBillingAccountsByContact = new Map<Id, List<Billing_Account__c>>();
        // we need the linked entities by contacts first
        Map<Id, List<BAMLinkedEntity__c>> linkedEntitiesByContact = getLinkedEntityByContact();
        if(linkedEntitiesByContact == null || linkedEntitiesByContact.isEmpty()){
            return relatedBillingAccountsByContact;
        }
        system.debug('#PSO getRelatedBillingAccountsByContact entry2');

        // start collecting the groups here when there is no BA's linked found
        Map<String, String> bamGroupIdByContact = new Map<String, String>();

        // iterate through to find billing accounts on Linked entities or
        for (String contactId : linkedEntitiesByContact.keySet()) {
            system.debug('#PSO getRelatedBillingAccountsByContact entry3');
            // grab linked entities for contact
            List<BAMLinkedEntity__c> linkedEntities = linkedEntitiesByContact.get(contactId);
            system.debug('#PSO getRelatedBillingAccountsByContact entry4');
            // go through each entity to find billing accounts for the contact
            for (BAMLinkedEntity__c linkedEntity : linkedEntities) {
                system.debug('#PSO getRelatedBillingAccountsByContact entry5');
                // there must be a billing account to be eligible to submit a contact to a onboarding process
                if (linkedEntity.BillingAccount__c != null) {
                    if (relatedBillingAccountsByContact.get(contactId) == null) {
                        relatedBillingAccountsByContact.put(contactId, new List<Billing_Account__c>{
                        });
                    }
                    List<Billing_Account__c> relatedBillingAccounts = relatedBillingAccountsByContact.get(contactId);
                    relatedBillingAccounts.add(linkedEntity.BillingAccount__r);
                } else {
                    // if no billing account found look for a group to fin Billing account allocations
                    bamGroupIdByContact.put(linkedEntity.Group__c, linkedEntity.ContactRole__r.ContactApplication__r.Contact__c);
                }
            }
        }

        // we need a set to hold the billing account ids to extract them from Group Billing Account and SOQL actual Billing Accounts
        Set<Id> billingAccountIds = new Set<Id>();

        // let's get related Group Billing Accounts by group Ids
        for (BAMGroupBillingAccount__c bamGroupBillingAccount : [
                SELECT Id, Group__c, BillingAccount__c, BillingAccount__r.MLID__c, BillingAccount__r.LEGACY_ID__c, BillingAccount__r.Source_System__c, BillingAccount__r.Name, BillingAccount__r.SAP_marked_for_deletion__c
                FROM BAMGroupBillingAccount__c
                WHERE Group__c = :bamGroupIdByContact.keySet()
                AND Group__r.Status__c = 'Active'
        ]) {
            String contactId = bamGroupIdByContact.get(bamGroupBillingAccount.Group__c);
            if (relatedBillingAccountsByContact.get(contactId) == null) {
                relatedBillingAccountsByContact.put(contactId, new List<Billing_Account__c>{
                });
            }
            List<Billing_Account__c> relatedBillingAccounts = relatedBillingAccountsByContact.get(contactId);
            relatedBillingAccounts.add(bamGroupBillingAccount.BillingAccount__r);
        }

        return relatedBillingAccountsByContact;

    }

    // constructor to initialise the data, this will start loading all the data required for the application at once,
    // when there is a data request this will use the singleton pattern to bring the data.
    public pso_Base() {

    }

    /**
     *
     *
     * @param contacts Contacts to pull Active Contact Application, Contact Role, Linked Entity, Groups, Group Billing Accounts and Billing accounts
     * @param isActiveRecordsOnly Only the records with Status Active
     * @param allRows Bring all the records includes Deleted and Archived, so that we can track any changes for a onboarding request which is in progress
     * @param isPendingFields  do you want to consider is Pending Delete and Pending Activation fields in the SOQL?
     * @param isDeleted if the isPendingFields is true, this will include Pending_Delete__c = true other wise Pending_Delete__c = false
     * @param isToBeActivated if the isPendingFields is true, this will include Pending_Deactivation__c = true otherwise Pending_Deactivation__c = false
     */
    public static void initialise(List<String> contacts, Boolean isActiveRecordsOnly, Boolean allRows, Boolean isPendingFields, Boolean isDeleted, Boolean isToBeActivated) {
        // contact id is required before requesting data
        if (contacts == null || contacts.isEmpty()) {
            system.debug('pso_base : Contact id cannot be null ');
            throw new AuraHandledException('pso_base : Contact id cannot be null ');
        }
        isActiveOnly = isActiveRecordsOnly;
        isAllRows = allRows;
        contactIds = contacts;
        isConsiderPendingFields = isPendingFields;
        isPendingDelete = isDeleted;
        isPendingActivate = isToBeActivated;
        // this initialisation is required to initiate each collection, this has to be in following order as there are dependencies.
        applications = null;
        contactRoles = null;
        contactApplications = null;
        linkedEntities = null;
        relatedBillingAccounts = null;
    }


    /**
     * Initialise with all rows, Overwrites above initialise constructor, this will not consider the pending fields at all.
     *
     * @param contacts Contacts to pull Active Contact Application, Contact Role, Linked Entity, Groups, Group Billing Accounts and Billing accounts
     * @param isActiveRecordsOnly Only the records with Status Active
     * @param allRows Bring all the records includes Deleted and Archived, so that we can track any changes for a onboarding request which is in progress
     */
    public static void initialise(List<String> contacts, Boolean isActiveRecordsOnly, Boolean allRows) {
        pso_base.initialise(contacts, isActiveRecordsOnly, allRows, false, false, false);
    }
    /**
     * Methods is to identify if the any of the following relsted records are changed once an
     * onboarding request is in pending, if something is modified we need to shoe the status as
     * Partially Provisioned
     *
     * @param lastModifiedDate
     *
     * @return true/false
     */
    public static String isModifiedAfterSubmit(Datetime lastModifiedDate) {
        // check on related contact applications
        for (BAMContactApplication__c contactApplication : contactApplications) {
            // if the record is modified while the request is in progress
            if (contactApplication.LastModifiedDate > lastModifiedDate) {
                return 'Contact Application';
            }
        }

        // check on related contact role
        for (BAMContactRole__c bamContactRole : contactRoles.values()) {
            // if the record is modified while the request is in progress
            if (bamContactRole.LastModifiedDate > lastModifiedDate) {
                return 'Contact Role';
            }
        }

        //check on related linked entities
        for (BAMLinkedEntity__c bamLinkedEntity : linkedEntities) {
        // if the record is modified while the request is in progress
            if (bamLinkedEntity.LastModifiedDate > lastModifiedDate) {
                return 'Linked Entities';
            }
        }

        //check on related billing accounts
        for (Billing_Account__c billingAccount : relatedBillingAccounts) {
            // if the record is modified while the request is in progress
            if (billingAccount.LastModifiedDate > lastModifiedDate) {
                return 'Related Billing Account';
            }
        }


        //check on related billing accounts
        for (BAMGroup__c billingAccount : groups) {
            // if the record is modified while the request is in progress
            if (billingAccount.LastModifiedDate > lastModifiedDate) {
                return 'Group';
            }
        }

        //check on related billing accounts
        for (BAMGroupBillingAccount__c billingAccount : groupBillingAccounts) {
            // if the record is modified while the request is in progress
            if (billingAccount.LastModifiedDate > lastModifiedDate) {
                return 'Group Billing Account';
            }
        }

        return '';
    }

    public class ValidationException extends Exception {
    }


}