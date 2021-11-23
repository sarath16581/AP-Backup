/* @author 
 * @date 2021-03-15
 * @group Tests
 * @tag Selector
 * @tag Deal_Support_Request__c, Network__c
 * @domain Core
 * @description test class for addMultipleLodgementPointController
 * @changelog
 * 2021-03-15 - seth.heang@austpost.com.au - Created
 * 2021-07-20 - seth.heang@auspost.com.au - Update selector class due to main class SOQL query change
 */
@isTest
public class addMultipleLodgementPointControllerTest {

    /*
     * This test class is specifically for covering the code in the 'After Update' trigger for Deal Support Request Object
	*/
    private static TestMethod void manageAddLodgementPointComponentTest(){
        
        // Setup Account & Contact information
        Account account = ApplicationTestDataFactory.getAccounts(1, true)[0];
        Contact primaryContact = ApplicationTestDataFactory.getContacts(1, account.Id, true)[0];

        // Setup the custom setting for th Org Unit Type Code filter on the Network Search
        DSR_Settings__c orgUnitTypeFilter = new DSR_Settings__c();
        orgUnitTypeFilter.Name = 'Test Org Unit Type Code Filter';
        orgUnitTypeFilter.Lodgement_Point_Org_Unit_Type_Filter__c = 'LPO';
        insert orgUnitTypeFilter;
        
        // setting up test data for DSR
        List<Network__c> twoNetworks = ApplicationTestDataFactory.getLPONetwork(2, true);
        twoNetworks[0].Name = 'Melbourne';
        twoNetworks[0].Org_ID__c = '123456';
        twoNetworks[0].Org_Unit_Type__c = 'LPO';
        twoNetworks[0].State__c = 'VIC';

        twoNetworks[1].Name = 'Sydney';    
        twoNetworks[1].Org_ID__c = '333333';
        twoNetworks[1].Org_Unit_Type__c = 'LPO';
        twoNetworks[1].State__c = 'NSW';

        // Setup DSR information
        Deal_Support_Request__c dealSupportRequest = ApplicationTestDataFactory.getDealSupportRequests(1, null, null, true)[0];
        dealSupportRequest.recordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('Deal_Support_Request__c', new Set<String>{'Credit_Management_Request'}).values()[0].Id;
        dealSupportRequest.Stage__c = 'New';
        dealSupportRequest.Status__c = 'Draft';
        dealSupportRequest.Lodgement_Point_to_Work_Centre_Code__c = 'Melbourne:123456\nSydney:333333';
        // Set up Worktype information and its associated field
        dealSupportRequest.Credit_Work_Type__c = 'Add lodgement point';
        dealSupportRequest.Customer_Request_Attached__c = 'Yes';
        dealSupportRequest.CustomerContact1__c = primaryContact.Id;
		dealSupportRequest.Credit_Person_Code__c = '3W';

        // =====================================
		// Stubbing
		// =====================================

        DealSupportRequestsSelector dsrSelector = (DealSupportRequestsSelector)MockUtility.mockSelector(DealSupportRequestsSelector.class);   
        NetworksSelector networkSelector = (NetworksSelector)MockUtility.mockSelector(NetworksSelector.class); 
        ApplicationDatabase mockDatabase = MockUtility.mockDatabase();


        // set up our responses
		MockUtility.Mocks.startStubbing();
        
        // DSR response selected by ID
        Map<Id, Deal_Support_Request__c> mockDsrMap = new Map<Id, Deal_Support_Request__c>{dealSupportRequest.Id => dealSupportRequest};
        //mockDsrMap.put(dealSupportRequest.Id, dealSupportRequest);
        MockUtility.Mocks.when(dsrSelector.selectById(mockDsrMap.keyset())).thenReturn(mockDsrMap);

        // Network response
        Map<Id, Network__c> mockNetworkMap = new Map<Id, Network__c>{twoNetworks[0].Id => twoNetworks[0]};
        mockNetworkMap.put(twoNetworks[1].Id, twoNetworks[1]);
        MockUtility.Mocks.when(networkSelector.selectByNameAndOrgId((Set<String>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject())).thenReturn(mockNetworkMap);
        MockUtility.Mocks.when(networkSelector.selectByNetworkNameANDOrgIdANDNotID_OR_ENDWITH_SUBSTRING_OR_WORKCENTRE(
            (String)fflib_Match.anyObject(), 
            (Set<String>)fflib_Match.anyObject(), 
            (Set<String>)fflib_Match.anyObject(), 
            (String)fflib_Match.anyObject())).thenReturn(mockNetworkMap);

        // mock database, set response for DML update
        MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject(),(Boolean)fflib_Match.anyBoolean())).thenReturn(true);
        MockUtility.Mocks.stopStubbing();

