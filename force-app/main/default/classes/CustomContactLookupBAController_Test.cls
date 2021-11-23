/*************************************************************************************
Description: Test class to cover CustomContactLookupBAController functionality.
History:
--------------------------------------------------------------------------------------
            No Created History found.
2018-06-26  TDO-76 : rahul.kapoor@coroma.com.au Refactored comments and indentation,
            added assertEquals and assertNotEquals, added create test data method and
            new tests to perform search with/Without search string.
**************************************************************************************/
@isTest
private class CustomContactLookupBAController_Test {

    /*********************************************************************************
    *  Scenario:
    *      Setup method to create test data.
    **********************************************************************************/
    @testSetup
    static void createTestData(){
        //Create a Contact.
        Contact testContact = new Contact(FirstName = 'John',
                                          LastName = 'Doer',
                                          Phone = '4444',
                                          MobilePhone = '3333',
                                          MailingStreet='test address');
        insert testContact;
    }

    /***********************************************************************************
    *  Scenario:
    *      Test to prepare the query and issue of the search command with search string.
    ************************************************************************************/
    static testMethod void testPerformSearchWithSearchString() {
        //Fetch Contact
        Contact testContact = [SELECT Id,FirstName,LastName,Phone
                               FROM Contact
                               LIMIT 1];

        //Required so SOSL will fire in Unit Tests Properly.
        Id [] fixedSearchResults= new Id[1];
        fixedSearchResults[0] = testContact.Id;
        Test.setFixedSearchResults(fixedSearchResults);

        CustomContactLookupBAController lookup = new CustomContactLookupBAController();

        //Call getFormTag and getTextBox for code test coverage.
        lookup.getFormTag();
        lookup.getTextBox();

        Test.startTest();

        lookup.searchString = '4444';
        PageReference pr = lookup.search();

        Test.stopTest();

        //Fetch Contact
        Contact fetchContact = [SELECT Id,FirstName,LastName,Phone
                                FROM Contact
                                LIMIT 1];

        System.assertNotEquals(null, lookup.contact_results,
                'CustomContactLookupBAController_Test_testPerformSearchWithSearchString : Contact Results should be retrieved.');

        System.assertEquals(testContact.Id, fetchContact.Id,
                'CustomContactLookupBAController_Test_testPerformSearchWithSearchString : Contact should be retrieved.');

    }

    /**************************************************************************************
    *  Scenario:
    *      Test to prepare the query and issue of the search command without search string.
    ***************************************************************************************/
    static testMethod void testPerformSearchWithoutSearchString() {
        CustomContactLookupBAController lookup = new CustomContactLookupBAController();

        Test.startTest();

        lookup.searchString = '';
        PageReference pr = lookup.search();

        Test.stopTest();

        //Create Contact list
        list<Contact> contactList = new list<Contact>();

        System.assertEquals(contactList, lookup.contact_results,
                'CustomContactLookupBAController_Test_testPerformSearchWithoutSearchString : Contact Results should not be retrieved.');

    }

    /***********************************************************************************
    *  Scenario:
    *      Test to cover code coverage for strays by setting service cloud console param.
    ************************************************************************************/
    static testMethod void testCheckForStrays() {
        CustomContactLookupBAController lookup = new CustomContactLookupBAController();
        lookup.inServiceCloudConsole = 'false';
        lookup.checkForStrays();
    }

    /*********************************************************************************
    *  Scenario:
    *      Test to set the Workspace Connector Info successfully.
    **********************************************************************************/
    static testMethod void testSetWorkspaceConnectorInfo(){
        String result = CustomContactLookupBAController.setWorkspaceConnectorInfo('123','456');

        System.assertEquals('success', result,
                'CustomContactLookupBAController_Test_testSetWorkspaceConnectorInfo : Success should be retrieved.');
    }

}