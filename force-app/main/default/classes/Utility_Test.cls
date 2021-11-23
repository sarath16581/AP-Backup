/**
  * @author       : nathan.franklin@auspost.com.au
  * @description  : Test Class for Utility... Basic class to ensure Utility is covered for deployment
  */
/*******************************  History ************************************************
2019-01-21 nathan.franklin@auspost.com.au Created, a little bit dodgy
2020-01-10 vcheng@salesforce.com Added coverage for ABN Validation method
*******************************  History ************************************************/
@isTest (IsParallel=true)
public with sharing class Utility_Test {

    /************************
     * Scenario:
     *
     * Testing all Record type related functions in Utility
     *************************/
    public static testMethod void testRecordTypeMethods() {

        Map<Id, RecordType> recordTypes = Utility.getRecordTypesAsSObject('Case');
        System.Debug(recordTypes);
        System.assertEquals(false, recordTypes.isEmpty());

        Map<Id, RecordType> recordTypeDevNames = Utility.getRecordTypesAsSObjectByDevName('Case', new Set<String>{'SSSWGeneralEnquiry'});
        System.assertEquals(false, recordTypeDevNames.isEmpty());

        Map<Id,String> recordTypeNamesById = Utility.getsObjectRecordTypeNames('Case');
        System.assertEquals(false, recordTypeNamesById.isEmpty());

        Map<String,Id> recordTypeNamesByName = Utility.getsObjectRecordTypes('Case');
        System.assertEquals(false, recordTypeNamesByName.isEmpty());

        Set<Id> recordTypeIds = Utility.getRecordTypeIds('Case', 'SSSW');
        System.assertEquals(false, recordTypeIds.isEmpty());
        
        Id recordTypeIdsDevName = (Id) Utility.getRecordTypesAsIdByDevName('Case', 'SSSWGeneralEnquiry');
        System.assertEquals(false, String.IsBlank(recordTypeIdsDevName));

        // of course!
        System.assertEquals(true, Utility.isValidRecordType(recordTypeIds, new List<Id>(recordTypeIds)[0]));

    }

    /************************
     * Scenario:
     *
     * Testing all Group related functions in Utility
     *************************/
    public static testMethod void testGroupMethods() {

        Map<Id,Group> groups = Utility.getGroups('QUEUE');
        System.assertEquals(false, groups.isEmpty());

        List<Group> listGroups = groups.values();
        Id groupId = Utility.getGroupId(listGroups[0].DeveloperName, 'QUEUE');
        System.assertNotEquals(null, groupId);

        Map<Id,Group> groupDetails = Utility.getGroupDetails(groups.keySet(), 'QUEUE');
        System.assertEquals(false, groupDetails.isEmpty());

    }

    /************************
     * Scenario:
     *
     * Testing all Business Hours related functions in Utility
     *************************/
    public static testMethod void testBusinessHours() {
        Account at = new Account(Name=SSSWConstants.ENTITLEMENT_ACC);
        insert at;

        Entitlement ent = new Entitlement(AccountId = at.Id, Name='Standard Entitlement');
        insert ent;

        Id id = Utility.getStandardEntitlement();
        System.assertNotEquals(null, id);

        Map<String,Id> businessHours = Utility.getBussinessHourMap();
        System.assertEquals(false, businessHours.isEmpty());

        // in order for this to pass, business hours need to exist in the same timezone as the user's timezone that is running the test
        Id currentUserBusinessHours = Utility.getCurrentUserBussinessHour();

        // default business hours
        Id defaultBusinessHours = Utility.getDefaultBussinessHour();
    }

    /************************
     * Scenario:
     *
     * Testing all Case related functions in Utility
     *************************/
    public static testMethod void testCaseRelated() {

        Set<String> closedStatuses = Utility.getCaseClosedStatus();
        System.assertEquals(false, closedStatuses.isEmpty());

        Id caseTeamRoleId = Utility.getCaseTeamRole('Case Viewer');
        System.assertNotEquals(null, caseTeamRoleId);

    }

    /************************
     * Scenario:
     *
     * Testing all Generic functions in Utility
     *************************/
    public static testMethod void testGeneric() {

        Map<Id, User> users = Utility.getUsers(new Set<Id>{UserInfo.getUserId()});
        System.assertEquals(false, users.isEmpty());

        String strEntire = 'xxx11111yyy';
        String strStart ='xxx';
        String strEnd ='yyy';
        String strCapture = Utility.parsetext('xxx11111yyy','xxx', 'yyy');

    }
    
     /* @author: rajesh.punjabi@mav3rik.com
     * @description: This method is specific to Live Chat and Feeditem. 
     * @description: Live Chat body content contains html tag which are not supported by Feeditem.
*/
    @IsTest
    public static void convertTextoRichText(){
        String sText = 'This is test String with unsupported Tags <p align="center"> and BR Tag <br>';
        
        Test.startTest();
        sText = Utility.convertTextoRichText(sText);
        Test.stopTest();
        System.assert(!sText.contains('<p align="center">'));
    }

  /*  @IsTest
    public static void getProfileIds(){
        Test.startTest();
        Set<Id> setProfileIds = Utility.getProfileIds('DDC Consumer Community User,BSP Community User');
        Test.stopTest();
    }*/

    TestMethod
    public static void testABNFormat()
    {
        Test.startTest();

        Boolean notNumeric = Utility.isValidAbnFormat('abcdef');
        System.assertEquals(false, notNumeric, 'Expected to fail for non-numeric ABN String');
        Boolean invalid11Digit = Utility.isValidAbnFormat('12345678901');
        System.assertEquals(false, invalid11Digit, 'Expected to fail for bad 11 digit ABN String');
        Boolean tooShort = Utility.isValidAbnFormat('5182475355');
        System.assertEquals(false, tooShort, 'Expected to fail for less than 11 digits');

        Boolean tooLong = Utility.isValidAbnFormat('518247535560');
        System.assertEquals(false, tooLong, 'Expected to fail for more than 11 digits');
        Boolean validAbn = Utility.isValidAbnFormat('51824753556');
        System.assertEquals(true, validAbn, 'Valid ABN, should succeed');

        Test.stopTest();
    }

}