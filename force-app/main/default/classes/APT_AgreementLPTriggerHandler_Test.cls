@isTest
private class APT_AgreementLPTriggerHandler_Test{
    
   
   public static testMethod void testingData(){
        Contact con= APT_TestUtils.createContact();
        insert con;
        Account tempacct = APT_TestUtils.createOrganisation();
        insert tempacct;
        tempacct.Legacy_Id__c = '60000000' ;
        update tempacct;
        Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
        insert opp;
        Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
        aptContract.APT_Product__c= 'eParcel' ;
        aptContract.Apttus__Related_Opportunity__c=opp.Id;
        aptContract.Apttus__Account__c=tempacct.Id;
        //aptContract.Operational_Schedule__c='';
        aptContract.RecordType = [Select Id From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'SecurePay Online Payments' Limit 1];
        insert aptContract;
        Network__c nwk = APT_TestUtils.createNetwork();
        insert nwk;
        APT_Lodgement_Zone__c zone = APT_TestUtils.getLodgementZone('test','NA');
        insert zone;
        Billing_Account__c  billAcc = APT_TestUtils.createBillingAccount(tempacct.id);
        insert billAcc;
        Test.startTest();
        list<APT_Agreement_Lodgement_Point__c> listAcc=new list<APT_Agreement_Lodgement_Point__c>();

        APT_Agreement_Lodgement_Point__c alp = APT_TestUtils.createLodgementPoint(tempacct.Id,aptContract.Id,nwk.Id,zone.Id,'eParcel',billAcc.Id);
        alp.APT_Status__c=APT_Constants.INACTIVE;
        try{
            alp.APT_Agreement__c=null;
        listAcc.add(alp);
        
        insert listAcc;
        update listAcc;
        }
   catch(Exception ex){ }       


        //APT_AgreementLPTriggerHandler.updateOperationalScheduleOnLPChange(listAcc);
        Test.stopTest();
    }
    
   
     public static testMethod void testingData1(){
        Contact con= APT_TestUtils.createContact();
        insert con;
         Contact con2= APT_TestUtils.createContact();
        insert con2;
        Account tempacct = APT_TestUtils.createOrganisation();
        insert tempacct;
        tempacct.Legacy_Id__c = '60000000' ;
        update tempacct;
        Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
        insert opp;
        Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
        aptContract.APT_Product__c= 'eParcel' ;
        aptContract.Apttus__Related_Opportunity__c=opp.Id;
        aptContract.Apttus__Account__c=tempacct.Id;
        //aptContract.RecordType = [Select Id From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'SecurePay Online Payments' Limit 1];
        insert aptContract;
        APT_Operational_Schedule__c opSchedule = new APT_Operational_Schedule__c(APT_Contract__c = aptContract.Id);
        insert opSchedule;
        Network__c nwk = APT_TestUtils.createNetwork();
        nwk.APT_GA_Code__c ='1234';
        nwk.APT_Distribution_Channel__c = 'NA';
        insert nwk;
        APT_Lodgement_Zone__c zone = APT_TestUtils.getLodgementZone('test','NA');
        insert zone;
        Billing_Account__c  billAcc = APT_TestUtils.createBillingAccount(tempacct.id);
        insert billAcc;
         Billing_Account__c  billAcc2 = APT_TestUtils.createBillingAccount(tempacct.id);
        insert billAcc2;
        list<APT_Agreement_Lodgement_Point__c> listAcc=new list<APT_Agreement_Lodgement_Point__c>();
         
         Product2 product =APT_TestUtils.createDomesticProduct('eParcel','eParcelStandard','Postal Services','CAT1','Standard');
        product.APT_Product_type__c = 'eParcels Domestic';
        insert product;
         system.debug('$$$ productCode:' + product.ProductCode);
         
         Apttus__AgreementLineItem__c ali = new Apttus__AgreementLineItem__c();
        ali.Apttus__ProductId__c = product.id;
         ali.Apttus__AgreementId__c = aptContract.id;
        insert ali;
         
         
         Apttus__AgreementLineItem__c ali2 = new Apttus__AgreementLineItem__c();
        ali2.Apttus__ProductId__c = product.id;
         ali2.Apttus__AgreementId__c = aptContract.id;
        insert ali2;
         
        Test.startTest();
        APT_Agreement_Lodgement_Point__c alp = APT_TestUtils.createLodgementPoint(tempacct.Id,aptContract.Id,nwk.Id,zone.Id,'eParcel',billAcc.Id);
        insert alp;
         alp.APT_Status__c = 'Active';
         alp.APT_Billing_Account_Flag__c = True;
         alp.APT_Agreement_Line_Item__c = ali.id;
         
        update alp;
         system.debug('$$$ code1 in test class: ' + alp.APT_Agreement_Line_Item__r.Apttus__ProductId__r.ProductCode); 
        listAcc.add(alp);
         
        APT_Agreement_Lodgement_Point__c alp2 = APT_TestUtils.createLodgementPoint(tempacct.Id,aptContract.Id,nwk.Id,zone.Id,'eParcel',billAcc2.Id);
        insert alp2;
         alp2.APT_Agreement_Line_Item__c = ali2.id;
         alp2.APT_Status__c = 'Active';
         alp2.APT_Billing_Account_Flag__c = True;
         
        update alp2;
          system.debug('$$$ code2 in test class: ' + alp.APT_Agreement_Line_Item__r.Apttus__ProductId__r.ProductCode);
         
        APT_AgreementLPTriggerHandler.validateDuplicateAccounts(listAcc);
        Test.stopTest();
    }
    public static testMethod void testingData2(){
        Contact con= APT_TestUtils.createContact();
        insert con;
        Account tempacct = APT_TestUtils.createOrganisation();
        insert tempacct;
        tempacct.Legacy_Id__c = '60000000' ;
        update tempacct;
        Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
        insert opp;
        Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
        aptContract.APT_Product__c= 'eParcel' ;
        aptContract.Apttus__Related_Opportunity__c=opp.Id;
        aptContract.Apttus__Account__c=tempacct.Id;
        aptContract.RecordType = [Select Id From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'SecurePay Online Payments' Limit 1];
        insert aptContract;
        Network__c nwk = APT_TestUtils.createNetwork();
        nwk.APT_GA_Code__c ='98765432';
        nwk.APT_Distribution_Channel__c=';;';
        insert nwk;
        APT_Lodgement_Zone__c zone = APT_TestUtils.getLodgementZone('test','NA');
        insert zone;
        Billing_Account__c  billAcc = APT_TestUtils.createBillingAccount(tempacct.id);
        insert billAcc;
        APT_Agreement_Lodgement_Point__c alp2 = APT_TestUtils.createLodgementPoint(tempacct.Id,aptContract.Id,nwk.Id,zone.Id,'eParcel',billAcc.Id);
        insert alp2;
        update alp2;
        APT_Operational_Schedule__c opSchedule1 = new APT_Operational_Schedule__c(APT_Contract__c = aptContract.Id);
        insert opSchedule1;
        APT_Operational_Schedule__c opSchedule2 = new APT_Operational_Schedule__c(APT_Contract__c = aptContract.Id);
        insert opSchedule2;
        Test.startTest();
        APT_Agreement_Lodgement_Point__c alp = APT_TestUtils.createLodgementPoint(tempacct.Id,aptContract.Id,nwk.Id,zone.Id,'eParcel',billAcc.Id);
        insert alp;
        update alp;
        Test.stopTest();
    }
    

