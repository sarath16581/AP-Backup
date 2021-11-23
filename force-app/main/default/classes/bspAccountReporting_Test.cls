@isTest
private class bspAccountReporting_Test {
    
    @testSetup
    static void testSetup() {
        Id reportRecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByDeveloperName().get('Report').getRecordTypeId();
        
        Account testAccount = TestDataProvider.createAccount('Test Account', 1)[0];
        testAccount.Business_Solutions_Customer__c = true;
        testAccount.Transfer_Case_Queue__c = 'Sorry We Missed You'; 
        Database.insert(testAccount);
        
        testAccount.Legacy_Id__c = '60000000';
        Database.update(testAccount);
        
        List<Billing_Account__c> testBillingAccList = TestDataProvider.createBillingAccount('', 4, new List<Account>{
            testAccount
                });
        testBillingAccList[0].Source_System__c = BspConstants.SOURCE_SYSTEM_TEAM;
        testBillingAccList[0].LEGACY_ID__c = 'P1234567';
        testBillingAccList[1].Source_System__c = BspConstants.SOURCE_SYSTEM_SAP_ERP;
        testBillingAccList[1].LEGACY_ID__c = '12039485';
        testBillingAccList[1].MLID__c = '42N';
        testBillingAccList[2].Source_System__c = BspConstants.SOURCE_SYSTEM_SAP_ERP;
        testBillingAccList[2].LEGACY_ID__c = '20355936';
        testBillingAccList[2].MLID__c = 'JDQ';
        testBillingAccList[3].Source_System__c = BspConstants.SOURCE_SYSTEM_TEAM;
        testBillingAccList[3].LEGACY_ID__c = 'P323456';
        Database.insert(testBillingAccList);
        
        Contact newCon = new Contact(FirstName = 'David', LastName = 'Catindoy', MobilePhone = '0421546325', Email = 'davidcatindoy@gmail.com', BillingAccount__c = testBillingAccList[0].Id, AccountId = testAccount.Id, Contact_Type__c = StarTrack_Constants.CONTACT_TYPE, Status__c = StarTrack_Constants.CON_STAT_ACTIVE, CCUAuthorisedAllOrgCases__c = true);
        Database.insert(newCon);
        
        
        // BAM Specific functionality
        // creation of a product that is linked to the customer record to ensure BSP is enabled for the customer
        Product2 bspProduct = new Product2(Name = 'BSP');
        insert bspProduct;
        
        BAMApplication__c app = new BAMApplication__c(AppKey__c = 'BSP', ConfigurationModel__c = 'Per Customer', Product__c = bspProduct.Id, ServiceType__c = 'Salesforce', Status__c = 'Active');
        insert app;
        
        List<BAMApplicationRole__c> appRoles = new List<BAMApplicationRole__c>{
            new BAMApplicationRole__c(Application__c = app.Id, Role__c = 'Super Admin', ShowOrganisation__c = true, Status__c = 'Active'),
                new BAMApplicationRole__c(Application__c = app.Id, Role__c = 'Admin', ShowBillingAccount__c = true, ShowGroup__c = true, Status__c = 'Active'),
                new BAMApplicationRole__c(Application__c = app.Id, Role__c = 'User', ShowBillingAccount__c = true, ShowGroup__c = true, Status__c = 'Active')
                };
                    insert appRoles;
        
        
        //--insert files to "testAccount"
        Blob beforeblob=Blob.valueOf('Unit Test Attachment Body');
        
        ContentVersion cv = new ContentVersion();  //TO DO: Can get from data factory class
        cv.title = 'test File ';      
        cv.PathOnClient ='test';           
        cv.VersionData =beforeblob; 
        cv.Document_Type__c = 'DIFOT';
        cv.Document_Interval__c = 'Daily';
        cv.RecordTypeId = reportRecordTypeId;
        cv.Document_Date__c = datetime.now().date();
        Database.insert(cv);     
        
        // ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :cv.Id];
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=testAccount.id;
        contentlink.ShareType= 'v';
        contentlink.ContentDocumentId=documents[0].Id;
        contentlink.Visibility = 'AllUsers'; 
        insert contentlink;   
    }
    
    
    private static User setupCommunityUser()
    {
        Contact con = [Select Id, AccountId, BillingAccount__c From Contact LIMIT 1];
        
        // grab the application roles for BSP so we can assign them to the user
        BAMApplication__c app = [Select Id From BAMApplication__c Where AppKey__c = 'BSP'];
        BAMApplicationRole__c bspAdminRole = [Select Id, Application__c, Role__c From BAMApplicationRole__c Where Application__r.AppKey__c = 'BSP' And Role__c = 'Admin'];
        
        // populate all the billing accounts we will need to use in this test
        Map<Id, Billing_Account__c> billingAccountsMap = new Map<Id, Billing_Account__c>([Select Id, Name, LEGACY_ID__c From Billing_Account__c]);
        Map<String, Billing_Account__c> billingAccounts = mapBillingAccountsToNumber(billingAccountsMap.values());
        System.debug(billingAccounts);
        
        BAMContactApplication__c contactApplication = new BAMContactApplication__c(BSPCanViewAllConsignments__c = false, Application__c = app.Id, Contact__c = con.Id, Status__c = 'Active');
        insert contactApplication;
        
        // wee need to assign some roles with billing accounts to the contact to test their access
        List<BAMContactRole__c> contactRoles = new List<BAMContactRole__c>{
            new BAMContactRole__c(ApplicationRole__c = bspAdminRole.Id, ContactApplication__c = contactApplication.Id, Status__c = 'Active')
                };
                    insert contactRoles;
        
        // add some linked entities to the contact role
        // in this test, only 3 out of the 4 billing accounts are available to this user
        List<BAMLinkedEntity__c> entities = new List<BAMLinkedEntity__c>{
            new BAMLinkedEntity__c(ContactRole__c = contactRoles[0].Id, BillingAccount__c = billingAccounts.get('P1234567').Id, Status__c = 'Active'),
                new BAMLinkedEntity__c(ContactRole__c = contactRoles[0].Id, BillingAccount__c = billingAccounts.get('12039485').Id, Status__c = 'Active'),
                new BAMLinkedEntity__c(ContactRole__c = contactRoles[0].Id, BillingAccount__c = billingAccounts.get('20355936').Id, Status__c = 'Active')
                };
                    insert entities;
        System.Debug(entities);
        
        User u = new User(Alias = 'bspUser', Email = 'user@testorg.a', ContactId = con.Id, EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                          LocaleSidKey = 'en_US', ProfileId = [SELECT Id FROM Profile WHERE Name = 'BSP Community User'].Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'user@testorg.a');
        return u;
        
    }
    
