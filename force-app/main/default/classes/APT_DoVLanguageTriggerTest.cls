/**
 * @description       : This Test class is written for APT_DoVLanguageTrigger
 * @author            : Mansi Shah
 * @group             : 
 * @last modified on  : 05-21-2021
 * @last modified by  : Mansi Shah
 * Modifications Log 
 * Ver   Date         Author       Modification
 * 1.0   05-21-2021   Mansi Shah   Initial Version
**/
@isTest
public class APT_DoVLanguageTriggerTest {
    @TestSetup
    static void makeData(){
        Apttus__APTS_Admin__c admin = new Apttus__APTS_Admin__c();
        admin.Name = 'APTS_ContentRepositoryType';
        admin.Apttus__Value__c = 'Chatter';
        insert admin;

        List<APT_Agreement_auto_activate_recordtypes__c> aaRTypeList = new List<APT_Agreement_auto_activate_recordtypes__c>();

        APT_Agreement_auto_activate_recordtypes__c customsetting1 = new APT_Agreement_auto_activate_recordtypes__c();
        customsetting1.Name = 'APT_MSA_Service_Schedule';
        aaRTypeList.add(customsetting1);

        APT_Agreement_auto_activate_recordtypes__c customsetting2 = new APT_Agreement_auto_activate_recordtypes__c();
        customsetting2.Name = 'APT_Postbillpay_Contract';
        aaRTypeList.add(customsetting2);

        insert aaRTypeList;

        Contact con= APT_TestUtils.createContact();
        insert con;

        List<Account> accList = new List<Account>();

        Account legacyacct = APT_TestUtils.createOrganisation();
        legacyacct.Legacy_Id__c = '60000000';
        accList.add(legacyacct);

        Account tempacct = APT_TestUtils.createOrganisation();
        tempacct.Legacy_Id__c = '60000000';
        accList.add(tempacct);
        insert accList;

        legacyacct.Legacy_Id__c = '60000000';
        update legacyacct;

        Billing_Account__c billacc = APT_TestUtils.createBillingAccount(tempacct.id);
        billacc.LEGACY_ID__c = '60000000';
        insert billacc;

        Opportunity opp1 = APT_TestUtils.createOpportunity(tempacct.id);
        insert opp1;

        List<Product2> productList = new List<Product2>();
        Product2 product =APT_TestUtils.createInternationalProduct('Road Express - STE','X00','Parcel Services');
        product.APT_Product_Type__c = 'StarTrack';//add product type to product
        product.APT_Product_Lines__c = 'StarTrack';
        product.APT_Contracting_Entity__c = 'StarTrack Express Pty Ltd';
        productList.add(product);

        Product2 product1 =APT_TestUtils.createInternationalProduct('Special Services - STE','X01','Parcel Services');
        product1.APT_Product_Type__c = 'StarTrack';//add product type to product
        product1.APT_Product_Lines__c = 'StarTrack';
        product1.APT_Contracting_Entity__c = 'StarTrack Express Pty Ltd';
        productList.add(product1);

        insert productList;

        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;

        APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(priceList.Id);
        r2tSystemProperties.APT_Org_Id_Service_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
        r2tSystemProperties.APT_CompanyCreditAssessmentEndPointURL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
        r2tSystemProperties.APT_INDV_Credit_Assessment_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
        r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c = 'test@apttus.com1';
        //RecordType rt12 = [SELECT Id,Name FROM RecordType WHERE SobjectType= 'APT_Contract_Fee__c' and DeveloperName = 'Transaction_Fees'];
        r2tSystemProperties.Transaction_Fee_Reord_Type_ID__c = Schema.SObjectType.APT_Contract_Fee__c.getRecordTypeInfosByName().get('Transaction Fees').getRecordTypeId();
        r2tSystemProperties.Name = 'System Properties';
        r2tSystemProperties.APT_ReversalFees__c = Schema.SObjectType.APT_Contract_Fee__c.getRecordTypeInfosByName().get('Card Dishonour and Reversal Fees').getRecordTypeId();
        r2tSystemProperties.APT_Change_Management__c = Schema.SObjectType.APT_Contract_Fee__c.getRecordTypeInfosByName().get('Change Management').getRecordTypeId();
        insert r2tSystemProperties;

        Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id,product.id,'','');
        insert priceListItem;

