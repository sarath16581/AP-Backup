/***
 * @author kalpita
 * @date 2018-10-24
 * @group 
 * @description Test class for APT_ImportController.
 * @changelog
 * 2016-06-23 - Kalpita - Created
 * 2018-10-24 - Kalpita - updated the code to have test data creation and actual test run in seperate scopes to avoid governor limits 
 * 2021-11-17 - Mathew Jose - Fixing the test method failures created by the introduction of key contact lookup filter on Opportuntiy (CI-194)
 * 2022-02-11  REQ2723568: API version 52 upgrade
*/

@isTest
private with sharing class APT_ImportControllerTest {

    public static testmethod void testAPT_ImportController(){
        Test.startTest();
        
        Account acc = new Account();
        acc.NAME = 'test acc';
        insert acc;
        
        Id rtID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
        Apttus__APTS_Agreement__c agmt = new Apttus__APTS_Agreement__c();
        agmt.Name = 'Apttus Test';
        agmt.Apttus__Status_Category__c = 'In Signatures';
        agmt.Apttus__Status__c = 'Other Party Signatures';
        agmt.Apttus__Account__c = acc.ID;
        if(rtID != null)
        agmt.RecordTypeId = rtID;
        insert agmt;
        
        ApexPages.StandardController stdImp = new ApexPages.StandardController(agmt);
        APT_ImportController objAPTSImportCtrl = new APT_ImportController(stdImp);
        
        system.assertEquals(objAPTSImportCtrl.agreementId==agmt.Id,true);
        
        PageReference pageRef =  objAPTSImportCtrl.doThirdParty();
        system.assertEquals(pageRef!=null,true);
        
        pageRef =  objAPTSImportCtrl.doPartiallySigned();
        //system.assertEquals(pageRef!=null,true);
        
        pageRef =  objAPTSImportCtrl.doFullySigned();
        //system.assertEquals(pageRef!=null,true);
        
        objAPTSImportCtrl.doCancel();
        PageReference pagRf = new PageReference('/'+objAPTSImportCtrl.agreementId);
        //system.assertEquals(pageRef.getUrl()==pagRf.getURl(),true);
         
        Test.stopTest();
         
    }
    public static testmethod void testAPT_ImportController1(){
        
        
        Account acc1 = new Account();
        acc1.NAME = 'test acc';
        insert acc1;
        
        Id rtID1 = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
        Apttus__APTS_Agreement__c agmt1 = new Apttus__APTS_Agreement__c();
        agmt1.Name = 'Apttus Test1';
        agmt1.Apttus__Status_Category__c = 'Request';
        agmt1.Apttus__Status__c = 'Signature Declined';
        //agmt1.APT_Submit_to_Contract_Consulting_Team__c = false;
        agmt1.Apttus__Account__c = acc1.ID;
        agmt1.Apttus__Contract_End_Date__c = System.Today() + 100;
        if(rtID1 != null)
        agmt1.RecordTypeId = rtID1;
        insert agmt1;
        
        ApexPages.StandardController stdImp1 = new ApexPages.StandardController(agmt1);
        APT_ImportController objAPTSImportCtrl1 = new APT_ImportController(stdImp1);
        Test.startTest();
        objAPTSImportCtrl1.doFullySigned();
        PageReference pageRef =  objAPTSImportCtrl1.doThirdParty();
        agmt1.Apttus__Status_Category__c = 'Request';
        update agmt1;
        pageRef =  objAPTSImportCtrl1.doLegacy();
        
        ID agreeId = objAPTSImportCtrl1.agreementId;
        Apttus__APTS_Agreement__c agreement = [Select Apttus__Status_Category__c, Apttus__Status__c From Apttus__APTS_Agreement__c Where Id = :agreeId];
        system.assertEquals(agreement.Apttus__Status__c ,'Author Contract');
        
        Test.stopTest();
    }
    public static testmethod void testAPT_ImportController2(){
        Account acc = new Account();
        acc.NAME = 'test acc';
        insert acc;
        
        Opportunity opp = APT_TestUtils.createOpportunity(acc.id);
        insert opp;
        
        Contact con = APT_TestUtils.createContact();
        insert con;
        
        //Create PriceList
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;
        
        //Domestic (non startrack) product
        Product2 productCAT1STD = APT_TestUtils.createDomesticProduct('CAT1 Standard', 'CAT1Standard', 'Parcel Services', 'CAT1', 'STANDARD');
        productCAT1STD.APT_Domestic_Pricing__c = true;
        productCAT1STD.APT_Product_Lines__c = 'eParcels Domestic;';
        productCAT1STD.APT_Product_type__c = 'eParcels Domestic';
        insert productCAT1STD;
        
		//Create price list item
        Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id,productCAT1STD.id,'','');
        insert priceListItem;        
        
        //Create Proposal
        Apttus_Proposal__Proposal__c Proposal1= APT_TestUtils.getQuoteProposal(acc.id,opp.id,'Proposal','Quote', priceList.id);
        Proposal1.Apttus_Proposal__Approval_Stage__c='Accepted';
        //Proposal1.APT_Method_of_Payment__c = 'None';
        insert Proposal1;
		
        //Create Apttus records to facilitate the creation of proposal line items
        //This is required to work around the issue with Included Product lines missing on the Agreement.
        //Which was resulting in the test class to fail since the DSR creation flow from Contract was failing.
        Apttus_Config2__ProductConfiguration__c config =new  Apttus_Config2__ProductConfiguration__c(Name='Sample',Apttus_QPConfig__Proposald__c=Proposal1.id,Apttus_Config2__PriceListId__c=priceList.id,Apttus_Config2__Status__c = APT_Constants.CONFIGURATION_STATUS_FINALIZED);
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

        Apttus_Config2__LineItem__c lineItem = APT_TestUtils.getConfigLineItem(config.id,summaryGroup.id  ,1,true,2,'',productCAT1STD.id,false,prodOptionComponent.id,
                productCAT1STD.id,classHierarchy.id,'',2.3,false,'',2,priceList.id,priceListItem.Id,'','','','',
                false,false,22.00,24.00,'',34.00,23.00,33.50,'');
        insert lineItem;
        Apttus_Config2__ProductAttributeValue__c attriObj = new Apttus_Config2__ProductAttributeValue__c(Apttus_Config2__LineItemId__c =lineItem.ID,APT_PostBillPay_Gross_Settlement_fee__c = 'Yes', APT_Monthly_Spend__c=100.00);
        insert attriObj;

        lineItem.Apttus_Config2__AttributeValueId__c = attriObj.ID;
        update lineItem;

        Apttus_Proposal__Proposal_Line_Item__c propLineItem = APT_TestUtils.getProposalLineItem(proposal1.Id,lineItem.Id,priceListItem.Id,productCAT1STD.Id,productCAT1STD.Id);
        propLineItem.Apttus_Proposal__Product__c=productCAT1STD.Id;
        propLineItem.Apttus_QPConfig__LineNumber__c =1;
        propLineItem.Apttus_QPConfig__ItemSequence__c=1;
        insert propLineItem;        
        //Creating agreement.        
        Id rtID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
        Apttus__APTS_Agreement__c agmt = new Apttus__APTS_Agreement__c();
        agmt.Name = 'Apttus Test';
        agmt.ownerid = userinfo.getUserid();
        agmt.Apttus__Primary_Contact__c = con.id;
        agmt.Apttus__Agreement_Category__c = 'Standard';
        agmt.Apttus__Status_Category__c = 'In Signatures';
        agmt.Apttus__Status__c = 'Other Party Signatures';
        agmt.Apttus__Other_Party_Signed_By__c = con.id;
        agmt.Termination_Notice_Period__c = '30';
        agmt.APT_Pricing_Category__c = 'Standard';
        agmt.Apttus__Subtype__c = 'Short Form';
        agmt.Term__c = 'Fixed Term';
        agmt.APT_Contract_Type__c = 'New Contract';
        agmt.Apttus__Contract_Start_Date__c = date.Today();
        agmt.APT_Contracting_Entity1__c = 'Australian Postal Corporation';
        agmt.Apttus__Related_Opportunity__c = opp.id;
        agmt.Apttus_QPComply__RelatedProposalId__c = Proposal1.Id;
        agmt.APT_Trading_As__c = 'None';
        agmt.Apttus__Account__c = acc.ID;
        if(rtID != null)
        agmt.RecordTypeId = rtID;
        insert agmt;
        
        Test.startTest();
        
            ApexPages.StandardController stdImp = new ApexPages.StandardController(agmt);
            APT_ImportController objAPTSImportCtrl = new APT_ImportController(stdImp);
            
            objAPTSImportCtrl.apiSessionId = '';
            objAPTSImportCtrl.apiServerURL  = '';
            objAPTSImportCtrl.output_text_Value = '';
            
            PageReference pageRef =  objAPTSImportCtrl.doThirdParty();
            pageRef =  objAPTSImportCtrl.doFullySigned();
            pageRef =  objAPTSImportCtrl.doPartiallySigned();
            // Commented out by Adrian Recio, temporary fix to avoid the soql 101 limit
            //pageRef =  objAPTSImportCtrl.doLegacy();
            system.assertEquals(pageRef!=null,true);
            
        test.stopTest();
    }
}