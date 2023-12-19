/**************************************************
Type:
History:
--------------------------------------------------
2019-06-27    vcheng@salesforce.com  Created
2019-09-06    hasantha.liyanage@auspost.com.au Modified getInitLoad method
2020-11-09    saiswetha.pingali@auspost.com.au INC1688693- Fix for issues reported with critical update ' Use with sharing for @AuraEnabled Apex Controllers with Implicit Sharing
2023-10-02    Boris Bachovski    Refactor to use IsInactiveCustomer__c instead of is_Inactive_Customer__c
**************************************************/
public without sharing class BAMConfigureApplicationsController {

    public static String FIELD_CONTACTS = 'contacts';
    public static String FIELD_ADMINS = 'admins';
    public static String FIELD_PRODUCTS = 'products';
    public static String FIELD_ACCOUNT = 'account';
    public static String FIELD_ACTIVE = 'active';
    public static String FIELD_MESSAGE = 'message';
    public static String MSG_NO_ACCOUNT_ACCESS = 'You do not have access to this account';


    public static String RT_ASSET_GENERAL = 'General';

    private static UserRecordAccess getRecordAccess(Id recordId)
    {
        Id userId = UserInfo.getUserId();

        List<UserRecordAccess> listUserRecordAccesses = [
                SELECT RecordId, HasEditAccess, HasReadAccess, HasDeleteAccess
                FROM UserRecordAccess
                WHERE UserId = :userId
                AND RecordId = :recordId
        ];
        return listUserRecordAccesses[0];
    }

    @AuraEnabled
    public static Map<String, Object> getInitLoad(Id accountId) {
        //Get external onboarding request BAM record type id
        Id bamExtObRTId = BAMUserUtility.BAM_EXTERNAL_ONBOARDING_REQUEST_RECORD_TYPE_ID;

        Map<String, Object> mapResults = new Map<String, Object>();

        // check Account access
        UserRecordAccess accountAccess = getRecordAccess(accountId);
        if(accountAccess == null || accountAccess.HasReadAccess != true) {
            // early out
            mapResults.put(FIELD_MESSAGE, MSG_NO_ACCOUNT_ACCESS);
            return mapResults;
        }

        List<Product2> relatedProducts = getProducts(accountId);
        mapResults.put(FIELD_PRODUCTS, relatedProducts);

        // house keeping, get the account object
        List<Account> accounts = [SELECT Id, Name FROM Account WHERE Id =: accountId];
        if(accounts.size() == 1) {
            mapResults.put(FIELD_ACCOUNT, accounts[0]);
        }

        // get related contacts
        Map<Id, Contact> contacts = new Map<Id, Contact>([
                SELECT Id, Name, AccountId, Email, Phone, MobilePhone, Status__c, OID_ID__c
                FROM Contact
                WHERE IsInactiveCustomer__c = false
                AND AccountId =: accountId
                ORDER BY Name
        ]);

        Set<Id> contactIds = contacts.keySet();

        // 2. get the Contact Roles and map against the Contact Ids
        List<BAMContactApplication__c> listContactApplications = [
                SELECT Id, Application__c, Application__r.Name, Contact__r.AccountId,
                        Contact__c
                        , (
                        SELECT Id, Status__c, Error__c, Request_Date__c, Type__c
                        FROM BAM_External_Onboarding_Requests__r
                        WHERE RecordTypeId = :bamExtObRTId
                        ORDER BY CreatedDate DESC
                        LIMIT 1
                ),
                (
                        SELECT Id, Status__c, ApplicationRole__r.Role__c
                        FROM ContactRoles__r
                        WHERE Pending_Delete__c = FALSE
                        ORDER BY LastModifiedDate DESC
                )
                FROM BAMContactApplication__c
                WHERE Contact__r.AccountId = :accountId
                AND Contact__c IN: contactIds
                ORDER BY Contact__c, Application__r.Name
        ];

        // getting the contacts ready to send to UI
        Map<String,ContactWrapper> idTocontact = new Map<String,ContactWrapper>();
        for(Contact con : contacts.values()) {
            ContactWrapper preparedContact = new ContactWrapper();
            preparedContact.Name = con.Name;
            preparedContact.Id = con.Id;
            preparedContact.AccountId = con.AccountId;
            preparedContact.Email = con.Email;
            preparedContact.Phone = con.Phone;
            preparedContact.MobilePhone = con.MobilePhone;
            preparedContact.Status = con.Status__c;
            preparedContact.CNumber = con.OID_ID__c;

            // contains the applications related list
            List<ApplicationWrapper> applications = new List<ApplicationWrapper>();

            // start find the related applications
            for(BAMContactApplication__c BAMContactApplication : listContactApplications) {
                if(BAMContactApplication.Contact__c == con.Id && BAMContactApplication.Contact__r.AccountId == con.AccountId) {
                    ApplicationWrapper contactApplication = new ApplicationWrapper();
                    contactApplication.statusError = false;
                    contactApplication.statusPending = false;
                    contactApplication.statusActive = false;

                    //access the external onboarding requedt to chec the status of any pending requests
                    List<BAMExternalOnboardingRequest__c> bamExtRequests = BAMContactApplication.BAM_External_Onboarding_Requests__r;

                    if(!bamExtRequests.isEmpty()) {
                        // get the first record, which should be latest from SOQL ordering
                        BAMExternalOnboardingRequest__c lastRequest = bamExtRequests.get(0);

                        if(lastRequest.Status__c == 'Error'){
                            contactApplication.statusError = true;
                            contactApplication.errorMessage = lastRequest.Error__c;
                        } else if(lastRequest.Status__c == 'Pending') {
                            contactApplication.statusPending = true;
                        }
                    }

                    // if status cannot be set by the requests, check the contact roles, separated here for pre-launch existing access
                    List<BAMContactRole__c> contactRoles = BAMContactApplication.ContactRoles__r;
                    
                    if(!contactApplication.statusError && !contactApplication.statusPending
                            && contactRoles != null && !contactRoles.isEmpty()) {
                        BAMContactRole__c bamContactRole = contactRoles[0];
                        if(bamContactRole.Status__c == 'Active') {
                            contactApplication.statusActive = true;
                        } else if(bamContactRole.Status__c == 'Pending') {
                            contactApplication.statusPending = true;
                        }
                    }

                    contactApplication.Name = BAMContactApplication.Application__r.Name ;
                    applications.add(contactApplication);
                }
            }

            preparedContact.Applications = applications;
            idTocontact.put(con.Id,preparedContact);
        }

        //get customer BAM super Admins
        List<BAMContactRole__c> contactAdminRoles = [
                SELECT ContactApplication__r.Contact__r.Id, ApplicationRole__r.Role__c, ContactApplication__r.Status__c
                From BAMContactRole__c
                Where ContactApplication__r.Application__r.AppKey__c = 'BAM'
                AND ContactApplication__r.Contact__r.Id IN :contacts.keyset()
                ORDER BY ContactApplication__r.Contact__r.Status__c
        ];
        system.debug(contactAdminRoles);
        List<BAMAdminWrapper> bamSuperAdminContacts = new List<BAMAdminWrapper>();
        for(BAMContactRole__c cr :contactAdminRoles){
            // if only if super admins to show at the right hand side box
            if(cr.ApplicationRole__r.Role__c == 'Super Admin') {
                BAMAdminWrapper adminRecord = new BAMAdminWrapper();
                adminRecord.Id = contacts.get(cr.ContactApplication__r.Contact__r.Id).Id;
                adminRecord.Name = contacts.get(cr.ContactApplication__r.Contact__r.Id).Name;
                adminRecord.AccountId = contacts.get(cr.ContactApplication__r.Contact__r.Id).AccountId;
                adminRecord.Email = contacts.get(cr.ContactApplication__r.Contact__r.Id).Email;
                adminRecord.Phone = contacts.get(cr.ContactApplication__r.Contact__r.Id).Phone;
                adminRecord.MobilePhone = contacts.get(cr.ContactApplication__r.Contact__r.Id).MobilePhone;
                adminRecord.ContactStatus = contacts.get(cr.ContactApplication__r.Contact__r.Id).Status__c;
                adminRecord.CNumber = contacts.get(cr.ContactApplication__r.Contact__r.Id).OID_ID__c;
                adminRecord.ApplicationRoleStatus = cr.ContactApplication__r.Status__c;

                //bamSuperAdminContacts.add(contactMap.get(cr.ContactApplication__r.Contact__r.Id));
                bamSuperAdminContacts.add(adminRecord);
                system.debug(contacts.get(cr.ContactApplication__r.Contact__r.Id));
            }

            //updating all the contacts with existing bam apps access
            ContactWrapper preparedContact = (ContactWrapper) idTocontact.get(cr.ContactApplication__r.Contact__r.Id);
            preparedContact.isExistingBAMApps = 'checked';
        }
        mapResults.put(FIELD_ADMINS, bamSuperAdminContacts);
        mapResults.put(FIELD_CONTACTS, idTocontact.values());
        // return a status
        mapResults.put('status', 'OK');
        return mapResults;
    }

    private static List<Product2> getProducts(Id accountId)
    {
        List<Product2> relatedProducts = [
                SELECT Id, Name, (
                        SELECT Id, Name
                        FROM BAM_Applications__r
                ), (
                        SELECT Id, Name, AccountId
                        FROM Assets
                        WHERE AccountId =: accountId
                        AND Status != 'Inactive'
                )
                FROM Product2
                WHERE Id IN (
                        SELECT Product__c
                        FROM BAMApplication__c
                )
                ORDER BY Name
        ];
        return relatedProducts;
    }

    @AuraEnabled
    public static Map<String, Object> updateApplications(Id accountId, List<Map<String, Object>> products)
    {
        Map<String, Object> mapResults = new Map<String, Object>();

        List<Id> idsToActivate = new List<Id>();
        List<Id> idsToDisable = new List<Id>();
        for(Map<String, Object> objProduct:products)
        {
            // assume it will be a Product2 with a json 'active' field
            Id productId = (Id) objProduct.get('Id');
            if(objProduct.get(FIELD_ACTIVE) == true)
            {
                idsToActivate.add(productId);
            }
            else
            {
                idsToDisable.add(productId);
            }
        }

        if(idsToActivate.size() > 0)
        {
            upsertActiveApplications(accountId, idsToActivate);
        }

        if(idsToDisable.size() > 0)
        {
            upsertInactiveApplications(accountId, idsToDisable);
        }

        // return the latest product statuses
        List<Product2> relatedProducts = getProducts(accountId);
        mapResults.put(FIELD_PRODUCTS, relatedProducts);

        String sMessage = idsToActivate.size() + ' active, ' + idsToDisable.size() + ' inactive';
        mapResults.put('toastMessage', sMessage);

        return mapResults;
    }


    private static void upsertActiveApplications(Id accountId, List<Id> productIds)
    {
        List<Product2> relatedProducts = [
                SELECT Id, Name, (
                        SELECT Id, Name
                        FROM BAM_Applications__r
                ), (
                        SELECT Id, Name, AccountId
                        FROM Assets
                        WHERE AccountId =: accountId
                )
                FROM Product2
                WHERE Id IN:productIds
        ];


        Id recordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(RT_ASSET_GENERAL).getRecordTypeId();

        // loop through and upsert where necessary
        List<Asset> assets = new List<Asset>();
        for(Product2 product : relatedProducts)
        {
            Asset upsertAsset;
            if(product.Assets.size() > 0)
            {
                // assume always 1
                upsertAsset = product.Assets[0];
            }
            else
            {
                upsertAsset = new Asset();
                upsertAsset.RecordTypeId = recordTypeId;
                upsertAsset.Product2Id = product.Id;
                upsertAsset.AccountId = accountId;
                upsertAsset.Name = product.Name;
            }

            upsertAsset.Status = 'Active';
            assets.add(upsertAsset);
        }

        if(assets.size() > 0)
        {
            upsert assets;
            System.debug('BAM_assetCreationCmp_CC::ACTIVE assets upserted ' + assets);
        }
    }


    private static void upsertInactiveApplications(Id accountId, List<Id> productIds)
    {
        List<Product2> relatedProducts = [
                SELECT Id, Name, (
                        SELECT Id, Name
                        FROM BAM_Applications__r
                ), (
                        SELECT Id, Name, AccountId
                        FROM Assets
                        WHERE AccountId =: accountId
                )
                FROM Product2
                WHERE Id IN: productIds
        ];

        // loop through and upsert where necessary
        List<Asset> assets = new List<Asset>();
        for(Product2 product : relatedProducts)
        {
            Asset upsertAsset;
            if(product.Assets.size() > 0)
            {
                // assume always 1
                upsertAsset = product.Assets[0];
                upsertAsset.Status = 'Inactive';
                assets.add(upsertAsset);
            }
            else
            {
                // do nothing, no need to create an inactive asset
            }
        }

        if(assets.size() > 0)
        {
            upsert assets;
            System.debug('BAM_assetCreationCmp_CC::INACTIVE assets upserted ' + assets);
        }
    }

    public class BAMAdminWrapper {
        @AuraEnabled public String Id;
        @AuraEnabled public String Name;
        @AuraEnabled public String AccountId;
        @AuraEnabled public String Email;
        @AuraEnabled public String Phone;
        @AuraEnabled public String MobilePhone;
        @AuraEnabled public String ContactStatus;
        @AuraEnabled public String ApplicationRoleStatus;
        @AuraEnabled public String CNumber;
    }

    public class ContactWrapper {
        @AuraEnabled public String Id;
        @AuraEnabled public String Name;
        @AuraEnabled public String AccountId;
        @AuraEnabled public String Email;
        @AuraEnabled public String Phone;
        @AuraEnabled public String MobilePhone;
        @AuraEnabled public String Status;
        @AuraEnabled public String CNumber;
        @AuraEnabled public String isExistingBAMApps;
        @AuraEnabled public List<ApplicationWrapper> Applications;
    }

    public class ApplicationWrapper {
        @AuraEnabled public String Name;
        @AuraEnabled public Boolean statusError;
        @AuraEnabled public Boolean statusPending;
        @AuraEnabled public Boolean statusActive;
        @AuraEnabled public String errorMessage;
    }

}