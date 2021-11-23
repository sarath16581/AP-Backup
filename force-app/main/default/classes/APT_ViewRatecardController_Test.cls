/**************************************************
@Name: APT_ViewRatecardController_Test
@ModifiedBy: Meet Desai
@ModifiedOn: 19 March, 2020
@Description: Replaced createOpportunity() function with createOpportunityofIdentifyStage() function
***************************************************/
@isTest
private class APT_ViewRatecardController_Test {

    /*
        This method will create test data for execution of test class
    */
    @testSetup static void setup() {

    }
    public static TestMethod void testMethod1() {

        APT_R2T_System_Properties__c r2tSystemProperties = new APT_R2T_System_Properties__c();
        r2tSystemProperties.Name = 'test';
        r2tSystemProperties.APT_Default_Proposal_Template__c = 'Proposal';
        r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c = 'test@test.com';
        //r2tSystemProperties.APT_ACIC_Request_Product_types__c = 'Worforce Verification';
        insert r2tSystemProperties;

        Contact con= APT_TestUtils.createContact();
        con.Email = 'temp@temp.com';
        insert con;
        
        Account tempacct = APT_TestUtils.createOrganisation();
        insert tempacct;
        
        /* Start: Meet Desa: Replaced createOpportunity with createOpportunityofIdentifyStage */
        Opportunity opp = APT_TestUtils.createOpportunityofIdentifyStage(tempacct.id);
        opp.KeyContact__c = con.Id;
        insert opp;
        /* End: Meet Desa: Replaced createOpportunity with createOpportunityofIdentifyStage */
        
        User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
        
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;
        
        //create international product
        Product2 bundle1 = APT_TestUtils.createDomesticProduct('Eparcel','eParcelStandard','Postal Services','CAT1', 'Standard');
        bundle1.APT_Sync_with_Opportunity__c=true;
        bundle1.APT_Is_Charge_Account_Product__c = true;
        bundle1.APT_Is_Cash_Account_Product__c = false;
        bundle1.APT_Consolidated_Usage_Price_Tiers__c = true;
        bundle1.APT_Product_type__c='eParcels Domestic';
        insert bundle1;
             
        //Create Option product
        Product2 option = APT_TestUtils.createDomesticProduct('Eparcel','eParcelStandard','Postal Services','CAT1', 'Standard');
        option.Apttus_Config2__ConfigurationType__c='Option';
        option.APT_Sync_with_Opportunity__c=true;
        option.APT_International_Pricing__c = false;
        option.APT_Consolidated_Usage_Price_Tiers__c = true;
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
        
        //Apttus_XApps__Application__c
        Apttus_XApps__Application__c app1 = new Apttus_XApps__Application__c();
        app1.Name = 'test App';
        app1.Apttus_XApps__Activated__c = true;
        insert app1;
        
        //APT_App_Setup__c
        APT_App_Setup__c aSetup = new APT_App_Setup__c();
        aSetup.APT_App_Name__c = app1.ID;
        aSetup.Name = 'test';
        aSetup.APT_Is_Presto_App__c = true;
        aSetup.Apt_Product__c = bundle1.ID;
        aSetup.APT_Attribute_Name__c = 'Apttus_Config2__AttributeValueId__c';
        aSetup.APT_Attribute_Value__c = attribute1.ID;
        insert aSetup;
        
        APT_App_Setup__c aSetup2 = new APT_App_Setup__c();
        aSetup2.APT_App_Name__c = app1.ID;
        aSetup2.Name = 'test2';
        aSetup2.APT_Is_Presto_App__c = true;
        aSetup2.Apt_Product__c = bundle1.ID;
        aSetup2.APT_Attribute_Name__c = 'Apttus_Config2__AttributeValueId__c';
        aSetup2.APT_Attribute_Value__c = attribute1.Id;
        //insert aSetup2;
        
        //Apttus_Config2__UsagePriceTier__c
        Apttus_Config2__UsagePriceTier__c upt = new Apttus_Config2__UsagePriceTier__c();
        upt.Apttus_Config2__Sequence__c = 1;
        upt.Apttus_Config2__LineItemId__c = bundleLine.Id;
        insert upt;
        
        Attachment attachment1 = new Attachment();
        attachment1.ParentId = bundleLine.Id;
        attachment1.Name = 'Test';
        attachment1.Body = Blob.valueOf('Test');
        insert attachment1;
        
        ApexPages.currentPage().getHeaders().put('Referer', 'www.ausiepost.org');
        Apexpages.currentPage().getParameters().put('parentRecordID', bundleLine.ID);
        Apexpages.currentPage().getParameters().put('isPrestoMode', 'True');
        system.assert(bundleLine.Id!=null);
        Test.StartTest();
        APT_ViewRatecardControllerAPI vrc = new APT_ViewRatecardControllerAPI();
        vrc.init();
        vrc.doCancel();
        vrc.prestoAPI();
        vrc.redirect(bundleLine.Id);
        
        
        APT_ViewRatecardControllerAPI vrc12 = new APT_ViewRatecardControllerAPI('test','test');
        
        Test.StopTest();
        
    }
    
    public static TestMethod void testMethod2() {

        APT_R2T_System_Properties__c r2tSystemProperties = new APT_R2T_System_Properties__c();
        r2tSystemProperties.Name = 'test';
        r2tSystemProperties.APT_Default_Proposal_Template__c = 'Proposal';
        r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c = 'test@test.com';
        //r2tSystemProperties.APT_ACIC_Request_Product_types__c = 'Worforce Verification';
        insert r2tSystemProperties;

        Contact con= APT_TestUtils.createContact();
        con.Email = 'temp@temp.com';
        insert con;
        
        Account tempacct = APT_TestUtils.createOrganisation();
        insert tempacct;
        
        /* Start: Meet Desa: Replaced createOpportunity with createOpportunityofIdentifyStage */
        Opportunity opp = APT_TestUtils.createOpportunityofIdentifyStage(tempacct.id);
        opp.KeyContact__c = con.Id;
        insert opp;
        /* End: Meet Desa: Replaced createOpportunity with createOpportunityofIdentifyStage */
        
        User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
        
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;
        
        //create international product
        Product2 bundle1 = APT_TestUtils.createDomesticProduct('Eparcel','eParcelStandard','Postal Services','CAT1', 'Standard');
        bundle1.APT_Sync_with_Opportunity__c=true;
        bundle1.APT_Is_Charge_Account_Product__c = true;
        bundle1.APT_Is_Cash_Account_Product__c = false;
        bundle1.APT_Consolidated_Usage_Price_Tiers__c = true;
        bundle1.APT_Product_Type__c ='eParcels Domestic';
        insert bundle1;
             
        //Create Option product
        Product2 option = APT_TestUtils.createDomesticProduct('Eparcel','eParcelStandard','Postal Services','CAT1', 'Standard');
        option.Apttus_Config2__ConfigurationType__c='Option';
        option.APT_Sync_with_Opportunity__c=true;
        option.APT_International_Pricing__c = false;
        option.APT_Consolidated_Usage_Price_Tiers__c = true;
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
        
        //Apttus_XApps__Application__c
        Apttus_XApps__Application__c app1 = new Apttus_XApps__Application__c();
        app1.Name = 'test App';
        app1.Apttus_XApps__Activated__c = true;
        insert app1;
        
        //APT_App_Setup__c
        APT_App_Setup__c aSetup = new APT_App_Setup__c();
        aSetup.APT_App_Name__c = app1.ID;
        aSetup.Name = 'test';
        aSetup.APT_Is_Presto_App__c = true;
        aSetup.Apt_Product__c = bundle1.ID;
        aSetup.APT_Attribute_Name__c = 'Apttus_Config2__AttributeValueId__c';
        aSetup.APT_Attribute_Value__c = attribute1.ID;
        insert aSetup;
        
        APT_App_Setup__c aSetup2 = new APT_App_Setup__c();
        aSetup2.APT_App_Name__c = app1.ID;
        aSetup2.Name = 'test2';
        aSetup2.APT_Is_Presto_App__c = true;
        aSetup2.Apt_Product__c = bundle1.ID;
        aSetup2.APT_Attribute_Name__c = 'Apttus_Config2__AttributeValueId__c';
        aSetup2.APT_Attribute_Value__c = attribute1.Id;
        insert aSetup2;
        
        //Apttus_Config2__UsagePriceTier__c
        Apttus_Config2__UsagePriceTier__c upt = new Apttus_Config2__UsagePriceTier__c();
        upt.Apttus_Config2__Sequence__c = 1;
        upt.Apttus_Config2__LineItemId__c = bundleLine.Id;
        insert upt;
        
        ApexPages.currentPage().getHeaders().put('Referer', 'www.ausiepost.org');
        Apexpages.currentPage().getParameters().put('parentRecordID', bundleLine.ID);
        Apexpages.currentPage().getParameters().put('isPrestoMode', 'True');
        system.assert(bundleLine.Id!=null);
        Test.StartTest();
        APT_ViewRatecardControllerAPI vrc = new APT_ViewRatecardControllerAPI();
        //Try{
            vrc.init();
            vrc.doCancel();
        vrc.prestoAPI(); 
        vrc.redirect(bundleLine.Id);
        //}catch(Exception ex) {
        //    System.debug('*****exception'+ex.getMessage());
        //}
        Test.StopTest();
        
    }
    
