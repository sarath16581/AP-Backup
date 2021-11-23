@isTest
private class APT_AgreementTriggerHandler_Test{

    public static testMethod void includedProductLinesAutomationTest(){

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
        //aptContract3.Apttus__Related_Opportunity__c=opp3.Id;
        aptContract3.Apttus__Account__c=tempacct.Id;
        aptContract3.RecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
        aptContract3.Apttus_QPComply__RelatedProposalId__c = proposal.ID;
        aptContract3.APT_New_Rate_Card_Download__c = true;
        aptContract3.OwnerId = u1.ID;
        aptContract3.Apttus__Status_Category__c = 'Request';
        aptContract3.Apttus__Status__c = 'Request';
        aptContract3.APT_Contract_Type__c = APT_Constants.CONTRACT_TYPE_NEW_CONTRACT;
        agreeList.add(aptContract3);

        Test.startTest();

        insert agreeList;

        Test.stopTest();
        //get agreement & the operational schedule record getting created.
        Apttus__APTS_Agreement__c agreementAfterInsert = [Select Included_Product_Lines__c, Apttus_QPComply__RelatedProposalId__r.APT_Contracting_Entity__c,
                                                                (Select Id, APT_Minimum_Monthly_Revenue__c,
                                                                APT_Startrack__c,APT_Express_Road__c,
                                                                APT_Special_Services_Tailgate__c,
                                                                Premium_Priority_Air_Services__c,
                                                                APT_Security_Services__c,
                                                                APT_Next_Flight__c
                                                                from Operational_Schedules__r) 
                                                        from Apttus__APTS_Agreement__c where Id = : agreeList[0].Id];
        System.Assert(agreementAfterInsert.Included_Product_Lines__c.containsIgnoreCase('StarTrack'));
        System.Assert(agreementAfterInsert.Operational_Schedules__r[0].APT_Express_Road__c);
        System.AssertEquals(agreementAfterInsert.Operational_Schedules__r[0].APT_Minimum_Monthly_Revenue__c,1000.00);
        System.Assert(agreementAfterInsert.Operational_Schedules__r[0].APT_Startrack__c);

    }
    public static testMethod void testingData(){

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

        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp1 = APT_TestUtils.createOpportunity(tempacct.id);
        Opportunity opp2 = APT_TestUtils.createOpportunity(tempacct.id);
        Opportunity opp3 = APT_TestUtils.createOpportunity(tempacct.id);
        oppList.add(opp1);
        oppList.add(opp2);
        oppList.add(opp3);
        insert oppList;

        List<Product2> productList = new List<Product2>();
        Product2 product =APT_TestUtils.createInternationalProduct('Postal Services','26940998','Postal Services');
        product.name = APT_Constants.BUNDLE_NAME_INTERNATIONAL;
        product.APT_Product_Type__c = 'Workforce Verification';//add product type to product
        productList.add(product);

        Product2 product1 =APT_TestUtils.createInternationalProduct('Postal Services','26940998','Postal Services');
        product1.ProductCode = APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD;
        product1.APT_Product_Type__c = 'Workforce Verification';//add product type to product
        productList.add(product1);

        Product2 product2 =APT_TestUtils.createInternationalProduct('Postal Services','26940998','Postal Services');
        product2.Family = APT_Constants.PARCEL_SERVICES;
        product2.APT_Product_Type__c = 'Workforce Verification';//add product type to product
        productList.add(product2);

        Product2 product3 =APT_TestUtils.createInternationalProduct('Postal Services','26940998','Postal Services');
        product3.APT_Product_Type__c = 'Workforce Verification';//add product type to product
        productList.add(product3);

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
        Apttus_Config2__ProductAttributeValue__c attriObj = new Apttus_Config2__ProductAttributeValue__c(Apttus_Config2__LineItemId__c =lineItem.ID,APT_PostBillPay_Gross_Settlement_fee__c = 'Yes');
        insert attriObj;

        lineItem.Apttus_Config2__AttributeValueId__c = attriObj.ID;
        update lineItem;

        Apttus_Proposal__Proposal_Line_Item__c propLineItem = APT_TestUtils.getProposalLineItem(proposal.Id,lineItem.Id,priceListItem.Id,product.Id,product.Id);
        propLineItem.Apttus_Proposal__Product__c=product.Id;
        propLineItem.Apttus_QPConfig__LineNumber__c =1;
        propLineItem.Apttus_QPConfig__ItemSequence__c=1;
        insert propLineItem;

        APT_Lodgement_Zone__c LP = APT_TestUtils.getLodgementZone('Sample','1234');
        insert LP;

        APT_Quote_Lodgement_Point__c quoteLP = new APT_Quote_Lodgement_Point__c(APT_Proposal_Line_Item__c=propLineItem.Id,APT_Quote_Proposal__c=proposal.Id,APT_Lodgement_Zone_Lookup__c=LP.Id);
        insert quoteLP;

        APT_Line_Item_Rate_Card__c lineRateCard = new APT_Line_Item_Rate_Card__c(APT_Proposal_Line_Item__c=propLineItem.Id,APT_Value_1__c='1',APT_Value_2__c='2',APT_Value_3__c='3');
        insert lineRateCard;

        //Create Proposal
        Application__c appli = new Application__c();
        //appli.Name = 'test';
        appli.Opportunity__c = opp1.Id;
        appli.Account__c = tempacct.Id;
        insert appli;

        User u1 = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name ='System Administrator' and ID != :UserInfo.getUserId()  limit 1];

