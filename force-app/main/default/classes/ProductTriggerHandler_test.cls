/**************************************************
Type:       Test Class - Trigger Handler for OpportunityLineItem Object
Purpose:    Test Class - Handle Triggers for the OpportunityLineItem Object for a cleaner code coverage
--------------------------------------------------
August 2, 2018 - Created by daric.antoni.a.dava 
**************************************************/
@isTest
public class ProductTriggerHandler_test {
    
    public static final String TEST_PROFILE_NAME = 'System Administrator';
    
    // Test method to create user account
    public static Account createUserAccount(){
        RecordType orgrectype = [SELECT Id FROM RecordType WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];
        
        // Build Test holding user
        User u1 = new User();
        u1 = OpptyLineItemTriggerHandler_TestUtil.getTestUser(ProductTriggerHandler_test.TEST_PROFILE_NAME);                                       
        insert u1;
        
        // Create Test Account
        Account accVar = new Account();
        accVar = OpptyLineItemTriggerHandler_TestUtil.getTestAccount(u1.Id,orgrectype.Id);
        insert accVar;
        
        return accVar;
    }
    
    // Generate an Opportunity that has multiple simple products
    public static void createOpptyData(Boolean isExeptProd){
        Account accVar = createUserAccount(); 
        
        String prefix = isExeptProd ? '' : 'Non-';
        
        // Create Product
        Product2 prodVar1 = OpptyLineItemTriggerHandler_TestUtil.getTestProduct(prefix+'Exception Product 1',isExeptProd);
        Product2 prodVar2 = OpptyLineItemTriggerHandler_TestUtil.getTestProduct(prefix+'Exception Product 2','EP 2',isExeptProd);
        insert new List<Product2>{prodVar1,prodVar2};
        
        // Get Standard PBID
        ID standardPBID = Test.getStandardPricebookId();
        
        // Create Pricebook
        Pricebook2 pbVar1 = OpptyLineItemTriggerHandler_TestUtil.getTestPricebook('Test Pricebook 1',true);
        Pricebook2 pbVar2 = OpptyLineItemTriggerHandler_TestUtil.getTestPricebook('Test Pricebook 2',true);
        insert new List<Pricebook2>{pbVar1,pbVar2};
        
        // Standard PBE
        PricebookEntry standardPrice1 = OpptyLineItemTriggerHandler_TestUtil.getTestPricebookEntry(standardPBID, prodVar1.Id, 10000);
        PricebookEntry standardPrice2 = OpptyLineItemTriggerHandler_TestUtil.getTestPricebookEntry(standardPBID, prodVar2.Id, 10000);
        insert new List<PricebookEntry>{standardPrice1,standardPrice2};
        
        // Create PricebookEntry
        PricebookEntry pbeVar1 = OpptyLineItemTriggerHandler_TestUtil.getTestPricebookEntry(pbVar1.ID, prodVar1.ID, 1);
        PricebookEntry pbeVar2 = OpptyLineItemTriggerHandler_TestUtil.getTestPricebookEntry(pbVar2.ID, prodVar2.ID, 1);
        insert new List<PricebookEntry>{pbeVar1,pbeVar2};
        
        //create opportunity
        Opportunity oppVar = OpptyLineItemTriggerHandler_TestUtil.getTestOpportunity(accVar.Id);
        insert oppVar;
        
        // Create Opportunity Line Item
        OpportunityLineItem oliVar1 = OpptyLineItemTriggerHandler_TestUtil.getTestOpportunityLineItem(oppVar.ID,pbeVar1.ID,prodVar1.ID);
        oliVar1.Description = 'test oli desc 1';
        // RSolomon Forcing different dates to avoid a duplicate entry
        oliVar1.Contract_Start_Date__c = Date.newInstance(2013, 07 ,28);
        oliVar1.Contract_End_Date__c = Date.newInstance(2014, 07 ,28);
        
        OpportunityLineItem oliVar2 = OpptyLineItemTriggerHandler_TestUtil.getTestOpportunityLineItem(oppVar.ID,pbeVar1.ID,prodVar2.ID);
        oliVar2.Description = 'test oli desc 2';
        // RSolomon Forcing different dates to avoid a duplicate entry
        oliVar2.Contract_Start_Date__c = Date.newInstance(2013, 07 ,27);
        oliVar2.Contract_End_Date__c = Date.newInstance(2014, 07 ,27);
        insert new List<OpportunityLineItem>{oliVar1,oliVar2};
    }   
    
    // Test method to change a product To Exception Product
    public static testMethod void testChangeToExceptionProduct(){
        
        createOpptyData(false);
        Opportunity oldOppVar = [SELECT Id, Product_Complexity_Rating__C FROM Opportunity where Name = 'test oppty 1' limit 1];
        
        List<Product2> prodToChangeList = [SELECT Id,Name,Is_Exception_Product__c FROM Product2];
        
        test.startTest();
        for(Product2 prodToChange :prodToChangeList ){
            prodToChange.Is_Exception_Product__c = true;
        }
        
        update prodToChangeList;
        test.stopTest();
        
        Opportunity updOppVar = [SELECT Id, Product_Complexity_Rating__C FROM Opportunity where Name = 'test oppty 1' limit 1];
        
        
        // Assert that the expected Complexity rating is 0 since there is no existing complex product
        system.assertEquals(0, oldOppVar.Product_Complexity_Rating__C);
        // Assert that the expected Complexity rating is 3 since there is now an existing complex product
        system.assertEquals(3, updOppVar.Product_Complexity_Rating__C);
    }  

    
    // Test method to change a product To Exception Product
    public static testMethod void testChangeToNonExceptionProduct(){
        
        createOpptyData(true);
        Opportunity oldOppVar = [SELECT Id, Product_Complexity_Rating__C FROM Opportunity where Name = 'test oppty 1' limit 1];
        
        Product2 prodToChange = [SELECT Id,Name,Is_Exception_Product__c FROM Product2 WHERE Name = 'Exception Product 1' LIMIT 1];
        
        test.startTest();
        prodToChange.Name = 'Non-Exception Product 1';
        prodToChange.Is_Exception_Product__c = false;
        update prodToChange;
        test.stopTest();
        
        Opportunity updOppVar = [SELECT Id, Product_Complexity_Rating__C FROM Opportunity where Name = 'test oppty 1' limit 1];
        
        
        // Assert that the expected Complexity rating is 0 since there is no existing complex product
        system.assertEquals(3, oldOppVar.Product_Complexity_Rating__C);
        // Assert that the expected Complexity rating is 3 since there is now an existing complex product
        system.assertEquals(0, updOppVar.Product_Complexity_Rating__C);
    }  	
}