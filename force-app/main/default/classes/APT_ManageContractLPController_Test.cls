@isTest
/**
    Description: This apex class is test class for APT_ManageRateCardProductsController.
    Created By - Raviteja Epuri
    Created Date - 20th Jan 2016
    Last Modified By - Mahesh Patel
    Last Modified Date - 12th March 2021
**/
private class APT_ManageContractLPController_Test 
{
    private static Billing_Account__c bacct;
    private static Apttus__APTS_Agreement__c agID;
    private static Apttus__AgreementLineItem__c agrmntLineItem;
    private static Network__c aptNwk;
    private static Network__c aptNwk1;
    private static Product2 bundleProduct;
    private static APT_Agreement_Lodgement_Point__c alpObject;

    @TestSetup
    static void createTestData(){
        
        Test.StartTest();

        Contact con = APT_TestUtils.createContact();
        insert con;
        
        //Create Account
        RecordType rectype = [SELECT Id FROM RecordType WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];
        Account acc = APT_TestUtils.createOrganisation();
        acc.Name = 'test organisation';
        acc.AccountNumber = 'Cus 60000000';
        acc.RecordTypeId = rectype.ID;
        acc.Legacy_Id__c = '60000000';
        insert acc;
        
        Opportunity opp = APT_TestUtils.createOpportunity(acc.id);
        //opp.KeyContact__c = con.Id;
        insert opp;
        
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;

        //Create Network
        RecordType aptNwkRecordType = [SELECT Id, Name FROM RecordType WHERE DeveloperName = 'Delivery_1' AND sObjectType = 'Network__c' limit 1];
        aptNwk = APT_TestUtils.createNetwork();
        aptNwk.Post_Code__c = '1000';
        aptNwk.Status__c = 'Open';
        aptNwk.State__c = 'ACT';
        aptNwk.APT_eParcel_Enabled__c = APT_Constants.OPTION_YES;
        aptNwk.Org_ID__c = '272786';
        aptNwk.APT_Transport_Capability__c = 'Either VAN or Truck';
        // Adrian Recio, 22/5/2017, Test class population for APT Business Unit field
        aptNwk.APT_Business_Unit__c = 'Bussiness';
        aptNwk.Business_Unit__c = '10000000';
        aptNwk.RecordTypeID = aptNwkRecordType.ID; 
        insert aptNwk;
        
        //Create Network Hub
        APT_Network_Hubs__c networkHub = new APT_Network_Hubs__c();
        networkHub.APT_Post_Code__c = '1000';
        networkHub.APT_Parent_Hub__c = aptNwk.Id;
        insert networkHub;

        //Create Proposal
        Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opp.ID,'Proposal','Quote', priceList.ID);
        //Proposal.Expected_Revenue_Start_Date__c = System.Today() - 20;
        //Proposal.Apttus_Proposal__Approval_Stage__c = 'Accepted';
        //Proposal.Apttus_Proposal__Opportunity__c = opp.Id;
        insert Proposal;
       
        //Create Agreement
        agID = APT_TestUtils.createAgreement(con.id);
        agID.Name = 'agId';
        agID.Apttus__Account__c = acc.id;
        insert agID;
        
        //Create Lodgement Zone
        APT_Lodgement_Zone__c lodZone = APT_TestUtils.getLodgementZone('Lodgement','Test');
        lodZone.APT_Post_Code_Start__c = 1;
        lodZone.APT_Post_Code_End__c = 9999;
        insert lodZone;
        
        //Create Cash Account 
        APT_Cash_Account__c cacct = new APT_Cash_Account__c();
        insert cacct; 

        //Create Agreement Lodgement Point
        APT_Agreement_Lodgement_Point__c objALP = APT_TestUtils.createLodgementPoint(acc.id,agID.id,aptNwk.id,lodZone.id,'Promo Post',null);
        objALP.APT_Status__c = 'Active';
        objALP.APT_Cash_Account__c = cacct.Id;
        insert objALP;  
        
