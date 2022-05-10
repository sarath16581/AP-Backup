/***
 * @author Aakash Khatri
 * @date 2016-06-22
 * @group 
 * @description This class is test class for APT_UpdateProposalUsagePriceTierBatch.
 * @changelog
 * 2016-06-22 - Aakash Khatri - Created
 * 2021-11-17 - Mathew Jose - Fixing the test method failures created by the introduction of key contact lookup filter on Opportuntiy (CI-194)
 * 2022-02-11  REQ2723568: API version 52 upgrade
*/
 
@isTest
private class APT_UpdateProposalUsagePriceTest {
    
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

        Account acc = APT_TestUtils.createOrganisation();
        insert acc;

        Contact con= APT_TestUtils.createContact();
        con.Email = 'temp@temp.com';
        //Applying the following change as key contact have look up filter introduced on Opportunity (CI-194).  
        con.AccountId = acc.Id;
        insert con;
                
        Opportunity opp = APT_TestUtils.createOpportunity(acc.id);
        opp.KeyContact__c = con.Id;
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
        
        
        //Apttus_QPConfig__ProposalProductAttributeValue__c
        Apttus_QPConfig__ProposalProductAttributeValue__c ppav = APT_TestUtils.getProposalProductAttributeValue(proposalLineItem.Id);
        ppav.APTS_Price_Structure__c = 'BANDED {Z30}';
        insert ppav;
        
        proposalLineItem.Apttus_QPConfig__AttributeValueId__c = ppav.ID;
        update proposalLineItem;
        
        APT_Charge_Code__c chargecode = new APT_Charge_Code__c();
        chargecode.APT_Price_Structure__c = 'BANDED {Z30}';
        chargecode.APT_Network_Type__c = 'Standard';
        chargecode.APT_Weight_Measure__c = 'CUBIC';
        insert chargecode;
        
        //create APT_Line_Item_Rate_Card__c
        APT_Line_Item_Rate_Card__c lirc = new APT_Line_Item_Rate_Card__c();
        //lirc.Name = 'test';
        lirc.APT_Proposal_Line_Item__c = proposalLineItem.ID;
        lirc.APT_Value_1__c = 'WG';
        lirc.APT_Value_14__c = '50';
        insert lirc;
        
        //Apttus_QPConfig__ProposalUsagePriceTier__c
        Apttus_QPConfig__ProposalUsagePriceTier__c pupt = new Apttus_QPConfig__ProposalUsagePriceTier__c();
        pupt.Apttus_QPConfig__Sequence__c = 1;
        pupt.Apttus_QPConfig__LineItemId__c = proposalLineItem.ID;
        pupt.Apttus_QPConfig__Dimension1Value__c = 'WG';
        pupt.Apttus_QPConfig__Dimension2Value__c = '100';
        pupt.Apttus_QPConfig__Dimension3Value__c = 'Base';
        pupt.Apttus_QPConfig__AdjustmentAmount__c = 100;
        insert pupt;
        
        //Apttus_QPConfig__ProposalUsagePriceTier__c
        Apttus_QPConfig__ProposalUsagePriceTier__c pupt1 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
        pupt1.Apttus_QPConfig__Sequence__c = 1;
        pupt1.Apttus_QPConfig__LineItemId__c = proposalLineItem.ID;
        pupt1.Apttus_QPConfig__Dimension1Value__c = 'WG';
        pupt1.Apttus_QPConfig__Dimension2Value__c = '22';
        pupt1.Apttus_QPConfig__Dimension3Value__c = 'Base';
        pupt1.Apttus_QPConfig__AdjustmentAmount__c = 100;
        insert pupt1;
        
