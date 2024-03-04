/**
* @author Nathan Franklin
* @date 2021-01-12
* @group Tests
* @tag Selector
* @tag Pick Up Location
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2021-05-12 - Shashwat.Nath@auspost.com.au - Created
* 2023-10-10 - paul.perry5@auspost.com.au - Added test coverage for selecting related tasks and filtering status pending information options
*/
@IsTest
public with sharing class PickUpLocationSelector_Test{
    /**
     * Test:
     *  Ensures that the selectors QueryBuilder is generating the correct output
     */
    @IsTest
    public static void testEnsureQueryBuilderProducesCorrectString() {

        // =====================================
        // Data Preparation
        // =====================================
        // None!

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        PickUpLocationSelector selector = PickUpLocationSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{PickUpLocationSelector.Options.FILTER_PRIMARY_PICKUP_LOCATION});
        String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Pick_Up_Location__c\\b').matcher(soql).find(), 'Resulting query does not select from Pick Up Location');

		qb = selector.newQueryBuilder(new Set<Object>{
			PickUpLocationSelector.Options.FILTER_STATUS_PENDING_INFORMATION,
			PickUpLocationSelector.Options.WITH_PENDING_TASKS
		});

		soql = qb.toSoqlString();

		System.assertEquals(true, soql.contains('FROM Tasks'), 'Resulting query does not select from Pick Up Location with Tasks');

        Test.stopTest();

    }

    /**
     * Test:
     *  Ensures that the selectors QueryBuilder is generating the correct output
     */
    @IsTest
    public static void testEnsureQueryBuilderProducesCorrectStringWithRelatedFields() {

        // =====================================
        // Data Preparation
        // =====================================
        // None!

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        PickUpLocationSelector selector = PickUpLocationSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{PickUpLocationSelector.Options.FILTER_PRIMARY_PICKUP_LOCATION});
        String soql = qb.toSoqlString();
        System.assertEquals(false, Pattern.compile('(?is)Primary_Pick_Up_Location__c\\..*?\\bfrom Pick_Up_Location__c\\b').matcher(soql).find(), 'Resulting query does not select pick up location');
        Test.stopTest();

    }
    /**
     * Executes a query to ensure it returns expected results with actual inserted data
     */
    @IsTest
    public static void testSelectorIntegration() {

        // =====================================
        // Data Preparation
        // =====================================
        MockUtility.disableTriggerExecution();

        Opportunity opp = new Opportunity(Name = 'Test Optty', StageName = 'Identify', CloseDate = system.today());
        Insert opp;
        Customer_Scoping_Questionnaire__c CSQ = new Customer_Scoping_Questionnaire__c(CSQ_Status__c = 'Approved_by_SM', Opportunity__c = opp.Id);
        Insert CSQ;
        Freight_Offering__c freightOffering = new Freight_Offering__c(Customer_Scoping_Questionnaire__c = CSQ.Id, Cartons__c = true, 
                                                                      B2BCartons__c = 50, B2CCartons__c  = 50, Qty_ConnotesCartons__c = 100, 
                                                                      Qty_Items_cartons__c = 100, B2CBBP__c = 50, B2BBBP__c = 50, 
                                                                      B2BSatchels__c = 50, B2CSatchels__c = 50);
        Insert freightOffering;
        
        Pick_Up_Location__c pickUpLoc = new Pick_Up_Location__c(pick_up_location_status__c = 'Rejected', CSQ__c = CSQ.Id, Location_Type__c='Metro' , Primary_Pick_Up_Location__c = false , State__c='NSW' , Freight_Offering__c = freightOffering.id);
        Insert pickUpLoc; 
            
        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        
        PickUpLocationSelector selector = PickUpLocationSelector.newInstance(1);
        Map<Id, Pick_Up_Location__c > results = selector.selectById(new Set<Id>{pickUpLoc.id});
        System.assertEquals(1, results.size(), 'Result count was wrong');

        results = selector.selectById(new Set<Id>{pickUpLoc.id}, new Set<Object>{PickUpLocationSelector.Options.FILTER_PRIMARY_PICKUP_LOCATION});
        System.assertEquals(1, results.size(), 'Result count was wrong');

        List<Pick_Up_Location__c> resultList = selector.selectByParentId(new Set<Id>{CSQ.Id}, new Set<Object>{PickUpLocationSelector.Options.FILTER_PRIMARY_PICKUP_LOCATION});
        System.assertEquals(1, resultList.size(), 'Result count was wrong');
        Test.stopTest();
    }
    
      /**
     * Test:
     *  Ensures that the selectors QueryBuilder is generating the correct output
     */
    @IsTest
    public static void testEnsureQueryBuilderProducesCorrectStringWithFieldOverrides() {

        // =====================================
        // Data Preparation
        // =====================================
        // None!

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        PickUpLocationSelector selector1 = PickUpLocationSelector.newInstance(0, new Set<SObjectField>{Pick_Up_Location__c.Name});

        PickUpLocationSelector selector = PickUpLocationSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
                Pick_Up_Location__c.SObjectType => new Set<SObjectField>{Pick_Up_Location__c.Name}
        });
        QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{PickUpLocationSelector.Options.FILTER_PRIMARY_PICKUP_LOCATION});
        String soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?ism)Name.*?\\bfrom Pick_Up_Location__c\\b').matcher(soql).find(), 'Resulting query does not select Name field: ' + soql);

        Test.stopTest();

    }
}