/**
 * Date			Version		  	Owner			   	Desription
 * 29-Mar-17	1.0				Adrian A			Test class for AdjustmentTriggerHandler
 * 02-Jun-23	1.1				Pratyush Chalasani 	Test carry-over of Is_APPC__c from related Disputed Item
 */
@isTest
private with sharing class AdjustmentTriggerHandlerTest {
	/* Test Method for AdjustmentTriggerHandler to close a case */
	@isTest
	public static void AdjustmentTriggerHandlerTest() {
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

	/* Make sure Is_APPC__c flag for Adjustment is carried over from Disputed Item */
	@isTest
	static void test_Is_APPC_flag() {
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

				diItem.Is_APPC__c = 'Yes';
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
			test.stopTest();
			
			adjustmentRec = [SELECT Is_APPC__c FROM Adjustment__c WHERE Id = :adjustmentRec.Id];
			
			Assert.areEqual(true, adjustmentRec.Is_APPC__c);
		}catch(Exception e){
			e.getStackTraceString();	
		}
	}

	/*
		Make sure Is_APPC__c flag for Adjustment is carried over from Disputed Item.
		(Test with multiple child records)
	*/
	@isTest
	static void test_Is_APPC_flag_multiple_records() {
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

				diItem.Is_APPC__c = 'Yes';
			}
			insert diTempListWithoutCA; // populateCreditApproval
			
			List<Credit_Approval__c> caList = [Select Id , Status__c from Credit_Approval__c];
			
			// Force Approved for testing
			for(Credit_Approval__c caVar: caList){
				caVar.Status__c = 'Approved';
			}
			
			update caList;
			
			test.startTest();
			Adjustment__c adjustmentRec1 = new Adjustment__c();
			adjustmentRec1.Organisation__c = cs.Calc_Link_Account__c;
			adjustmentRec1.Case__c = cs.Id;
			adjustmentRec1.Status__c = 'New';
			adjustmentRec1.Type__c = 'Non-Discretionary';
			insert adjustmentRec1;

			Adjustment__c adjustmentRec2 = new Adjustment__c();
			adjustmentRec2.Organisation__c = cs.Calc_Link_Account__c;
			adjustmentRec2.Case__c = cs.Id;
			adjustmentRec2.Status__c = 'New';
			adjustmentRec2.Type__c = 'Discretionary Credit';
			insert adjustmentRec2;
			test.stopTest();
			
			adjustmentRec1 = [SELECT Is_APPC__c FROM Adjustment__c WHERE Id = :adjustmentRec1.Id];
			adjustmentRec2 = [SELECT Is_APPC__c FROM Adjustment__c WHERE Id = :adjustmentRec2.Id];
			
			Assert.areEqual(true, adjustmentRec1.Is_APPC__c);
			Assert.areEqual(true, adjustmentRec2.Is_APPC__c);
		}catch(Exception e){
			e.getStackTraceString();	
		}
	}
}