@isTest
public class APT_ViewratecardBatchTest {

    @TestSetup
    static void makeData(){
        
        Apttus__APTS_Template__c template = new Apttus__APTS_Template__c(name = 'R2T APPC Proposal');
        insert template;

        Account tempacct = APT_TestUtils.createOrganisation();
        insert tempacct;
        
        Contact con= APT_TestUtils.createContact();
        con.Email = 'temp@temp.com';
        con.accountId = tempAcct.Id;
        insert con;

        /* Start: Meet Desa: Replaced createOpportunity with createOpportunityofIdentifyStage */
        Opportunity opp = APT_TestUtils.createOpportunityofIdentifyStage(tempacct.id);
        opp.KeyContact__c = con.Id;
        insert opp;
        /* End: Meet Desa: Replaced createOpportunity with createOpportunityofIdentifyStage */
     
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;
        
        //create international product
        Product2 bundle1 = APT_TestUtils.createDomesticProduct('APPC','APPC','Postal Services','CAT1', 'Standard');
        bundle1.APT_Sync_with_Opportunity__c=true;
        bundle1.APT_Is_Charge_Account_Product__c = true;
        bundle1.APT_Is_Cash_Account_Product__c = false;
        bundle1.APT_Consolidated_Usage_Price_Tiers__c = true;
        bundle1.APT_Product_type__c='Parcel Contract';
        insert bundle1;
        
        //Create Option product
        Product2 option = APT_TestUtils.createDomesticProduct('Eparcel','eParcelStandard','Postal Services','CAT1', 'Standard');
        option.Apttus_Config2__ConfigurationType__c='Option';
        option.APT_Sync_with_Opportunity__c=true;
        option.APT_International_Pricing__c = false;
        option.APT_Consolidated_Usage_Price_Tiers__c = true;
        option.ProductCode = APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE;
        insert option;
        
        //Create PriceBookEntry
        Id pricebookId = Test.getStandardPricebookId();             
        PricebookEntry standardPrice = APT_TestUtils.getPricebookEntry(Test.getStandardPricebookId(),option.ID);            
        insert standardPrice;
        
        //Create Price list Item
        Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
        insert pli;
        
        //Create Proposal
        Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(tempacct.ID,opp.ID,'Proposal','Quote', priceList.ID);
        //proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c = System.Today() - 1;
        Proposal.Expected_Revenue_Start_Date__c = System.Today() - 20;
        Proposal.Apttus_Proposal__Approval_Stage__c = 'Accepted';
        Proposal.Apttus_Proposal__Opportunity__c = opp.Id;
        
        proposal.APT_pricing_fields_changed__c = true; 
        proposal.Apttus_Proposal__Approval_Stage__c = APT_Constants.APPROVAL_STAGE_GENERATED;
        proposal.APT_Proposal_Generated_Date__c = System.Today() - 20;
        proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c = System.Today() - 25;
        insert Proposal;
        
        //Create Product Configuration             
        Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
                                                                                                   proposal.Id, 'Proposal',
                                                                                                   'Ad Hoc',priceList.Id, null,
                                                                                                   'Finalized',
                                                                                                   null, Datetime.now(), true);
        prodconfig.Apttus_Config2__Status__c = 'Finalized';
        insert prodconfig;
        
        //Apttus_Config2__ClassificationName__c
        Apttus_Config2__ClassificationName__c cn = new Apttus_Config2__ClassificationName__c();
        cn.Name = 'test';
        cn.Apttus_Config2__Type__c = 'Option Group';
        cn.Apttus_Config2__HierarchyLabel__c = 'Pricing Products';
        insert cn;
        
        //Apttus_Config2__ClassificationHierarchy__c
        Apttus_Config2__ClassificationHierarchy__c cHierarchy = new Apttus_Config2__ClassificationHierarchy__c();
        cHierarchy.Name = 'test';
        cHierarchy.Apttus_Config2__Label__c = 'Pricing Products';
        cHierarchy.Apttus_Config2__HierarchyId__c = cn.Id;
        insert cHierarchy;
        
