@isTest
public with sharing class BAMValidationService_Test {
    private static String LEGACY_ID = '1111';
    private static String TEST_CNUMBER = 'C1234';
    private static String DUMMY_CNUMBER = 'C-DUMMY';


    @isTest
    static void test_checkIfDuplicateContactExistsInOrg() {
        Account org = BAMTestUtility.createTestAccount(LEGACY_ID);
        insert org;
        Contact con = BAMTestUtility.createTestContact(org.Id, TEST_CNUMBER);
        insert con;
        Contact duplicateCon = BAMTestUtility.createTestContact(org.Id, TEST_CNUMBER);
        Boolean isDuplicate = BAMValidationService.checkIfDuplicateContactExistsInOrg(org.Id, duplicateCon.FirstName, duplicateCon.LastName, duplicateCon.Email, duplicateCon.Id);
        System.assert(isDuplicate);
    }

    @isTest
    static void test_checkIfDulicateCnumberExistsInOrg_noDublicate() {
        Account org = BAMTestUtility.createTestAccount(LEGACY_ID);
        insert org;
        Contact con = BAMTestUtility.createTestContact(org.Id, TEST_CNUMBER);
        insert con;

        Test.startTest();
        Boolean result = BAMValidationService.checkIfDulicateCnumberExistsInOrg(org.Id, con.Email);
        system.assert(!result);
        Test.stopTest();
    }
}