/*
* Created by: Apttus Managed Services
* Created Date: 20/04/2017
* Author: Ravi Chhatrala
* Apttus Case #: 00210442
* Last Modified by: Ravi Chhatrala
* Last Modified Date: 24/04/2017
*/
@isTest
private class APTMS_OpportunityHandlerTest {
    
    private static Apttus_Proposal__Proposal__c Proposal;
    private static Apttus_Proposal__Proposal__c existingProposal;
    private static Apttus_Config2__ProductConfiguration__c prodconfig;
    private static Apttus_Config2__ProductConfiguration__c prodconfig1;
    private static Apttus_Config2__LineItem__c bundleLine;
    private static Apttus_Config2__LineItem__c bundleLine1;
    private static Apttus_Config2__LineItem__c bundleLine2;
    private static Opportunity existingOpty;
    private static APT_Opportunity_Product_Line_Item__c testOppProLineItem;
    private static Account acc;
    private static Apttus_Config2__PriceList__c priceList;
    private static Product2 bundle1;
    private static Product2 bundle2;
    private static Apttus_Config2__PriceListItem__c pli;
    public static final String NEW_CUSTOMER_MAP_KEY = 'New Customer';
    public static final String EXISTING_CUSTOMER_MAP_KEY = 'Existing Customer';
    
    //Create Test Data
    private static void createTestData() {
        
        //Create Account
        acc = APT_TestUtils.createOrganisation();
        insert acc;

        //Create Opportunity
        Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
        opty.type = APT_Constants.OPPORTUNITY_TYPE_NEW_CUSTOMER;
        insert opty;

        //Create PriceList
        priceList = APT_TestUtils.createPriceList();
        insert priceList;

        //Create Proposal
        List<Apttus_Proposal__Proposal__c> lstPro = new List<Apttus_Proposal__Proposal__c>();
        Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
        Proposal.APT_Selected_LP__c = 'Selected Proposal';
        Proposal.RecordTypeID = [SELECT id from RecordType where Name =: APT_Constants.RECORD_TYPE_RENEWAL_QUOTE].Id;
        lstPro.add(Proposal);
        
        insert lstPro;
        
        //create international product
        bundle1 = APT_TestUtils.createInternationalProduct(APT_Constants.PRODUCT_NAME_EPARCEL,'APOST001','Postal Services');
        bundle1.Non_contracted__c = false;
        insert bundle1;

        bundle2 = APT_TestUtils.createInternationalProduct(APT_Constants.PRODUCT_NAME_EPARCEL,'APOST002','Postal Services');
        bundle2.APT_Sync_with_Opportunity__c = true;
        bundle2.Apttus_Config2__HasOptions__c = true;
        bundle2.Non_contracted__c = true;
        bundle2.Apttus_Config2__ConfigurationType__c = APT_Constants.LABEL_LINE_TYPE_BUNDLE;
        insert bundle2;

        Product2 option1 = APT_TestUtils.createInternationalProduct(APT_Constants.PRODUCT_NAME_EPARCEL,'APOST003','Postal Services');
        option1.APT_Sync_with_Opportunity__c = true;
        option1.Apttus_Config2__ConfigurationType__c = APT_Constants.LABEL_LINE_TYPE_OPTION;
        insert option1;
        
        //Create Product Configuration             
        prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
        proposal.Id, 'Proposal','Ad Hoc',priceList.Id, null,'Ready For Finalization',null, Datetime.now(), true);
        insert prodconfig;
        
        //Create Price list Item
        pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
        insert pli;
        
        /*Apttus_Config2__PriceListItem__c pli1= APT_TestUtils.createPriceListItem(priceList.ID,bundle2.ID,'C Manufacturing','BAND 2');
        insert pli1;*/
        
        Apttus_Config2__PriceListItem__c pli2= APT_TestUtils.createPriceListItem(priceList.ID,option1.ID,'C Manufacturing','BAND 2');
        insert pli2;

