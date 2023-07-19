/*
Description: This apex test class to cover the methods in APT_OpptyProductListController.
Created By: Mathew Jose
Created Date: 21st March, 2021
2023-06-22 - Ken McGuire - modified for getting preclassified items
*/

@isTest
private class APT_OpptyProductListController_Test {

	//Setting up test data. 
	@testSetup static void setup() {

		Contact con = APT_TestUtils.createContact();
		insert con;
		
		Account tempacct = APT_TestUtils.createOrganisation();
		insert tempacct;
		
		Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
		insert opp;
		
		//Create Products
		Product2 product =APT_TestUtils.createInternationalProduct('Car','26940998','Postal Services');
		insert product;
		List<Product2> productList = new List<Product2>();
		for(Integer i=0; i<5; i++){
			productList.add(APT_TestUtils.createInternationalProduct('Car'+i,'26940998'+i,'Postal Services'));
		}
		insert productList;
		
		Id priceBookId=Test.getStandardPricebookId();
		List<PricebookEntry> pbeList = new List<PricebookEntry>();
		for(Integer i=0; i<5; i++){
			pbeList.add(APT_TestUtils.getPricebookEntry(priceBookId,productList[i].Id));
		}
		insert pbeList;

		List<OpportunityLineItem> oppLineItemList = new List<OpportunityLineItem>();
		for(Integer i=0; i<5; i++){
			oppLineItemList.add(new OpportunityLineItem(Quantity=2,OpportunityId=opp.Id,TotalPrice =45678,PricebookEntryId=pbeList[i].Id,Contract_Start_Date__c=System.Today(),Contract_End_Date__c=System.Today()+1 , Classification__c = 'New Business'));
		}
		insert oppLineItemList;
	}

	//Method to test the retrieval of OpportunityLineItems via SOQL which is presented in the datatable. 
	@isTest static void getOpptyProductsTest() {
		Opportunity opp = [Select id from opportunity limit 1];
		List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
		oppLineList = APT_OpptyProductListController.getOpptyProducts(opp.id,false);
		System.AssertEquals(oppLineList.size(),5);
	}

	//Method which tests the successful update of opportunity line items when saved via lwc datatable.
	@isTest static void updateOppProductsSuccessTest() {
		Opportunity opp = [Select id from opportunity limit 1];
		List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
		oppLineList = [Select id, Contract_Start_Date__c, Contract_End_Date__c 
		from OpportunityLineItem 
		where opportunityId = : opp.Id];
		System.AssertEquals(oppLineList.size(),5);
		for(OpportunityLineItem oli: oppLineList){
			oli.Contract_Start_Date__c = System.Today()+2;
			oli.Contract_End_Date__c = System.Today()+5;
		}
		String response = APT_OpptyProductListController.updateOppProducts(oppLineList);
		APT_OpptyProductListController.Errors serverResponse = (APT_OpptyProductListController.Errors)System.JSON.deserialize(response, APT_OpptyProductListController.Errors.class);
		System.AssertEquals(serverResponse.status, 'Success');
	}

	//Method which tests the failed update of opportunitylineitems when saved via lwc datatable.
	@isTest static void updateOppProductsFailTest() {
		Opportunity opp = [Select id from opportunity limit 1];
		List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
		oppLineList = [Select id, Contract_Start_Date__c, Contract_End_Date__c 
		from OpportunityLineItem 
		where opportunityId = : opp.Id];
		System.AssertEquals(oppLineList.size(),5);
		for(OpportunityLineItem oli: oppLineList){
			oli.Contract_Start_Date__c = System.Today()+2;
			oli.Contract_End_Date__c = System.Today()-2;
		}
		String response = APT_OpptyProductListController.updateOppProducts(oppLineList);
		APT_OpptyProductListController.Errors serverResponse = (APT_OpptyProductListController.Errors)System.JSON.deserialize(response, APT_OpptyProductListController.Errors.class);
		System.AssertEquals(serverResponse.status, 'Errors');
	}
}