        //create international product
        Product2 bundle1 = APT_TestUtils.createDomesticProduct('Promo Post','eParcelStandard','Postal Services','CAT1', 'Standard');
        bundle1.APT_Sync_with_Opportunity__c=true;
        bundle1.APT_Is_Charge_Account_Product__c = true;
        bundle1.APT_Is_Cash_Account_Product__c = false;
        bundle1.APT_Consolidated_Usage_Price_Tiers__c = true;
        insert bundle1;
             
        //Create Option product
        Product2 option = APT_TestUtils.createDomesticProduct('Eparcel','eParcelStandard','Postal Services','CAT1', 'Standard');
        option.Apttus_Config2__ConfigurationType__c='Option';
        option.APT_Sync_with_Opportunity__c=true;
        option.APT_International_Pricing__c = false;
        option.APT_Consolidated_Usage_Price_Tiers__c = true;
        insert option;
             
        //Create Price list Item
        Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
        insert pli;
                    
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
        bundleLine.Apttus_Config2__NetAdjustmentPercent__c = 10;
        bundleLine.Apttus_Config2__ParentBundleNumber__c = 1;
        bundleLine.Apttus_Config2__OptionId__c = option.ID;
        insert bundleLine;                  
      
        //Create Proposal Line Item               
        Apttus_Proposal__Proposal_Line_Item__c proposalLT1= APT_TestUtils.getProposalLineItem(Proposal.id,bundleLine.id,pli.id,bundle1.id,option.id);
        proposalLT1.Apttus_QPConfig__Quantity2__c=3;
        proposalLT1.Apttus_QPConfig__NetPrice__c=10;
        proposalLT1.Apttus_QPConfig__IsPrimaryLine__c = true;
        proposalLT1.Apttus_QPConfig__OptionId__c = null;
        proposalLT1.Apttus_QPConfig__ParentBundleNumber__c = 1;
        insert proposalLT1;
        
        //Create product Attribute value                
        Apttus_Config2__ProductAttributeValue__c attribute1 = APT_TestUtils.GetAttributeValue(bundleLine.Id,'Standard',false,false,false,'Yes','B Mining',True,false);
        attribute1.Category__c='CAT1';
        attribute1.APT_Lodgement_Zone__c=lodZone.ID; 
        attribute1.APT_Lodgement_State__c = 'ACT';
        attribute1.APT_AirmailSmallParcelGT2kgAVGWeightKG__c = 3;  
        attribute1.APT_Postcode__c ='1000';    
        insert attribute1;

        //agreement line item
        agrmntLineItem = new Apttus__AgreementLineItem__c (Apttus__ProductId__c=bundle1.Id,Apttus_CMConfig__LineNumber__c=1,
                                                        Apttus_CMConfig__ItemSequence__c=1,Apttus__AgreementId__c=agID.Id,Apttus_CMConfig__BaseProductId__c=bundle1.Id,Apttus_CMConfig__BillToAccountId__c=acc.Id,Apttus_CMConfig__DerivedFromId__c=bundleLine.Id);
        agrmntLineItem.Apttus_CMConfig__IsPrimaryLine__c = true;
        agrmntLineItem.Apttus_CMConfig__LineType__c = 'Product/Service';
        insert agrmntLineItem;
        
        //Store into global member to access in other mathods
        bundleProduct = bundle1;
        alpObject = objALP;

        //create custom setting APT_SiteInspectionLookupFieldIds__c
        List<APT_SiteInspectionLookupFieldIds__c> siteInspectionLookupFieldIds = new List<APT_SiteInspectionLookupFieldIds__c>();

        APT_SiteInspectionLookupFieldIds__c siteInspectionLookupFieldId1 = new APT_SiteInspectionLookupFieldIds__c();
        siteInspectionLookupFieldId1.Name = 'APT_Agreement_Lodgement_Point__c';
        siteInspectionLookupFieldId1.Field_Id__c = 'Field_Id__c';
        siteInspectionLookupFieldIds.add(siteInspectionLookupFieldId1);

