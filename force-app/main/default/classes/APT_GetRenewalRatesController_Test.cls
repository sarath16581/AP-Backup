/**
Description: Test class for Apex Class-APT_GetRenewalRatesController.
Created By - Drashtee Shah
Created Date - 29th Feb, 2016
Last Modified By -
Last Modified Date -
**/
@isTest(SeeAllData=false)
private class APT_GetRenewalRatesController_Test {
    /**
        Creating test data
    **/    
    private static TestMethod void TestMethodDomestic() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {      
            //Create Account
            Account acc = APT_TestUtils.createOrganisation();
            acc.Type = 'Charge Account + Sub Account';
            acc.ACN__c = '123456789';
            acc.LEGACY_ID__c = '60992317';
            insert acc;
            acc.LEGACY_ID__c = '60992317';
            Update acc;
            
            APT_Charge_Account__c cacc = new APT_Charge_Account__c();
            cacc.APT_Industry_Type__c = 'CTTT';
            insert cacc;
            
            //Create Opportunity
            Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
            opty.Amount = 100;
            insert opty;
            
            //Create PriceList
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            //create international product
                        Product2 bundle1 = APT_TestUtils.createDomesticProduct('eParcel Express','eParcelExpress','Postal Services','CAT1','Express');

            insert bundle1;
            
            Product2 option1 = new Product2();
            option1.Name = 'test1';
            option1.Apttus_Config2__ConfigurationType__c = 'Option';
            option1.APT_Category__c = 'CAT1';
            option1.APT_Network_Type__c = 'Express';
            option1.ProductCode = 'eParcelExpress';

            insert option1;
            
            
                        Product2 option2 = new Product2();
            option2.Name = 'test1';
            option2.Apttus_Config2__ConfigurationType__c = 'Option';
            option2.APT_Category__c = 'CAT1';
            option2.APT_Network_Type__c = 'Express';
            option2.ProductCode = 'eParcel Post Return';

            insert option2;
            
                 Product2 option6= new Product2();
            option6.Name = 'test1';
            option6.Apttus_Config2__ConfigurationType__c = 'Option';
            option6.APT_Category__c = 'CAT1';
            option6.APT_Network_Type__c = 'Express';
            option6.ProductCode = 'eParcel Call for Return';

            insert option6;
            
            
            
            
                 Product2 option7= new Product2();
            option7.Name = 'test1';
            option7.Apttus_Config2__ConfigurationType__c = 'Option';
            option7.APT_Category__c = 'CAT1';
            option7.APT_Network_Type__c = 'Express';
            option7.ProductCode = 'MissingManifestFee';

            insert option7;
            
            
            
                 Product2 option8= new Product2();
            option8.Name = 'test1';
            option8.Apttus_Config2__ConfigurationType__c = 'Option';
            option8.APT_Category__c = 'CAT1';
            option8.APT_Network_Type__c = 'Express';
            option8.ProductCode = 'AdministrativeFee';

            insert option8;
            
            
                 Product2 option18= new Product2();
            option18.Name = 'test1';
            option18.Apttus_Config2__ConfigurationType__c = 'Bundle';
            option18.APT_Category__c = 'CAT1';
            option18.APT_Network_Type__c = 'Express';
            option18.ProductCode = 'eParcelExpress';

            insert option18;
            
            
             Product2 option9= new Product2();
            option9.Name = 'test1';
            option9.Apttus_Config2__ConfigurationType__c = 'Option';
            option9.APT_Category__c = 'CAT1';
            option9.APT_Network_Type__c = 'Express';
            option9.ProductCode = 'ReturntoSender';

            insert option9;
            
            
               Product2 option10= new Product2();
            option10.Name = 'test1';
            option10.Apttus_Config2__ConfigurationType__c = 'Option';
            option10.APT_Category__c = 'CAT1';
            option10.APT_Network_Type__c = 'Express';
            option10.ProductCode = 'Minimum Collection Value';

            insert option10;
            
            
            
            Product2 bundle2 = APT_TestUtils.createDomesticProduct('eParcel Express','eParcelExpress','Postal Services','CAT1','Express');
            insert bundle2;
            
            // Product2 option2 = new Product2();
            // option2.Name = 'test1';
            // option2.Apttus_Config2__ConfigurationType__c = 'Option';
            // option2.APT_Category__c = 'CAT1';
            // option2.APT_Network_Type__c = 'Express';
            // option2.ProductCode = 'eParcelExpress';

            // insert option2;
            
            Product2 option3 = new Product2();
            option3.Name = 'test1';
            option3.Apttus_Config2__ConfigurationType__c = 'Option';
            option3.APT_Category__c = 'CAT1';
            option3.APT_Network_Type__c = 'Express';
            option3.ProductCode = 'eParcelExpress';

            insert option3;
            
            system.debug('Product2call1---->'+option3);
                        system.debug('Product2call2---->'+bundle2);

                                    system.debug('Product2call3---->'+option1);
                                    system.debug('Product2call4---->'+bundle1);

            
            //Create Price list Item
            Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
            insert pli;
            
            //Create Proposal
            Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
            Proposal.Apttus_Proposal__Account__c = acc.ID;
            insert Proposal;
            
            //Create Product Configuration             
            Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
            proposal.Id, 'Proposal',
            'Ad Hoc',priceList.Id, null,
            'Ready For Finalization',
            null, Datetime.now(), true);
            insert prodconfig;
            
             //CAS-02939-C8D8Y0 added By Apttus MS 21-05-2018 start          
             
            Apttus_Config2__TempObject__c objTemp = new Apttus_Config2__TempObject__c();
            objTemp.Apttus_Config2__ConfigurationId__c = prodconfig.Id;            
            insert objTemp;
            
             //CAS-02939-C8D8Y0 added By Apttus MS 21-05-2018 End
            
            // Create LineItem
            list<Apttus_Config2__LineItem__c> appConLineList=new list<Apttus_Config2__LineItem__c>();
            Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
            1, 'Product/Service', option1.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
            null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine.Apttus_Config2__NetPrice__c = 5225;
            bundleLine.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
            bundleLine.Apttus_Config2__ParentBundleNumber__c = 1;
            bundleLine.APT_Rate_Card_Key__c = '60992317';
            bundleLine.Apttus_Config2__OptionId__c = option1.Id;
            
            //insert bundleLine;
            bundleLine.APT_RC_Key__c='20000128';

            appConLineList.add(bundleLine);
            insert appConLineList;
            
            APT_Lodgement_Zone__c lodg = new APT_Lodgement_Zone__c();
            lodg.APT_Lodgement_Zone_Code__c = 'AU';
            insert lodg;
            
             
            
            list<Apttus_Config2__LineItem__c> bundleLine2=new list<Apttus_Config2__LineItem__c>();
            
            Apttus_Config2__LineItem__c bundleLine1 = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
            1, 'Product/Service', bundle2.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
            null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
           bundleLine1.Apttus_Config2__ConfigurationId__c=  prodconfig.id;
            bundleLine1.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine1.Apttus_Config2__NetPrice__c = 5225;
            bundleLine1.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine1.Apttus_Config2__NetAdjustmentPercent__c = -10;
            bundleLine1.Apttus_Config2__ParentBundleNumber__c = 1;
            bundleLine1.APT_Rate_Card_Key__c = '60992317';
            bundleLine1.Apttus_Config2__ProductId__c=option1.Id;

            bundleLine1.Apttus_Config2__OptionId__c = option1.Id;
            bundleLine1.APT_RC_Key__c='20000128';


            bundleLine2.add(bundleLine1);
            insert bundleLine2;
            
            system.debug('bundleLine2[0].APT_Rate_Card_Key__c1---->'+bundleLine1.APT_Rate_Card_Key__c);
    

            
              Apttus_Config2__ProductAttributeValue__c attriObj = new Apttus_Config2__ProductAttributeValue__c(Apttus_Config2__LineItemId__c =bundleLine2[0].ID,APT_PostBillPay_Gross_Settlement_fee__c = 'Yes', APT_Lodgement_Zone__c=lodg.id);
        insert attriObj;
        
        bundleLine2[0].Apttus_Config2__AttributeValueId__c = attriObj.ID;
        update bundleLine2;
         
         
                     system.debug('bundleLine1.Apttus_Config2__ProductId__c---->'+bundleLine1.Apttus_Config2__ProductId__c);

         

            Apttus_Config2__LineItem__c bundleLine13 = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
            1, 'Product/Service', option1.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
            null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
           bundleLine13.Apttus_Config2__ConfigurationId__c=  prodconfig.id;
           
            bundleLine13.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine13.Apttus_Config2__NetPrice__c = 5225;
            bundleLine13.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine13.Apttus_Config2__NetAdjustmentPercent__c = -10;
            bundleLine13.Apttus_Config2__ParentBundleNumber__c = 1;
            bundleLine13.APT_Rate_Card_Key__c = '60992317';
            bundleLine13.Apttus_Config2__OptionId__c = option18.Id;
            bundleLine13.Apttus_Config2__ProductId__c = option18.Id;
            //bundleLine13.Apttus_Config2__AttributeValueId__c = attriObj.ID;
            

            insert bundleLine13;

            
            Apttus_Config2__LineItem__c bundleLine3 = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
            1, 'Product/Service', option1.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
            null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
           bundleLine3.Apttus_Config2__ConfigurationId__c=  prodconfig.id;
           
            bundleLine3.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine3.Apttus_Config2__NetPrice__c = 5225;
            bundleLine3.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine3.Apttus_Config2__NetAdjustmentPercent__c = -10;
            bundleLine3.Apttus_Config2__ParentBundleNumber__c = 1;
            bundleLine3.APT_Rate_Card_Key__c = '60992317';
            bundleLine3.Apttus_Config2__OptionId__c = option1.Id;
            bundleLine3.Apttus_Config2__ProductId__c = option1.Id;
           // bundleLine3.Apttus_Config2__AttributeValueId__c = attriObj.ID;

            insert bundleLine3;
            
            
               Apttus_Config2__LineItem__c bundleLine5 = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
            1, 'Product/Service', option2.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
            null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
           bundleLine5.Apttus_Config2__ConfigurationId__c=  prodconfig.id;
            bundleLine5.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine5.Apttus_Config2__NetPrice__c = 5225;
            bundleLine5.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine5.Apttus_Config2__NetAdjustmentPercent__c = -10;
            bundleLine5.Apttus_Config2__ParentBundleNumber__c = 1;
            bundleLine5.APT_Rate_Card_Key__c = '60992317';
            bundleLine5.Apttus_Config2__OptionId__c = option2.Id;
            bundleLine5.Apttus_Config2__ProductId__c = option2.Id;
            bundleLine5.Apttus_Config2__ChargeType__c='eParcel Returns - Delivery Fee (per article)';
            //bundleLine5.Apttus_Config2__AttributeValueId__c = attriObj.ID;
            insert bundleLine5;
            
            
            
               Apttus_Config2__LineItem__c bundleLine6 = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
            1, 'Product/Service', option6.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
            null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
           bundleLine6.Apttus_Config2__ConfigurationId__c=  prodconfig.id;
            bundleLine6.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine6.Apttus_Config2__NetPrice__c = 5225;
            bundleLine6.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine6.Apttus_Config2__NetAdjustmentPercent__c = -10;
            bundleLine6.Apttus_Config2__ParentBundleNumber__c = 1;
            bundleLine6.APT_Rate_Card_Key__c = '60992317';
            bundleLine6.Apttus_Config2__OptionId__c = option6.Id;
            bundleLine6.Apttus_Config2__ProductId__c = option6.Id;
            bundleLine6.Apttus_Config2__ChargeType__c='Parcel Post Call for Returns - Delivery Fee (per article)';
            //bundleLine6.Apttus_Config2__AttributeValueId__c = attriObj.ID;
            
