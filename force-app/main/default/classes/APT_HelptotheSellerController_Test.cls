/**
Description: This apex class is test class for APT_HelptotheSellerController.
Created By - Drashtee Shah
Created Date - 16th feb, 2016
Last Modified By -
Last Modified Date - 
@changelog:
2022-06-09 - Seth Heang - Added test coverage for validation check on contract expiration date
**/
@isTest
public class APT_HelptotheSellerController_Test {
    /**
        Creating Test Data
    **/
    public static testMethod void APT_HelptotheSellerController1() {
        
        System.runAs(new user(ID = UserInfo.getUserID())) {
        // create contact
        Contact con = APT_TestUtils.createContact();
        insert con;
        
        //create account
        Account tempacct = APT_TestUtils.createOrganisation();
        insert tempacct;
        
        //create opportunity
        Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
        insert opp;
        
        // create pricelist
        Apttus_Config2__PriceList__c  priceList =APT_TestUtils.createPriceList();
        insert priceList;
        
        //create proposal
        Apttus_Proposal__Proposal__c proposal = APT_TestUtils.getQuoteProposal(tempacct.id,opp.Id,'Proposal','Test',priceList.id);
        proposal.APT_Contract_Number__c='APT-012.123';
        insert proposal;
        
        //create product configuration
        Apttus_Config2__ProductConfiguration__c  config= new Apttus_Config2__ProductConfiguration__c  (Name ='Sample',Apttus_Config2__VersionNumber__c =1,Apttus_Config2__BusinessObjectId__c =proposal.Id,Apttus_QPConfig__Proposald__c =proposal.Id,Apttus_Config2__SummaryGroupType__c ='Test',Apttus_Config2__BusinessObjectType__c ='Test1',
                                                        Apttus_Config2__PriceListId__c =priceList.Id,Apttus_Config2__Status__c =APT_Constants.CONFIGURATION_STATUS_FINALIZED,Apttus_Config2__FinalizedDate__c =System.Today(),Apttus_Config2__EffectiveDate__c =System.Today(),Apttus_Config2__IsTransient__c =True);
        
        insert config;
        
        // getting recordtype
        RecordType rt = [select id,Name from RecordType where SobjectType='Apttus__APTS_Agreement__c' and Name='Community Update Pack' Limit 1];
        
        //create agreement
        Apttus__APTS_Agreement__c agreement = APT_TestUtils.createAgreement(con.Id);
        agreement.Apttus__Agreement_Number__c = '012';
        agreement.Apttus__Related_Opportunity__c =opp.id;
        agreement.Apttus_QPComply__RelatedProposalId__c =proposal.id;
        agreement.Apttus__Version_Number__c=123.0;
        agreement.RecordType = rt;
        agreement.Apttus__Agreement_Category__c = 'Standard';
        agreement.Apttus__Total_Contract_Value__c = 100;
        insert agreement;
        
        String agreementID = agreement.ID;
        
        agreement = [select id,Apttus__Agreement_Number__c, Apttus__Related_Opportunity__c,Apttus_QPComply__RelatedProposalId__c,
                    Apttus__Version_Number__c,Apttus__Agreement_Category__c,Apttus__Total_Contract_Value__c from 
                    Apttus__APTS_Agreement__c where id = :agreementID Limit 1];
        
        //create APT_R2T_Signers_Authority_Help_Text__c
        APT_R2T_Signers_Authority_Help_Text__c saht = new APT_R2T_Signers_Authority_Help_Text__c();
        saht.Name = 'custom setting';
        saht.Compare_Contract_Category__c = true;
        saht.Contract_Category__c = 'Standard';
        saht.Record_Type_Name__c = 'APT_MSA_Service_Schedule';
        insert saht;
        
        APT_R2T_Signers_Authority_Help_Text__c saht1 = new APT_R2T_Signers_Authority_Help_Text__c();
        saht1.Name = 'custom setting2';
        saht1.Compare_Contract_Category__c = true;
        saht1.Contract_Category__c = 'Standard';
        saht1.Record_Type_Name__c = 'APT_MSA_Service_Schedule';
        insert saht1;
        
        Test.StartTest();
        System.debug('*******Agreement'+agreement.Apttus__Total_Contract_Value__c);
        agreement.Apttus__Total_Contract_Value__c = 100;
        update agreement;
        PageReference pageRef = Page.APT_HelptotheSeller;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(agreement);
        
        Apexpages.currentPage().getParameters().put('id', agreement.ID);
        Apexpages.currentPage().getParameters().put('name', 'true');
        APT_HelptotheSellerController hsc = new APT_HelptotheSellerController(sc);
        hsc.donext();
        hsc.docancel();
        pagereference pgRef = hsc.Next();
        System.assert(pgRef != null);
        Test.StopTest();
        
        }
    }
    /**
        Creating Test Data
    **/    
    public static testMethod void APT_HelptotheSellerController2() {
        
        System.runAs(new user(ID = UserInfo.getUserID())) {
        // create contact
        Contact con = APT_TestUtils.createContact();
        insert con;
        
        //create account
        Account tempacct = APT_TestUtils.createOrganisation();
        insert tempacct;
        
        //create opportunity
        Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
        insert opp;
        
        // create pricelist
        Apttus_Config2__PriceList__c  priceList =APT_TestUtils.createPriceList();
        insert priceList;
        
        //create proposal
        Apttus_Proposal__Proposal__c proposal = APT_TestUtils.getQuoteProposal(tempacct.id,opp.Id,'Proposal','Test',priceList.id);
        proposal.APT_Contract_Number__c='APT-012.123';
        insert proposal;
        
        //create product configuration
        Apttus_Config2__ProductConfiguration__c  config= new Apttus_Config2__ProductConfiguration__c  (Name ='Sample',Apttus_Config2__VersionNumber__c =1,Apttus_Config2__BusinessObjectId__c =proposal.Id,Apttus_QPConfig__Proposald__c =proposal.Id,Apttus_Config2__SummaryGroupType__c ='Test',Apttus_Config2__BusinessObjectType__c ='Test1',
                                                        Apttus_Config2__PriceListId__c =priceList.Id,Apttus_Config2__Status__c =APT_Constants.CONFIGURATION_STATUS_FINALIZED,Apttus_Config2__FinalizedDate__c =System.Today(),Apttus_Config2__EffectiveDate__c =System.Today(),Apttus_Config2__IsTransient__c =True);
        
        insert config;
        
        // getting recordtype
        RecordType rt = [select id,Name from RecordType where SobjectType='Apttus__APTS_Agreement__c' and Name='Community Update Pack' Limit 1];
        
        //create agreement
        Apttus__APTS_Agreement__c agreement = APT_TestUtils.createAgreement(con.Id);
        agreement.Apttus__Agreement_Number__c = '012';
        agreement.Apttus__Related_Opportunity__c =opp.id;
        agreement.Apttus_QPComply__RelatedProposalId__c =proposal.id;
        agreement.Apttus__Version_Number__c=123.0;
        agreement.RecordType = rt;
        agreement.Apttus__Agreement_Category__c = 'Standard';
        agreement.Apttus__Total_Contract_Value__c = 100;
        insert agreement;
        
        //create APT_R2T_Signers_Authority_Help_Text__c
        APT_R2T_Signers_Authority_Help_Text__c saht = new APT_R2T_Signers_Authority_Help_Text__c();
        saht.Name = 'custom setting';
        saht.Compare_Contract_Category__c = false;
        saht.Contract_Category__c = 'Standard';
        saht.Type__c='HelpText';
        saht.Record_Type_Name__c = 'APT_MSA_Service_Schedule';
        saht.Value_To__c = 1000;
        saht.Value_From__c = 1;
        insert saht;
        
        APT_R2T_Signers_Authority_Help_Text__c saht2 = new APT_R2T_Signers_Authority_Help_Text__c();
        saht2.Name = 'custom setting2';
        saht2.Compare_Contract_Category__c = true;
        saht2.Contract_Category__c = 'Standard';
        saht2.Record_Type_Name__c = 'APT_MSA_Service_Schedule';
        saht2.Value_To__c = 1000;
        saht2.Type__c='HelpText';
        saht2.Value_From__c = 1;
        insert saht2;
        
       /* APT_R2T_Signers_Authority_Help_Text__c saht3 = new APT_R2T_Signers_Authority_Help_Text__c();
        saht.Name = 'custom setting3';
        saht.Compare_Contract_Category__c = false;
        saht.Contract_Category__c = 'Standard';
        saht.Record_Type_Name__c = 'Community Update Pack';
        saht.Value_To__c = 1000;
        saht.Value_From__c = 1;
        insert saht3;*/
        
        Test.StartTest();
        
        PageReference pageRef = Page.APT_HelptotheSeller;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(agreement);
        
        Apexpages.currentPage().getParameters().put('id', agreement.ID);
        Apexpages.currentPage().getParameters().put('name', 'true');
        APT_HelptotheSellerController hsc = new APT_HelptotheSellerController(sc);
        hsc.donext();
        hsc.docancel();
        PageReference pgRef = hsc.Next();
        System.assert(pgRef != null);
        Test.StopTest();
        
        }
    }
    
