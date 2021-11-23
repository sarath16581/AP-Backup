/**************************************************
Description:    Test Class  for the InviteContactToBSPController
History:
--------------------------------------------------
2019-10-01  shashwat.a.nath@accenture.com  Created
**************************************************/

@isTest
public with sharing class InviteContactToBSPControllerTest {

    public static testmethod void fetchCurrentUserDetailsTest() {
        //Setting up Test Data
        Contact contactRecord = APT_TestUtils.createContact();
        insert contactRecord;

    //Start of the test
    Test.StartTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(contactRecord);
        InviteContactToBSPController cont = new InviteContactToBSPController(sc);
        InviteContactToBSPController.fetchCurrentUserDetails(UserInfo.getUserId());
    Test.StopTest();


    }

}