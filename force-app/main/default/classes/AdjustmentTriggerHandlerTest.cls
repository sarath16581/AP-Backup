/**
 * Date            Version          Owner               Desription
 * 29-Mar-17        1.0             Adrian A            Test class for AdjustmentTriggerHandler
 */
@isTest
private with sharing class AdjustmentTriggerHandlerTest {
    /* Test Method for AdjustmentTriggerHandler to close a case */
	public static testmethod void AdjustmentTriggerHandlerTest() {
        try{
            // Create Test Case
            Case cs = I2CTestDataBuilder.createCase();
            insert cs;
			
            List<Disputed_Item__c> diTempListWithoutCA = new List<Disputed_Item__c>();
            // Create Test Disputed Items without existing CA
            List<Disputed_Item__c> diListWithoutCA = I2CTestDataBuilder.createDisputeItem(cs);
    
            // Create Test Disputed Items with existing CA
            List<Disputed_Item__c> diListwithCA = I2CTestDataBuilder.createDisputeItem(cs);
    
            for(Disputed_Item__c diItem : diListWithoutCA){
            	if(diItem.Product__c == 'Parcels'){
                	diTempListWithoutCA.add(diItem);    
                }
            }
			insert diTempListWithoutCA; // populateCreditApproval
            
            List<Credit_Approval__c> caList = [Select Id , Status__c from Credit_Approval__c LIMIT 1];
            
            // Force Approved for testing
            for(Credit_Approval__c caVar: caList){
                caVar.Status__c = 'Approved';
            }
            
            update caList;
            
            test.startTest();
            Adjustment__c adjustmentRec = new Adjustment__c();
            adjustmentRec.Organisation__c = cs.Calc_Link_Account__c;
            adjustmentRec.Case__c = cs.Id;
            adjustmentRec.Status__c = 'New';
            adjustmentRec.Type__c = 'Non-Discretionary';
            insert adjustmentRec;
            AdjustmentTriggerHandler.adjRecursiveFlag = false;
            adjustmentRec.CreditAmountExclusiveGST__c = 100;
			adjustmentRec.CreditAmountInclusiveGST__c = 110;            
            update adjustmentRec;
			test.stopTest();
            system.assertEquals('New', adjustmentRec.Status__c);
        }catch(Exception e){
        	e.getStackTraceString();    
        }
	}
}