            insert bundleLine6;
            
            
                 Apttus_Config2__LineItem__c bundleLine7 = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
            1, 'Product/Service', option7.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
            null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
           bundleLine7.Apttus_Config2__ConfigurationId__c=  prodconfig.id;
            bundleLine7.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine7.Apttus_Config2__NetPrice__c = 5225;
            bundleLine7.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine7.Apttus_Config2__NetAdjustmentPercent__c = -10;
            bundleLine7.Apttus_Config2__ParentBundleNumber__c = 1;
            bundleLine7.APT_Rate_Card_Key__c = '60992317';
            bundleLine7.Apttus_Config2__OptionId__c = option7.Id;
            bundleLine7.Apttus_Config2__ProductId__c = option7.Id;
            bundleLine7.Apttus_Config2__ChargeType__c='Standard Price';
            //bundleLine7.Apttus_Config2__AttributeValueId__c = attriObj.ID;
            insert bundleLine7;
            
            
                     Apttus_Config2__LineItem__c bundleLine8 = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
            1, 'Product/Service', option8.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
            null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
           bundleLine8.Apttus_Config2__ConfigurationId__c=  prodconfig.id;
            bundleLine8.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine8.Apttus_Config2__NetPrice__c = 5225;
            bundleLine8.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine8.Apttus_Config2__NetAdjustmentPercent__c = -10;
            bundleLine8.Apttus_Config2__ParentBundleNumber__c = 1;
            bundleLine8.APT_Rate_Card_Key__c = '60992317';
            bundleLine8.Apttus_Config2__OptionId__c = option8.Id;
            bundleLine8.Apttus_Config2__ProductId__c = option8.Id;
            bundleLine8.Apttus_Config2__ChargeType__c='Standard Price';
            //bundleLine8.Apttus_Config2__AttributeValueId__c = attriObj.ID;
            
            insert bundleLine8;
            
            
            
            
                     Apttus_Config2__LineItem__c bundleLine9 = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
            1, 'Product/Service', option9.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
            null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
           bundleLine9.Apttus_Config2__ConfigurationId__c=  prodconfig.id;
            bundleLine9.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine9.Apttus_Config2__NetPrice__c = 5225;
            bundleLine9.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine9.Apttus_Config2__NetAdjustmentPercent__c = -10;
            bundleLine9.Apttus_Config2__ParentBundleNumber__c = 1;
            bundleLine9.APT_Rate_Card_Key__c = '60992317';
            bundleLine9.Apttus_Config2__OptionId__c = option9.Id;
            bundleLine9.Apttus_Config2__ProductId__c = option9.Id;
            bundleLine9.Apttus_Config2__ChargeType__c='Standard Price';
            //bundleLine9.Apttus_Config2__AttributeValueId__c = attriObj.ID;
            
            insert bundleLine9;
            
            
            
            
                     Apttus_Config2__LineItem__c bundleLine10 = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
            1, 'Product/Service', option10.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
            null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
           bundleLine10.Apttus_Config2__ConfigurationId__c=  prodconfig.id;
            bundleLine10.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine10.Apttus_Config2__NetPrice__c = 5225;
            bundleLine10.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine10.Apttus_Config2__NetAdjustmentPercent__c = -10;
            bundleLine10.Apttus_Config2__ParentBundleNumber__c = 1;
            bundleLine10.APT_Rate_Card_Key__c = '60992317';
            bundleLine10.Apttus_Config2__OptionId__c = option10.Id;
            bundleLine10.Apttus_Config2__ProductId__c = option10.Id;
            bundleLine10.Apttus_Config2__ChargeType__c='Standard Price';
           // bundleLine13.Apttus_Config2__AttributeValueId__c = attriObj.ID;
            insert bundleLine10;
            
            //system.debug('bundleLine2[0].APT_Rate_Card_Key__c1---->'+bundleLine1.APT_Rate_Card_Key__c);
             Apttus_Config2__ProductAttributeValue__c attriObj11 = new Apttus_Config2__ProductAttributeValue__c(Apttus_Config2__LineItemId__c =bundleLine13.ID,APT_PostBillPay_Gross_Settlement_fee__c = 'Yes',APT_Band__c='BAND 3',APT_Lodgement_Zone__c=lodg.id);
        insert attriObj11;
          
            
            Apttus_Config2__ProductAttributeValue__c attriObj1 = new Apttus_Config2__ProductAttributeValue__c(Apttus_Config2__LineItemId__c =bundleLine3.ID,APT_PostBillPay_Gross_Settlement_fee__c = 'Yes',APT_Band__c='BAND 3',APT_Lodgement_Zone__c=lodg.id);
        insert attriObj1;
        bundleLine13.Apttus_Config2__AttributeValueId__c = attriObj11.ID;
         
        bundleLine3.Apttus_Config2__AttributeValueId__c = attriObj1.ID;
        bundleLine5.Apttus_Config2__AttributeValueId__c = attriObj1.id;
                bundleLine6.Apttus_Config2__AttributeValueId__c = attriObj1.id;
                                bundleLine7.Apttus_Config2__AttributeValueId__c = attriObj1.id;
                                bundleLine8.Apttus_Config2__AttributeValueId__c = attriObj1.id;
                                bundleLine9.Apttus_Config2__AttributeValueId__c = attriObj1.id;
                                                                bundleLine10.Apttus_Config2__AttributeValueId__c = attriObj1.id;


        update bundleLine9;
        update bundleLine10;
        update bundleLine13; 
        update bundleLine3;
        update bundleLine5;
        update bundleLine6;

        update bundleLine7;
        update bundleLine8;

        system.debug('pro.product--->'+bundle2.Id);

        
        product2 pro= [select id,ProductCode from product2 where id=:bundleLine1.Apttus_Config2__ProductId__c];
        
system.debug('pro.product--->'+bundle2.Id);

            
            
            
            //create price list
            Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
            insert testPriceList;
            
            //create R2T System Properties
            APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
            r2tSystemProperties.APT_Org_Id_Service_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_CompanyCreditAssessmentEndPointURL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_INDV_Credit_Assessment_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_Query_Rate_Card_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            
            insert r2tSystemProperties;
            
            APT_Domestic_Price_Data__c domesticPriceData = APT_TestUtils.createDomesticPriceData(bundleLine.Apttus_Config2__AttributeValueId__r.Category__c,'Express',bundleLine.Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone_Code__c,'ZONE2','Sydney'
            ,bundleLine.Apttus_Config2__AttributeValueId__r.APTS_Price_Structure__c,0.50,'up to 500g',7,0,0);
             APT_Domestic_Price_Data__c domesticPriceData1 = APT_TestUtils.createDomesticPriceData(bundleLine.Apttus_Config2__AttributeValueId__r.Category__c,'Express',bundleLine.Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone_Code__c,'ZONE2','Sydney'
            ,bundleLine.Apttus_Config2__AttributeValueId__r.APTS_Price_Structure__c,1.00,'501g to 1kg',7,0,0);
            List<APT_Domestic_Price_Data__c> domesticPriceDataList = new List<APT_Domestic_Price_Data__c>{domesticPriceData,domesticPriceData1};
            insert domesticPriceDataList;
            //Test.startTest();
           // APT_SAP_CustomerContractService.ExternalCustomerContractServices_v1HTTPEndpoint1 endPoint = new APT_SAP_CustomerContractService.ExternalCustomerContractServices_v1HTTPEndpoint1();
            
            // endPoint.inputHttpHeaders_x  = APT_WebServiceUtility.getinputHttpHeaders() ;
            // endPoint.Header = APT_WebServiceUtility.getqueryRateCardInterfaceHeader(APT_WebServiceUtility.INTERFACE_NAME_QUERYRATECARDS);
            // endpoint.timeout_x = APT_WebServiceUtility.DEFAULT_WEBSERVICE_TIMEOUT;
            
            // APT_R2T_System_Properties__c r2tSystemProperty = APT_R2T_System_Properties__c.getOrgDefaults();
            // if(r2tSystemProperty != null && r2tSystemProperty.APT_Query_Rate_Card_End_Point_URL__c != null) {
            //     endPoint.endpoint_x = r2tSystemProperty.APT_Query_Rate_Card_End_Point_URL__c;
            // } 
            
            // APT_SAP_QueryRateCardService.Ratecards_element response = endPoint.queryRatecards_v1(bundleLine.APT_Rate_Card_Key__c);
            
            APT_SAP_QueryRateCardService.CreationType CreationType=new APT_SAP_QueryRateCardService.CreationType();
            CreationType.Timestamp=datetime.ValueOf('1968-09-21 02:16:42');
           CreationType.DayId=20160125.0;
           CreationType.MonthId=201601.0;
            CreationType.UserId='MOLONEYK';
            CreationType.UserLevel='1';
            CreationType.ToolName='YIELD_TOOL_APP';
            CreationType.UploadType='User';
            
            APT_SAP_QueryRateCardService.ApprovalDetails ApprovalDetails=new APT_SAP_QueryRateCardService.ApprovalDetails();
            
            ApprovalDetails.Flag='';
            ApprovalDetails.Timestamp=datetime.ValueOf('1968-09-21 02:16:42');
            ApprovalDetails.UserId='MOLONEYK';
            
            APT_SAP_QueryRateCardService.ExtractDetails ExtractDetails=new APT_SAP_QueryRateCardService.ExtractDetails ();
            ExtractDetails.Flag='';
            ExtractDetails.Timestamp=datetime.ValueOf('1968-09-21 02:16:42');
            ExtractDetails.UserId='MOLONEYK';
            ExtractDetails.ApprovalDetails=ApprovalDetails;

 
 
 APT_SAP_QueryRateCardService.StatusDetails StatusDetails=new APT_SAP_QueryRateCardService.StatusDetails();
 StatusDetails.Type_x='DOMESTIC';
 StatusDetails.Timestamp=datetime.ValueOf('1968-09-21 02:16:42');

 APT_SAP_QueryRateCardService.CustomerPricingDetailsType CustomerPricingDetailsType =new APT_SAP_QueryRateCardService.CustomerPricingDetailsType();
 
     CustomerPricingDetailsType.Domestic='No';
     CustomerPricingDetailsType.IndustrySegment='Books / Print Material';
     CustomerPricingDetailsType.InternationalLetters='YES';
     CustomerPricingDetailsType.EparcelLodgement='YES';
     CustomerPricingDetailsType.VolumeAvailable='YES';
     
     APT_SAP_QueryRateCardService.TransitCoverDetailsType  TransitCoverDetails=new APT_SAP_QueryRateCardService.TransitCoverDetailsType ();
     TransitCoverDetails.MinimumTransitCover=10.0;
     TransitCoverDetails.MaximumTransitCover=11.2;
     TransitCoverDetails.Percentage=11.2;
     
     
     APT_SAP_QueryRateCardService.FeaturesDetailsType FeaturesDetailsType=new APT_SAP_QueryRateCardService.FeaturesDetailsType();
     FeaturesDetailsType.TransitCoverDetails=TransitCoverDetails;
       FeaturesDetailsType.ReturnsPercentageAnnualVolume=3.0;
     FeaturesDetailsType.UpTo500GTotalReturnsVolume=10.0;
     FeaturesDetailsType.AverageChargeableWeight=11.3;
     FeaturesDetailsType.EparcelReturnsDeliveryFee=100.3;
     FeaturesDetailsType.ParcelPostReturnsDeliveryFee=120.5;
     FeaturesDetailsType.ParcelPostReturnsPickupFee=159.4;
     FeaturesDetailsType.ReturnPaidUpTo500GParcelPostFee=200.2;
     FeaturesDetailsType.ReturnPaidOver500GParcelPostFee=30.3;
     FeaturesDetailsType.ReturnPaidAnnualFee=122.3;
     FeaturesDetailsType.IdentityDeliveryFee=150.5;
     
     APT_SAP_QueryRateCardService.StandardChargesType StandardChargesType=new APT_SAP_QueryRateCardService.StandardChargesType();
     
    StandardChargesType.InternationalAdminFee=45.45;
   StandardChargesType.CollectionFee=37.27;
   
   APT_SAP_QueryRateCardService.CurrentPricingDetailsType CurrentPricingDetailsType =new APT_SAP_QueryRateCardService.CurrentPricingDetailsType ();
   
    CurrentPricingDetailsType.LodgementZoneCode='AU';
    CurrentPricingDetailsType.ChargeCode='SINTB017';
    
    APT_SAP_QueryRateCardService.NewPricingDetailsType NewPricingDetailsType =new APT_SAP_QueryRateCardService.NewPricingDetailsType ();
    NewPricingDetailsType.LodgementZoneCode='AU';
    NewPricingDetailsType.PriceZoneStructure='Abc';
    NewPricingDetailsType.Category='Num';
   
