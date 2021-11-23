@isTest
private class APTS_BasicCPQFlowTest {
    private static testMethod void BasicCPQFlowExecution() {
         
        APTS_TestDataFactory.CreateAllConfigSettings();
        APTS_TestDataFactory.CreateAllBasicData(true);
        
        Test.startTest();  
        // Commented out by Adrian Recio 
        // Description: Method call commented out temporarily until unknown manage code error is resolve by Apttus.
        //Apttus_Config2.PricingWebService.updatePriceForCart(APTS_TestDataFactory.GloCartID);
        
        
        //APTS_TestDataFactory.CreateApprReq(APTS_TestDataFactory.objOpty.ID);
        //APTS_TestDataFactory.CreateContact(APTS_TestDataFactory.objAcc.ID);
        //APTS_TestDataFactory.ExecuteBasicCPQFlow();
        Test.stopTest();    
    }
    
    private static testmethod void testmethod2(){
        Test.startTest();
        Apttus_Config2__PriceList__c conPricelist = APTS_TestDataFactory.insertPriceListNonUS();
        Account acc = APTS_TestDataFactory.insertAccount();
        Opportunity opp = APTS_TestDataFactory.insertOppty(acc);
        APTS_TestDataFactory.CreateApprReq(Opp.ID);        
        Test.stopTest();
    }
}