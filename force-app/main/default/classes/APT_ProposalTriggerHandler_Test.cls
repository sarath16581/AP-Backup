/**
This apex class is test class for APT_ProposalTriggerHandler.
Created By - Adil Muzaffar
Created Date - 7th Dec, 2015
Last Modified By -
Last Modified Date -

2021.07.01 seth.heang@auspost.com.au    Add code coverage for auto-population functionality of proposal's APT_Method_of_Payment__c field
2023.05.02 nasir.jawed2@auspost.com.au  Added Account_Plan__c data to cover the test coverage for testMethod3()
**/
@isTest
private with sharing class APT_ProposalTriggerHandler_Test {
    /**
    Creating test data
    **/
static testMethod void testMethod1() {
      //  APT_ProposalTriggerHandler controller = new APT_ProposalTriggerHandler();
        
        //Create Account
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {    
         Account acc = APT_TestUtils.createOrganisation();
         insert acc;                          
         
         //Create Opportunity
         Opportunity opty = APT_TestUtils.createOpportunity(acc.id);
         opty.Type_of_billing_account_required__c = 'Charge account and sub-account';
         opty.Sender_name_to_appear_on_parcel_label__c = 'Tony';
         insert opty;
         
         Opportunity opty2 = APT_TestUtils.createOpportunity(acc.id);
         opty2.Type_of_billing_account_required__c = 'Charge account';
         opty2.Sender_name_to_appear_on_parcel_label__c = 'Smith';
         insert opty2;
         
         //Create PriceList
         Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
         insert priceList;
         
         //create international product
         Product2 bundle1 = APT_TestUtils.createInternationalProduct('International Bundle','eParcelStandard','Postal Services');
         bundle1.APT_Sync_with_Opportunity__c = TRUE;
         bundle1.APT_Is_Cash_Account_Product__c = false;
         bundle1.APT_Is_Charge_Account_Product__c =true;
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
         
         //create networ
         Network__c ntwk = APT_TestUtils.createNetwork();
         insert ntwk;
         
         //Create Proposal
         Apttus_Proposal__Proposal__c Proposal1= APT_TestUtils.getQuoteProposal(acc.id,opty.id,'Proposal','Quote', priceList.id);
         Proposal1.Apttus_Proposal__Approval_Stage__c='Accepted';
        // Proposal.APT_Method_of_Payment__c = 'Cash Account';
         insert Proposal1;
         
         Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.id,opty2.id,'Proposal','Quote', priceList.id);
         Proposal.Apttus_Proposal__Approval_Stage__c='Draft';
         Proposal.Expected_Revenue_Start_Date__c = System.today();
         Proposal.Expected_Revenue_End_Date__c = System.today() +90;
         Proposal.Apttus_Proposal__Primary__c =false;
         Proposal.APT_Selected_LP__c = ntwk.id;
         insert Proposal;
         
         //Create Product Configuration             
         Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
         proposal.id, 'Proposal',
         'Ad Hoc',priceList.id, null,
         'Finalized',
         null, Datetime.now(), true);
         insert prodconfig;
         
         // Create Network
         Network__c networkObj = new Network__c(Name='Test Network');
         Insert networkObj;
         
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
            bundleLine.APT_Lodgement_Zone_Selected__c = String.valueOf(networkObj.Id);
            insert bundleLine;                  
          
          
            APT_Quote_Rate_Card__c ratecrd = new APT_Quote_Rate_Card__c();
            ratecrd.APT_Line_Item__c = bundleLine.Id;
            ratecrd.APT_Value_1__c = 'Val1';
            insert ratecrd;
            
           //Create Proposal Line Item               
            Apttus_Proposal__Proposal_Line_Item__c proposalLT1= APT_TestUtils.getProposalLineItem(Proposal.id,bundleLine.id,pli.id,bundle1.id,option.Id);
            proposalLT1.Apttus_QPConfig__Quantity2__c=3;
            proposalLT1.Apttus_QPConfig__NetPrice__c=10;
           // proposalLT1.Apttus_QPConfig__DerivedFromId__c = bundleLine.Id;
            proposalLT1.Apttus_QPConfig__OptionId__c = null;
            insert proposalLT1;
            
            
                    
           //Create Proposal Product AttributeValue
           Apttus_QPConfig__ProposalProductAttributeValue__c ProposalProductAttributeValue1 =APT_TestUtils.getProposalProductAttributeValue(proposalLT1.id);
           insert ProposalProductAttributeValue1;
            List<Apttus_Proposal__Proposal__c> newlist = new List<Apttus_Proposal__Proposal__c>();
             newlist.add(proposal1);
                           
            map<id, Apttus_Proposal__Proposal__c> map1 = new map<id, Apttus_Proposal__Proposal__c>();
                    map1.put(proposal.id,proposal);
            
            set<Apttus_Proposal__Proposal__c> setproposals = new set<Apttus_Proposal__Proposal__c>();
            set<Id> setids = new set<Id>();
            setproposals.add(proposal);
            setids.add(proposal.Id);
            test.startTest(); //10/23/2019 added as a fix for the SOQL error
            
            Proposal.Expected_Revenue_Start_Date__c = System.today() + 2;
            Proposal.Expected_Revenue_End_Date__c = System.today() + 32;
           
            update  Proposal;
            
            Proposal.Apttus_Proposal__Approval_Stage__c = 'Accepted';
            Proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c = System.today();
            Proposal.Apttus_Proposal__Primary__c = true;
            
            update Proposal;
            
            Proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c = System.today() + 5;
            
            update Proposal;
            
            proposalLT1.Apttus_QPConfig__Quantity2__c= 5;
            update proposalLT1;
            
            //APT_ProposalTriggerHandler.afterUpdateEvent(newlist,map1);
            
             //APT_ProposalTriggerHandler.sycWithOpportunity(setids);
             //APT_ProposalTriggerHandler.createQuoteLP(setproposals);
    //system.assert(pgRef == null);
            
            test.stopTest();   
            // Assert APT_Method_of_Payment__c on Proposal updated to 'Charge Account' which is mapped from Opportunity
            Apttus_Proposal__Proposal__c testPropCharge = [SELECT id, APT_Method_of_Payment__c FROM Apttus_Proposal__Proposal__c WHERE id = :Proposal.Id];
            System.assertEquals(testPropCharge.APT_Method_of_Payment__c, 'Charge Account');
            // Assert APT_Method_of_Payment__c on Proposal updated to 'Charge Account + Sub Account' which is mapped from Opportunity
            Apttus_Proposal__Proposal__c testPropChargeAndSub = [SELECT id, APT_Method_of_Payment__c FROM Apttus_Proposal__Proposal__c WHERE id = :Proposal1.Id];
            System.assertEquals(testPropChargeAndSub.APT_Method_of_Payment__c, 'Charge Account + Sub Account');
            System.assert(proposalLT1 != null);
    }
    }
    /*static testMethod void testMethod2() {
        APT_ProposalTriggerHandler controller = new APT_ProposalTriggerHandler();
        Account tempacct = APT_TestUtils.createOrganisation();
        insert tempacct;
        Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
        insert opp;
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;
       List<Apttus_Proposal__Proposal__c>  quotelist = new List<Apttus_Proposal__Proposal__c>();      
        Apttus_Proposal__Proposal__c quote1 = APT_TestUtils.getQuoteProposal(tempacct.id,opp.id,'Proposal','Test1',priceList.id);
        Apttus_Proposal__Proposal__c quote2 = APT_TestUtils.getQuoteProposal(tempacct.id,opp.id,'Proposal','Test2',priceList.id);
        quotelist.add(quote1);
        quotelist.add(quote2);
        insert quotelist;
        Set<id> ids = new Set<id>();
        for(Apttus_Proposal__Proposal__c q1 :quotelist){
        ids.add(q1.id);
        }       
        test.startTest();
        APT_ProposalTriggerHandler.sycWithOpportunity(ids);
        //system.assert(pgRef == null);
        test.stopTest();        
    }*/
        /**
    Creating test data
    **/
    static testMethod void testMethod3() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {  
                //Create Account
         Account acc = APT_TestUtils.createOrganisation();
         insert acc;                          
         
		//Create Account Plan Record
		Account_Plan__c ap= APT_TestDataFactory.getAccountPlanRecord(1,acc.id,false)[0];
		insert ap;
         //Create Opportunity
         Opportunity opty = APT_TestUtils.createOpportunity(acc.id);
		opty.Account_Plan__c=ap.id;
		opty.Amount =1;
         insert opty;
         
         //Create PriceList
         Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
         insert priceList;
         
         //create international product
         Product2 bundle1 = APT_TestUtils.createInternationalProduct('International Bundle','eParcelStandard','Postal Services');
         bundle1.APT_Sync_with_Opportunity__c = TRUE;
         bundle1.APT_Is_Cash_Account_Product__c = false;
         bundle1.APT_Is_Charge_Account_Product__c =true;
         insert bundle1;
         
         //Create Budget_and_Revenue__c
         Budget_and_Revenue__c barObj = new Budget_and_Revenue__c();
         barObj.Name = 'Test Name';
         barObj.Organisation__c = acc.Id;
         barObj.Int_Last_Upd_Date__c = System.today().addDays(-90);
         barObj.Product__c = bundle1.Id;
         
         Insert barObj;
         
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
         
         //create networ
         List<Network__c> lstntwk = new List<Network__c>();
         Network__c ntwk = APT_TestUtils.createNetwork();
         lstntwk.add(ntwk);
         Network__c ntwk1 = APT_TestUtils.createNetwork();
         ntwk1.Name = 'Lodgement Point 2';
         ntwk1.Post_Code__c = '2323';
         ntwk1.Org_ID__c = 'A1pOMJJ0QXeb';
         ntwk1.APT_DWS_ID__c = 'A1pOMJJ0QXeb';
         lstntwk.add(ntwk1);
         insert lstntwk;
         
         //Create Proposal
         Apttus_Proposal__Proposal__c Proposal1= APT_TestUtils.getQuoteProposal(acc.id,opty.id,'Proposal','Quote', priceList.id);
         Proposal1.Apttus_Proposal__Approval_Stage__c='Draft';
         
         insert Proposal1;
         
         Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.id,opty.id,'Proposal','Quote', priceList.id);
         Proposal.Apttus_Proposal__Approval_Stage__c='Draft';
         Proposal.Expected_Revenue_Start_Date__c = System.today();
         Proposal.Expected_Revenue_End_Date__c = System.today() +90;
         Proposal.Apttus_Proposal__Primary__c =false;
         //Proposal.APT_Selected_LP__c = ntwk.id;
         insert Proposal;
         
         //Create Product Configuration             
         Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
         proposal.id, 'Proposal',
         'Ad Hoc',priceList.id, null,
         'Finalized',
         null, Datetime.now(), true);
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
            bundleLine.APT_Selected_LP__c = ntwk.Id + ',' + ntwk1.Id;
                    insert bundleLine;                  
          
           //Create Proposal Line Item               
            Apttus_Proposal__Proposal_Line_Item__c proposalLT1= APT_TestUtils.getProposalLineItem(Proposal.id,bundleLine.id,pli.id,bundle1.id,option.id);
            proposalLT1.Apttus_QPConfig__Quantity2__c=3;
            proposalLT1.Apttus_QPConfig__NetPrice__c=10;
            insert proposalLT1;
                    
           //Create Proposal Product AttributeValue
           Apttus_QPConfig__ProposalProductAttributeValue__c ProposalProductAttributeValue1 =APT_TestUtils.getProposalProductAttributeValue(proposalLT1.id);
           insert ProposalProductAttributeValue1;
            List<Apttus_Proposal__Proposal__c> newlist = new List<Apttus_Proposal__Proposal__c>();
             newlist.add(proposal1);
                           
            map<id, Apttus_Proposal__Proposal__c> map1 = new map<id, Apttus_Proposal__Proposal__c>();
                    map1.put(proposal.id,proposal);
            
            set<Apttus_Proposal__Proposal__c> setproposals = new set<Apttus_Proposal__Proposal__c>();
            set<Id> setids = new set<Id>();
            setproposals.add(proposal);
            setids.add(proposal.Id);
            test.startTest();
            
            
            Proposal.Apttus_Proposal__Approval_Stage__c = 'Accepted';
            Proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c = System.today();
            Proposal.Apttus_Proposal__Primary__c = true;
            
            update Proposal;
            
            //APT_ProposalTriggerHandler.afterUpdateEvent(newlist,map1);
            
             //APT_ProposalTriggerHandler.sycWithOpportunity(setids);
             //APT_ProposalTriggerHandler.createQuoteLP(setproposals);
    //system.assert(pgRef == null);
            
            
            test.stopTest();
            System.assert(Proposal != null);
     }
    }

    /**
     * Test amend proposal increase in revenue
     * Added by Adrian Recio
    */
    private static testMethod void testIncreaseRevenue() {
        // Get standard price book Id
        Id priceBookId = Test.getStandardPricebookId();

        //Create test admin config
        Apttus__APTS_Admin__c adminObj = APT_TestUtil2.createAptAdmin();
        insert adminObj;

        //Create validation field custom setting
        APT_R2TValidationFields__c valFieldVar = APT_TestUtil2.createAptValidationFields();
        insert valFieldVar;

        //Create config system properties
        Apttus_Config2__ConfigSystemProperties__c cofingSettingVar = APT_TestUtil2.createAptConfigSystem();
        insert cofingSettingVar;

        // Create custom class configuration
        Apttus_Config2__ConfigCustomClasses__c configCC = APT_TestUtil2.createAptConfigClass();
        insert configCC;

        /*
        APT_R2TValidationFields__c valFieldVar2 = new APT_TestUtil2.createAptValidationFields();
        valFieldVar2.APT_Unique_Fields__c = APT_Constants.APT_Unique_fields;
        valFieldVar2.Name = 'eParcelStandard';
        valFieldVar2.APT_Product_Code__c = 'eParcelStandard';
        insert valFieldVar2;
        */

        // Create config line item custom fields
        List<Apttus_Config2__ConfigLineItemCustomFields__c>cliCustomFieldList = new List<Apttus_Config2__ConfigLineItemCustomFields__c>();
        Apttus_Config2__ConfigLineItemCustomFields__c cliCustomFieldVar = APT_TestUtil2.createCLICustomFields();
        cliCustomFieldList.add(cliCustomFieldVar);
        Apttus_Config2__ConfigLineItemCustomFields__c cliCustomFieldVar2 = new Apttus_Config2__ConfigLineItemCustomFields__c();
        cliCustomFieldVar2.Name = '2';
        cliCustomFieldVar2.Apttus_Config2__CustomFieldNames__c = 'Apttus_Config2__AttributeValueId__r.APT_RK_Code_Applied__c';
        cliCustomFieldList.add(cliCustomFieldVar2);
        insert cliCustomFieldList;

        //Create test classification
        Apttus_Config2__ClassificationName__c classVar = APT_TestUtil2.createAptCName();
        insert classVar;

        //Create pricelist
        Apttus_Config2__PriceList__c priceList = APT_TestUtil2.createPriceList();
        insert priceList;

        //Create R2T System properties custom setting
        //Assign the cart validation product of international bunlde
        APT_R2T_System_Properties__c r2tObj = APT_TestUtil2.createR2TSystemProperties(priceList,classVar);
        r2tObj.APT_Cart_Validation_products__c = ';' + APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE + ';';
        insert r2tObj;

        //Create test Products
        List<Product2> prodList = new List<Product2>();
        //Digital and non digital international bundle
        Product2 IntBundleVar = APT_TestUtil2.createInternationalProduct(APT_Constants.PRODUCT_NAME_INTERNATIONAL_BUNDLE,
                APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE,
                'Parcels & eCommerce Services',
                'Postal Services');
        prodList.add(IntBundleVar);

        //International PCMS Bundle
        Product2 IntBundleVar2 = APT_TestUtil2.createInternationalProduct(APT_Constants.PRODUCT_NAME_INTERNATIONAL_BUNDLE,
                APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE,
                'Parcels & eCommerce Services',
                'Postal Services');
        prodList.add(IntBundleVar2);

        //International digital pcms bundle
        Product2 IntBundleVar3 = APT_TestUtil2.createInternationalProduct(APT_Constants.PRODUCT_NAME_INTERNATIONAL_BUNDLE,
                APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE_WITH_AIRMAIL,
                'Parcels & eCommerce Services',
                'Postal Services');
        prodList.add(IntBundleVar3);

        //International airmail letters
        Product2 IntBundleVar4 = APT_TestUtil2.createInternationalProduct(APT_Constants.PRODUCT_NAME_INTERNATIONAL_BUNDLE,
                APT_Constants.PRODUCT_CODE_INTERNATIONAL_AIRMAIL_LETTERS,
                'Parcels & eCommerce Services',
                'Postal Services');
        prodList.add(IntBundleVar4);

        //Eparcel Express
        Product2 DomesticProdVar = APT_TestUtil2.createDomesticProduct(APT_Constants.PRODUCT_NAME_EPARCEL_EXPRESS,
                APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS,
                'Parcels & eCommerce Services',
                'Postal Services',
                'CAT1', 'Express');
        prodList.add(DomesticProdVar);
        insert prodList;

        //create Logdement Zone
        APT_Lodgement_Zone__c logdZone = APT_TestUtil2.createLodgementZone('Aust Antarctic Territory','AAT');
        insert logdZone;

        //Create price book entry
        List<PricebookEntry>pbeList = new List<PricebookEntry>();
        PricebookEntry priceBookEntry1 =  APT_TestUtil2.getPricebookEntry(priceBookId,IntBundleVar);
        pbeList.add(priceBookEntry1);
        PricebookEntry priceBookEntry2 =  APT_TestUtil2.getPricebookEntry(priceBookId,DomesticProdVar);
        pbeList.add(priceBookEntry2);
        insert pbeList;

        //Create Price list Item
        List<Apttus_Config2__PriceListItem__c> pliList = new List<Apttus_Config2__PriceListItem__c>();
        Apttus_Config2__PriceListItem__c pli1 = APT_TestUtil2.createPriceListItem(priceList.ID,IntBundleVar.ID,'C Manufacturing','BAND 2');
        pliList.add(pli1);
        Apttus_Config2__PriceListItem__c pli2 = APT_TestUtil2.createPriceListItem(priceList.ID,DomesticProdVar.ID,'C Manufacturing','BAND 2');
        pliList.add(pli2);
        Apttus_Config2__PriceListItem__c pli3 = APT_TestUtil2.createPriceListItem(priceList.ID,IntBundleVar2.ID,'C Manufacturing','BAND 2');
        pliList.add(pli3);
        Apttus_Config2__PriceListItem__c pli4 = APT_TestUtil2.createPriceListItem(priceList.ID,IntBundleVar3.ID,'C Manufacturing','BAND 2');
        pliList.add(pli4);
        Apttus_Config2__PriceListItem__c pli5 = APT_TestUtil2.createPriceListItem(priceList.ID,IntBundleVar4.ID,'C Manufacturing','BAND 2');
        pliList.add(pli5);
        Apttus_Config2__PriceListItem__c pli6 = APT_TestUtil2.createPriceListItem(priceList.ID,IntBundleVar4.ID,'C Manufacturing','BAND 2');
        pliList.add(pli6);
        insert pliList;

        //Create price matrix
        List<Apttus_Config2__PriceMatrix__c> pmList = new List<Apttus_Config2__PriceMatrix__c>();
        Apttus_Config2__PriceMatrix__c pmVar = new Apttus_Config2__PriceMatrix__c();
        pmVar.Apttus_Config2__PriceListItemId__c = pli1.id;
        pmVar.Apttus_Config2__Sequence__c = 1;
        pmList.add(pmVar);

        Apttus_Config2__PriceMatrix__c pmVar2 = new Apttus_Config2__PriceMatrix__c();
        pmVar2.Apttus_Config2__PriceListItemId__c = pli2.id;
        pmVar2.Apttus_Config2__Sequence__c = 1;
        pmList.add(pmVar2);

        insert pmList;

        // Create test organisation
        Account accVar = APT_TestUtil2.createOrganisation();
        insert accVar;

        // Create test contact
        Contact conVar = APT_TestUtil2.createContact();
        insert conVar;

        // Create test opportunity of new customer
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity oppVar = APT_TestUtil2.createOpportunity(accVar); // Represents the new opportunity for the amendment proposal
        oppVar.Amount = 3000;
        oppList.add(oppVar);
        Opportunity oppVarOrig = APT_TestUtil2.createOpportunity(accVar); // Represent the original opportunity for the amendment proposal
        oppVarOrig.Amount = 2500;
        oppList.add(oppVarOrig);
        insert oppList;

        // Create test original agreement for amendment
        Apttus__APTS_Agreement__c  agreementVar  = APT_TestUtil2.createAgreement(accVar,
                conVar,
                oppVarOrig,
                new Apttus_Proposal__Proposal__c(),
                APT_AmendRenewController.SUPERSEDED_STATUS,
                APT_AmendRenewController.AMENDED_STATUS_CATEGORY,
                'MSA & Service Schedule');
        insert agreementVar;

        // Create test amendment proposal
        Apttus_Proposal__Proposal__c proposalVar = APT_TestUtil2.createQuoteProposal(accVar,
                oppVar,
                agreementVar,
                APT_Constants.RECORD_TYPE_AMENDMENT_QUOTE,
                priceList);
        // Add increase revenue as revenue type
        proposalVar.APT_Revenue_Type__c = APT_AmendRenewController.INCREASE_REVENUE;
        insert proposalVar;
        
        test.startTest(); //10/23/2019 added as a fix for the SOQL error
        //Create Product Configuration
        List<Apttus_Config2__ProductConfiguration__c>configList = new List<Apttus_Config2__ProductConfiguration__c>();
        Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtil2.getProductConfiguration('Product Configuration', 1,
                proposalVar.Id, 'Proposal','Ad Hoc',
                priceList.Id, null,'New',null,
                Datetime.now(), true);
        configList.add(prodconfig);
        insert configList;

        // Create LineItem
        List<Apttus_Config2__LineItem__c> lstLineItem = new List<Apttus_Config2__LineItem__c>();

        // Digitial International Bundle Configuration line item
        Apttus_Config2__LineItem__c IntBundleVarCLI = APT_TestUtil2.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
                1, 'Product/Service', IntBundleVar.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
                null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable
                'Each', 1, priceList.Id, pli1.Id,//Uom, term, priceList, Pli,
                'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
                true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod,
                5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
        IntBundleVarCLI.Apttus_Config2__AllowManualAdjustment__c = true;
        IntBundleVarCLI.Apttus_Config2__NetPrice__c = 5225;
        IntBundleVarCLI.Apttus_Config2__PrimaryLineNumber__c = 1;
        IntBundleVarCLI.Apttus_Config2__NetAdjustmentPercent__c = -10;
        IntBundleVarCLI.APT_Is_OPC_deleted__c = false;
        lstLineItem.add(IntBundleVarCLI);

        // Eparcel Express Configuration Line Item
        Apttus_Config2__LineItem__c DomesticVarCLI = APT_TestUtil2.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
                1, 'Product/Service', DomesticProdVar.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
                null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable
                'Each', 1, priceList.Id, pli2.Id,//Uom, term, priceList, Pli,
                'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
                true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod,
                5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
        DomesticVarCLI.Apttus_Config2__AllowManualAdjustment__c = true;
        DomesticVarCLI.Apttus_Config2__NetPrice__c = 5225;
        DomesticVarCLI.Apttus_Config2__PrimaryLineNumber__c = 2;
        DomesticVarCLI.Apttus_Config2__NetAdjustmentPercent__c = -10;
        DomesticVarCLI.APT_Is_OPC_deleted__c = false;
        lstLineItem.add(DomesticVarCLI);

        // Non Digital Internation Bundle
        Apttus_Config2__LineItem__c NDIntBundleVarCLI = APT_TestUtil2.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
                1, 'Product/Service', IntBundleVar.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
                null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable
                'Each', 1, priceList.Id, pli3.Id,//Uom, term, priceList, Pli,
                'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
                true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod,
                5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
        NDIntBundleVarCLI.Apttus_Config2__AllowManualAdjustment__c = true;
        NDIntBundleVarCLI.Apttus_Config2__NetPrice__c = 5225;
        NDIntBundleVarCLI.Apttus_Config2__PrimaryLineNumber__c = 1;
        NDIntBundleVarCLI.Apttus_Config2__NetAdjustmentPercent__c = -10;
        NDIntBundleVarCLI.APT_Is_OPC_deleted__c = false;
        lstLineItem.add(NDIntBundleVarCLI);

        //International PCMS
        Apttus_Config2__LineItem__c InternationalPCMS_CLI = APT_TestUtil2.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
                1, 'Product/Service', IntBundleVar2.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
                null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable
                'Each', 1, priceList.Id, pli4.Id,//Uom, term, priceList, Pli,
                'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
                true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod,
                5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
        InternationalPCMS_CLI.Apttus_Config2__AllowManualAdjustment__c = true;
        InternationalPCMS_CLI.Apttus_Config2__NetPrice__c = 5225;
        InternationalPCMS_CLI.Apttus_Config2__PrimaryLineNumber__c = 1;
        InternationalPCMS_CLI.Apttus_Config2__NetAdjustmentPercent__c = -10;
        InternationalPCMS_CLI.APT_Is_OPC_deleted__c = false;
        lstLineItem.add(InternationalPCMS_CLI);

        //International Digital PCMS
        Apttus_Config2__LineItem__c IntDigitalPCMS_CLI = APT_TestUtil2.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
                1, 'Product/Service', IntBundleVar3.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
                null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable
                'Each', 1, priceList.Id, pli5.Id,//Uom, term, priceList, Pli,
                'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
                true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod,
                5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
        IntDigitalPCMS_CLI.Apttus_Config2__AllowManualAdjustment__c = true;
        IntDigitalPCMS_CLI.Apttus_Config2__NetPrice__c = 5225;
        IntDigitalPCMS_CLI.Apttus_Config2__PrimaryLineNumber__c = 1;
        IntDigitalPCMS_CLI.Apttus_Config2__NetAdjustmentPercent__c = -10;
        IntDigitalPCMS_CLI.APT_Is_OPC_deleted__c = false;
        lstLineItem.add(IntDigitalPCMS_CLI);

        // International Airmail
        Apttus_Config2__LineItem__c IntAIrmail_CLI = APT_TestUtil2.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
                1, 'Product/Service', IntBundleVar4.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
                null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable
                'Each', 1, priceList.Id, pli6.Id,//Uom, term, priceList, Pli,
                'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
                true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod,
                5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
        IntAIrmail_CLI.Apttus_Config2__AllowManualAdjustment__c = true;
        IntAIrmail_CLI.Apttus_Config2__NetPrice__c = 5225;
        IntAIrmail_CLI.Apttus_Config2__PrimaryLineNumber__c = 1;
        IntAIrmail_CLI.Apttus_Config2__NetAdjustmentPercent__c = -10;
        IntAIrmail_CLI.APT_Is_OPC_deleted__c = false;
        lstLineItem.add(IntAIrmail_CLI);
        insert lstLineItem;

        //create Product Attribute
        List<Apttus_Config2__ProductAttributeValue__c> prodAttList = new List<Apttus_Config2__ProductAttributeValue__c>();
        Apttus_Config2__ProductAttributeValue__c attribute1 = APT_TestUtil2.createAttributeValue(IntBundleVarCLI.Id,'Standard',false,false,false,'Yes','B Mining',True,True);
        //attribute1.Category__c = 'CAT1';
        attribute1.APT_Lodgement_Zone__c = logdZone.ID;
        attribute1.APT_PostBillPay_Gross_Settlement_fee__c = 'No';
        attribute1.APT_eParcel_Lodgment__c = true; // Required true if digital
        attribute1.APT_International_Letters__c = false; // Required false if digital
        attribute1.APT_Minimum_Quantity__c = 10;
        attribute1.APTS_Price_Structure__c = 'BANDED {Z30}';
        prodAttList.add(attribute1);

        Apttus_Config2__ProductAttributeValue__c attribute2 = APT_TestUtil2.createAttributeValue(DomesticVarCLI.Id,'Standard',false,false,false,'Yes','B Mining',True,True);
        attribute2.Category__c = 'CAT1';
        attribute2.APT_Lodgement_Zone__c = logdZone.ID;
        attribute2.APT_PostBillPay_Gross_Settlement_fee__c = 'No';
        attribute2.APT_eParcel_Lodgment__c = true;
        attribute2.APT_International_Letters__c = false;
        attribute2.APT_Minimum_Quantity__c = 20;
        attribute2.APTS_Price_Structure__c = 'BASE+PER_KG {Z30}';
        prodAttList.add(attribute2);

        Apttus_Config2__ProductAttributeValue__c attribute3 = APT_TestUtil2.createAttributeValue(NDIntBundleVarCLI.Id,'Standard',false,false,false,'Yes','B Mining',True,True);
        attribute3.Category__c = 'CAT1';
        attribute3.APT_Lodgement_Zone__c = logdZone.ID;
        attribute3.APT_PostBillPay_Gross_Settlement_fee__c = 'No';
        attribute3.APT_eParcel_Lodgment__c = false; // Required false if non digital
        attribute3.APT_International_Letters__c = true; // Required true if non digitial
        attribute3.APT_Minimum_Quantity__c = 20;
        attribute3.APTS_Price_Structure__c = 'BASE+PER_KG {Z30}';
        prodAttList.add(attribute3);
        insert prodAttList;

        // Assign back the attribute to the bundle
        List<Apttus_Config2__LineItem__c> appConfigLineItemList = new List<Apttus_Config2__LineItem__c>();
        IntBundleVarCLI.Apttus_Config2__AttributeValueId__c = attribute1.Id;
        DomesticVarCLI.Apttus_Config2__AttributeValueId__c = attribute2.Id;

        appConfigLineItemList.add(IntBundleVarCLI);
        appConfigLineItemList.add(DomesticVarCLI);
        update appConfigLineItemList;

        // Create Charge code
        List<APT_Charge_Code__c>aptCCList = new List<APT_Charge_Code__c>();
        APT_Charge_Code__c objChargeCode = APT_TestUtils.createChargeCode(attribute1.APTS_Price_Structure__c);
        aptCCList.add(objChargeCode);
        APT_Charge_Code__c objChargeCode2 = APT_TestUtils.createChargeCode(attribute2.APTS_Price_Structure__c);
        aptCCList.add(objChargeCode2);
        insert aptCCList;

        //Create usage price tier
        List<Apttus_Config2__UsagePriceTier__c> uptList = new List<Apttus_Config2__UsagePriceTier__c>();
        Apttus_Config2__UsagePriceTier__c uptVar = new Apttus_Config2__UsagePriceTier__c();
        uptVar.Apttus_Config2__LineItemId__c = IntBundleVarCLI.Id;
        uptVar.Apttus_Config2__PriceMatrixId__c = pmVar.Id;
        uptVar.Apttus_Config2__Sequence__c = 1;
        uptVar.Apttus_Config2__Dimension1Value__c = 'Zone1';
        uptVar.Apttus_Config2__Dimension2Value__c = 'Per Item';
        uptVar.Apttus_Config2__AdjustmentAmount__c = 10;
        uptVar.Apttus_Config2__UsageRate__c = 10;
        uptVar.Apttus_Config2__PriceOverride__c = 10;
        uptList.add(uptVar);

        Apttus_Config2__UsagePriceTier__c uptVar2 = new Apttus_Config2__UsagePriceTier__c();
        uptVar2.Apttus_Config2__LineItemId__c = DomesticVarCLI.Id;
        uptVar2.Apttus_Config2__PriceMatrixId__c = pmVar2.Id;
        uptVar2.Apttus_Config2__Sequence__c = 1;
        uptVar2.Apttus_Config2__Dimension1Value__c = 'Zone1';
        uptVar2.Apttus_Config2__Dimension2Value__c = 'Per Item';
        uptVar2.Apttus_Config2__AdjustmentAmount__c = 10;
        uptVar2.Apttus_Config2__UsageRate__c = 10;
        uptVar2.Apttus_Config2__PriceOverride__c = 10;
        uptList.add(uptVar2);

        Apttus_Config2__UsagePriceTier__c uptVar3 = new Apttus_Config2__UsagePriceTier__c();
        uptVar3.Apttus_Config2__LineItemId__c = DomesticVarCLI.Id;
        uptVar3.Apttus_Config2__PriceMatrixId__c = pmVar2.Id;
        uptVar3.Apttus_Config2__Sequence__c = 1;
        uptVar3.Apttus_Config2__Dimension1Value__c = 'Zone1';
        uptVar3.Apttus_Config2__Dimension2Value__c = 'Per Item';
        uptVar3.Apttus_Config2__AdjustmentAmount__c = 10;
        uptVar3.Apttus_Config2__UsageRate__c = 10;
        uptVar3.Apttus_Config2__PriceOverride__c = 10;
        uptList.add(uptVar3);

        insert uptList;

        List<OpportunityLineItem> listOli = new List<OpportunityLineItem>();
        OpportunityLineItem oli = APT_TestUtil2.createOpportunityLI(oppVar, priceBookEntry1.Id, 'New Business');
        oli.TotalPrice = 2000;
        oli.Quantity = 10;
        listOli.add(oli);

        OpportunityLineItem oli2 = APT_TestUtil2.createOpportunityLI(oppVar, priceBookEntry2.Id, 'New Business');
        oli2.TotalPrice = 1000;
        oli2.Quantity = 10;
        listOli.add(oli2);
        insert listOli;

        List<APT_Opportunity_Product_Line_Item__c> APTOplList = new List<APT_Opportunity_Product_Line_Item__c>();
        APT_Opportunity_Product_Line_Item__c APTopliVar = APT_TestUtil2.createAPTOpportunityLI(proposalVar,IntBundleVar);
        APTopliVar.APT_TotalPrice__c = 2000;
        APTopliVar.APT_Quantity__c = 10;
        APTopliVar.APT_Revenue_Start_Date__c = System.Today();
        APTopliVar.APT_Revenue_End_Date__c= System.Today() + 10;
        APTopliVar.APT_Classification__c = 'New Business';
        APTopliVar.APT_Unit_Sales_Price__c = 200;
        APTOplList.add(APTopliVar);

        APT_Opportunity_Product_Line_Item__c APTopliVar2 = APT_TestUtil2.createAPTOpportunityLI(proposalVar,DomesticProdVar);
        APTopliVar2.APT_TotalPrice__c = 1000;
        APTopliVar2.APT_Quantity__c = 10;
        APTopliVar2.APT_Revenue_Start_Date__c = System.Today();
        APTopliVar2.APT_Revenue_End_Date__c= System.Today() + 10;
        APTopliVar2.APT_Classification__c = 'New Business';
        APTopliVar2.APT_Unit_Sales_Price__c = 100;
        APTOplList.add(APTopliVar2);

        insert APTOplList;

        // Create Opportunity Product Line Item
        /*
        List<APT_Opportunity_Product_Line_Item__c> lstOLI = new List<APT_Opportunity_Product_Line_Item__c>();
        APT_Opportunity_Product_Line_Item__c OppProLineItem = APT_TestUtils.createOpProdLI('Renewal','Yes',bundle1.id,prodconfig.id,1,Proposal.id, 1, Date.Today(),Date.Today() + 100);
        OppProLineItem.APT_Sub_Classification__c = 'Contracted Price Increases';
        OppProLineItem.APT_TotalPrice__c = 10;
        lstOLI.add(OppProLineItem);

        insert lstOLI;
        */
        /*
        APT_Promo_Post_allowed_Lodgements__c custLodgement = new APT_Promo_Post_allowed_Lodgements__c();
        custLodgement.Name = 'ADELAIDE BC BULK DOCK';
        custLodgement.APT_Post_code__c = '6000';
        insert custLodgement;
        */


        proposalVar.Apttus_QPConfig__ConfigurationFinalizedDate__c = System.today();
        proposalVar.Apttus_Proposal__Primary__c = true;
        proposalVar.Apttus_Proposal__Approval_Stage__c = APT_Constants.APPROVAL_STAGE_ACCEPTED;
        //proposalVar.APT_Contract_Id__c =  origContract.Id;
        update proposalVar;
        //APT_ProposalTriggerHandler.afterUpdateEvent(newlist,map1);

        //APT_ProposalTriggerHandler.sycWithOpportunity(setids);
        //APT_ProposalTriggerHandler.createQuoteLP(setproposals);
        //system.assert(pgRef == null);


        test.stopTest();
        oppVar = [select APT_Revenue_Decrease__c from opportunity where id= :oppVar.Id];
        //System.assert(oppVar.APT_Revenue_Decrease__c == 94);
    }

    /**
     * Test amend proposal decrease in revenue
     * Added by Adrian Recio
    */
    private static testMethod void testDecreaseRevenue() {
        // Get standard price book Id
        Id priceBookId = Test.getStandardPricebookId();

        //Create test admin config
        Apttus__APTS_Admin__c adminObj = APT_TestUtil2.createAptAdmin();
        insert adminObj;

        //Create validation field custom setting
        APT_R2TValidationFields__c valFieldVar = APT_TestUtil2.createAptValidationFields();
        insert valFieldVar;

        //Create config system properties
        Apttus_Config2__ConfigSystemProperties__c cofingSettingVar = APT_TestUtil2.createAptConfigSystem();
        insert cofingSettingVar;

        // Create custom class configuration
        Apttus_Config2__ConfigCustomClasses__c configCC = APT_TestUtil2.createAptConfigClass();
        insert configCC;

        /*
        APT_R2TValidationFields__c valFieldVar2 = new APT_TestUtil2.createAptValidationFields();
        valFieldVar2.APT_Unique_Fields__c = APT_Constants.APT_Unique_fields;
        valFieldVar2.Name = 'eParcelStandard';
        valFieldVar2.APT_Product_Code__c = 'eParcelStandard';
        insert valFieldVar2;
        */

        // Create config line item custom fields
        List<Apttus_Config2__ConfigLineItemCustomFields__c>cliCustomFieldList = new List<Apttus_Config2__ConfigLineItemCustomFields__c>();
        Apttus_Config2__ConfigLineItemCustomFields__c cliCustomFieldVar = APT_TestUtil2.createCLICustomFields();
        cliCustomFieldList.add(cliCustomFieldVar);
        Apttus_Config2__ConfigLineItemCustomFields__c cliCustomFieldVar2 = new Apttus_Config2__ConfigLineItemCustomFields__c();
        cliCustomFieldVar2.Name = '2';
        cliCustomFieldVar2.Apttus_Config2__CustomFieldNames__c = 'Apttus_Config2__AttributeValueId__r.APT_RK_Code_Applied__c';
        cliCustomFieldList.add(cliCustomFieldVar2);
        insert cliCustomFieldList;

        //Create test classification
        Apttus_Config2__ClassificationName__c classVar = APT_TestUtil2.createAptCName();
        insert classVar;

        //Create pricelist
        Apttus_Config2__PriceList__c priceList = APT_TestUtil2.createPriceList();
        insert priceList;

        //Create R2T System properties custom setting
        //Assign the cart validation product of international bunlde
        APT_R2T_System_Properties__c r2tObj = APT_TestUtil2.createR2TSystemProperties(priceList,classVar);
        r2tObj.APT_Cart_Validation_products__c = ';' + APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE + ';';
        insert r2tObj;

        //Create test Products
        List<Product2> prodList = new List<Product2>();
        //Digital and non digital international bundle
        Product2 IntBundleVar = APT_TestUtil2.createInternationalProduct(APT_Constants.PRODUCT_NAME_INTERNATIONAL_BUNDLE,
                APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE,
                'Parcels & eCommerce Services',
                'Postal Services');
        prodList.add(IntBundleVar);

        //International PCMS Bundle
        Product2 IntBundleVar2 = APT_TestUtil2.createInternationalProduct(APT_Constants.PRODUCT_NAME_INTERNATIONAL_BUNDLE,
                APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE,
                'Parcels & eCommerce Services',
                'Postal Services');
        prodList.add(IntBundleVar2);

        //International digital pcms bundle
        Product2 IntBundleVar3 = APT_TestUtil2.createInternationalProduct(APT_Constants.PRODUCT_NAME_INTERNATIONAL_BUNDLE,
                APT_Constants.PRODUCT_CODE_INTERNATIONAL_DIGITAL_PCMS_BUNDLE_WITH_AIRMAIL,
                'Parcels & eCommerce Services',
                'Postal Services');
        prodList.add(IntBundleVar3);

        //International airmail letters
        Product2 IntBundleVar4 = APT_TestUtil2.createInternationalProduct(APT_Constants.PRODUCT_NAME_INTERNATIONAL_BUNDLE,
                APT_Constants.PRODUCT_CODE_INTERNATIONAL_AIRMAIL_LETTERS,
                'Parcels & eCommerce Services',
                'Postal Services');
        prodList.add(IntBundleVar4);

        //Eparcel Express
        Product2 DomesticProdVar = APT_TestUtil2.createDomesticProduct(APT_Constants.PRODUCT_NAME_EPARCEL_EXPRESS,
                APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS,
                'Parcels & eCommerce Services',
                'Postal Services',
                'CAT1', 'Express');
        prodList.add(DomesticProdVar);
        insert prodList;

        //create Logdement Zone
        APT_Lodgement_Zone__c logdZone = APT_TestUtil2.createLodgementZone('Aust Antarctic Territory','AAT');
        insert logdZone;

        //Create price book entry
        List<PricebookEntry>pbeList = new List<PricebookEntry>();
        PricebookEntry priceBookEntry1 =  APT_TestUtil2.getPricebookEntry(priceBookId,IntBundleVar);
        pbeList.add(priceBookEntry1);
        PricebookEntry priceBookEntry2 =  APT_TestUtil2.getPricebookEntry(priceBookId,DomesticProdVar);
        pbeList.add(priceBookEntry2);
        insert pbeList;

        //Create Price list Item
        List<Apttus_Config2__PriceListItem__c> pliList = new List<Apttus_Config2__PriceListItem__c>();
        Apttus_Config2__PriceListItem__c pli1 = APT_TestUtil2.createPriceListItem(priceList.ID,IntBundleVar.ID,'C Manufacturing','BAND 2');
        pliList.add(pli1);
        Apttus_Config2__PriceListItem__c pli2 = APT_TestUtil2.createPriceListItem(priceList.ID,DomesticProdVar.ID,'C Manufacturing','BAND 2');
        pliList.add(pli2);
        Apttus_Config2__PriceListItem__c pli3 = APT_TestUtil2.createPriceListItem(priceList.ID,IntBundleVar2.ID,'C Manufacturing','BAND 2');
        pliList.add(pli3);
        Apttus_Config2__PriceListItem__c pli4 = APT_TestUtil2.createPriceListItem(priceList.ID,IntBundleVar3.ID,'C Manufacturing','BAND 2');
        pliList.add(pli4);
        Apttus_Config2__PriceListItem__c pli5 = APT_TestUtil2.createPriceListItem(priceList.ID,IntBundleVar4.ID,'C Manufacturing','BAND 2');
        pliList.add(pli5);
        Apttus_Config2__PriceListItem__c pli6 = APT_TestUtil2.createPriceListItem(priceList.ID,IntBundleVar4.ID,'C Manufacturing','BAND 2');
        pliList.add(pli6);
        insert pliList;

        //Create price matrix
        List<Apttus_Config2__PriceMatrix__c> pmList = new List<Apttus_Config2__PriceMatrix__c>();
        Apttus_Config2__PriceMatrix__c pmVar = new Apttus_Config2__PriceMatrix__c();
        pmVar.Apttus_Config2__PriceListItemId__c = pli1.id;
        pmVar.Apttus_Config2__Sequence__c = 1;
        pmList.add(pmVar);

        Apttus_Config2__PriceMatrix__c pmVar2 = new Apttus_Config2__PriceMatrix__c();
        pmVar2.Apttus_Config2__PriceListItemId__c = pli2.id;
        pmVar2.Apttus_Config2__Sequence__c = 1;
        pmList.add(pmVar2);

        insert pmList;

        // Create test organisation
        Account accVar = APT_TestUtil2.createOrganisation();
        insert accVar;

        // Create test contact
        Contact conVar = APT_TestUtil2.createContact();
        insert conVar;

        // Create test opportunity of new customer
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity oppVar = APT_TestUtil2.createOpportunity(accVar); // Represents the new opportunity for the amendment proposal
        oppVar.Amount = 3000;
        oppList.add(oppVar);
        Opportunity oppVarOrig = APT_TestUtil2.createOpportunity(accVar); // Represent the original opportunity for the amendment proposal
        oppVarOrig.Amount = 4000;
        oppList.add(oppVarOrig);
        insert oppList;

        // Create test original agreement for amendment
        Apttus__APTS_Agreement__c  agreementVar  = APT_TestUtil2.createAgreement(accVar,
                conVar,
                oppVarOrig,
                new Apttus_Proposal__Proposal__c(),
                APT_AmendRenewController.SUPERSEDED_STATUS,
                APT_AmendRenewController.AMENDED_STATUS_CATEGORY,
                'MSA & Service Schedule');
        insert agreementVar;

        // Create test amendment proposal
        Apttus_Proposal__Proposal__c proposalVar = APT_TestUtil2.createQuoteProposal(accVar,
                oppVar,
                agreementVar,
                APT_Constants.RECORD_TYPE_AMENDMENT_QUOTE,
                priceList);
        // Add increase revenue as revenue type
        proposalVar.APT_Revenue_Type__c = APT_AmendRenewController.DECREASE_REVENUE;
        insert proposalVar;
        test.startTest(); //10/23/2019 added as a fix for the SOQL error
        //Create Product Configuration
        List<Apttus_Config2__ProductConfiguration__c>configList = new List<Apttus_Config2__ProductConfiguration__c>();
        Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtil2.getProductConfiguration('Product Configuration', 1,
                proposalVar.Id, 'Proposal','Ad Hoc',
                priceList.Id, null,'New',null,
                Datetime.now(), true);
        configList.add(prodconfig);
        insert configList;

        // Create LineItem
        List<Apttus_Config2__LineItem__c> lstLineItem = new List<Apttus_Config2__LineItem__c>();

        // Digitial International Bundle Configuration line item
        Apttus_Config2__LineItem__c IntBundleVarCLI = APT_TestUtil2.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
                1, 'Product/Service', IntBundleVar.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
                null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable
                'Each', 1, priceList.Id, pli1.Id,//Uom, term, priceList, Pli,
                'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
                true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod,
                5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
        IntBundleVarCLI.Apttus_Config2__AllowManualAdjustment__c = true;
        IntBundleVarCLI.Apttus_Config2__NetPrice__c = 5225;
        IntBundleVarCLI.Apttus_Config2__PrimaryLineNumber__c = 1;
        IntBundleVarCLI.Apttus_Config2__NetAdjustmentPercent__c = -10;
        IntBundleVarCLI.APT_Is_OPC_deleted__c = false;
        lstLineItem.add(IntBundleVarCLI);

        // Eparcel Express Configuration Line Item
        Apttus_Config2__LineItem__c DomesticVarCLI = APT_TestUtil2.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
                1, 'Product/Service', DomesticProdVar.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
                null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable
                'Each', 1, priceList.Id, pli2.Id,//Uom, term, priceList, Pli,
                'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
                true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod,
                5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
        DomesticVarCLI.Apttus_Config2__AllowManualAdjustment__c = true;
        DomesticVarCLI.Apttus_Config2__NetPrice__c = 5225;
        DomesticVarCLI.Apttus_Config2__PrimaryLineNumber__c = 2;
        DomesticVarCLI.Apttus_Config2__NetAdjustmentPercent__c = -10;
        DomesticVarCLI.APT_Is_OPC_deleted__c = false;
        lstLineItem.add(DomesticVarCLI);

        // Non Digital Internation Bundle
        Apttus_Config2__LineItem__c NDIntBundleVarCLI = APT_TestUtil2.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
                1, 'Product/Service', IntBundleVar.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
                null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable
                'Each', 1, priceList.Id, pli3.Id,//Uom, term, priceList, Pli,
                'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
                true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod,
                5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
        NDIntBundleVarCLI.Apttus_Config2__AllowManualAdjustment__c = true;
        NDIntBundleVarCLI.Apttus_Config2__NetPrice__c = 5225;
        NDIntBundleVarCLI.Apttus_Config2__PrimaryLineNumber__c = 1;
        NDIntBundleVarCLI.Apttus_Config2__NetAdjustmentPercent__c = -10;
        NDIntBundleVarCLI.APT_Is_OPC_deleted__c = false;
        lstLineItem.add(NDIntBundleVarCLI);

        //International PCMS
        Apttus_Config2__LineItem__c InternationalPCMS_CLI = APT_TestUtil2.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
                1, 'Product/Service', IntBundleVar2.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
                null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable
                'Each', 1, priceList.Id, pli4.Id,//Uom, term, priceList, Pli,
                'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
                true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod,
                5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
        InternationalPCMS_CLI.Apttus_Config2__AllowManualAdjustment__c = true;
        InternationalPCMS_CLI.Apttus_Config2__NetPrice__c = 5225;
        InternationalPCMS_CLI.Apttus_Config2__PrimaryLineNumber__c = 1;
        InternationalPCMS_CLI.Apttus_Config2__NetAdjustmentPercent__c = -10;
        InternationalPCMS_CLI.APT_Is_OPC_deleted__c = false;
        lstLineItem.add(InternationalPCMS_CLI);

        //International Digital PCMS
        Apttus_Config2__LineItem__c IntDigitalPCMS_CLI = APT_TestUtil2.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
                1, 'Product/Service', IntBundleVar3.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
                null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable
                'Each', 1, priceList.Id, pli5.Id,//Uom, term, priceList, Pli,
                'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
                true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod,
                5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
        IntDigitalPCMS_CLI.Apttus_Config2__AllowManualAdjustment__c = true;
        IntDigitalPCMS_CLI.Apttus_Config2__NetPrice__c = 5225;
        IntDigitalPCMS_CLI.Apttus_Config2__PrimaryLineNumber__c = 1;
        IntDigitalPCMS_CLI.Apttus_Config2__NetAdjustmentPercent__c = -10;
        IntDigitalPCMS_CLI.APT_Is_OPC_deleted__c = false;
        lstLineItem.add(IntDigitalPCMS_CLI);

        // International Airmail
        Apttus_Config2__LineItem__c IntAIrmail_CLI = APT_TestUtil2.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
                1, 'Product/Service', IntBundleVar4.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
                null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable
                'Each', 1, priceList.Id, pli6.Id,//Uom, term, priceList, Pli,
                'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
                true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod,
                5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
        IntAIrmail_CLI.Apttus_Config2__AllowManualAdjustment__c = true;
        IntAIrmail_CLI.Apttus_Config2__NetPrice__c = 5225;
        IntAIrmail_CLI.Apttus_Config2__PrimaryLineNumber__c = 1;
        IntAIrmail_CLI.Apttus_Config2__NetAdjustmentPercent__c = -10;
        IntAIrmail_CLI.APT_Is_OPC_deleted__c = false;
        lstLineItem.add(IntAIrmail_CLI);
        insert lstLineItem;

        //create Product Attribute
        List<Apttus_Config2__ProductAttributeValue__c> prodAttList = new List<Apttus_Config2__ProductAttributeValue__c>();
        Apttus_Config2__ProductAttributeValue__c attribute1 = APT_TestUtil2.createAttributeValue(IntBundleVarCLI.Id,'Standard',false,false,false,'Yes','B Mining',True,True);
        //attribute1.Category__c = 'CAT1';
        attribute1.APT_Lodgement_Zone__c = logdZone.ID;
        attribute1.APT_PostBillPay_Gross_Settlement_fee__c = 'No';
        attribute1.APT_eParcel_Lodgment__c = true; // Required true if digital
        attribute1.APT_International_Letters__c = false; // Required false if digital
        attribute1.APT_Minimum_Quantity__c = 10;
        attribute1.APTS_Price_Structure__c = 'BANDED {Z30}';
        prodAttList.add(attribute1);

        Apttus_Config2__ProductAttributeValue__c attribute2 = APT_TestUtil2.createAttributeValue(DomesticVarCLI.Id,'Standard',false,false,false,'Yes','B Mining',True,True);
        attribute2.Category__c = 'CAT1';
        attribute2.APT_Lodgement_Zone__c = logdZone.ID;
        attribute2.APT_PostBillPay_Gross_Settlement_fee__c = 'No';
        attribute2.APT_eParcel_Lodgment__c = true;
        attribute2.APT_International_Letters__c = false;
        attribute2.APT_Minimum_Quantity__c = 20;
        attribute2.APTS_Price_Structure__c = 'BASE+PER_KG {Z30}';
        prodAttList.add(attribute2);

        Apttus_Config2__ProductAttributeValue__c attribute3 = APT_TestUtil2.createAttributeValue(NDIntBundleVarCLI.Id,'Standard',false,false,false,'Yes','B Mining',True,True);
        attribute3.Category__c = 'CAT1';
        attribute3.APT_Lodgement_Zone__c = logdZone.ID;
        attribute3.APT_PostBillPay_Gross_Settlement_fee__c = 'No';
        attribute3.APT_eParcel_Lodgment__c = false; // Required false if non digital
        attribute3.APT_International_Letters__c = true; // Required true if non digitial
        attribute3.APT_Minimum_Quantity__c = 20;
        attribute3.APTS_Price_Structure__c = 'BASE+PER_KG {Z30}';
        prodAttList.add(attribute3);
        insert prodAttList;

        // Assign back the attribute to the bundle
        List<Apttus_Config2__LineItem__c> appConfigLineItemList = new List<Apttus_Config2__LineItem__c>();
        IntBundleVarCLI.Apttus_Config2__AttributeValueId__c = attribute1.Id;
        DomesticVarCLI.Apttus_Config2__AttributeValueId__c = attribute2.Id;

        appConfigLineItemList.add(IntBundleVarCLI);
        appConfigLineItemList.add(DomesticVarCLI);
        update appConfigLineItemList;

        // Create Charge code
        List<APT_Charge_Code__c>aptCCList = new List<APT_Charge_Code__c>();
        APT_Charge_Code__c objChargeCode = APT_TestUtils.createChargeCode(attribute1.APTS_Price_Structure__c);
        aptCCList.add(objChargeCode);
        APT_Charge_Code__c objChargeCode2 = APT_TestUtils.createChargeCode(attribute2.APTS_Price_Structure__c);
        aptCCList.add(objChargeCode2);
        insert aptCCList;

        //Create usage price tier
        List<Apttus_Config2__UsagePriceTier__c> uptList = new List<Apttus_Config2__UsagePriceTier__c>();
        Apttus_Config2__UsagePriceTier__c uptVar = new Apttus_Config2__UsagePriceTier__c();
        uptVar.Apttus_Config2__LineItemId__c = IntBundleVarCLI.Id;
        uptVar.Apttus_Config2__PriceMatrixId__c = pmVar.Id;
        uptVar.Apttus_Config2__Sequence__c = 1;
        uptVar.Apttus_Config2__Dimension1Value__c = 'Zone1';
        uptVar.Apttus_Config2__Dimension2Value__c = 'Per Item';
        uptVar.Apttus_Config2__AdjustmentAmount__c = 10;
        uptVar.Apttus_Config2__UsageRate__c = 10;
        uptVar.Apttus_Config2__PriceOverride__c = 10;
        uptList.add(uptVar);

        Apttus_Config2__UsagePriceTier__c uptVar2 = new Apttus_Config2__UsagePriceTier__c();
        uptVar2.Apttus_Config2__LineItemId__c = DomesticVarCLI.Id;
        uptVar2.Apttus_Config2__PriceMatrixId__c = pmVar2.Id;
        uptVar2.Apttus_Config2__Sequence__c = 1;
        uptVar2.Apttus_Config2__Dimension1Value__c = 'Zone1';
        uptVar2.Apttus_Config2__Dimension2Value__c = 'Per Item';
        uptVar2.Apttus_Config2__AdjustmentAmount__c = 10;
        uptVar2.Apttus_Config2__UsageRate__c = 10;
        uptVar2.Apttus_Config2__PriceOverride__c = 10;
        uptList.add(uptVar2);

        Apttus_Config2__UsagePriceTier__c uptVar3 = new Apttus_Config2__UsagePriceTier__c();
        uptVar3.Apttus_Config2__LineItemId__c = DomesticVarCLI.Id;
        uptVar3.Apttus_Config2__PriceMatrixId__c = pmVar2.Id;
        uptVar3.Apttus_Config2__Sequence__c = 1;
        uptVar3.Apttus_Config2__Dimension1Value__c = 'Zone1';
        uptVar3.Apttus_Config2__Dimension2Value__c = 'Per Item';
        uptVar3.Apttus_Config2__AdjustmentAmount__c = 10;
        uptVar3.Apttus_Config2__UsageRate__c = 10;
        uptVar3.Apttus_Config2__PriceOverride__c = 10;
        uptList.add(uptVar3);

        insert uptList;

        List<OpportunityLineItem> listOli = new List<OpportunityLineItem>();
        OpportunityLineItem oli = APT_TestUtil2.createOpportunityLI(oppVar, priceBookEntry1.Id, 'New Business');
        oli.TotalPrice = 2000;
        oli.Quantity = 10;
        listOli.add(oli);

        OpportunityLineItem oli2 = APT_TestUtil2.createOpportunityLI(oppVar, priceBookEntry2.Id, 'New Business');
        oli2.TotalPrice = 1000;
        oli2.Quantity = 10;
        listOli.add(oli2);
        insert listOli;

        List<APT_Opportunity_Product_Line_Item__c> APTOplList = new List<APT_Opportunity_Product_Line_Item__c>();
        APT_Opportunity_Product_Line_Item__c APTopliVar = APT_TestUtil2.createAPTOpportunityLI(proposalVar,IntBundleVar);
        APTopliVar.APT_TotalPrice__c = 2000;
        APTopliVar.APT_Quantity__c = 10;
        APTopliVar.APT_Revenue_Start_Date__c = System.Today();
        APTopliVar.APT_Revenue_End_Date__c= System.Today() + 10;
        APTopliVar.APT_Classification__c = 'New Business';
        APTopliVar.APT_Unit_Sales_Price__c = 200;
        APTOplList.add(APTopliVar);

        APT_Opportunity_Product_Line_Item__c APTopliVar2 = APT_TestUtil2.createAPTOpportunityLI(proposalVar,DomesticProdVar);
        APTopliVar2.APT_TotalPrice__c = 1000;
        APTopliVar2.APT_Quantity__c = 10;
        APTopliVar2.APT_Revenue_Start_Date__c = System.Today();
        APTopliVar2.APT_Revenue_End_Date__c= System.Today() + 10;
        APTopliVar2.APT_Classification__c = 'New Business';
        APTopliVar2.APT_Unit_Sales_Price__c = 100;
        APTOplList.add(APTopliVar2);

        insert APTOplList;

        // Create Opportunity Product Line Item
        /*
        List<APT_Opportunity_Product_Line_Item__c> lstOLI = new List<APT_Opportunity_Product_Line_Item__c>();
        APT_Opportunity_Product_Line_Item__c OppProLineItem = APT_TestUtils.createOpProdLI('Renewal','Yes',bundle1.id,prodconfig.id,1,Proposal.id, 1, Date.Today(),Date.Today() + 100);
        OppProLineItem.APT_Sub_Classification__c = 'Contracted Price Increases';
        OppProLineItem.APT_TotalPrice__c = 10;
        lstOLI.add(OppProLineItem);

        insert lstOLI;
        */
        /*
        APT_Promo_Post_allowed_Lodgements__c custLodgement = new APT_Promo_Post_allowed_Lodgements__c();
        custLodgement.Name = 'ADELAIDE BC BULK DOCK';
        custLodgement.APT_Post_code__c = '6000';
        insert custLodgement;
        */

        
        proposalVar.Apttus_QPConfig__ConfigurationFinalizedDate__c = System.today();
        proposalVar.Apttus_Proposal__Primary__c = true;
        proposalVar.Apttus_Proposal__Approval_Stage__c = APT_Constants.APPROVAL_STAGE_ACCEPTED;
        //proposalVar.APT_Contract_Id__c =  origContract.Id;
        update proposalVar;
        //APT_ProposalTriggerHandler.afterUpdateEvent(newlist,map1);

        //APT_ProposalTriggerHandler.sycWithOpportunity(setids);
        //APT_ProposalTriggerHandler.createQuoteLP(setproposals);
        //system.assert(pgRef == null);


        test.stopTest();
        oppVar = [select APT_Revenue_Decrease__c from opportunity where id= :oppVar.Id];
        //System.assert(oppVar.APT_Revenue_Decrease__c == 94);
    }

    /**
    *Added By Lyndon Lavapie
    *Test method to cover Computation of Decrease Revenue
    **/
    /*
    static testMethod void testMethod4() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {
                //Create Account
         Account acc = APT_TestUtils.createOrganisation();
         insert acc;

         //create international product
         Product2 bundle1 = APT_TestUtils.createInternationalProduct('International Bundle','eParcelStandard','Postal Services');
         bundle1.APT_Sync_with_Opportunity__c = TRUE;
         bundle1.APT_Is_Cash_Account_Product__c = false;
         bundle1.APT_Is_Charge_Account_Product__c =true;
         insert bundle1;


        //Create price book entry
        PricebookEntry priceBookEntry1 =  APT_TestUtils.getPricebookEntry(Test.getStandardPricebookId(),bundle1.id);
        insert priceBookEntry1;
        List<Opportunity> opptyList = new List<Opportunity>();
        //Create Opportunity
        Opportunity origOppty = APT_TestUtils.createOpportunity(acc.id);
        origOppty.Amount = 100;
        opptyList.add(origOppty);
        //insert origOppty;

        //Create Opportunity
         Opportunity opty = APT_TestUtils.createOpportunity(acc.id);
         opty.Amount = 100;
         opptyList.add(opty);

         //Create Opportunity
         Opportunity opty2 = APT_TestUtils.createOpportunity(acc.id);
         opty2.Amount = 100;
         opptyList.add(opty2);

         insert(opptyList);
         //insert opty;


        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId=opty.Id, PricebookEntryId=priceBookEntry1.Id, Quantity=10 );
        oli.Contract_Start_Date__c = Date.Today();
        oli.Contract_End_Date__c = Date.Today() + 100;
        oli.Classification__c = 'New Business';
        oli.TotalPrice = 20.00;
        insert oli;



         //Create PriceList
         Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
         insert priceList;

         //Create Budget_and_Revenue__c
         Budget_and_Revenue__c barObj = new Budget_and_Revenue__c();
         barObj.Name = 'Test Name';
         barObj.Organisation__c = acc.Id;
         barObj.Int_Last_Upd_Date__c = System.today().addDays(-90);
         barObj.Product__c = bundle1.Id;

         Insert barObj;

         //Create Option product
         Product2 option = APT_TestUtils.createInternationalProduct('International Bundle','eParcelStandard','Postal Services');
         option.Apttus_Config2__ConfigurationType__c='Option';
         option.APT_Sync_with_Opportunity__c = TRUE;
         insert option;

         //Create Price list Item
         Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.id,bundle1.id,'C Manufacturing','BAND 2');
         insert pli;

         //create networ
         List<Network__c> lstntwk = new List<Network__c>();
         Network__c ntwk = APT_TestUtils.createNetwork();
         lstntwk.add(ntwk);
         Network__c ntwk1 = APT_TestUtils.createNetwork();
         ntwk1.Name = 'Lodgement Point 2';
         ntwk1.Post_Code__c = '2323';
         ntwk1.Org_ID__c = 'A1pOMJJ0QXeb';
         ntwk1.APT_DWS_ID__c = 'A1pOMJJ0QXeb';
         lstntwk.add(ntwk1);
         insert lstntwk;


         List<Apttus_Proposal__Proposal__c> proposalList = new List<Apttus_Proposal__Proposal__c>();
         //Create Proposal
         Apttus_Proposal__Proposal__c Proposal1= APT_TestUtils.getQuoteProposal(acc.id,opty.id,'Proposal','Quote', priceList.id);
         Proposal1.Apttus_Proposal__Approval_Stage__c='Draft';
         proposalList.add(Proposal1);
         //insert Proposal1;

         Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.id,opty.id,APT_Constants.RECORD_TYPE_AMENDMENT_QUOTE,'Quote', priceList.id);

         Proposal.Apttus_Proposal__Approval_Stage__c='Draft';
         //Proposal.APT_Original_Opportunity__c = opty.Id;
         Proposal.Expected_Revenue_Start_Date__c = System.today();
         Proposal.Expected_Revenue_End_Date__c = System.today() +90;
         Proposal.Apttus_Proposal__Primary__c =false;
         Proposal.APT_Revenue_Type__c = APT_AmendRenewController.DECREASE_REVENUE;
         //Proposal.APT_Selected_LP__c = ntwk.id;
         //insert Proposal;
         proposalList.add(Proposal);

         insert proposalList;

         List<Apttus__APTS_Agreement__c> contractList = new List<Apttus__APTS_Agreement__c>();
        Apttus__APTS_Agreement__c  origContract  = new Apttus__APTS_Agreement__c(Apttus__Account__c = acc.ID,
                                                                                 Apttus__Status__c = 'Amended',
                                                                                 Apttus__Status_Category__c ='Superseded',
                                                                                 Apttus__Agreement_Number__c = '01234567',
                                                                                 Apttus__Related_Opportunity__c=origOppty.ID );
        //insert origContract;
        contractList.add(origContract);


        Apttus__APTS_Agreement__c  contract1  = new Apttus__APTS_Agreement__c(Apttus__Account__c = acc.ID,
                                                                                 Apttus__Status__c = 'Request',
                                                                                 Apttus__Status_Category__c ='Request',
                                                                                 Apttus__Agreement_Number__c = '01234567',
                                                                                 Apttus__Related_Opportunity__c=opty.ID );
        //insert contract1;
        contractList.add(contract1);
        insert contractList;



         APT_Opportunity_Product_Line_Item__c opli = new APT_Opportunity_Product_Line_Item__c();
            opli.APT_Quote_Proposal__c = Proposal.id;
            opli.APT_Product__c = bundle1.Id;
            opli.APT_Quantity__c = 3;
            opli.APT_TotalPrice__c = 6;
            opli.APT_Revenue_Start_Date__c = System.Today();
            opli.APT_Revenue_End_Date__c= System.Today() + 10;
            insert opli;

         //Create Product Configuration
         Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1,
         proposal.id, 'Proposal',
         'Ad Hoc',priceList.id, null,
         'Finalized',
         null, Datetime.now(), true);
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
            bundleLine.APT_Selected_LP__c = ntwk.Id + ',' + ntwk1.Id;
                    insert bundleLine;

           //Create Proposal Line Item
            Apttus_Proposal__Proposal_Line_Item__c proposalLT1= APT_TestUtils.getProposalLineItem(Proposal.id,bundleLine.id,pli.id,bundle1.id,option.id);
            proposalLT1.Apttus_QPConfig__Quantity2__c=3;
            proposalLT1.Apttus_QPConfig__NetPrice__c=10;
            insert proposalLT1;

           //Create Proposal Product AttributeValue
           Apttus_QPConfig__ProposalProductAttributeValue__c ProposalProductAttributeValue1 =APT_TestUtils.getProposalProductAttributeValue(proposalLT1.id);
           insert ProposalProductAttributeValue1;
            List<Apttus_Proposal__Proposal__c> newlist = new List<Apttus_Proposal__Proposal__c>();
             newlist.add(proposal1);

            map<id, Apttus_Proposal__Proposal__c> map1 = new map<id, Apttus_Proposal__Proposal__c>();
                    map1.put(proposal.id,proposal);

            set<Apttus_Proposal__Proposal__c> setproposals = new set<Apttus_Proposal__Proposal__c>();
            set<Id> setids = new set<Id>();
            setproposals.add(proposal);
            setids.add(proposal.Id);
            test.startTest();



            //Update the status of Proposal to Accepted
            Proposal.RecordTypeId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get(APT_Constants.RECORD_TYPE_AMENDMENT_QUOTE).getRecordTypeId();
            //Proposal.APT_Revenue_Type__c = APT_AmendRenewController.DECREASE_REVENUE;
            Proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c = System.today();
            Proposal.Apttus_Proposal__Primary__c = true;
            Proposal.Apttus_Proposal__Approval_Stage__c = APT_Constants.APPROVAL_STAGE_ACCEPTED;
            Proposal.APT_Contract_Id__c =  origContract.Id;
            update Proposal;
            //APT_ProposalTriggerHandler.afterUpdateEvent(newlist,map1);

             //APT_ProposalTriggerHandler.sycWithOpportunity(setids);
             //APT_ProposalTriggerHandler.createQuoteLP(setproposals);
            //system.assert(pgRef == null);


            test.stopTest();
            opty = [select APT_Revenue_Decrease__c from opportunity where id= :opty.Id];
            System.assert(opty.APT_Revenue_Decrease__c == 94);
     }
    }
    */
    /**
    *Added By Lyndon Lavapie
    *Test method to cover changes to block Oppty stage update on decrease revenue
    **/
    /*
    static testMethod void testMethod5() {

        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {
         Account acc = APT_TestUtils.createOrganisation();
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
         bundle1.APT_Is_Cash_Account_Product__c = false;
         bundle1.APT_Is_Charge_Account_Product__c =true;
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

         //create networ
         Network__c ntwk = APT_TestUtils.createNetwork();
         insert ntwk;


         Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.id,opty.id,APT_Constants.RECORD_TYPE_AMENDMENT_QUOTE,'Quote', priceList.id);
         Proposal.Apttus_Proposal__Approval_Stage__c='Draft';
         Proposal.Expected_Revenue_Start_Date__c = System.today();
         Proposal.Expected_Revenue_End_Date__c = System.today() +90;
         Proposal.Apttus_Proposal__Primary__c =false;
         Proposal.APT_Selected_LP__c = ntwk.id;
         Proposal.APT_Revenue_Type__c = APT_AmendRenewController.INCREASE_REVENUE;
         insert Proposal;


            test.startTest();


            Proposal.Apttus_Proposal__Approval_Stage__c = 'Accepted';
            Proposal.Apttus_QPConfig__ConfigurationFinalizedDate__c = System.today();
            Proposal.Apttus_Proposal__Primary__c = true;

            update Proposal;

            test.stopTest();
            Opportunity opptyResult = [Select Id, StageName From Opportunity where Id =:opty.Id];
            System.assertEquals(opptyResult.StageName, 'Propose');
        }
    }
    */
   /* static testMethod void testMethod4() {
        APT_ProposalTriggerHandler controller = new APT_ProposalTriggerHandler();
        Account acc = APT_TestUtils.createOrganisation();
        insert acc;                          
     
        //Create Opportunity
        Opportunity opty = APT_TestUtils.createOpportunity(acc.id);
        insert opty;   
         set<id> ids = new set<id>();
         ids.add(opty.id);            
        test.startTest();
        APT_ConfigurationTriggerHandler.deleteExistingOpportunityLineItems(ids);
        //system.assert(pgRef == null);
        test.stopTest();        
    }

static testMethod void testMethod5() {
        APT_ProposalTriggerHandler controller = new APT_ProposalTriggerHandler();
                
        //Create Account
     Account acc = APT_TestUtils.createOrganisation();
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
     insert Proposal;
     
     //Create Product Configuration             
     Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
     proposal.id, 'Proposal',
     'Ad Hoc',priceList.id, null,
     'Finalized',
     null, Datetime.now(), true);
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
      
       //Create Proposal Line Item               
        Apttus_Proposal__Proposal_Line_Item__c proposalLT1= APT_TestUtils.getProposalLineItem(Proposal.id,bundleLine.id,pli.id,bundle1.id,option.id);
        
        insert proposalLT1;
        system.debug('^^!!'+proposalLT1);
        
        
       //Create Proposal Product AttributeValue
       Apttus_QPConfig__ProposalProductAttributeValue__c ProposalProductAttributeValue1 =APT_TestUtils.getProposalProductAttributeValue(proposalLT1.id);
       insert ProposalProductAttributeValue1;
        List<Apttus_Proposal__Proposal__c> newlist = new List<Apttus_Proposal__Proposal__c>();
         newlist.add(proposal);
                       
        map<id, PriceBookEntry> map1 = new map<id, PriceBookEntry>();
        
        map1.put(option.id,standardPrice);
        Set<id> ids = new Set<id>();
        
        ids.add(Proposal.id);

        
        test.startTest();
        APT_ProposalTriggerHandler.createOpportunityLineItems(proposalLT1,map1);
        //APT_ProposalTriggerHandler.createQuoteLP(ids);
        APT_ProposalTriggerHandler.createLineItemRateCard(ids);
        //system.assert(pgRef == null);
        test.stopTest();        







               
    } */

    public static testMethod void contractingEntityAutomationTest(){

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

        /*legacyacct.Legacy_Id__c = '60000000';
        update legacyacct;

        Billing_Account__c billacc = APT_TestUtils.createBillingAccount(tempacct.id);
        billacc.LEGACY_ID__c = '60000000';
        insert billacc;*/

        Opportunity opp1 = APT_TestUtils.createOpportunity(tempacct.id);
        insert opp1;

        List<Product2> productList = new List<Product2>();
        Product2 product =APT_TestUtils.createInternationalProduct('Road Express - STE','X00','Parcel Services');
        product.APT_Product_Type__c = 'StarTrack';//add product type to product
        product.APT_Product_Lines__c = 'StarTrack';
        product.APT_Contracting_Entity__c = 'StarTrack Express Pty Ltd';
        product.Apttus_Config2__ConfigurationType__c = 'Bundle';
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

        List<Apttus_Config2__PriceListItem__c> priceListItemList = new List<Apttus_Config2__PriceListItem__c>();
        Apttus_Config2__PriceListItem__c priceListItem1 = APT_TestUtils.createPriceListItem(priceList.id,product.id,'','');
        Apttus_Config2__PriceListItem__c priceListItem2 = APT_TestUtils.createPriceListItem(priceList.id,product1.id,'','');
        priceListItemList.add(priceListItem1);
        priceListItemList.add(priceListItem2);
        insert priceListItemList;

        Apttus_Proposal__Proposal__c proposal = APT_TestUtils.getQuoteProposal(tempacct.id,opp1.Id,'Proposal','Test',priceList.id);
        proposal.Apttus_Proposal__Approval_Stage__c = 'Draft';
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
        List<Apttus_Config2__LineItem__c>lineItemList = new List<Apttus_Config2__LineItem__c>();
        Apttus_Config2__LineItem__c lineItem1 = APT_TestUtils.getConfigLineItem(config.id,summaryGroup.id  ,1,true,2,'',product.id,false,prodOptionComponent.id,
                product.id,classHierarchy.id,'',2.3,false,'',2,priceList.id,priceListItem1.Id,'','','','',
                false,false,22.00,24.00,'',34.00,23.00,33.50,'');
        lineItemList.add(lineItem1);
        Apttus_Config2__LineItem__c lineItem2 = APT_TestUtils.getConfigLineItem(config.id,summaryGroup.id  ,1,true,2,'',product1.id,false,prodOptionComponent.id,
                product.id,classHierarchy.id,'',2.3,false,'',2,priceList.id,priceListItem2.Id,'','','','',
                false,false,22.00,24.00,'',34.00,23.00,33.50,'');  
        lineItemList.add(lineItem2);                
        insert lineItemList;

        Apttus_Config2__ProductAttributeValue__c attriObj1 = new Apttus_Config2__ProductAttributeValue__c(Apttus_Config2__LineItemId__c =lineItem1.ID,APT_PostBillPay_Gross_Settlement_fee__c = 'Yes', APT_Monthly_Spend__c=100.00);
        insert attriObj1;

        Apttus_Config2__ProductAttributeValue__c attriObj2 = new Apttus_Config2__ProductAttributeValue__c(Apttus_Config2__LineItemId__c =lineItem2.ID,APT_PostBillPay_Gross_Settlement_fee__c = 'Yes', APT_Monthly_Spend__c=200.00);
        insert attriObj2;

        lineItem1.Apttus_Config2__AttributeValueId__c = attriObj1.ID;
        lineItem2.Apttus_Config2__AttributeValueId__c = attriObj2.ID;
        update lineItem1;
        update lineItem2;

        Apttus_Proposal__Proposal_Line_Item__c propLineItem = APT_TestUtils.getProposalLineItem(proposal.Id,lineItem1.Id,priceListItem1.Id,product.Id,product.Id);
        propLineItem.Apttus_Proposal__Product__c=product.Id;
        propLineItem.Apttus_QPConfig__LineNumber__c =1;
        propLineItem.Apttus_QPConfig__ItemSequence__c=1;
        insert propLineItem;

        Apttus_Proposal__Proposal_Line_Item__c propLineItem1 = APT_TestUtils.getProposalLineItem(proposal.Id,lineItem1.Id,priceListItem2.Id,product1.Id,product1.Id);
        propLineItem1.Apttus_Proposal__Product__c=product1.Id;
        propLineItem1.Apttus_QPConfig__LineNumber__c =1;
        propLineItem1.Apttus_QPConfig__ItemSequence__c=1;
        insert propLineItem1; 
        
        Test.startTest();

        proposal.Apttus_Proposal__Approval_Stage__c = 'Accepted';
        Update proposal;

        Test.stopTest();

        System.assertEquals([Select APT_Contracting_Entity__c from Apttus_Proposal__Proposal__c where id = : proposal.Id].APT_Contracting_Entity__c,'StarTrack Express Pty Ltd');


    }



}