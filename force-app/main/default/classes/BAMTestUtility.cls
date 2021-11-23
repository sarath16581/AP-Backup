/*
 * Class to create test data 
 * AJ 12 Aug 2019 - Set to isTest. Updated createExternalOnboardingRequest to set record type as BAM
 */
@isTest
public class BAMTestUtility {

    static String TEST_FIRSTNAME = 'Charles';
    static String TEST_LASTNAME = 'Xavier';
    static String TEST_EMAIL = 'test@test.com';

    public static Account createTestAccount(String legacyId)
    {
        // create some weirdo account to bypass the billing account trigger error
        Account legacy = new Account();
        legacy.FirstName = 'legacy';
        legacy.LastName = 'retired';
        legacy.PersonEmail = 'retired@example.com';
        legacy.LEGACY_ID__c = '60000000';
        insert legacy;

        // create an Account(Org)
        Id rId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId();

        Account testAccount = new Account();
        testAccount.RecordTypeId = rId;
        testAccount.Name='TestAccount';
        testAccount.LEGACY_ID__c = legacyId;
        return testAccount;
    }


    public static Contact createTestContact(Id accId, String oId)
    {
        Contact testContact = new Contact();
        testContact.FirstName = TEST_FIRSTNAME;
        testContact.LastName = TEST_LASTNAME;
        testContact.Email = TEST_EMAIL;
        testContact.AccountId = accId;
        testContact.OID_ID__C = oId;
        testContact.Status__c = 'Active';
        return testContact;
    }

    public static BAMApplication__c createBamApplication(String appName)
    {
        Product2 product = new Product2();
        product.Name = appName;
        insert product;

        return createBamApplication(appName, product.Id);
    }

    public static BAMApplication__c createBamApplication(String appName, Id productId)
    {
        // create an application
        BAMApplication__c app = new BAMApplication__c();
        app.Name = appName;
        app.ConfigurationModel__c = 'Per Customer';
        app.Status__c = 'Active';
        app.Product__c = productId;
        app.appKey__c = appName.substring(0,Math.min(appName.length(), 9));
        app.ServiceType__c = 'Salesforce';
        return app;
    }

    public static Asset createAsset(Id accountId, Id productId, Boolean isActive)
    {
        // find the product
        List<Product2> products = [SELECT Id, Name FROM Product2 WHERE Id =: productId];

        Asset testAsset = new Asset();
        Id recordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('General').getRecordTypeId();
        testAsset.RecordTypeId = recordTypeId;
        testAsset.Product2Id = productId;
        testAsset.AccountId = accountId;
        testAsset.Name = products[0].Name;
        if(isActive) {
            testAsset.Status = 'Active';
        }
        else {
            testAsset.Status = 'Inactive';
        }
        return testAsset;
    }

    public static BAMApplicationRole__c createApplicationRole(BAMApplication__c app) {
        return createApplicationRole(app, 'Admin');
    }

    public static BAMApplicationRole__c createApplicationRole(BAMApplication__c app, String roleName) {
        BAMApplicationRole__c appRole = new BAMApplicationRole__c();
        appRole.Role__c = roleName;
        appRole.Application__c = app.Id;
        appRole.ShowBillingAccount__c = true;
        appRole.ShowGroup__c = true;
        appRole.ShowOrganisation__c = true;
        appRole.status__c = 'Active';
        return appRole;
    }

    public static Billing_Account__c createTestBillingAccount(Id accountId, String name)
    {
        Billing_Account__c bac = new Billing_Account__c();
        bac.Organisation__c = accountId;
        bac.Name = name;
        bac.Source_System__c = 'SAP ERP';
        return bac;
    }
    
    public static BAMGroup__c createTestGroup(Id accountId)
    {
        BAMGroup__c grp = new BAMGroup__c();
        grp.Organisation__c = accountId;
        grp.Name = 'Group001';
        return grp;
    }
    public static BAMGroupBillingAccount__c createTestGroupBillingAccount(Id grpId, Id baId)
    {
        BAMGroupBillingAccount__c grpBA = new BAMGroupBillingAccount__c();
        grpBA.BillingAccount__c = baId;
        grpBA.Group__c = grpId;
        return grpBA;
    }
    public static BAMContactApplication__c createTestContactApplication(Id contactId, Id appId)
    {
        BAMContactApplication__c conApp = new BAMContactApplication__c();
        conApp.Contact__c = contactId;
        conApp.Application__c = appId;
        conApp.Status__c = 'Active';
        return conApp;
    }        