        //create APT_R2T_Weight_Field_Mapping__c
        APT_R2T_Weight_Field_Mapping__c r2tWeightFieldMapping = new APT_R2T_Weight_Field_Mapping__c();
        r2tWeightFieldMapping.Name = 'BANDED {Z30}';
        r2tWeightFieldMapping.APT_Weight_Field__c = 'Value 4,Value 5,Value 6,Value 7,Value 8,Value 9,Value 10,Value 11,Value 12,Value 13,Value 14,Value 15';
        r2tWeightFieldMapping.APT_Weight_Value__c = '0.5,1,2,3,4,5,7,10,15,22,>22+Base,>22+Per Kg,22+Base,22+Subsequent,22+Per Kg';
        insert r2tWeightFieldMapping;
        
        APT_UpdateProposalUsagePriceTierBatch upuptb = new APT_UpdateProposalUsagePriceTierBatch(proposalIdSet);
        Database.executeBatch(upuptb);
    }
    
    private static TestMethod void testMethod2() {
        
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
        
        Account acc = APT_TestUtils.createOrganisation();
        insert acc;

        Contact con= APT_TestUtils.createContact();
        con.Email = 'temp@temp.com';
        //Applying the following change as key contact have look up filter introduced on Opportunity.  
        con.AccountId = acc.Id;
        insert con;        
        
        Opportunity opp = APT_TestUtils.createOpportunity(acc.id);
        opp.KeyContact__c = con.Id;
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
        
        //create APT_Line_Item_Rate_Card__c
        APT_Line_Item_Rate_Card__c lirc = new APT_Line_Item_Rate_Card__c();
        //lirc.Name = 'test';
        lirc.APT_Proposal_Line_Item__c = proposalLineItem.ID;
        lirc.APT_Value_1__c = 'WG';
        lirc.APT_Value_14__c = '50';
        lirc.APT_Value_15__c = '60';
        insert lirc;
        
        //Apttus_QPConfig__ProposalUsagePriceTier__c
        Apttus_QPConfig__ProposalUsagePriceTier__c pupt = new Apttus_QPConfig__ProposalUsagePriceTier__c();
        pupt.Apttus_QPConfig__Sequence__c = 1;
        pupt.Apttus_QPConfig__LineItemId__c = proposalLineItem.ID;
        pupt.Apttus_QPConfig__Dimension1Value__c = 'WG';
        pupt.Apttus_QPConfig__Dimension2Value__c = '100';
        pupt.Apttus_QPConfig__Dimension3Value__c = 'Base';
        pupt.Apttus_QPConfig__AdjustmentAmount__c = 100;
        insert pupt;
        
        //Apttus_QPConfig__ProposalUsagePriceTier__c
        Apttus_QPConfig__ProposalUsagePriceTier__c pupt1 = new Apttus_QPConfig__ProposalUsagePriceTier__c();
        pupt1.Apttus_QPConfig__Sequence__c = 1;
        pupt1.Apttus_QPConfig__LineItemId__c = proposalLineItem.ID;
        pupt1.Apttus_QPConfig__Dimension1Value__c = 'WG';
        pupt1.Apttus_QPConfig__Dimension2Value__c = '22';
        pupt1.Apttus_QPConfig__Dimension3Value__c = 'Base';
        pupt1.Apttus_QPConfig__AdjustmentAmount__c = 100;
        insert pupt1;
        
        //create APT_R2T_Weight_Field_Mapping__c
        APT_R2T_Weight_Field_Mapping__c r2tWeightFieldMapping = new APT_R2T_Weight_Field_Mapping__c();
        r2tWeightFieldMapping.Name = 'BANDED {Z30}';
        r2tWeightFieldMapping.APT_Weight_Field__c = 'Value 4,Value 5,Value 6,Value 7,Value 8,Value 9,Value 10,Value 11,Value 12,Value 13,Value 14,Value 15';
        r2tWeightFieldMapping.APT_Weight_Value__c = '0.5,1,2,3,4,5,7,10,15,22,22+Base,22+Subsequent,22+Per Kg';
        insert r2tWeightFieldMapping;
        
        APT_UpdateProposalUsagePriceTierBatch upuptb = new APT_UpdateProposalUsagePriceTierBatch(proposalIdSet);
        Database.executeBatch(upuptb);
    }
    
    private static TestMethod void testMethod3() {
        
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
        
        Account acc = APT_TestUtils.createOrganisation();
        insert acc;

        Contact con= APT_TestUtils.createContact();
        con.Email = 'temp@temp.com';
        //Applying the following change as key contact have look up filter introduced on Opportunity (CI-194).  
        con.AccountId = acc.Id;
        insert con;        
        
        Opportunity opp = APT_TestUtils.createOpportunity(acc.id);
        opp.KeyContact__c = con.Id;
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
        
        //create APT_Line_Item_Rate_Card__c
        APT_Line_Item_Rate_Card__c lirc = new APT_Line_Item_Rate_Card__c();
        //lirc.Name = 'test';
        lirc.APT_Proposal_Line_Item__c = proposalLineItem.ID;
        lirc.APT_Value_1__c = 'WG';
        lirc.APT_Value_14__c = '50';
        lirc.APT_Value_15__c = '60';
        insert lirc;
        
        //Apttus_QPConfig__ProposalUsagePriceTier__c
        Apttus_QPConfig__ProposalUsagePriceTier__c pupt = new Apttus_QPConfig__ProposalUsagePriceTier__c();
        pupt.Apttus_QPConfig__Sequence__c = 1;
        pupt.Apttus_QPConfig__LineItemId__c = proposalLineItem.ID;
        pupt.Apttus_QPConfig__Dimension1Value__c = 'WG';
        pupt.Apttus_QPConfig__Dimension2Value__c = '100';
        pupt.Apttus_QPConfig__Dimension3Value__c = 'Subsequent';
        pupt.Apttus_QPConfig__AdjustmentAmount__c = 100;
        insert pupt;
        
        //create APT_R2T_Weight_Field_Mapping__c
        APT_R2T_Weight_Field_Mapping__c r2tWeightFieldMapping = new APT_R2T_Weight_Field_Mapping__c();
        r2tWeightFieldMapping.Name = 'BANDED {Z30}';
        r2tWeightFieldMapping.APT_Weight_Field__c = 'Value 4,Value 5,Value 6,Value 7,Value 8,Value 9,Value 10,Value 11,Value 12,Value 13,Value 14,Value 15';
        r2tWeightFieldMapping.APT_Weight_Value__c = '0.5,1,2,3,4,5,7,10,15,22,22+Base,22+Subsequent,22+Per Kg';
        insert r2tWeightFieldMapping;
        
        APT_UpdateProposalUsagePriceTierBatch upuptb = new APT_UpdateProposalUsagePriceTierBatch(proposalIdSet);
        Database.executeBatch(upuptb);
    }
    
    private static TestMethod void testMethod4() {
        
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
        
        Account acc = APT_TestUtils.createOrganisation();
        insert acc;

        Contact con= APT_TestUtils.createContact();
        con.Email = 'temp@temp.com';
        //Applying the following change as key contact have look up filter introduced on Opportunity (CI-194).  
        con.AccountId = acc.Id;
        insert con;          
        
        Opportunity opp = APT_TestUtils.createOpportunity(acc.id);
        opp.KeyContact__c = con.Id;
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
        
        //create APT_Line_Item_Rate_Card__c
        APT_Line_Item_Rate_Card__c lirc = new APT_Line_Item_Rate_Card__c();
        //lirc.Name = 'test';
        lirc.APT_Proposal_Line_Item__c = proposalLineItem.ID;
        lirc.APT_Value_1__c = 'WG';
        lirc.APT_Value_14__c = '50';
        lirc.APT_Value_15__c = '60';
        insert lirc;
        
        //Apttus_QPConfig__ProposalUsagePriceTier__c
        Apttus_QPConfig__ProposalUsagePriceTier__c pupt = new Apttus_QPConfig__ProposalUsagePriceTier__c();
        pupt.Apttus_QPConfig__Sequence__c = 1;
        pupt.Apttus_QPConfig__LineItemId__c = proposalLineItem.ID;
        pupt.Apttus_QPConfig__Dimension1Value__c = 'WG';
        pupt.Apttus_QPConfig__Dimension2Value__c = '100';
        pupt.Apttus_QPConfig__Dimension3Value__c = 'Per Kg';
        pupt.Apttus_QPConfig__AdjustmentAmount__c = 100;
        insert pupt;
        
        //create APT_R2T_Weight_Field_Mapping__c
        APT_R2T_Weight_Field_Mapping__c r2tWeightFieldMapping = new APT_R2T_Weight_Field_Mapping__c();
        r2tWeightFieldMapping.Name = 'BANDED {Z30}';
        r2tWeightFieldMapping.APT_Weight_Field__c = 'Value 4,Value 5,Value 6,Value 7,Value 8,Value 9,Value 10,Value 11,Value 12,Value 13,Value 14,Value 15';
        r2tWeightFieldMapping.APT_Weight_Value__c = '0.5,1,2,3,4,5,7,10,15,22+Per Kg,22+Per Kg,22+Per Kg,22+Per Kg';
        insert r2tWeightFieldMapping;
        
        APT_UpdateProposalUsagePriceTierBatch upuptb = new APT_UpdateProposalUsagePriceTierBatch(proposalIdSet);
        Database.executeBatch(upuptb);
    }
    
    private static TestMethod void testMethod5() {
        
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

        Account acc = APT_TestUtils.createOrganisation();
        insert acc;

        Contact con= APT_TestUtils.createContact();
        con.Email = 'temp@temp.com';
        //Applying the following change as key contact have look up filter introduced on Opportunity (CI-194).  
        con.AccountId = acc.Id;
        insert con;          
        
        Opportunity opp = APT_TestUtils.createOpportunity(acc.id);
        opp.KeyContact__c = con.Id;
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
        
        //create APT_Line_Item_Rate_Card__c
        APT_Line_Item_Rate_Card__c lirc = new APT_Line_Item_Rate_Card__c();
        //lirc.Name = 'test';
        lirc.APT_Proposal_Line_Item__c = proposalLineItem.ID;
        lirc.APT_Value_1__c = 'WG';
        lirc.APT_Value_14__c = '50';
        lirc.APT_Value_15__c = '60';
        insert lirc;
        
        //Apttus_QPConfig__ProposalUsagePriceTier__c
        Apttus_QPConfig__ProposalUsagePriceTier__c pupt = new Apttus_QPConfig__ProposalUsagePriceTier__c();
        pupt.Apttus_QPConfig__Sequence__c = 1;
        pupt.Apttus_QPConfig__LineItemId__c = proposalLineItem.ID;
        pupt.Apttus_QPConfig__Dimension1Value__c = 'WG';
        pupt.Apttus_QPConfig__Dimension2Value__c = '0.5';
        pupt.Apttus_QPConfig__Dimension3Value__c = 'Subsequent';
        pupt.Apttus_QPConfig__AdjustmentAmount__c = 100;
        insert pupt;
        
        //create APT_R2T_Weight_Field_Mapping__c
        APT_R2T_Weight_Field_Mapping__c r2tWeightFieldMapping = new APT_R2T_Weight_Field_Mapping__c();
        r2tWeightFieldMapping.Name = 'BANDED {Z30}';
        r2tWeightFieldMapping.APT_Weight_Field__c = 'Value 4,Value 5,Value 6,Value 7,Value 8,Value 9,Value 10,Value 11,Value 12,Value 13,Value 14,Value 15';
        r2tWeightFieldMapping.APT_Weight_Value__c = '0.5,1,2,3,4,5,7,10,15,22,22+Base,22+Subsequent,22+Per Kg';
        insert r2tWeightFieldMapping;
        
        APT_UpdateProposalUsagePriceTierBatch upuptb = new APT_UpdateProposalUsagePriceTierBatch(proposalIdSet);
        Database.executeBatch(upuptb);
    }
}