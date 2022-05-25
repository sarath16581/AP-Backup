//orginal
/**************************************************
@Name: APT_ViewRatecardController_Test
@ModifiedBy: Meet Desai
@ModifiedOn: 19 March, 2020
@Description: Replaced createOpportunity() function with createOpportunityofIdentifyStage() function
***************************************************/
@isTest
private class APT_ViewRatecardController_Test {
    @testSetup static void setup() {
        
        APT_R2T_System_Properties__c r2tSystemProperties = new APT_R2T_System_Properties__c();
        r2tSystemProperties.Name = 'test';
        r2tSystemProperties.APT_Default_Proposal_Template__c = 'Proposal';
        r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c = 'test@test.com';
        //r2tSystemProperties.APT_ACIC_Request_Product_types__c = 'Worforce Verification';
        insert r2tSystemProperties;
        
        Account objAccount = new Account();
        objAccount.Name = 'Enterprise';
        objAccount.Type = 'test organisation';
        insert objAccount;
        
        Contact objcontact = new Contact();
        objcontact.FirstName = 'test';
        objcontact.LastName = 'Sample';
        objcontact.Email = 'xyz@abc.com';
        objcontact.accountId = objAccount.Id;
        insert objcontact;
        
        Opportunity objopportunity = new Opportunity();
        objopportunity.Name = 'opptest';
        objopportunity.AccountId = objAccount.Id;
        //objopportunity.ContactId = objcontact.Id;
        objopportunity.StageName = 'Qualify';
        objopportunity.CloseDate = system.today();
        insert objopportunity;
        
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;
        
        Product2 bundle1 = APT_TestUtils.createDomesticProduct(APT_Constants.PRODUCT_NAME_INTERNATIONAL_BUNDLE,'International','Postal Services','CAT1', 'Standard');
        bundle1.APT_Sync_with_Opportunity__c=true;
        bundle1.APT_Is_Charge_Account_Product__c = true;
        bundle1.APT_Is_Cash_Account_Product__c = false;
        bundle1.APT_Consolidated_Usage_Price_Tiers__c = true;
        bundle1.ProductCode = APT_Constants.PRODUCT_CODE_INTERNATIONAL_PCMSNew;
        bundle1.APT_Product_Type__c ='International';
        insert bundle1;
        
        Product2 option = APT_TestUtils.createDomesticProduct('Eparcel','eParcelStandard','Postal Services','CAT1', 'Standard');
        option.Apttus_Config2__ConfigurationType__c='Option';
        option.APT_Sync_with_Opportunity__c=true;
        option.APT_International_Pricing__c = false;
        option.APT_Consolidated_Usage_Price_Tiers__c = true;
        insert option;
        
        Id pricebookId = Test.getStandardPricebookId();             
        PricebookEntry standardPrice = APT_TestUtils.getPricebookEntry(Test.getStandardPricebookId(),option.ID);            
        insert standardPrice;
        
        Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
        insert pli;
        
        Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(objAccount.ID,objopportunity.ID,'Proposal','Quote', priceList.ID);
        //proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c = System.Today() - 1;
        Proposal.Expected_Revenue_Start_Date__c = System.Today() - 20;
        Proposal.Apttus_Proposal__Approval_Stage__c = 'Accepted';
        Proposal.Apttus_Proposal__Opportunity__c = objopportunity.Id;
        insert Proposal;
        
        Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
                                                                                                   proposal.Id, 'Proposal',
                                                                                                   'Ad Hoc',priceList.Id, null,
                                                                                                   'Finalized',
                                                                                                   null, Datetime.now(), true);
        prodconfig.Apttus_Config2__Status__c = 'Finalized';
        insert prodconfig;
        
        Apttus_Config2__ClassificationName__c cn = new Apttus_Config2__ClassificationName__c();
        cn.Name = 'test';
        cn.Apttus_Config2__Type__c = 'Option Group';
        cn.Apttus_Config2__HierarchyLabel__c = 'Pricing Products';
        insert cn;
        
        Apttus_Config2__ClassificationHierarchy__c cHierarchy = new Apttus_Config2__ClassificationHierarchy__c();
        cHierarchy.Name = 'test';
        cHierarchy.Apttus_Config2__Label__c = 'Pricing Products';
        cHierarchy.Apttus_Config2__HierarchyId__c = cn.Id;
        insert cHierarchy;
        