     APT_SAP_QueryRateCardService.MaxWeightBreak_element MaxWeightBreak_element=new APT_SAP_QueryRateCardService.MaxWeightBreak_element();
    
    
    
    APT_SAP_QueryRateCardService.FlatRatesDetailsType  FlatRatesDetailsType =new APT_SAP_QueryRateCardService.FlatRatesDetailsType ();
    FlatRatesDetailsType.DispersionType='DEFAULT';
    FlatRatesDetailsType.MaxWeightBreak=MaxWeightBreak_element;
    
    
    APT_SAP_QueryRateCardService.BandRateDetailsType BandRateDetailsType =new APT_SAP_QueryRateCardService.BandRateDetailsType ();
    BandRateDetailsType.Band='BAND_3';
    BandRateDetailsType.RevenueEstimation=12983.35;
    BandRateDetailsType.RevenueRange='5000 - 19999';
    
   APT_SAP_QueryRateCardService.ExpressCourierRates_element ExpressCourierRates_element=new APT_SAP_QueryRateCardService.ExpressCourierRates_element();
   ExpressCourierRates_element.UpTo2KGPerItem=12.0;
ExpressCourierRates_element.UpTo2KGPerKG=0.0;
ExpressCourierRates_element.Over2KGPerKG=2.4;

APT_SAP_QueryRateCardService.UKRatesDetailsType UKRatesDetailsType =new APT_SAP_QueryRateCardService.UKRatesDetailsType ();

UKRatesDetailsType.ExpressCourierRates=ExpressCourierRates_element;

APT_SAP_QueryRateCardService.AirmailRates_element AirmailRates_element =new APT_SAP_QueryRateCardService.AirmailRates_element ();
AirmailRates_element.UpTo2KGPerItem=12.0;
AirmailRates_element.UpTo2KGPerKG=0.0;
AirmailRates_element.Over2KGPerItem=10.5;
AirmailRates_element.Over2KGPerKG=2.7;



APT_SAP_QueryRateCardService.NewZealandRatesDetailsType NewZealandRatesDetailsType =new APT_SAP_QueryRateCardService.NewZealandRatesDetailsType ();
NewZealandRatesDetailsType.AirmailRates=AirmailRates_element;
NewZealandRatesDetailsType.ExpressCourierRates  =ExpressCourierRates_element;

APT_SAP_QueryRateCardService.Comments_element Comments_element =new APT_SAP_QueryRateCardService.Comments_element ();
 
 list<APT_SAP_QueryRateCardService.RateType> RateTypeList=new list<APT_SAP_QueryRateCardService.RateType>();
 
 APT_SAP_QueryRateCardService.RateType RateType =new APT_SAP_QueryRateCardService.RateType ();
 
RateType.DestinationZoneCode='ZONE2';
RateType.WeightRangeCode=0.5;
RateType.RAFCode='I01';
RateType.LookupFull='AIRLET_ZONE2';
RateType.SubsequentRate=1.23;
RateType.PerKgRate=17.6;
RateType.BaseRate=0.8;
RateTypeList.add(RateType);

map<string,set<decimal>> mapWeightCode = new map<String , set<decimal>>();

set<decimal> setweight=new set<decimal>();
setweight.add(0.50);

mapWeightCode.put('N1',setweight);




    APT_SAP_QueryRateCardService.RatesDetails_element RatesDetails_element =new APT_SAP_QueryRateCardService.RatesDetails_element ();
    RatesDetails_element.Rate=RateTypeList;
    
    APT_SAP_QueryRateCardService.RatecardContractDetailsType RatecardContractDetailsType =new APT_SAP_QueryRateCardService.RatecardContractDetailsType ();
    RatecardContractDetailsType.SubProductName='eParcelExpress';
    
    list<APT_SAP_QueryRateCardService.RateCardType> rateCardTypeList=new list<APT_SAP_QueryRateCardService.RateCardType>();
            APT_SAP_QueryRateCardService.RateCardType  rateCardType=new APT_SAP_QueryRateCardService.RateCardType();
            rateCardType.RateCardKey='20000128';
            rateCardType.PrecedingRateCardKey='';
            RateCardType.Type_x='DOMESTIC';
            RateCardType.ScenarioType='INTERNATIONAL_NEW_BPA';
            rateCardType.QuoteNumber='';
            rateCardType.ServiceTypeFlag='';
            rateCardType.ServiceType='';
            rateCardType.SignatureFlag='';
            rateCardType.CreationDetails=CreationType;
            rateCardType.StatusDetails =StatusDetails;
           rateCardType.ExtractDetails  =ExtractDetails;
           rateCardType.CustomerPricingDetails =CustomerPricingDetailsType;
          rateCardType.FeaturesDetails = FeaturesDetailsType;
          rateCardType.StandardCharges=StandardChargesType;
          rateCardType.CurrentPricingDetails = CurrentPricingDetailsType;
          rateCardType.NewPricingDetails=    NewPricingDetailsType;
          rateCardType.FlatRatesDetails=FlatRatesDetailsType;
       rateCardType.BandRateDetails=   BandRateDetailsType;
    rateCardType.UKRatesDetails = UKRatesDetailsType;
    
   rateCardType.NewZealandRatesDetails  =NewZealandRatesDetailsType;
   rateCardType.Comments=Comments_element;
   rateCardType.RatesDetails=RatesDetails_element;
   rateCardType.ContractDetails =    RatecardContractDetailsType;
   
         rateCardTypeList.add(rateCardType);   
            
            APT_SAP_QueryRateCardService.Ratecards_element  ratecards=new APT_SAP_QueryRateCardService.Ratecards_element();
           ratecards.Ratecard=rateCardTypeList;
           // Test.stopTest();
        
       
        
        
            
            PageReference pageRef = Page.APT_GetRenewalRates;
            Test.setCurrentPage(pageRef);
            
            Apexpages.currentPage().getHeaders().put('Referer', 'Page.APT_GetRenewalRates');
            Apexpages.currentPage().getParameters().put('selectedRecordID', bundleLine3.ID);
            Apexpages.currentPage().getParameters().put('selectedRecordID', bundleLine13.ID);

            Test.StartTest();
            Test.setMock(WebServiceMock.class, new APT_WebserviceMockCustomerContract());
            
            
            APT_GetRenewalRatesController grrc = new APT_GetRenewalRatesController();
            grrc.lineItemId=bundleLine3.id;

            system.debug('bundleLine2productcode------>'+bundleLine3.Apttus_Config2__ProductId__c);
            
                   id proNewId= bundleLine2[0].Apttus_Config2__ProductId__c;
          product2 proNow= [select id,ProductCode from product2 where id=:proNewId];
          
                      system.debug('bundleLine2[0].ProNopw---->'+bundle2.Id);
                      
                      
            APT_GetRenewalRatesController.updateConfig(ratecards,bundleLine3);
            APT_GetRenewalRatesController.updateConfig(ratecards,bundleLine13);

            grrc.UpdateConfigandRates();
            APT_GetRenewalRatesController.parseQueryRateCardResponse(ratecards,bundleLine3);
                     // list<APT_SAP_QueryRateCardService.RateType> listSortedRates =  APT_GetRenewalRatesController.sortRates(rateCardType,setDestinationZoneCode,mapWeightCode);
            
        //  APT_GetRenewalRatesController.parseDomesticRateCard(listSortedRates,bundleLine3);
            APT_GetRenewalRatesController.blnTestClass = true; 
            grrc.warningpopup();
            grrc.goBack();
            grrc.goBck();
            grrc.doGetRenewalRates();
            grrc.listLineItem=bundleLine2;
            Apexpages.currentPage().getParameters().put('selectedRecordID', null);
            //Test.StartTest();
            APT_GetRenewalRatesController grrc1 = new APT_GetRenewalRatesController();
            grrc1.doGetRenewalRates();
            Apexpages.currentPage().getParameters().put('selectedRecordID', bundleLine1.ID);
            //Test.StartTest();
            APT_GetRenewalRatesController grrc12 = new APT_GetRenewalRatesController();
            grrc12.doGetRenewalRates();
            string configID = bundleLine10.Apttus_Config2__ConfigurationId__c;
            system.debug('configID------->'+configID);
            //APT_GetRenewalRatesController grrc13 = new APT_GetRenewalRatesController();
            