        //Apttus_Config2__ProductOptionGroupId__c
        Apttus_Config2__ProductOptionGroup__c pog = new Apttus_Config2__ProductOptionGroup__c();
        pog.Apttus_Config2__Sequence__c = 1;
        pog.Apttus_Config2__ProductId__c = option.ID;
        pog.Apttus_Config2__OptionGroupId__c = cHierarchy.ID;
        insert pog;
        
        //Apttus_Config2__ProductOptionComponent__c
        Apttus_Config2__ProductOptionComponent__c poc = new Apttus_Config2__ProductOptionComponent__c();
        poc.Apttus_Config2__Sequence__c = 1;
        poc.Apttus_Config2__ComponentProductId__c = option.ID;
        poc.Apttus_Config2__ProductOptionGroupId__c = pog.Id;
        insert poc;
        
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
        bundleLine.Apttus_Config2__ParentBundleNumber__c = 1;
        bundleLine.Apttus_Config2__ProductOptionId__c = poc.ID;
        bundleLine.Apttus_Config2__OptionId__c = option.ID;
        insert bundleLine;                  
        
        //Create Proposal Line Item               
        Apttus_Proposal__Proposal_Line_Item__c proposalLT1= APT_TestUtils.getProposalLineItem(Proposal.id,bundleLine.id,pli.id,bundle1.id,option.id);
        proposalLT1.Apttus_QPConfig__Quantity2__c=3;
        proposalLT1.Apttus_QPConfig__NetPrice__c=10;
        proposalLT1.Apttus_QPConfig__IsPrimaryLine__c = true;
        proposalLT1.Apttus_QPConfig__OptionId__c = null;
        proposalLT1.Apttus_QPConfig__ParentBundleNumber__c = 1;
        proposalLT1.Apttus_Proposal__Product__c=bundle1.Id;
        insert proposalLT1;
        
        //Apttus_QPConfig__ProposalUsagePriceTier__c
        Apttus_QPConfig__ProposalUsagePriceTier__c pupt = new Apttus_QPConfig__ProposalUsagePriceTier__c();
        pupt.Apttus_QPConfig__Sequence__c = 1;
        pupt.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
        pupt.Apttus_QPConfig__Dimension1Value__c = 'WG';
        pupt.Apttus_QPConfig__Dimension2Value__c = '0.50';
        pupt.Apttus_QPConfig__Dimension3Value__c = 'Base';
        pupt.Apttus_QPConfig__AdjustmentAmount__c = 100;
        insert pupt;
        
        //create Logdement Zone             
        APT_Lodgement_Zone__c logdZone = APT_TestUtils.getLodgementZone('Aust Antarctic Territory','AAT');
        insert logdZone;               
        
        //Create Feature Pricing              
        APT_Feature_Pricing__c featurePricing = APT_TestUtils.getFeaturePricing('Aust Antarctic Territory','CAT1','AAT','Standard','EPR2',10,1);           
        insert featurePricing;
        
        //Create product Attribute value                
        Apttus_Config2__ProductAttributeValue__c attribute1 = APT_TestUtils.GetAttributeValue(bundleLine.Id,'Standard',false,false,false,'Yes','B Mining',True,True);
        attribute1.Category__c='CAT1';
        attribute1.APT_Lodgement_Zone__c=logdZone.ID;               
        insert attribute1;
        