    public static BAMContactRole__c createTestContactRole(Id conAppId, Id appRoleId)
    {
        BAMContactRole__c conRole = new BAMContactRole__c();
        conRole.ContactApplication__c = conAppId;
        conRole.ApplicationRole__c = appRoleId;
        conRole.Status__c ='Active';
        return conRole;
    }
    
    public static BAMLinkedEntity__c createTestLinkedEntity(Id conRoleId, Id entityId, String type)
    {
        BAMLinkedEntity__c le = new BAMLinkedEntity__c();
        le.ContactRole__c = conRoleId;

        switch on type {
            when 'ba' { 
                le.BillingAccount__c = entityId;
            }
            when 'grp' { 
                le.Group__c = entityId;
            }
            when 'org' { 
                le.Organisation__c = entityId;
            }
        }
        return le;
    }  
 
    public static Schema.Location createLocation(String locationName, Id orgId){
        Schema.Location objLocation = new Schema.Location();
        objLocation.Name = locationName;
        objLocation.Organisation__c = orgId;
        objLocation.LocationType = 'Warehouse';
        objLocation.TimeZone  = 'Australia/Sydney';
        objLocation.IsInventoryLocation = false;
        objLocation.IsMobile = false; 
        objLocation.RecordTypeId = Schema.SObjectType.Location.getRecordTypeInfosByName().get('Despatch Location').getRecordTypeId();       
        return objLocation;                
    }

    public static BAMExternalOnboardingRequest__c createExternalOnboardingRequest(Id conId, Id conAppId, String status, datetime responseDateTime)
    {
        Id bamExtObRTId = BAMUserUtility.BAM_EXTERNAL_ONBOARDING_REQUEST_RECORD_TYPE_ID;
        
        BAMExternalOnboardingRequest__c eobr = new BAMExternalOnboardingRequest__c();
        eobr.Contact__c = conId;
        eobr.Contact_Application__c = conAppId;
        eobr.Response_Date__c = responseDateTime;
        eobr.Status__c = status;
        eobr.RecordTypeId = bamExtObRTId;
        return eobr; 
    }
    
    public static Map<String, Object> convertToMap(Product2 product)
    {
        Map<String, Object> mapOriginal = product.getPopulatedFieldsAsMap();

        Map<String, Object> mapReturn = new Map<String, Object>();
        for(String keyString:mapOriginal.keySet())
        {
            mapReturn.put(keyString, mapOriginal.get(keyString));
        }
        return mapReturn;
    }

    public static Map<String, Id> createBamBasicRecords(){
        
        //Map to store object Ids to return
        Map<String, Id> recordIdMap = new  Map<String,Id>();
        
        Account acc = createTestAccount('9999');
        insert acc;
        recordIdMap.put('acc',acc.Id);
           System.debug('acc==>' + acc);
        
        Billing_Account__c testBA = createTestBillingAccount(acc.ID, 'BA001');
        insert testBA;
        recordIdMap.put('ba',testBA.Id);        
   System.debug('bar==>' + testBA.Id);
        
        Contact con = createTestContact(acc.Id, 'C123456');
        con.BillingAccount__c = testBA.Id;  
        insert con;
        recordIdMap.put('con',con.Id); 
           System.debug('con==>' + con.Account);
        System.debug('con==>' + con.BillingAccount__c);
        
        Schema.Location location = createLocation('Location1', acc.Id);
        insert location;
        recordIdMap.put('loc',location.Id); 
           System.debug('loc==>' + location.Id);
        BAMGroup__c grp = createTestGroup(acc.Id);
        grp.Despatch_Location__c = location.Id;
        insert grp;
        recordIdMap.put('grp',grp.Id); 
           System.debug('grp==>' + grp.Id);
        BAMGroupBillingAccount__c grpBA = createTestGroupBillingAccount(grp.Id, testBA.Id);
        insert grpBA;
           System.debug('grpBA==>' + grpBA);
        BAMApplication__c app = createBamApplication('BSP');
        app.appKey__c ='BSP';
        insert app;
        
        recordIdMap.put('app',app.Id); 
   System.debug('app==>' + app);
        Asset prod = createAsset(acc.Id, app.Product__c, true);
        insert prod;
           System.debug('prod==>' + prod);
        BAMApplicationRole__c appRole = createApplicationRole(app);
        insert appRole;
        recordIdMap.put('approle',appRole.Id); 
           System.debug('approle==>' + appRole.Id); 
        BAMContactApplication__c conApp = createTestContactApplication(con.Id, app.Id);
        insert conApp;
        recordIdMap.put('conapp',conApp.Id);
        System.debug('conapp==>' + conapp.Id); 
        BAMContactRole__c conRole = createTestContactRole(conApp.Id, appRole.Id);
        insert conRole;
        recordIdMap.put('conrole',conRole.Id);
        System.debug('conrole==>' + conrole.Id); 
        BAMLinkedEntity__c leBA = createTestLinkedEntity(conRole.Id, testBA.Id, 'ba');
        insert leBA;
        recordIdMap.put('billingaccle',leBA.Id);
        BAMLinkedEntity__c leOrg = createTestLinkedEntity(conRole.Id, acc.Id, 'org');
        insert leOrg;
        BAMLinkedEntity__c leGrp = createTestLinkedEntity(conRole.Id, grp.Id, 'grp');
        insert leGrp;
        System.debug('recordIdMap==>' + recordIdMap.keySet()); 
        User portalUser = createBusinessPortalUser(con, BspConstants.BSP_COMMUNITY_PROFILE_NAME);
        insert portalUser;
        recordIdMap.put('User',portalUser.Id);
        
              
        Profile prof = [SELECT Id,Name FROM profile where Name ='AusPost Integration API Only' LIMIT 1];
        User usr = TestUtility.createUser('Wayne',prof.id,null);
        insert usr;

        Profile prof1 = [SELECT Id,Name FROM profile where Name ='System Administrator' LIMIT 1];
        User usr1 = TestUtility.createUser('Admin',prof1.id,null);
        insert usr1;
        
        recordIdMap.put('APIUser',usr.Id);
        recordIdMap.put('Admin',usr1.Id);
        
        return recordIdMap;
    }