        Apttus_Proposal__Proposal__c proposal = APT_TestUtils.getQuoteProposal(tempacct.id,opp1.Id,'Proposal','Test',priceList.id);
        proposal.APT_minimum_monthly_spend__c = 1000;
        proposal.Apttus_Proposal__Approval_Stage__c = 'Accepted';
        insert proposal;

        Apttus_Config2__ProductConfiguration__c config =new  Apttus_Config2__ProductConfiguration__c(Name='Sample',Apttus_QPConfig__Proposald__c=proposal.id,Apttus_Config2__PriceListId__c=priceList.id,Apttus_Config2__Status__c = APT_Constants.CONFIGURATION_STATUS_FINALIZED);
        insert config;

        Apttus_Config2__SummaryGroup__c summaryGroup = new Apttus_Config2__SummaryGroup__c (Apttus_Config2__ConfigurationId__c=config.id, Apttus_Config2__ItemSequence__c=78, Apttus_Config2__LineNumber__c=45);
        insert summaryGroup ;

        Apttus_Config2__ProductOptionComponent__c prodOptionComponent = new Apttus_Config2__ProductOptionComponent__c(Apttus_Config2__Sequence__c=2);
        insert prodOptionComponent;

        Apttus_Config2__ClassificationName__c category = new Apttus_Config2__ClassificationName__c(Name='Test',Apttus_Config2__Active__c=true,
                Apttus_Config2__HierarchyLabel__c='High',Apttus_Config2__Type__c='Offering',Apttus_Config2__GuidePage__c='Sample');
        insert category;

        Apttus_Config2__ClassificationHierarchy__c classHierarchy = new Apttus_Config2__ClassificationHierarchy__c(Apttus_Config2__HierarchyId__c=category.id, Apttus_Config2__Label__c='Sample');
        insert classHierarchy ;

        Apttus_Config2__LineItem__c lineItem = APT_TestUtils.getConfigLineItem(config.id,summaryGroup.id  ,1,true,2,'',product.id,false,prodOptionComponent.id,
                product.id,classHierarchy.id,'',2.3,false,'',2,priceList.id,priceListItem.Id,'','','','',
                false,false,22.00,24.00,'',34.00,23.00,33.50,'');
        insert lineItem;
        Apttus_Config2__ProductAttributeValue__c attriObj = new Apttus_Config2__ProductAttributeValue__c(Apttus_Config2__LineItemId__c =lineItem.ID,APT_PostBillPay_Gross_Settlement_fee__c = 'Yes', APT_Monthly_Spend__c=100.00);
        insert attriObj;

        lineItem.Apttus_Config2__AttributeValueId__c = attriObj.ID;
        update lineItem;

        Apttus_Proposal__Proposal_Line_Item__c propLineItem = APT_TestUtils.getProposalLineItem(proposal.Id,lineItem.Id,priceListItem.Id,product.Id,product.Id);
        propLineItem.Apttus_Proposal__Product__c=product.Id;
        propLineItem.Apttus_QPConfig__LineNumber__c =1;
        propLineItem.Apttus_QPConfig__ItemSequence__c=1;
        insert propLineItem;

