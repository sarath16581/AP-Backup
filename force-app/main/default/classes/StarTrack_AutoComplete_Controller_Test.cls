/**************************************************
Type:       StarTrack AutoComplete Controller Test Class
History:
--------------------------------------------------
Aug-2015:  Fahad.Akhtar@cloudsherpas.com  Created
May-2018: Hasantha.Liyanage@auspost.com.au updated commented the unit tests as it was failing and will be re-written with scenario based tests.

**************************************************/
@isTest
private class StarTrack_AutoComplete_Controller_Test {

    @testSetup
    static void setupTestData() {
        //prepare multiple accounts with deferent names to support the filtering/SOQL search methods
        List<Account> accountList = new List<Account>();
        for(Integer i =0 ; i < 200 ; i++){
            //names inserted for LIKE % search
            accountList.add(new Account(Name='Test'+i));
        }
        //insert test records
        insert accountList;

    }

    /**
     * SCENARIO;
     *      Expecting successful scenario of returning all the records when search with name LIKE %T
     **/
    @isTest
    static void StarTrack_AutoComplete_getData_returnAllRecords() {
        String searchedTextResult = '';
        Test.startTest();
        //Search accounts [LIKE %T%]
        searchedTextResult = StarTrack_AutoComplete_Controller.getData('Account','Id','Name','T');
        Test.stopTest();

        // convert to AutoCompleteData
        List<StarTrack_AutoComplete_Controller.AutoCompleteData> jsonStringlist = (List<StarTrack_AutoComplete_Controller.AutoCompleteData>)System.JSON.deserialize(searchedTextResult, List<StarTrack_AutoComplete_Controller.AutoCompleteData>.class);

        // expecting all 200 records returned
        System.assertEquals(
                200,
                jsonStringlist.size(),
                'StarTrack_AutoComplete_getData_returnAllRecords : Searched records should return all the 200 records created'
        );
    }

    /**
     * SCENARIO;
     *      Expecting return of a specific searched record : name == Test100
     **/
    @isTest
    static void StarTrack_AutoComplete_getData_returnSearchedRecord() {
        String searchedTextResult = '';
        Test.startTest();
        //Search accounts [LIKE %Test100%]
        searchedTextResult = StarTrack_AutoComplete_Controller.getData('Account','Id','Name','Test100');
        Test.stopTest();

        // convert to AutoCompleteData
        List<StarTrack_AutoComplete_Controller.AutoCompleteData> jsonStringlist = (List<StarTrack_AutoComplete_Controller.AutoCompleteData>)System.JSON.deserialize(searchedTextResult, List<StarTrack_AutoComplete_Controller.AutoCompleteData>.class);

        //only one record should be returned
        System.assertEquals(
                1,
                jsonStringlist.size(),
                'StarTrack_AutoComplete_getData_returnSearchedRecord : Searched records should return only one record'
        );

        //only one record should be returned, and the name of the searched record result should be Test100
        System.assertEquals(
                'Test100',
                jsonStringlist.get(0).Id,
                'StarTrack_AutoComplete_getData_returnSearchedRecord : Searched records should return only one record with value Test100'
        );
    }

    /**
     * SCENARIO;
     *      Returning no records when the searched text is not available
     **/
    @isTest
    static void StarTrack_AutoComplete_getData_returnEmptyRecords() {
        String searchedTextResult = '';
        Test.startTest();
        //Search accounts [LIKE %xxxxxxx%]
        searchedTextResult = StarTrack_AutoComplete_Controller.getData('Account','Id','Name','xxxxxxx');
        Test.stopTest();

        // convert to AutoCompleteData
        List<StarTrack_AutoComplete_Controller.AutoCompleteData> jsonStringlist = (List<StarTrack_AutoComplete_Controller.AutoCompleteData>)System.JSON.deserialize(searchedTextResult, List<StarTrack_AutoComplete_Controller.AutoCompleteData>.class);

        // no records expected
        System.assertEquals(
                0,
                jsonStringlist.size(),
                'StarTrack_AutoComplete_getData_returnEmptyRecords : Search result should retrun 0 records'
        );
    }

    /**
     * This unit test is to cover the not-used mehods in StarTrack_AutoComplete_Controller,
     * need to re-visit the StarTrack_AutoComplete_Controller class and refactor
     **/
    @isTest
    static void StarTrack_AutoComplete_Controller_Test_004() {
        List<Account> accountList = [SELECT Id, Name FROM Account];
        Test.startTest();
        StarTrack_AutoComplete_Controller controller = new StarTrack_AutoComplete_Controller ();
        controller.setTargetFieldVar(accountList[0].Id);
        System.assertEquals(accountList[0].Id,controller.getTargetFieldVar());
        controller.setCacheField(null);
        Test.stopTest();
    }


}