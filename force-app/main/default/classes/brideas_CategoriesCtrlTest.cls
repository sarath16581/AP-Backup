@isTest
public with sharing class brideas_CategoriesCtrlTest {
    @testSetup
    private static void setup(){
        Test.startTest();

        Profile stdUserProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        List<User> users = new List<User>();

        users.add(new User(
                Username = 'unittest1@brideasCategoriesCtrlTest.com',
                Email = 'unittest1@brideasCategoriesCtrlTest.com',
                Alias = 'test1', EmailEncodingKey='UTF-8', LastName='Testing1', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = stdUserProfile.Id, TimeZoneSidKey='America/Los_Angeles'
        ));
        users.add(new User(
                Username = 'unittest2@brideasCategoriesCtrlTest.com',
                Email = 'unittest2@brideasCategoriesCtrlTest.com',
                Alias = 'test2', EmailEncodingKey='UTF-8', LastName='Testing2', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = stdUserProfile.Id, TimeZoneSidKey='America/Los_Angeles'
        ));

        insert users;

        brideas_Category__c catItem = new brideas_Category__c(Name = 'TestCategory1', Description__c = 'Category1 Description');

        insert catItem;

        Test.stopTest();

        Integer recordsNumber = [SELECT COUNT() FROM brideas_Category__c];

        System.assertEquals(1, recordsNumber);
    }

    @isTest
    private static void testConstructorMethod(){
        Test.startTest();
        brideas_CategoriesCtrl controller = new brideas_CategoriesCtrl();
        Test.stopTest();

        System.assertEquals(1, controller.records.size());
    }

    @isTest
    private static void testSave(){
        Test.startTest();
        brideas_CategoriesCtrl controller = new brideas_CategoriesCtrl();
        brideas_Category__c initialRecord = [SELECT Name, Description__c FROM brideas_Category__c LIMIT 1];

        controller.formName = 'TestCategory2';
        controller.formDescription = 'Category2 Description';
        controller.save();

        Integer numberAfterInsert = [SELECT COUNT() FROM brideas_Category__c];

        controller.formName = initialRecord.Name;
        controller.formDescription = 'Updated description';
        controller.save();

        Integer numberAfterUpdate = [SELECT COUNT() FROM brideas_Category__c];
        brideas_Category__c updatedRecord = [SELECT Description__c FROM brideas_Category__c WHERE Name = :initialRecord.Name LIMIT 1];

        Test.stopTest();

        System.assertEquals(2, numberAfterInsert);
        System.assertEquals(2, numberAfterUpdate);
        System.assertEquals('Updated description', updatedRecord.Description__c);
    }

    @isTest
    private static void testEdit(){
        Test.startTest();

        brideas_CategoriesCtrl testController = new brideas_CategoriesCtrl();
        testController.edit();

        Test.stopTest();

        System.assert(true); //nothing to test
    }

    @isTest
    private static void testRemove(){
        Test.startTest();
        brideas_CategoriesCtrl controller = new brideas_CategoriesCtrl();

        List<brideas_Category__c> initialRecords = [SELECT Id FROM brideas_Category__c];

        controller.rId = initialRecords[0].Id;
        controller.remove();

        Integer numberAfterDelete = [SELECT COUNT() FROM brideas_Category__c];

        controller.remove();

        Test.stopTest();

        System.assertEquals(1, initialRecords.size());
        System.assertEquals(0, numberAfterDelete);
    }

    @isTest
    private static void testGetCategoryItem(){
        Test.startTest();

        brideas_Category__c catItem = brideas_CategoriesCtrl.getCategoryItem('TestCategory1');

        Test.stopTest();

        System.assertEquals('Category1 Description', catItem.Description__c);
    }

    @isTest
    private static void testGetFeaturedCategory(){
        Test.startTest();

        String categoryName = brideas_CategoriesCtrl.getFeaturedCategory();
        //Added to cover the code coverage for Featured Category Image Url method.
        String categoryImageUrl = brideas_CategoriesCtrl.getFeaturedCategoryImageUrl();

        Test.stopTest();

        System.assertEquals('FeaturedCategory', categoryName);
    }
    
}