        List<Apttus__APTS_Agreement__c> agreeList = new List<Apttus__APTS_Agreement__c>();

        Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
        aptContract.APT_Product__c= 'eParcel';
        aptContract.Apttus__Related_Opportunity__c=opp1.Id;
        aptContract.Apttus__Account__c=tempacct.Id;
        aptContract.RecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
        aptContract.Apttus_QPComply__RelatedProposalId__c = proposal.ID;
        aptContract.APT_New_Rate_Card_Download__c = true;
        aptContract.OwnerId = u1.ID;
        aptContract.APMS_Application__c = appli.ID;
        aptContract.Apttus__Status_Category__c = 'Request';
        aptContract.Apttus__Status__c = 'Request';
        aptContract.Included_Product_Lines__c = 'eParcels Domestic;'+APT_Constants.PRODUCT_CODE_PRINT_POST;
        agreeList.add(aptContract);

        Apttus__APTS_Agreement__c aptContract1 = APT_TestUtils.createAgreement(con.Id);
        aptContract1.APT_Product__c= 'eParcel';
        aptContract1.Apttus__Related_Opportunity__c=opp2.Id;
        aptContract1.Apttus__Account__c=tempacct.Id;
        aptContract1.RecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Post Billpay Contract').getRecordTypeId();
        aptContract1.Apttus_QPComply__RelatedProposalId__c = proposal.ID;
        aptContract1.APT_New_Rate_Card_Download__c = true;
        aptContract1.OwnerId = u1.ID;
        aptContract1.APMS_Application__c = appli.ID;
        aptContract1.Apttus__Status_Category__c = 'Request';
        aptContract1.Apttus__Status__c = 'Request';
        aptContract1.Included_Product_Lines__c = APT_Constants.PRODUCT_CODE_PRINT_POST;
        agreeList.add(aptContract1);

        Apttus__APTS_Agreement__c aptContract2 = APT_TestUtils.createAgreement(con.Id);
        aptContract2.APT_Product__c= 'eParcel';
        aptContract2.Apttus__Related_Opportunity__c=opp3.Id;
        aptContract2.Apttus__Account__c=tempacct.Id;
        aptContract2.RecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Post Billpay Contract').getRecordTypeId();
        aptContract2.Apttus_QPComply__RelatedProposalId__c = proposal.ID;
        aptContract2.APT_New_Rate_Card_Download__c = true;
        aptContract2.OwnerId = u1.ID;
        aptContract2.APMS_Application__c = appli.ID;
        aptContract2.Apttus__Status_Category__c = 'Request';
        aptContract2.Apttus__Status__c = 'Request';
        aptContract2.Included_Product_Lines__c = APT_Constants.PRODUCT_CODE_PRINT_POST;
        aptContract2.APT_Contract_Type__c = APT_Constants.CONTRACT_TYPE_NEW_CONTRACT;
        agreeList.add(aptContract2);

        //Create NetworkInterface
        List<Network__c> lstNw = new List<Network__c>();
        Network__c aptNw = APT_TestUtils.createNetwork();
        aptnw.Post_Code__c = '2586';
        aptnw.recordtypeid = Schema.SObjectType.Network__c.getRecordTypeInfosByName().get('Delivery').getRecordTypeId();
        aptnw.Status__c = 'Open';
        aptnw.APT_Apttus_LP__c = true;
        lstNw.add(aptNw);

        Network__c aptNw1 = APT_TestUtils.createNetwork();
        aptnw1.Name = 'Lodgement point 2';
        aptnw1.Post_Code__c = '2486';
        aptnw1.recordtypeid = Schema.SObjectType.Network__c.getRecordTypeInfosByName().get('Retail').getRecordTypeId();
        aptnw1.Status__c = 'Open';
        aptnw.APT_Apttus_LP__c = true;
        aptnw1.Org_ID__c = 'A1pOMJJ0QXeb';
        aptnw1.APT_DWS_ID__c = 'A1pOMJJ0QXeb';
        lstNw.add(aptNw1);