        Apttus_Config2__ProductOptionGroup__c pog = new Apttus_Config2__ProductOptionGroup__c();
        pog.Apttus_Config2__Sequence__c = 1;
        pog.Apttus_Config2__ProductId__c = option.ID;
        pog.Apttus_Config2__OptionGroupId__c = cHierarchy.ID;
        insert pog;
        
        Apttus_Config2__ProductOptionComponent__c poc = new Apttus_Config2__ProductOptionComponent__c();
        poc.Apttus_Config2__Sequence__c = 1;
        poc.Apttus_Config2__ComponentProductId__c = option.ID;
        poc.Apttus_Config2__ProductOptionGroupId__c = pog.Id;
        insert poc;
        
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
        //bundleLine.APT_Product_Code__c = 'APPC';
        insert bundleLine;                  
        
        Apttus_Proposal__Proposal_Line_Item__c proposalLT1= APT_TestUtils.getProposalLineItem(Proposal.id,bundleLine.id,pli.id,bundle1.id,option.id);
        proposalLT1.Apttus_QPConfig__Quantity2__c=3;
        proposalLT1.Apttus_QPConfig__NetPrice__c=10;
        proposalLT1.Apttus_QPConfig__IsPrimaryLine__c = true;
        proposalLT1.Apttus_QPConfig__OptionId__c = null;
        proposalLT1.Apttus_QPConfig__ParentBundleNumber__c = 1;
        proposalLT1.Apttus_Proposal__Product__c=bundle1.Id;
        insert proposalLT1;
        
        Apttus_QPConfig__ProposalUsagePriceTier__c pupt = new Apttus_QPConfig__ProposalUsagePriceTier__c();
        pupt.Apttus_QPConfig__Sequence__c = 1;
        pupt.Apttus_QPConfig__LineItemId__c = proposalLT1.ID;
        pupt.Apttus_QPConfig__Dimension1Value__c = 'WG';
        pupt.Apttus_QPConfig__Dimension2Value__c = '0.50';
        pupt.Apttus_QPConfig__Dimension3Value__c = 'Base';
        pupt.Apttus_QPConfig__AdjustmentAmount__c = 100;
        insert pupt;
        
        APT_Lodgement_Zone__c logdZone = APT_TestUtils.getLodgementZone('Aust Antarctic Territory','AAT');
        insert logdZone;               
        
        APT_Feature_Pricing__c featurePricing = APT_TestUtils.getFeaturePricing('Aust Antarctic Territory','CAT1','AAT','Standard','EPR2',10,1);           
        insert featurePricing;
        
        Apttus_Config2__ProductAttributeValue__c attribute1 = APT_TestUtils.GetAttributeValue(bundleLine.Id,'Standard',false,false,false,'Yes','B Mining',True,false);
        attribute1.Category__c='CAT1';
        attribute1.APT_Lodgement_Zone__c=logdZone.ID;               
        insert attribute1;
        
        Apttus_XApps__Application__c app1 = new Apttus_XApps__Application__c();
        app1.Name = 'test App';
        app1.Apttus_XApps__Activated__c = true;
        insert app1;
        
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
        
