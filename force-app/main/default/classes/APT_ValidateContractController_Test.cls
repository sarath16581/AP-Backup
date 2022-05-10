@istest
Public class APT_ValidateContractController_Test
{
    
    @testSetup static void setup() {
        
        //Create Contact
        Contact con= APT_TestUtils.createContact();
        con.MailingCity = 'Melbourne';
        con.MailingState = 'VIC';
        con.MailingStreet = 'Flinders Street';
        con.MailingPostalCode = '3000'; 
        insert con;
        
        //Create Account
        List<Account> accList = new List<Account>();
        
        Account legacyacct = APT_TestUtils.createOrganisation();
        legacyacct.Legacy_Id__c = '60000000';
        legacyacct.Name = 'legacyacct';
        accList.add(legacyacct);
        
        Account tempacct = APT_TestUtils.createOrganisation();
        tempacct.Legacy_Id__c = '60000000';
        tempacct.Name = 'tempacct';
        accList.add(tempacct);
        insert accList;
        
        legacyacct.Legacy_Id__c = '60000000';
        update legacyacct;
        
        //Create Billing Account
        List<Billing_Account__c> billAccountList = new List<Billing_Account__c>();
        Billing_Account__c billacc = APT_TestUtils.createBillingAccount(legacyacct.id);
        billacc.LEGACY_ID__c = '60000000';
        billAccountList.add(billacc);
        Billing_Account__c billacc2 = APT_TestUtils.createBillingAccount(tempacct.id);
        billacc2.LEGACY_ID__c = '60000000';
        billAccountList.add(billacc2);
        insert billAccountList;
        
        //Create Opportunity
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp1 = APT_TestUtils.createOpportunity(legacyacct.id);
        Opportunity opp2 = APT_TestUtils.createOpportunity(tempacct.id);
        
        opp1.Is_Superseded_Opportunity__c = true;
        opp2.Is_Superseded_Opportunity__c = true;
        oppList.add(opp1);
        oppList.add(opp2);       
        insert oppList;   
        
        //CREATE PRODUCTS
        List<Product2> productList = new List<Product2>();    
        
        //Create APPC Product
        Product2 product = APT_TestUtils.createAPPCProduct('Australia Post Parcel Contract','X01','APPC');
        product.APT_Product_Type__c = 'Parcel Contract';
        product.APT_Product_Lines__c = 'Parcel Contract';
        product.APT_Contracting_Entity__c = 'Australian Postal Corporation';
        productList.add(product);
        
        Product2 product1 =APT_TestUtils.createInternationalProduct('eParcel','26940998','Product Innovation');
        product1.ProductCode = APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD;
        product1.APT_Product_Type__c = 'eParcels Domestic';//add product type to product
        product1.APT_Apttus_Product_Classification__c = 'Parcel Services';
        productList.add(product1);
        
        Product2 product2 = APT_TestUtils.createAPPCProduct(APT_Constants.OPERATIONAL_SCHEDULE_EXPRESS_ROAD_PRODUCT,'X01','APPC');
        product2.APT_Product_Type__c = 'StarTrack';
        product2.APT_Product_Lines__c = 'StarTrack';
        product2.APT_Contracting_Entity__c = 'StarTrack Express Pty Ltd';
        productList.add(product2);
        
        Product2 product3 = APT_TestUtils.createAPPCProduct(APT_Constants.OPERATIONAL_SCHEDULE_SECURITY_SERVICES_PRODUCT,'X01','APPC');
        product3.APT_Product_Type__c = 'StarTrack';
        product3.APT_Product_Lines__c = 'StarTrack';
        product3.APT_Contracting_Entity__c = 'StarTrack Express Pty Ltd';
        productList.add(product3);
        
        Product2 product4 = APT_TestUtils.createAPPCProduct(APT_Constants.OPERATIONAL_SCHEDULE_NEXT_FLIGHT_PRODUCT,'X01','APPC');
        product4.APT_Product_Type__c = 'StarTrack';
        product4.APT_Product_Lines__c = 'StarTrack';
        product4.APT_Contracting_Entity__c = 'StarTrack Express Pty Ltd';
        productList.add(product4);
        
        Product2 product5 =APT_TestUtils.createInternationalProduct('Postal Services','26940998','Postal Services');
        product5.name = APT_Constants.BUNDLE_NAME_INTERNATIONAL;
        product5.APT_Product_Type__c = 'Workforce Verification';//add product type to product
        productList.add(product5);
        
        Product2 product6 =APT_TestUtils.createInternationalProduct('Postal Services','26940998','Postal Services');
        product6.ProductCode = APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD;
        product6.APT_Product_Type__c = 'Workforce Verification';//add product type to product
        productList.add(product6);
        
        Product2 product7 =APT_TestUtils.createInternationalProduct('Postal Services','26940998','Postal Services');
        product7.Family = APT_Constants.PARCEL_SERVICES;
        product7.APT_Product_Type__c = 'Workforce Verification';//add product type to product
        productList.add(product7);
        
        Product2 product8 =APT_TestUtils.createInternationalProduct('Postal Services','26940998','Postal Services');
        product8.APT_Product_Type__c = 'Workforce Verification';//add product type to product
        productList.add(product8);
        
        Product2 product9 =APT_TestUtils.createInternationalProduct('International Bundle','26940998','Postal Services');
        product9.APT_Product_Type__c = 'Workforce Verification';//add product type to product
        productList.add(product9);
        
        insert productList;
        
        //CREATE Price List
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;
        
        //CREATE Price List Item
        List<Apttus_Config2__PriceListItem__c> priceListItemList = new List<Apttus_Config2__PriceListItem__c>();  
        Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id, product.id, '', '');
        priceListItemList.add(priceListItem);
        Apttus_Config2__PriceListItem__c priceListItem2 = APT_TestUtils.createPriceListItem(priceList.id, product1.id, '', '');
        priceListItemList.add(priceListItem2);
        Apttus_Config2__PriceListItem__c priceListItem3 = APT_TestUtils.createPriceListItem(priceList.id, product2.id, '', '');
        priceListItemList.add(priceListItem3);
        Apttus_Config2__PriceListItem__c priceListItem4 = APT_TestUtils.createPriceListItem(priceList.id, product3.id, '', '');
        priceListItemList.add(priceListItem4);
        Apttus_Config2__PriceListItem__c priceListItem5 = APT_TestUtils.createPriceListItem(priceList.id, product4.id, '', '');
        priceListItemList.add(priceListItem5);
        
        Apttus_Config2__PriceListItem__c priceListItem6 = APT_TestUtils.createPriceListItem(priceList.id,product5.id,'','');
        priceListItemList.add(priceListItem6);
        
        insert priceListItemList;
        
        APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(priceList.Id);
        r2tSystemProperties.APT_Org_Id_Service_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
        r2tSystemProperties.APT_CompanyCreditAssessmentEndPointURL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
        r2tSystemProperties.APT_INDV_Credit_Assessment_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
        r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c = 'test@apttus.com1';
        //RecordType rt12 = [SELECT Id,Name FROM RecordType WHERE SobjectType= 'APT_Contract_Fee__c' and DeveloperName = 'Transaction_Fees'];
        r2tSystemProperties.Transaction_Fee_Reord_Type_ID__c = '01290000001UPguAAG';  //Schema.SObjectType.APT_Contract_Fee__c.getRecordTypeInfosByName().get('Transaction Fees').getRecordTypeId();
        r2tSystemProperties.Name = 'System Properties';
        r2tSystemProperties.APT_ReversalFees__c = Schema.SObjectType.APT_Contract_Fee__c.getRecordTypeInfosByName().get('Card Dishonour and Reversal Fees').getRecordTypeId();
        r2tSystemProperties.APT_Change_Management__c = Schema.SObjectType.APT_Contract_Fee__c.getRecordTypeInfosByName().get('Change Management').getRecordTypeId();
        insert r2tSystemProperties;
        
        
        //CREATE Proposal
        List<Apttus_Proposal__Proposal__c> proposalList = new List<Apttus_Proposal__Proposal__c>();
        Apttus_Proposal__Proposal__c proposal = APT_TestUtils.getQuoteProposal(legacyacct.id,opp1.Id,'Proposal','Test',priceList.id);
        proposal.Apttus_Proposal__Approval_Stage__c = 'Accepted';
        proposalList.add(proposal);
        Apttus_Proposal__Proposal__c proposal2 = APT_TestUtils.getQuoteProposal(tempacct.id,opp2.Id,'Proposal','Test',priceList.id);
        proposal2.Apttus_Proposal__Approval_Stage__c = 'Accepted';
        proposal2.Apttus_QPApprov__Approval_Status__c = APT_Constants.APPROVAL_STAGE_APPROVED;
        proposalList.add(proposal2);
        insert proposalList;
        
        //CREATE Case
        Case proposalCase = new Case(Proposal__c = proposal.Id, APT_Approved_ABN__c = '123456789', APT_Approved_Entities__c = 'AusPost', APT_Payment_Terms__c = '14 days');
        insert proposalCase;
        
        //CREATE Product Configuration
        List<Apttus_Config2__ProductConfiguration__c> configList = new List<Apttus_Config2__ProductConfiguration__c>();
        Apttus_Config2__ProductConfiguration__c config =new  Apttus_Config2__ProductConfiguration__c(Name='Sample',Apttus_QPConfig__Proposald__c=proposal.id,Apttus_Config2__PriceListId__c=priceList.id,Apttus_Config2__Status__c = APT_Constants.CONFIGURATION_STATUS_FINALIZED);
        configList.add(config);
        Apttus_Config2__ProductConfiguration__c config2 =new  Apttus_Config2__ProductConfiguration__c(Name='Sample',Apttus_QPConfig__Proposald__c=proposal2.id,Apttus_Config2__PriceListId__c=priceList.id,Apttus_Config2__Status__c = APT_Constants.CONFIGURATION_STATUS_FINALIZED);
        configList.add(config2);
        insert configList;
        
        //CREATE SummaryGroup
        List<Apttus_Config2__SummaryGroup__c> summaryGroupList = new List<Apttus_Config2__SummaryGroup__c>();
        Apttus_Config2__SummaryGroup__c summaryGroup = new Apttus_Config2__SummaryGroup__c (Apttus_Config2__ConfigurationId__c=config.id, Apttus_Config2__ItemSequence__c=78, Apttus_Config2__LineNumber__c=45);
        summaryGroupList.add(summaryGroup);
        Apttus_Config2__SummaryGroup__c summaryGroup2 = new Apttus_Config2__SummaryGroup__c (Apttus_Config2__ConfigurationId__c=config2.id, Apttus_Config2__ItemSequence__c=78, Apttus_Config2__LineNumber__c=45);
        summaryGroupList.add(summaryGroup2);
        insert summaryGroupList;
        
        //CREATE ProductOptionComponent
        Apttus_Config2__ProductOptionComponent__c prodOptionComponent = new Apttus_Config2__ProductOptionComponent__c(Apttus_Config2__Sequence__c=2);
        insert prodOptionComponent;
        
        //CREATE Category
        Apttus_Config2__ClassificationName__c category = new Apttus_Config2__ClassificationName__c(Name='Test',Apttus_Config2__Active__c=true,
                                                                                                   Apttus_Config2__HierarchyLabel__c='High',Apttus_Config2__Type__c='Offering',Apttus_Config2__GuidePage__c='Sample');
        insert category;
        
        //CREATE Category Hierarchy
        Apttus_Config2__ClassificationHierarchy__c classHierarchy = new Apttus_Config2__ClassificationHierarchy__c(Apttus_Config2__HierarchyId__c=category.id, Apttus_Config2__Label__c='Sample');
        insert classHierarchy;
        
        //CREATE Line Item
        List<Apttus_Config2__LineItem__c> lineItemList = new List<Apttus_Config2__LineItem__c>();
        Apttus_Config2__LineItem__c lineItem = APT_TestUtils.getConfigLineItem(config.id,summaryGroup.id , 1, true, 2, '', product.id, false,prodOptionComponent.id,
                                                                               product.id,classHierarchy.id,'',2.3,false,'',2,priceList.id,priceListItem.Id,'','','','',
                                                                               false,false,22.00,24.00,'',34.00,23.00,33.50,'');
        
        lineItemList.add(lineItem);
        
        Apttus_Config2__LineItem__c lineItem2 = APT_TestUtils.getConfigLineItem(config2.id,summaryGroup2.id , 1, true, 2, '', product1.id, false,prodOptionComponent.id,
                                                                                product1.id,classHierarchy.id,'',2.3,false,'',2,priceList.id,priceListItem2.Id,'','','','',
                                                                                false,false,22.00,24.00,'',34.00,23.00,33.50,'');
        
        lineItemList.add(lineItem2);
        
        Apttus_Config2__LineItem__c lineItem3 = APT_TestUtils.getConfigLineItem(config.id,summaryGroup.id , 1, true, 2, '', product2.id, false,prodOptionComponent.id,
                                                                                product2.id,classHierarchy.id,'',2.3,false,'',2,priceList.id,priceListItem3.Id,'','','','',
                                                                                false,false,22.00,24.00,'',34.00,23.00,33.50,'');
        
        lineItemList.add(lineItem3);
        
        Apttus_Config2__LineItem__c lineItem4 = APT_TestUtils.getConfigLineItem(config.id,summaryGroup.id , 1, true, 2, '', product3.id, false,prodOptionComponent.id,
                                                                                product3.id,classHierarchy.id,'',2.3,false,'',2,priceList.id,priceListItem4.Id,'','','','',
                                                                                false,false,22.00,24.00,'',34.00,23.00,33.50,'');
        
        lineItemList.add(lineItem4);
        
        Apttus_Config2__LineItem__c lineItem5 = APT_TestUtils.getConfigLineItem(config.id,summaryGroup.id , 1, true, 2, '', product4.id, false,prodOptionComponent.id,
                                                                                product4.id,classHierarchy.id,'',2.3,false,'',2,priceList.id,priceListItem5.Id,'','','','',
                                                                                false,false,22.00,24.00,'',34.00,23.00,33.50,'');
        
        lineItemList.add(lineItem5);
        
        insert lineItemList;
        
        //CREATE Lodgement Zone
        APT_Lodgement_Zone__c LZ = APT_TestUtils.getLodgementZone('Capital','1234');
        LZ.APT_Post_Code_End__c = 3000;
        LZ.APT_Post_Code_Start__c = 2158;
        insert LZ;
        
        //CREATE Product Attribute Value
        List<Apttus_Config2__ProductAttributeValue__c> attributeValueList = new List<Apttus_Config2__ProductAttributeValue__c>();
        Apttus_Config2__ProductAttributeValue__c attriObj = new Apttus_Config2__ProductAttributeValue__c(Apttus_Config2__LineItemId__c =lineItem.ID,APT_PostBillPay_Gross_Settlement_fee__c = 'Yes', APT_StarTrack_Service_Type__c = 'FPP',   APT_Lodgement_Zone__c = LZ.Id, APTS_Price_Structure__c = 'Z6');
        attributeValueList.add(attriObj);
        Apttus_Config2__ProductAttributeValue__c attriObj2 = new Apttus_Config2__ProductAttributeValue__c(Apttus_Config2__LineItemId__c =lineItem2.ID,APT_PostBillPay_Gross_Settlement_fee__c = 'Yes', APT_StarTrack_Service_Type__c = 'FPP',   APT_Lodgement_Zone__c = LZ.Id, APTS_Price_Structure__c = 'Z6');
        attributeValueList.add(attriObj2);
        Apttus_Config2__ProductAttributeValue__c attriObj3 = new Apttus_Config2__ProductAttributeValue__c(Apttus_Config2__LineItemId__c =lineItem3.ID,APT_PostBillPay_Gross_Settlement_fee__c = 'Yes', APT_StarTrack_Service_Type__c = 'PRM',   APT_Lodgement_Zone__c = LZ.Id, APTS_Price_Structure__c = 'Z6');
        attributeValueList.add(attriObj3);
        Apttus_Config2__ProductAttributeValue__c attriObj4 = new Apttus_Config2__ProductAttributeValue__c(Apttus_Config2__LineItemId__c =lineItem4.ID,APT_PostBillPay_Gross_Settlement_fee__c = 'Yes', APT_StarTrack_Service_Type__c = 'PRM',   APT_Lodgement_Zone__c = LZ.Id, APTS_Price_Structure__c = 'Z6');
        attributeValueList.add(attriObj4);
        Apttus_Config2__ProductAttributeValue__c attriObj5 = new Apttus_Config2__ProductAttributeValue__c(Apttus_Config2__LineItemId__c =lineItem5.ID,APT_PostBillPay_Gross_Settlement_fee__c = 'Yes', APT_StarTrack_Service_Type__c = 'PRM',   APT_Lodgement_Zone__c = LZ.Id, APTS_Price_Structure__c = 'Z6');
        attributeValueList.add(attriObj5);
        insert attributeValueList;
        
        //CREATE Proposal Line Item
        List<Apttus_Proposal__Proposal_Line_Item__c> pliList = new List<Apttus_Proposal__Proposal_Line_Item__c>();
        Apttus_Proposal__Proposal_Line_Item__c propLineItem = APT_TestUtils.getProposalLineItem(proposal.Id,lineItem.Id,priceListItem.Id,product.Id,product.Id);
        //propLineItem.Apttus_Proposal__Product__c=product.Id;
        propLineItem.Apttus_QPConfig__LineNumber__c =1;
        propLineItem.Apttus_QPConfig__ItemSequence__c=1;
        propLineItem.Apttus_QPConfig__IsPrimaryLine__c=true;
        propLineItem.Apttus_QPConfig__LineType__c = 'Product/Service';
        pliList.add(propLineItem);
        Apttus_Proposal__Proposal_Line_Item__c propLineItem3 = APT_TestUtils.getProposalLineItem(proposal.Id,lineItem3.Id,priceListItem3.Id,product2.Id,product2.Id);
        propLineItem3.Apttus_QPConfig__LineNumber__c =2;
        propLineItem3.Apttus_QPConfig__ItemSequence__c=2;
        propLineItem3.Apttus_QPConfig__IsPrimaryLine__c=true;
        propLineItem3.Apttus_QPConfig__LineType__c = 'Product/Service';
        pliList.add(propLineItem3);
        Apttus_Proposal__Proposal_Line_Item__c propLineItem4 = APT_TestUtils.getProposalLineItem(proposal.Id,lineItem4.Id,priceListItem4.Id,product3.Id,product3.Id);
        propLineItem4.Apttus_QPConfig__LineNumber__c =3;
        propLineItem4.Apttus_QPConfig__ItemSequence__c=3;
        propLineItem4.Apttus_QPConfig__IsPrimaryLine__c=true;
        propLineItem4.Apttus_QPConfig__LineType__c = 'Product/Service';
        pliList.add(propLineItem4);
        Apttus_Proposal__Proposal_Line_Item__c propLineItem5 = APT_TestUtils.getProposalLineItem(proposal.Id,lineItem5.Id,priceListItem5.Id,product4.Id,product4.Id);
        propLineItem5.Apttus_QPConfig__LineNumber__c =3;
        propLineItem5.Apttus_QPConfig__ItemSequence__c=3;
        propLineItem5.Apttus_QPConfig__IsPrimaryLine__c=true;
        propLineItem5.Apttus_QPConfig__LineType__c = 'Product/Service';
        pliList.add(propLineItem5);
        Apttus_Proposal__Proposal_Line_Item__c propLineItem2 = APT_TestUtils.getProposalLineItem(proposal2.Id,lineItem2.Id,priceListItem2.Id,product1.Id,product1.Id);
        propLineItem2.Apttus_QPConfig__LineNumber__c =1;
        propLineItem2.Apttus_QPConfig__ItemSequence__c=1;
        propLineItem.Apttus_QPConfig__IsPrimaryLine__c=true;
        propLineItem.Apttus_QPConfig__LineType__c = 'Product/Service';
        pliList.add(propLineItem2);
        insert pliList;
        
        //Create Proposal
        List<Application__c> appLiList = new List<Application__c>();
        Application__c appli = new Application__c();
        appli.Opportunity__c = opp1.Id;
        appli.Account__c = legacyacct.Id;
        appLiList.add(appli);
        Application__c appli2 = new Application__c();
        appli2.Opportunity__c = opp2.Id;
        appli2.Account__c = tempacct.Id;
        appLiList.add(appli2);
        insert appLiList;

    }
    
    public static testMethod void testingContractController(){
        test.starttest();
        Contact con = [Select Id from Contact Limit 1];
        Account legacyacct = [Select Id from Account where Name = 'legacyacct' Limit 1];
        
        Opportunity opp1 = [Select Id, AccountId from Opportunity where AccountId = :legacyacct.Id Limit 1];
        Application__c app = new Application__c();
        app.Opportunity__c = opp1.Id;
        
        Billing_Account__c billacc = [Select Id, Organisation__c from Billing_Account__c where Organisation__c =:legacyacct.Id Limit 1];
        Product2 product = [Select Id from Product2 where Name = 'Australia Post Parcel Contract' Limit 1];
        Product2 product2 = [Select Id from Product2 where Name = 'International Bundle' Limit 1];
        // Product2 product3 = [Select Id from Product2 where Family = 'Parcel Services' Limit 1];
        
        Apttus_Config2__LineItem__c lineItem = [Select Id from Apttus_Config2__LineItem__c where Apttus_Config2__ProductId__c =:product.Id Limit 1];
        // Apttus_Config2__LineItem__c lineItem2 = [Select Id from Apttus_Config2__LineItem__c where Apttus_Config2__ProductId__c =:product2.Id Limit 1];
        // Apttus_Config2__LineItem__c lineItem3 = [Select Id from Apttus_Config2__LineItem__c where Apttus_Config2__ProductId__c =:product3.Id Limit 1];
        User u1 = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name ='System Administrator' and ID != :UserInfo.getUserId()  limit 1];
        Apttus_Proposal__Proposal__c proposal = [Select Id from Apttus_Proposal__Proposal__c where Apttus_Proposal__Account__c =:legacyacct.Id Limit 1];
        proposal.Apttus_QPApprov__Approval_Status__c = APT_Constants.APPROVAL_STAGE_APPROVED;
        List<Apttus__AgreementLineItem__c> agreementLineItemList = new List<Apttus__AgreementLineItem__c>();
        
        //CREATE Contract for APPC
        Apttus__APTS_Agreement__c aptContractParent = APT_TestUtils.createAgreement(con.Id);
        aptContractParent.APT_Product__c= 'Australia Post Parcel Contract';
        aptContractParent.Apttus__Related_Opportunity__c = opp1.Id;
        aptContractParent.Apttus__Account__c= legacyacct.Id;
        //aptContractParent.RecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
        aptContractParent.RecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('SecurePay Online Payments').getRecordTypeId();
        //aptContractParent.RecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
        aptContractParent.Apttus_QPComply__RelatedProposalId__c = proposal.Id;
        aptContractParent.APT_New_Rate_Card_Download__c = true;
        aptContractParent.OwnerId = u1.ID;
        //aptContractParent.APMS_Application__c = appli.ID;
        aptContractParent.Apttus__Status_Category__c = 'Request';
        aptContractParent.Apttus__Status__c = 'Request';
        aptContractParent.Included_Product_Lines__c = APT_Constants.PRODUCT_TYPE_PARCEL_CONTRACT;
        aptContractParent.APT_Contract_Type__c = APT_Constants.CONTRACT_TYPE_NEW_CONTRACT;
        aptContractParent.APT_Commercial_Contact__c = con.Id;// should be contact Id
        aptContractParent.APT_Operational_contact__c = con.Id;// should be contact Id    
        aptContractParent.APT_System_User__c = con.Id;// should be contact Id
        aptContractParent.APT_Registered_Business_Name__c = 'test business name';// text area
        aptContractParent.APTContract_Party_Legal_and_Trading_Name__c = 'test';// text area
        aptContractParent.APT_Trading_As__c = 'test';// text area
        aptContractParent.Billing_Account__c = billacc.Id; // billing accont Id
        insert aptcontractparent;
        
        
        ApexPages.currentPage().getParameters().put(APT_Constants.PARAM_ID,aptcontractparent.id);
        ApexPages.currentPage().getParameters().put('Count','1');
        APT_ValidateContractController obj = new APT_ValidateContractController();
        APT_AgreementObjectsSelector mockSelector = (APT_AgreementObjectsSelector) MockUtility.mockSelector(APT_AgreementObjectsSelector.class);
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSelector.selectByConfigId((Set<Id>)fflib_Match.eq(new Set<Id>{aptcontractparent.Id}))).thenReturn(
            new List<Apttus__APTS_Agreement__c>(new List<Apttus__APTS_Agreement__c>{aptcontractparent}));
        MockUtility.Mocks.stopStubbing();
        obj.getCheckAndRedirect();
        System.assertEquals(null,aptContractParent.Contract_Expiration_Date__c);
        test.stoptest();
    }
    
    
    public static testMethod void testingContractController1(){
        test.starttest();
        Contact con = [Select Id from Contact Limit 1];
        Account legacyacct = [Select Id from Account where Name = 'legacyacct' Limit 1];
        
        Opportunity opp1 = [Select Id, AccountId from Opportunity where AccountId = :legacyacct.Id Limit 1];
        Application__c app = new Application__c();
        app.Opportunity__c = opp1.Id;
        
        Billing_Account__c billacc = [Select Id, Organisation__c from Billing_Account__c where Organisation__c =:legacyacct.Id Limit 1];
        Product2 product = [Select Id from Product2 where Name = 'Australia Post Parcel Contract' Limit 1];
        Product2 product2 = [Select Id from Product2 where Name = 'International Bundle' Limit 1];
        // Product2 product3 = [Select Id from Product2 where Family = 'Parcel Services' Limit 1];
        
        Apttus_Config2__LineItem__c lineItem = [Select Id from Apttus_Config2__LineItem__c where Apttus_Config2__ProductId__c =:product.Id Limit 1];
        // Apttus_Config2__LineItem__c lineItem2 = [Select Id from Apttus_Config2__LineItem__c where Apttus_Config2__ProductId__c =:product2.Id Limit 1];
        // Apttus_Config2__LineItem__c lineItem3 = [Select Id from Apttus_Config2__LineItem__c where Apttus_Config2__ProductId__c =:product3.Id Limit 1];
        User u1 = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name ='System Administrator' and ID != :UserInfo.getUserId()  limit 1];
        Apttus_Proposal__Proposal__c proposal = [Select Id,Apttus_Proposal__Proposal_Expiration_Date__c from Apttus_Proposal__Proposal__c where Apttus_Proposal__Account__c =:legacyacct.Id Limit 1];
        proposal.Apttus_QPApprov__Approval_Status__c = APT_Constants.APPROVAL_STAGE_APPROVED;
        proposal.Apttus_Proposal__Proposal_Expiration_Date__c=system.today()-5;
        update proposal;
        List<Apttus__AgreementLineItem__c> agreementLineItemList = new List<Apttus__AgreementLineItem__c>();
        
        //CREATE Contract for APPC
        Apttus__APTS_Agreement__c aptContractParent = APT_TestUtils.createAgreement(con.Id);
        aptContractParent.APT_Product__c= 'Australia Post Parcel Contract';
        aptContractParent.Apttus__Related_Opportunity__c = opp1.Id;
        aptContractParent.Apttus__Account__c= legacyacct.Id;
        //aptContractParent.RecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
        aptContractParent.RecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('SecurePay Online Payments').getRecordTypeId();
        //aptContractParent.RecordTypeID = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId();
        aptContractParent.Apttus_QPComply__RelatedProposalId__c = proposal.Id;
        aptContractParent.APT_New_Rate_Card_Download__c = true;
        aptContractParent.OwnerId = u1.ID;
        //aptContractParent.APMS_Application__c = appli.ID;
        aptContractParent.Apttus__Status_Category__c = 'Request';
        aptContractParent.Apttus__Status__c = 'Request';
        aptContractParent.Included_Product_Lines__c = APT_Constants.PRODUCT_TYPE_PARCEL_CONTRACT;
        aptContractParent.APT_Contract_Type__c = APT_Constants.CONTRACT_TYPE_NEW_CONTRACT;
        aptContractParent.APT_Commercial_Contact__c = con.Id;// should be contact Id
        aptContractParent.APT_Operational_contact__c = con.Id;// should be contact Id    
        aptContractParent.APT_System_User__c = con.Id;// should be contact Id
        aptContractParent.APT_Registered_Business_Name__c = 'test business name';// text area
        aptContractParent.APTContract_Party_Legal_and_Trading_Name__c = 'test';// text area
        aptContractParent.APT_Trading_As__c = 'test';// text area
        aptContractParent.Billing_Account__c = billacc.Id; // billing accont Id
        aptContractParent.Contract_Expiration_Date__c = system.today()-5;
        insert aptcontractparent;
        ApexPages.currentPage().getParameters().put(APT_Constants.PARAM_ID,aptcontractparent.id);
        ApexPages.currentPage().getParameters().put('Count','1');
        APT_ValidateContractController obj = new APT_ValidateContractController();
        APT_AgreementObjectsSelector mockSelector = (APT_AgreementObjectsSelector) MockUtility.mockSelector(APT_AgreementObjectsSelector.class);
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSelector.selectByConfigId((Set<Id>)fflib_Match.eq(new Set<Id>{aptcontractparent.Id}))).thenReturn(
            new List<Apttus__APTS_Agreement__c>(new List<Apttus__APTS_Agreement__c>{aptcontractparent}));
        MockUtility.Mocks.stopStubbing();
        obj.getCheckAndRedirect();
        System.assertEquals(obj.Count, '1');
        System.assertEquals(system.today()-5,aptContractParent.Contract_Expiration_Date__c);
        test.stoptest();
    } 
    
}