        Network__c aptNw2 = APT_TestUtils.createNetwork();
        aptNw2.Name = 'Lodgement point 2';
        aptNw2.Post_Code__c = '2486';
        aptNw2.recordtypeid = Schema.SObjectType.Network__c.getRecordTypeInfosByName().get('Business Hub').getRecordTypeId();
        aptNw2.Status__c = 'Open';
        aptnw.APT_Apttus_LP__c = true;
        aptNw2.Org_ID__c = 'A1pOMJJ0QXec';
        aptNw2.APT_DWS_ID__c = 'A1pOMJJ0QXec';
        lstNw.add(aptNw2);
        insert lstNw;

        //Create Lodgement Zone
        APT_Lodgement_Zone__c lodZone= APT_TestUtils.getLodgementZone('Lodgement','Test');
        lodZone.APT_Post_Code_End__c = 3000;
        lodZone.APT_Post_Code_Start__c = 2158;
        insert lodZone;


        Set<id> agreementID = new Set<id>();
        For(Apttus__APTS_Agreement__c ag : agreeList) {
            agreementID.add(ag.id);
        }

        Test.startTest();

        insert agreeList;



        List<Attachment>attList = new List<Attachment>();

        attachment attach = new attachment();
        attach.Name = 'testAttachment';
        attach.parentID = aptContract.ID;
        attach.body = Blob.valueOf('temp');
        attach.ContentType = 'application/msword';
        attach.IsPrivate = false;
        attach.Description = 'Test';
        attList.add(attach);

        attachment attach1 = new attachment();
        attach1.Name = 'testAttachment';
        attach1.parentID = aptContract1.ID;
        attach1.body = Blob.valueOf('temp');
        attach1.ContentType = 'application/msword';
        attach1.IsPrivate = false;
        attach1.Description = 'Test';
        attList.add(attach1);

        insert attList;

        List<Apttus__AgreementLineItem__c> aliList = new List<Apttus__AgreementLineItem__c>();

        Apttus__AgreementLineItem__c ali = new Apttus__AgreementLineItem__c();
        ali.Apttus_CMConfig__DerivedFromId__c = lineItem.ID;
        ali.Apttus__AgreementId__c = aptContract1.ID;
        ali.Apttus__ProductId__c = product.Id;
        ali.Apttus_CMConfig__LineNumber__c = 1;
        ali.Apttus_CMConfig__ItemSequence__c = 1;
        ali.Apttus_CMConfig__LineType__c = APT_Constants.LINE_TYPE_PRODUCT_SERVICE;
        ali.Apttus_CMConfig__IsPrimaryLine__c = true;
        aliList.add(ali);

        Apttus__AgreementLineItem__c ali2 = new Apttus__AgreementLineItem__c();
        ali2.Apttus_CMConfig__DerivedFromId__c = lineItem.ID;
        ali2.Apttus__AgreementId__c = aptContract1.ID;
        ali2.Apttus__ProductId__c = product1.Id;
        ali2.Apttus_CMConfig__LineNumber__c = 1;
        ali2.Apttus_CMConfig__ItemSequence__c = 1;
        ali2.Apttus_CMConfig__LineType__c = APT_Constants.LINE_TYPE_PRODUCT_SERVICE;
        ali2.Apttus_CMConfig__IsPrimaryLine__c = true;
        aliList.add(ali2);

        Apttus__AgreementLineItem__c ali3 = new Apttus__AgreementLineItem__c();
        ali3.Apttus_CMConfig__DerivedFromId__c = lineItem.ID;
        ali3.Apttus__AgreementId__c = aptContract1.ID;
        ali3.Apttus__ProductId__c = product2.Id;
        ali3.Apttus_CMConfig__LineNumber__c = 1;
        ali3.Apttus_CMConfig__ItemSequence__c = 1;
        ali3.Apttus_CMConfig__LineType__c = APT_Constants.LINE_TYPE_PRODUCT_SERVICE;
        ali3.Apttus_CMConfig__IsPrimaryLine__c = true;
        aliList.add(ali3);

        Apttus__AgreementLineItem__c ali4 = new Apttus__AgreementLineItem__c();
        ali4.Apttus_CMConfig__DerivedFromId__c = lineItem.ID;
        ali4.Apttus__AgreementId__c = aptContract1.ID;
        ali4.Apttus__ProductId__c = product3.Id;
        ali4.Apttus_CMConfig__LineNumber__c = 1;
        ali4.Apttus_CMConfig__ItemSequence__c = 1;
        ali4.Apttus_CMConfig__LineType__c = APT_Constants.LINE_TYPE_PRODUCT_SERVICE;
        ali4.Apttus_CMConfig__IsPrimaryLine__c = true;
        aliList.add(ali4);

        insert aliList;

        System.debug('Kushal Test1 contract ID '+ aptContract.ID+'aptContract1 '+aptContract1);
        System.debug('Kushal Test '+ attach.ID+'____Parent ID'+attach.parentID);
        System.debug('Kushal Test1 '+ attach1.ID+'____Parent ID1'+attach1.parentID);
        Apttus__Agreement_Term_Exception__c objTE = new Apttus__Agreement_Term_Exception__c();
        objTE.Apttus__Agreement__c = aptContract.ID;
        objTE.Apttus__Approval_Status__c = 'Approved';
        objTE.Apttus__Comments__c = 'Test';
        objTE.Apttus__Exception__c = 'Test';
        //insert objTE;

