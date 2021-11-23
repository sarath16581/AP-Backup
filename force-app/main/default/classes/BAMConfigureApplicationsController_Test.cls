/**************************************************
Type:
History:
--------------------------------------------------
2019-06-27    vcheng@salesforce.com  Created
**************************************************/
@isTest
public class BAMConfigureApplicationsController_Test {

    private static String LEGACY_ID = 'something';


    @isTest private static void test_noAccountAccess()
    {
        // create an Account
        Account testAccount = BAMTestUtility.createTestAccount(LEGACY_ID);
        insert testAccount;
        Id accountId = testAccount.Id;
        // then delete it to simulate no access
        delete testAccount;

        Test.startTest();
        Map<String, Object> mapResults = BAMConfigureApplicationsController.getInitLoad(testAccount.Id);
        System.debug('BAMConfigureApplicationsController_Test::test_noAccountAccess:' + mapResults);

        String sMessage = (String) mapResults.get(BAMConfigureApplicationsController.FIELD_MESSAGE);
        System.assertEquals(BAMConfigureApplicationsController.MSG_NO_ACCOUNT_ACCESS, sMessage, 'Expected error message for now acces, got ' + sMessage);
        Test.stopTest();
    }

    @isTest
    public static void test_initSearch()
    {
        BAMApplication__c app = BAMTestUtility.createBamApplication(BAMUserTableController.ACCESS_MANAGEMENT);
        insert app;
        // create an application role
        BAMApplicationRole__c appRole = BAMTestUtility.createApplicationRole(app);
        insert appRole;
        // create an account
        Account testAccount = BAMTestUtility.createTestAccount(LEGACY_ID);
        insert testAccount;
        // create a Application-Product-Asset
        Asset testAsset = BAMTestUtility.createAsset(testAccount.Id, app.Product__c, true);
        insert testAsset;
        // create a contact
        Contact testContact = BAMTestUtility.createTestContact(testAccount.Id, '1234');
        insert testContact;

        // create the junction Contact-Application
        BAMContactApplication__c contactApp = new BAMContactApplication__c();
        contactApp.Contact__c = testContact.Id;
        contactApp.Application__c = app.Id;
        insert contactApp;

        User testUser = BAMTestUtility.createBusinessPortalUser(testContact,BAMUserUtility.MERCHANT_PORTAL_PROFILE_NAME);
        insert testUser;

        Test.startTest();




        Map<String, Object> mapResults = BAMConfigureApplicationsController.getInitLoad(testAccount.Id);
        System.debug('BAMConfigureApplicationsController_Test::test_getInitLoad:' + mapResults);

        Account accountResult = (Account) mapResults.get(BAMConfigureApplicationsController.FIELD_ACCOUNT);
        System.assertEquals(testAccount.Id, accountResult.Id, 'Expected Account ' + testAccount.Id + ' to be returned, got ' + accountResult);

        Test.stopTest();
    }

    @isTest
    private static void test_updateApplicationsActive()
    {
        Account testAccount = BAMTestUtility.createTestAccount(LEGACY_ID);
        insert testAccount;

        Id accountId = testAccount.Id;

        String appName1 = 'App001';
        String appName2 = 'App002';
        BAMApplication__c appWithAsset = BAMTestUtility.createBamApplication(appName1);
        appWithAsset.AppKey__c = 'App001';
        BAMApplication__c appNoAsset = BAMTestUtility.createBamApplication(appName2);
        appNoAsset.AppKey__c = 'App002';
        List<BAMApplication__c> testApps = new List<BAMApplication__c> {appWithAsset, appNoAsset};
        insert testApps;

        Asset assetForApp = BAMTestUtility.createAsset(accountId, appWithAsset.Product__c, false);
        insert assetForApp;

        // retrieve the products created
        List<Id> productIds = new List<Id> {appWithAsset.Product__c, appNoAsset.Product__c};
        List<Product2> products = [SELECT Id, Name FROM Product2 WHERE Id =:productIds];

        // convert each one to a map and add the 'active' field
        List<Map<String, Object>> listProducts = new List<Map<string, Object>>();
        for(Product2 product:products)
        {
            Map<String, Object> mapProduct = BAMTestUtility.convertToMap(product);
            mapProduct.put(BAMConfigureApplicationsController.FIELD_ACTIVE, true);
            listProducts.add(mapProduct);
        }

        Test.startTest();
        Map<String, Object> mapResults = BAMConfigureApplicationsController.updateApplications(testAccount.Id, listProducts);
        System.debug('BAMConfigureApplicationsController_Test::test_updateApplicationsActive:' + mapResults);

        List<Asset> assetResults = [
                SELECT Id, AccountId, Status
                FROM Asset WHERE AccountId =: accountId
                AND Status = 'Active'
        ];
        System.assertEquals(2, assetResults.size(), 'Expected 2 assets, found ' + assetResults);

        //Account accountResult = (Account) mapResults.get(BAMConfigureApplicationsController.FIELD_ACCOUNT);
        //System.assertEquals(testAccount.Id, accountResult.Id, 'Expected Account ' + testAccount.Id + ' to be returned, got ' + accountResult);

        Test.stopTest();
    }


    @isTest
    private static void test_updateApplicationsInactive()
    {
        Account testAccount = BAMTestUtility.createTestAccount(LEGACY_ID);
        insert testAccount;

        Id accountId = testAccount.Id;

        String appName1 = 'App001';
        String appName2 = 'App002';
        BAMApplication__c appWithAsset = BAMTestUtility.createBamApplication(appName1);
        appWithAsset.AppKey__c = 'App001';
        BAMApplication__c appNoAsset = BAMTestUtility.createBamApplication(appName2);
        appNoAsset.AppKey__c = 'App002';
        List<BAMApplication__c> testApps = new List<BAMApplication__c> {appWithAsset, appNoAsset};
        insert testApps;

        Asset assetForApp = BAMTestUtility.createAsset(accountId, appWithAsset.Product__c, false);
        insert assetForApp;

        // retrieve the products created
        List<Id> productIds = new List<Id> {appWithAsset.Product__c, appNoAsset.Product__c};
        List<Product2> products = [SELECT Id, Name FROM Product2 WHERE Id =:productIds];

        // convert each one to a map and add the 'active' field
        List<Map<String, Object>> listProducts = new List<Map<string, Object>>();
        for(Product2 product:products)
        {
            Map<String, Object> mapProduct = BAMTestUtility.convertToMap(product);
            mapProduct.put(BAMConfigureApplicationsController.FIELD_ACTIVE, false);
            listProducts.add(mapProduct);
        }

        Test.startTest();
        Map<String, Object> mapResults = BAMConfigureApplicationsController.updateApplications(testAccount.Id, listProducts);
        System.debug('BAMConfigureApplicationsController_Test::test_updateApplicationsInactive:' + mapResults);

        List<Asset> assetResults = [
                SELECT Id, AccountId, Status
                FROM Asset WHERE AccountId =: accountId
                AND Status != 'Active'
        ];
        System.assertEquals(1, assetResults.size(), 'Expected 1 asset, found ' + assetResults);

        //Account accountResult = (Account) mapResults.get(BAMConfigureApplicationsController.FIELD_ACCOUNT);
        //System.assertEquals(testAccount.Id, accountResult.Id, 'Expected Account ' + testAccount.Id + ' to be returned, got ' + accountResult);

        Test.stopTest();
    }

}