    public static TestMethod void testMethod3() {

        APT_R2T_System_Properties__c r2tSystemProperties = new APT_R2T_System_Properties__c();
        r2tSystemProperties.Name = 'test';
        r2tSystemProperties.APT_Default_Proposal_Template__c = 'Proposal';
        r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c = 'test@test.com';
        //r2tSystemProperties.APT_ACIC_Request_Product_types__c = 'Worforce Verification';
        insert r2tSystemProperties;

        Contact con= APT_TestUtils.createContact();
        con.Email = 'temp@temp.com';
        insert con;
        
        Account tempacct = APT_TestUtils.createOrganisation();
        insert tempacct;
        
        /* Start: Meet Desa: Replaced createOpportunity with createOpportunityofIdentifyStage */
        Opportunity opp = APT_TestUtils.createOpportunityofIdentifyStage(tempacct.id);
        opp.KeyContact__c = con.Id;
        insert opp;
        /* End: Meet Desa: Replaced createOpportunity with createOpportunityofIdentifyStage */
        
        User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
        
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;
        
        //create international product
        Product2 bundle1 = APT_TestUtils.createDomesticProduct('Eparcel','eParcelStandard','Postal Services','CAT1', 'Standard');
        bundle1.APT_Sync_with_Opportunity__c=true;
        bundle1.APT_Is_Charge_Account_Product__c = true;
        bundle1.APT_Is_Cash_Account_Product__c = false;
        bundle1.APT_Consolidated_Usage_Price_Tiers__c = true;
        bundle1.APT_Product_Type__c ='eParcels Domestic';
        insert bundle1;
             
        //Create Option product
        Product2 option = APT_TestUtils.createDomesticProduct('Eparcel','eParcelStandard','Postal Services','CAT1', 'Standard');
        option.Apttus_Config2__ConfigurationType__c='Option';
        option.APT_Sync_with_Opportunity__c=true;
        option.APT_International_Pricing__c = false;
        option.APT_Consolidated_Usage_Price_Tiers__c = true;
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
        
        //Apttus_XApps__Application__c
        Apttus_XApps__Application__c app1 = new Apttus_XApps__Application__c();
        app1.Name = 'test App';
        app1.Apttus_XApps__Activated__c = true;
        app1.Apttus_XApps__Edition__c = 'Essentials';
        app1.Apttus_XApps__RefId__c = 'a40O0000000AL5AIAW';
        app1.Apttus_XApps__UniqueId__c = 'a40O0000000AL5AIAW';
        insert app1;
        
        Apttus_XApps__Application__c app2 = new Apttus_XApps__Application__c();
        app2.Name = 'test App2';
        app2.Apttus_XApps__Activated__c = true;
        //insert app2;
        
        //APT_App_Setup__c
        
        APT_App_Setup__c aSetup = new APT_App_Setup__c();
        aSetup.APT_App_Name__c = app1.ID;
        aSetup.Name = 'test';
        aSetup.APT_Is_Presto_App__c = true;
        aSetup.Apt_Product__c = bundle1.ID;
        aSetup.APT_Attribute_Name__c = 'Apttus_Config2__AttributeValueId__c';
        aSetup.APT_Attribute_Value__c = attribute1.ID;
        insert aSetup;
        
        APT_App_Setup__c aSetup2 = new APT_App_Setup__c();
        aSetup2.APT_App_Name__c = app1.ID;
        aSetup2.Name = 'test2';
        aSetup2.APT_Is_Presto_App__c = true;
        aSetup2.Apt_Product__c = bundle1.ID;
        aSetup2.APT_Attribute_Name__c = 'Apttus_Config2__AttributeValueId__c';
        aSetup2.APT_Attribute_Value__c = attribute1.Id;
        aSetup2.APT_IsRateCalculatorCall__c=true;
        insert aSetup2;
        
        //Apttus_Config2__UsagePriceTier__c
        Apttus_Config2__UsagePriceTier__c upt = new Apttus_Config2__UsagePriceTier__c();
        upt.Apttus_Config2__Sequence__c = 1;
        upt.Apttus_Config2__LineItemId__c = bundleLine.Id;
        insert upt;
        
        ApexPages.currentPage().getHeaders().put('Referer', 'www.ausiepost.org');
        Apexpages.currentPage().getParameters().put('parentRecordID', bundleLine.ID);
        Apexpages.currentPage().getParameters().put('isPrestoMode', 'True');
        system.assert(bundleLine.Id!=null);
        Test.StartTest();
        APT_ViewRatecardControllerAPI vrc = new APT_ViewRatecardControllerAPI();
        //Try{
            vrc.init();
            vrc.doCancel();
        vrc.prestoAPI(); 
        vrc.redirect(bundleLine.Id);
            
        //}catch(Exception ex) {
        //    System.debug('*****exception'+ex.getMessage());
        //}
        Test.StopTest();
        
    }
    