            Test.StopTest();
            //system.assert(pageRef!=null);
            //Test.StopTest();
        }
    }
    
    
    
    private static TestMethod void TestMethodDomestic11() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {      
            //Create Account
            Account acc = APT_TestUtils.createOrganisation();
            acc.Type = 'Charge Account + Sub Account';
            acc.ACN__c = '123456789';
            acc.LEGACY_ID__c = '60992317';
            insert acc;
            acc.LEGACY_ID__c = '60992317';
            Update acc;
            
            APT_Charge_Account__c cacc = new APT_Charge_Account__c();
            cacc.APT_Industry_Type__c = 'CTTT';
            insert cacc;
            
            //Create Opportunity
            Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
            opty.Amount = 100;
            insert opty;
            
            //Create PriceList
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            //create international product
                        Product2 bundle1 = APT_TestUtils.createDomesticProduct('eParcel Express','eParcelExpress','Postal Services','CAT1','Express');

            insert bundle1;
            
            Product2 option1 = new Product2();
            option1.Name = 'test1';
            option1.Apttus_Config2__ConfigurationType__c = 'Option';
            option1.APT_Category__c = 'CAT1';
            option1.APT_Network_Type__c = 'Express';
            option1.ProductCode = 'eParcelExpress';

            insert option1;
            
            
                        Product2 option2 = new Product2();
            option2.Name = 'test1';
            option2.Apttus_Config2__ConfigurationType__c = 'Option';
            option2.APT_Category__c = 'CAT1';
            option2.APT_Network_Type__c = 'Express';
            option2.ProductCode = 'eParcelExpress';

            insert option2;
            
                 Product2 option6= new Product2();
            option6.Name = 'test1';
            option6.Apttus_Config2__ConfigurationType__c = 'Option';
            option6.APT_Category__c = 'CAT1';
            option6.APT_Network_Type__c = 'Express';
            option6.ProductCode = 'eParcel Call for Return';

            insert option6;
            
            
            
            
                 Product2 option7= new Product2();
            option7.Name = 'test1';
            option7.Apttus_Config2__ConfigurationType__c = 'Option';
            option7.APT_Category__c = 'CAT1';
            option7.APT_Network_Type__c = 'Express';
            option7.ProductCode = 'MissingManifestFee';

            insert option7;
            
            
            
                 Product2 option8= new Product2();
            option8.Name = 'test1';
            option8.Apttus_Config2__ConfigurationType__c = 'Option';
            option8.APT_Category__c = 'CAT1';
            option8.APT_Network_Type__c = 'Express';
            option8.ProductCode = 'AdministrativeFee';

            insert option8;
            
            
                 Product2 option18= new Product2();
            option18.Name = 'test1';
            option18.Apttus_Config2__ConfigurationType__c = 'Bundle';
            option18.APT_Category__c = 'CAT1';
            option18.APT_Network_Type__c = 'Express';
            option18.ProductCode = 'eParcelExpress';

            insert option18;
            
            
             Product2 option9= new Product2();
            option9.Name = 'test1';
            option9.Apttus_Config2__ConfigurationType__c = 'Option';
            option9.APT_Category__c = 'CAT1';
            option9.APT_Network_Type__c = 'Express';
            option9.ProductCode = 'ReturntoSender';

            insert option9;
            
            
               Product2 option10= new Product2();
            option10.Name = 'test1';
            option10.Apttus_Config2__ConfigurationType__c = 'Option';
            option10.APT_Category__c = 'CAT1';
            option10.APT_Network_Type__c = 'Express';
            option10.ProductCode = 'Minimum Collection Value';

            insert option10;
            
            
            
            Product2 bundle2 = APT_TestUtils.createDomesticProduct('eParcel Express','eParcelExpress','Postal Services','CAT1','Express');
            insert bundle2;
            
            // Product2 option2 = new Product2();
            // option2.Name = 'test1';
            // option2.Apttus_Config2__ConfigurationType__c = 'Option';
            // option2.APT_Category__c = 'CAT1';
            // option2.APT_Network_Type__c = 'Express';
            // option2.ProductCode = 'eParcelExpress';

            // insert option2;
            
            Product2 option3 = new Product2();
            option3.Name = 'test1';
            option3.Apttus_Config2__ConfigurationType__c = 'Option';
            option3.APT_Category__c = 'CAT1';
            option3.APT_Network_Type__c = 'Express';
            option3.ProductCode = 'eParcelExpress';

            insert option3;
            
            system.debug('Product2call1---->'+option3);
                        system.debug('Product2call2---->'+bundle2);

                                    system.debug('Product2call3---->'+option1);
                                    system.debug('Product2call4---->'+bundle1);

            
            //Create Price list Item
            Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
            insert pli;
            
            //Create Proposal
            Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
            Proposal.Apttus_Proposal__Account__c = acc.ID;
            insert Proposal;
            
            //Create Product Configuration             
            Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
            proposal.Id, 'Proposal',
            'Ad Hoc',priceList.Id, null,
            'Ready For Finalization',
            null, Datetime.now(), true);
            insert prodconfig;
            
             //CAS-02939-C8D8Y0 added By Apttus MS 21-05-2018 start          
             
            Apttus_Config2__TempObject__c objTemp = new Apttus_Config2__TempObject__c();
            objTemp.Apttus_Config2__ConfigurationId__c = prodconfig.Id;            
            insert objTemp;
            
             //CAS-02939-C8D8Y0 added By Apttus MS 21-05-2018 End
            
            // Create LineItem
            list<Apttus_Config2__LineItem__c> appConLineList=new list<Apttus_Config2__LineItem__c>();
            Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
            1, 'Product/Service', option1.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
            null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine.Apttus_Config2__NetPrice__c = 5225;
            bundleLine.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
            bundleLine.Apttus_Config2__ParentBundleNumber__c = 1;
            
            bundleLine.Apttus_Config2__OptionId__c = option1.Id;
          
            //insert bundleLine;
            bundleLine.APT_RC_Key__c='60992317';

            appConLineList.add(bundleLine);
            insert appConLineList;
            
            
            
             
            
            list<Apttus_Config2__LineItem__c> bundleLine2=new list<Apttus_Config2__LineItem__c>();
            
            Apttus_Config2__LineItem__c bundleLine1 = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
            1, 'Product/Service', bundle2.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
            null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
           bundleLine1.Apttus_Config2__ConfigurationId__c=  prodconfig.id;
            bundleLine1.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine1.Apttus_Config2__NetPrice__c = 5225;
            bundleLine1.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine1.Apttus_Config2__NetAdjustmentPercent__c = -10;
            bundleLine1.Apttus_Config2__ParentBundleNumber__c = 1;
            
            bundleLine1.Apttus_Config2__ProductId__c=option1.Id;

            bundleLine1.Apttus_Config2__OptionId__c = option1.Id;
            bundleLine1.APT_RC_Key__c='60992317';


            bundleLine2.add(bundleLine1);
            insert bundleLine2;
            
            system.debug('bundleLine2[0].APT_Rate_Card_Key__c1---->'+bundleLine1.APT_Rate_Card_Key__c);
    

            
              Apttus_Config2__ProductAttributeValue__c attriObj = new Apttus_Config2__ProductAttributeValue__c(Apttus_Config2__LineItemId__c =bundleLine2[0].ID,APT_PostBillPay_Gross_Settlement_fee__c = 'Yes');
        insert attriObj;
        
        bundleLine2[0].Apttus_Config2__AttributeValueId__c = attriObj.ID;
        update bundleLine2;
         
         
                     system.debug('bundleLine1.Apttus_Config2__ProductId__c---->'+bundleLine1.Apttus_Config2__ProductId__c);

         

            Apttus_Config2__LineItem__c bundleLine13 = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
            1, 'Product/Service', option1.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
            null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
           bundleLine13.Apttus_Config2__ConfigurationId__c=  prodconfig.id;
           
            bundleLine13.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine13.Apttus_Config2__NetPrice__c = 5225;
            bundleLine13.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine13.Apttus_Config2__NetAdjustmentPercent__c = -10;
            bundleLine13.Apttus_Config2__ParentBundleNumber__c = 1;
            
            bundleLine13.Apttus_Config2__OptionId__c = option18.Id;
            bundleLine13.Apttus_Config2__ProductId__c = option18.Id;
            

            insert bundleLine13;

            
            Apttus_Config2__LineItem__c bundleLine3 = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
            1, 'Product/Service', option1.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
            null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
           bundleLine3.Apttus_Config2__ConfigurationId__c=  prodconfig.id;
           
            bundleLine3.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine3.Apttus_Config2__NetPrice__c = 5225;
            bundleLine3.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine3.Apttus_Config2__NetAdjustmentPercent__c = -10;
            bundleLine3.Apttus_Config2__ParentBundleNumber__c = 1;
            
            bundleLine3.Apttus_Config2__OptionId__c = option1.Id;
            bundleLine3.Apttus_Config2__ProductId__c = option1.Id;
            

            insert bundleLine3;
            
            
               Apttus_Config2__LineItem__c bundleLine5 = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
            1, 'Product/Service', option2.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
            null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
           bundleLine5.Apttus_Config2__ConfigurationId__c=  prodconfig.id;
            bundleLine5.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine5.Apttus_Config2__NetPrice__c = 5225;
            bundleLine5.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine5.Apttus_Config2__NetAdjustmentPercent__c = -10;
            bundleLine5.Apttus_Config2__ParentBundleNumber__c = 1;
            
            bundleLine5.Apttus_Config2__OptionId__c = option2.Id;
            bundleLine5.Apttus_Config2__ProductId__c = option2.Id;
            bundleLine5.Apttus_Config2__ChargeType__c='eParcel Returns - Delivery Fee (per article)';

            insert bundleLine5;
            
            
            
               Apttus_Config2__LineItem__c bundleLine6 = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
            1, 'Product/Service', option6.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
            null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
           bundleLine6.Apttus_Config2__ConfigurationId__c=  prodconfig.id;
            bundleLine6.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine6.Apttus_Config2__NetPrice__c = 5225;
            bundleLine6.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine6.Apttus_Config2__NetAdjustmentPercent__c = -10;
            bundleLine6.Apttus_Config2__ParentBundleNumber__c = 1;
            bundleLine6.APT_Rate_Card_Key__c = '60992317';
            bundleLine6.Apttus_Config2__OptionId__c = option6.Id;
            bundleLine6.Apttus_Config2__ProductId__c = option6.Id;
            bundleLine6.Apttus_Config2__ChargeType__c='Parcel Post Call for Returns - Delivery Fee (per article)';

            insert bundleLine6;
            
            
                 Apttus_Config2__LineItem__c bundleLine7 = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
            1, 'Product/Service', option7.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
            null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
           bundleLine7.Apttus_Config2__ConfigurationId__c=  prodconfig.id;
            bundleLine7.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine7.Apttus_Config2__NetPrice__c = 5225;
            bundleLine7.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine7.Apttus_Config2__NetAdjustmentPercent__c = -10;
            bundleLine7.Apttus_Config2__ParentBundleNumber__c = 1;
            bundleLine7.APT_Rate_Card_Key__c = '60992317';
            bundleLine7.Apttus_Config2__OptionId__c = option7.Id;
            bundleLine7.Apttus_Config2__ProductId__c = option7.Id;
            bundleLine7.Apttus_Config2__ChargeType__c='Standard Price';

            insert bundleLine7;
            
            
                     Apttus_Config2__LineItem__c bundleLine8 = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
            1, 'Product/Service', option8.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
            null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
           bundleLine8.Apttus_Config2__ConfigurationId__c=  prodconfig.id;
            bundleLine8.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine8.Apttus_Config2__NetPrice__c = 5225;
            bundleLine8.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine8.Apttus_Config2__NetAdjustmentPercent__c = -10;
            bundleLine8.Apttus_Config2__ParentBundleNumber__c = 1;
            bundleLine8.APT_Rate_Card_Key__c = '60992317';
            bundleLine8.Apttus_Config2__OptionId__c = option8.Id;
            bundleLine8.Apttus_Config2__ProductId__c = option8.Id;
            bundleLine8.Apttus_Config2__ChargeType__c='Standard Price';

            insert bundleLine8;
            
            
            
            
                     Apttus_Config2__LineItem__c bundleLine9 = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
            1, 'Product/Service', option9.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
            null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
           bundleLine9.Apttus_Config2__ConfigurationId__c=  prodconfig.id;
            bundleLine9.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine9.Apttus_Config2__NetPrice__c = 5225;
            bundleLine9.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine9.Apttus_Config2__NetAdjustmentPercent__c = -10;
            bundleLine9.Apttus_Config2__ParentBundleNumber__c = 1;
            bundleLine9.APT_Rate_Card_Key__c = '60992317';
            bundleLine9.Apttus_Config2__OptionId__c = option9.Id;
            bundleLine9.Apttus_Config2__ProductId__c = option9.Id;
            bundleLine9.Apttus_Config2__ChargeType__c='Standard Price';

            insert bundleLine9;
            
            
            
            
                     Apttus_Config2__LineItem__c bundleLine10 = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
            1, 'Product/Service', option10.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
            null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
           bundleLine10.Apttus_Config2__ConfigurationId__c=  prodconfig.id;
            bundleLine10.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine10.Apttus_Config2__NetPrice__c = 5225;
            bundleLine10.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine10.Apttus_Config2__NetAdjustmentPercent__c = -10;
            bundleLine10.Apttus_Config2__ParentBundleNumber__c = 1;
            
            bundleLine10.Apttus_Config2__OptionId__c = option10.Id;
            bundleLine10.Apttus_Config2__ProductId__c = option10.Id;
            bundleLine10.Apttus_Config2__ChargeType__c='Standard Price';

            insert bundleLine10;
            
            //system.debug('bundleLine2[0].APT_Rate_Card_Key__c1---->'+bundleLine1.APT_Rate_Card_Key__c);
             Apttus_Config2__ProductAttributeValue__c attriObj11 = new Apttus_Config2__ProductAttributeValue__c(Apttus_Config2__LineItemId__c =bundleLine13.ID,APT_PostBillPay_Gross_Settlement_fee__c = 'Yes',APT_Band__c='BAND 3');
        insert attriObj11;
          
            
            Apttus_Config2__ProductAttributeValue__c attriObj1 = new Apttus_Config2__ProductAttributeValue__c(Apttus_Config2__LineItemId__c =bundleLine3.ID,APT_PostBillPay_Gross_Settlement_fee__c = 'Yes',APT_Band__c='BAND 3');
        insert attriObj1;
        bundleLine13.Apttus_Config2__AttributeValueId__c = attriObj11.ID;
         
        bundleLine3.Apttus_Config2__AttributeValueId__c = attriObj1.ID;
        bundleLine5.Apttus_Config2__AttributeValueId__c = attriObj1.id;
                bundleLine6.Apttus_Config2__AttributeValueId__c = attriObj1.id;
                                bundleLine7.Apttus_Config2__AttributeValueId__c = attriObj1.id;
                                bundleLine8.Apttus_Config2__AttributeValueId__c = attriObj1.id;
                                bundleLine9.Apttus_Config2__AttributeValueId__c = attriObj1.id;
                                                                bundleLine10.Apttus_Config2__AttributeValueId__c = attriObj1.id;


        update bundleLine9;
        update bundleLine10;
        update bundleLine13; 
        update bundleLine3;
        update bundleLine5;
        update bundleLine6;

        update bundleLine7;
        update bundleLine8;

        system.debug('pro.product--->'+bundle2.Id);

        
        product2 pro= [select id,ProductCode from product2 where id=:bundleLine1.Apttus_Config2__ProductId__c];
        