	/**
		Creating Test Data
	**/
	public static testMethod void APT_HelptotheSellerController3() {
		
		System.runAs(new user(ID = UserInfo.getUserID())) {
		// create contact
		Contact con = APT_TestUtils.createContact();
		insert con;

		//create account
		Account tempacct = APT_TestUtils.createOrganisation();
		insert tempacct;

		//create opportunity
		Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
		insert opp;

		// create pricelist
		Apttus_Config2__PriceList__c  priceList =APT_TestUtils.createPriceList();
		insert priceList;

		//create proposal
		Apttus_Proposal__Proposal__c proposal = APT_TestUtils.getQuoteProposal(tempacct.id,opp.Id,'Proposal','Test',priceList.id);
		proposal.APT_Contract_Number__c='APT-012.123';
		insert proposal;

		//create product configuration
		Apttus_Config2__ProductConfiguration__c  config= new Apttus_Config2__ProductConfiguration__c  (Name ='Sample',Apttus_Config2__VersionNumber__c =1,Apttus_Config2__BusinessObjectId__c =proposal.Id,Apttus_QPConfig__Proposald__c =proposal.Id,Apttus_Config2__SummaryGroupType__c ='Test',Apttus_Config2__BusinessObjectType__c ='Test1',
		                                                Apttus_Config2__PriceListId__c =priceList.Id,Apttus_Config2__Status__c =APT_Constants.CONFIGURATION_STATUS_FINALIZED,Apttus_Config2__FinalizedDate__c =System.Today(),Apttus_Config2__EffectiveDate__c =System.Today(),Apttus_Config2__IsTransient__c =True);

		insert config;

		// getting recordtype
		RecordType rt = [select id,Name from RecordType where SobjectType='Apttus__APTS_Agreement__c' and Name='Community Update Pack' Limit 1];

		//create agreement
		Apttus__APTS_Agreement__c agreement = APT_TestUtils.createAgreement(con.Id);
		agreement.Apttus__Agreement_Number__c = '012';
		agreement.Apttus__Related_Opportunity__c =opp.id;
		agreement.Apttus_QPComply__RelatedProposalId__c =proposal.id;
		agreement.Apttus__Version_Number__c=123.0;
		agreement.RecordType = rt;
		agreement.Apttus__Agreement_Category__c = 'Standard';
		agreement.Apttus__Total_Contract_Value__c = 100;
		insert agreement;

		//create APT_R2T_Signers_Authority_Help_Text__c
		APT_R2T_Signers_Authority_Help_Text__c saht = new APT_R2T_Signers_Authority_Help_Text__c();
		saht.Name = 'custom setting';
		saht.Compare_Contract_Category__c = false;
		saht.Type__c=APT_Constants.HelpText;
		saht.Contract_Category__c = 'Standard';
		saht.Record_Type_Name__c = 'APT_MSA_Service_Schedule';
		saht.Value_To__c = 1000;
		saht.Value_From__c = 1;
		insert saht;

		APT_R2T_Signers_Authority_Help_Text__c saht2 = new APT_R2T_Signers_Authority_Help_Text__c();
		saht2.Name = 'custom setting2';
		saht2.Compare_Contract_Category__c = true;
		saht2.Contract_Category__c = 'Standard';
		saht2.Record_Type_Name__c = 'APT_MSA_Service_Schedule';
		saht2.Type__c=APT_Constants.MinSigners;
		saht2.Value_To__c = 1000;
		saht2.Value_From__c = 1;
		saht2.Min_Number_of_Signers__c =4;
		insert saht2;

		Apttus_DocuApi__DocuSignDefaultRecipient2__c docSignRecip= new Apttus_DocuApi__DocuSignDefaultRecipient2__c(Apttus_CMDSign__AgreementId__c=agreement.id,Apttus_DocuApi__RecipientType__c=APT_Constants.Signer);
		insert docSignRecip;
		Test.StartTest();

		PageReference pageRef = Page.APT_HelptotheSeller;
		Test.setCurrentPage(pageRef);

		ApexPages.StandardController sc = new ApexPages.StandardController(agreement);

		Apexpages.currentPage().getParameters().put('id', agreement.ID);
		//Apexpages.currentPage().getParameters().put('name', 'true');
		APT_HelptotheSellerController hsc = new APT_HelptotheSellerController(sc);
		hsc.donext();
		hsc.docancel();
		PageReference pgRef = hsc.Next();
		System.assert(pgRef != null);

		String titleVal = APT_HelptotheSellerController.titleValue;
		String nextVal = APT_HelptotheSellerController.nextValue;
		String cancelVal = APT_HelptotheSellerController.cancelValue;

		PageReference pgRefDocuSign = hsc.addDocusignRecipient();
		System.assert(pgRefDocuSign != null);

		// test coverage for contract expiration date validation
		// make contract expiration date in the past
		agreement.Contract_Expiration_Date__c = System.TODAY()-7;
		update agreement;
		hsc.Agrvalue = agreement;
		hsc.init();
		Boolean contractExpDateResult = hsc.validateExpDate(agreement);
		System.assertEquals(true, contractExpDateResult, 'result should be true due as validation check triggered');
		System.assertNotEquals(0, ApexPages.getMessages().size(), 'VF page should have error message');
		System.assertEquals(true, ApexPages.hasMessages(ApexPages.SEVERITY.ERROR), 'VF page should have error message');
		Test.StopTest();

		}
	}

}