    public static TestMethod void testMethodViewrateCardBatchExecute() {
        APT_R2T_System_Properties__c r2tSystemProperties = new APT_R2T_System_Properties__c();
        r2tSystemProperties.Name = 'test';
        r2tSystemProperties.APT_Default_Proposal_Template__c = 'Proposal';
        r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c = 'test@test.com';
        //r2tSystemProperties.APT_ACIC_Request_Product_types__c = 'Worforce Verification';
        insert r2tSystemProperties;

        Contact con= APT_TestUtils.createContact();
        con.Email = 'temp@temp.com';
        insert con;
        
        Account tempacct = APT_TestUtils.createOrganisation();
        insert tempacct;
        
        /* Start: Meet Desa: Replaced createOpportunity with createOpportunityofIdentifyStage */
        Opportunity opp = APT_TestUtils.createOpportunityofIdentifyStage(tempacct.id);
        opp.KeyContact__c = con.Id;
        insert opp;
        /* End: Meet Desa: Replaced createOpportunity with createOpportunityofIdentifyStage */
        
        User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
        
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;
        
        //create international product
        Product2 bundle1 = APT_TestUtils.createDomesticProduct('Eparcel','eParcelStandard','Postal Services','CAT1', 'Standard');
        bundle1.APT_Product_Type__c = 'eParcels Domestic';
        bundle1.APT_Sync_with_Opportunity__c=true;
        bundle1.APT_Is_Charge_Account_Product__c = true;
        bundle1.APT_Is_Cash_Account_Product__c = false;
        bundle1.APT_Consolidated_Usage_Price_Tiers__c = true;
        bundle1.Non_contracted__c = false;
        insert bundle1;
             
        //Create Option product
        Product2 option = APT_TestUtils.createDomesticProduct('Eparcel','eParcelStandard','Postal Services','CAT1', 'Standard');
        option.Apttus_Config2__ConfigurationType__c='Option';
        option.APT_Sync_with_Opportunity__c=true;
        option.APT_International_Pricing__c = false;
        option.APT_Domestic_Pricing__c=true;
        option.Non_contracted__c = false;
        option.ProductCode=APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD;
        option.APT_Consolidated_Usage_Price_Tiers__c = true;
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
        insert Proposal;

        //Create Proposal for exempted prod types
        Apttus_Proposal__Proposal__c Proposal2= APT_TestUtils.getQuoteProposal(tempacct.ID,opp.ID,'Proposal','Quote', priceList.ID);
        //proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c = System.Today() - 1;
        Proposal.Expected_Revenue_Start_Date__c = System.Today() - 20;
        Proposal.Apttus_Proposal__Approval_Stage__c = 'Accepted';
        Proposal.Apttus_Proposal__Opportunity__c = opp.Id;
        proposal.Exempted_Product_Type__c='Priority Product';
        insert Proposal2;
             
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
        //bundleLine.Apttus_Config2__OptionId__c = option.ID;
        insert bundleLine;                  
      
        //Create Proposal Line Item               
        Apttus_Proposal__Proposal_Line_Item__c proposalLT1= APT_TestUtils.getProposalLineItem(Proposal.id,bundleLine.id,pli.id,bundle1.id,option.id);
        proposalLT1.Apttus_QPConfig__Quantity2__c=3;
        proposalLT1.Apttus_QPConfig__NetPrice__c=10;
        proposalLT1.Apttus_QPConfig__IsPrimaryLine__c = true;
        proposalLT1.Apttus_QPConfig__OptionId__c = option.Id;
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
        attribute1.APT_Consignment_Pricing__c='No';            
        insert attribute1;
        
        //Apttus_XApps__Application__c
        Apttus_XApps__Application__c app1 = new Apttus_XApps__Application__c();
        app1.Name = 'test App';
        app1.Apttus_XApps__Activated__c = true;
        insert app1;
        
        //APT_App_Setup__c
       
        //APT_App_Setup__c
        APT_App_Setup__c aSetup = new APT_App_Setup__c();
        aSetup.APT_App_Name__c = app1.ID;
        aSetup.Name = 'test';
        aSetup.APT_Is_Presto_App__c = true;
        aSetup.Apt_Product__c = bundle1.ID;
        aSetup.APT_Attribute_Name__c = 'Apttus_Config2__AttributeValueId__c';
        aSetup.APT_Attribute_Value__c = attribute1.ID;
        insert aSetup;
        
        APT_App_Setup__c aSetup2 = new APT_App_Setup__c();
        aSetup2.APT_App_Name__c = app1.ID;
        aSetup2.Name = 'test2';
        aSetup2.APT_Is_Presto_App__c = true;
        aSetup2.Apt_Product__c = bundle1.ID;
        aSetup2.APT_Attribute_Name__c = 'Apttus_Config2__AttributeValueId__c';
        aSetup2.APT_Attribute_Value__c = attribute1.Id;
        insert aSetup2;
        
        //Apttus_Config2__UsagePriceTier__c
        Apttus_Config2__UsagePriceTier__c upt = new Apttus_Config2__UsagePriceTier__c();
        upt.Apttus_Config2__Sequence__c = 1;
        upt.Apttus_Config2__LineItemId__c = bundleLine.Id;
        insert upt;
        
        
        Apttus__APTS_Template__c template1 = new Apttus__APTS_Template__c();
        template1.Name = 'Proposal';
        insert template1;
        
        Attachment attachment1 = new Attachment();
        attachment1.ParentId = template1.Id;
        attachment1.Name = 'Test';
        attachment1.Body = Blob.valueOf('Test');
        insert attachment1;
        
        ApexPages.currentPage().getHeaders().put('Referer', 'www.ausiepost.org');
        Apexpages.currentPage().getParameters().put('parentRecordID', bundleLine.ID);
        Apexpages.currentPage().getParameters().put('isPrestoMode', 'True');
        Apexpages.currentPage().getParameters().put('Id', Proposal.ID);
        system.assert(bundleLine.Id!=null);
        Test.StartTest();
        APT_ViewratecardBatch rateCardBatch = new APT_ViewratecardBatch(prodconfig.id,proposal.Id, 'test', 'www.sample@test.com', 'Test.com', true,proposal.Exempted_Product_Type__c);
        rateCardBatch.updateProposalInCaseOfDocAPIFail();
        APT_ViewRatecardControllerAPI vrc = new APT_ViewRatecardControllerAPI();
            vrc.init();
        APT_ViewRatecardBatchExecute vrbe = new APT_ViewRatecardBatchExecute(Proposal.ID);
        vrbe.isCallFromRateCalc = false;
        vrbe.init();
        
        APT_ViewRatecardBatchExecute vrbe1 = new APT_ViewRatecardBatchExecute();
        vrbe1.isCallFromRateCalc = false;
        vrbe1.hideMessage = true;
        vrbe1.init();
        
        Test.StopTest();
        
    }
    