system.debug('pro.product--->'+bundle2.Id);

            
            
            
            //create price list
            Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
            insert testPriceList;
            
            //create R2T System Properties
            APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
            r2tSystemProperties.APT_Org_Id_Service_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_CompanyCreditAssessmentEndPointURL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_INDV_Credit_Assessment_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_Query_Rate_Card_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            
            insert r2tSystemProperties;
            
            APT_Domestic_Price_Data__c domesticPriceData = APT_TestUtils.createDomesticPriceData(bundleLine.Apttus_Config2__AttributeValueId__r.Category__c,'Express',bundleLine.Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone_Code__c,'ZONE2','Sydney'
            ,bundleLine.Apttus_Config2__AttributeValueId__r.APTS_Price_Structure__c,0.50,'up to 500g',7,0,0);
             APT_Domestic_Price_Data__c domesticPriceData1 = APT_TestUtils.createDomesticPriceData(bundleLine.Apttus_Config2__AttributeValueId__r.Category__c,'Express',bundleLine.Apttus_Config2__AttributeValueId__r.APT_Lodgement_Zone_Code__c,'ZONE2','Sydney'
            ,bundleLine.Apttus_Config2__AttributeValueId__r.APTS_Price_Structure__c,1.00,'501g to 1kg',7,0,0);
            List<APT_Domestic_Price_Data__c> domesticPriceDataList = new List<APT_Domestic_Price_Data__c>{domesticPriceData,domesticPriceData1};
            insert domesticPriceDataList;
            //Test.startTest();
           // APT_SAP_CustomerContractService.ExternalCustomerContractServices_v1HTTPEndpoint1 endPoint = new APT_SAP_CustomerContractService.ExternalCustomerContractServices_v1HTTPEndpoint1();
            
            // endPoint.inputHttpHeaders_x  = APT_WebServiceUtility.getinputHttpHeaders() ;
            // endPoint.Header = APT_WebServiceUtility.getqueryRateCardInterfaceHeader(APT_WebServiceUtility.INTERFACE_NAME_QUERYRATECARDS);
            // endpoint.timeout_x = APT_WebServiceUtility.DEFAULT_WEBSERVICE_TIMEOUT;
            
            // APT_R2T_System_Properties__c r2tSystemProperty = APT_R2T_System_Properties__c.getOrgDefaults();
            // if(r2tSystemProperty != null && r2tSystemProperty.APT_Query_Rate_Card_End_Point_URL__c != null) {
            //     endPoint.endpoint_x = r2tSystemProperty.APT_Query_Rate_Card_End_Point_URL__c;
            // } 
            
            // APT_SAP_QueryRateCardService.Ratecards_element response = endPoint.queryRatecards_v1(bundleLine.APT_Rate_Card_Key__c);
            
            APT_SAP_QueryRateCardService.CreationType CreationType=new APT_SAP_QueryRateCardService.CreationType();
            CreationType.Timestamp=datetime.ValueOf('1968-09-21 02:16:42');
           CreationType.DayId=20160125.0;
           CreationType.MonthId=201601.0;
            CreationType.UserId='MOLONEYK';
            CreationType.UserLevel='1';
            CreationType.ToolName='YIELD_TOOL_APP';
            CreationType.UploadType='User';
            
            APT_SAP_QueryRateCardService.ApprovalDetails ApprovalDetails=new APT_SAP_QueryRateCardService.ApprovalDetails();
            
            ApprovalDetails.Flag='';
            ApprovalDetails.Timestamp=datetime.ValueOf('1968-09-21 02:16:42');
            ApprovalDetails.UserId='MOLONEYK';
            
            APT_SAP_QueryRateCardService.ExtractDetails ExtractDetails=new APT_SAP_QueryRateCardService.ExtractDetails ();
            ExtractDetails.Flag='';
            ExtractDetails.Timestamp=datetime.ValueOf('1968-09-21 02:16:42');
            ExtractDetails.UserId='MOLONEYK';
            ExtractDetails.ApprovalDetails=ApprovalDetails;

 
 
 APT_SAP_QueryRateCardService.StatusDetails StatusDetails=new APT_SAP_QueryRateCardService.StatusDetails();
 StatusDetails.Type_x='DOMESTIC';
 StatusDetails.Timestamp=datetime.ValueOf('1968-09-21 02:16:42');

 APT_SAP_QueryRateCardService.CustomerPricingDetailsType CustomerPricingDetailsType =new APT_SAP_QueryRateCardService.CustomerPricingDetailsType();
 
     CustomerPricingDetailsType.Domestic='No';
     CustomerPricingDetailsType.IndustrySegment='Books / Print Material';
     CustomerPricingDetailsType.InternationalLetters='YES';
     CustomerPricingDetailsType.EparcelLodgement='YES';
     CustomerPricingDetailsType.VolumeAvailable='YES';
     
     APT_SAP_QueryRateCardService.TransitCoverDetailsType  TransitCoverDetails=new APT_SAP_QueryRateCardService.TransitCoverDetailsType ();
     TransitCoverDetails.MinimumTransitCover=10.0;
     TransitCoverDetails.MaximumTransitCover=11.2;
     TransitCoverDetails.Percentage=11.2;
     
     
     APT_SAP_QueryRateCardService.FeaturesDetailsType FeaturesDetailsType=new APT_SAP_QueryRateCardService.FeaturesDetailsType();
     FeaturesDetailsType.TransitCoverDetails=TransitCoverDetails;
       FeaturesDetailsType.ReturnsPercentageAnnualVolume=3.0;
     FeaturesDetailsType.UpTo500GTotalReturnsVolume=10.0;
     FeaturesDetailsType.AverageChargeableWeight=11.3;
     FeaturesDetailsType.EparcelReturnsDeliveryFee=100.3;
     FeaturesDetailsType.ParcelPostReturnsDeliveryFee=120.5;
     FeaturesDetailsType.ParcelPostReturnsPickupFee=159.4;
     FeaturesDetailsType.ReturnPaidUpTo500GParcelPostFee=200.2;
     FeaturesDetailsType.ReturnPaidOver500GParcelPostFee=30.3;
     FeaturesDetailsType.ReturnPaidAnnualFee=122.3;
     FeaturesDetailsType.IdentityDeliveryFee=150.5;
     
     APT_SAP_QueryRateCardService.StandardChargesType StandardChargesType=new APT_SAP_QueryRateCardService.StandardChargesType();
     
    StandardChargesType.InternationalAdminFee=45.45;
   StandardChargesType.CollectionFee=37.27;
   
   APT_SAP_QueryRateCardService.CurrentPricingDetailsType CurrentPricingDetailsType =new APT_SAP_QueryRateCardService.CurrentPricingDetailsType ();
   
    CurrentPricingDetailsType.LodgementZoneCode='AU';
    CurrentPricingDetailsType.ChargeCode='SINTB017';
    
    APT_SAP_QueryRateCardService.NewPricingDetailsType NewPricingDetailsType =new APT_SAP_QueryRateCardService.NewPricingDetailsType ();
    NewPricingDetailsType.LodgementZoneCode='AU';
    NewPricingDetailsType.PriceZoneStructure='Abc';
    NewPricingDetailsType.Category='Num';
   
     APT_SAP_QueryRateCardService.MaxWeightBreak_element MaxWeightBreak_element=new APT_SAP_QueryRateCardService.MaxWeightBreak_element();
    
    
    
    APT_SAP_QueryRateCardService.FlatRatesDetailsType  FlatRatesDetailsType =new APT_SAP_QueryRateCardService.FlatRatesDetailsType ();
    FlatRatesDetailsType.DispersionType='DEFAULT';
    FlatRatesDetailsType.MaxWeightBreak=MaxWeightBreak_element;
    
    
    APT_SAP_QueryRateCardService.BandRateDetailsType BandRateDetailsType =new APT_SAP_QueryRateCardService.BandRateDetailsType ();
    BandRateDetailsType.Band='BAND_3';
    BandRateDetailsType.RevenueEstimation=12983.35;
    BandRateDetailsType.RevenueRange='5000 - 19999';
    
   APT_SAP_QueryRateCardService.ExpressCourierRates_element ExpressCourierRates_element=new APT_SAP_QueryRateCardService.ExpressCourierRates_element();
   ExpressCourierRates_element.UpTo2KGPerItem=12.0;
ExpressCourierRates_element.UpTo2KGPerKG=0.0;
ExpressCourierRates_element.Over2KGPerKG=2.4;

APT_SAP_QueryRateCardService.UKRatesDetailsType UKRatesDetailsType =new APT_SAP_QueryRateCardService.UKRatesDetailsType ();

UKRatesDetailsType.ExpressCourierRates=ExpressCourierRates_element;

APT_SAP_QueryRateCardService.AirmailRates_element AirmailRates_element =new APT_SAP_QueryRateCardService.AirmailRates_element ();
AirmailRates_element.UpTo2KGPerItem=12.0;
AirmailRates_element.UpTo2KGPerKG=0.0;
AirmailRates_element.Over2KGPerItem=10.5;
AirmailRates_element.Over2KGPerKG=2.7;



APT_SAP_QueryRateCardService.NewZealandRatesDetailsType NewZealandRatesDetailsType =new APT_SAP_QueryRateCardService.NewZealandRatesDetailsType ();
NewZealandRatesDetailsType.AirmailRates=AirmailRates_element;
NewZealandRatesDetailsType.ExpressCourierRates  =ExpressCourierRates_element;

APT_SAP_QueryRateCardService.Comments_element Comments_element =new APT_SAP_QueryRateCardService.Comments_element ();
 
 list<APT_SAP_QueryRateCardService.RateType> RateTypeList=new list<APT_SAP_QueryRateCardService.RateType>();
 
 APT_SAP_QueryRateCardService.RateType RateType =new APT_SAP_QueryRateCardService.RateType ();
 
RateType.DestinationZoneCode='ZONE2';
RateType.WeightRangeCode=0.5;
RateType.RAFCode='I01';
RateType.LookupFull='AIRLET_ZONE2';
RateType.SubsequentRate=1.23;
RateType.PerKgRate=17.6;
RateType.BaseRate=0.8;
RateTypeList.add(RateType);

map<string,set<decimal>> mapWeightCode = new map<String , set<decimal>>();

set<decimal> setweight=new set<decimal>();
setweight.add(0.50);