        APT_SiteInspectionLookupFieldIds__c siteInspectionLookupFieldId2 = new APT_SiteInspectionLookupFieldIds__c();
        siteInspectionLookupFieldId2.Name = 'APT_Collection_Street_Address__c';
        siteInspectionLookupFieldId2.Field_Id__c = 'Field_Id__c';
        siteInspectionLookupFieldIds.add(siteInspectionLookupFieldId2);

        APT_SiteInspectionLookupFieldIds__c siteInspectionLookupFieldId3 = new APT_SiteInspectionLookupFieldIds__c();
        siteInspectionLookupFieldId3.Name = 'APT_Contract__c';
        siteInspectionLookupFieldId3.Field_Id__c = 'Field_Id__c';
        siteInspectionLookupFieldIds.add(siteInspectionLookupFieldId3);

        APT_SiteInspectionLookupFieldIds__c siteInspectionLookupFieldId4 = new APT_SiteInspectionLookupFieldIds__c();
        siteInspectionLookupFieldId4.Name = 'APT_Customer_Contact_Name__c';
        siteInspectionLookupFieldId4.Field_Id__c = 'Field_Id__c';
        siteInspectionLookupFieldIds.add(siteInspectionLookupFieldId4);

        APT_SiteInspectionLookupFieldIds__c siteInspectionLookupFieldId5 = new APT_SiteInspectionLookupFieldIds__c();
        siteInspectionLookupFieldId5.Name = 'APT_Lodgement_Point__c';
        siteInspectionLookupFieldId5.Field_Id__c = 'Field_Id__c';
        siteInspectionLookupFieldIds.add(siteInspectionLookupFieldId5);

        APT_SiteInspectionLookupFieldIds__c siteInspectionLookupFieldId6 = new APT_SiteInspectionLookupFieldIds__c();
        siteInspectionLookupFieldId6.Name = 'APT_Lodgement_Zone__c';
        siteInspectionLookupFieldId6.Field_Id__c = 'Field_Id__c';
        siteInspectionLookupFieldIds.add(siteInspectionLookupFieldId6);

        APT_SiteInspectionLookupFieldIds__c siteInspectionLookupFieldId7 = new APT_SiteInspectionLookupFieldIds__c();
        siteInspectionLookupFieldId7.Name = 'APT_Organisation__c';
        siteInspectionLookupFieldId7.Field_Id__c = 'Field_Id__c';
        siteInspectionLookupFieldIds.add(siteInspectionLookupFieldId7);

        APT_SiteInspectionLookupFieldIds__c siteInspectionLookupFieldId8 = new APT_SiteInspectionLookupFieldIds__c();
        siteInspectionLookupFieldId8.Name = 'APT_Postal_Code__c';
        siteInspectionLookupFieldId8.Field_Id__c = 'Field_Id__c';
        siteInspectionLookupFieldIds.add(siteInspectionLookupFieldId8);

        APT_SiteInspectionLookupFieldIds__c siteInspectionLookupFieldId9 = new APT_SiteInspectionLookupFieldIds__c();
        siteInspectionLookupFieldId9.Name = 'APT_State__c';
        siteInspectionLookupFieldId9.Field_Id__c = 'Field_Id__c';
        siteInspectionLookupFieldIds.add(siteInspectionLookupFieldId9);

        APT_SiteInspectionLookupFieldIds__c siteInspectionLookupFieldId10 = new APT_SiteInspectionLookupFieldIds__c();
        siteInspectionLookupFieldId10.Name = 'APT_Suburb__c';
        siteInspectionLookupFieldId10.Field_Id__c = 'Field_Id__c';
        siteInspectionLookupFieldIds.add(siteInspectionLookupFieldId10);

        insert siteInspectionLookupFieldIds;