    public static TestMethod void testMethodViewrateCardBatchExecute1() {
        APT_R2T_System_Properties__c r2tSystemProperties = new APT_R2T_System_Properties__c();
        r2tSystemProperties.Name = 'test';
        r2tSystemProperties.APT_Default_Proposal_Template__c = 'Proposal';
        r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c = 'test@test.com';
        //r2tSystemProperties.APT_ACIC_Request_Product_types__c = 'Worforce Verification';
        insert r2tSystemProperties;

        Contact con= APT_TestUtils.createContact();
        con.Email = 'temp@temp.com';
        insert con;
        
        Account tempacct = APT_TestUtils.createOrganisation();
        insert tempacct;
        
        /* Start: Meet Desa: Replaced createOpportunity with createOpportunityofIdentifyStage */
        Opportunity opp = APT_TestUtils.createOpportunityofIdentifyStage(tempacct.id);
        opp.KeyContact__c = con.Id;
        insert opp;
        /* End: Meet Desa: Replaced createOpportunity with createOpportunityofIdentifyStage */
        
        User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
        
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;
        
        //create international product
        Product2 bundle1 = APT_TestUtils.createDomesticProduct(APT_Constants.PRODUCT_NAME_INTERNATIONAL_BUNDLE,'International','Postal Services','CAT1', 'Standard');
        bundle1.APT_Sync_with_Opportunity__c=true;
        bundle1.APT_Is_Charge_Account_Product__c = true;
        bundle1.APT_Is_Cash_Account_Product__c = false;
        bundle1.APT_Consolidated_Usage_Price_Tiers__c = true;
        bundle1.Non_contracted__c = false;
        bundle1.APT_Product_Type__c ='International';
        insert bundle1;
             
        //Create Option product
        Product2 option = APT_TestUtils.createDomesticProduct('Eparcel','eParcelStandard','Postal Services','CAT1', 'Standard');
        option.Apttus_Config2__ConfigurationType__c='Option';
        option.APT_Sync_with_Opportunity__c=true;
        option.APT_International_Pricing__c = false;
        option.APT_Domestic_Pricing__c=true;
        option.Non_contracted__c = false;
        option.ProductCode=APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS;
        option.APT_Consolidated_Usage_Price_Tiers__c = true;
        bundle1.APT_Product_Type__c ='eParcels Domestic';
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
        //bundleLine.Apttus_Config2__AttributeValueId__c=attribute1.id;
        //bundleLine.Apttus_Config2__OptionId__c = option.ID;
        insert bundleLine;    
        
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
        attribute1.APT_Cubic_Factor__c=4; 
        attribute1.APTS_Price_Structure__c='Z30';  
        attribute1.APT_Signature_On_Delivery__c = 'No'; 
        attribute1.APT_Consignment_Pricing__c=APT_Constants.OPTION_YES;     
        insert attribute1;              
      
        //Create Proposal Line Item               
        Apttus_Proposal__Proposal_Line_Item__c proposalLT1= APT_TestUtils.getProposalLineItem(Proposal.id,bundleLine.id,pli.id,bundle1.id,option.id);
        proposalLT1.Apttus_QPConfig__Quantity2__c=3;
        proposalLT1.Apttus_QPConfig__NetPrice__c=10;
        proposalLT1.Apttus_QPConfig__IsPrimaryLine__c = true;
        proposalLT1.Apttus_QPConfig__OptionId__c = option.Id;
        proposalLT1.Apttus_Proposal__Product__c = bundle1.id;
        //proposalLT1.Apttus_QPConfig__ParentBundleNumber__c = 1;
        proposalLT1.Apttus_QPConfig__IsOptionRollupLine__c=false;
        insert proposalLT1;
        
        APT_Charge_Code__c chargeCode= new APT_Charge_Code__c(APT_Price_Structure__c='Z30',APT_Network_Type__c=APT_Constants.NETWORK_TYPE_STANDARD,APT_Weight_Measure__c=APT_Constants.WEIGHT_MEASURE_CUBIC);
        insert chargeCode;
        
        //Apttus_QPConfig__ProposalUsagePriceTier__c
        Apttus_QPConfig__ProposalUsagePriceTier__c pupt = new Apttus_QPConfig__ProposalUsagePriceTier__c();
        pupt.Apttus_QPConfig__Sequence__c = 1;
        pupt.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
        pupt.Apttus_QPConfig__Dimension1Value__c = 'WG';
        pupt.Apttus_QPConfig__Dimension2Value__c = '0.50';
        pupt.Apttus_QPConfig__Dimension3Value__c = 'Base';
        pupt.Apttus_QPConfig__AdjustmentAmount__c = 100;
        insert pupt;
        
        
        
        //Apttus_XApps__Application__c
        Apttus_XApps__Application__c app1 = new Apttus_XApps__Application__c();
        app1.Name = 'test App';
        app1.Apttus_XApps__Activated__c = true;
        insert app1;
        
        //APT_App_Setup__c
        
        
        APT_App_Setup__c aSetup2 = new APT_App_Setup__c();
        aSetup2.APT_App_Name__c = app1.ID;
        aSetup2.Name = 'test2';
        aSetup2.APT_Is_Presto_App__c = true;
        aSetup2.Apt_Product__c = bundle1.ID;
        aSetup2.APT_Attribute_Name__c = 'Apttus_Config2__AttributeValueId__c';
        aSetup2.APT_Attribute_Value__c = attribute1.Id;
        aSetup2.APT_IsRateCalculatorCall__c=true;
        insert aSetup2;
        
        //Apttus_Config2__UsagePriceTier__c
        Apttus_Config2__UsagePriceTier__c upt = new Apttus_Config2__UsagePriceTier__c();
        upt.Apttus_Config2__Sequence__c = 1;
        upt.Apttus_Config2__LineItemId__c = bundleLine.Id;
        insert upt;
        
        
        Apttus__APTS_Template__c template1 = new Apttus__APTS_Template__c();
        template1.Name = 'Proposal';
        insert template1;
        
        Attachment attachment1 = new Attachment();
        attachment1.ParentId = template1.Id;
        attachment1.Name = 'Test';
        attachment1.Body = Blob.valueOf('Test');
        insert attachment1;
        
        ApexPages.currentPage().getHeaders().put('Referer', 'www.ausiepost.org');
        Apexpages.currentPage().getParameters().put('parentRecordID', bundleLine.ID);
        Apexpages.currentPage().getParameters().put('isPrestoMode', 'True');
        Apexpages.currentPage().getParameters().put('Id', Proposal.ID);
        system.assert(bundleLine.Id!=null);
        Test.StartTest();
            APT_ViewRatecardControllerAPI rateController = new APT_ViewRatecardControllerAPI();
            rateController.isPrestoModeParam ='true';
            rateController.ratecardCalculatorMode=true;
            APT_ViewratecardBatch rateCardBatch = new APT_ViewratecardBatch(prodconfig.id,proposal.Id, 'test', 'www.sample@test.com', 'Test.com', true,proposal.Exempted_Product_Type__c);
            Database.executeBatch(rateCardBatch);
            rateCardBatch.updateProposalInCaseOfDocAPIFail();
            APT_ViewRatecardBatchExecute vrbe = new APT_ViewRatecardBatchExecute(Proposal.ID);
            vrbe.isCallFromRateCalc = true;
            vrbe.init();

            APT_ViewRatecardBatchExecute vrbe1 = new APT_ViewRatecardBatchExecute();
            vrbe1.isCallFromRateCalc = true;
            vrbe1.hideMessage = true;
            vrbe1.init();
        
        Test.StopTest();
        
    }
    
    //Added by Viraj
    
