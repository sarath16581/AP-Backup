/**
  * @author       : deepak.kemidi@auspost.com.au
  * @date         : 31/03/2024
  * @description  : Test Class for VendorEmailUtils class
  */
@isTest
private class VendorEmailUtilsTest {

    @isTest
    static void testGetEmailAddress() {
        Test.loadData(Auspost_Vendors_Email_Address__mdt.SObjectType, 'testData');
        Test.startTest();
        List<String> result = VendorEmailUtils.getEmailAddress();
        Test.stopTest();
        System.assertEquals('test1@example.com,test2@example.com', result[0], 'Incorrect email addresses returned');
    }

    @isTest
    static void testGetEmailAddress_NoRecords() {
        Test.startTest();
        List<String> result = VendorEmailUtils.getEmailAddress();
        Test.stopTest();
        System.assertEquals(0, result.size(), 'Expected empty list when there are no custom metadata records');
    }

    @isTest
    static void testGetEmailAddress_NullEmail() {
        Test.loadData(Auspost_Vendors_Email_Address__mdt.SObjectType, 'testData_NullEmail');
        Test.startTest();
        List<String> result = VendorEmailUtils.getEmailAddress();
        Test.stopTest();
        System.assertEquals(0, result.size(), 'Expected empty list when all email addresses are null');
    }
}