    private static Map<String, Billing_Account__c> mapBillingAccountsToNumber(List<Billing_Account__c> billingAccounts) {
        Map<String, Billing_Account__c> output = new Map<String, Billing_Account__c>();
        for(Billing_Account__c billingAccount : billingAccounts) {
            output.put(billingAccount.LEGACY_ID__c, billingAccount);
        }
        return output;
    }
    
    @IsTest
    public static void testIsDIFOTFilesExists()
    {
        
        User commUser = setupCommunityUser();
        System.runAs(commUser)
        {
            Test.startTest();
            Boolean isFilesExists = bspAccountReporting.isDIFOTFilesExists();
            System.assertEquals(true, isFilesExists, 'Success :Files exists');
            Test.stopTest();
        }
    }
    
    @IsTest
    public static void testGetAllOrgFiles()
    {
        User commUser = setupCommunityUser();
        System.runAs(commUser)
        {
            Test.startTest();
            List<Account> acc = [SELECT Id FROM Account where Name='Test Account' LIMIT 1];
            bspAccountReporting.SerchResultsWrapper srw = bspAccountReporting.getFiles('Report', 'DIFOT', 'Daily', datetime.now().date().addDays(-5) , datetime.now().date().addDays(5), 1,2, 'CreatedDate', 'Desc' ,'all');
            
            System.assertEquals(1, srw.paginatedSearchResults.size(), 'Success :Got DIFOT Files');
            Test.stopTest();
        }
    }

}