    public static TestMethod void testMethodViewrateCardBatchExecuteNotCallFromRate() {
        APT_R2T_System_Properties__c r2tSystemProperties = new APT_R2T_System_Properties__c();
        r2tSystemProperties.Name = 'test';
        r2tSystemProperties.APT_Default_Proposal_Template__c = 'Proposal';
        r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c = 'test@test.com';
        //r2tSystemProperties.APT_ACIC_Request_Product_types__c = 'Worforce Verification';
        insert r2tSystemProperties;

        Contact con= APT_TestUtils.createContact();
        con.Email = 'temp@temp.com';
        insert con;
        
        Account tempacct = APT_TestUtils.createOrganisation();
        insert tempacct;
        
        /* Start: Meet Desa: Replaced createOpportunity with createOpportunityofIdentifyStage */
        Opportunity opp = APT_TestUtils.createOpportunityofIdentifyStage(tempacct.id);
        opp.KeyContact__c = con.Id;
        insert opp;
        /* End: Meet Desa: Replaced createOpportunity with createOpportunityofIdentifyStage */
        
        User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
        
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;
        
        //create international product
        Product2 bundle1 = APT_TestUtils.createDomesticProduct(APT_Constants.PRODUCT_CODE_INTERNATIONAL_PCMSNew,'International','Postal Services','CAT1', 'Standard');
        bundle1.APT_Sync_with_Opportunity__c=true;
        bundle1.APT_Is_Charge_Account_Product__c = true;
        bundle1.APT_Is_Cash_Account_Product__c = false;
        bundle1.APT_Consolidated_Usage_Price_Tiers__c = true;
        bundle1.Non_contracted__c = false;
        bundle1.ProductCode = APT_Constants.PRODUCT_CODE_INTERNATIONAL_PCMS;
        bundle1.APT_Product_Type__c ='International';
        insert bundle1;
             
        //Create Option product
        Product2 option = APT_TestUtils.createDomesticProduct('Eparcel','eParcelStandard','Postal Services','CAT1', 'Standard');
        option.Apttus_Config2__ConfigurationType__c='Option';
        option.APT_Sync_with_Opportunity__c=true;
        option.APT_International_Pricing__c = false;
        option.APT_Domestic_Pricing__c=true;
        option.Non_contracted__c = false;
        option.ProductCode=APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS;
        option.APT_Consolidated_Usage_Price_Tiers__c = true;
        bundle1.APT_Product_Type__c ='eParcels Domestic';
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
        bundleLine.APT_Rate_Card_Key__c = 'abc123';
        //bundleLine.Apttus_Config2__AttributeValueId__c=attribute1.id;
        //bundleLine.Apttus_Config2__OptionId__c = option.ID;
       
        insert bundleLine;    
        
        //create Logdement Zone             
        APT_Lodgement_Zone__c logdZone = APT_TestUtils.getLodgementZone('Aust Antarctic Territory','AAT');
        insert logdZone;               
               
        //Create Feature Pricing              
        APT_Feature_Pricing__c featurePricing = APT_TestUtils.getFeaturePricing('Aust Antarctic Territory','CAT1','AAT','Standard','EPR2',10,1);           
        insert featurePricing;
              
        //Create product Attribute value                
        Apttus_Config2__ProductAttributeValue__c attribute1 = APT_TestUtils.GetAttributeValue(bundleLine.Id,'Standard',false,false,false,'Yes','B Mining',True,false);
        attribute1.Category__c='CAT1';
        attribute1.APT_Lodgement_Zone__c=logdZone.ID; 
        attribute1.APT_Cubic_Factor__c=4; 
        attribute1.APTS_Price_Structure__c='Z30';  
        attribute1.APT_Signature_On_Delivery__c = 'No'; 
        attribute1.APT_Band__c = 'BAND 6';
        attribute1.APT_Consignment_Pricing__c=APT_Constants.OPTION_YES;     
        insert attribute1;              
      
        //Create Proposal Line Item               
        Apttus_Proposal__Proposal_Line_Item__c proposalLT1= APT_TestUtils.getProposalLineItem(Proposal.id,bundleLine.id,pli.id,bundle1.id,option.id);
        proposalLT1.Apttus_QPConfig__Quantity2__c=3;
        proposalLT1.Apttus_QPConfig__NetPrice__c=10;
        proposalLT1.Apttus_QPConfig__IsPrimaryLine__c = true;
        proposalLT1.Apttus_QPConfig__OptionId__c = option.Id;
        proposalLT1.Apttus_Proposal__Product__c = bundle1.id;
        //proposalLT1.Apttus_QPConfig__ParentBundleNumber__c = 1;
        proposalLT1.Apttus_QPConfig__IsOptionRollupLine__c=false;
        insert proposalLT1;
        
        APT_Charge_Code__c chargeCode= new APT_Charge_Code__c(APT_Price_Structure__c='Z30',APT_Network_Type__c=APT_Constants.NETWORK_TYPE_STANDARD,APT_Weight_Measure__c=APT_Constants.WEIGHT_MEASURE_CUBIC);
        insert chargeCode;
        
        //Apttus_QPConfig__ProposalUsagePriceTier__c
        Apttus_QPConfig__ProposalUsagePriceTier__c pupt = new Apttus_QPConfig__ProposalUsagePriceTier__c();
        pupt.Apttus_QPConfig__Sequence__c = 1;
        pupt.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
        pupt.Apttus_QPConfig__Dimension1Value__c = 'WG';
        pupt.Apttus_QPConfig__Dimension2Value__c = '0.50';
        pupt.Apttus_QPConfig__Dimension3Value__c = 'Base';
        pupt.Apttus_QPConfig__AdjustmentAmount__c = 100;
        insert pupt;
        
        
        
        //Apttus_XApps__Application__c
        Apttus_XApps__Application__c app1 = new Apttus_XApps__Application__c();
        app1.Name = 'test App';
        app1.Apttus_XApps__Activated__c = true;
        insert app1;
        
        //APT_App_Setup__c
        APT_App_Setup__c aSetup = new APT_App_Setup__c();
        aSetup.APT_App_Name__c = app1.ID;
        aSetup.Name = 'test';
        aSetup.APT_Is_Presto_App__c = true;
        aSetup.Apt_Product__c = bundle1.ID;
        aSetup.APT_Attribute_Name__c = 'Apttus_Config2__AttributeValueId__c';
        aSetup.APT_Attribute_Value__c = attribute1.ID;
        insert aSetup;
        
        APT_App_Setup__c aSetup2 = new APT_App_Setup__c();
        aSetup2.APT_App_Name__c = app1.ID;
        aSetup2.Name = 'test2';
        aSetup2.APT_Is_Presto_App__c = true;
        aSetup2.Apt_Product__c = bundle1.ID;
        aSetup2.APT_Attribute_Name__c = 'Apttus_Config2__AttributeValueId__c';
        aSetup2.APT_Attribute_Value__c = attribute1.Id;
        aSetup2.APT_IsRateCalculatorCall__c=true;
        insert aSetup2;
        
        //Apttus_Config2__UsagePriceTier__c
        Apttus_Config2__UsagePriceTier__c upt = new Apttus_Config2__UsagePriceTier__c();
        upt.Apttus_Config2__Sequence__c = 1;
        upt.Apttus_Config2__LineItemId__c = bundleLine.Id;
        insert upt;
        
        
        Apttus__APTS_Template__c template1 = new Apttus__APTS_Template__c();
        template1.Name = 'Proposal';
        insert template1;
        
        Attachment attachment1 = new Attachment();
        attachment1.ParentId = template1.Id;
        attachment1.Name = 'Test';
        attachment1.Body = Blob.valueOf('Test');
        insert attachment1;

        
        
        APT_Consolidated_Usage_Price_Tier__c objConsolidatedPriceTier = new APT_Consolidated_Usage_Price_Tier__c();
        objConsolidatedPriceTier.APT_Line_Item__c = bundleLine.ID;
        insert objConsolidatedPriceTier;
        
        ApexPages.currentPage().getHeaders().put('Referer', 'www.ausiepost.org');
        Apexpages.currentPage().getParameters().put('parentRecordID', bundleLine.ID);
        Apexpages.currentPage().getParameters().put('isPrestoMode', 'True');
        Apexpages.currentPage().getParameters().put('Id', Proposal.ID);
        system.assert(bundleLine.Id!=null);
        Test.StartTest();
            try{
                APT_ViewRatecardControllerAPI rateController = new APT_ViewRatecardControllerAPI();
                rateController.isPrestoModeParam ='true';
                rateController.ratecardCalculatorMode=true;
                APT_ViewratecardBatch rateCardBatch = new APT_ViewratecardBatch(prodconfig.id,proposal.Id, 'test', 'www.sample@test.com', 'Test.com', false,proposal.Exempted_Product_Type__c);
                Database.executeBatch(rateCardBatch);
                rateCardBatch.updateProposalInCaseOfDocAPIFail();
                APT_ViewRatecardBatchExecute vrbe = new APT_ViewRatecardBatchExecute(Proposal.ID);
                vrbe.isCallFromRateCalc = true;
                vrbe.init();
                rateCardBatch.rateCalcAttachmentIdlist.put(APT_Constants.FILE_DIGITALCODE,attachment1.ID);
                rateCardBatch.mapLineItem.put(APT_Constants.PRODUCT_CODE_INTERNATIONAL_PCMSNew, bundleLine);
                rateCardBatch.proposalRateCAlc = Proposal;
                rateCardBatch.finish(null);
                
                APT_ViewRatecardBatchExecute vrbe1 = new APT_ViewRatecardBatchExecute();
                vrbe1.isCallFromRateCalc = true;
                vrbe1.hideMessage = true;
                vrbe1.init();
            }catch(Exception e){
                system.debug('*** error: ' +e.getMessage());
            }
        
        Test.StopTest();
        
    }
    
    
    
    
    
    
    //ended by viraj
    //added by viraj method test4
    