        Test.StopTest();

    }   

    private static testMethod void testAgreementErr() {
        // Setup test data
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);

        System.runAs(testuser) {
            
            Test.startTest();

            Apttus__APTS_Agreement__c agreement = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];
            Apttus__AgreementLineItem__c agreementLI = [SELECT Id FROM Apttus__AgreementLineItem__c LIMIT 1];
            
            Network__c network = [SELECT Id FROM Network__c LIMIT 1];

            APT_Agreement_Lodgement_Point__c agrLP = [SELECT Id FROM APT_Agreement_Lodgement_Point__c LIMIT 1];

            Apttus_Config2__LineItem__c tmLineItem = [SELECT Id, Apttus_Config2__ProductId__c  from Apttus_Config2__LineItem__c LIMIT 1]; 
            tmLineItem.Apttus_Config2__ProductId__c = '01t90000007BTm0AAG';
            update tmLineItem;

            Apexpages.currentPage().getParameters().put('agId',agreement.id);
            Apexpages.currentPage().getParameters().PUT('deactivateALIId', agrLP.id);
            Apexpages.currentPage().getParameters().PUT('selectedALIId', agreementLI.id);
            Apexpages.currentPage().getParameters().PUT('redirectALIId', agrLP.id);
            ApexPages.currentPage().getHeaders().put('Referer', 'https://auspost--devr2t--apttus-config2.cs5.visual.force.com/apex/CartDetailView?configRequestId=a4sO0000000Cu0oIAC&id=a4NO00000009fSrMAI&flow=NewQuote&launchState=cart');

            APT_ManageContractLPController objCls = new APT_ManageContractLPController();
            
            objCls.source = 'ProdSpecific';
            objCls.agreementId = agreement.Id;
            objCls.addProdSpecificLP();
            objCls.agreementId = agreement.Id;
            objCls.doSelectALIMthd();
            objCls.agreementId = agreement.Id;
            objCls.stateval= 'ACT';
            objCls.domesticLodgementZone = 'Test';
            objCls.productId = '01t90000007BTm0AAG';
            objCls.lodgementPoint = new Network__c(); 
            objCls.lodgementPoint.APT_Transport_Capability__c = APT_Constants.TRANSPORT_CAPABILITY_EITHER_VAN_OR_TRUCK;
            objCls.lodgementPoint.APT_eParcel_Enabled__c = APT_Constants.OPTION_YES;
            objCls.lodgementPoint.Post_Code__c = '1000';
            objCls.bussinessUnit = 'Hub';
            objCls.SearchLP();
            objCls.showallLodgementpoints();
    
            objCls.listLodgementPointWrapper.get(0).IsSelected = true;

            Apexpages.currentPage().getParameters().put('selectedLodgementPointId', network.Id);

            objCls.AddLP();
            objCls.deactivateLP();
            objCls.addGenericLP();
            objCls.searchLPButton();

            objCls.recordsperpage = 1000;
            objCls.offSetVal = 1500;
            objCls.goPrevious();

            objCls.getBussinessPickval();
            objCls.getdomesticLodgementZoneVal();
            objCls.redirectSite();
            objCls.showPopup();
            objCls.redirectPopup();
            objCls.closePopup();

            objCls.source = 'ProdSpecific';
            objCls.agreementId = agreement.Id;
            objCls.doSelectALIMthd();

            PageReference pgRef = objCls.showallLodgementpoints();
            
            objCls.offSetVal = 2200;
            objCls.goNext();
            objCls.goLast();

            Test.stopTest();
            System.assert(pgRef == null);
        }
    }
    
    private static testMethod void testAgreementEr() {
        // Setup test data
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);

        System.runAs(testuser) {
            Test.startTest();
            ApexPages.currentPage().getParameters().put('agId',null);
            APT_ManageContractLPController objCls1 = new APT_ManageContractLPController();
            PageReference pgRef = objCls1.backToContract();
            
            Test.stopTest();
            System.assert(pgRef != null);
        }
    }
    private static testMethod void testProdNoItemsError(){
        // Setup test data
        // This code runs as the system admin test user
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);

        System.runAs(testuser) {
            test.startTest();
            APT_ManageContractLPController objCls = new APT_ManageContractLPController();
            pageReference pgRef = objCls.addProdSpecificLP();
            
            test.stopTest();
            System.assert(pgRef == null);
        }
    }
}