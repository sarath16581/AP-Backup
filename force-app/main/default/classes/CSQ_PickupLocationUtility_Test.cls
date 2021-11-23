/*
 * @date 2021-04-10
 * @group Pick_Up Location
 * @tag Pick_Up Location
 * @domain Core
 * @description Apex Test class for CSQ_PickupLocationUtility Class.
 * @changelog
 * 2021-04-10 - Dheeraj.Mandavilli@auspost.com.au - Created
 * 2021-06-22 - Dheeraj.Mandavilli@auspost.com.au - Added a new method to test create pick up location.
 */
@IsTest
public with sharing class CSQ_PickupLocationUtility_Test {
    
    @IsTest
	private static void getOppIdTest() {
        
        Opportunity opp = new Opportunity(Name = 'Test Optty', StageName = 'Identify', CloseDate = system.today());
        Insert opp;
        Customer_Scoping_Questionnaire__c CSQ = new Customer_Scoping_Questionnaire__c(CSQ_Status__c = 'Approved_by_SM', Opportunity__c = opp.Id);
        Insert CSQ;
        Freight_Offering__c freightOffering = new Freight_Offering__c(Customer_Scoping_Questionnaire__c = CSQ.Id, Cartons__c = true, 
                                                                      B2BCartons__c = 50, B2CCartons__c  = 50, Qty_ConnotesCartons__c = 100, 
                                                                      Qty_Items_cartons__c = 100, B2CBBP__c = 50, B2BBBP__c = 50, 
                                                                      B2BSatchels__c = 50, B2CSatchels__c = 50);
        Insert freightOffering;
        
        Pick_Up_Location__c pickUpLoc = new Pick_Up_Location__c(pick_up_location_status__c = 'Rejected', CSQ__c = CSQ.Id, Freight_Offering__c = freightOffering.id,State__c='NSW',Location_Type__c='Metro');
        Insert pickUpLoc;

        Test.startTest(); 
        Id oppId  = CSQ_PickupLocationUtility.getOppId(pickUpLoc.Id);
        System.assertNotEquals(oppId, null);
        Test.stopTest();
    }
    
    @IsTest
	private static void getPrimaryPickupLocationDetailsTest() {
        
        Opportunity opp = new Opportunity(Name = 'Test Optty', StageName = 'Identify', CloseDate = system.today());
        Insert opp;
        Customer_Scoping_Questionnaire__c CSQ = new Customer_Scoping_Questionnaire__c(CSQ_Status__c = 'Approved_by_SM', Opportunity__c = opp.Id);
        Insert CSQ;
        Freight_Offering__c freightOffering = new Freight_Offering__c(Customer_Scoping_Questionnaire__c = CSQ.Id, Cartons__c = true, 
                                                                      B2BCartons__c = 50, B2CCartons__c  = 50, Qty_ConnotesCartons__c = 100, 
                                                                      Qty_Items_cartons__c = 100, B2CBBP__c = 50, B2BBBP__c = 50, 
                                                                      B2BSatchels__c = 50, B2CSatchels__c = 50);
        Insert freightOffering;
        
        Pick_Up_Location__c pickUpLoc = new Pick_Up_Location__c(pick_up_location_status__c = 'Rejected', CSQ__c = CSQ.Id, Freight_Offering__c = freightOffering.id, Primary_Pick_Up_Location__c = True,State__c='NSW',Location_Type__c='Metro');
        Insert pickUpLoc;
        
        Test.startTest(); 
        boolean primLocFound  = CSQ_PickupLocationUtility.getPrimaryPickupLocationDetails(opp.Id);
        System.assertNotEquals(primLocFound, false);
        Test.stopTest();
    }
    
   @IsTest
	private static void updatePickupLocationTest() {
        
        Opportunity opp = new Opportunity(Name = 'Test Optty', StageName = 'Identify', CloseDate = system.today(), Primary_Pick_Up_Location__c='');
        Insert opp;
        Customer_Scoping_Questionnaire__c CSQ = new Customer_Scoping_Questionnaire__c(CSQ_Status__c = 'Approved_by_SM', Opportunity__c = opp.Id);
        Insert CSQ;
        Freight_Offering__c freightOffering = new Freight_Offering__c(Customer_Scoping_Questionnaire__c = CSQ.Id, Cartons__c = true, 
                                                                      B2BCartons__c = 50, B2CCartons__c  = 50, Qty_ConnotesCartons__c = 100, 
                                                                      Qty_Items_cartons__c = 100, B2CBBP__c = 50, B2BBBP__c = 50, 
                                                                      B2BSatchels__c = 50, B2CSatchels__c = 50);
        Insert freightOffering;
        
        Pick_Up_Location__c pickUpLoc = new Pick_Up_Location__c(pick_up_location_status__c = 'Rejected', CSQ__c = CSQ.Id, Freight_Offering__c = freightOffering.id, Primary_Pick_Up_Location__c = false,State__c='NSW',Location_Type__c='Metro');
        Insert pickUpLoc;
        
        Test.startTest(); 
        boolean primLocUpdate  = CSQ_PickupLocationUtility.updatePickupLocation(pickUpLoc.Id,opp.Id);
        System.assertNotEquals(primLocUpdate, false);
        Test.stopTest();
    }

    @IsTest
	private static void createPickupLocationTest() {
        
        Opportunity opp = new Opportunity(Name = 'Test Optty', StageName = 'Identify', CloseDate = system.today(), Primary_Pick_Up_Location__c='');
        Insert opp;
        Customer_Scoping_Questionnaire__c CSQ = new Customer_Scoping_Questionnaire__c(CSQ_Status__c = 'Approved_by_SM', Opportunity__c = opp.Id);
        Insert CSQ;
        Freight_Offering__c freightOffering = new Freight_Offering__c(Customer_Scoping_Questionnaire__c = CSQ.Id, Cartons__c = true, 
                                                                      B2BCartons__c = 50, B2CCartons__c  = 50, Qty_ConnotesCartons__c = 100, 
                                                                      Qty_Items_cartons__c = 100, B2CBBP__c = 50, B2BBBP__c = 50, 
                                                                      B2BSatchels__c = 50, B2CSatchels__c = 50);
        Insert freightOffering;
        
        Pick_Up_Location__c pickUpLoc = new Pick_Up_Location__c(pick_up_location_status__c = 'Rejected', CSQ__c = CSQ.Id, Freight_Offering__c = freightOffering.id, Primary_Pick_Up_Location__c = false,State__c='NSW',Location_Type__c='Metro');
        
        Test.startTest(); 
        Id pickupLocId  = CSQ_PickupLocationUtility.createPickupLocation(pickUpLoc);
        System.assertNotEquals(pickupLocId, null);
        Test.stopTest();
    }
}