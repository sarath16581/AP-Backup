/**
 * @description This apex class is test class for APT_ManageRateCardProductsController.
 * @author Yukti Jain
 * @date 2016-07-28
 * @changelog
 * 2016-01-20 - Yukti Jain - Created
 * 2024-01-30 - Ranjeewa Silva - Updates to existing tests to ensure test data conforms to new validation rule in APT_Sub_Account__c.
 */
@isTest
private with sharing class APT_ManageLodgementPointLookupCntlr_Test{
	/**
	Creating test data
	**/	 
	static testMethod void testMethod1() {
		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
		User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
		EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
		LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
		TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
		UserName=APT_Constants.EMAIL_TEST_USER);
		System.runAs(testuser) {
			 APT_ManageLodgementPointLookupController objcls5 = new APT_ManageLodgementPointLookupController();
			 objcls5.searchbillingAcc();
			 objcls5.showAllbillingAccs();
			 objcls5.searchAccouts();
			 objcls5.showAllAccs();
			 
			 //Create Account
			 Account acc = APT_TestUtils.createOrganisation();
			 acc.AccountNumber = '12345';
			 insert acc;  
	
			 //Create Opportunity
			 Opportunity opty = APT_TestUtils.createOpportunity(acc.id);
			 insert opty;
			 
			 //Create PriceList
			 Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
			 insert priceList;
			 
			 //create international product
			 Product2 bundle1 = APT_TestUtils.createInternationalProduct('International Bundle','eParcelStandard','Postal Services');
			 bundle1.APT_Sync_with_Opportunity__c = TRUE;
			 insert bundle1;
			 
			 //Create Option product
			 Product2 option = APT_TestUtils.createInternationalProduct('International Bundle','eParcelStandard','Postal Services');
			 option.Apttus_Config2__ConfigurationType__c='Option';
			 option.APT_Sync_with_Opportunity__c = TRUE;
			 insert option;
			 
			 //Create PriceBookEntry
			 id pricebookid = Test.getStandardPricebookid(); 
			 PricebookEntry standardPrice = APT_TestUtils.getPricebookEntry(Test.getStandardPricebookid(),option.id);
			 insert standardPrice;
			 
			 //Create Price list Item
			 Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.id,bundle1.id,'C Manufacturing','BAND 2');
			 insert pli;
			 
			 //Create Proposal
			 Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.id,opty.id,'Proposal','Quote', priceList.id);
			 Proposal.Apttus_Proposal__Approval_Stage__c='Draft';
			 insert Proposal;
			 
			 //Create Product Configuration
			 Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
			 proposal.id, 'Proposal',
			 'Ad Hoc',priceList.id, null,
			 'Finalized',
			 null, Datetime.now(), true);
			 insert prodconfig;

			test.startTest();
			ApexPages.currentPage().getParameters().put('enteredAccVal','Account Test');
			ApexPages.currentPage().getParameters().put('prodConId',prodconfig.id);
			ApexPages.currentPage().getParameters().put('quoteId',Proposal.id);
			ApexPages.currentPage().getParameters().put('source','billingAccCPQ');
			APT_ManageLodgementPointLookupController objcls1 = new APT_ManageLodgementPointLookupController();
			objcls1.searchbillingAcc();
			objcls1.showAllbillingAccs();
			objcls1.searchAccouts();
			objcls1.showAllAccs();
			
			APT_Charge_Account__c chrgAcc = new APT_Charge_Account__c();
			//chrgAcc.Name = 'Account Test';
			chrgAcc.APT_Company_Name__c = 'Test Company';
			chrgAcc.APT_Quote_Proposal__c = Proposal.id;
			chrgAcc.APT_ABN__c = 'Test Acc';
			chrgAcc.APT_ACN__c = 'Test Acc';
			chrgAcc.APT_Credit_Limit_Required__c = 150.5;
			insert chrgAcc;
		
			APT_Cash_Account__c cshAcc = new APT_Cash_Account__c();
			//cshAcc.Name = 'Account Test';
			cshAcc.APT_Cust_Name__c = 'Test Company';
			cshAcc.APT_Proposal__c= Proposal.id;
			cshAcc.APT_ABN__c = 'Test Acc';
			cshAcc.APT_ACN__c = 'Test Acc';
			insert cshAcc;
		
			APT_sub_Account__c subAcc = new APT_sub_Account__c();
			subAcc.Name = 'Account Test';
			subAcc.APT_Sub_Account_Contact_Name__c = 'Test Company';
			subAcc.APT_Quote_Proposal__c = Proposal.id;
			subAcc.APT_Sub_Account_Contact_Email_Address__c = 'Test@test.com';
			subAcc.APT_Charge_Account__c = chrgAcc.id;
			subAcc.APT_Sub_Account_Request_Status__c = 'Draft';
			insert subAcc;
			
			
			ApexPages.currentPage().getParameters().put('source','cashAccountCLM');
			APT_ManageLodgementPointLookupController objcls3 = new APT_ManageLodgementPointLookupController();
			objcls3.searchAccouts();
			objcls3.showAllAccs();
			
			ApexPages.currentPage().getParameters().put('source','subAccountCLM');
			APT_ManageLodgementPointLookupController objcls = new APT_ManageLodgementPointLookupController();
			objcls.searchAccouts();
			objcls.showAllAccs();
			
			ApexPages.currentPage().getParameters().put('source','chargeAccountCLM');
			APT_ManageLodgementPointLookupController objcls2 = new APT_ManageLodgementPointLookupController();
			objcls2.searchAccouts();
			objcls2.showAllAccs();
			
			ApexPages.currentPage().getParameters().put('enteredAccVal','');
			APT_ManageLodgementPointLookupController objcls4 = new APT_ManageLodgementPointLookupController();
			objcls4.searchAccouts();
			objcls4.showAllAccs();
			test.stopTest();
						 system.assert(Proposal!=null);
			system.assert(prodconfig!=null);
		}
	}
}