        //Create Lodgement Point
        APT_Agreement_Lodgement_Point__c  objLp = new APT_Agreement_Lodgement_Point__c();
        objLp.APT_Status__c = 'Active';
        objLp.APT_Agreement__c = aptContract1.id;
        objLp.APT_Address__c = 'australia';
        objLp.APT_eParcel_Enabled__c = 'Yes';
        objLp.APT_Transport_Capability__c = 'VAN Only';
        objLp.APT_Organisation_ID__c = 'ORG123';
        objLp.APT_Lodgement_Point_Lookup__c= aptNw.id;
        objLp.APT_Organisation__c = tempacct.id;
        objLp.APT_Lodgement_Zone_Lookup__c= lodZone.id;
        objLp.APT_DWS_ID__c = 'DwS12';
        objLp.APT_Billing_Account__c = billacc.Id;
        //objLp.APT_Selected_Lodgement_Point__c = objLp.Name;
        objLp.APT_LP_Post_Code__c = 'Pcode';
        objLp.APT_Lodgement_Zone__c = 'LZoone';
        objLp.APT_Product__c = 'Promo Post';
        objLp.APT_Outlet_Type__c = 'OType';
        insert objLp;




        // connect lodgement point to agreement before update

        List<Apttus__APTS_Agreement__c> agreeUpdateList = new List<Apttus__APTS_Agreement__c>();

        aptContract.OwnerId = UserInfo.getUserId();
        // LJ changed for test coverageS
        //aptContract.Apttus__Status__c = 'Fully Signed';
        aptContract.Apttus__Status_Category__c = APT_Constants.STATUS_CATEGORY_IN_EFFECT;
        aptContract.Apttus__Agreement_Category__c = APT_Constants.NETWORK_TYPE_STANDARD;
        aptContract.Term__c = APT_Constants.TERM_OPEN_ENDED;
        agreeUpdateList.add(aptContract);

        aptContract1.APT_Ratecards_Created__c = true;
        aptContract1.Apttus__Status_Category__c = APT_Constants.AGREEMENT_STATUS_CATEGORY_IN_AUTHORING;
        agreeUpdateList.add(aptContract1);

        update agreeUpdateList;

        aptContract.Apttus__Status_Category__c = APT_Constants.AGREEMENT_STATUS_CATEGORY_IN_SIGNATURES;

        aptContract1.Apttus__Status_Category__c = APT_Constants.STATUS_CATEGORY_IN_EFFECT;
        aptContract1.Apttus__Status__c = APT_Constants.AGREEMENT_STATUS_FULLY_SIGNED;
        aptContract1.Apttus__Version_Number__c = 123;

        agreeUpdateList = new List<Apttus__APTS_Agreement__c>();
        agreeUpdateList.add(aptContract);
        agreeUpdateList.add(aptContract1);

        // Removed by Adrian Recio
        // For future test class optimization
        /*
        update agreeUpdateList;
        
        aptContract1.Apttus__Status__c = APT_Constants.LABEL_ACTIVATED;
        update aptContract1;
        */
        APT_AgreementTriggerHandler.getSettlementProfile(null);
        APT_AgreementTriggerHandler.getSettlementProfile(APT_Constants.SETTLEMENT_PROFILE_5);
        APT_AgreementTriggerHandler.getSettlementProfile(APT_Constants.SETTLEMENT_PROFILE_7);
        APT_AgreementTriggerHandler.getSettlementProfile(APT_Constants.SETTLEMENT_PROFILE_14);
        APT_AgreementTriggerHandler.getSettlementProfile(APT_Constants.SETTLEMENT_PROFILE_15);
        APT_AgreementTriggerHandler.getSettlementProfile(APT_Constants.SETTLEMENT_PROFILE_28);
        APT_AgreementTriggerHandler.getSettlementProfile(APT_Constants.SETTLEMENT_PROFILE_30);
        APT_AgreementTriggerHandler.getSettlementProfile(APT_Constants.SETTLEMENT_PROFILE_45);
        APT_AgreementTriggerHandler.getSettlementProfile(APT_Constants.SETTLEMENT_PROFILE_60);
        APT_AgreementTriggerHandler.getSettlementProfile(APT_Constants.SETTLEMENT_PROFILE_90);
        APT_AgreementTriggerHandler.getSettlementProfile(APT_Constants.SETTLEMENT_PROFILE_120);
        APT_AgreementTriggerHandler.getSettlementProfile('22');