        User u1 = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name ='System Administrator' and ID != :UserInfo.getUserId()  limit 1];

        List<Apttus__APTS_Agreement__c> agreeList = new List<Apttus__APTS_Agreement__c>();
        Apttus__APTS_Agreement__c aptContract3 = APT_TestUtils.createAgreement(con.Id);
        aptContract3.APT_Product__c= 'Local Pickup and Delivery Services';
        aptContract3.Apttus__Account__c=tempacct.Id;
        aptContract3.RecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
        aptContract3.Apttus_QPComply__RelatedProposalId__c = proposal.ID;
        aptContract3.APT_New_Rate_Card_Download__c = true;
        aptContract3.OwnerId = u1.ID;
        aptContract3.Apttus__Status_Category__c = 'Request';
        aptContract3.Apttus__Status__c = 'Request';
        aptContract3.APT_Contract_Type__c = APT_Constants.CONTRACT_TYPE_NEW_CONTRACT;
        agreeList.add(aptContract3);
        insert agreeList;
    }

    @isTest
    public static void testMethodInsert(){
        Apttus__APTS_Agreement__c oAgreement = [SELECT ID FROM Apttus__APTS_Agreement__c LIMIT 1];

        List<APT_DoV_Language__c> ListOfDoVLanguage = new List<APT_DoV_Language__c>();
        
        APT_DoV_Language__c oDoVLanguage1 = new APT_DoV_Language__c();
        oDoVLanguage1.APT_Contract__c = oAgreement.Id;
        oDoVLanguage1.APT_DoV_Action__c = 'Add';
        oDoVLanguage1.APT_DoV_Details__c = 'As detailed below';
        oDoVLanguage1.APT_DoV_Product__c = 'Post Billpay';
        oDoVLanguage1.APT_DOV_Reason__c = 'Add new products';
        oDoVLanguage1.APT_DoV_Type__c = 'Open Ended';
        ListOfDoVLanguage.add(oDoVLanguage1);

        APT_DoV_Language__c oDoVLanguage2 = new APT_DoV_Language__c();
        oDoVLanguage2.APT_Contract__c = oAgreement.Id;
        oDoVLanguage2.APT_DoV_Action__c = 'Replace';
        oDoVLanguage2.APT_DoV_Details__c = 'As detailed below';
        oDoVLanguage2.APT_DoV_Product__c = 'Returns';
        oDoVLanguage2.APT_DOV_Reason__c = 'Add new products';
        oDoVLanguage2.APT_DoV_Type__c = 'Open Ended';
        ListOfDoVLanguage.add(oDoVLanguage2);

        Test.startTest();
        insert ListOfDoVLanguage;
        Apttus__APTS_Agreement__c oAgreement1 = [SELECT ID,APT_DOV_Language__c FROM Apttus__APTS_Agreement__c LIMIT 1];
        System.assertEquals('Returns - Replace;Post Billpay - Add',oAgreement1.APT_DOV_Language__c);
        Test.stopTest();
    }
    @isTest
    public static void testMethodUpdate(){
        Apttus__APTS_Agreement__c oAgreement = [SELECT ID FROM Apttus__APTS_Agreement__c LIMIT 1];

        List<APT_DoV_Language__c> ListOfDoVLanguage = new List<APT_DoV_Language__c>();
        
        Test.startTest();
        APT_DoV_Language__c oDoVLanguage1 = new APT_DoV_Language__c();
        oDoVLanguage1.APT_Contract__c = oAgreement.Id;
        oDoVLanguage1.APT_DoV_Action__c = 'Add';
        oDoVLanguage1.APT_DoV_Details__c = 'As detailed below';
        oDoVLanguage1.APT_DoV_Product__c = 'Post Billpay';
        oDoVLanguage1.APT_DOV_Reason__c = 'Add new products';
        oDoVLanguage1.APT_DoV_Type__c = 'Open Ended';
        ListOfDoVLanguage.add(oDoVLanguage1);
        insert ListOfDoVLanguage;

       
        oDoVLanguage1.APT_DoV_Action__c = 'Replace'; 
        update oDoVLanguage1;
        Test.stopTest();
        Apttus__APTS_Agreement__c oAgreement1 = [SELECT ID,APT_DOV_Language__c FROM Apttus__APTS_Agreement__c LIMIT 1];
        System.assertEquals('Post Billpay - Replace',oAgreement1.APT_DOV_Language__c);
        
    }
}