mapWeightCode.put('N1',setweight);




    APT_SAP_QueryRateCardService.RatesDetails_element RatesDetails_element =new APT_SAP_QueryRateCardService.RatesDetails_element ();
    RatesDetails_element.Rate=RateTypeList;
    
    APT_SAP_QueryRateCardService.RatecardContractDetailsType RatecardContractDetailsType =new APT_SAP_QueryRateCardService.RatecardContractDetailsType ();
    RatecardContractDetailsType.SubProductName='eParcelExpress';
    
    list<APT_SAP_QueryRateCardService.RateCardType> rateCardTypeList=new list<APT_SAP_QueryRateCardService.RateCardType>();
            APT_SAP_QueryRateCardService.RateCardType  rateCardType=new APT_SAP_QueryRateCardService.RateCardType();
            rateCardType.RateCardKey='20000128';
            rateCardType.PrecedingRateCardKey='';
            RateCardType.Type_x='DOMESTIC';
            RateCardType.ScenarioType='INTERNATIONAL_NEW_BPA';
            rateCardType.QuoteNumber='';
            rateCardType.ServiceTypeFlag='';
            rateCardType.ServiceType='';
            rateCardType.SignatureFlag='';
            rateCardType.CreationDetails=CreationType;
            rateCardType.StatusDetails =StatusDetails;
           rateCardType.ExtractDetails  =ExtractDetails;
           rateCardType.CustomerPricingDetails =CustomerPricingDetailsType;
          rateCardType.FeaturesDetails = FeaturesDetailsType;
          rateCardType.StandardCharges=StandardChargesType;
          rateCardType.CurrentPricingDetails = CurrentPricingDetailsType;
          rateCardType.NewPricingDetails=    NewPricingDetailsType;
          rateCardType.FlatRatesDetails=FlatRatesDetailsType;
       rateCardType.BandRateDetails=   BandRateDetailsType;
    rateCardType.UKRatesDetails = UKRatesDetailsType;
    
   rateCardType.NewZealandRatesDetails  =NewZealandRatesDetailsType;
   rateCardType.Comments=Comments_element;
   rateCardType.RatesDetails=RatesDetails_element;
   rateCardType.ContractDetails =    RatecardContractDetailsType;
   
         rateCardTypeList.add(rateCardType);   
            
            APT_SAP_QueryRateCardService.Ratecards_element  ratecards=new APT_SAP_QueryRateCardService.Ratecards_element();
           ratecards.Ratecard=rateCardTypeList;
           // Test.stopTest();
        
       
        
        
            
            PageReference pageRef = Page.APT_GetRenewalRates;
            Test.setCurrentPage(pageRef);
            
            Apexpages.currentPage().getHeaders().put('Referer', 'Page.APT_GetRenewalRates');
            Apexpages.currentPage().getParameters().put('selectedRecordID', bundleLine3.ID);
            Apexpages.currentPage().getParameters().put('selectedRecordID', bundleLine13.ID);

            Test.StartTest();
            Test.setMock(WebServiceMock.class, new APT_WebserviceMockCustomerContract());
            
            
            APT_GetRenewalRatesController grrc = new APT_GetRenewalRatesController();
            grrc.lineItemId=bundleLine3.id;

            system.debug('bundleLine2productcode------>'+bundleLine3.Apttus_Config2__ProductId__c);
            
                   id proNewId= bundleLine2[0].Apttus_Config2__ProductId__c;
          product2 proNow= [select id,ProductCode from product2 where id=:proNewId];
          
                      system.debug('bundleLine2[0].ProNopw---->'+bundle2.Id);
                      
                      
            APT_GetRenewalRatesController.updateConfig(ratecards,bundleLine3);
            APT_GetRenewalRatesController.updateConfig(ratecards,bundleLine13);

            grrc.UpdateConfigandRates();
            APT_GetRenewalRatesController.parseQueryRateCardResponse(ratecards,bundleLine3);
                     // list<APT_SAP_QueryRateCardService.RateType> listSortedRates =  APT_GetRenewalRatesController.sortRates(rateCardType,setDestinationZoneCode,mapWeightCode);
            
        //  APT_GetRenewalRatesController.parseDomesticRateCard(listSortedRates,bundleLine3);
            
            grrc.warningpopup();
            grrc.goBack();
            grrc.goBck();
            grrc.doGetRenewalRates();
            grrc.listLineItem=bundleLine2;
            Apexpages.currentPage().getParameters().put('selectedRecordID', null);
            //Test.StartTest();
            APT_GetRenewalRatesController grrc1 = new APT_GetRenewalRatesController();
            grrc1.doGetRenewalRates();
            Apexpages.currentPage().getParameters().put('selectedRecordID', bundleLine1.ID);
            //Test.StartTest();
            APT_GetRenewalRatesController grrc12 = new APT_GetRenewalRatesController();
            grrc12.doGetRenewalRates();
            string configID = bundleLine10.Apttus_Config2__ConfigurationId__c;
            system.debug('configID------->'+configID);
            //APT_GetRenewalRatesController grrc13 = new APT_GetRenewalRatesController();
            
            Test.StopTest();
            //system.assert(pageRef!=null);
            //Test.StopTest();
        }
    }
    
     private static TestMethod void TestMethodDomesticCONFIG() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {      
            //Create Account
            Account acc = APT_TestUtils.createOrganisation();
            acc.Type = 'Charge Account + Sub Account';
            acc.ACN__c = '123456789';
            acc.LEGACY_ID__c = '60992317';
            insert acc;
            acc.LEGACY_ID__c = '60992317';
            Update acc;
            
            APT_Charge_Account__c cacc = new APT_Charge_Account__c();
            cacc.APT_Industry_Type__c = 'CTTT';
            insert cacc;
            
            //Create Opportunity
            Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
            opty.Amount = 100;
            insert opty;
            
            //Create PriceList
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            //create international product
            Product2 bundle1 = APT_TestUtils.createInternationalProduct('International Bundle','InternationalBundle','Parcel Services');
            insert bundle1;
            
            Product2 option1 = new Product2();
            option1.Name = 'CAT1 Standard';
            option1.Apttus_Config2__ConfigurationType__c = 'Option';
            option1.APT_Category__c = 'CAT1';
            option1.APT_Network_Type__c = 'Standard';
            insert option1;
            
            
            
            //Create Price list Item
            Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,null,null);
            insert pli;
            
            //Create Proposal
            Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
            Proposal.Apttus_Proposal__Account__c = acc.ID;
            insert Proposal;
            
            //Create Product Configuration             
            Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
            proposal.Id, 'Proposal',
            'Ad Hoc',priceList.Id, null,
            'Ready For Finalization',
            null, Datetime.now(), true);
            insert prodconfig;
            
        //     // Create LineItem
             list<Apttus_Config2__LineItem__c> appConLineList1=new list<Apttus_Config2__LineItem__c>();
            Apttus_Config2__LineItem__c bundleLine1 = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
            1, 'Product/Service', bundle1.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
            null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            bundleLine1.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine1.Apttus_Config2__NetPrice__c = 5225;
            bundleLine1.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine1.Apttus_Config2__NetAdjustmentPercent__c = -10;
            bundleLine1.Apttus_Config2__ParentBundleNumber__c = 1;
            bundleLine1.Apttus_Config2__OptionId__c = option1.Id;
            //insert bundleLine;
           bundleLine1.APT_RC_Key__c='20000128';

            appConLineList1.add(bundleLine1);
            insert appConLineList1;
            
            
                        
              Apttus_Config2__ProductAttributeValue__c attriObj11 = new Apttus_Config2__ProductAttributeValue__c(Apttus_Config2__LineItemId__c =appConLineList1[0].ID,APT_PostBillPay_Gross_Settlement_fee__c = 'Yes');
        insert attriObj11;
        
        appConLineList1[0].Apttus_Config2__AttributeValueId__c = attriObj11.ID;
        update appConLineList1;
            
            
               list<Apttus_Config2__LineItem__c> bundleLine3=new list<Apttus_Config2__LineItem__c>();
            
            Apttus_Config2__LineItem__c bundleLine4 = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
            1, 'Product/Service', bundle1.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
            null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
           bundleLine4.Apttus_Config2__ConfigurationId__c=  prodconfig.id;
            bundleLine4.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine4.Apttus_Config2__NetPrice__c = 5225;
            bundleLine4.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine4.Apttus_Config2__NetAdjustmentPercent__c = -10;
            bundleLine4.Apttus_Config2__ParentBundleNumber__c = 1;
            bundleLine4.Apttus_Config2__OptionId__c = option1.Id;
           // bundleLine4.Apttus_Config2__ProductId__c = option1.Id;
            
           bundleLine4.APT_RC_Key__c='20000128';

            bundleLine3.add(bundleLine4);
            insert bundleLine3;
            
            system.debug('bundleLine2[0].APT_Rate_Card_Key__c1---->'+bundleLine1.APT_Rate_Card_Key__c);
              Apttus_Config2__ProductAttributeValue__c attriObj1 = new Apttus_Config2__ProductAttributeValue__c(Apttus_Config2__LineItemId__c =bundleLine3[0].ID,APT_PostBillPay_Gross_Settlement_fee__c = 'Yes');
        insert attriObj1;
        
        bundleLine3[0].Apttus_Config2__AttributeValueId__c = attriObj1.ID;
        update bundleLine3;
            
        APT_SAP_QueryRateCardService.CreationType CreationType=new APT_SAP_QueryRateCardService.CreationType();
            CreationType.Timestamp=datetime.ValueOf('1968-09-21 02:16:42');
           CreationType.DayId=20160125.0;
           CreationType.MonthId=201601.0;
            CreationType.UserId='MOLONEYK';
            CreationType.UserLevel='1';
            CreationType.ToolName='YIELD_TOOL_APP';
            CreationType.UploadType='User';
            
            APT_SAP_QueryRateCardService.ApprovalDetails ApprovalDetails=new APT_SAP_QueryRateCardService.ApprovalDetails();
            
            ApprovalDetails.Flag='';
            ApprovalDetails.Timestamp=datetime.ValueOf('1968-09-21 02:16:42');
            ApprovalDetails.UserId='MOLONEYK';
            
            APT_SAP_QueryRateCardService.ExtractDetails ExtractDetails=new APT_SAP_QueryRateCardService.ExtractDetails ();
            ExtractDetails.Flag='';
            ExtractDetails.Timestamp=datetime.ValueOf('1968-09-21 02:16:42');
            ExtractDetails.UserId='MOLONEYK';
            ExtractDetails.ApprovalDetails=ApprovalDetails;

 
 
 APT_SAP_QueryRateCardService.StatusDetails StatusDetails=new APT_SAP_QueryRateCardService.StatusDetails();
 StatusDetails.Type_x='INTERNATIONAL';
 StatusDetails.Timestamp=datetime.ValueOf('1968-09-21 02:16:42');

 APT_SAP_QueryRateCardService.CustomerPricingDetailsType CustomerPricingDetailsType =new APT_SAP_QueryRateCardService.CustomerPricingDetailsType();
 
     CustomerPricingDetailsType.Domestic='No';
     CustomerPricingDetailsType.IndustrySegment='Books / Print Material';
     CustomerPricingDetailsType.InternationalLetters='YES';
     CustomerPricingDetailsType.EparcelLodgement='YES';
     CustomerPricingDetailsType.VolumeAvailable='YES';
     
     APT_SAP_QueryRateCardService.TransitCoverDetailsType  TransitCoverDetails=new APT_SAP_QueryRateCardService.TransitCoverDetailsType ();
     TransitCoverDetails.MinimumTransitCover=10.0;
     TransitCoverDetails.MaximumTransitCover=11.2;
     TransitCoverDetails.Percentage=11.2;
     
     
     APT_SAP_QueryRateCardService.FeaturesDetailsType FeaturesDetailsType=new APT_SAP_QueryRateCardService.FeaturesDetailsType();
     FeaturesDetailsType.TransitCoverDetails=TransitCoverDetails;
       FeaturesDetailsType.ReturnsPercentageAnnualVolume=3.0;
     FeaturesDetailsType.UpTo500GTotalReturnsVolume=10.0;
     FeaturesDetailsType.AverageChargeableWeight=11.3;
     FeaturesDetailsType.EparcelReturnsDeliveryFee=100.3;
     FeaturesDetailsType.ParcelPostReturnsDeliveryFee=120.5;
     FeaturesDetailsType.ParcelPostReturnsPickupFee=159.4;
     FeaturesDetailsType.ReturnPaidUpTo500GParcelPostFee=200.2;
     FeaturesDetailsType.ReturnPaidOver500GParcelPostFee=30.3;
     FeaturesDetailsType.ReturnPaidAnnualFee=122.3;
     FeaturesDetailsType.IdentityDeliveryFee=150.5;
     
     APT_SAP_QueryRateCardService.StandardChargesType StandardChargesType=new APT_SAP_QueryRateCardService.StandardChargesType();
     
    StandardChargesType.InternationalAdminFee=45.45;
   StandardChargesType.CollectionFee=37.27;
   
   APT_SAP_QueryRateCardService.CurrentPricingDetailsType CurrentPricingDetailsType =new APT_SAP_QueryRateCardService.CurrentPricingDetailsType ();
   
    CurrentPricingDetailsType.LodgementZoneCode='AU';
    CurrentPricingDetailsType.ChargeCode='SINTB017';
    
    APT_SAP_QueryRateCardService.NewPricingDetailsType NewPricingDetailsType =new APT_SAP_QueryRateCardService.NewPricingDetailsType ();
    NewPricingDetailsType.LodgementZoneCode='AU';
    NewPricingDetailsType.PriceZoneStructure='Abc';
    NewPricingDetailsType.Category='Num';
   
     APT_SAP_QueryRateCardService.MaxWeightBreak_element MaxWeightBreak_element=new APT_SAP_QueryRateCardService.MaxWeightBreak_element();
    
    
    
    APT_SAP_QueryRateCardService.FlatRatesDetailsType  FlatRatesDetailsType =new APT_SAP_QueryRateCardService.FlatRatesDetailsType ();
    FlatRatesDetailsType.DispersionType='DEFAULT';
    FlatRatesDetailsType.MaxWeightBreak=MaxWeightBreak_element;
    
    
    APT_SAP_QueryRateCardService.BandRateDetailsType BandRateDetailsType =new APT_SAP_QueryRateCardService.BandRateDetailsType ();
    BandRateDetailsType.Band='BAND_3';
    BandRateDetailsType.RevenueEstimation=12983.35;
    BandRateDetailsType.RevenueRange='5000 - 19999';
    
   APT_SAP_QueryRateCardService.ExpressCourierRates_element ExpressCourierRates_element=new APT_SAP_QueryRateCardService.ExpressCourierRates_element();
   ExpressCourierRates_element.UpTo2KGPerItem=12.0;