    public static testMethod void method1(){
        Contact con= APT_TestUtils.createContact();
        insert con;
        Account tempacct = APT_TestUtils.createOrganisation();
        insert tempacct;
        tempacct.Legacy_Id__c = '60000000' ;
        update tempacct;
        Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
        insert opp;
        Opportunity opp2 = APT_TestUtils.createOpportunity(tempacct.id);
        insert opp2;
        Product2 product =APT_TestUtils.createDomesticProduct('eParcel','eParcelStandard','Postal Services','CAT1','Standard');
        product.APT_Product_type__c = 'eParcels Domestic';
        insert product;
        
        Product2 product1 =APT_TestUtils.createDomesticProduct('eParcel Express','eParcelExpress','Postal Services','CAT1','Standard');
        product1.APT_Product_type__c = 'eParcels Domestic';
        insert product1;
        
        Product2 product2 =APT_TestUtils.createInternationalProduct('International Bundle','InternationalBundle','Parcel Services');
        product2.APT_Product_type__c = 'International';
        insert product2;
        
        //Product2 product3 =APT_TestUtils.createDomesticProduct('Local Pickup and Delivery Services','LPDC','Others',null,null);
        Product2 product3 =APT_TestUtils.createDomesticProduct('Local Pickup and Delivery Services','eParcelStandard','Others',null,null);
        product3.APT_Product_type__c = 'Local Pickup and Delivery Services';
        insert product3;
        
        Product2 product4 =APT_TestUtils.createDomesticProduct('Print Post','Print Post','Postal Services',null,null);
        product4.APT_Product_type__c = 'Print Post';
        insert product4;
        
        Product2 product5 =APT_TestUtils.createDomesticProduct('Unaddressed Mail Services','Unaddressed Mail Services','Postal Services',null,null);
        product5.APT_Product_type__c = 'UMS';
        insert product5;
        
        Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
        aptContract.APT_Product__c= 'eParcel' ;
        //aptContract.APT_Product__c= 'Local Pickup and Delivery Services' ;
        aptContract.Apttus__Related_Opportunity__c=opp.Id;
        aptContract.Apttus__Account__c=tempacct.Id;
        //aptContract.RecordType = [Select Id From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'MSA & Service Schedule' Limit 1];
        aptContract.RecordType = [Select Id From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'SecurePay Online Payments' Limit 1];
        insert aptContract;
       
        Network__c nwk = APT_TestUtils.createNetwork();
        nwk.APT_GA_Code__c ='98765432';
        nwk.APT_Distribution_Channel__c=';;';
        insert nwk;
        
        APT_Lodgement_Zone__c zone = APT_TestUtils.getLodgementZone('test','NA');
        insert zone;
        
        Billing_Account__c  billAcc = APT_TestUtils.createBillingAccount(tempacct.id);
        insert billAcc;
        
        List<Apttus__AgreementLineItem__c> aliList = new List<Apttus__AgreementLineItem__c>();
        Apttus__AgreementLineItem__c aLi = new Apttus__AgreementLineItem__c(Apttus__AgreementId__c = aptContract.Id,Apttus__ProductId__c = product.Id);
        aliList.add(aLi);
        Apttus__AgreementLineItem__c aLi1 = new Apttus__AgreementLineItem__c(Apttus__AgreementId__c = aptContract.Id,Apttus__ProductId__c = product1.Id);
        aliList.add(aLi1);
        Apttus__AgreementLineItem__c aLi2 = new Apttus__AgreementLineItem__c(Apttus__AgreementId__c = aptContract.Id,Apttus__ProductId__c = product2.Id);
        aliList.add(aLi2);
       
        //insert aliList;
        
        system.debug('$$$ aptContract.Id = ' + aptContract.Id + '||| $$$ product3.Id = ' + product3.Id);
        Apttus__AgreementLineItem__c aLi3 = new Apttus__AgreementLineItem__c(Apttus__AgreementId__c = aptContract.Id,Apttus__ProductId__c = product3.Id);
        aliList.add(aLi3);
        //insert aLi3;
        
        Apttus__AgreementLineItem__c aLi4 = new Apttus__AgreementLineItem__c(Apttus__AgreementId__c = aptContract.Id,Apttus__ProductId__c = product4.Id);
        aliList.add(aLi4);
        //insert aLi4;
        
        Apttus__AgreementLineItem__c aLi5 = new Apttus__AgreementLineItem__c(Apttus__AgreementId__c = aptContract.Id,Apttus__ProductId__c = product5.Id);
        aliList.add(aLi5);
         //insert aLi5;
        insert aliList;
       
        
        List<APT_Operational_Schedule__c> opsList = new List<APT_Operational_Schedule__c>();
        APT_Operational_Schedule__c opSchedule1 = new APT_Operational_Schedule__c(APT_Contract__c = aptContract.Id);
        opsList.add(opSchedule1);
        insert opsList;
        aptContract.Operational_Schedule__c = opsList[0].Id;
        update aptContract;
        Test.startTest();
        List<APT_Agreement_Lodgement_Point__c> alpList = new List<APT_Agreement_Lodgement_Point__c>();
        APT_Agreement_Lodgement_Point__c alp1 = APT_TestUtils.createLodgementPoint(tempacct.Id,aptContract.Id,nwk.Id,zone.Id,'eParcel',billAcc.Id);
        alp1.APT_Agreement_Line_Item__c = aliList[0].Id;
        alpList.add(alp1);
        APT_Agreement_Lodgement_Point__c alp2 = APT_TestUtils.createLodgementPoint(tempacct.Id,aptContract.Id,nwk.Id,zone.Id,'eParcel Express',billAcc.Id);
        alp2.APT_Agreement_Line_Item__c = aliList[1].Id;
        alpList.add(alp2);
        APT_Agreement_Lodgement_Point__c alp3 = APT_TestUtils.createLodgementPoint(tempacct.Id,aptContract.Id,nwk.Id,zone.Id,'International Bundle',billAcc.Id);
        alp3.APT_Agreement_Line_Item__c = aliList[2].Id;
        alpList.add(alp3);
        APT_Agreement_Lodgement_Point__c alp4 = APT_TestUtils.createLodgementPoint(tempacct.Id,aptContract.Id,nwk.Id,zone.Id,'Local Pickup and Delivery Services',billAcc.Id);
        alp4.APT_Agreement_Line_Item__c = aliList[3].Id;
        alpList.add(alp4);
        APT_Agreement_Lodgement_Point__c alp5 = APT_TestUtils.createLodgementPoint(tempacct.Id,aptContract.Id,nwk.Id,zone.Id,'Print Post',billAcc.Id);
        alp5.APT_Agreement_Line_Item__c = aliList[4].Id;
        alpList.add(alp5);
        APT_Agreement_Lodgement_Point__c alp6 = APT_TestUtils.createLodgementPoint(tempacct.Id,aptContract.Id,nwk.Id,zone.Id,'Unaddressed Mail Services',billAcc.Id);
        alp6.APT_Agreement_Line_Item__c = aliList[5].Id;
        alpList.add(alp6);
        insert alpList;


        Test.stopTest();
        
        
    }