     public static TestMethod void testMethod4APIController() {

         APT_R2T_System_Properties__c r2tSystemProperties = new APT_R2T_System_Properties__c();
         r2tSystemProperties.Name = 'test';
         r2tSystemProperties.APT_Default_Proposal_Template__c = 'Proposal';
         r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c = 'test@test.com';
         //r2tSystemProperties.APT_ACIC_Request_Product_types__c = 'Worforce Verification';
         insert r2tSystemProperties;

         Contact con= APT_TestUtils.createContact();
         con.Email = 'temp@temp.com';
         insert con;
        
        Account tempacct = APT_TestUtils.createOrganisation();
        insert tempacct;
        
        /* Start: Meet Desa: Replaced createOpportunity with createOpportunityofIdentifyStage */
        Opportunity opp = APT_TestUtils.createOpportunityofIdentifyStage(tempacct.id);
        opp.KeyContact__c = con.Id;
        insert opp;
        /* End: Meet Desa: Replaced createOpportunity with createOpportunityofIdentifyStage */
        
        User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
        
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;
        
        //create international product
        Product2 bundle1 = APT_TestUtils.createDomesticProduct(APT_Constants.PRODUCT_NAME_INTERNATIONAL_BUNDLE,'International','Postal Services','CAT1', 'Standard');
        bundle1.APT_Sync_with_Opportunity__c=true;
        bundle1.APT_Is_Charge_Account_Product__c = true;
        bundle1.APT_Is_Cash_Account_Product__c = false;
        bundle1.APT_Consolidated_Usage_Price_Tiers__c = true;
        bundle1.ProductCode = APT_Constants.PRODUCT_CODE_INTERNATIONAL_PCMSNew;
        bundle1.APT_Product_Type__c ='International';
        insert bundle1;
             
        //Create Option product
        Product2 option = APT_TestUtils.createDomesticProduct('Eparcel','eParcelStandard','Postal Services','CAT1', 'Standard');
        option.Apttus_Config2__ConfigurationType__c='Option';
        option.APT_Sync_with_Opportunity__c=true;
        option.APT_International_Pricing__c = false;
        option.APT_Consolidated_Usage_Price_Tiers__c = true;
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
        Apttus_Config2__ProductAttributeValue__c attribute1 = APT_TestUtils.GetAttributeValue(bundleLine.Id,'Standard',false,false,false,'Yes','B Mining',True,false);
        attribute1.Category__c='CAT1';
        attribute1.APT_Lodgement_Zone__c=logdZone.ID;               
        insert attribute1;
        
        //Apttus_XApps__Application__c
        Apttus_XApps__Application__c app1 = new Apttus_XApps__Application__c();
        app1.Name = 'test App';
        app1.Apttus_XApps__Activated__c = true;
        insert app1;
        
        //APT_App_Setup__c
        APT_App_Setup__c aSetup = new APT_App_Setup__c();
        aSetup.APT_App_Name__c = app1.ID;
        aSetup.Name = 'test';
        aSetup.APT_Is_Presto_App__c = true;
        aSetup.Apt_Product__c = bundle1.ID;
        aSetup.APT_Attribute_Name__c = 'Apttus_Config2__AttributeValueId__c';
        aSetup.APT_Attribute_Value__c = attribute1.ID;
        insert aSetup;
        
        APT_App_Setup__c aSetup2 = new APT_App_Setup__c();
        aSetup2.APT_App_Name__c = app1.ID;
        aSetup2.Name = 'test2';
        aSetup2.APT_Is_Presto_App__c = true;
        aSetup2.Apt_Product__c = bundle1.ID;
        aSetup2.APT_Attribute_Name__c = 'Apttus_Config2__AttributeValueId__c';
        aSetup2.APT_Attribute_Value__c = attribute1.Id;
        insert aSetup2;
        
        //Apttus_Config2__UsagePriceTier__c
        Apttus_Config2__UsagePriceTier__c upt = new Apttus_Config2__UsagePriceTier__c();
        upt.Apttus_Config2__Sequence__c = 1;
        upt.Apttus_Config2__LineItemId__c = bundleLine.Id;
        insert upt;
         
        APT_Consolidated_Usage_Price_Tier__c objConsolidatedPriceTier = new APT_Consolidated_Usage_Price_Tier__c();
        objConsolidatedPriceTier.APT_Line_Item__c = bundleLine.ID;
        insert objConsolidatedPriceTier;

         Apttus__APTS_Template__c template1 = new Apttus__APTS_Template__c();
         template1.Name = 'Proposal';
         insert template1;

         Attachment attachment1 = new Attachment();
         attachment1.ParentId = template1.Id;
         attachment1.Name = 'Test';
         attachment1.Body = Blob.valueOf('Test');
         insert attachment1;
        
        ApexPages.currentPage().getHeaders().put('Referer', 'www.ausiepost.org');
        Apexpages.currentPage().getParameters().put('parentRecordID', bundleLine.ID);
        Apexpages.currentPage().getParameters().put('isPrestoMode', 'True');
        Apexpages.currentPage().getParameters().put('Id', Proposal.ID);
        system.assert(bundleLine.Id!=null);
        Test.StartTest();
             
        APT_ViewratecardBatch rateCardBatch = new APT_ViewratecardBatch(prodconfig.id,proposal.Id, 'test', 'www.sample@test.com', 'Test.com', false,proposal.Exempted_Product_Type__c);
        Database.executeBatch(rateCardBatch); 
        rateCardBatch.updateProposalInCaseOfDocAPIFail();
        APT_ViewRatecardControllerAPI vrc = new APT_ViewRatecardControllerAPI();
        
        //vrc.isPrestoModeParam ='true';              
        //vrc.ratecardCalculatorMode=true; 
        vrc.init();
        vrc.doCancel();
        vrc.prestoAPI(); 
        vrc.redirect(bundleLine.Id); 
        /*APT_ViewRatecardBatchExecute vrbe = new APT_ViewRatecardBatchExecute(Proposal.ID);
        vrbe.isCallFromRateCalc = true;
        vrbe.init();
        APT_ViewRatecardBatchExecute vrbe1 = new APT_ViewRatecardBatchExecute();        
        vrbe1.isCallFromRateCalc = true;        
        vrbe1.hideMessage = true;       
        vrbe1.init();*/
        Test.StopTest(); 
        
    }
    //ended by viraj test4
    