ExpressCourierRates_element.UpTo2KGPerKG=0.0;
ExpressCourierRates_element.Over2KGPerKG=2.4;

APT_SAP_QueryRateCardService.UKRatesDetailsType UKRatesDetailsType =new APT_SAP_QueryRateCardService.UKRatesDetailsType ();

UKRatesDetailsType.ExpressCourierRates=ExpressCourierRates_element;

APT_SAP_QueryRateCardService.AirmailRates_element AirmailRates_element =new APT_SAP_QueryRateCardService.AirmailRates_element ();
AirmailRates_element.UpTo2KGPerItem=12.0;
AirmailRates_element.UpTo2KGPerKG=0.0;
AirmailRates_element.Over2KGPerItem=10.5;
AirmailRates_element.Over2KGPerKG=2.7;



APT_SAP_QueryRateCardService.NewZealandRatesDetailsType NewZealandRatesDetailsType =new APT_SAP_QueryRateCardService.NewZealandRatesDetailsType ();
NewZealandRatesDetailsType.AirmailRates=AirmailRates_element;
NewZealandRatesDetailsType.ExpressCourierRates  =ExpressCourierRates_element;

APT_SAP_QueryRateCardService.Comments_element Comments_element =new APT_SAP_QueryRateCardService.Comments_element ();
 
 list<APT_SAP_QueryRateCardService.RateType> RateTypeList=new list<APT_SAP_QueryRateCardService.RateType>();
 
 APT_SAP_QueryRateCardService.RateType RateType =new APT_SAP_QueryRateCardService.RateType ();
 
RateType.DestinationZoneCode='ZONE2';
RateType.WeightRangeCode=0.5;
RateType.RAFCode='I01';
RateType.LookupFull='AIRLET_ZONE2';
RateType.SubsequentRate=1.23;
RateType.PerKgRate=17.6;
RateType.BaseRate=0.8;

RateTypeList.add(RateType);

           
map<string,set<decimal>> mapWeightCode = new map<String , set<decimal>>();

set<decimal> setweight=new set<decimal>();
setweight.add(0.50);

mapWeightCode.put('N1',setweight);




    APT_SAP_QueryRateCardService.RatesDetails_element RatesDetails_element =new APT_SAP_QueryRateCardService.RatesDetails_element ();
    RatesDetails_element.Rate=RateTypeList;
    
    APT_SAP_QueryRateCardService.RatecardContractDetailsType RatecardContractDetailsType =new APT_SAP_QueryRateCardService.RatecardContractDetailsType ();
    RatecardContractDetailsType.SubProductName='eParcelExpress';
    
    list<APT_SAP_QueryRateCardService.RateCardType> rateCardTypeList=new list<APT_SAP_QueryRateCardService.RateCardType>();
            APT_SAP_QueryRateCardService.RateCardType  rateCardType=new APT_SAP_QueryRateCardService.RateCardType();
            rateCardType.RateCardKey='20000128';
            rateCardType.PrecedingRateCardKey='';
            RateCardType.Type_x='INTERNATIONAL';
            RateCardType.ScenarioType='INTERNATIONAL_NEW_BPA';
            rateCardType.QuoteNumber='';
            rateCardType.ServiceTypeFlag='';
            rateCardType.ServiceType='';
            rateCardType.SignatureFlag='';
            rateCardType.CreationDetails=CreationType;
            rateCardType.StatusDetails =StatusDetails;
           rateCardType.ExtractDetails  =ExtractDetails;
           rateCardType.CustomerPricingDetails =CustomerPricingDetailsType;
          rateCardType.FeaturesDetails = FeaturesDetailsType;
          rateCardType.StandardCharges=StandardChargesType;
          rateCardType.CurrentPricingDetails = CurrentPricingDetailsType;
          rateCardType.NewPricingDetails=    NewPricingDetailsType;
          rateCardType.FlatRatesDetails=FlatRatesDetailsType;
       rateCardType.BandRateDetails=   BandRateDetailsType;
    rateCardType.UKRatesDetails = UKRatesDetailsType;
    
   rateCardType.NewZealandRatesDetails  =NewZealandRatesDetailsType;
   rateCardType.Comments=Comments_element;
   rateCardType.RatesDetails=RatesDetails_element;
   rateCardType.ContractDetails =    RatecardContractDetailsType;
   
         rateCardTypeList.add(rateCardType);   
            
            APT_SAP_QueryRateCardService.Ratecards_element  ratecards=new APT_SAP_QueryRateCardService.Ratecards_element();
           ratecards.Ratecard=rateCardTypeList;
           // Test.stopTest();
        
       
        system.debug('bundleLine3[0].id---->'+bundleLine3[0].id);
        
                system.debug('appConLineList1.id---->'+appConLineList1[0].id);

        
            
            PageReference pageRef = Page.APT_GetRenewalRates;
            Test.setCurrentPage(pageRef);
            
            Apexpages.currentPage().getHeaders().put('Referer', 'Page.APT_GetRenewalRates');
            Apexpages.currentPage().getParameters().put('selectedRecordID', bundleLine3[0].ID);
        
            
            APT_GetRenewalRatesController grrc = new APT_GetRenewalRatesController();
                        grrc.lineItemId=bundleLine3[0].id;


            
            
            APT_GetRenewalRatesController.updateConfig(ratecards,bundleLine3[0]);
            APT_GetRenewalRatesController.blnTestClass = true;
            grrc.warningpopup();
                       grrc.UpdateConfigandRates();
 
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
//             Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
//             1, 'Product/Service', bundle1.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
//             null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
//             'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
//             'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
//             true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
//             5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc]
//             bundleLine.Apttus_Config2__AllowManualAdjustment__c = true;
//             bundleLine.Apttus_Config2__NetPrice__c = 5225;
//             bundleLine.Apttus_Config2__PrimaryLineNumber__c = 1;
//             bundleLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
//             bundleLine.Apttus_Config2__ParentBundleNumber__c = 1;
//             bundleLine.APT_Rate_Card_Key__c = '10012882';
//             bundleLine.Apttus_Config2__OptionId__c = option1.Id;
//                         bundleLine.APT_RC_Key__c='20000128';

//             insert bundleLine;
//             system.debug('bundleLine.APT_Rate_Card_Key__c1---->'+bundleLine.APT_Rate_Card_Key__c);
//               Apttus_Config2__ProductAttributeValue__c attriObj = new Apttus_Config2__ProductAttributeValue__c(Apttus_Config2__LineItemId__c =bundleLine.ID,APT_PostBillPay_Gross_Settlement_fee__c = 'Yes');
//         insert attriObj;
        
//         bundleLine.Apttus_Config2__AttributeValueId__c = attriObj.ID;
//         update bundleLine;
//             system.debug('bundleLine.APT_Rate_Card_Key__c2---->'+bundleLine.APT_Rate_Card_Key__c);
//           /*  APT_SAP_CustomerContractService.ExternalCustomerContractServices_v1HTTPEndpoint1 endPoint = new APT_SAP_CustomerContractService.ExternalCustomerContractServices_v1HTTPEndpoint1();
            
//             endPoint.inputHttpHeaders_x  = APT_WebServiceUtility.getinputHttpHeaders() ;
//             endPoint.Header = APT_WebServiceUtility.getqueryRateCardInterfaceHeader(APT_WebServiceUtility.INTERFACE_NAME_QUERYRATECARDS);
//             endpoint.timeout_x = APT_WebServiceUtility.DEFAULT_WEBSERVICE_TIMEOUT;
            
//             APT_R2T_System_Properties__c r2tSystemProperty = APT_R2T_System_Properties__c.getOrgDefaults();
//             if(r2tSystemProperty != null && r2tSystemProperty.APT_Query_Rate_Card_End_Point_URL__c != null) {
//                 endPoint.endpoint_x = r2tSystemProperty.APT_Query_Rate_Card_End_Point_URL__c;
//             } 
            
//             APT_SAP_QueryRateCardService.Ratecards_element response = endPoint.queryRatecards_v1(bundleLine.APT_Rate_Card_Key__c);*/
//             APT_GetRenewalRatesController var = new APT_GetRenewalRatesController();
            
            
//             //var.UpdateConfigandRates();
            
           
            
//             Pagereference result1 = var.UpdateConfigandRates();
//             system.assertEquals(null,result1);
            
            
//             APT_SAP_QueryRateCardService.CreationType CreationType=new APT_SAP_QueryRateCardService.CreationType();
//             CreationType.Timestamp=datetime.ValueOf('1968-09-21 02:16:42');
//           CreationType.DayId=20160125.0;
//           CreationType.MonthId=201601.0;
//             CreationType.UserId='MOLONEYK';
//             CreationType.UserLevel='1';
//             CreationType.ToolName='YIELD_TOOL_APP';
//             CreationType.UploadType='User';
            
//             APT_SAP_QueryRateCardService.ApprovalDetails ApprovalDetails=new APT_SAP_QueryRateCardService.ApprovalDetails();
            
//             ApprovalDetails.Flag='';
//             ApprovalDetails.Timestamp=datetime.ValueOf('1968-09-21 02:16:42');
//             ApprovalDetails.UserId='MOLONEYK';
            
//             APT_SAP_QueryRateCardService.ExtractDetails ExtractDetails=new APT_SAP_QueryRateCardService.ExtractDetails ();
//             ExtractDetails.Flag='';
//             ExtractDetails.Timestamp=datetime.ValueOf('1968-09-21 02:16:42');
//             ExtractDetails.UserId='MOLONEYK';
//             ExtractDetails.ApprovalDetails=ApprovalDetails;

 
 
//  APT_SAP_QueryRateCardService.StatusDetails StatusDetails=new APT_SAP_QueryRateCardService.StatusDetails();
//  StatusDetails.Type_x='FINAL';
//  StatusDetails.Timestamp=datetime.ValueOf('1968-09-21 02:16:42');

//  APT_SAP_QueryRateCardService.CustomerPricingDetailsType CustomerPricingDetailsType =new APT_SAP_QueryRateCardService.CustomerPricingDetailsType();
 
//      CustomerPricingDetailsType.Domestic='No';
//      CustomerPricingDetailsType.IndustrySegment='Books / Print Material';
//      CustomerPricingDetailsType.InternationalLetters='YES';
//      CustomerPricingDetailsType.EparcelLodgement='YES';
//      CustomerPricingDetailsType.VolumeAvailable='YES';
     
//      APT_SAP_QueryRateCardService.TransitCoverDetailsType  TransitCoverDetails=new APT_SAP_QueryRateCardService.TransitCoverDetailsType ();
//      TransitCoverDetails.MinimumTransitCover=10.0;
//      TransitCoverDetails.MaximumTransitCover=11.2;
//      TransitCoverDetails.Percentage=11.2;
     
     
//      APT_SAP_QueryRateCardService.FeaturesDetailsType FeaturesDetailsType=new APT_SAP_QueryRateCardService.FeaturesDetailsType();
//      FeaturesDetailsType.TransitCoverDetails=TransitCoverDetails;
//      FeaturesDetailsType.ReturnsPercentageAnnualVolume=3.0;
//      FeaturesDetailsType.UpTo500GTotalReturnsVolume=10.0;
//      FeaturesDetailsType.AverageChargeableWeight=11.3;
//      FeaturesDetailsType.EparcelReturnsDeliveryFee=100.3;
//      FeaturesDetailsType.ParcelPostReturnsDeliveryFee=120.5;
//      FeaturesDetailsType.ParcelPostReturnsPickupFee=159.4;
//      FeaturesDetailsType.ReturnPaidUpTo500GParcelPostFee=200.2;
//      FeaturesDetailsType.ReturnPaidOver500GParcelPostFee=30.3;
//      FeaturesDetailsType.ReturnPaidAnnualFee=122.3;
//      FeaturesDetailsType.IdentityDeliveryFee=150.5;
     
//      APT_SAP_QueryRateCardService.StandardChargesType StandardChargesType=new APT_SAP_QueryRateCardService.StandardChargesType();
     
//     StandardChargesType.InternationalAdminFee=45.45;
//   StandardChargesType.CollectionFee=37.27;
   