        Apttus_Config2__UsagePriceTier__c objConfig2UsagePriceTier =  new Apttus_Config2__UsagePriceTier__c();
        objConfig2UsagePriceTier.Apttus_Config2__AdjustmentAmount__c = 0.64;
        objConfig2UsagePriceTier.Apttus_Config2__AdjustmentType__c = 'List Price Override';
        objConfig2UsagePriceTier.Apttus_Config2__Dimension1Value__c = 'WG';
        objConfig2UsagePriceTier.Apttus_Config2__Dimension2Value__c = '0.5';
        objConfig2UsagePriceTier.Apttus_Config2__Dimension3Value__c = 'Per Kg';
        objConfig2UsagePriceTier.Apttus_Config2__Dimension4Value__c = '';
        objConfig2UsagePriceTier.Apttus_Config2__Dimension5Value__c = ''; 
        objConfig2UsagePriceTier.Apttus_Config2__Dimension6Value__c = '231.5';
        objConfig2UsagePriceTier.Apttus_Config2__FlatPrice__c = 234;
        objConfig2UsagePriceTier.Apttus_Config2__Sequence__c = 3;
        objConfig2UsagePriceTier.Apttus_Config2__LineItemId__c = bundleLine.Id;
        insert objConfig2UsagePriceTier;
    }
    static testMethod void testMethod1() 
    {
        
        Apttus_Proposal__Proposal__c proposal = [Select Id from Apttus_Proposal__Proposal__c limit 1];
        Apttus_Config2__ProductConfiguration__c prodConfig = [Select Id from Apttus_Config2__ProductConfiguration__c limit 1];

        Test.startTest();
        
        APT_ViewratecardBatch obj = new APT_ViewratecardBatch(prodConfig.id, proposal.Id, '', '', '', true, 'Parcel Contract');
        //String configId, String proposalId, String sessionId, String serverUrl, String pageUrl, Boolean isCallFromRateCalc, String prodType
        DataBase.executeBatch(obj); 
        
        Test.stopTest();
    }
    
    static testMethod void testMethod2() 
    {
        Apttus_Proposal__Proposal__c proposal = [Select Id from Apttus_Proposal__Proposal__c limit 1];
        Apttus_Config2__ProductConfiguration__c prodConfig = [Select Id from Apttus_Config2__ProductConfiguration__c limit 1];
        
        Test.startTest();
        
        APT_ViewratecardBatch obj = new APT_ViewratecardBatch(prodConfig.id, proposal.Id, '', '', '', false, 'Parcel Contract');
        //String configId, String proposalId, String sessionId, String serverUrl, String pageUrl, Boolean isCallFromRateCalc, String prodType
        DataBase.executeBatch(obj); 
        
        Test.stopTest();
    }
    
    static testMethod void testMethod3() 
    {   
        Product2 lstProduct2 = [Select Id, ProductCode from Product2 limit 1];
        lstProduct2.ProductCode = APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE;
        update lstProduct2;
        Apttus_Proposal__Proposal__c proposal = [Select Id from Apttus_Proposal__Proposal__c limit 1];
        Apttus_Config2__ProductConfiguration__c prodConfig = [Select Id from Apttus_Config2__ProductConfiguration__c limit 1];
        Apttus_Config2__LineItem__c lstConfig2LineItem = [Select Id, Apttus_Config2__ProductId__r.ProductCode from Apttus_Config2__LineItem__c limit 1];
        lstConfig2LineItem.APT_New__c = true;
        lstConfig2LineItem.Apttus_Config2__ProductId__c = lstProduct2.Id;
        update lstConfig2LineItem;
        Apttus_Config2__UsagePriceTier__c lstUsagePriceTier = [Select Id, Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__c, Apttus_Config2__LineItemId__r.Apttus_Config2__OptionId__r.APT_Consolidated_Usage_Price_Tiers__c from Apttus_Config2__UsagePriceTier__c limit 1];
        update lstUsagePriceTier;
        Test.startTest();
        APT_ViewRatecardControllerAPI objViewRatecardControllerAPI = new APT_ViewRatecardControllerAPI(lstConfig2LineItem.id,APT_Constants.BOOLEAN_TRUE,APT_Constants.BOOL_TRUE);
  
        objViewRatecardControllerAPI.init();
        APT_ViewratecardBatch obj = new APT_ViewratecardBatch(prodConfig.id, proposal.Id, '', '', '', false, 'Parcel Contract');
        //String configId, String proposalId, String sessionId, String serverUrl, String pageUrl, Boolean isCallFromRateCalc, String prodType
        DataBase.executeBatch(obj); 
        
        Test.stopTest();
    }

}