    public static TestMethod void testMethod4() {
        APT_R2T_System_Properties__c r2tSystemProperties = new APT_R2T_System_Properties__c();
        r2tSystemProperties.Name = 'test';
        r2tSystemProperties.APT_Default_Proposal_Template__c = 'Proposal';
        r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c = 'test@test.com';
        //r2tSystemProperties.APT_ACIC_Request_Product_types__c = 'Worforce Verification';
        insert r2tSystemProperties;

        Contact con= APT_TestUtils.createContact();
        con.Email = 'temp@temp.com';
        insert con;
        
        Account tempacct = APT_TestUtils.createOrganisation();
        insert tempacct;
        
        /* Start: Meet Desa: Replaced createOpportunity with createOpportunityofIdentifyStage */
        Opportunity opp = APT_TestUtils.createOpportunityofIdentifyStage(tempacct.id);
        opp.KeyContact__c = con.Id;
        insert opp;
        /* End: Meet Desa: Replaced createOpportunity with createOpportunityofIdentifyStage */
        
        User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
        
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;
        
        //create international product
        Product2 bundle1 = APT_TestUtils.createDomesticProduct(APT_Constants.PRODUCT_NAME_INTERNATIONAL_BUNDLE,'International','Postal Services','CAT1', 'Standard');
        bundle1.APT_Sync_with_Opportunity__c=true;
        bundle1.APT_Is_Charge_Account_Product__c = true;
        bundle1.APT_Is_Cash_Account_Product__c = false;
        bundle1.APT_Consolidated_Usage_Price_Tiers__c = true;
        bundle1.APT_Product_Type__c ='International';
        insert bundle1;
             
        //Create Option product
        Product2 option = APT_TestUtils.createDomesticProduct('Eparcel','eParcelStandard','Postal Services','CAT1', 'Standard');
        option.Apttus_Config2__ConfigurationType__c='Option';
        option.APT_Sync_with_Opportunity__c=true;
        option.APT_International_Pricing__c = false;
        option.APT_Consolidated_Usage_Price_Tiers__c = true;
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
        
        //Apttus_XApps__Application__c
        Apttus_XApps__Application__c app1 = new Apttus_XApps__Application__c();
        app1.Name = 'test App';
        app1.Apttus_XApps__Activated__c = true;
        insert app1;
        
        //APT_App_Setup__c
        APT_App_Setup__c aSetup = new APT_App_Setup__c();
        aSetup.APT_App_Name__c = app1.ID;
        aSetup.Name = 'test';
        aSetup.APT_Is_Presto_App__c = true;
        aSetup.Apt_Product__c = bundle1.ID;
        aSetup.APT_Attribute_Name__c = 'Apttus_Config2__AttributeValueId__c';
        aSetup.APT_Attribute_Value__c = attribute1.ID;
        insert aSetup;
        
        APT_App_Setup__c aSetup2 = new APT_App_Setup__c();
        aSetup2.APT_App_Name__c = app1.ID;
        aSetup2.Name = 'test2';
        aSetup2.APT_Is_Presto_App__c = true;
        aSetup2.Apt_Product__c = bundle1.ID;
        aSetup2.APT_Attribute_Name__c = 'Apttus_Config2__AttributeValueId__c';
        aSetup2.APT_Attribute_Value__c = attribute1.Id;
        insert aSetup2;
        
        //Apttus_Config2__UsagePriceTier__c
        Apttus_Config2__UsagePriceTier__c upt = new Apttus_Config2__UsagePriceTier__c();
        upt.Apttus_Config2__Sequence__c = 1;
        upt.Apttus_Config2__LineItemId__c = bundleLine.Id;
        insert upt;
        /*
        Apttus__APTS_Template__c template1 = new Apttus__APTS_Template__c();        
        template1.Name = 'R2T Proposal Template';       
        insert template1; 
                
        Attachment attachment1 = new Attachment();      
        attachment1.ParentId = template1.Id;        
        attachment1.Name = 'Test';      
        attachment1.Body = Blob.valueOf('Test');        
        insert attachment1;
                
        APT_R2T_System_Properties__c r2tSystemProperties = new APT_R2T_System_Properties__c();      
        r2tSystemProperties.Name = 'test';      
        r2tSystemProperties.APT_Default_Proposal_Template__c = '';      
        r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c = 'test@test.com';       
        insert r2tSystemProperties;*/
        
        ApexPages.currentPage().getHeaders().put('Referer', 'www.ausiepost.org');
        Apexpages.currentPage().getParameters().put('parentRecordID', bundleLine.ID);
        Apexpages.currentPage().getParameters().put('isPrestoMode', 'True');
        Apexpages.currentPage().getParameters().put('Id', Proposal.ID);
        system.assert(bundleLine.Id!=null);
        Test.StartTest();
             
            APT_ViewratecardBatch rateCardBatch = new APT_ViewratecardBatch(prodconfig.id,proposal.Id, 'test', 'www.sample@test.com', 'Test.com', true,proposal.Exempted_Product_Type__c);
            rateCardBatch.updateProposalInCaseOfDocAPIFail();
            APT_ViewRatecardControllerAPI vrc = new APT_ViewRatecardControllerAPI();

            //vrc.isPrestoModeParam ='true';
            //vrc.ratecardCalculatorMode=true;
            vrc.init();
            vrc.doCancel();
            vrc.prestoAPI();
            vrc.redirect(bundleLine.Id);
            /*APT_ViewRatecardBatchExecute vrbe = new APT_ViewRatecardBatchExecute(Proposal.ID);
            vrbe.isCallFromRateCalc = true;
            vrbe.init();
            APT_ViewRatecardBatchExecute vrbe1 = new APT_ViewRatecardBatchExecute();
            vrbe1.isCallFromRateCalc = true;
            vrbe1.hideMessage = true;
            vrbe1.init();*/
        Test.StopTest();
        
    }
      
    public static testMethod void testAPT_ViewratecardBatchExecuteMethod(){
        APT_R2T_System_Properties__c r2tSystemProperties = new APT_R2T_System_Properties__c();
        r2tSystemProperties.Name = 'test';
        r2tSystemProperties.APT_Default_Proposal_Template__c = 'Proposal';
        r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c = 'test@test.com';
        //r2tSystemProperties.APT_ACIC_Request_Product_types__c = 'Worforce Verification';
        insert r2tSystemProperties;

        APT_Charge_Code__c chargeCode= new APT_Charge_Code__c(APT_Price_Structure__c='Z30',APT_Network_Type__c=APT_Constants.NETWORK_TYPE_STANDARD,APT_Weight_Measure__c=APT_Constants.WEIGHT_MEASURE_DEADWEIGHT, APT_Consignment_Pricing__c = true);
        insert chargeCode;


        Contact con= APT_TestUtils.createContact();
        con.Email = 'temp@temp.com';
        insert con;

        Account tempacct = APT_TestUtils.createOrganisation();
        insert tempacct;

        /* Start: Meet Desa: Replaced createOpportunity with createOpportunityofIdentifyStage */
        Opportunity opp = APT_TestUtils.createOpportunityofIdentifyStage(tempacct.id);
        opp.KeyContact__c = con.Id;
        insert opp;
        /* End: Meet Desa: Replaced createOpportunity with createOpportunityofIdentifyStage */

        User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];

        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;

        //create international product
        Product2 bundle1 = APT_TestUtils.createDomesticProduct(APT_Constants.PRODUCT_NAME_INTERNATIONAL_BUNDLE,'International','Postal Services','CAT1', 'Standard');
        bundle1.APT_Sync_with_Opportunity__c=true;
        bundle1.APT_Is_Charge_Account_Product__c = true;
        bundle1.APT_Is_Cash_Account_Product__c = false;
        bundle1.APT_Consolidated_Usage_Price_Tiers__c = true;
        bundle1.Non_contracted__c = false;
        bundle1.APT_Product_Type__c ='International';
        bundle1.ProductCode=APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD;
        insert bundle1;

        //Create Option product
        Product2 option = APT_TestUtils.createDomesticProduct('Eparcel','eParcelStandard','Postal Services','CAT1', 'Standard');
        option.Apttus_Config2__ConfigurationType__c='Option';
        option.APT_Sync_with_Opportunity__c=true;
        option.APT_International_Pricing__c = false;
        option.APT_Domestic_Pricing__c=true;
        option.Non_contracted__c = false;
        option.ProductCode=APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD;
        option.APT_Consolidated_Usage_Price_Tiers__c = true;
        option.APT_Product_Type__c ='eParcels Domestic';
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
        //bundleLine.Apttus_Config2__AttributeValueId__c=attribute1.id;
        //bundleLine.Apttus_Config2__OptionId__c = option.ID;
        insert bundleLine;