        APT_AgreementTriggerHandler.getPricingPlan(null);
        APT_AgreementTriggerHandler.getPricingPlan(APT_Constants.PRICING_PLAN_1_2);
        APT_AgreementTriggerHandler.getPricingPlan(APT_Constants.PRICING_PLAN_1_3);
        APT_AgreementTriggerHandler.getPricingPlan(APT_Constants.PRICING_PLAN_1_4);
        APT_AgreementTriggerHandler.getPricingPlan(APT_Constants.PRICING_PLAN_1_5);
        APT_AgreementTriggerHandler.getPricingPlan(APT_Constants.PRICING_PLAN_1_6);
        APT_AgreementTriggerHandler.getPricingPlan(APT_Constants.PRICING_PLAN_1_7);
        APT_AgreementTriggerHandler.getPricingPlan(APT_Constants.PRICING_PLAN_1_8);
        APT_AgreementTriggerHandler.getPricingPlan(APT_Constants.PRICING_PLAN_1_9);
        APT_AgreementTriggerHandler.getPricingPlan(APT_Constants.PRICING_PLAN_2_0);
        APT_AgreementTriggerHandler.getPricingPlan(APT_Constants.PRICING_PLAN_2_1);
        APT_AgreementTriggerHandler.getPricingPlan(APT_Constants.PRICING_PLAN_2_2);
        APT_AgreementTriggerHandler.getPricingPlan(APT_Constants.PRICING_PLAN_2_3);
        APT_AgreementTriggerHandler.getPricingPlan(APT_Constants.PRICING_PLAN_2_4);
        APT_AgreementTriggerHandler.getPricingPlan(APT_Constants.PRICING_PLAN_3_5);
        APT_AgreementTriggerHandler.getPricingPlan('22');

        //create case for proposal so when DOS is created Approved ABN, Approved entities and payment terms are copied to DOS
        Case ACICCase = new Case();
        ACICCase.Proposal__c = proposal.Id;
        ACICCase.APT_Approved_ABN__c = 'ABN';
        ACICCase.APT_Approved_Entities__c = 'ENTITITIT';
        ACICCase.APT_Payment_Terms__c = '14 days';
        insert ACICCase;

        APT_AgreementTriggerHandler.createOperationalSchedule(agreeList);