  public static testMethod void method2(){
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
        productList.add(product);
        
        Product2 product1 =APT_TestUtils.createInternationalProduct('Postal Services','26940998','Postal Services');
        product1.ProductCode = APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD;
        productList.add(product1);
        
        Product2 product2 =APT_TestUtils.createInternationalProduct('Postal Services','26940998','Postal Services');
        product2.Family = APT_Constants.PARCEL_SERVICES;
        productList.add(product2);
        
        Product2 product3 =APT_TestUtils.createInternationalProduct('Postal Services','26940998','Postal Services');
        productList.add(product3);
        
        insert productList;
        
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;
        
        
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
        lineItem.APT_Agreement_Billing_Account_IDs__c='testnumvalue;testnumvalue1;';
        insert lineItem;
        Apttus_Config2__ProductAttributeValue__c attriObj = new Apttus_Config2__ProductAttributeValue__c(Apttus_Config2__LineItemId__c =lineItem.ID,APT_PostBillPay_Gross_Settlement_fee__c = 'Yes',APT_eParcel_Lodgment__c = true);
        insert attriObj;
        
        lineItem.Apttus_Config2__AttributeValueId__c = attriObj.ID;
        update lineItem;
        
        
        
        
        Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
        aptContract.APT_Product__c= 'eParcel' ;
        aptContract.Apttus__Related_Opportunity__c=opp1.Id;
        aptContract.Apttus__Account__c=tempacct.Id;
        aptContract.RecordType = [Select Id From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'SecurePay Online Payments' Limit 1];
        insert aptContract;
        Network__c nwk = APT_TestUtils.createNetwork();
        nwk.APT_GA_Code__c ='98765432';
        nwk.APT_Distribution_Channel__c=';;';
        insert nwk;
        APT_Lodgement_Zone__c zone = APT_TestUtils.getLodgementZone('test','NA');
        insert zone;
        Billing_Account__c  billAcc1 = APT_TestUtils.createBillingAccount(tempacct.id);
        insert billAcc1;
        Test.startTest();
        Apttus__AgreementLineItem__c aLi = new Apttus__AgreementLineItem__c(Apttus__AgreementId__c = aptContract.Id,Apttus__ProductId__c = product.Id,
                                                                            Apttus_CMConfig__DerivedFromId__c = lineItem.Id);
        insert aLi;

        
        List<APT_Operational_Schedule__c> opsList = new List<APT_Operational_Schedule__c>();
        APT_Operational_Schedule__c opSchedule1 = new APT_Operational_Schedule__c(APT_Contract__c = aptContract.Id);
        opsList.add(opSchedule1);
        insert opsList;
        aptContract.Operational_Schedule__c = opsList[0].Id;
        update aptContract;
        
        List<APT_Agreement_Lodgement_Point__c> alpList = new List<APT_Agreement_Lodgement_Point__c>();
        APT_Agreement_Lodgement_Point__c alp1 = APT_TestUtils.createLodgementPoint(tempacct.Id,aptContract.Id,nwk.Id,zone.Id,'eParcel',billAcc1.Id);
        alp1.APT_Agreement_Line_Item__c = aLi.Id;
        alpList.add(alp1);
        insert alpList;
        alpList[0].APT_Status__c=APT_Constants.INACTIVE;

        update alpList;
        
        
        
        APT_Agreement_Lodgement_Point__c alp2 = APT_TestUtils.createLodgementPoint(tempacct.Id,aptContract.Id,nwk.Id,zone.Id,'eParcel',billAcc1.Id);
        alp2.APT_Agreement_Line_Item__c = aLi.Id;
        alpList.add(alp2);
        upsert alpList;
        update alpList;

         APT_AgreementLPTriggerHandler.updateLPDetailsToLineItem(alpList);

        Test.stopTest();
        
    
    }
    