        //Create Feature Pricing
        APT_Feature_Pricing__c featurePricing = APT_TestUtils.getFeaturePricing('Aust Antarctic Territory','CAT1','AAT','Standard','EPR2',10,1);
        insert featurePricing;

        //create Logdement Zone
        APT_Lodgement_Zone__c logdZone = APT_TestUtils.getLodgementZone('Aust Antarctic Territory','AAT');
        insert logdZone;

        //Create product Attribute value
        Apttus_Config2__ProductAttributeValue__c attribute1 = APT_TestUtils.GetAttributeValue(bundleLine.Id,'Standard',false,false,false,'Yes','B Mining',True,True);
        attribute1.Category__c='CAT1';
        attribute1.APT_Lodgement_Zone__c=logdZone.ID;
        attribute1.APT_Cubic_Factor__c=4;
        attribute1.APTS_Price_Structure__c='Z30';
        attribute1.APT_Signature_On_Delivery__c = 'No';
        attribute1.APT_Consignment_Pricing__c=APT_Constants.OPTION_YES;
        attribute1.APT_International_Letters__c= true;
        insert attribute1;

        //Create Proposal Line Item
        Apttus_Proposal__Proposal_Line_Item__c proposalLT1= APT_TestUtils.getProposalLineItem(Proposal.id,bundleLine.id,pli.id,bundle1.id,option.id);
        proposalLT1.Apttus_QPConfig__Quantity2__c=3;
        proposalLT1.Apttus_QPConfig__NetPrice__c=10;
        proposalLT1.Apttus_QPConfig__IsPrimaryLine__c = true;
        proposalLT1.Apttus_QPConfig__OptionId__c = option.Id;
        proposalLT1.Apttus_Proposal__Product__c = bundle1.id;
        //proposalLT1.Apttus_QPConfig__ParentBundleNumber__c = 1;
        proposalLT1.Apttus_QPConfig__IsOptionRollupLine__c=false;
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



        //Apttus_XApps__Application__c
        Apttus_XApps__Application__c app1 = new Apttus_XApps__Application__c();
        app1.Name = 'test App';
        app1.Apttus_XApps__Activated__c = true;
        insert app1;

        //APT_App_Setup__c


        APT_App_Setup__c aSetup2 = new APT_App_Setup__c();
        aSetup2.APT_App_Name__c = app1.ID;
        aSetup2.Name = 'test2';
        aSetup2.APT_Is_Presto_App__c = true;
        aSetup2.Apt_Product__c = bundle1.ID;
        aSetup2.APT_Attribute_Name__c = 'Apttus_Config2__AttributeValueId__c';
        aSetup2.APT_Attribute_Value__c = attribute1.Id;
        aSetup2.APT_IsRateCalculatorCall__c=true;
        insert aSetup2;

        //Apttus_Config2__UsagePriceTier__c
        Apttus_Config2__UsagePriceTier__c upt = new Apttus_Config2__UsagePriceTier__c();
        upt.Apttus_Config2__Sequence__c = 1;
        upt.Apttus_Config2__LineItemId__c = bundleLine.Id;
        insert upt;


        Apttus__APTS_Template__c template1 = new Apttus__APTS_Template__c();
        template1.Name = 'Proposal';
        insert template1;

        Attachment attachment1 = new Attachment();
        attachment1.ParentId = template1.Id;
        attachment1.Name = 'Test';
        attachment1.Body = Blob.valueOf('Test');
        insert attachment1;

        ApexPages.currentPage().getHeaders().put('Referer', 'www.ausiepost.org');
        Apexpages.currentPage().getParameters().put('parentRecordID', bundleLine.ID);
        Apexpages.currentPage().getParameters().put('isPrestoMode', 'True');
        Apexpages.currentPage().getParameters().put('Id', Proposal.ID);
        system.assert(bundleLine.Id!=null);
        Test.StartTest();
            APT_ViewRatecardControllerAPI rateController = new APT_ViewRatecardControllerAPI();
            rateController.isPrestoModeParam ='true';
            rateController.ratecardCalculatorMode=true;
            APT_ViewratecardBatch rateCardBatch = new APT_ViewratecardBatch(prodconfig.id,proposal.Id, 'test', 'www.sample@test.com', 'Test.com', true,proposal.Exempted_Product_Type__c);
            Database.executeBatch(rateCardBatch);
            rateCardBatch.updateProposalInCaseOfDocAPIFail();
            APT_ViewRatecardBatchExecute vrbe = new APT_ViewRatecardBatchExecute(Proposal.ID);
            vrbe.isCallFromRateCalc = true;
            vrbe.init();

            APT_ViewRatecardBatchExecute vrbe1 = new APT_ViewRatecardBatchExecute();
            vrbe1.isCallFromRateCalc = true;
            vrbe1.hideMessage = true;
            vrbe1.init();
            vrbe.redirectToProposal();

        Test.StopTest();

    }
    /*public static TestMethod void TestUtilsMethod() {
        
        APT_TestUtils.createR2TSystemProperties(null);
        APT_TestUtils.createOrganisation();
        APT_TestUtils.createOpportunity(null);
        APT_TestUtils.createPriceList();
        APT_TestUtils.createPriceListItem(null, null, null, null);
        APT_TestUtils.createPriceMatrix(null, null, null, null);
        APT_TestUtils.createInternationalPriceData(null, null, null, null, null, null, null, null, null, null);
        APT_TestUtils.createInternationalProduct(null, null, null);
        APT_TestUtils.createDomesticProduct(null, null, null, null, null);
        APT_TestUtils.createProductAttributeGroup(null);
        APT_TestUtils.createProductAttribute(null, null);
        APT_TestUtils.createPriceDimension(null, null, null, null, null);
        APT_TestUtils.createDomesticPriceData(null, null, null, null, null, null, null, null, null, null, null);
        APT_TestUtils.getQuoteProposal(null, null, null, null, null);
        APT_TestUtils.getProductConfiguration(null, null, null, null, null, null, null, null, null, null, null);
        APT_TestUtils.getProductConfiguration2(null, null, null, null, null, null, null, null, null, null);
        APT_TestUtils.getConfigLineItem(null,null, null, null, null, null, null, null, null, null, null,null, null, null, null, null, null, null, null, null, null,null, null, null, null, null, null, null, null, null, null);
        APT_TestUtils.GetAttributeValue(null,null, null, null, null, null, null, null, null);
        APT_TestUtils.UpdateLineItem(null);
        APT_TestUtils.getLodgementZone(null, null);
        APT_TestUtils.getFeaturePricing(null, null, null, null, null, null, null);
        APT_TestUtils.getProposalLineItem(null, null, null, null, null);
        APT_TestUtils.getProposalProductAttributeValue(null);
        APT_TestUtils.getPricebookEntry(null, null);
        APT_TestUtils.createContact();
        APT_TestUtils.createAgreement(null);
        APT_TestUtils.createCase(null, null);
        APT_TestUtils.createNetwork();
        APT_TestUtils.createBillingAccount(null);
        APT_TestUtils.createSystemSettings();
        APT_TestUtils.createLodgementPoint(null, null, null, null, null, null);
        APT_TestUtils.createChargeCode(null);
        APT_TestUtils.createOpProdLI(null, null, null, null, null, null, null, null, null);
        APT_TestUtils.createAttachment(null);
        
    }*/
}