        String response = APT_AgreementTriggerHandler.afterAgreementFullySigned(agreementID);
        APT_AgreementTriggerHandler.afterAgreementActivatedForChildAgreements(agreementID);
        Test.stopTest();
    }

    public static testMethod void testingData1(){

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

        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp1 = APT_TestUtils.createOpportunity(tempacct.id);
        Opportunity opp2 = APT_TestUtils.createOpportunity(tempacct.id);
        Opportunity opp3 = APT_TestUtils.createOpportunity(tempacct.id);
        oppList.add(opp1);
        oppList.add(opp2);
        oppList.add(opp3);
        insert oppList;

        List<Product2> productList = new List<Product2>();
        Product2 product =APT_TestUtils.createInternationalProduct('Postal Services','26940998','Postal Services');
        product.name = APT_Constants.BUNDLE_NAME_INTERNATIONAL;
        product.APT_Product_Type__c = 'Workforce Verification';//add product type to product
        productList.add(product);

        Product2 product1 =APT_TestUtils.createInternationalProduct('Postal Services','26940998','Postal Services');
        product1.ProductCode = APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD;
        product1.APT_Product_Type__c = 'Workforce Verification';//add product type to product
        productList.add(product1);

        Product2 product2 =APT_TestUtils.createInternationalProduct('Postal Services','26940998','Postal Services');
        product2.Family = APT_Constants.PARCEL_SERVICES;
        product2.APT_Product_Type__c = 'Workforce Verification';//add product type to product
        productList.add(product2);

        Product2 product3 =APT_TestUtils.createInternationalProduct('Postal Services','26940998','Postal Services');
        product3.APT_Product_Type__c = 'Workforce Verification';//add product type to product
        productList.add(product3);

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
        Apttus_Config2__ProductAttributeValue__c attriObj = new Apttus_Config2__ProductAttributeValue__c(Apttus_Config2__LineItemId__c =lineItem.ID,APT_PostBillPay_Gross_Settlement_fee__c = 'Yes');
        insert attriObj;

        lineItem.Apttus_Config2__AttributeValueId__c = attriObj.ID;
        update lineItem;

        Apttus_Proposal__Proposal_Line_Item__c propLineItem = APT_TestUtils.getProposalLineItem(proposal.Id,lineItem.Id,priceListItem.Id,product.Id,product.Id);
        propLineItem.Apttus_Proposal__Product__c=product.Id;
        propLineItem.Apttus_QPConfig__LineNumber__c =1;
        propLineItem.Apttus_QPConfig__ItemSequence__c=1;
        insert propLineItem;

        /*
        APT_Lodgement_Zone__c LP = APT_TestUtils.getLodgementZone('Sample','1234');
        insert LP;
        */

        /*
        APT_Quote_Lodgement_Point__c quoteLP = new APT_Quote_Lodgement_Point__c(APT_Proposal_Line_Item__c=propLineItem.Id,APT_Quote_Proposal__c=proposal.Id,APT_Lodgement_Zone_Lookup__c=LP.Id);
        insert quoteLP;
        */

        /*
        APT_Line_Item_Rate_Card__c lineRateCard = new APT_Line_Item_Rate_Card__c(APT_Proposal_Line_Item__c=propLineItem.Id,APT_Value_1__c='1',APT_Value_2__c='2',APT_Value_3__c='3');
        insert lineRateCard;
        */

        //Create Proposal
        Application__c appli = new Application__c();
        //appli.Name = 'test';
        appli.Opportunity__c = opp1.Id;
        appli.Account__c = tempacct.Id;
        insert appli;

        User u1 = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name ='System Administrator' and ID != :UserInfo.getUserId()  limit 1];

        List<Apttus__APTS_Agreement__c> agreeList = new List<Apttus__APTS_Agreement__c>();

        Apttus__APTS_Agreement__c aptContractParent = APT_TestUtils.createAgreement(con.Id);
        aptContractParent.APT_Product__c= 'eParcel';
        aptContractParent.Apttus__Related_Opportunity__c=opp3.Id;
        aptContractParent.Apttus__Account__c=tempacct.Id;
        aptContractParent.RecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Post Billpay Contract').getRecordTypeId();
        aptContractParent.Apttus_QPComply__RelatedProposalId__c = proposal.ID;
        aptContractParent.APT_New_Rate_Card_Download__c = true;
        aptContractParent.OwnerId = u1.ID;
        aptContractParent.APMS_Application__c = appli.ID;
        aptContractParent.Apttus__Status_Category__c = 'Request';
        aptContractParent.Apttus__Status__c = 'Request';
        aptContractParent.Included_Product_Lines__c = APT_Constants.PRODUCT_CODE_PRINT_POST;
        aptContractParent.APT_Contract_Type__c = APT_Constants.CONTRACT_TYPE_NEW_CONTRACT;
        aptContractParent.Apttus_QPComply__RelatedProposalId__c = proposal.Id;//should be proposal Id
        aptContractParent.APT_Commercial_Contact__c = con.Id;// should be contact Id
        aptContractParent.APT_Operational_contact__c = con.Id;// should be contact Id    
        aptContractParent.APT_System_User__c = con.Id;// should be contact Id
        aptContractParent.APT_Registered_Business_Name__c = 'test business name';// text area
        aptContractParent.APTContract_Party_Legal_and_Trading_Name__c = 'test';// text area
        aptContractParent.APT_Trading_As__c = 'test';// text area
        aptContractParent.Billing_Account__c = billacc.Id; // billing accont Id
        aptContractParent.Included_Product_Lines__c = 'eParcels Domestic';// multi select picklist
        insert aptContractParent;

        List<Apttus__AgreementLineItem__c> aliList = new List<Apttus__AgreementLineItem__c>();

        Apttus__AgreementLineItem__c ali = new Apttus__AgreementLineItem__c();
        ali.Apttus_CMConfig__DerivedFromId__c = lineItem.ID;
        ali.Apttus__AgreementId__c = aptContractParent.ID;
        ali.Apttus__ProductId__c = product.Id;
        ali.Apttus_CMConfig__LineNumber__c = 1;
        ali.Apttus_CMConfig__ItemSequence__c = 1;
        ali.Apttus_CMConfig__LineType__c = APT_Constants.LINE_TYPE_PRODUCT_SERVICE;
        ali.Apttus_CMConfig__IsPrimaryLine__c = true;
        aliList.add(ali);

        Apttus__AgreementLineItem__c ali2 = new Apttus__AgreementLineItem__c();
        ali2.Apttus_CMConfig__DerivedFromId__c = lineItem.ID;
        ali2.Apttus__AgreementId__c = aptContractParent.ID;
        ali2.Apttus__ProductId__c = product1.Id;
        ali2.Apttus_CMConfig__LineNumber__c = 1;
        ali2.Apttus_CMConfig__ItemSequence__c = 1;
        ali2.Apttus_CMConfig__LineType__c = APT_Constants.LINE_TYPE_PRODUCT_SERVICE;
        ali2.Apttus_CMConfig__IsPrimaryLine__c = true;
        aliList.add(ali2);

        Apttus__AgreementLineItem__c ali3 = new Apttus__AgreementLineItem__c();
        ali3.Apttus_CMConfig__DerivedFromId__c = lineItem.ID;
        ali3.Apttus__AgreementId__c = aptContractParent.ID;
        ali3.Apttus__ProductId__c = product2.Id;
        ali3.Apttus_CMConfig__LineNumber__c = 1;
        ali3.Apttus_CMConfig__ItemSequence__c = 1;
        ali3.Apttus_CMConfig__LineType__c = APT_Constants.LINE_TYPE_PRODUCT_SERVICE;
        ali3.Apttus_CMConfig__IsPrimaryLine__c = true;
        aliList.add(ali3);

        Apttus__AgreementLineItem__c ali4 = new Apttus__AgreementLineItem__c();
        ali4.Apttus_CMConfig__DerivedFromId__c = lineItem.ID;
        ali4.Apttus__AgreementId__c = aptContractParent.ID;
        ali4.Apttus__ProductId__c = product3.Id;
        ali4.Apttus_CMConfig__LineNumber__c = 1;
        ali4.Apttus_CMConfig__ItemSequence__c = 1;
        ali4.Apttus_CMConfig__LineType__c = APT_Constants.LINE_TYPE_PRODUCT_SERVICE;
        ali4.Apttus_CMConfig__IsPrimaryLine__c = true;
        aliList.add(ali4);

        insert aliList;

        Apttus__APTS_Agreement__c aptContract2 = APT_TestUtils.createAgreement(con.Id);
        aptContract2.APT_Product__c= 'eParcel';
        aptContract2.Apttus__Related_Opportunity__c=opp3.Id;
        aptContract2.Apttus__Account__c=tempacct.Id;
        aptContract2.RecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Post Billpay Contract').getRecordTypeId();
        aptContract2.Apttus_QPComply__RelatedProposalId__c = proposal.ID;
        aptContract2.APT_New_Rate_Card_Download__c = true;
        aptContract2.OwnerId = u1.ID;
        aptContract2.APMS_Application__c = appli.ID;
        aptContract2.Apttus__Status_Category__c = 'Request';
        aptContract2.Apttus__Status__c = 'Request';
        aptContract2.Included_Product_Lines__c = null; //APT_Constants.PRODUCT_CODE_PRINT_POST;
        aptContract2.Apttus__Parent_Agreement__c = aptContractParent.ID;
        aptContract2.APT_Contract_Type__c = APT_Constants.CONTRACT_TYPE_NEW_CONTRACT;
        agreeList.add(aptContract2);

        Apttus__APTS_Agreement__c aptContract3 = APT_TestUtils.createAgreement(con.Id);
        aptContract3.APT_Product__c= 'Local Pickup and Delivery Services';
        //aptContract3.Apttus__Related_Opportunity__c=opp3.Id;
        aptContract3.Apttus__Account__c=tempacct.Id;
        aptContract3.RecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
        aptContract3.Apttus_QPComply__RelatedProposalId__c = proposal.ID;
        aptContract3.APT_New_Rate_Card_Download__c = true;
        aptContract3.OwnerId = u1.ID;
        aptContract3.APMS_Application__c = appli.ID;
        aptContract3.Apttus__Status_Category__c = 'Request';
        aptContract3.Apttus__Status__c = 'Request';
        aptContract3.Included_Product_Lines__c = null;
        aptContract3.Apttus__Parent_Agreement__c = aptContractParent.ID;
        aptContract3.APT_Contract_Type__c = APT_Constants.CONTRACT_TYPE_NEW_CONTRACT;
        agreeList.add(aptContract3);

        Test.startTest();

        insert agreeList;

        aptContract2.Included_Product_Lines__c = APT_Constants.PRODUCT_CODE_PRINT_POST;
        update aptContract2;

        aptContract2.Apttus__Status__c = 'Fully Signed';
        aptContract3.Included_Product_Lines__c = 'Local Pickup and Delivery Services';
        update aptContract3;

        Test.stopTest();
    }
     /*Shashwat.Nath@auspost.com.au has created the below test method to test functionality for superseding the original Opportunrity
      when user does the DOV and and the new contract is in stage of In Signature and Fully Signed */
      public static testMethod void testOpportunitySuperseding(){
        Profile p = [SELECT Id FROM Profile WHERE Name='Sales Admin'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser ){ 
            
            // Creating test dada as a test user
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
            
            
            // Creating the Contact Test Data
            Contact con = APT_TestUtils.createContact();
            con.MailingCity = 'Melbourne';
            con.MailingState = 'VIC';
            con.MailingStreet = 'Flinders Street';
            con.MailingPostalCode = '3000'; 
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
            
            List<Opportunity> oppList = new List<Opportunity>();
            Opportunity opp1 = APT_TestUtils.createOpportunity(tempacct.id);
            Opportunity opp2 = APT_TestUtils.createOpportunity(tempacct.id);
            Opportunity opp3 = APT_TestUtils.createOpportunity(tempacct.id);
            oppList.add(opp1);
            oppList.add(opp2);
            oppList.add(opp3);
            insert oppList;
            
            opp2.ECLM_Original_Opportunity_No__c = opp1.id ;
            opp2.Opportunity_SubType__c = 'DoV Increase';
            
            update opp2;
            
            List<Product2> productList = new List<Product2>();
            Product2 product =APT_TestUtils.createInternationalProduct('Postal Services','26940998','Postal Services');
            product.name = APT_Constants.BUNDLE_NAME_INTERNATIONAL;
            product.APT_Product_Type__c = 'Workforce Verification';//add product type to product
            productList.add(product);
            
            Product2 product1 =APT_TestUtils.createInternationalProduct('Postal Services','26940998','Postal Services');
            product1.ProductCode = APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD;
            product1.APT_Product_Type__c = 'Workforce Verification';//add product type to product
            productList.add(product1);
            
            Product2 product2 =APT_TestUtils.createInternationalProduct('Postal Services','26940998','Postal Services');
            product2.Family = APT_Constants.PARCEL_SERVICES;
            product2.APT_Product_Type__c = 'Workforce Verification';//add product type to product
            productList.add(product2);
            
            Product2 product3 =APT_TestUtils.createInternationalProduct('Postal Services','26940998','Postal Services');
            product3.APT_Product_Type__c = 'Workforce Verification';//add product type to product
            productList.add(product3);
            
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
            Apttus_Config2__ProductAttributeValue__c attriObj = new Apttus_Config2__ProductAttributeValue__c(Apttus_Config2__LineItemId__c =lineItem.ID,APT_PostBillPay_Gross_Settlement_fee__c = 'Yes');
            insert attriObj;
            
            lineItem.Apttus_Config2__AttributeValueId__c = attriObj.ID;
            update lineItem;
            
            Apttus_Proposal__Proposal_Line_Item__c propLineItem = APT_TestUtils.getProposalLineItem(proposal.Id,lineItem.Id,priceListItem.Id,product.Id,product.Id);
            propLineItem.Apttus_Proposal__Product__c=product.Id;
            propLineItem.Apttus_QPConfig__LineNumber__c =1;
            propLineItem.Apttus_QPConfig__ItemSequence__c=1;
            insert propLineItem;
            
           
            //Create Proposal
            Application__c appli = new Application__c();
            //appli.Name = 'test';
            appli.Opportunity__c = opp1.Id;
            appli.Account__c = tempacct.Id;
            insert appli;
            
            User u1 = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name ='System Administrator' and ID != :UserInfo.getUserId()  limit 1];
            
            List<Apttus__APTS_Agreement__c> agreeList = new List<Apttus__APTS_Agreement__c>();
            
            Apttus__APTS_Agreement__c aptContractParent = APT_TestUtils.createAgreement(con.Id);
            aptContractParent.APT_Product__c= 'eParcel';
            aptContractParent.Apttus__Related_Opportunity__c=opp2.Id;
            aptContractParent.Apttus__Account__c=tempacct.Id;
            aptContractParent.RecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Post Billpay Contract').getRecordTypeId();
            aptContractParent.Apttus_QPComply__RelatedProposalId__c = proposal.ID;
            aptContractParent.APT_New_Rate_Card_Download__c = true;
            aptContractParent.OwnerId = u1.ID;
            aptContractParent.APMS_Application__c = appli.ID;
            aptContractParent.Apttus__Status_Category__c = 'Request';
            aptContractParent.Apttus__Status__c = 'Request';
            aptContractParent.Included_Product_Lines__c = APT_Constants.PRODUCT_CODE_PRINT_POST;
            aptContractParent.APT_Contract_Type__c = APT_Constants.CONTRACT_TYPE_NEW_CONTRACT;
            aptContractParent.Apttus_QPComply__RelatedProposalId__c = proposal.Id;//should be proposal Id
            aptContractParent.APT_Commercial_Contact__c = con.Id;// should be contact Id
            aptContractParent.APT_Operational_contact__c = con.Id;// should be contact Id    
            aptContractParent.APT_System_User__c = con.Id;// should be contact Id
            aptContractParent.APT_Registered_Business_Name__c = 'test business name';// text area
            aptContractParent.APTContract_Party_Legal_and_Trading_Name__c = 'test';// text area
            aptContractParent.APT_Trading_As__c = 'test';// text area
            aptContractParent.Billing_Account__c = billacc.Id; // billing accont Id
            aptContractParent.Included_Product_Lines__c = 'eParcels Domestic';// multi select picklist
            insert aptContractParent;
            
            attachment atch = APT_TestUtils.createAttachment(aptContractParent.id);
            atch.body = blob.ValueOf('Test');
            insert atch;
            
            // Test Starts
            Test.startTest();
                // Update the new Contract to In Signature and Fully Signed 
                aptContractParent.Apttus__Status_Category__c = 'In Signatures';
                aptContractParent.Apttus__Status__c = 'Fully Signed';
                
                update aptContractParent;
            // Test Stop    
            Test.stopTest();
            
            // Query the orignal Opportunity record associated to the current opportunity
            Opportunity opp = [Select id,Is_Superseded_Opportunity__c from Opportunity Where id=:opp1.id];
            
            // Assert whether the original Opportunity gets Superseded
            System.AssertEquals(opp.Is_Superseded_Opportunity__c ,true);
        }
    }


}