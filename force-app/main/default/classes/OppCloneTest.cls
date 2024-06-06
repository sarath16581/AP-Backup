/****************************************************************************************
Author:         Unknown
History:
-----------------------------------------------------------------------------------------
25-11-2016        Unknown              Test class created 
09-03-2021        Seth Heang           Remove (seeAllData=true) and remove hard-coded PricebookEntryId reference to use locally created PricebookEntry test data
*****************************************************************************************/
@isTest
private class OppCloneTest{
    static testMethod void testcloneWithoutItems() {        
        test.startTest();
        
        
        Account a=new Account();
        a.name='ttestt';
        insert a;
        
        Opportunity o = new Opportunity();
        o.Name='testtest';
        o.Account=a;
        o.Offering_Type__c='Product';
        o.StageName='Identify';
        o.Probability=3;
        o.CloseDate=Date.today();
        o.Commit_to_close_by__c=Date.today();
        o.Type='Existing Customer';
        insert o;
        
        // Create Product2
        Product2 testProduct = new Product2();
        testProduct.Name = 'Test Product';
        testProduct.IsActive = TRUE;
        insert testProduct;
        // Get Standard Pricebook2
        Id standardPBId = Test.getStandardPricebookId();
        // Create PricebookEntry
        PricebookEntry pbe = new PricebookEntry();
        pbe.Pricebook2Id = standardPBId;
        pbe.Product2Id = testProduct.Id;
        pbe.UnitPrice = 1.00;
        pbe.IsActive = TRUE;
        pbe.UseStandardPrice = FALSE;
        insert pbe;
        
        OpportunityLineItem li = new OpportunityLineItem(OpportunityId = o.Id,Quantity = 5,PricebookEntryId = pbe.Id,
                TotalPrice = 5,Contract_Start_Date__c = system.today(),Contract_End_Date__c = system.today().addDays(3));
		li = (OpportunityLineItem)ApplicationTestDataFactory.setUnwritableFields(li, new Map<String, Object>{
				'Annualised_Value__c' => 5000,
				'Product2Id' => testProduct.Id
		});
		li.Opportunity = o;
        
        OpportunityCloneWithItemsController oc=new OpportunityCloneWithItemsController();
        oc.cloneWithoutItems();
        
        oc.cloneWithItems();
        
        ApexPages.StandardController sc = new ApexPages.standardController(o);
        // create an instance of the controller
        OpportunityCloneWithItemsController myPageCon = new OpportunityCloneWithItemsController (sc);
        
        //try calling methods/properties of the controller in all possible scenarios
        // to get the best coverage.
        
        myPageCon.cloneWithoutItems();
        myPageCon.cloneWithItems();
        
        test.stopTest();    
    }    
}