//   APT_SAP_QueryRateCardService.CurrentPricingDetailsType CurrentPricingDetailsType =new APT_SAP_QueryRateCardService.CurrentPricingDetailsType ();
   
//     CurrentPricingDetailsType.LodgementZoneCode='AU';
//     CurrentPricingDetailsType.ChargeCode='SINTB017';
    
//     APT_SAP_QueryRateCardService.NewPricingDetailsType NewPricingDetailsType =new APT_SAP_QueryRateCardService.NewPricingDetailsType ();
//     NewPricingDetailsType.LodgementZoneCode='AU';
   
//      APT_SAP_QueryRateCardService.MaxWeightBreak_element MaxWeightBreak_element=new APT_SAP_QueryRateCardService.MaxWeightBreak_element();
    
    
    
//     APT_SAP_QueryRateCardService.FlatRatesDetailsType  FlatRatesDetailsType =new APT_SAP_QueryRateCardService.FlatRatesDetailsType ();
//     FlatRatesDetailsType.DispersionType='DEFAULT';
//     FlatRatesDetailsType.MaxWeightBreak=MaxWeightBreak_element;
    
    
//     APT_SAP_QueryRateCardService.BandRateDetailsType BandRateDetailsType =new APT_SAP_QueryRateCardService.BandRateDetailsType ();
//     BandRateDetailsType.Band='BAND_3';
//     BandRateDetailsType.RevenueEstimation=12983.35;
//     BandRateDetailsType.RevenueRange='5000 - 19999';
    
//   APT_SAP_QueryRateCardService.ExpressCourierRates_element ExpressCourierRates_element=new APT_SAP_QueryRateCardService.ExpressCourierRates_element();
//   ExpressCourierRates_element.UpTo2KGPerItem=12.0;
// ExpressCourierRates_element.UpTo2KGPerKG=0.0;
// ExpressCourierRates_element.Over2KGPerKG=2.4;

// APT_SAP_QueryRateCardService.UKRatesDetailsType UKRatesDetailsType =new APT_SAP_QueryRateCardService.UKRatesDetailsType ();

// UKRatesDetailsType.ExpressCourierRates=ExpressCourierRates_element;

// APT_SAP_QueryRateCardService.AirmailRates_element AirmailRates_element =new APT_SAP_QueryRateCardService.AirmailRates_element ();
// AirmailRates_element.UpTo2KGPerItem=12.0;
// AirmailRates_element.UpTo2KGPerKG=0.0;
// AirmailRates_element.Over2KGPerItem=10.5;
// AirmailRates_element.Over2KGPerKG=2.7;



// APT_SAP_QueryRateCardService.NewZealandRatesDetailsType NewZealandRatesDetailsType =new APT_SAP_QueryRateCardService.NewZealandRatesDetailsType ();
// NewZealandRatesDetailsType.AirmailRates=AirmailRates_element;
// NewZealandRatesDetailsType.ExpressCourierRates  =ExpressCourierRates_element;

// APT_SAP_QueryRateCardService.Comments_element Comments_element =new APT_SAP_QueryRateCardService.Comments_element ();
 
//  list<APT_SAP_QueryRateCardService.RateType> RateTypeList=new list<APT_SAP_QueryRateCardService.RateType>();
 
//  APT_SAP_QueryRateCardService.RateType RateType =new APT_SAP_QueryRateCardService.RateType ();
 
// RateType.DestinationZoneCode='ZONE2';
// RateType.WeightRangeCode=0.5;
// RateType.RAFCode='I01';
// RateType.LookupFull='AIRLET_ZONE2';

// RateType.SubsequentRate=1.23;
// RateType.PerKgRate=17.6;
// RateTypeList.add(RateType);


//     APT_SAP_QueryRateCardService.RatesDetails_element RatesDetails_element =new APT_SAP_QueryRateCardService.RatesDetails_element ();
//     RatesDetails_element.Rate=RateTypeList;
    
//     APT_SAP_QueryRateCardService.RatecardContractDetailsType RatecardContractDetailsType =new APT_SAP_QueryRateCardService.RatecardContractDetailsType ();
//     RatecardContractDetailsType.SubProductName='AIRLET';
    
//     list<APT_SAP_QueryRateCardService.RateCardType> rateCardTypeList=new list<APT_SAP_QueryRateCardService.RateCardType>();
//             APT_SAP_QueryRateCardService.RateCardType  rateCardType=new APT_SAP_QueryRateCardService.RateCardType();
//             rateCardType.RateCardKey='20000128';
//             rateCardType.PrecedingRateCardKey='';
//             RateCardType.Type_x='FINAL';
//             RateCardType.ScenarioType='INTERNATIONAL_NEW_BPA';
//             rateCardType.QuoteNumber='';
//             rateCardType.ServiceTypeFlag='';
//             rateCardType.ServiceType='';
//             rateCardType.SignatureFlag='';
//             rateCardType.CreationDetails=CreationType;
//             rateCardType.StatusDetails =StatusDetails;
//           rateCardType.ExtractDetails  =ExtractDetails;
//           rateCardType.CustomerPricingDetails =CustomerPricingDetailsType;
//           rateCardType.FeaturesDetails = FeaturesDetailsType;
//           rateCardType.StandardCharges=StandardChargesType;
//           rateCardType.CurrentPricingDetails = CurrentPricingDetailsType;
//           rateCardType.NewPricingDetails=    NewPricingDetailsType;
//           rateCardType.FlatRatesDetails=FlatRatesDetailsType;
//       rateCardType.BandRateDetails=   BandRateDetailsType;
//     rateCardType.UKRatesDetails = UKRatesDetailsType;
    
//   rateCardType.NewZealandRatesDetails  =NewZealandRatesDetailsType;
//   rateCardType.Comments=Comments_element;
//   rateCardType.RatesDetails=RatesDetails_element;
//   rateCardType.ContractDetails =    RatecardContractDetailsType;
   
//          rateCardTypeList.add(rateCardType);   
            
//             APT_SAP_QueryRateCardService.Ratecards_element  ratecards=new APT_SAP_QueryRateCardService.Ratecards_element();
//           ratecards.Ratecard=rateCardTypeList;
//           // Test.stopTest();
        
            
            // PageReference pageRef = Page.APT_GetRenewalRates;
            // Test.setCurrentPage(pageRef);
            
            // Apexpages.currentPage().getHeaders().put('Referer', 'Page.APT_GetRenewalRates');
            // Apexpages.currentPage().getParameters().put('selectedRecordID', appConLineList1[0].ID);
            // // Test.StartTest();
            // // Test.setMock(WebServiceMock.class, new APT_WebserviceMockCustomerContract());
            
            
            // APT_GetRenewalRatesController grrc = new APT_GetRenewalRatesController();
            // // APT_GetRenewalRatesController.updateConfig(ratecards,bundleLine);
            // // grrc.UpdateConfigandRates();
            // APT_GetRenewalRatesController.parseQueryRateCardResponse(ratecards,bundleLine);
            // grrc.warningpopup();
            // grrc.goBack();
            // grrc.goBck();
            // grrc.doGetRenewalRates();
            // grrc.listLineItem=appConLineList1;
            // Apexpages.currentPage().getParameters().put('selectedRecordID', null);
            // //Test.StartTest();
            // APT_GetRenewalRatesController grrc1 = new APT_GetRenewalRatesController();
            // grrc1.doGetRenewalRates();
            // Apexpages.currentPage().getParameters().put('selectedRecordID', bundleLine.ID);
            // //Test.StartTest();
            // APT_GetRenewalRatesController grrc12 = new APT_GetRenewalRatesController();
            // grrc12.doGetRenewalRates();
            // Test.StopTest();
            
            
            
        }
    }
    /**
        Creating test data
    **/     
   /* private static TestMethod void TestMethodInternational() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {   
            //Create Account
            Account acc = APT_TestUtils.createOrganisation();
            acc.Type = 'Charge Account + Sub Account';
            acc.ACN__c = '123456789';
            acc.LEGACY_ID__c = '1001';
            insert acc;
            
            APT_Charge_Account__c cacc = new APT_Charge_Account__c();
            cacc.APT_Industry_Type__c = 'CTTT';
            insert cacc;
            
            //Create Opportunity
            Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
            opty.Amount = 100;
            insert opty;
            
            //Create PriceList
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            //create international product
            Product2 bundle1 = APT_TestUtils.createInternationalProduct('International Bundle','APOST001','Postal Services');
            bundle1.ProductCode = 'AIRPCL';
            insert bundle1;
            
            Product2 option1 = new Product2();
            option1.ProductCode = 'AIRPCL';
            option1.Name = 'test1';
            option1.Apttus_Config2__ConfigurationType__c = 'Option';
            option1.APT_Category__c = 'CAT1';
            option1.APT_Network_Type__c = 'Express';
            insert option1;
            
            //Create Price list Item
            Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
            insert pli;
            
            //Create Proposal
            Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
            Proposal.Apttus_Proposal__Account__c = acc.ID;
            insert Proposal;
            
            //Create Product Configuration             
            Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
            proposal.Id, 'Proposal',
            'Ad Hoc',priceList.Id, null,
            'Ready For Finalization',
            null, Datetime.now(), true);
            insert prodconfig;
            
            // Create LineItem
            Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
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
            bundleLine.Apttus_Config2__ParentBundleNumber__c = 1;
            bundleLine.APT_Rate_Card_Key__c = '12345678';
            bundleLine.Apttus_Config2__OptionId__c = option1.Id;
            bundleLine.Apttus_Config2__ChargeType__c = 'Standard Price';
            insert bundleLine;
            
            //create price list
            Apttus_Config2__PriceList__c testPriceList = APT_TestUtils.createPriceList();
            insert testPriceList;
            
            //APT_R2T_International_Pricing_Properties__c
            APT_R2T_International_Pricing_Properties__c r2tInternationalPricingProperties = new APT_R2T_International_Pricing_Properties__c();
            r2tInternationalPricingProperties.Name = 'R2T International Pricing Properties';
            r2tInternationalPricingProperties.APT_AIRPCL_Charge_Type__c = 'Standard Price';
            
            insert r2tInternationalPricingProperties;
            
            //create R2T System Properties
            APT_R2T_System_Properties__c r2tSystemProperties = APT_TestUtils.createR2TSystemProperties(testPriceList.Id);
            r2tSystemProperties.APT_Org_Id_Service_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_CompanyCreditAssessmentEndPointURL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_INDV_Credit_Assessment_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            r2tSystemProperties.APT_Query_Rate_Card_End_Point_URL__c = 'https://webapi-pdevext.npe.auspost.com.au/pdev/services/ABN/queryABN/v1.0';
            
            insert r2tSystemProperties;
            
            PageReference pageRef = Page.APT_GetRenewalRates;
            Test.setCurrentPage(pageRef);
            
            Apexpages.currentPage().getHeaders().put('Referer', 'Page.APT_GetRenewalRates');
            Apexpages.currentPage().getParameters().put('selectedRecordID', bundleLine.ID);
            
            Test.setMock(WebServiceMock.class, new APT_WebserviceMockCustomerInternational());
            
            Test.StartTest();
            APT_GetRenewalRatesController grrc = new APT_GetRenewalRatesController();
            grrc.doGetRenewalRates();
            grrc.goBack();
            Test.StopTest();
            system.assert(pageRef!=null);
        }
    }
    private static TestMethod void TestMethodCommonDataModel() {
        
        //APT_SAP_CommonDataModel
       APT_SAP_CommonDataModel.SOAPException_element test1 = new APT_SAP_CommonDataModel.SOAPException_element();
        APT_SAP_CommonDataModel.InterfaceHeader test2 = new APT_SAP_CommonDataModel.InterfaceHeader();
        APT_SAP_CommonDataModel.Exception_x test3 = new APT_SAP_CommonDataModel.Exception_x();
        APT_SAP_CommonDataModel.SynchronisationHeaderType test4 = new APT_SAP_CommonDataModel.SynchronisationHeaderType();
        
        
        //APT_SAP_QueryRateCardService 
      APT_SAP_QueryRateCardService.DetailedRateType test111 = new APT_SAP_QueryRateCardService.DetailedRateType();
        APT_SAP_QueryRateCardService.DeliveryChoicesFeesType test112 = new APT_SAP_QueryRateCardService.DeliveryChoicesFeesType();
    }*/
}