     public static testMethod void method3(){
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
        productList.add(product);
        
        Product2 product1 =APT_TestUtils.createInternationalProduct('Postal Services','26940998','Postal Services');
        product1.ProductCode = APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD;
        productList.add(product1);
        
        Product2 product2 =APT_TestUtils.createInternationalProduct('Postal Services','26940998','Postal Services');
        product2.Family = APT_Constants.PARCEL_SERVICES;
        productList.add(product2);
        
        Product2 product3 =APT_TestUtils.createInternationalProduct('Postal Services','26940998','Postal Services');
        productList.add(product3);
        
        insert productList;
        
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;
        
        
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
        lineItem.APT_Agreement_Billing_Account_IDs__c='testnumvalue;testnumvalue1;';

        insert lineItem;
        Apttus_Config2__ProductAttributeValue__c attriObj = new Apttus_Config2__ProductAttributeValue__c(Apttus_Config2__LineItemId__c =lineItem.ID,APT_PostBillPay_Gross_Settlement_fee__c = 'Yes',APT_eParcel_Lodgment__c = true);
        insert attriObj;
        
        lineItem.Apttus_Config2__AttributeValueId__c = attriObj.ID;
        update lineItem;
        
        
        
        
        Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
        aptContract.APT_Product__c= 'eParcel' ;
        aptContract.Apttus__Related_Opportunity__c=opp1.Id;
        aptContract.Apttus__Account__c=tempacct.Id;
        aptContract.RecordType = [Select Id From RecordType where SobjectType = 'Apttus__APTS_Agreement__c' and Name = 'SecurePay Online Payments' Limit 1];
        insert aptContract;
        Network__c nwk = APT_TestUtils.createNetwork();
        nwk.APT_GA_Code__c ='98765432';
        nwk.APT_Distribution_Channel__c=';;';
        insert nwk;
        APT_Lodgement_Zone__c zone = APT_TestUtils.getLodgementZone('test','NA');
        insert zone;
        Billing_Account__c  billAcc1 = APT_TestUtils.createBillingAccount(tempacct.id);
        insert billAcc1;
        Test.startTest();
        Apttus__AgreementLineItem__c aLi = new Apttus__AgreementLineItem__c(Apttus__AgreementId__c = aptContract.Id,Apttus__ProductId__c = product.Id,
                                                                            Apttus_CMConfig__DerivedFromId__c = lineItem.Id);
        insert aLi;

        
        List<APT_Operational_Schedule__c> opsList = new List<APT_Operational_Schedule__c>();
        APT_Operational_Schedule__c opSchedule1 = new APT_Operational_Schedule__c(APT_Contract__c = aptContract.Id);
        opsList.add(opSchedule1);
        insert opsList;
        aptContract.Operational_Schedule__c = opsList[0].Id;
        update aptContract;
        
        List<APT_Agreement_Lodgement_Point__c> alpList = new List<APT_Agreement_Lodgement_Point__c>();
        APT_Agreement_Lodgement_Point__c alp1 = APT_TestUtils.createLodgementPoint(tempacct.Id,aptContract.Id,nwk.Id,zone.Id,'eParcel',billAcc1.Id);
        alp1.APT_Agreement_Line_Item__c = aLi.Id;
        alpList.add(alp1);
        insert alpList;

        update alpList;
        
        
        
        APT_Agreement_Lodgement_Point__c alp2 = APT_TestUtils.createLodgementPoint(tempacct.Id,aptContract.Id,nwk.Id,zone.Id,'eParcel',billAcc1.Id);
        alp2.APT_Agreement_Line_Item__c = aLi.Id;
        alpList.add(alp2);
        upsert alpList;
        update alpList;

         APT_AgreementLPTriggerHandler.updateLPDetailsFromLineItem(alpList);

        Test.stopTest();
        
    
    }
    
    
    
  
    
}