        Test.startTest();
        // initialise wrapper object for network search
        addMultipleLodgementPointController.SObJectResult networkObj = new addMultipleLodgementPointController.SObJectResult(
            mockNetworkMap.values()[0].Name,
            mockNetworkMap.values()[0].Org_Id__c,
            mockNetworkMap.values()[0].Network_Address__c,
            mockNetworkMap.values()[0].Id
        );
        // serialise the wrapper object into JSON format, to mock the JSON send from LWC Javascript to apex controller
        List<addMultipleLodgementPointController.SObJectResult> networkObjList = new List<addMultipleLodgementPointController.SObJectResult>();
        networkObjList.add(networkObj);
        String networkJSONString = JSON.serialize(networkObjList);

        // Test the loading functionality from DSR's lodgement point to work centre code mapping and conversion to list of wrapper object records(to be used in LWC component)
        List<addMultipleLodgementPointController.SObjectResult> networkLoaded = new List<addMultipleLodgementPointController.SObjectResult>();
        networkLoaded = addMultipleLodgementPointController.onLoadLPdata(mockDsrMap.values()[0].Id);

        // Test the search functionality of lodgement point, search 'Melb'
        List<addMultipleLodgementPointController.SObjectResult> networkSearch = new List<addMultipleLodgementPointController.SObjectResult>();
        networkSearch = addMultipleLodgementPointController.getResults('Melb', new List<String>{''});

        // Test the Adding functionality of lodgement point, passed in the DSR ID & JSON string of object list
        addMultipleLodgementPointController.addMultiLodgementPointsWCC(mockDsrMap.values()[0].Id, networkJSONString);

        // Get Icon String from Account and Network Salesforce Tab for testing
        String getNetworkIcon = addMultipleLodgementPointController.getIconName('Network__c');
        String getAccountIcon = addMultipleLodgementPointController.getIconName('Account');
        // check if Account Icon returns 'standard:account' string which is out-of-box and static value
        Boolean isAccountIcon = getAccountIcon.contains('standard:account');
        // as Network Icon is custom and thus could be changed, we can only safely check that it's custom
        Boolean isCustomIcon = getNetworkIcon.contains('custom');

        Test.stopTest();
        // Verify that 'Melbourne:123456' was converted to wrapper object record
        System.assertEquals(mockNetworkMap.values()[0].Name, networkLoaded[0].recName, 'Expected Melbourne in the lodgement point loaded');
        System.assertEquals(mockNetworkMap.values()[0].Org_ID__c, networkLoaded[0].recWCC, 'Expected 123456 in the work centre code loaded');

        // Verify that 'Sydney:333333' was converted to wrapper object record
        System.assertEquals(mockNetworkMap.values()[1].Name, networkLoaded[1].recName, 'Expected Sydney in the lodgement point loaded');
        System.assertEquals(mockNetworkMap.values()[1].Org_ID__c, networkLoaded[1].recWCC, 'Expected 333333 in the work centre code loaded');
        
        // Verify that 'Melbourne' is in the search result
        System.assertEquals(mockNetworkMap.values()[0].Name, networkSearch[0].recName, 'Expected Melbourne in the search result');
        
        // Verify Account & Custom Icon
        System.assertEquals(true, isAccountIcon, 'Expected Account Icon');
        System.assertEquals(true, isCustomIcon, 'Expected Custom Icon');
        // Check if the DSR record has been updated once
        ((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, MockUtility.Mocks.times(1))).dmlUpdate((List<SObject>)fflib_Match.anyObject());
    }
}