        Map<String, String> mapOPLRecTypeNameTest = new Map<String, String>();
        //Get all active record types of OPL object
        for(RecordType rc : [
                                SELECT Id, Name, DeveloperName, IsActive, SobjectType 
                                FROM RecordType 
                                WHERE SobjectType =: APT_Constants.SOBJECT_OPPORTUNITY_PRODUCT_LINE_ITEM AND IsActive=TRUE
                            ]){
            
            if(rc.DeveloperName == APT_Constants.OPPORTUNITY_RECORD_TYPE_NEW_OPPORTUNITY_TYPE){
                mapOPLRecTypeNameTest.put(NEW_CUSTOMER_MAP_KEY, rc.Id);
            } else if(rc.DeveloperName == APT_Constants.OPPORTUNITY_RECORD_TYPE_EXISTING_OPPORTUNITY_TYPE){
                mapOPLRecTypeNameTest.put(EXISTING_CUSTOMER_MAP_KEY, rc.Id);
            }
        }
        
        test.startTest();
        //Create Opportunity Product Line Item
        List<APT_Opportunity_Product_Line_Item__c> lstOLI = new List<APT_Opportunity_Product_Line_Item__c>();
        for(integer i=0; i<=3 ; i++){
           APT_Opportunity_Product_Line_Item__c OppProLineItem = APT_TestUtils.createOpProdLI(APT_Constants.OPPORTUNITY_TYPE_NEW_BUSINESS,'Yes',bundle1.id,prodconfig.id,1,Proposal.id, 1, Date.Today(),Date.Today() + 100);
           OppProLineItem.APT_Sub_Classification__c = 'Contracted Price Increases';
           OppProLineItem.RecordTypeId = mapOPLRecTypeNameTest.get(NEW_CUSTOMER_MAP_KEY);
           OppProLineItem.APT_TotalPrice__c = 10;  
           lstOLI.add(OppProLineItem);
        }
        
        System.debug('--> lstOLI--> '+lstOLI);
        insert lstOLI;
        
        System.debug('lstOLI Inserted ' + lstOLI);
        
        APTMS_AvoidRecursion.firstRun = true;
        
        //Update Opportunity Type to test the Opportunity Trigger
        opty.Type = APT_Constants.OPPORTUNITY_TYPE_EXISTING_CUSTOMER;
        update opty;
        
        System.debug('Oppo Updated to Existing');
        
        /*
        * Check Record Type of OPL after updating the RecordType of Opportunity to Existing
        * Expected Output: RecordType of OPL should be 'Existing Customer'
        */
        for(APT_Opportunity_Product_Line_Item__c opl : [SELECT Id, RecordTypeId FROM APT_Opportunity_Product_Line_Item__c WHERE Id IN :lstOLI]){
            System.debug('Existing RecordTypeId: ' + mapOPLRecTypeNameTest.get(EXISTING_CUSTOMER_MAP_KEY));
            System.debug('Record Type of OLI record ' + opl.RecordTypeId);
            System.assertEquals(mapOPLRecTypeNameTest.get(EXISTING_CUSTOMER_MAP_KEY), opl.RecordTypeId);
        }
    
        APTMS_AvoidRecursion.firstRun = true;
        //Update Opportunity Type to test the Opportunity Trigger
        opty.Type = APT_Constants.OPPORTUNITY_TYPE_NEW_CUSTOMER;
        update opty;
        
        System.debug('Oppo Updated to New');
        
        /*
        * Check Record Type of OPL after updating the RecordType of Opportunity to New
        * Expected Output: RecordType of OPL should be New Customer
        */
        for(APT_Opportunity_Product_Line_Item__c opl : [SELECT Id, RecordTypeId FROM APT_Opportunity_Product_Line_Item__c WHERE Id IN :lstOLI]){
            System.debug('Existing RecordTypeId: ' + mapOPLRecTypeNameTest.get(EXISTING_CUSTOMER_MAP_KEY));
            System.debug('Record Type of OLI record ' + opl.RecordTypeId);
            System.assertEquals(mapOPLRecTypeNameTest.get(NEW_CUSTOMER_MAP_KEY), opl.RecordTypeId);
        }
        
        //Update Opportunity Type to test the Opportunity Trigger
        opty.Type = APT_Constants.OPPORTUNITY_TYPE_EXISTING_CUSTOMER;
        update opty;
        
        test.stopTest();
    }
    

     private static testMethod void testMethod1() {
        // Setup test data
        // This code runs as the system admin test user
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {
            createTestData();
         }   
     }
}