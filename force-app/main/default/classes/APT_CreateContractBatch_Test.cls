/**
Description - 
Created By - Aakash Khatri
Created Date - 23rd June, 2016
***************************************
@ModifiedBy: Meet Desai
@ModifiedOn: 12 Mar, 2020
@Description: Updated Merge Documents logic to refer Files/ Content Documents instead of Attachments
 */
 
@isTest
private class APT_CreateContractBatch_Test {
    
    private static TestMethod void testMethod1() {
        
        //create price list
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;
        
        //APT_R2T_International_Pricing_Properties__c
        APT_R2T_International_Pricing_Properties__c r2tInternationalPricingProperties = new APT_R2T_International_Pricing_Properties__c();
        r2tInternationalPricingProperties.Name = 'R2T International Pricing Properties';
        r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c = 'Standard Price';
        
        insert r2tInternationalPricingProperties;
        
        //create R2T System Properties
        APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(priceList.Id);
        r2tSystemProperties.APT_Org_Id_Service_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
        r2tSystemProperties.APT_CompanyCreditAssessmentEndPointURL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
        r2tSystemProperties.APT_INDV_Credit_Assessment_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
        r2tSystemProperties.APT_Query_Rate_Card_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
        r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c = 'temp@temp.com';
        r2tSystemProperties.APT_Sync_Contract_Rate_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
        
        insert r2tSystemProperties;
        
        Apttus__ComplySystemProperties__c complySystemProperties = new Apttus__ComplySystemProperties__c();
        complySystemProperties.Name = 'System Properties';
        complySystemProperties.Apttus__InstanceUrl__c = 'https://auspost--devr2t.cs5.my.salesforce.com';
        insert complySystemProperties;
        
        Contact con= APT_TestUtils.createContact();
        con.Email = 'temp@temp.com';
        insert con;
        
        Account acc = APT_TestUtils.createOrganisation();
        insert acc;
        
        Opportunity opp = APT_TestUtils.createOpportunity(acc.id);
        opp.KeyContact__c = con.Id;
        opp.Stagename = 'Identify';
        insert opp;
        
        User u = [SELECT Id,Name,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
        
        //create international product
        Product2 bundle1 = APT_TestUtils.createDomesticProduct('International Bundle','eParcelStandard','Postal Services','CAT1', 'Standard');
        bundle1.APT_Sync_with_Opportunity__c=true;
        bundle1.APT_Is_Charge_Account_Product__c = true;
        bundle1.APT_Is_Cash_Account_Product__c = false;
        insert bundle1;
        
        Product2 option2 = APT_TestUtils.createDomesticProduct('International Bundle','eParcelIdentityonDeliveryService','Postal Services','CAT1', 'Standard');
        option2.Apttus_Config2__ConfigurationType__c='Option';
        option2.APT_Sync_with_Opportunity__c=true;
        option2.APT_International_Pricing__c = false;
        option2.APT_Domestic_Pricing__c = true;
        insert option2;
        
        //Create Price list Item
        Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
        insert pli;
        
        //create proposal
        Apttus_Proposal__Proposal__c proposal= APT_TestUtils.getQuoteProposal(acc.ID,opp.ID,'Proposal','Quote', priceList.ID);
        proposal.Expected_Revenue_Start_Date__c = System.Today() - 20;
        proposal.Apttus_Proposal__Approval_Stage__c = 'Accepted';
        proposal.Apttus_Proposal__Opportunity__c = opp.Id;
        insert proposal;
        
        set<Id> proposalIdSet = new set<Id>();
        proposalIdSet.add(proposal.Id);
        system.assert(proposalIdSet.size() > 0);
        
        //Create Product Configuration             
        Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
        proposal.Id, 'Proposal',
        'Ad Hoc',priceList.Id, null,
        'Finalized',
        null, Datetime.now(), true);
        prodconfig.Apttus_Config2__Status__c = 'Finalized';
        insert prodconfig;
        
        // Create LineItem
        Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.id, null, 1, true,//Config id, grpid, LineNum, isPrimary
        1, 'Product/Service', bundle1.id, true, null,//ItemSeq, lineType, bundleid, customizable, productOptionid
        null, null, null, 1, true,//optionid, class id, class hierarchy, qty, qty Modifiable 
        'Each', 1, priceList.id, pli.id,//Uom, term, priceList, Pli,
        'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
        true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
        5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
        bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
        bundleLine.Apttus_Config2__NetPrice__c = 5225;
        bundleLine.Apttus_Config2__PrimaryLineNumber__c = 1;
        bundleLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
        insert bundleLine;
        
        
        //Create Product Attribute value
        Apttus_Config2__ProductAttributeValue__c prntpav = APT_TestUtils.GetAttributeValue(bundleLine.Id,'High',true,true,true,'5674','Industry',true,true);
        prntpav.APT_Min_Transit_Cover_Amount_Per_Article__c = 45.4;
        prntpav.APTS_Price_Structure__c = 'BANDED {Z30}';
        insert prntpav;
        
        bundleLine.Apttus_Config2__AttributeValueId__c = prntpav.Id;
        update bundleLine;
        
        //create proposal Lineitem
        Apttus_Proposal__Proposal_Line_Item__c proposalLineItem = APT_TestUtils.getProposalLineItem(proposal.ID, bundleLine.ID, pli.Id, bundle1.Id, option2.ID);
        insert proposalLineItem;
        
        Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
        aptContract.APT_Product__c= 'eParcel' ;
        aptContract.Apttus__Related_Opportunity__c=opp.Id;
        aptContract.Apttus__Account__c=acc.Id;
        aptContract.RecordType = [Select Id From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'SecurePay Online Payments' Limit 1];
        aptContract.RecordType.DeveloperName = 'SecurePay Online Payments';
        aptContract.Ownerid=u.id;
        aptContract.Apttus__Status__c = 'Fully Signed';
        aptContract.Apttus_QPComply__RelatedProposalId__c = proposal.ID;
        aptContract.APT_New_Rate_Card_Download__c = true;
        
        Test.StartTest();
        insert aptContract;
        Test.StopTest();
        
         List<Id> templateIdSet = new List<ID>();
         
        //create templates
        Apttus__APTS_Template__c template = new Apttus__APTS_Template__c();
        template.Name = 'testtemplate';
        template.Apttus__Category__c = 'Default';
        insert template;
        templateIdSet.add(template.ID);
        
        Apttus__APTS_Template__c template2 = new Apttus__APTS_Template__c();
        template2.Name = 'testtemplate2';
        template2.Apttus__Category__c = 'Default';
        insert template2;
        templateIdSet.add(template2.ID);
        
        /* Start: Meet Desai: Created Content Version Records */
        List<ContentVersion> contentVersionList = new List<ContentVersion>();
        
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'testtemplate';
        contentVersion.PathOnClient = 'testtemplate.pdf';
    	contentVersion.VersionData = Blob.valueOf('Test Content');
        contentVersion.IsMajorVersion = true;
       	contentVersionList.add(contentVersion);
        
        insert contentVersionList;
        /* End: Meet Desai: Created Content Version Records */
        
        /* Start: Meet Desai: Created Content Document Link Records */
        List<ContentDocumentLink> contentDocumentLinkList = new List<ContentDocumentLink>();
        List<ContentDocument> contentDocumentList = [select Id from ContentDocument];
        
        for (ContentDocument contentDocument : contentDocumentList){
            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.LinkedEntityId = aptContract.Id;
            contentDocumentLink.ContentDocumentId = contentDocument.Id;
            contentDocumentLinkList.Add(contentDocumentLink);
        }
        
        insert contentDocumentLinkList;
        /* End: Meet Desai: Created Content Document Link Records */
        
        Apttus__AsyncMergeCall__c asyncmergecall = new Apttus__AsyncMergeCall__c();
        asyncmergecall.Apttus__Agreement__c = aptContract.ID;
        /* Start: Meet Desai: Updated "Apttus__Result__c" with ContentDocumentId instead of TemplateId */
        asyncmergecall.Apttus__Result__c = [select Id from ContentDocument].Id;
        /* End: Meet Desai: Updated "Apttus__Result__c" with ContentDocumentId instead of TemplateId */
        asyncmergecall.Apttus__Status__c = 'Completed';
        insert asyncmergecall;
        
        aptContract.APT_Submitted_Async_Merge_Call_Ids__c = asyncmergecall.ID;
        aptContract.APT_Template_Order_Sequence__c = template.ID;
        aptContract.APT_Merge_Documents__c = true;
        update aptContract;
        
        //create Apttus__Agreement_Protection__c
        Apttus__Agreement_Protection__c ap1 = new Apttus__Agreement_Protection__c();
        ap1.Apttus__Protection_Level__c = 'Full access';
        ap1.Apttus__Protection_Type__c = 'Automatic';
        insert ap1;
        
        map<Id, String> templatepLevelMap = new map<Id, String>();
        templatepLevelMap.put(template.ID, ap1.Id);
        templatepLevelMap.put(template2.Id, ap1.Id);
        
        //create Apttus__Document_Output_Format__c
        Apttus__Document_Output_Format__c dofc = new Apttus__Document_Output_Format__c();
        dofc.Name = 'testformat';
        dofc.Apttus__Output_Format__c = 'PDF';
        dofc.Apttus__AllowOverrideWatermark__c = true;
        insert dofc;
        
        map<Id, String> templateOutputFormatMap = new map<ID, String>();
        templateOutputFormatMap.put(template.Id, dofc.ID);
        templateOutputFormatMap.put(template2.Id, dofc.ID);
        try {
        APT_CreateContractBatch ccb = new APT_CreateContractBatch(aptContract.ID, templateIdSet, templatepLevelMap, templateOutputFormatMap, true, true);
        
        
            Database.executeBatch(ccb);
        }catch (Exception ex) {
            System.debug(ex.getMessage());
        }
    }
    
}