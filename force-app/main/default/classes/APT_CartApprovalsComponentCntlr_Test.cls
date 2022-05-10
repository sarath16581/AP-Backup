/**
Created By - Yukti Jain
Created Date - 22nd Feb, 2016
Last Modified By -madhuri.awasthi@auspost.com.au REQ2723568: Text Class changes
Last Modified Date -11th Feb 2022 
2022-02-11  REQ2723568: API version 52 upgrade
**/
@isTest
private class APT_CartApprovalsComponentCntlr_Test {
    static testmethod void testBatch () {
        test.startTest();
        APT_CartApprovalsComponentController objCls = new APT_CartApprovalsComponentController();
        objCls.getLineItemSO();
        
        //Create Account
        Account acc = APT_TestUtils.createOrganisation();
        acc.Type = 'Charge Account + Sub Account';
        acc.ACN__c = '123456789';
        insert acc;
        
        //Create Opportunity
        Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
        opty.Amount = 100;
        insert opty;
        
        //Create PriceList
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;
        
        //create international product
        Product2 bundle1 = APT_TestUtils.createInternationalProduct('International Bundle','APOST001','Postal Services');
        insert bundle1;
        
        //Create Price list Item
        Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
        insert pli;
        
        //Create Proposal
        Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
        Proposal.Apttus_Proposal__Account__c = acc.ID;
        insert Proposal;
        
        //Create Product Configuration             
        Apttus_Config2__ProductConfiguration__c config =new Apttus_Config2__ProductConfiguration__c(Name='Sample',Apttus_QPConfig__Proposald__c=Proposal.id,Apttus_Config2__PriceListId__c=priceList.id);
        insert config;
        
        // Create LineItem
        Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(config.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
        1, 'Product/Service', bundle1.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
        null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
        'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
        'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
        true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
        5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
        bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
        bundleLine.Apttus_Config2__NetPrice__c = 5225;
        bundleLine.Apttus_Config2__PrimaryLineNumber__c = 1;
        bundleLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
        insert bundleLine; 
        
        Apttus_Approval__Approval_Request__c appReq = new Apttus_Approval__Approval_Request__c();
        appReq.Apttus_CQApprov__CartId__c = config.Id;
        appReq.Apttus_Approval__Approver_Comments__c = 'Reassigned with comments - Test \n Test';
        
        objCls.approvalRequestSO = appReq;
        objCls.lineItemSOId = bundleLine.id;
        objCls.getLineItemSO();
        
        String cartSOId = config.ID;
        system.assertEquals(cartSOId ,config.ID);
        
        Apttus_Config2__ConfigSystemProperties__c configSystemProperties = new Apttus_Config2__ConfigSystemProperties__c();
        configSystemProperties.Name = 'System Properties';
        configSystemProperties.Apttus_Config2__InstanceUrl__c = 'https://auspost--devr2t.cs5.my.salesforce.com';
        insert configSystemProperties;
        objCls.cartSOId = cartSOId;
         
        //objCls.getConfigurationURL();
        objCls.getProposalURL();
        objCls.getOpportunityURL();
        objCls.getAccountURL();
        objCls.getApprovalRequestURL();
        objCls.getLineItems();
        objCls.getdelegateComments();
        test.stopTest();
    }
}