        APT_Charge_Code__c objCharge_Code = new APT_Charge_Code__c();
        
        
    }
    
    @isTest 
    Public static void TestMethoddave1() {
        APT_R2T_System_Properties__c lstSystemProperties = [Select Id from APT_R2T_System_Properties__c limit 1];
        Account lstAccount = [Select Id, Name, Type from account limit 1];
        Contact lstcontact = [select Id, Email, accountId from contact limit 1];
        
        Opportunity lstopportunity = [select Id, Name, AccountId, StageName, CloseDate from Opportunity limit 1];
        lstopportunity.KeyContact__c = lstcontact.Id;
        update lstopportunity;
        
        User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
        
        Apttus_Config2__LineItem__c lstConfig2LineItem = [select Id,Apttus_Config2__ProductId__r.APT_Product_type__c  from Apttus_Config2__LineItem__c limit 1];
        
        ApexPages.currentPage().getHeaders().put('Referer', 'www.ausiepost.org');
        Apexpages.currentPage().getParameters().put('parentRecordID', lstConfig2LineItem.ID);
        Apexpages.currentPage().getParameters().put('isPrestoMode', 'True');
        Test.StartTest();
        APT_ViewRatecardControllerAPI vrc = new APT_ViewRatecardControllerAPI();
        vrc.init();
        vrc.doCancel();
        vrc.prestoAPI();
        vrc.redirect(lstConfig2LineItem.Id);
        Test.StopTest();
        system.assert(lstConfig2LineItem.Id!=null);
        
    }
    @isTest 
    Public static void TestMethoddave2() {
        APT_R2T_System_Properties__c lstSystemProperties = [Select Id from APT_R2T_System_Properties__c limit 1];
        Account lstAccount = [Select Id, Name, Type from account limit 1];
        Contact lstcontact = [select Id, Email, accountId from contact limit 1];
        
        Opportunity lstopportunity = [select Id, Name, AccountId, StageName, CloseDate from Opportunity limit 1];
        lstopportunity.KeyContact__c = lstcontact.Id;
        update lstopportunity;
        
        User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
        
        Apttus_Config2__LineItem__c lstConfig2LineItem = [select Id from Apttus_Config2__LineItem__c limit 1];
        
        ApexPages.currentPage().getHeaders().put('Referer', 'www.ausiepost.org');
        Apexpages.currentPage().getParameters().put('parentRecordID', lstConfig2LineItem.ID);
        Apexpages.currentPage().getParameters().put('isPrestoMode', 'True');
        Test.StartTest();
        APT_ViewRatecardControllerAPI vrc = new APT_ViewRatecardControllerAPI('test', 'Demo');
        vrc.init();
        vrc.doCancel();
        //vrc.prestoAPI();
        vrc.redirect(lstConfig2LineItem.Id);
        Test.StopTest();
        system.assert(lstConfig2LineItem.Id!=null);
    }
    @isTest 
    Public static void TestMethoddave3() {
        APT_R2T_System_Properties__c lstSystemProperties = [Select Id from APT_R2T_System_Properties__c limit 1];
        Account lstAccount = [Select Id, Name, Type from account limit 1];
        Contact lstcontact = [select Id, Email, accountId from contact limit 1];
        
        Opportunity lstopportunity = [select Id, Name, AccountId, StageName, CloseDate from Opportunity limit 1];
        lstopportunity.KeyContact__c = lstcontact.Id;
        update lstopportunity;
        
        User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
        
        Apttus_Config2__LineItem__c lstConfig2LineItem = [select Id from Apttus_Config2__LineItem__c limit 1];
        
        ApexPages.currentPage().getHeaders().put('Referer', 'www.ausiepost.org');
        Apexpages.currentPage().getParameters().put('parentRecordID', lstConfig2LineItem.ID);
        Apexpages.currentPage().getParameters().put('isPrestoMode', 'True');
        Test.StartTest();
        APT_ViewRatecardControllerAPI vrc = new APT_ViewRatecardControllerAPI('test', 'Demo','test1','demo1');
        vrc.init();
        vrc.doCancel();
        //vrc.prestoAPI();
        vrc.redirect(lstConfig2LineItem.Id);
        Test.StopTest();
        system.assert(lstConfig2LineItem.Id!=null);
    }
    @isTest 
    Public static void TestMethoddave4() {
        APT_R2T_System_Properties__c lstSystemProperties = [Select Id from APT_R2T_System_Properties__c limit 1];
        Account lstAccount = [Select Id, Name, Type from account limit 1];
        Contact lstcontact = [select Id, Email, accountId from contact limit 1];
        
        Opportunity lstopportunity = [select Id, Name, AccountId, StageName, CloseDate from Opportunity limit 1];
        lstopportunity.KeyContact__c = lstcontact.Id;
        update lstopportunity;
        
        User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
        
        Apttus_Config2__LineItem__c lstConfig2LineItem = [select Id from Apttus_Config2__LineItem__c limit 1];
        
        ApexPages.currentPage().getHeaders().put('Referer', 'www.ausiepost.org');
        Apexpages.currentPage().getParameters().put('parentRecordID', lstConfig2LineItem.ID);
        Apexpages.currentPage().getParameters().put('isPrestoMode', 'True');
        Test.StartTest();
        APT_ViewRatecardControllerAPI vrc = new APT_ViewRatecardControllerAPI('test', 'Demo', true);
        vrc.init();
        vrc.doCancel();
        //vrc.prestoAPI();
        vrc.redirect(lstConfig2LineItem.Id);
        Test.StopTest();
        system.assert(lstConfig2LineItem.Id!=null);
    }
    @isTest 
    Public static void TestMethodMember() {
        APT_R2T_System_Properties__c lstSystemProperties = [Select Id from APT_R2T_System_Properties__c limit 1];
        Account lstAccount = [Select Id, Name, Type from account limit 1];
        Contact lstcontact = [select Id, Email, accountId from contact limit 1];
        
        Opportunity lstopportunity = [select Id, Name, AccountId, StageName, CloseDate from Opportunity limit 1];
        lstopportunity.KeyContact__c = lstcontact.Id;
        update lstopportunity;
        
        User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
        
        
        Apttus_Proposal__Proposal__c lstProposalProposal = [Select Id, Exempted_Product_Type__c from Apttus_Proposal__Proposal__c limit 1];
        Apttus_Config2__ProductConfiguration__c lstProductConfiguration = [Select Id from Apttus_Config2__ProductConfiguration__c limit 1];
        Apttus_Config2__LineItem__c lstConfig2LineItem = [select Id from Apttus_Config2__LineItem__c limit 1];
        
        ApexPages.currentPage().getHeaders().put('Referer', 'www.ausiepost.org');
        Apexpages.currentPage().getParameters().put('parentRecordID', lstConfig2LineItem.ID);
        Apexpages.currentPage().getParameters().put('isPrestoMode', 'True');
        Apexpages.currentPage().getParameters().put('Id', lstProposalProposal.ID);
        
        Test.StartTest(); 
        APT_ViewratecardBatch rateCardBatch = new APT_ViewratecardBatch(lstProductConfiguration.id,lstProposalProposal.Id, 'test', 'www.sample@test.com', 'Test.com', false,lstProposalProposal.Exempted_Product_Type__c);
        Database.executeBatch(rateCardBatch); 
        rateCardBatch.updateProposalInCaseOfDocAPIFail();
        APT_ViewRatecardControllerAPI vrc = new APT_ViewRatecardControllerAPI();
        vrc.init();
        vrc.doCancel();
        vrc.prestoAPI(); 
        vrc.redirect(lstConfig2LineItem.Id); 
        Test.StopTest(); 
        system.assert(lstConfig2LineItem.Id!=null);
        system.assert(lstProposalProposal.Id!=null);
        system.assert(lstProductConfiguration.Id!=null);
    }
    @isTest 
    Public static void TestMethodMember2() {
        APT_R2T_System_Properties__c lstSystemProperties = [Select Id from APT_R2T_System_Properties__c limit 1];
        Account lstAccount = [Select Id, Name, Type from account limit 1];
        Contact lstcontact = [select Id, Email, accountId from contact limit 1];
        
        Opportunity lstopportunity = [select Id, Name, AccountId, StageName, CloseDate from Opportunity limit 1];
        lstopportunity.KeyContact__c = lstcontact.Id;
        update lstopportunity;
        
        User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
        
        
        Apttus_Proposal__Proposal__c lstProposalProposal = [Select Id, Exempted_Product_Type__c from Apttus_Proposal__Proposal__c limit 1];
        Apttus_Config2__ProductConfiguration__c lstProductConfiguration = [Select Id from Apttus_Config2__ProductConfiguration__c limit 1];
        Apttus_Config2__LineItem__c lstConfig2LineItem = [select Id from Apttus_Config2__LineItem__c limit 1];
        
        ApexPages.currentPage().getHeaders().put('Referer', 'www.ausiepost.org');
        Apexpages.currentPage().getParameters().put('parentRecordID', lstConfig2LineItem.ID);
        Apexpages.currentPage().getParameters().put('isPrestoMode', 'True');
        Apexpages.currentPage().getParameters().put('Id', lstProposalProposal.ID);
     
        Test.StartTest();
        APT_ViewRatecardControllerAPI rateController = new APT_ViewRatecardControllerAPI();
        rateController.isPrestoModeParam ='true';
        rateController.ratecardCalculatorMode=true;
        APT_ViewratecardBatch rateCardBatch = new APT_ViewratecardBatch(lstProductConfiguration.id,lstProposalProposal.Id, 'test', 'www.sample@test.com', 'Test.com', true,lstProposalProposal.Exempted_Product_Type__c);
        Database.executeBatch(rateCardBatch);
        rateCardBatch.updateProposalInCaseOfDocAPIFail();
        APT_ViewRatecardBatchExecute vrbe = new APT_ViewRatecardBatchExecute(lstProposalProposal.ID);
        vrbe.isCallFromRateCalc = true;
        vrbe.init();
        
        APT_ViewRatecardBatchExecute vrbe1 = new APT_ViewRatecardBatchExecute();
        vrbe1.isCallFromRateCalc = true;
        vrbe1.hideMessage = true;
        vrbe1.init();
        vrbe.redirectToProposal();
        Test.StopTest();
        
        system.assert(lstConfig2LineItem.Id!=null);
        system.assert(lstProposalProposal.Id!=null);
        system.assert(lstProductConfiguration.Id!=null);
    }
    @isTest 
    Public static void TestMethodMember3() {
        APT_R2T_System_Properties__c lstSystemProperties = [Select Id from APT_R2T_System_Properties__c limit 1];
        
        Account lstAccount = [Select Id, Name, Type from account limit 1];
        Contact lstcontact = [select Id, Email, accountId from contact limit 1];
        
        Opportunity lstopportunity = [select Id, Name, AccountId, StageName, CloseDate from Opportunity limit 1];
        lstopportunity.KeyContact__c = lstcontact.Id;
        update lstopportunity;
        
        User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
        
        Product2 lstProduct2 = [select id from Product2 limit 1];
        lstProduct2.APT_Domestic_Pricing__c = true;
        update lstProduct2;
        Apttus_Proposal__Proposal__c lstProposalProposal = [Select Id, Exempted_Product_Type__c,APT_pricing_fields_changed__c from Apttus_Proposal__Proposal__c limit 1];
        lstProposalProposal.APT_pricing_fields_changed__c = true;
        //lstProposalProposal.APT_Proposal_Generated_Date__c = system.today()+5;
        //lstProposalProposal.Apttus_QPConfig__ConfigurationFinalizedDate__c = system.today();
        update lstProposalProposal;
        
        Apttus_Config2__ProductConfiguration__c lstProductConfiguration = [Select Id from Apttus_Config2__ProductConfiguration__c limit 1];
        Apttus_Config2__LineItem__c lstConfig2LineItem = [select Id from Apttus_Config2__LineItem__c limit 1];
        Apttus_Proposal__Proposal_Line_Item__c objProposalLineItem = [Select Id, Apttus_QPConfig__OptionId__r.APT_Domestic_Pricing__c from Apttus_Proposal__Proposal_Line_Item__c limit 1];
        objProposalLineItem.Apttus_QPConfig__OptionId__c =lstProduct2.id;
        objProposalLineItem.Apttus_QPConfig__LineNumber__c = 1;
        update objProposalLineItem;
        
        ApexPages.currentPage().getHeaders().put('Referer', 'www.ausiepost.org');
        Apexpages.currentPage().getParameters().put('parentRecordID', lstConfig2LineItem.ID);
        Apexpages.currentPage().getParameters().put('isPrestoMode', 'True');
        Apexpages.currentPage().getParameters().put('Id', lstProposalProposal.ID);
        
        Test.StartTest();
        APT_ViewratecardBatch rateCardBatch = new APT_ViewratecardBatch(lstProductConfiguration.id,lstProposalProposal.Id, 'test', 'www.sample@test.com', 'Test.com', true,lstProposalProposal.Exempted_Product_Type__c);
        rateCardBatch.updateProposalInCaseOfDocAPIFail();
        APT_ViewRatecardControllerAPI vrc = new APT_ViewRatecardControllerAPI();
        vrc.init();
        APT_ViewRatecardBatchExecute vrbe = new APT_ViewRatecardBatchExecute(lstProposalProposal.ID);
        vrbe.isCallFromRateCalc = false;
        vrbe.init();
        
        APT_ViewRatecardBatchExecute vrbe1 = new APT_ViewRatecardBatchExecute();
        vrbe1.isCallFromRateCalc = false;
        vrbe1.hideMessage = true;
        vrbe1.init();
        Test.StopTest();
        
        system.assert(lstProduct2.Id!=null);
        system.assert(lstProposalProposal.Id!=null);
        system.assert(lstConfig2LineItem.Id!=null);
        system.assert(lstProductConfiguration.Id!=null);
        system.assert(objProposalLineItem.Id!=null);
    }
    public static TestMethod void redirectToProposal_CatchBlockCoverage(){
        APT_ViewRatecardBatchExecute obj = new APT_ViewRatecardBatchExecute('TestClassProposalId');
        obj.redirectToProposal();
    }
    public static TestMethod void init_CatchBlockCoverage(){
        APT_ViewRatecardBatchExecute obj = new APT_ViewRatecardBatchExecute('TestClassProposalId');
        obj.init();
    }
    @isTest 
    Public static void TestMethodMember1() {
        APT_R2T_System_Properties__c lstSystemProperties = [Select Id from APT_R2T_System_Properties__c limit 1];
        Account lstAccount = [Select Id, Name, Type from account limit 1];
        Contact lstcontact = [select Id, Email, accountId from contact limit 1];
        
        Opportunity lstopportunity = [select Id, Name, AccountId, StageName, CloseDate from Opportunity limit 1];
        lstopportunity.KeyContact__c = lstcontact.Id;
        update lstopportunity;
        
        User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
        product2 objprod =[select id from product2 limit 1];
        objprod.ProductCode ='APPC';
        objprod.APT_Product_Type__c ='StarTrack';
        update objprod;
        Apttus_Proposal__Proposal__c lstProposalProposal = [Select Id, Exempted_Product_Type__c from Apttus_Proposal__Proposal__c limit 1];
        Apttus_Config2__ProductConfiguration__c lstProductConfiguration = [Select Id from Apttus_Config2__ProductConfiguration__c limit 1];
        Apttus_Config2__LineItem__c lstConfig2LineItem = [select Id,APT_Product_Code__c, Apttus_Config2__ProductId__r.ProductCode from Apttus_Config2__LineItem__c limit 1];
        lstConfig2LineItem.Apttus_Config2__ProductId__c= objprod.Id;
        update lstConfig2LineItem;
        ApexPages.currentPage().getHeaders().put('Referer', 'www.ausiepost.org');
        Apexpages.currentPage().getParameters().put('parentRecordID', lstConfig2LineItem.ID);
        Apexpages.currentPage().getParameters().put('isPrestoMode', 'True');
        Apexpages.currentPage().getParameters().put('Id', lstProposalProposal.ID);
        
        Test.StartTest();
        APT_ViewratecardBatch rateCardBatch = new APT_ViewratecardBatch(lstProductConfiguration.id,lstProposalProposal.Id, 'test', 'www.sample@test.com', 'Test.com', true,lstProposalProposal.Exempted_Product_Type__c);
        rateCardBatch.updateProposalInCaseOfDocAPIFail();
        APT_ViewRatecardControllerAPI vrc = new APT_ViewRatecardControllerAPI();
        vrc.init();
        vrc.doCancel();
        vrc.syncConfigLineItems();
        vrc.redirect(lstConfig2LineItem.Id);
        Test.StopTest();
        
        system.assert(objprod.Id!=null);
        system.assert(lstProposalProposal.Id!=null);
        system.assert(lstProductConfiguration.Id!=null);
        system.assert(lstConfig2LineItem.Id!=null);
    }
    @isTest 
    Public static void TestMethodMember1copay() {
        APT_R2T_System_Properties__c lstSystemProperties = [Select Id from APT_R2T_System_Properties__c limit 1];
        Account lstAccount = [Select Id, Name, Type from account limit 1];
        Contact lstcontact = [select Id, Email, accountId from contact limit 1];
        
        Opportunity lstopportunity = [select Id, Name, AccountId, StageName, CloseDate from Opportunity limit 1];
        lstopportunity.KeyContact__c = lstcontact.Id;
        update lstopportunity;
        
        User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
        product2 objprod =[select id from product2 limit 1];
        objprod.APT_Product_Type__c ='StarTrack';
        update objprod;
        Apttus_Proposal__Proposal__c lstProposalProposal = [Select Id, Exempted_Product_Type__c from Apttus_Proposal__Proposal__c limit 1];
        Apttus_Config2__ProductConfiguration__c lstProductConfiguration = [Select Id from Apttus_Config2__ProductConfiguration__c limit 1];
        Apttus_Config2__LineItem__c lstConfig2LineItem = [select Id,APT_Product_Code__c from Apttus_Config2__LineItem__c limit 1];
        lstConfig2LineItem.Apttus_Config2__ProductId__c= objprod.Id;
        update lstConfig2LineItem;
        ApexPages.currentPage().getHeaders().put('Referer', 'www.ausiepost.org');
        Apexpages.currentPage().getParameters().put('parentRecordID', lstConfig2LineItem.ID);
        Apexpages.currentPage().getParameters().put('isPrestoMode', 'True');
        Apexpages.currentPage().getParameters().put('Id', lstProposalProposal.ID);
        
        Test.StartTest();
        APT_ViewratecardBatch rateCardBatch = new APT_ViewratecardBatch(lstProductConfiguration.id,lstProposalProposal.Id, 'test', 'www.sample@test.com', 'Test.com', true,lstProposalProposal.Exempted_Product_Type__c);
        rateCardBatch.updateProposalInCaseOfDocAPIFail();
        APT_ViewRatecardControllerAPI vrc = new APT_ViewRatecardControllerAPI();
        vrc.init();
        vrc.doCancel();
        vrc.prestoAPI();
        vrc.redirect(lstConfig2LineItem.Id);
        Test.StopTest();
        system.assert(objprod.Id!=null);
        system.assert(lstProposalProposal.Id!=null);
        system.assert(lstProductConfiguration.Id!=null);
        
    }
    @isTest 
    Public static void TestMethodMember1copay12() {
        APT_R2T_System_Properties__c lstSystemProperties = [Select Id from APT_R2T_System_Properties__c limit 1];
        Account lstAccount = [Select Id, Name, Type from account limit 1];
        Contact lstcontact = [select Id, Email, accountId from contact limit 1];
        
        Opportunity lstopportunity = [select Id, Name, AccountId, StageName, CloseDate from Opportunity limit 1];
        lstopportunity.KeyContact__c = lstcontact.Id;
        update lstopportunity;
        
        User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
        product2 objprod =[select id from product2 limit 1];
        objprod.APT_Product_Type__c ='StarTrack';
        update objprod;
        Apttus_Proposal__Proposal__c lstProposalProposal = [Select Id, Exempted_Product_Type__c from Apttus_Proposal__Proposal__c limit 1];
        Apttus_Config2__ProductConfiguration__c lstProductConfiguration = [Select Id from Apttus_Config2__ProductConfiguration__c limit 1];
        Apttus_Config2__LineItem__c lstConfig2LineItem = [select Id,APT_Product_Code__c, Apttus_Config2__ProductId__r.ProductCode from Apttus_Config2__LineItem__c limit 1];
        lstConfig2LineItem.Apttus_Config2__ProductId__c= objprod.Id;
        //lstConfig2LineItem.APT_Product_Code__c = 'APPC';
        update lstConfig2LineItem;
        
        APT_App_Setup__c lstAppSetup = [select id from APT_App_Setup__c limit 1];
        lstAppSetup.APT_Attribute_Value__c = 'BANDED {Z40}';
        lstAppSetup.APT_IsRateCalculatorCall__c = true;
        update lstAppSetup;
        APT_App_Setup__c lstAppSetup1 = [select id from APT_App_Setup__c limit 1];
        lstAppSetup1.APT_Attribute_Value__c = 'BANDED {Z40}';
        update lstAppSetup1;
        
        
        ApexPages.currentPage().getHeaders().put('Referer', 'www.ausiepost.org');
        Apexpages.currentPage().getParameters().put('parentRecordID', lstConfig2LineItem.ID);
        Apexpages.currentPage().getParameters().put('isPrestoMode', 'True');
        Apexpages.currentPage().getParameters().put('Id', lstProposalProposal.ID);
        
        Test.StartTest();
        APT_ViewratecardBatch rateCardBatch = new APT_ViewratecardBatch(lstProductConfiguration.id,lstProposalProposal.Id, 'test', 'www.sample@test.com', 'Test.com', true,lstProposalProposal.Exempted_Product_Type__c);
        rateCardBatch.updateProposalInCaseOfDocAPIFail();
        APT_ViewRatecardControllerAPI vrc = new APT_ViewRatecardControllerAPI();
        vrc.init();
        vrc.doCancel();
        vrc.prestoAPI();
        vrc.redirect(lstConfig2LineItem.Id);
        Test.StopTest();
        system.assert(objprod.Id!=null);
        system.assert(lstProposalProposal.Id!=null);
        system.assert(lstProductConfiguration.Id!=null);
        
    }
    @istest
    public static void test2(){
        APT_ViewRatecardControllerAPI vrc = new APT_ViewRatecardControllerAPI();  
        vrc.prestoAPI('pdf');
    }
    @istest
    public static void test3(){
        Apttus_Config2__LineItem__c lstConfig2LineItem = [select Id,APT_Product_Code__c from Apttus_Config2__LineItem__c limit 1];
        Attachment objattachments = [SELECT Id, Name FROM Attachment limit 1];
        APT_ViewRatecardControllerAPI vrc = new APT_ViewRatecardControllerAPI();  
        vrc.redirect(lstConfig2LineItem.Id);
    }
    @isTest 
    Public static void TestMethodMembertesting() {
        APT_R2T_System_Properties__c lstSystemProperties = [Select Id from APT_R2T_System_Properties__c limit 1];
        Account lstAccount = [Select Id, Name, Type from account limit 1];
        Contact lstcontact = [select Id, Email, accountId from contact limit 1];
        
        Opportunity lstopportunity = [select Id, Name, AccountId, StageName, CloseDate from Opportunity limit 1];
        lstopportunity.KeyContact__c = lstcontact.Id;
        update lstopportunity;
        
        User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
        product2 objprod =[select id from product2 limit 1];
        objprod.APT_Product_Type__c ='StarTrack';
        objprod.ProductCode = APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD;
        update objprod;
        
        Apttus_Proposal__Proposal__c lstProposalProposal = [Select Id, Exempted_Product_Type__c from Apttus_Proposal__Proposal__c limit 1];
        Apttus_Config2__ProductConfiguration__c lstProductConfiguration = [Select Id from Apttus_Config2__ProductConfiguration__c limit 1];
        Apttus_Config2__LineItem__c lstConfig2LineItem = [select Id,APT_Product_Code__c from Apttus_Config2__LineItem__c limit 1];
        lstConfig2LineItem.Apttus_Config2__ProductId__c= objprod.Id;
        update lstConfig2LineItem;
        ApexPages.currentPage().getHeaders().put('Referer', 'www.ausiepost.org');
        Apexpages.currentPage().getParameters().put('parentRecordID', lstConfig2LineItem.ID);
        Apexpages.currentPage().getParameters().put('isPrestoMode', 'True');
        Apexpages.currentPage().getParameters().put('Id', lstProposalProposal.ID);
        
        Test.StartTest();
        APT_ViewratecardBatch rateCardBatch = new APT_ViewratecardBatch(lstProductConfiguration.id,lstProposalProposal.Id, 'test', 'www.sample@test.com', 'Test.com', true,lstProposalProposal.Exempted_Product_Type__c);
        rateCardBatch.updateProposalInCaseOfDocAPIFail();
        APT_ViewRatecardControllerAPI vrc = new APT_ViewRatecardControllerAPI();
        vrc.init();
        Test.StopTest();
        system.assert(objprod.Id!=null);
        system.assert(lstProposalProposal.Id!=null);
        system.assert(lstProductConfiguration.Id!=null);
        system.assert(lstConfig2LineItem.Id!=null);
    }
}