    public static User createBusinessPortalUser(Contact customerContact , String profileName){
        Profile profileMap = [
                SELECT Id, Name
                FROM Profile
                WHERE Name = :profileName
                LIMIT 1
        ];

        Integer randomNumber = Integer.valueof((Math.random() * 10));
        String usernameSuffix = ((String) customerContact.Id).substring(14, 17);
        User newBSPUser = new User();
        newBSPUser.ProfileId = profileMap.Id;
        newBSPUser.FirstName = customerContact.FirstName;
        newBSPUser.LastName = customerContact.LastName;
        newBSPUser.ContactId = customerContact.Id;
        //newBSPUser.Contact.accountId = customerContact.AccountId;
        newBSPUser.Username = customerContact.LastName.left(4) + randomNumber + '@' + usernameSuffix + '.bsp';
        newBSPUser.Email = customerContact.Email;
        //newBSPUser.User_Type__c = 'CSPLitePortal';
        newBSPUser.CommunityNickname = customerContact.LastName.left(4) + usernameSuffix;
        newBSPUser.Alias = customerContact.FirstName.left(1) + customerContact.LastName.left(4) + usernameSuffix;
        newBSPUser.TimeZoneSidKey = 'Australia/Sydney'; // Required
        newBSPUser.LocaleSidKey = 'en_AU'; // Required
        newBSPUser.EmailEncodingKey = 'ISO-8859-1'; // Required
        newBSPUser.LanguageLocaleKey = 'en_US'; // Required
        newBSPUser.IsActive = true;
        System.debug(newBSPUser);
        return  newBSPUser;
    }
    


    // to remove, for demo only
    public static void mockCamundaEvent(String requestId, String status, String responseText, Boolean cssoFailed)
    {
        Id safeRequestId = (Id) requestId;
        Id bamExtObRTId = BAMUserUtility.BAM_EXTERNAL_ONBOARDING_REQUEST_RECORD_TYPE_ID;

        List<BAMExternalOnboardingRequest__c> beors = [
                SELECT Id, Type__c, Contact_Application__c, Application_Name__c, Contact__c
                FROM BAMExternalOnboardingRequest__c
                WHERE Id =: safeRequestId 
                AND RecordTypeId = :bamExtObRTId 
        ];
        if(beors.size() > 0)
        {
            BAMExternalOnboardingRequest__c bamExt = beors[0];

            ExternalOnboardingEvent__e evt = new ExternalOnboardingEvent__e();
            evt.IsBam__c = true;
            evt.RequestNumber__c = requestId;

            if(bamExt.Application_Name__c == 'Access Management')
                evt.Application__c = 'BAM';
            else if(bamExt.Application_Name__c == 'Parcel Send')
                evt.Application__c = 'PS';
            else
                evt.Application__c = 'BSP';

            evt.Contact__c = bamExt.Contact__c;
            if(cssoFailed){
                evt.Type__c = 'CSSO'; 
            }
            else{
               evt.Type__c = bamExt.Type__c; 
            }
            
            evt.Status__c = status;

            if(responseText != null && responseText != '')
                evt.ResponseText__c = responseText;

            System.debug(evt);
            EventBus.publish(evt);
        }
        else
        {
            System.debug('No BAM External Onboarding Events found');
        }
    }


}