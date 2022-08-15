/**
Description - This apex class is test class for apex Trigger - APT_ProductAttributeValueTrigger & apex class - APT_ProductAttributeValueTriggerHandler
Created By - Raviteja Epuri
Created Date - 2nd Nov, 2015
Last Modified By -
Last Modified Date - 
2022-05-15 Nasir Jawed Changed Tier
**/
@isTest(seealldata=false)
private with sharing class APT_ProductAttributeValueTrigger_Test {
    
    // Custom exception
    private class ValidationException extends Exception {}
    list<Apttus_Config2__ProductAttributeValue__c> listProductAttribute=new list<Apttus_Config2__ProductAttributeValue__c>();
    
    /**
Creating test data
**/
    public Apttus_Config2__LineItem__c bundleLine;
    private static testMethod void testMethodeParcelStandard() 
        
    {
        UserRole role = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
        insert role;

        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
                                 EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
                                 LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
                                 TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
                                 UserName=APT_Constants.EMAIL_TEST_USER, UserRoleId = role.Id);
        list<Apttus_Config2__ProductAttributeValue__c> listProductAttribute=new list<Apttus_Config2__ProductAttributeValue__c>();
        Apttus_Config2__LineItem__c bundleLine;
        Product2 bundle11;
        System.runAs(testuser) {    
            //Create Account
            Account acc = APT_TestUtils.createOrganisation();
            acc.Industry = 'Logistics';
            insert acc;
            
            //Create Opportunity
            Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
            insert opty;
            
            //Create PriceList
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            //create international product
            Product2 bundle1 = APT_TestUtils.createInternationalProduct('International Bundle','eParcelStandard','Postal Services');
            insert bundle1;
            
            bundle11 = APT_TestUtils.createInternationalProduct('International Express - Documents','EXPRESS_DOCT','Postal Services');
            insert bundle11;
            
            //Create Price list Item
            Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
            insert pli;
            
            //Create Proposal
            Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
            insert Proposal;
            
            //Create Product Configuration             
            Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
                                                                                                       proposal.Id, 'Proposal',
                                                                                                       'Ad Hoc',priceList.Id, null,
                                                                                                       'Ready For Finalization',
                                                                                                       null, Datetime.now(), true);
            insert prodconfig;
            
            // Create LineItem
            bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
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
            insert bundleLine;                  
            
            //create Logdement Zone             
            APT_Lodgement_Zone__c logdZone = APT_TestUtils.getLodgementZone('Aust Antarctic Territory','AAT');
            logdZone.APT_Post_Code_Start__c = 1000;
            logdZone.APT_Post_Code_End__c = 9000;
            insert logdZone;               
            /*
//APT_International_Price_Data__c
APT_International_Price_Data__c ipd = new APT_International_Price_Data__c();
ipd.APT_Band__c = 'BAND 2';
ipd.APT_Band_Range_Max__c = 100;
ipd.APT_Band_Range_Min__c = 1;
ipd.APT_Zone__c = 'Zone1';
ipd.APT_Product__c = bundle1.Name;
ipd.APT_Industry__c = 'B Mining';
insert ipd;
*/
            //international price data
            list<APT_International_Price_Data__c> listInternationalPriceData = new list<APT_International_Price_Data__c>();
            List<String> listProduct = new List<String>{APT_Constants.AIRLET_INTERNATIONAL_PRODUCT,
                APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT,
                APT_Constants.AIRPTI_INTERNATIONAL_PRODUCT,
                APT_Constants.AIRRPI_INTERNATIONAL_PRODUCT,
                APT_Constants.AIRSMPCL_INTERNATIONAL_PRODUCT,
                APT_Constants.ECIPCL_INTERNATIONAL_PRODUCT,
                APT_Constants.EMSDOCT_INTERNATIONAL_PRODUCT,
                APT_Constants.EMSMERCH_INTERNATIONAL_PRODUCT,
                APT_Constants.EMSMER20_INTERNATIONAL_PRODUCT};
                    
                    
                    for(string prod:listProduct)
                {
                    for(integer i=1;i<=8;i++)
                    {
                        
                        APT_International_Price_Data__c ipd = APT_TestUtils.createInternationalPriceData(prod, 'B Mining', 'BAND 2', 'Zone'+i, 0, 2999, 10, 10, 20, 20);
                        listInternationalPriceData.add(ipd);             
                        
                    } 
                }           
            
            
            
            insert listInternationalPriceData;
            
            //Create Feature Pricing              
            APT_Feature_Pricing__c featurePricing = APT_TestUtils.getFeaturePricing('Aust Antarctic Territory','CAT1','AAT','Standard','EPR2',10,1);           
            insert featurePricing;
            
            //Create product Attribute value                
            Apttus_Config2__ProductAttributeValue__c attribute1 = APT_TestUtils.GetAttributeValue(bundleLine.Id,'Standard',false,false,false,'Yes','B Mining',True,false);
            attribute1.Category__c='CAT1';
            attribute1.APT_Postcode__c = '2000';
            attribute1.APT_Lodgement_Zone__c=logdZone.ID; 
            attribute1.APT_AirmailSmallParcelGT2kgAVGWeightKG__c = 3;
            attribute1.APT_Distribution_Type_Printpost__c = 'Local Sort Division;Same State Metro;Other State';
            
            attribute1.APT_Volume_Threshold_Post_BillPay__c='25,001 – 100,000';
            attribute1.APT_PostBillPay_Volume_threshold__c='25,001 – 100,000';
            insert attribute1; 
            
            Apttus_Config2__ProductAttributeValue__c attribute11 = APT_TestUtils.GetAttributeValue(bundleLine.Id,'Standard',false,false,false,'No','B Mining',True,false);
            attribute11.Category__c='CAT1';
            attribute11.APT_Postcode__c = '2000';
            attribute11.APT_Lodgement_Zone__c=logdZone.ID; 
            attribute11.APT_AirmailSmallParcelGT2kgAVGWeightKG__c = 3;
            attribute11.APT_Distribution_Type_Printpost__c = 'Local Sort Division;Same State Metro;Other State';
            attribute11.APT_eParcel_Lodgment__c = false;
            attribute11.APT_International_Letters__c = true;
            attribute11.APT_ECI_Merchandise_AVG_Weight_KG__c = 5;
            attribute11.APT_Volume_Threshold_Post_BillPay__c='0 – 25,000';
            attribute11.APT_PostBillPay_Volume_threshold__c='25,001 – 100,000';
            attribute11.APT_RK_Code_Applied__c = false;
            attribute11.Revenue_Committment__c='Less than 3,000';
            attribute11.APT_Volume_Data__c='No';
            listProductAttribute.add(attribute11);
            
            Apttus_Config2__ProductAttributeValue__c attribute111 = APT_TestUtils.GetAttributeValue(bundleLine.Id,'Standard',false,false,false,'No','B Mining',True,false);
            attribute111.Category__c='CAT1';
            attribute111.APT_Postcode__c = '2000';
            attribute111.APT_Lodgement_Zone__c=logdZone.ID; 
            attribute111.APT_AirmailSmallParcelGT2kgAVGWeightKG__c = 3;
            attribute111.APT_Distribution_Type_Printpost__c = 'Local Sort Division;Same State Metro;Other State';
            attribute111.APT_eParcel_Lodgment__c = false;
            attribute111.APT_International_Letters__c = true;
            attribute111.APT_ECI_Merchandise_AVG_Weight_KG__c = 5;
            attribute11.APT_RK_Code_Applied__c = false;
            attribute11.Revenue_Committment__c='3,000 - 4,999';
            attribute11.APT_Volume_Data__c='No';
            
            listProductAttribute.add(attribute111);
            
            try {
                insert listProductAttribute;
            } catch(Exception ex) {
                System.debug('ex::'+ex.getMessage());
            }
            
            
            
            // Apttus_Config2__ProductAttributeValue__c attribute11 = APT_TestUtils.GetAttributeValue(bundleLine.Id,'Standard',false,false,false,'Yes','B Mining',True,false);
            // attribute11.Category__c='CAT1';
            // attribute11.APT_Postcode__c = '2000';
            // attribute11.APT_Lodgement_Zone__c=logdZone.ID; 
            // attribute11.APT_AirmailSmallParcelGT2kgAVGWeightKG__c = 3;
            // attribute11.APT_Distribution_Type_Printpost__c = 'Local Sort Division;Same State Metro;Other State';
            // attribute11.APT_PostBillPay_Volume_threshold__c='25,001 – 100,000';
            // attribute11.APT_PostBillPay_Volume_threshold__c='25,001 – 100,000';
            // insert attribute11;
            
            Test.starttest();    
            // update product Attribute value
            //attribute1.Category__c='CAT1';
            attribute1.APT_Distribution_Type_Printpost__c = 'Local Sort Division;Same State Metro;Other State;Large Postcode Direct';               
            Update attribute1; 
            //system.assert('SUCCESS' == APT_Constants.SUCCESS_LABEL);
            Test.stoptest();
            system.assert(listInternationalPriceData.size()>0);
            System.assertEquals(listProduct[0],'AIRLET');
            system.assert(attribute1.Apttus_Config2__LineItemId__c !=null);      
        }
        set<string> s11=new set<string>();
        s11.add('Zone6');
        list<APT_International_Price_Data__c> listIdpData=new list<APT_International_Price_Data__c>();
        APT_International_Price_Data__c ipd1 = APT_TestUtils.createInternationalPriceData('EXPRESS_DOCT', 'B Mining', 'BAND 2', 'Zone6', 0, 2999, 10, 10, 20, 20);
        listIdpData.add(ipd1);
        string data=listIdpData[0].APT_Band__c + APT_Constants.SEPERATOR_SIMILARITY + listIdpData[0].APT_Product__c + APT_Constants.SEPERATOR_SIMILARITY + listIdpData[0].APT_Zone__c;
        map<string, list<APT_International_Price_Data__c>> mapDataPrice=new map<string,list<APT_International_Price_Data__c>>();
        mapDataPrice.put(data,listIdpData);
        double num=0;
        
        APT_ProductAttributeValueTriggerHandler.beforeUpdateEvent(listProductAttribute,null,null);
        // APT_ProductAttributeValueTriggerHandler.calculateProductRevenueforNewIntBundle(num,bundleLine,'BAND 2','EXPRESS_DOCT',s11,'CSP',mapDataPrice,listProductAttribute[0]);
        
    }
    /**
Creating test data
**/   
    private static testMethod void testMethodeParcelStandard2() 
        
    {
        UserRole role = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
        insert role;

        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
                                 EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
                                 LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
                                 TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
                                 UserName=APT_Constants.EMAIL_TEST_USER, UserRoleId = role.Id);
        System.runAs(testuser) {            
            //Create Account
            Account acc = APT_TestUtils.createOrganisation();
            acc.Industry = 'Logistics';
            insert acc;
            
            //Create Opportunity
            Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
            insert opty;
            
            //Create PriceList
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            //create international product
            Product2 bundle1 = APT_TestUtils.createInternationalProduct('International Bundle','eParcelStandard','Postal Services');
            insert bundle1;
            
            //Create Price list Item
            Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
            insert pli;
            
            //Create Proposal
            Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
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
            insert bundleLine;                  
            
            //create Logdement Zone             
            APT_Lodgement_Zone__c logdZone = APT_TestUtils.getLodgementZone('Aust Antarctic Territory','AAT');
            logdZone.APT_Post_Code_Start__c = 1000;
            logdZone.APT_Post_Code_End__c = 9000;
            insert logdZone;               
            /*
//APT_International_Price_Data__c
APT_International_Price_Data__c ipd = new APT_International_Price_Data__c();
ipd.APT_Band__c = 'BAND 2';
ipd.APT_Band_Range_Max__c = 100;
ipd.APT_Band_Range_Min__c = 1;
ipd.APT_Zone__c = 'Zone1';
ipd.APT_Product__c = bundle1.Name;
ipd.APT_Industry__c = 'B Mining';
insert ipd;
*/
            //international price data
            list<APT_International_Price_Data__c> listInternationalPriceData = new list<APT_International_Price_Data__c>();
            List<String> listProduct = new List<String>{APT_Constants.AIRLET_INTERNATIONAL_PRODUCT,
                APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT,
                APT_Constants.AIRPTI_INTERNATIONAL_PRODUCT,
                APT_Constants.AIRRPI_INTERNATIONAL_PRODUCT,
                APT_Constants.AIRSMPCL_INTERNATIONAL_PRODUCT,
                APT_Constants.ECIPCL_INTERNATIONAL_PRODUCT,
                APT_Constants.EMSDOCT_INTERNATIONAL_PRODUCT,
                APT_Constants.EMSMERCH_INTERNATIONAL_PRODUCT,
                APT_Constants.EMSMER20_INTERNATIONAL_PRODUCT};
                    
                    
                    for(string prod:listProduct)
                {
                    for(integer i=1;i<=8;i++)
                    {
                        
                        APT_International_Price_Data__c ipd = APT_TestUtils.createInternationalPriceData(prod, 'B Mining', 'BAND 2', 'Zone'+i, 0, 2999, 10, 10, 20, 20);
                        listInternationalPriceData.add(ipd);             
                        
                    } 
                }           
            
            
            
            insert listInternationalPriceData;
            
            //Create Feature Pricing              
            APT_Feature_Pricing__c featurePricing = APT_TestUtils.getFeaturePricing('Aust Antarctic Territory','CAT1','AAT','Standard','EPR2',10,1);           
            insert featurePricing;
            
            //Create product Attribute value                
            Apttus_Config2__ProductAttributeValue__c attribute1 = APT_TestUtils.GetAttributeValue(bundleLine.Id,'Standard',false,false,false,'Yes','B Mining',True,false);
            attribute1.Category__c='CAT1';
            attribute1.APT_Postcode__c = '2000';
            attribute1.APT_Lodgement_Zone__c=logdZone.ID; 
            attribute1.APT_AirmailSmallParcelGT2kgAVGWeightKG__c = 3;
            attribute1.APT_Distribution_Type_Printpost__c = 'Local Sort Division;Same State Metro;Other State';
            attribute1.APT_eParcel_Lodgment__c = false;
            attribute1.APT_International_Letters__c = true;
            attribute1.APT_RK_Code_Applied__c = false;
            attribute1.APT_Volume_Data__c = APT_Constants.OPTION_YES;
            
            insert attribute1; 
            
            
            Test.starttest();    
            // update product Attribute value
            //attribute1.Category__c='CAT1';
            attribute1.APT_Distribution_Type_Printpost__c = 'Local Sort Division;Same State Metro;Other State;Large Postcode Direct';               
            Update attribute1; 
            //system.assert('SUCCESS' == APT_Constants.SUCCESS_LABEL);
            Test.stoptest();
            system.assert(attribute1.Apttus_Config2__LineItemId__c !=null);  
            System.assertEquals(listProduct[0],'AIRLET'); 
            system.assert(listInternationalPriceData.size()>0);
        }
    }
    /**
Creating test data
**/   
    private static testMethod void testMethodeParcelStandard3() 
        
    {
        UserRole role = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
        insert role;

        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
                                 EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
                                 LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
                                 TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
                                 UserName=APT_Constants.EMAIL_TEST_USER, UserRoleId = role.Id);
        list<Apttus_Config2__ProductAttributeValue__c> listProductAttribute=new list<Apttus_Config2__ProductAttributeValue__c>();
        
        System.runAs(testuser) {   
            //Create Account
            Account acc = APT_TestUtils.createOrganisation();
            acc.Industry = 'Logistics';
            insert acc;
            
            //Create Opportunity
            Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
            insert opty;
            
            //Create PriceList
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            //create international product
            Product2 bundle1 = APT_TestUtils.createInternationalProduct('International Bundle','eParcelStandard','Postal Services');
            insert bundle1;
            
            //Create Price list Item
            Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
            insert pli;
            
            //Create Proposal
            Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
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
            insert bundleLine;                  
            
            //create Logdement Zone             
            APT_Lodgement_Zone__c logdZone = APT_TestUtils.getLodgementZone('Aust Antarctic Territory','AAT');
            logdZone.APT_Post_Code_Start__c = 1000;
            logdZone.APT_Post_Code_End__c = 9000;
            insert logdZone;               
            /*
//APT_International_Price_Data__c
APT_International_Price_Data__c ipd = new APT_International_Price_Data__c();
ipd.APT_Band__c = 'BAND 2';
ipd.APT_Band_Range_Max__c = 100;
ipd.APT_Band_Range_Min__c = 1;
ipd.APT_Zone__c = 'Zone1';
ipd.APT_Product__c = bundle1.Name;
ipd.APT_Industry__c = 'B Mining';
insert ipd;
*/
            //international price data
            list<APT_International_Price_Data__c> listInternationalPriceData = new list<APT_International_Price_Data__c>();
            List<String> listProduct = new List<String>{APT_Constants.AIRLET_INTERNATIONAL_PRODUCT,
                APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT,
                APT_Constants.AIRPTI_INTERNATIONAL_PRODUCT,
                APT_Constants.AIRRPI_INTERNATIONAL_PRODUCT,
                APT_Constants.AIRSMPCL_INTERNATIONAL_PRODUCT,
                APT_Constants.ECIPCL_INTERNATIONAL_PRODUCT,
                APT_Constants.EMSDOCT_INTERNATIONAL_PRODUCT,
                APT_Constants.EMSMERCH_INTERNATIONAL_PRODUCT,
                APT_Constants.EMSMER20_INTERNATIONAL_PRODUCT};
                    
                    
                    for(string prod:listProduct)
                {
                    for(integer i=1;i<=8;i++)
                    {
                        
                        APT_International_Price_Data__c ipd = APT_TestUtils.createInternationalPriceData(prod, 'B Mining', 'BAND 2', 'Zone'+i, 0, 2999, 10, 10, 20, 20);
                        listInternationalPriceData.add(ipd);             
                        
                    } 
                }           
            
            
            
            insert listInternationalPriceData;
            
            //Create Feature Pricing              
            APT_Feature_Pricing__c featurePricing = APT_TestUtils.getFeaturePricing('Aust Antarctic Territory','CAT1','AAT','Standard','EPR2',10,1);           
            insert featurePricing;
            
            //Create product Attribute value                
            Apttus_Config2__ProductAttributeValue__c attribute1 = APT_TestUtils.GetAttributeValue(bundleLine.Id,'Standard',false,false,false,'Yes','B Mining',True,false);
            attribute1.Category__c='CAT1';
            attribute1.APT_Postcode__c = '2000';
            attribute1.APT_Lodgement_Zone__c=logdZone.ID; 
            attribute1.APT_AirmailSmallParcelGT2kgAVGWeightKG__c = 3;
            attribute1.APT_Distribution_Type_Printpost__c = 'Local Sort Division;Same State Metro;Other State';
            attribute1.APT_eParcel_Lodgment__c = false;
            attribute1.APT_International_Letters__c = true;
            attribute1.APT_ECI_Merchandise_AVG_Weight_KG__c = 5;
            attribute1.APT_Volume_Threshold_Post_BillPay__c='25,001 – 100,000';
            attribute1.APT_PostBillPay_Volume_threshold__c='25,001 – 100,000';
            insert attribute1; 
            
            
            
            
            Test.starttest();    
            // update product Attribute value
            //attribute1.Category__c='CAT1';
            attribute1.APT_Distribution_Type_Printpost__c = 'Local Sort Division;Same State Metro;Other State;Large Postcode Direct';               
            Update attribute1; 
            //system.assert('SUCCESS' == APT_Constants.SUCCESS_LABEL);
            Test.stoptest();
            system.assert(attribute1.Apttus_Config2__LineItemId__c !=null);
            System.assertEquals(listProduct[0],'AIRLET'); 
            system.assert(listInternationalPriceData.size()>0); 
        }
        
    }
    /**
Creating test data
**/  
    private static testMethod void testMethodeParcelStandard4() 
        
    {
        UserRole role = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
        insert role;

        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
                                 EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
                                 LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
                                 TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
                                 UserName=APT_Constants.EMAIL_TEST_USER, UserRoleId = role.Id);
        System.runAs(testuser) {   
            //Create Account
            Account acc = APT_TestUtils.createOrganisation();
            acc.Industry = 'Logistics';
            insert acc;
            
            //Create Opportunity
            Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
            insert opty;
            
            //Create PriceList
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            //create international product
            Product2 bundle1 = APT_TestUtils.createInternationalProduct('International Bundle','eParcelStandard','Postal Services');
            insert bundle1;
            
            //Create Price list Item
            Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
            insert pli;
            
            //Create Proposal
            Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
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
            insert bundleLine;                  
            
            //create Logdement Zone             
            APT_Lodgement_Zone__c logdZone = APT_TestUtils.getLodgementZone('Aust Antarctic Territory','AAT');
            logdZone.APT_Post_Code_Start__c = 1000;
            logdZone.APT_Post_Code_End__c = 9000;
            insert logdZone;               
            /*
//APT_International_Price_Data__c
APT_International_Price_Data__c ipd = new APT_International_Price_Data__c();
ipd.APT_Band__c = 'BAND 2';
ipd.APT_Band_Range_Max__c = 100;
ipd.APT_Band_Range_Min__c = 1;
ipd.APT_Zone__c = 'Zone1';
ipd.APT_Product__c = bundle1.Name;
ipd.APT_Industry__c = 'B Mining';
insert ipd;
*/
            //international price data
            list<APT_International_Price_Data__c> listInternationalPriceData = new list<APT_International_Price_Data__c>();
            List<String> listProduct = new List<String>{APT_Constants.AIRLET_INTERNATIONAL_PRODUCT,
                APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT,
                APT_Constants.AIRPTI_INTERNATIONAL_PRODUCT,
                APT_Constants.AIRRPI_INTERNATIONAL_PRODUCT,
                APT_Constants.AIRSMPCL_INTERNATIONAL_PRODUCT,
                APT_Constants.ECIPCL_INTERNATIONAL_PRODUCT,
                APT_Constants.EMSDOCT_INTERNATIONAL_PRODUCT,
                APT_Constants.EMSMERCH_INTERNATIONAL_PRODUCT,
                APT_Constants.EMSMER20_INTERNATIONAL_PRODUCT};
                    
                    
                    for(string prod:listProduct)
                {
                    for(integer i=1;i<=8;i++)
                    {
                        
                        APT_International_Price_Data__c ipd = APT_TestUtils.createInternationalPriceData(prod, 'B Mining', 'BAND 2', 'Zone'+i, 0, 2999, 10, 10, 20, 20);
                        listInternationalPriceData.add(ipd);             
                        
                    } 
                }           
            
            
            insert listInternationalPriceData;
            
            //Create Feature Pricing              
            APT_Feature_Pricing__c featurePricing = APT_TestUtils.getFeaturePricing('Aust Antarctic Territory','CAT1','AAT','Standard','EPR2',10,1);           
            insert featurePricing;
            
            //Create product Attribute value                
            Apttus_Config2__ProductAttributeValue__c attribute1 = APT_TestUtils.GetAttributeValue(bundleLine.Id,'Standard',false,false,false,'Yes','B Mining',True,false);
            attribute1.Category__c='CAT1';
            attribute1.APT_Postcode__c = '2000';
            attribute1.APT_Lodgement_Zone__c=logdZone.ID; 
            attribute1.APT_AirmailSmallParcelGT2kgAVGWeightKG__c = 3;
            attribute1.APT_ECI_Merchandise_AVG_Weight_KG__c = 5;
            attribute1.APT_Distribution_Type_Printpost__c = 'Local Sort Division;Same State Metro;Other State';
            attribute1.APT_Volume_Threshold_Post_BillPay__c='25,001 – 100,000';
            attribute1.APT_PostBillPay_Volume_threshold__c='25,001 – 100,000';
            insert attribute1; 
            
            Test.starttest();    
            // update product Attribute value
            //attribute1.Category__c='CAT1';
            attribute1.APT_Distribution_Type_Printpost__c = 'Local Sort Division;Same State Metro;Other State;Large Postcode Direct';               
            Update attribute1; 
            //system.assert('SUCCESS' == APT_Constants.SUCCESS_LABEL);
            Test.stoptest();
            System.assertEquals(listProduct[0],'AIRLET');
            system.assert(listInternationalPriceData.size()>0);
            system.assert(attribute1.Apttus_Config2__LineItemId__c !=null);  
            
        }
        
    }
    /**
Creating test data
**/
    private static testMethod void testMethodeParcelExpress() 
        
    {
        UserRole role = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
        insert role;

        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
                                 EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
                                 LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
                                 TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
                                 UserName=APT_Constants.EMAIL_TEST_USER, UserRoleId = role.Id);
        System.runAs(testuser) {        
            //Create Account
            Account acc = APT_TestUtils.createOrganisation();
            acc.Industry = 'Logistics';
            insert acc;
            
            //Create Opportunity
            Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
            insert opty;
            
            //Create PriceList
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            //create international product
            Product2 bundle1 = APT_TestUtils.createInternationalProduct('AIRLET','eParcelExpress','Postal Services');
            insert bundle1;
            
            //Create Price list Item
            Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
            insert pli;
            
            //Create Proposal
            Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
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
            insert bundleLine;                  
            
            //create Logdement Zone             
            APT_Lodgement_Zone__c logdZone = APT_TestUtils.getLodgementZone('Aust Antarctic Territory','AAT');
            logdZone.APT_Post_Code_Start__c = 1000;
            logdZone.APT_Post_Code_End__c = 9000;
            insert logdZone;               
            
            //Create Feature Pricing              
            APT_Feature_Pricing__c featurePricing = APT_TestUtils.getFeaturePricing('Aust Antarctic Territory','CAT1','AAT','Express','EPR2',10,1);           
            insert featurePricing;
            
            //Create product Attribute value                
            Apttus_Config2__ProductAttributeValue__c attribute1 = APT_TestUtils.GetAttributeValue(bundleLine.Id,'Express',false,false,false,'Yes','B Mining',True,false);
            attribute1.Category__c='CAT1';
            attribute1.APT_Postcode__c = '2000';
            attribute1.APT_Lodgement_Zone__c=logdZone.ID;    
            attribute1.APT_AirmailSmallParcelGT2kgAVGWeightKG__c = 3;  
            attribute1.APT_Distribution_Type_Printpost__c = 'Local Sort Division;Same State Metro;Other State';
            attribute1.APT_eParcel_Lodgment__c = false;
            attribute1.APT_International_Letters__c = true;
            attribute1.APT_Volume_Threshold_Post_BillPay__c='25,001 – 100,000';
            attribute1.APT_PostBillPay_Volume_threshold__c='25,001 – 100,000';
            insert attribute1;
            
            
            Test.starttest();     
            // update product Attribute value               
            Update attribute1;                
            //system.assert('SUCCESS' == APT_Constants.SUCCESS_LABEL);
            Test.stoptest();
            system.assert(attribute1.Apttus_Config2__LineItemId__c !=null); 
        }
    }   
    
    /**
Creating test data
**/    
    private static testMethod void testMethodeParcelExpress2() 
        
    {
        UserRole role = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
        insert role;

        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
                                 EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
                                 LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
                                 TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
                                 UserName=APT_Constants.EMAIL_TEST_USER, UserRoleId = role.Id);
        System.runAs(testuser) {
            //Create Account
            Account acc = APT_TestUtils.createOrganisation();
            acc.Industry = 'Logistics';
            insert acc;
            
            //Create Opportunity
            Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
            insert opty;
            
            //Create PriceList
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            //create international product
            Product2 bundle1 = APT_TestUtils.createInternationalProduct('International Bundle','eParcelExpress','Postal Services');
            insert bundle1;
            
            //Create Price list Item
            Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
            insert pli;
            
            //Create Proposal
            Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
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
            insert bundleLine;                  
            
            //create Logdement Zone             
            APT_Lodgement_Zone__c logdZone = APT_TestUtils.getLodgementZone('Aust Antarctic Territory','AAT');
            logdZone.APT_Zone_Structure__c = 'BASE';
            logdZone.APT_Post_Code_Start__c = 1000;
            logdZone.APT_Post_Code_End__c = 9000;
            insert logdZone;               
            
            //Create Feature Pricing              
            APT_Feature_Pricing__c featurePricing = APT_TestUtils.getFeaturePricing('Aust Antarctic Territory','CAT1','AAT','Express','EPR2',10,1);           
            insert featurePricing;
            
            //Create product Attribute value                
            Apttus_Config2__ProductAttributeValue__c attribute1 = APT_TestUtils.GetAttributeValue(bundleLine.Id,'Express',false,false,false,'Yes','B Mining',True,false);
            attribute1.Category__c= null;
            attribute1.APT_Postcode__c = '2000';
            attribute1.APT_Lodgement_Zone__c=logdZone.ID;      
            attribute1.APT_AirmailSmallParcelGT2kgAVGWeightKG__c = 3;
            attribute1.APTS_Price_Structure__c = 'Z003';
            attribute1.APT_Distribution_Type_Printpost__c = 'Local Sort Division;Same State Metro;Other State';  
            attribute1.APT_Volume_Threshold_Post_BillPay__c='25,001 – 100,000';
            attribute1.APT_PostBillPay_Volume_threshold__c='25,001 – 100,000';
            insert attribute1;
            
            
            Test.starttest();     
            // update product Attribute value               
            Update attribute1;                
            //system.assert('SUCCESS' == APT_Constants.SUCCESS_LABEL);
            Test.stoptest();
            system.assert(attribute1.Apttus_Config2__LineItemId__c !=null);  
        }
    }   
    
    public static testMethod void testMethodeAPPC_ExistingCustomer()  
    {
        UserRole role = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
        insert role;

        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
                                 EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
                                 LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
                                 TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
                                 UserName=APT_Constants.EMAIL_TEST_USER, UserRoleId = role.Id);
        System.runAs(testuser) {
            //Create Account
            Account acc = APT_TestUtils.createOrganisation();
            acc.Industry = 'Logistics';
            insert acc;
            
            //Create Opportunity
            Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
            insert opty;
            
            //Create PriceList
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            //create international product
            Product2 bundle1 = APT_TestUtils.createInternationalProduct('APPC','APPC','APPC');
            insert bundle1;
            
            //Create Price list Item
            Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
            insert pli;
            
            //Create Proposal
            Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
            insert Proposal;
            
            //Create Product Configuration             
            Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
                                                                                                       proposal.Id, 'Proposal',
                                                                                                       'Ad Hoc',priceList.Id, null,
                                                                                                       'Ready For Finalization',
                                                                                                       null, Datetime.now(), true);
            prodconfig.Apttus_Config2__AccountId__c = acc.Id;
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
            insert bundleLine;                  
            
            //create Logdement Zone             
            APT_Lodgement_Zone__c logdZone = APT_TestUtils.getLodgementZone('Aust Antarctic Territory','AAT');
            logdZone.APT_Zone_Structure__c = 'BASE';
            logdZone.APT_Post_Code_Start__c = 1000;
            logdZone.APT_Post_Code_End__c = 9000;
            insert logdZone;               
            
            //Create Feature Pricing              
            APT_Feature_Pricing__c featurePricing = APT_TestUtils.getFeaturePricing('Aust Antarctic Territory','CAT1','AAT','Express','EPR2',10,1);           
            insert featurePricing;
            
            //Create product Attribute value                
            Apttus_Config2__ProductAttributeValue__c attribute1 = APT_TestUtils.GetAttributeValue(bundleLine.Id,'Express',false,false,false,'Yes','B Mining',True,false);
            attribute1.Category__c= null;
            attribute1.APT_Postcode__c = '2000';
            attribute1.APT_Lodgement_Zone__c=logdZone.ID;      
            attribute1.APT_AirmailSmallParcelGT2kgAVGWeightKG__c = 3;
            attribute1.APTS_Price_Structure__c = 'Z003';
            attribute1.APT_Distribution_Type_Printpost__c = 'Local Sort Division;Same State Metro;Other State';  
            attribute1.APT_Volume_Threshold_Post_BillPay__c='25,001 – 100,000';
            attribute1.APT_PostBillPay_Volume_threshold__c='25,001 – 100,000';
            attribute1.APT_Min_Spend_Per_Annum__c = 6000;
            insert attribute1;
            
            APT_Simplified_Parcel_Spend_Range__c spendRange = new APT_Simplified_Parcel_Spend_Range__c();
            spendRange.APT_Product_Code__c = 'APPC';
            spendRange.APT_Min_Spend__c = 5000;
            spendRange.APT_Max_Spend__c = 7000;
            spendRange.APT_Tier__c = 'T04';
            insert spendRange;
            
            Test.starttest();     
            // update product Attribute value               
            Update attribute1;                
            //system.assert('SUCCESS' == APT_Constants.SUCCESS_LABEL);
            Test.stoptest();
            system.assert(attribute1.Apttus_Config2__LineItemId__c !=null);  
        }
    }   
    
    public static testMethod void testMethodeAPPC_NonExistingCustomer()  
    {
        UserRole role = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
        insert role;

        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
                                 EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
                                 LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
                                 TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
                                 UserName=APT_Constants.EMAIL_TEST_USER, UserRoleId = role.Id);
        System.runAs(testuser) {
            //Create Account
            Account acc = APT_TestUtils.createOrganisation();
            acc.Industry = 'Logistics';
            insert acc;
            
            //Create Opportunity
            Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
            insert opty;
            
            //Create PriceList
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            //create international product
            Product2 bundle1 = APT_TestUtils.createInternationalProduct('APPC','APPC','APPC');
            insert bundle1;
            
            //Create Price list Item
            Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
            insert pli;
            
            //Create Proposal
            Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
            insert Proposal;
            
            //Create Product Configuration             
            Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
                                                                                                       proposal.Id, 'Proposal',
                                                                                                       'Ad Hoc',priceList.Id, null,
                                                                                                       'Ready For Finalization',
                                                                                                       null, Datetime.now(), true);
            prodconfig.Apttus_Config2__AccountId__c = acc.Id;
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
            insert bundleLine;                  
            
            //create Logdement Zone             
            APT_Lodgement_Zone__c logdZone = APT_TestUtils.getLodgementZone('Aust Antarctic Territory','AAT');
            logdZone.APT_Zone_Structure__c = 'BASE';
            logdZone.APT_Post_Code_Start__c = 1000;
            logdZone.APT_Post_Code_End__c = 9000;
            insert logdZone;               
            
            //Create Feature Pricing              
            APT_Feature_Pricing__c featurePricing = APT_TestUtils.getFeaturePricing('Aust Antarctic Territory','CAT1','AAT','Express','EPR2',10,1);           
            insert featurePricing;
            
            //Create product Attribute value                
            Apttus_Config2__ProductAttributeValue__c attribute1 = APT_TestUtils.GetAttributeValue(bundleLine.Id,'Express',false,false,false,'Yes','B Mining',True,false);
            attribute1.Category__c= null;
            attribute1.APT_Postcode__c = '2000';
            attribute1.APT_Lodgement_Zone__c=logdZone.ID;      
            attribute1.APT_AirmailSmallParcelGT2kgAVGWeightKG__c = 3;
            attribute1.APTS_Price_Structure__c = 'Z003';
            attribute1.APT_Distribution_Type_Printpost__c = 'Local Sort Division;Same State Metro;Other State';  
            attribute1.APT_Volume_Threshold_Post_BillPay__c='25,001 – 100,000';
            attribute1.APT_PostBillPay_Volume_threshold__c='25,001 – 100,000';
            attribute1.APT_Min_Spend_Per_Annum__c = 6000;
            insert attribute1;
            
            APT_Simplified_Parcel_Spend_Range__c spendRange = new APT_Simplified_Parcel_Spend_Range__c();
            spendRange.APT_Product_Code__c = 'APPC';
            spendRange.APT_Min_Spend__c = 5000;
            spendRange.APT_Max_Spend__c = 7000;
            spendRange.APT_Tier__c = 'T04';
            insert spendRange;
            
            Test.starttest();     
            // update product Attribute value               
            Update attribute1;                
            //system.assert('SUCCESS' == APT_Constants.SUCCESS_LABEL);
            Test.stoptest();
            system.assert(attribute1.Apttus_Config2__LineItemId__c !=null);  
        }
    }   
    /**
Creating test data
**/    
    private static testMethod void testMethodException() 
        
    {
        UserRole role = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
        insert role;

        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
                                 EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
                                 LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
                                 TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
                                 UserName=APT_Constants.EMAIL_TEST_USER, UserRoleId = role.Id);
        System.runAs(testuser) {        
            //Create Account
            Account acc = APT_TestUtils.createOrganisation();
            acc.Industry = 'Logistics';
            insert acc;
            
            //Create Opportunity
            Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
            insert opty;
            
            //Create PriceList
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            //create international product
            Product2 bundle1 = APT_TestUtils.createInternationalProduct('International Bundle',null,'Postal Services');
            
            insert bundle1;
            
            //Create Price list Item
            Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
            insert pli;
            
            //Create Proposal
            Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
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
            insert bundleLine;                  
            
            //create Logdement Zone             
            APT_Lodgement_Zone__c logdZone = APT_TestUtils.getLodgementZone('Aust Antarctic Territory','AAT');
            logdZone.APT_Zone_Structure__c = 'BASE';
            logdZone.APT_Post_Code_Start__c = 1000;
            logdZone.APT_Post_Code_End__c = 9000;
            insert logdZone;               
            
            //Create Feature Pricing              
            APT_Feature_Pricing__c featurePricing = APT_TestUtils.getFeaturePricing('Aust Antarctic Territory','CAT1','AAT','Express','EPR2',10,1);           
            insert featurePricing;
            
            //Create product Attribute value                
            Apttus_Config2__ProductAttributeValue__c attribute1 = APT_TestUtils.GetAttributeValue(bundleLine.Id,'Express',false,false,false,'Yes','B Mining',True,false);
            //attribute1.Category__c= null;
            attribute1.APT_Postcode__c = '2000';
            //attribute1.APT_Lodgement_Zone__c=logdZone.ID;      
            attribute1.APT_AirmailSmallParcelGT2kgAVGWeightKG__c = 3;
            attribute1.APTS_Price_Structure__c = 'Z003';
            attribute1.APT_Distribution_Type_Printpost__c = 'Local Sort Division;Same State Metro;Other State';  
            attribute1.APT_Volume_Threshold_Post_BillPay__c='25,001 – 100,000';
            attribute1.APT_PostBillPay_Volume_threshold__c='25,001 – 100,000';
            /*try {
insert attribute1;
} catch(Exception ex) {
System.debug('ex::'+ex.getMessage());
}*/
            insert attribute1;
            
            
            Test.starttest();     
            // update product Attribute value
            //Generate Validation rule exception to simulate the capture of exception in unit tests tests
            //Cumulative dispersions for all zone should be 100. 
            try {
                attribute1.Category__c = null;
                Update attribute1;
            } catch(Exception ex) {
                
                System.debug('ex::'+ex.getMessage());
                /*Boolean expectedExceptionThrown =  ex.getMessage().contains('Total Zone Dispersion (%) must be 100') ? true : false;
System.AssertEquals(expectedExceptionThrown, true);*/
            }
            
            //system.assert('SUCCESS' == APT_Constants.SUCCESS_LABEL);
            Test.stoptest();
            system.assert(attribute1.Apttus_Config2__LineItemId__c !=null);
        }
    }
    /* 
Test method for PCMS bundles    
*/
    
    private static testMethod void testMethodePCMSbundles() 
        
    {
        UserRole role = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
        insert role;

        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
                                 EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
                                 LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
                                 TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
                                 UserName=APT_Constants.EMAIL_TEST_USER, UserRoleId = role.Id);
        System.runAs(testuser) {    
            //Create Account
            Account acc = APT_TestUtils.createOrganisation();
            acc.Industry = 'Logistics';
            insert acc;
            
            //Create Opportunity
            Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
            insert opty;
            
            //Create PriceList
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            //create international product
            Product2 bundle1 = APT_TestUtils.createInternationalProduct('International Digital PCMS Bundle incl Airmail Letters',
                                                                        'InternationalDigitalPCMSBundlewithAirmail','Parcel Services');
            insert bundle1;
            
            //Create Price list Item
            Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
            insert pli;
            
            //Create Proposal
            Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
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
            insert bundleLine;                  
            
            //create Logdement Zone             
            APT_Lodgement_Zone__c logdZone = APT_TestUtils.getLodgementZone('Aust Antarctic Territory','AAT');
            logdZone.APT_Post_Code_Start__c = 1000;
            logdZone.APT_Post_Code_End__c = 9000;
            insert logdZone;               
            
            //international price data
            list<APT_International_Price_Data__c> listInternationalPriceData = new list<APT_International_Price_Data__c>();
            List<String> listProduct = new List<String>{APT_Constants.PRODUCT_AIRMAILLETTER,
                APT_Constants.PRODUCT_InternationalExpressDocuments,
                APT_Constants.PRODUCT_InternationalExpressMerchandise,
                APT_Constants.PRODUCT_InternationalStandard,
                APT_Constants.PRODUCT_INTERNATIONALSTANDARDWITHSIGNATURE,
                APT_Constants.PRODUCT_InternationalEconomy,
                APT_Constants.PRODUCT_INTERNATIONALECONOMYWITHSIGNATURE};
                    
                    
                    for(string prod:listProduct)
                {
                    for(integer i=1;i<=9;i++)
                    {
                        
                        //APT_International_Price_Data__c ipd = APT_TestUtils.createInternationalPriceData(prod, 'B Mining', 'BAND 2', 'Zone'+i, 0, 2999, 10, 10, 20, 20);
                        APT_International_Price_Data__c ipd = new APT_International_Price_Data__c();
                        ipd.APT_Product__c = prod;
                        ipd.APT_Industry__c = 'B Mining';
                        ipd.APT_Band__c = 'BAND 2';
                        ipd.APT_Zone__c = 'Zone'+i;
                        ipd.APT_Band_Range_Min__c = 0;
                        ipd.APT_Band_Range_Max__c = 2999;
                        ipd.APT_CSP_Per_Item_Rate__c = 10;
                        ipd.APT_CSP_Per_Kg_Rate__c = 10;
                        ipd.APT_eParcel_Per_Item_Rate__c = 10;
                        ipd.APT_eParcel_Per_Kg_Rate__c = 10;
                        ipd.APT_Weight__c = 'up to 500g';
                        listInternationalPriceData.add(ipd);             
                        
                    } 
                }           
            
            
            
            insert listInternationalPriceData;
            
            //Create Feature Pricing              
            APT_Feature_Pricing__c featurePricing = APT_TestUtils.getFeaturePricing('Aust Antarctic Territory','CAT1','AAT','Standard','EPR2',10,1);           
            insert featurePricing;
            
            //Create product Attribute value                
            Apttus_Config2__ProductAttributeValue__c attribute1 = APT_TestUtils.GetAttributeValue(bundleLine.Id,'Standard',false,false,false,'Yes','B Mining',True,false);
            attribute1.Category__c='CAT1';
            attribute1.APT_Postcode__c = '2000';
            attribute1.APT_Lodgement_Zone__c=logdZone.ID; 
            attribute1.APT_AirmailSmallParcelGT2kgAVGWeightKG__c = 3;
            attribute1.APT_Distribution_Type_Printpost__c = 'Local Sort Division;Same State Metro;Other State';
            attribute1.APT_Volume_Threshold_Post_BillPay__c='25,001 – 100,000';
            attribute1.APT_PostBillPay_Volume_threshold__c='25,001 – 100,000';
            insert attribute1; 
            
            
            Test.starttest();    
            // update product Attribute value
            //attribute1.Category__c='CAT1';
            attribute1.APT_Distribution_Type_Printpost__c = 'Local Sort Division;Same State Metro;Other State;Large Postcode Direct';               
            Update attribute1; 
            //system.assert('SUCCESS' == APT_Constants.SUCCESS_LABEL);
            Test.stoptest();
            system.assert(listInternationalPriceData.size()>0);
            System.assertEquals(listProduct[0],'AIRMAIL_LETTERS');
            system.assert(attribute1.Apttus_Config2__LineItemId__c !=null);      
        }
        
        double num=0;
        set<string> s11=new set<string>();
        s11.add('Zone6');
        list<APT_International_Price_Data__c> listIdpData=new list<APT_International_Price_Data__c>();
        APT_International_Price_Data__c ipd1 = APT_TestUtils.createInternationalPriceData('EXPRESS_DOCT', 'B Mining', 'BAND 2', 'Zone6', 0, 2999, 10, 10, 20, 20);
        listIdpData.add(ipd1);
        string data=listIdpData[0].APT_Band__c + APT_Constants.SEPERATOR_SIMILARITY + listIdpData[0].APT_Product__c + APT_Constants.SEPERATOR_SIMILARITY + listIdpData[0].APT_Zone__c;
        map<string, list<APT_International_Price_Data__c>> mapDataPrice=new map<string,list<APT_International_Price_Data__c>>();
        mapDataPrice.put(data,listIdpData);
        
        
        //APT_ProductAttributeValueTriggerHandler.calculateProductRevenueforNewIntBundle(num,Null,'BAND 2','EXPRESS_DOCT',s11,'CSP',mapDataPrice,null);
        //APT_ProductAttributeValueTriggerHandler.calculateProductRevenueforNewIntBundle(num,Null,'BAND 2','EXPRESS_DOCT',s11,'CSP',mapDataPrice,null);
        
        
    }
    
    @isTest
    public static void testMethodePCMSbundles1()     
    {
        UserRole role = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
        insert role;

        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
                                 EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
                                 LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
                                 TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
                                 UserName=APT_Constants.EMAIL_TEST_USER, UserRoleId = role.Id);
        System.runAs(testuser) {    
            //Create Account
            Account acc = APT_TestUtils.createOrganisation();
            acc.Industry = 'Logistics';
            insert acc;
            
            //Create Opportunity
            Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
            insert opty;
            
            //Create PriceList
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            //create international product
            Product2 bundle1 = APT_TestUtils.createInternationalProduct('International Digital PCMS Bundle incl Airmail Letters',
                                                                        'InternationalDigitalPCMSBundlewithAirmail','Parcel Services');
            bundle1.ProductCode = null;
            insert bundle1;
            
            //Create Price list Item
            Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
            pli.APT_Band__c = 'Band 2';
            insert pli;
            
            //Create Proposal
            Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
            insert Proposal;
            
            //Create Product Configuration             
            Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
                                                                                                       proposal.Id, 'Proposal',
                                                                                                       'Ad Hoc',priceList.Id, null,
                                                                                                       'Ready For Finalization',
                                                                                                       null, Datetime.now(), true);
            prodconfig.Apttus_Config2__AccountId__c =null;
            insert prodconfig;
            System.debug('Line: 1121');
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
            insert bundleLine;                  
            
            //create Logdement Zone             
            APT_Lodgement_Zone__c logdZone = APT_TestUtils.getLodgementZone('Aust Antarctic Territory','AAT');
            logdZone.APT_Post_Code_Start__c = 1000;
            logdZone.APT_Post_Code_End__c = 9000;
            insert logdZone;               
            
            //international price data
            list<APT_International_Price_Data__c> listInternationalPriceData = new list<APT_International_Price_Data__c>();
            List<String> listProduct = new List<String>{APT_Constants.PRODUCT_AIRMAILLETTER,
                APT_Constants.PRODUCT_InternationalExpressDocuments,
                APT_Constants.PRODUCT_InternationalExpressMerchandise,
                APT_Constants.PRODUCT_InternationalStandard,
                APT_Constants.PRODUCT_INTERNATIONALSTANDARDWITHSIGNATURE,
                APT_Constants.PRODUCT_InternationalEconomy,
                APT_Constants.PRODUCT_INTERNATIONALECONOMYWITHSIGNATURE};
                    
                    
                    for(string prod:listProduct)
                {
                    for(integer i=1;i<=9;i++)
                    {
                        
                        //APT_International_Price_Data__c ipd = APT_TestUtils.createInternationalPriceData(prod, 'B Mining', 'BAND 2', 'Zone'+i, 0, 2999, 10, 10, 20, 20);
                        APT_International_Price_Data__c ipd = new APT_International_Price_Data__c();
                        ipd.APT_Product__c = prod;
                        ipd.APT_Industry__c = 'B Mining';
                        ipd.APT_Band__c = 'BAND 2';
                        ipd.APT_Zone__c = 'Zone'+i;
                        ipd.APT_Band_Range_Min__c = 0;
                        ipd.APT_Band_Range_Max__c = 2999;
                        ipd.APT_CSP_Per_Item_Rate__c = 10;
                        ipd.APT_CSP_Per_Kg_Rate__c = 10;
                        ipd.APT_eParcel_Per_Item_Rate__c = 10;
                        ipd.APT_eParcel_Per_Kg_Rate__c = 10;
                        ipd.APT_Weight__c = 'up to 500g';
                        listInternationalPriceData.add(ipd);             
                        
                    } 
                }           
            
            
            
            insert listInternationalPriceData;
            
            //Create Feature Pricing              
            APT_Feature_Pricing__c featurePricing = APT_TestUtils.getFeaturePricing('Aust Antarctic Territory','CAT1','AAT','Standard','EPR2',10,1);           
            insert featurePricing;
            
            //Create product Attribute value                
            Apttus_Config2__ProductAttributeValue__c attribute1 = APT_TestUtils.GetAttributeValue(bundleLine.Id,'Standard',false,false,false,'Yes','B Mining',True,false);
            attribute1.Category__c='CAT1';
            attribute1.APT_Postcode__c = '2000';
            attribute1.APT_Lodgement_Zone__c=logdZone.ID; 
            attribute1.APT_AirmailSmallParcelGT2kgAVGWeightKG__c = 3;
            attribute1.APT_Distribution_Type_Printpost__c = 'Local Sort Division;Same State Metro;Other State';
            attribute1.APT_Volume_Threshold_Post_BillPay__c='25,001 – 100,000';
            attribute1.APT_PostBillPay_Volume_threshold__c='25,001 – 100,000';
            //attribute1.Apttus_Config2__LineItemId__c = null;
            attribute1.APT_Domestic_Customer__c = null;
            insert attribute1; 
            
            list<Product2> products = new list<Product2>();
            
            //Domestic (non startrack) product
            Product2 productCAT1STD = APT_TestUtils.createDomesticProduct('CAT1 Standard', 'CAT1Standard', 'Parcel Services', 'CAT1', 'STANDARD');
            productCAT1STD.APT_Domestic_Pricing__c = true;
            products.add( productCAT1STD);
            //Startrack Product
            Product2 productNXF = APT_TestUtils.createStarTrackProduct('Next Flight Tier 1', 'NextFlightTier1', 'Parcel Services', 'T01', 'NXF', 'Startrack');
            productNXF.APT_Domestic_Pricing__c = true;
            products.add(productNXF);
            Product2 productEXP = APT_TestUtils.createStarTrackProduct('Road Express', 'RoadExpress', 'Parcel Services', 'T01', 'EXP', 'Startrack');
            productEXP.APT_Domestic_Pricing__c = true;
            products.add(productEXP);
            //International product 1
            Product2 productAIRLET = APT_TestUtils.createInternationalProduct('Air Mail Letters', 'AIRLET', 'Parcel Services');
            productAIRLET.APT_International_Pricing__c = true;
            products.add( productAIRLET);
            
            Product2 internationalProduct1 = APT_TestUtils.createInternationalProduct(APT_Constants.EXPRESS_DOCT_INTERNATIONAL_PRODUCT ,
                                                                                      APT_Constants.EXPRESS_DOCT_INTERNATIONAL_PRODUCT , 'Parcel Services');
            internationalProduct1.APT_International_Pricing__c = true;
            products.add(internationalProduct1);
            
            Product2 internationalProduct2 = APT_TestUtils.createInternationalProduct(APT_Constants.EXPRESS_MERCH_INTERNATIONAL_PRODUCT ,
                                                                                      APT_Constants.EXPRESS_MERCH_INTERNATIONAL_PRODUCT , 'Parcel Services');
            internationalProduct2.APT_International_Pricing__c = true;
            products.add( internationalProduct2);
            
            Product2 internationalProduct3 = APT_TestUtils.createInternationalProduct(APT_Constants.STANDARD_INTERNATIONAL_PRODUCT ,
                                                                                      APT_Constants.STANDARD_INTERNATIONAL_PRODUCT , 'Parcel Services');
            internationalProduct3.APT_International_Pricing__c = true;
            products.add(internationalProduct3);
            
            Product2 internationalProduct4 = APT_TestUtils.createInternationalProduct(APT_Constants.STANDARD_SIGN_INTERNATIONAL_PRODUCT  ,
                                                                                      APT_Constants.STANDARD_SIGN_INTERNATIONAL_PRODUCT  , 'Parcel Services');
            internationalProduct4.APT_International_Pricing__c = true;
            products.add( internationalProduct4);
            
            Product2 internationalProduct5 = APT_TestUtils.createInternationalProduct(APT_Constants.ECONOMY_INTERNATIONAL_PRODUCT,
                                                                                      APT_Constants.ECONOMY_INTERNATIONAL_PRODUCT, 'Parcel Services');
            internationalProduct5.APT_International_Pricing__c = true;
            products.add( internationalProduct5);
            
            Product2 internationalProduct6 = APT_TestUtils.createInternationalProduct(APT_Constants.ECONOMY_SIGN_INTERNATIONAL_PRODUCT,
                                                                                      APT_Constants.ECONOMY_SIGN_INTERNATIONAL_PRODUCT, 'Parcel Services');
            internationalProduct6.APT_International_Pricing__c = true;
            products.add( internationalProduct6);
            
            Product2 internationalProduct7 = APT_TestUtils.createInternationalProduct(APT_Constants.PRODUCT_CODE_NEW_AIRMAIL_LETTERS,
                                                                                      APT_Constants.PRODUCT_CODE_NEW_AIRMAIL_LETTERS, 'Parcel Services');
            internationalProduct7.APT_International_Pricing__c = true;
            products.add( internationalProduct7);
			
			Product2 internationalProduct8 = APT_TestUtils.createInternationalProduct(APT_Constants.AIRLET_INTERNATIONAL_PRODUCT,
                                                                                      APT_Constants.AIRLET_INTERNATIONAL_PRODUCT, 'Parcel Services');
            internationalProduct8.APT_International_Pricing__c = true;
            products.add( internationalProduct8);
			
			Product2 internationalProduct9 = APT_TestUtils.createInternationalProduct(APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT,
                                                                                      APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT, 'Parcel Services');
            internationalProduct9.APT_International_Pricing__c = true;
            products.add( internationalProduct9);
			
			Product2 internationalProduct10 = APT_TestUtils.createInternationalProduct(APT_Constants.AIRPTI_INTERNATIONAL_PRODUCT,
                                                                                      APT_Constants.AIRPTI_INTERNATIONAL_PRODUCT, 'Parcel Services');
            internationalProduct10.APT_International_Pricing__c = true;
            products.add( internationalProduct10);
			
			Product2 internationalProduct11 = APT_TestUtils.createInternationalProduct(APT_Constants.AIRRPI_INTERNATIONAL_PRODUCT,
                                                                                      APT_Constants.AIRRPI_INTERNATIONAL_PRODUCT, 'Parcel Services');
            internationalProduct11.APT_International_Pricing__c = true;
            products.add( internationalProduct11);
			
			Product2 internationalProduct12 = APT_TestUtils.createInternationalProduct(APT_Constants.AIRSMPCL_INTERNATIONAL_PRODUCT,
                                                                                      APT_Constants.AIRSMPCL_INTERNATIONAL_PRODUCT, 'Parcel Services');
            internationalProduct12.APT_International_Pricing__c = true;
            products.add( internationalProduct12);
			
			Product2 internationalProduct13 = APT_TestUtils.createInternationalProduct(APT_Constants.EMSDOCT_INTERNATIONAL_PRODUCT,
                                                                                      APT_Constants.EMSDOCT_INTERNATIONAL_PRODUCT, 'Parcel Services');
            internationalProduct13.APT_International_Pricing__c = true;
            products.add( internationalProduct13);
			
			Product2 internationalProduct14 = APT_TestUtils.createInternationalProduct(APT_Constants.EMSMERCH_INTERNATIONAL_PRODUCT,
                                                                                      APT_Constants.EMSMERCH_INTERNATIONAL_PRODUCT, 'Parcel Services');
            internationalProduct14.APT_International_Pricing__c = true;
            products.add( internationalProduct14);
			
			Product2 internationalProduct15 = APT_TestUtils.createInternationalProduct(APT_Constants.EMSMER20_INTERNATIONAL_PRODUCT,
                                                                                      APT_Constants.EMSMER20_INTERNATIONAL_PRODUCT, 'Parcel Services');
            internationalProduct15.APT_International_Pricing__c = true;
            products.add( internationalProduct15);
			
            insert products;
			
            list<Product2> internationalProducts = new list<Product2> {internationalProduct1,
                internationalProduct2,
                internationalProduct3/*,
                internationalProduct4,
                internationalProduct5,
                internationalProduct6, 
                internationalProduct7,
                internationalProduct8,
                internationalProduct9,
                internationalProduct10,
                internationalProduct11,
                internationalProduct12,
                internationalProduct13,
                internationalProduct14,
                internationalProduct15*/};
                  
            List<Apttus_Config2__PriceListItem__c> priceListItemList = new List<Apttus_Config2__PriceListItem__c>();
            //pli for productCAT1STD
            Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id,productCAT1STD.id,'','');
            priceListItem.APT_Pricing_Key__c = productCAT1STD.Id + '~' + 'BANDED {Z6}' + '~' + 'CB';	
            priceListItem.APT_Band__c = 'Band 2';
            priceListItemList.add(priceListItem);
            //pli for product NXF
            Apttus_Config2__PriceListItem__c priceListItem2 = APT_TestUtils.createPriceListItem(priceList.id,productNXF.id,'','');
            priceListItem2.APT_Pricing_Key__c = productNXF.Id;
            priceListItem2.APT_Zone_Combination__c = productNXF.Id;
            priceListItem2.APT_Band__c = 'Band 2';
            priceListItemList.add(priceListItem2);
            
            Apttus_Config2__PriceListItem__c priceListItem3 = APT_TestUtils.createPriceListItem(priceList.id,productEXP.id,'','');
            priceListItem3.APT_Pricing_Key__c = productEXP.Id+'~'+'QC3';
            priceListItem3.APT_Zone_Combination__c = productEXP.Id +'~QC3~Direct-QC3';
            priceListItem3.APT_Band__c = 'Band 2';
            priceListItemList.add(priceListItem3);             
            
            Apttus_Config2__PriceListItem__c priceListItem4 = APT_TestUtils.createPriceListItem(priceList.id,productAIRLET.id,'','');
            priceListItem4.APT_Pricing_Key__c = productAIRLET.Id + '~' + productAIRLET.Productcode+'~'+'BAND 2';
            priceListItem4.APT_Band__c = 'Band 2';
            priceListItemList.add(priceListItem4);
            
            Apttus_Config2__PriceListItem__c priceListItemIP_1 = APT_TestUtils.createPriceListItem(priceList.id,internationalProduct1.id,'','');
            priceListItemIP_1.APT_Band__c = 'Band 2';
            priceListItemIP_1.APT_Band_Range_Max__c = 1000;
            priceListItemIP_1.APT_Pricing_Key__c = internationalProduct1.Id + '~' + internationalProduct1.Productcode+'~'+'BAND 2';
            priceListItemList.add(priceListItemIP_1);
            
            Apttus_Config2__PriceListItem__c priceListItemIP_2 = APT_TestUtils.createPriceListItem(priceList.id,internationalProduct2.id,'','');
            priceListItemIP_2.APT_Band__c = 'Band 2';
            priceListItemIP_2.APT_Band_Range_Max__c = 1000;
            priceListItemIP_2.APT_Pricing_Key__c = internationalProduct2.Id + '~' + internationalProduct2.Productcode+'~'+'BAND 2';
            priceListItemList.add(priceListItemIP_2);
            
            Apttus_Config2__PriceListItem__c priceListItemIP_3 = APT_TestUtils.createPriceListItem(priceList.id,internationalProduct3.id,'','');
            priceListItemIP_3.APT_Band__c = 'Band 2';
            priceListItemIP_3.APT_Band_Range_Max__c = 1000;
            priceListItemIP_3.APT_Pricing_Key__c = internationalProduct3.Id + '~' + internationalProduct3.Productcode+'~'+'BAND 2';
            priceListItemList.add(priceListItemIP_3);
            
            Apttus_Config2__PriceListItem__c priceListItemIP_4 = APT_TestUtils.createPriceListItem(priceList.id,internationalProduct4.id,'','');
            priceListItemIP_4.APT_Band__c = 'Band 2';
            priceListItemIP_4.APT_Band_Range_Max__c = 1000;
            priceListItemIP_4.APT_Pricing_Key__c = internationalProduct4.Id + '~' + internationalProduct4.Productcode+'~'+'BAND 2';
            priceListItemList.add(priceListItemIP_4);
            
            Apttus_Config2__PriceListItem__c priceListItemIP_5 = APT_TestUtils.createPriceListItem(priceList.id,internationalProduct5.id,'','');
            priceListItemIP_5.APT_Band__c = 'Band 2';
            priceListItemIP_5.APT_Band_Range_Max__c = 1000;
            priceListItemIP_5.APT_Pricing_Key__c = internationalProduct5.Id + '~' + internationalProduct5.Productcode+'~'+'BAND 2';
            priceListItemList.add(priceListItemIP_5);
            
            Apttus_Config2__PriceListItem__c priceListItemIP_6 = APT_TestUtils.createPriceListItem(priceList.id,internationalProduct6.id,'','');
            priceListItemIP_6.APT_Band__c = 'Band 2';
            priceListItemIP_6.APT_Band_Range_Max__c = 1000;
            priceListItemIP_6.APT_Pricing_Key__c = internationalProduct6.Id + '~' + internationalProduct6.Productcode+'~'+'BAND 2';
            priceListItemList.add(priceListItemIP_6);
			
			Apttus_Config2__PriceListItem__c priceListItemIP_7 = APT_TestUtils.createPriceListItem(priceList.id,internationalProduct7.id,'','');
            priceListItemIP_7.APT_Band__c = 'Band 2';
            priceListItemIP_7.APT_Band_Range_Max__c = 1000;
            priceListItemIP_7.APT_Pricing_Key__c = internationalProduct7.Id + '~' + internationalProduct7.Productcode+'~'+'BAND 2';
            priceListItemList.add(priceListItemIP_7);
			
			Apttus_Config2__PriceListItem__c priceListItemIP_8 = APT_TestUtils.createPriceListItem(priceList.id,internationalProduct8.id,'','');
            priceListItemIP_8.APT_Band__c = 'Band 2';
            priceListItemIP_8.APT_Band_Range_Max__c = 1000;
            priceListItemIP_8.APT_Pricing_Key__c = internationalProduct8.Id + '~' + internationalProduct8.Productcode+'~'+'BAND 2';
            priceListItemList.add(priceListItemIP_8);
			
			Apttus_Config2__PriceListItem__c priceListItemIP_9 = APT_TestUtils.createPriceListItem(priceList.id,internationalProduct9.id,'','');
            priceListItemIP_9.APT_Band__c = 'Band 2';
            priceListItemIP_9.APT_Band_Range_Max__c = 1000;
            priceListItemIP_9.APT_Pricing_Key__c = internationalProduct9.Id + '~' + internationalProduct9.Productcode+'~'+'BAND 2';
            priceListItemList.add(priceListItemIP_9);
            
			Apttus_Config2__PriceListItem__c priceListItemIP_10  = APT_TestUtils.createPriceListItem(priceList.id,internationalProduct10.id,'','');
            priceListItemIP_10 .APT_Band__c = 'Band 2';
            priceListItemIP_10 .APT_Band_Range_Max__c = 1000;
            priceListItemIP_10 .APT_Pricing_Key__c = internationalProduct10.Id + '~' + internationalProduct10.Productcode+'~'+'BAND 2';
            priceListItemList.add(priceListItemIP_10 );

			Apttus_Config2__PriceListItem__c priceListItemIP_11 = APT_TestUtils.createPriceListItem(priceList.id,internationalProduct11.id,'','');
            priceListItemIP_11.APT_Band__c = 'Band 2';
            priceListItemIP_11.APT_Band_Range_Max__c = 1000;
            priceListItemIP_11.APT_Pricing_Key__c = internationalProduct11.Id + '~' + internationalProduct11.Productcode+'~'+'BAND 2';
            priceListItemList.add(priceListItemIP_11);
			
			Apttus_Config2__PriceListItem__c priceListItemIP_12 = APT_TestUtils.createPriceListItem(priceList.id,internationalProduct12.id,'','');
            priceListItemIP_12.APT_Band__c = 'Band 2';
            priceListItemIP_12.APT_Band_Range_Max__c = 1000;
            priceListItemIP_12.APT_Pricing_Key__c = internationalProduct12.Id + '~' + internationalProduct12.Productcode+'~'+'BAND 2';
            priceListItemList.add(priceListItemIP_12);
			
			Apttus_Config2__PriceListItem__c priceListItemIP_13 = APT_TestUtils.createPriceListItem(priceList.id,internationalProduct13.id,'','');
            priceListItemIP_13.APT_Band__c = 'Band 2';
            priceListItemIP_13.APT_Band_Range_Max__c = 1000;
            priceListItemIP_13.APT_Pricing_Key__c = internationalProduct13.Id + '~' + internationalProduct13.Productcode+'~'+'BAND 2';
            priceListItemList.add(priceListItemIP_13);
			
			Apttus_Config2__PriceListItem__c priceListItemIP_14 = APT_TestUtils.createPriceListItem(priceList.id,internationalProduct14.id,'','');
            priceListItemIP_14.APT_Band__c = 'Band 2';
            priceListItemIP_14.APT_Band_Range_Max__c = 1000;
            priceListItemIP_14.APT_Pricing_Key__c = internationalProduct14.Id + '~' + internationalProduct14.Productcode+'~'+'BAND 2';
            priceListItemList.add(priceListItemIP_14);
			
			Apttus_Config2__PriceListItem__c priceListItemIP_15 = APT_TestUtils.createPriceListItem(priceList.id,internationalProduct15.id,'','');
            priceListItemIP_15.APT_Band__c = 'Band 2';
            priceListItemIP_15.APT_Band_Range_Max__c = 1000;
            priceListItemIP_15.APT_Pricing_Key__c = internationalProduct15.Id + '~' + internationalProduct15.Productcode+'~'+'BAND 2';
            priceListItemList.add(priceListItemIP_15);
			
            insert priceListItemList;
            
            Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = APT_TestUtils.createProductAttributeGroup('Apttus_Config2__ProductAttributeValue__c');
            insert productAttributeGroup;
            
            Apttus_Config2__ProductAttribute__c productAttribute = APT_TestUtils.createProductAttribute('APT_Zone__c', productAttributeGroup.Id);
            insert productAttribute;
            
            list<Apttus_Config2__PriceDimension__c> listPriceDimension = new list<Apttus_Config2__PriceDimension__c>();
            Apttus_Config2__PriceDimension__c priceDimension1 = APT_TestUtils.createPriceDimension('Destination Zone Code', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Destination_Zone_Code__c', productAttribute.Id);
            listPriceDimension.add(priceDimension1);
            
            Apttus_Config2__PriceDimension__c priceDimension2 = APT_TestUtils.createPriceDimension('Domestic Price Type', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Domestic_Price_Type__c', productAttribute.Id);
            listPriceDimension.add(priceDimension2);
            
            Apttus_Config2__PriceDimension__c priceDimension3 = APT_TestUtils.createPriceDimension('Weight Range Code', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Weight_Range_Code__c', productAttribute.Id);
            listPriceDimension.add(priceDimension3);
            
            Apttus_Config2__PriceDimension__c priceDimension4 = APT_TestUtils.createPriceDimension('Zone Type', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Zone_Type__c', productAttribute.Id);
            listPriceDimension.add(priceDimension4); 
            
            Apttus_Config2__PriceDimension__c priceDimension5 = APT_TestUtils.createPriceDimension('Inbound - Outbound', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Inbound_Outbound__c', productAttribute.Id);
            listPriceDimension.add(priceDimension5);
            
            Apttus_Config2__PriceDimension__c priceDimension6 = APT_TestUtils.createPriceDimension('Pickup Zone Code', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Pickup_Zone_Code__c', productAttribute.Id);
            listPriceDimension.add(priceDimension6);
            
            Apttus_Config2__PriceDimension__c priceDimension7 = APT_TestUtils.createPriceDimension('Price Type', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Price_Type__c', productAttribute.Id);
            listPriceDimension.add(priceDimension7);
            
            Apttus_Config2__PriceDimension__c priceDimension8 = APT_TestUtils.createPriceDimension('Basic Charge', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Basic_Charge__c', productAttribute.Id);
            listPriceDimension.add(priceDimension8);            
            
            Apttus_Config2__PriceDimension__c priceDimension9 = APT_TestUtils.createPriceDimension('KG Rate', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_KG_Rate__c', productAttribute.Id);
            listPriceDimension.add(priceDimension9); 
            
            Apttus_Config2__PriceDimension__c priceDimension10 = APT_TestUtils.createPriceDimension('Minimum Charge', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Minimum_Charge__c', productAttribute.Id);
            listPriceDimension.add(priceDimension10);
            
            Apttus_Config2__PriceDimension__c priceDimension11 = APT_TestUtils.createPriceDimension('Zone', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Zone__c', productAttribute.Id);
            listPriceDimension.add(priceDimension11);
            
            Apttus_Config2__PriceDimension__c priceDimension12 = APT_TestUtils.createPriceDimension('International Price Type', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
            listPriceDimension.add(priceDimension12);
            
            Apttus_Config2__PriceDimension__c priceDimension13 = APT_TestUtils.createPriceDimension('Weight Range', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'Weight_Range__c', productAttribute.Id);
            listPriceDimension.add(priceDimension13);    
            
            insert listPriceDimension;
            
            List<Apttus_Config2__PriceMatrix__c> listPM = new List<Apttus_Config2__PriceMatrix__c>();
            Apttus_Config2__PriceMatrix__c priceMatrix = APT_TestUtils.createPriceMatrix(pli.Id, priceDimension1.Id, priceDimension2.Id, priceDimension3.Id);
            listPM.add(priceMatrix);
            
            // PM for the Pli corresponding to NXF 
            Apttus_Config2__PriceMatrix__c priceMatrix1 = APT_TestUtils.createPriceMatrix(priceListItem2.Id, priceDimension6.Id, priceDimension1.Id, priceDimension8.Id);
            priceMatrix1.Apttus_Config2__Dimension4Id__c = priceDimension9.Id;
            priceMatrix1.Apttus_Config2__Dimension4ValueType__c = 'Discrete';
            priceMatrix1.Apttus_Config2__Dimension5Id__c = priceDimension10.Id;
            priceMatrix1.Apttus_Config2__Dimension5ValueType__c = 'Discrete';
            listPM.add(priceMatrix1);   
            
            // PM for the Pli corresponding to EXP 1
            Apttus_Config2__PriceMatrix__c priceMatrix2 = APT_TestUtils.createPriceMatrix(priceListItem3.Id,priceDimension4.Id, priceDimension5.Id, priceDimension6.Id);
            priceMatrix2.Apttus_Config2__Dimension4Id__c = priceDimension1.Id;
            priceMatrix2.Apttus_Config2__Dimension4ValueType__c = 'Discrete';
            priceMatrix2.Apttus_Config2__Dimension5Id__c = priceDimension7.Id;
            priceMatrix2.Apttus_Config2__Dimension5ValueType__c = 'Discrete';
            listPM.add(priceMatrix2); 
            
            // PM for the Pli corresponding to AIRLET
            Apttus_Config2__PriceMatrix__c priceMatrix3 = APT_TestUtils.createPriceMatrix(priceListItem4.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
            listPM.add(priceMatrix3);          
            
            Apttus_Config2__PriceMatrix__c priceMatrixIP_1 = APT_TestUtils.createPriceMatrix(priceListItemIP_1.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
            listPM.add(priceMatrixIP_1);          
            
            Apttus_Config2__PriceMatrix__c priceMatrixIP_2 = APT_TestUtils.createPriceMatrix(priceListItemIP_2.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
            listPM.add(priceMatrixIP_2);          
            
            Apttus_Config2__PriceMatrix__c priceMatrixIP_3 = APT_TestUtils.createPriceMatrix(priceListItemIP_3.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
            listPM.add(priceMatrixIP_3);          
            
            Apttus_Config2__PriceMatrix__c priceMatrixIP_4 = APT_TestUtils.createPriceMatrix(priceListItemIP_4.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
            listPM.add(priceMatrixIP_4);                     
			
			Apttus_Config2__PriceMatrix__c priceMatrixIP_5 = APT_TestUtils.createPriceMatrix(priceListItemIP_5.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
            listPM.add(priceMatrixIP_5);  

			Apttus_Config2__PriceMatrix__c priceMatrixIP_6 = APT_TestUtils.createPriceMatrix(priceListItemIP_6.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
            listPM.add(priceMatrixIP_6);  			
            
			Apttus_Config2__PriceMatrix__c priceMatrixIP_7 = APT_TestUtils.createPriceMatrix(priceListItemIP_7.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
            listPM.add(priceMatrixIP_7);  
			
			Apttus_Config2__PriceMatrix__c priceMatrixIP_8 = APT_TestUtils.createPriceMatrix(priceListItemIP_8.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
            listPM.add(priceMatrixIP_8);  
			
			Apttus_Config2__PriceMatrix__c priceMatrixIP_9 = APT_TestUtils.createPriceMatrix(priceListItemIP_9.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
            listPM.add(priceMatrixIP_9);  
			
			Apttus_Config2__PriceMatrix__c priceMatrixIP_10 = APT_TestUtils.createPriceMatrix(priceListItemIP_10.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
            listPM.add(priceMatrixIP_10);  
			
			Apttus_Config2__PriceMatrix__c priceMatrixIP_11 = APT_TestUtils.createPriceMatrix(priceListItemIP_11.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
            listPM.add(priceMatrixIP_11);  
			
			Apttus_Config2__PriceMatrix__c priceMatrixIP_12 = APT_TestUtils.createPriceMatrix(priceListItemIP_12.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
            listPM.add(priceMatrixIP_12);  
			
			Apttus_Config2__PriceMatrix__c priceMatrixIP_13 = APT_TestUtils.createPriceMatrix(priceListItemIP_13.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
            listPM.add(priceMatrixIP_13);  
			
			Apttus_Config2__PriceMatrix__c priceMatrixIP_14 = APT_TestUtils.createPriceMatrix(priceListItemIP_14.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
            listPM.add(priceMatrixIP_14);  
			
			Apttus_Config2__PriceMatrix__c priceMatrixIP_15 = APT_TestUtils.createPriceMatrix(priceListItemIP_15.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
            listPM.add(priceMatrixIP_15);  
			
            insert listPM;
            System.debug('Line: 1387');
            list<Apttus_Config2__PriceMatrixEntry__c> listPME = new list<Apttus_Config2__PriceMatrixEntry__c>();
            Apttus_Config2__PriceMatrixEntry__c pme1 = new Apttus_Config2__PriceMatrixEntry__c();
            pme1.Apttus_Config2__Dimension1Value__c = '1';
            pme1.Apttus_Config2__Dimension2Value__c = '2';
            pme1.Apttus_Config2__Dimension3Value__c = '';
            pme1.Apttus_Config2__PriceMatrixId__c = priceMatrix.Id;
            pme1.Apttus_Config2__Sequence__c = 1;
            pme1.Apttus_Config2__UsageRate__c = 1;
            pme1.Apttus_Config2__AdjustmentAmount__c = 1;
            pme1.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pme1);
            
            Apttus_Config2__PriceMatrixEntry__c pme2 = new Apttus_Config2__PriceMatrixEntry__c();
            pme2.Apttus_Config2__Dimension1Value__c = '1';
            pme2.Apttus_Config2__Dimension2Value__c = '2';
            pme2.Apttus_Config2__Dimension3Value__c = '';
            pme2.Apttus_Config2__PriceMatrixId__c = priceMatrix1.Id;
            pme2.Apttus_Config2__Sequence__c = 1;
            pme2.Apttus_Config2__UsageRate__c = 1;
            pme2.Apttus_Config2__AdjustmentAmount__c = 1;
            pme2.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pme2);
            
            Apttus_Config2__PriceMatrixEntry__c pme3 = new Apttus_Config2__PriceMatrixEntry__c();
            pme3.Apttus_Config2__Dimension1Value__c = '1';
            pme3.Apttus_Config2__Dimension2Value__c = '2';
            pme3.Apttus_Config2__Dimension3Value__c = '';
            pme3.Apttus_Config2__PriceMatrixId__c = priceMatrix2.Id;
            pme3.Apttus_Config2__Sequence__c = 1;
            pme3.Apttus_Config2__UsageRate__c = 1;
            pme3.Apttus_Config2__AdjustmentAmount__c = 1;
            pme3.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pme3);
            
            Apttus_Config2__PriceMatrixEntry__c pme4 = new Apttus_Config2__PriceMatrixEntry__c();
            pme4.Apttus_Config2__Dimension1Value__c = 'Zone1';
            pme4.Apttus_Config2__Dimension2Value__c = '2';
            pme4.Apttus_Config2__Dimension3Value__c = '3';
            pme4.Apttus_Config2__PriceMatrixId__c = priceMatrix3.Id;
            pme4.Apttus_Config2__Sequence__c = 1;
            pme4.Apttus_Config2__UsageRate__c = 1;
            pme4.Apttus_Config2__AdjustmentAmount__c = 1;
            pme4.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pme4);         
            
            Apttus_Config2__PriceMatrixEntry__c pmeIP_1 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_1.Apttus_Config2__Dimension1Value__c = 'Zone1';
            pmeIP_1.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_1.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_1.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_1.Id;
            pmeIP_1.Apttus_Config2__Sequence__c = 1;
            pmeIP_1.Apttus_Config2__UsageRate__c = 1;
            pmeIP_1.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_1.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_1);         
            
            Apttus_Config2__PriceMatrixEntry__c pmeIP_2 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_2.Apttus_Config2__Dimension1Value__c = 'Zone2';
            pmeIP_2.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_2.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_2.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_2.Id;
            pmeIP_2.Apttus_Config2__Sequence__c = 1;
            pmeIP_2.Apttus_Config2__UsageRate__c = 1;
            pmeIP_2.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_2.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_2);         
            
            Apttus_Config2__PriceMatrixEntry__c pmeIP_3 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_3.Apttus_Config2__Dimension1Value__c = 'Zone3';
            pmeIP_3.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_3.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_3.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_3.Id;
            pmeIP_3.Apttus_Config2__Sequence__c = 1;
            pmeIP_3.Apttus_Config2__UsageRate__c = 1;
            pmeIP_3.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_3.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_3);         
            
            Apttus_Config2__PriceMatrixEntry__c pmeIP_4 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_4.Apttus_Config2__Dimension1Value__c = 'Zone4';
            pmeIP_4.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_4.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_4.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_4.Id;
            pmeIP_4.Apttus_Config2__Sequence__c = 1;
            pmeIP_4.Apttus_Config2__UsageRate__c = 1;
            pmeIP_4.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_4.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_4);         
			
			Apttus_Config2__PriceMatrixEntry__c pmeIP_5 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_5.Apttus_Config2__Dimension1Value__c = 'Zone5';
            pmeIP_5.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_5.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_5.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_5.Id;
            pmeIP_5.Apttus_Config2__Sequence__c = 1;
            pmeIP_5.Apttus_Config2__UsageRate__c = 1;
            pmeIP_5.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_5.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_5);         
			
			Apttus_Config2__PriceMatrixEntry__c pmeIP_6 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_6.Apttus_Config2__Dimension1Value__c = 'Zone6';
            pmeIP_6.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_6.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_6.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_6.Id;
            pmeIP_6.Apttus_Config2__Sequence__c = 1;
            pmeIP_6.Apttus_Config2__UsageRate__c = 1;
            pmeIP_6.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_6.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_6);         
			
			Apttus_Config2__PriceMatrixEntry__c pmeIP_6_1 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_6_1.Apttus_Config2__Dimension1Value__c = 'Zone7';
            pmeIP_6_1.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_6_1.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_6_1.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_6.Id;
            pmeIP_6_1.Apttus_Config2__Sequence__c = 1;
            pmeIP_6_1.Apttus_Config2__UsageRate__c = 1;
            pmeIP_6_1.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_6_1.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_6_1);         
			
			Apttus_Config2__PriceMatrixEntry__c pmeIP_6_2 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_6_2.Apttus_Config2__Dimension1Value__c = 'Zone8';
            pmeIP_6_2.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_6_2.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_6_2.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_6.Id;
            pmeIP_6_2.Apttus_Config2__Sequence__c = 1;
            pmeIP_6_2.Apttus_Config2__UsageRate__c = 1;
            pmeIP_6_2.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_6_2.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_6_2);         
			
			Apttus_Config2__PriceMatrixEntry__c pmeIP_6_3 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_6_3.Apttus_Config2__Dimension1Value__c = 'Zone9';
            pmeIP_6_3.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_6_3.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_6_3.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_6.Id;
            pmeIP_6_3.Apttus_Config2__Sequence__c = 1;
            pmeIP_6_3.Apttus_Config2__UsageRate__c = 1;
            pmeIP_6_3.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_6_3.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_6_3);         
			
			Apttus_Config2__PriceMatrixEntry__c pmeIP_6_4 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_6_4.Apttus_Config2__Dimension1Value__c = 'Zone10';
            pmeIP_6_4.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_6_4.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_6_4.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_6.Id;
            pmeIP_6_4.Apttus_Config2__Sequence__c = 1;
            pmeIP_6_4.Apttus_Config2__UsageRate__c = 1;
            pmeIP_6_4.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_6_4.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_6_4);         
            
			Apttus_Config2__PriceMatrixEntry__c pmeIP_7 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_7.Apttus_Config2__Dimension1Value__c = 'Zone7';
            pmeIP_7.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_7.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_7.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_7.Id;
            pmeIP_7.Apttus_Config2__Sequence__c = 1;
            pmeIP_7.Apttus_Config2__UsageRate__c = 1;
            pmeIP_7.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_7.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_7);    
			
			Apttus_Config2__PriceMatrixEntry__c pmeIP_7_1 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_7_1.Apttus_Config2__Dimension1Value__c = 'Zone1';
            pmeIP_7_1.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_7_1.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_7_1.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_7.Id;
            pmeIP_7_1.Apttus_Config2__Sequence__c = 1;
            pmeIP_7_1.Apttus_Config2__UsageRate__c = 1;
            pmeIP_7_1.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_7_1.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_7_1);    
			
			Apttus_Config2__PriceMatrixEntry__c pmeIP_7_2 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_7_2.Apttus_Config2__Dimension1Value__c = 'Zone2';
            pmeIP_7_2.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_7_2.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_7_2.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_7.Id;
            pmeIP_7_2.Apttus_Config2__Sequence__c = 1;
            pmeIP_7_2.Apttus_Config2__UsageRate__c = 1;
            pmeIP_7_2.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_7_2.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_7_2);    

			Apttus_Config2__PriceMatrixEntry__c pmeIP_7_3 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_7_3.Apttus_Config2__Dimension1Value__c = 'Zone3';
            pmeIP_7_3.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_7_3.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_7_3.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_7.Id;
            pmeIP_7_3.Apttus_Config2__Sequence__c = 1;
            pmeIP_7_3.Apttus_Config2__UsageRate__c = 1;
            pmeIP_7_3.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_7_3.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_7_3);    
			
			Apttus_Config2__PriceMatrixEntry__c pmeIP_7_4 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_7_4.Apttus_Config2__Dimension1Value__c = 'Zone4';
            pmeIP_7_4.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_7_4.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_7_4.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_7.Id;
            pmeIP_7_4.Apttus_Config2__Sequence__c = 1;
            pmeIP_7_4.Apttus_Config2__UsageRate__c = 1;
            pmeIP_7_4.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_7_4.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_7_4);    		

			Apttus_Config2__PriceMatrixEntry__c pmeIP_7_5 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_7_5.Apttus_Config2__Dimension1Value__c = 'Zone5';
            pmeIP_7_5.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_7_5.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_7_5.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_7.Id;
            pmeIP_7_5.Apttus_Config2__Sequence__c = 1;
            pmeIP_7_5.Apttus_Config2__UsageRate__c = 1;
            pmeIP_7_5.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_7_5.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_7_5);    

			Apttus_Config2__PriceMatrixEntry__c pmeIP_7_6 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_7_6.Apttus_Config2__Dimension1Value__c = 'Zone6';
            pmeIP_7_6.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_7_6.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_7_6.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_7.Id;
            pmeIP_7_6.Apttus_Config2__Sequence__c = 1;
            pmeIP_7_6.Apttus_Config2__UsageRate__c = 1;
            pmeIP_7_6.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_7_6.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_7_6);    

			Apttus_Config2__PriceMatrixEntry__c pmeIP_7_8 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_7_8.Apttus_Config2__Dimension1Value__c = 'Zone8';
            pmeIP_7_8.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_7_8.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_7_8.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_7.Id;
            pmeIP_7_8.Apttus_Config2__Sequence__c = 1;
            pmeIP_7_8.Apttus_Config2__UsageRate__c = 1;
            pmeIP_7_8.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_7_8.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_7_8);    			
		
			Apttus_Config2__PriceMatrixEntry__c pmeIP_8 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_8.Apttus_Config2__Dimension1Value__c = 'Zone8';
            pmeIP_8.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_8.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_8.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_8.Id;
            pmeIP_8.Apttus_Config2__Sequence__c = 1;
            pmeIP_8.Apttus_Config2__UsageRate__c = 1;
            pmeIP_8.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_8.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_8);         

			Apttus_Config2__PriceMatrixEntry__c pmeIP_9 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_9.Apttus_Config2__Dimension1Value__c = 'Zone9';
            pmeIP_9.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_9.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_9.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_9.Id;
            pmeIP_9.Apttus_Config2__Sequence__c = 1;
            pmeIP_9.Apttus_Config2__UsageRate__c = 1;
            pmeIP_9.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_9.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_9);         

			Apttus_Config2__PriceMatrixEntry__c pmeIP_10 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_10.Apttus_Config2__Dimension1Value__c = 'Zone1';
            pmeIP_10.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_10.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_10.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_10.Id;
            pmeIP_10.Apttus_Config2__Sequence__c = 1;
            pmeIP_10.Apttus_Config2__UsageRate__c = 1;
            pmeIP_10.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_10.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_10);         

			Apttus_Config2__PriceMatrixEntry__c pmeIP_11 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_11.Apttus_Config2__Dimension1Value__c = 'Zone2';
            pmeIP_11.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_11.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_11.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_11.Id;
            pmeIP_11.Apttus_Config2__Sequence__c = 1;
            pmeIP_11.Apttus_Config2__UsageRate__c = 1;
            pmeIP_11.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_11.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_11);         

			Apttus_Config2__PriceMatrixEntry__c pmeIP_12 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_12.Apttus_Config2__Dimension1Value__c = 'Zone3';
            pmeIP_12.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_12.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_12.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_12.Id;
            pmeIP_12.Apttus_Config2__Sequence__c = 1;
            pmeIP_12.Apttus_Config2__UsageRate__c = 1;
            pmeIP_12.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_12.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_12);         

			Apttus_Config2__PriceMatrixEntry__c pmeIP_13 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_13.Apttus_Config2__Dimension1Value__c = 'Zone4';
            pmeIP_13.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_13.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_13.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_13.Id;
            pmeIP_13.Apttus_Config2__Sequence__c = 1;
            pmeIP_13.Apttus_Config2__UsageRate__c = 1;
            pmeIP_13.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_13.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_13);         
			
			Apttus_Config2__PriceMatrixEntry__c pmeIP_14 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_14.Apttus_Config2__Dimension1Value__c = 'Zone5';
            pmeIP_14.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_14.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_14.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_14.Id;
            pmeIP_14.Apttus_Config2__Sequence__c = 1;
            pmeIP_14.Apttus_Config2__UsageRate__c = 1;
            pmeIP_14.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_14.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_14);         			
			
			Apttus_Config2__PriceMatrixEntry__c pmeIP_15 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_15.Apttus_Config2__Dimension1Value__c = 'Zone6';
            pmeIP_15.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_15.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_15.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_15.Id;
            pmeIP_15.Apttus_Config2__Sequence__c = 1;
            pmeIP_15.Apttus_Config2__UsageRate__c = 1;
            pmeIP_15.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_15.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_15);         
			
            insert listPME; 
            System.debug('Test PME Count Start: ');              
            integer  count= database.countQuery('select count() from Apttus_Config2__PriceMatrixEntry__c where Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_International_Pricing__c = true');
            System.debug('Test PME Count end: ' + count);              
            
            
            Test.starttest();    
            // update product Attribute value
            //attribute1.Category__c='CAT1';
            attribute1.APT_Distribution_Type_Printpost__c = 'Local Sort Division;Same State Metro;Other State;Large Postcode Direct';               
            attribute1.APT_Domestic_Customer__c = null;
            attribute1.APT_Band__c = 'Band 2';
            attribute1.Category__c=null;
            attribute1.APT_Lodgement_Zone__c = null;
            attribute1.Apttus_Config2__LineItemId__c = null;
            attribute1.APT_Volume_Data__c = APT_Constants.OPTION_YES;
            attribute1.APTS_Price_Structure__c = APT_Constants.STRING_BANDED_Z6;
            attribute1.APT_RK_Code_Applied__c = false;

            try{
                Update attribute1;     
            }
            Catch(Exception e){
                
            }
            try{
                attribute1.Category__c = APT_Constants.CATEGORY_CAT2;
                attribute1.APT_BAND__c = APT_Constants.BAND_2;
                Update attribute1;
                
            }
            Catch(Exception e){}
            try{
                attribute1.Category__c = APT_Constants.CATEGORY_CAT3;
                attribute1.APT_BAND__c = APT_Constants.BAND_3;
                Update attribute1;     
               
            }
            Catch(Exception e){
                
            }
            try{
                attribute1.Category__c = APT_Constants.CATEGORY_CAT4;
                Update attribute1;     
               
            }
            Catch(Exception e){
                
            }
            try{
                attribute1.Category__c = APT_Constants.CATEGORY_CAT5;
                attribute1.APT_BAND__c = APT_Constants.BAND_4;
                Update attribute1;     
               
            }
            Catch(Exception e){
                
            }
            try{
                attribute1.Category__c = APT_Constants.CATEGORY_CAT6;
                attribute1.APT_BAND__c = APT_Constants.BAND_5;
                Update attribute1;     
            }
            Catch(Exception e){
                
            }
            
            for(product2 product : internationalProducts){
                try
                {
                Apttus_Config2__PriceListItem__c priceListIt = [select Id,  Apttus_Config2__ProductId__r.ProductCode from Apttus_Config2__PriceListItem__c where Apttus_Config2__ProductId__r.ProductCode =: product.ProductCode limit 1];
                
                Apttus_Config2__LineItem__c internationalLine = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
                                                                                                1, 'Product/Service', product.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
                                                                                                null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
                                                                                                'Each', 1, priceList.Id, priceListIt.Id,//Uom, term, priceList, Pli,
                                                                                                'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
                                                                                                true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
                                                                                                5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
                internationalLine.Apttus_Config2__AllowManualAdjustment__c = true;
                internationalLine.Apttus_Config2__NetPrice__c = 5225;
                internationalLine.Apttus_Config2__PrimaryLineNumber__c = 1;
                internationalLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
                insert internationalLine;
            
             
             Apttus_Config2__ProductAttributeValue__c attribute_IP = APT_TestUtils.GetAttributeValue(internationalLine.Id,'Standard',false,false,false,'Yes','B Mining',True,false);
                    
            attribute_IP.Category__c='CAT1';
            attribute_IP.APT_Postcode__c = '2000';
            attribute_IP.APT_Lodgement_Zone__c=logdZone.ID; 
            attribute_IP.APT_AirmailSmallParcelGT2kgAVGWeightKG__c = 3;
            attribute_IP.APT_Distribution_Type_Printpost__c = 'Local Sort Division;Same State Metro;Other State';
            attribute_IP.APT_Volume_Threshold_Post_BillPay__c='25,001 – 100,000';
            attribute_IP.APT_PostBillPay_Volume_threshold__c='25,001 – 100,000';
            //attribute1.Apttus_Config2__LineItemId__c = null;
            attribute_IP.APT_Volume_Data__c = APT_Constants.OPTION_YES;
            attribute1.APT_RK_Code_Applied__c = false;
            attribute_IP.APT_Domestic_Customer__c = null;
            insert attribute_IP; 
                
                attribute_IP.Category__c = APT_Constants.CATEGORY_CAT2;
                    
                    try{
                    
                        update attribute_IP;
                    }
                    catch(Exception e){}
                    if(product.ProductCode == APT_Constants.STANDARD_INTERNATIONAL_PRODUCT){
                        try{
                            attribute_IP.APT_International_Standard_Weight_Kgs__c = 1;
                            update attribute_IP;
                        }catch(Exception e){}
                        try{
                            attribute_IP.APT_International_Standard_Weight_Kgs__c = 2;
                            update attribute_IP;
                        }catch(Exception e){}
                        try{
                            attribute_IP.APT_International_Standard_Weight_Kgs__c = 10;
                            update attribute_IP;
                        }catch(Exception e){}
                    }
                    
                   else if(product.ProductCode == APT_Constants.STANDARD_SIGN_INTERNATIONAL_PRODUCT){
                        try{
                            attribute_IP.APT_International_Std_W_Sig_Weight_Kgs__c = 1;
                            update attribute_IP;
                        }catch(Exception e){}
                        try{
                            attribute_IP.APT_International_Std_W_Sig_Weight_Kgs__c = 2;
                            update attribute_IP;
                        }catch(Exception e){}
                        try{
                            attribute_IP.APT_International_Std_W_Sig_Weight_Kgs__c = 10;
                            update attribute_IP;
                        }catch(Exception e){}
                    }
                     else if(product.ProductCode == APT_Constants.ECONOMY_SIGN_INTERNATIONAL_PRODUCT){
                        try{
                            attribute_IP.APT_International_Eco_W_Sig_Weight_Kgs__c = 1;
                            update attribute_IP;
                        }catch(Exception e){}
                        try{
                            attribute_IP.APT_International_Eco_W_Sig_Weight_Kgs__c = 2;
                            update attribute_IP;
                        }catch(Exception e){}
                    }
                    else if(product.ProductCode == APT_Constants.ECONOMY_INTERNATIONAL_PRODUCT){
                        try{
                            attribute_IP.APT_International_Economy_Weight_Kgs__c = 1;
                            update attribute_IP;
                        }catch(Exception e){}
                        try{
                            attribute_IP.APT_International_Economy_Weight_Kgs__c = 2;
                            update attribute_IP;
                        }catch(Exception e){}
                    }
                    else if(product.ProductCode == APT_Constants.EXPRESS_MERCH_INTERNATIONAL_PRODUCT){
                        try{
                            attribute_IP.APT_International_Exp_Merch_Weight_Kgs__c = 1;
                            update attribute_IP;
                        }catch(Exception e){}
                        try{
                            attribute_IP.APT_International_Exp_Merch_Weight_Kgs__c = 2;
                            update attribute_IP;
                        }catch(Exception e){}
                        try{
                            attribute_IP.APT_International_Exp_Merch_Weight_Kgs__c = 10;
                            update attribute_IP;
                        }catch(Exception e){}
                    }
					 else if(product.ProductCode == APT_Constants.ECONOMY_SIGN_INTERNATIONAL_PRODUCT){
                        try{
                            attribute_IP.APT_International_Eco_W_Sig_Weight_Kgs__c = 1;
                            update attribute_IP;
                        }catch(Exception e){}
                        try{
                            attribute_IP.APT_International_Eco_W_Sig_Weight_Kgs__c = 2;
                            update attribute_IP;
                        }catch(Exception e){}
                    }
					
                    
                }
                catch(Exception e){
                    
                }
            }
            
            //system.assert('SUCCESS' == APT_Constants.SUCCESS_LABEL);
            Test.stoptest();
            //system.assert(listInternationalPriceData.size()>0);
            //System.assertEquals(listProduct[0],'AIRMAIL_LETTERS');
            //system.assert(attribute1.Apttus_Config2__LineItemId__c !=null);      
        }
        
        double num=0;
        set<string> s11=new set<string>();
        s11.add('Zone6');
        list<APT_International_Price_Data__c> listIdpData=new list<APT_International_Price_Data__c>();
        APT_International_Price_Data__c ipd1 = APT_TestUtils.createInternationalPriceData('EXPRESS_DOCT', 'B Mining', 'BAND 2', null, 0, 2999, 10, 10, 20, 20);
        listIdpData.add(ipd1);
        string data=listIdpData[0].APT_Band__c + APT_Constants.SEPERATOR_SIMILARITY + listIdpData[0].APT_Product__c + APT_Constants.SEPERATOR_SIMILARITY + listIdpData[0].APT_Zone__c;
        map<string, list<APT_International_Price_Data__c>> mapDataPrice=new map<string,list<APT_International_Price_Data__c>>();
        mapDataPrice.put(data,listIdpData);
        
        //APT_ProductAttributeValueTriggerHandler.calculateProductRevenueforNewIntBundle(num,Null,'BAND 2','EXPRESS_DOCT',s11,'CSP',mapDataPrice,null);
        //APT_ProductAttributeValueTriggerHandler.calculateProductRevenueforNewIntBundle(num,Null,'BAND 2','EXPRESS_DOCT',s11,'CSP',mapDataPrice,null);
    }    

@isTest
    public static void testMethodePCMSbundles1_1()     
    {
        UserRole role = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
        insert role;

        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
                                 EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
                                 LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
                                 TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
                                 UserName=APT_Constants.EMAIL_TEST_USER, UserRoleId = role.Id);
        System.runAs(testuser) {    
            //Create Account
            Account acc = APT_TestUtils.createOrganisation();
            acc.Industry = 'Logistics';
            insert acc;
            
            //Create Opportunity
            Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
            insert opty;
            
            //Create PriceList
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            //create international product
            Product2 bundle1 = APT_TestUtils.createInternationalProduct('International Digital PCMS Bundle incl Airmail Letters',
                                                                        'InternationalDigitalPCMSBundlewithAirmail','Parcel Services');
            bundle1.ProductCode = null;
            insert bundle1;
            
            //Create Price list Item
            Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
            pli.APT_Band__c = 'Band 2';
            insert pli;
            
            //Create Proposal
            Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
            insert Proposal;
            
            //Create Product Configuration             
            Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
                                                                                                       proposal.Id, 'Proposal',
                                                                                                       'Ad Hoc',priceList.Id, null,
                                                                                                       'Ready For Finalization',
                                                                                                       null, Datetime.now(), true);
            prodconfig.Apttus_Config2__AccountId__c =null;
            insert prodconfig;
            System.debug('Line: 1121');
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
            insert bundleLine;                  
            
            //create Logdement Zone             
            APT_Lodgement_Zone__c logdZone = APT_TestUtils.getLodgementZone('Aust Antarctic Territory','AAT');
            logdZone.APT_Post_Code_Start__c = 1000;
            logdZone.APT_Post_Code_End__c = 9000;
            insert logdZone;               
            
            //international price data
            list<APT_International_Price_Data__c> listInternationalPriceData = new list<APT_International_Price_Data__c>();
            List<String> listProduct = new List<String>{APT_Constants.PRODUCT_AIRMAILLETTER,
                APT_Constants.PRODUCT_InternationalExpressDocuments,
                APT_Constants.PRODUCT_InternationalExpressMerchandise,
                APT_Constants.PRODUCT_InternationalStandard,
                APT_Constants.PRODUCT_INTERNATIONALSTANDARDWITHSIGNATURE,
                APT_Constants.PRODUCT_InternationalEconomy,
                APT_Constants.PRODUCT_INTERNATIONALECONOMYWITHSIGNATURE};
                    
                    
                    for(string prod:listProduct)
                {
                    for(integer i=1;i<=9;i++)
                    {
                        
                        //APT_International_Price_Data__c ipd = APT_TestUtils.createInternationalPriceData(prod, 'B Mining', 'BAND 2', 'Zone'+i, 0, 2999, 10, 10, 20, 20);
                        APT_International_Price_Data__c ipd = new APT_International_Price_Data__c();
                        ipd.APT_Product__c = prod;
                        ipd.APT_Industry__c = 'B Mining';
                        ipd.APT_Band__c = 'BAND 2';
                        ipd.APT_Zone__c = 'Zone'+i;
                        ipd.APT_Band_Range_Min__c = 0;
                        ipd.APT_Band_Range_Max__c = 2999;
                        ipd.APT_CSP_Per_Item_Rate__c = 10;
                        ipd.APT_CSP_Per_Kg_Rate__c = 10;
                        ipd.APT_eParcel_Per_Item_Rate__c = 10;
                        ipd.APT_eParcel_Per_Kg_Rate__c = 10;
                        ipd.APT_Weight__c = 'up to 500g';
                        listInternationalPriceData.add(ipd);             
                        
                    } 
                }           
            
            
            
            insert listInternationalPriceData;
            
            //Create Feature Pricing              
            APT_Feature_Pricing__c featurePricing = APT_TestUtils.getFeaturePricing('Aust Antarctic Territory','CAT1','AAT','Standard','EPR2',10,1);           
            insert featurePricing;
            
            //Create product Attribute value                
            Apttus_Config2__ProductAttributeValue__c attribute1 = APT_TestUtils.GetAttributeValue(bundleLine.Id,'Standard',false,false,false,'Yes','B Mining',True,false);
            attribute1.Category__c='CAT1';
            attribute1.APT_Postcode__c = '2000';
            attribute1.APT_Lodgement_Zone__c=logdZone.ID; 
            attribute1.APT_AirmailSmallParcelGT2kgAVGWeightKG__c = 3;
            attribute1.APT_Distribution_Type_Printpost__c = 'Local Sort Division;Same State Metro;Other State';
            attribute1.APT_Volume_Threshold_Post_BillPay__c='25,001 – 100,000';
            attribute1.APT_PostBillPay_Volume_threshold__c='25,001 – 100,000';
            //attribute1.Apttus_Config2__LineItemId__c = null;
            attribute1.APT_Domestic_Customer__c = null;
            insert attribute1; 
            
            list<Product2> products = new list<Product2>();
            
            //Domestic (non startrack) product
            Product2 productCAT1STD = APT_TestUtils.createDomesticProduct('CAT1 Standard', 'CAT1Standard', 'Parcel Services', 'CAT1', 'STANDARD');
            productCAT1STD.APT_Domestic_Pricing__c = true;
            products.add( productCAT1STD);
            //Startrack Product
            Product2 productNXF = APT_TestUtils.createStarTrackProduct('Next Flight Tier 1', 'NextFlightTier1', 'Parcel Services', 'T01', 'NXF', 'Startrack');
            productNXF.APT_Domestic_Pricing__c = true;
            products.add(productNXF);
            Product2 productEXP = APT_TestUtils.createStarTrackProduct('Road Express', 'RoadExpress', 'Parcel Services', 'T01', 'EXP', 'Startrack');
            productEXP.APT_Domestic_Pricing__c = true;
            products.add(productEXP);
            //International product 1
            Product2 productAIRLET = APT_TestUtils.createInternationalProduct('Air Mail Letters', 'AIRLET', 'Parcel Services');
            productAIRLET.APT_International_Pricing__c = true;
            products.add( productAIRLET);
            
            Product2 internationalProduct1 = APT_TestUtils.createInternationalProduct(APT_Constants.EXPRESS_DOCT_INTERNATIONAL_PRODUCT ,
                                                                                      APT_Constants.EXPRESS_DOCT_INTERNATIONAL_PRODUCT , 'Parcel Services');
            internationalProduct1.APT_International_Pricing__c = true;
            products.add(internationalProduct1);
            
            Product2 internationalProduct2 = APT_TestUtils.createInternationalProduct(APT_Constants.EXPRESS_MERCH_INTERNATIONAL_PRODUCT ,
                                                                                      APT_Constants.EXPRESS_MERCH_INTERNATIONAL_PRODUCT , 'Parcel Services');
            internationalProduct2.APT_International_Pricing__c = true;
            products.add( internationalProduct2);
            
            Product2 internationalProduct3 = APT_TestUtils.createInternationalProduct(APT_Constants.STANDARD_INTERNATIONAL_PRODUCT ,
                                                                                      APT_Constants.STANDARD_INTERNATIONAL_PRODUCT , 'Parcel Services');
            internationalProduct3.APT_International_Pricing__c = true;
            products.add(internationalProduct3);
            
            Product2 internationalProduct4 = APT_TestUtils.createInternationalProduct(APT_Constants.STANDARD_SIGN_INTERNATIONAL_PRODUCT  ,
                                                                                      APT_Constants.STANDARD_SIGN_INTERNATIONAL_PRODUCT  , 'Parcel Services');
            internationalProduct4.APT_International_Pricing__c = true;
            products.add( internationalProduct4);
            
            Product2 internationalProduct5 = APT_TestUtils.createInternationalProduct(APT_Constants.ECONOMY_INTERNATIONAL_PRODUCT,
                                                                                      APT_Constants.ECONOMY_INTERNATIONAL_PRODUCT, 'Parcel Services');
            internationalProduct5.APT_International_Pricing__c = true;
            products.add( internationalProduct5);
            
            Product2 internationalProduct6 = APT_TestUtils.createInternationalProduct(APT_Constants.ECONOMY_SIGN_INTERNATIONAL_PRODUCT,
                                                                                      APT_Constants.ECONOMY_SIGN_INTERNATIONAL_PRODUCT, 'Parcel Services');
            internationalProduct6.APT_International_Pricing__c = true;
            products.add( internationalProduct6);
            
            Product2 internationalProduct7 = APT_TestUtils.createInternationalProduct(APT_Constants.PRODUCT_CODE_NEW_AIRMAIL_LETTERS,
                                                                                      APT_Constants.PRODUCT_CODE_NEW_AIRMAIL_LETTERS, 'Parcel Services');
            internationalProduct7.APT_International_Pricing__c = true;
            products.add( internationalProduct7);
			
			Product2 internationalProduct8 = APT_TestUtils.createInternationalProduct(APT_Constants.AIRLET_INTERNATIONAL_PRODUCT,
                                                                                      APT_Constants.AIRLET_INTERNATIONAL_PRODUCT, 'Parcel Services');
            internationalProduct8.APT_International_Pricing__c = true;
            products.add( internationalProduct8);
			
			Product2 internationalProduct9 = APT_TestUtils.createInternationalProduct(APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT,
                                                                                      APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT, 'Parcel Services');
            internationalProduct9.APT_International_Pricing__c = true;
            products.add( internationalProduct9);
			
			Product2 internationalProduct10 = APT_TestUtils.createInternationalProduct(APT_Constants.AIRPTI_INTERNATIONAL_PRODUCT,
                                                                                      APT_Constants.AIRPTI_INTERNATIONAL_PRODUCT, 'Parcel Services');
            internationalProduct10.APT_International_Pricing__c = true;
            products.add( internationalProduct10);
			
			Product2 internationalProduct11 = APT_TestUtils.createInternationalProduct(APT_Constants.AIRRPI_INTERNATIONAL_PRODUCT,
                                                                                      APT_Constants.AIRRPI_INTERNATIONAL_PRODUCT, 'Parcel Services');
            internationalProduct11.APT_International_Pricing__c = true;
            products.add( internationalProduct11);
			
			Product2 internationalProduct12 = APT_TestUtils.createInternationalProduct(APT_Constants.AIRSMPCL_INTERNATIONAL_PRODUCT,
                                                                                      APT_Constants.AIRSMPCL_INTERNATIONAL_PRODUCT, 'Parcel Services');
            internationalProduct12.APT_International_Pricing__c = true;
            products.add( internationalProduct12);
			
			Product2 internationalProduct13 = APT_TestUtils.createInternationalProduct(APT_Constants.EMSDOCT_INTERNATIONAL_PRODUCT,
                                                                                      APT_Constants.EMSDOCT_INTERNATIONAL_PRODUCT, 'Parcel Services');
            internationalProduct13.APT_International_Pricing__c = true;
            products.add( internationalProduct13);
			
			Product2 internationalProduct14 = APT_TestUtils.createInternationalProduct(APT_Constants.EMSMERCH_INTERNATIONAL_PRODUCT,
                                                                                      APT_Constants.EMSMERCH_INTERNATIONAL_PRODUCT, 'Parcel Services');
            internationalProduct14.APT_International_Pricing__c = true;
            products.add( internationalProduct14);
			
			Product2 internationalProduct15 = APT_TestUtils.createInternationalProduct(APT_Constants.EMSMER20_INTERNATIONAL_PRODUCT,
                                                                                      APT_Constants.EMSMER20_INTERNATIONAL_PRODUCT, 'Parcel Services');
            internationalProduct15.APT_International_Pricing__c = true;
            products.add( internationalProduct15);
			
            insert products;
			
            list<Product2> internationalProducts = new list<Product2> {/*internationalProduct1,
                internationalProduct2,
                internationalProduct3,*/
                internationalProduct4,
                internationalProduct5,
                internationalProduct6/*, 
                internationalProduct7,
                internationalProduct8,
                internationalProduct9,
                internationalProduct10,
                internationalProduct11,
                internationalProduct12,
                internationalProduct13,
                internationalProduct14,
                internationalProduct15*/};
                  
            List<Apttus_Config2__PriceListItem__c> priceListItemList = new List<Apttus_Config2__PriceListItem__c>();
            //pli for productCAT1STD
            Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id,productCAT1STD.id,'','');
            priceListItem.APT_Pricing_Key__c = productCAT1STD.Id + '~' + 'BANDED {Z6}' + '~' + 'CB';	
            priceListItem.APT_Band__c = 'Band 2';
            priceListItemList.add(priceListItem);
            //pli for product NXF
            Apttus_Config2__PriceListItem__c priceListItem2 = APT_TestUtils.createPriceListItem(priceList.id,productNXF.id,'','');
            priceListItem2.APT_Pricing_Key__c = productNXF.Id;
            priceListItem2.APT_Zone_Combination__c = productNXF.Id;
            priceListItem2.APT_Band__c = 'Band 2';
            priceListItemList.add(priceListItem2);
            //pli for EXP 1
            Apttus_Config2__PriceListItem__c priceListItem3 = APT_TestUtils.createPriceListItem(priceList.id,productEXP.id,'','');
            priceListItem3.APT_Pricing_Key__c = productEXP.Id+'~'+'QC3';
            priceListItem3.APT_Zone_Combination__c = productEXP.Id +'~QC3~Direct-QC3';
            priceListItem3.APT_Band__c = 'Band 2';
            priceListItemList.add(priceListItem3);             
            //pli for AIRLET
            Apttus_Config2__PriceListItem__c priceListItem4 = APT_TestUtils.createPriceListItem(priceList.id,productAIRLET.id,'','');
            priceListItem4.APT_Pricing_Key__c = productAIRLET.Id + '~' + productAIRLET.Productcode+'~'+'BAND 2';
            priceListItem4.APT_Band__c = 'Band 2';
            priceListItemList.add(priceListItem4);
            
            Apttus_Config2__PriceListItem__c priceListItemIP_1 = APT_TestUtils.createPriceListItem(priceList.id,internationalProduct1.id,'','');
            priceListItemIP_1.APT_Band__c = 'Band 2';
            priceListItemIP_1.APT_Band_Range_Max__c = 1000;
            priceListItemIP_1.APT_Pricing_Key__c = internationalProduct1.Id + '~' + internationalProduct1.Productcode+'~'+'BAND 2';
            priceListItemList.add(priceListItemIP_1);
            
            Apttus_Config2__PriceListItem__c priceListItemIP_2 = APT_TestUtils.createPriceListItem(priceList.id,internationalProduct2.id,'','');
            priceListItemIP_2.APT_Band__c = 'Band 2';
            priceListItemIP_2.APT_Band_Range_Max__c = 1000;
            priceListItemIP_2.APT_Pricing_Key__c = internationalProduct2.Id + '~' + internationalProduct2.Productcode+'~'+'BAND 2';
            priceListItemList.add(priceListItemIP_2);
            
            Apttus_Config2__PriceListItem__c priceListItemIP_3 = APT_TestUtils.createPriceListItem(priceList.id,internationalProduct3.id,'','');
            priceListItemIP_3.APT_Band__c = 'Band 3';
            priceListItemIP_3.APT_Band_Range_Max__c = 1000;
            priceListItemIP_3.APT_Pricing_Key__c = internationalProduct3.Id + '~' + internationalProduct3.Productcode+'~'+'BAND 2';
            priceListItemList.add(priceListItemIP_3);
            
            Apttus_Config2__PriceListItem__c priceListItemIP_4 = APT_TestUtils.createPriceListItem(priceList.id,internationalProduct4.id,'','');
            priceListItemIP_4.APT_Band__c = 'Band 4';
            priceListItemIP_4.APT_Band_Range_Max__c = 1000;
            priceListItemIP_4.APT_Pricing_Key__c = internationalProduct4.Id + '~' + internationalProduct4.Productcode+'~'+'BAND 2';
            priceListItemList.add(priceListItemIP_4);
            
            Apttus_Config2__PriceListItem__c priceListItemIP_5 = APT_TestUtils.createPriceListItem(priceList.id,internationalProduct5.id,'','');
            priceListItemIP_5.APT_Band__c = 'Band 5';
            priceListItemIP_5.APT_Band_Range_Max__c = 1000;
            priceListItemIP_5.APT_Pricing_Key__c = internationalProduct5.Id + '~' + internationalProduct5.Productcode+'~'+'BAND 2';
            priceListItemList.add(priceListItemIP_5);
            
            Apttus_Config2__PriceListItem__c priceListItemIP_6 = APT_TestUtils.createPriceListItem(priceList.id,internationalProduct6.id,'','');
            priceListItemIP_6.APT_Band__c = 'Band 2';
            priceListItemIP_6.APT_Band_Range_Max__c = 1000;
            priceListItemIP_6.APT_Pricing_Key__c = internationalProduct6.Id + '~' + internationalProduct6.Productcode+'~'+'BAND 2';
            priceListItemList.add(priceListItemIP_6);
			
			Apttus_Config2__PriceListItem__c priceListItemIP_7 = APT_TestUtils.createPriceListItem(priceList.id,internationalProduct7.id,'','');
            priceListItemIP_7.APT_Band__c = 'Band 2';
            priceListItemIP_7.APT_Band_Range_Max__c = 1000;
            priceListItemIP_7.APT_Pricing_Key__c = internationalProduct7.Id + '~' + internationalProduct7.Productcode+'~'+'BAND 2';
            priceListItemList.add(priceListItemIP_7);
			
			Apttus_Config2__PriceListItem__c priceListItemIP_8 = APT_TestUtils.createPriceListItem(priceList.id,internationalProduct8.id,'','');
            priceListItemIP_8.APT_Band__c = 'Band 3';
            priceListItemIP_8.APT_Band_Range_Max__c = 1000;
            priceListItemIP_8.APT_Pricing_Key__c = internationalProduct8.Id + '~' + internationalProduct8.Productcode+'~'+'BAND 2';
            priceListItemList.add(priceListItemIP_8);
			
			Apttus_Config2__PriceListItem__c priceListItemIP_9 = APT_TestUtils.createPriceListItem(priceList.id,internationalProduct9.id,'','');
            priceListItemIP_9.APT_Band__c = 'Band 4';
            priceListItemIP_9.APT_Band_Range_Max__c = 1000;
            priceListItemIP_9.APT_Pricing_Key__c = internationalProduct9.Id + '~' + internationalProduct9.Productcode+'~'+'BAND 2';
            priceListItemList.add(priceListItemIP_9);
            
			Apttus_Config2__PriceListItem__c priceListItemIP_10  = APT_TestUtils.createPriceListItem(priceList.id,internationalProduct10.id,'','');
            priceListItemIP_10 .APT_Band__c = 'Band 5';
            priceListItemIP_10 .APT_Band_Range_Max__c = 1000;
            priceListItemIP_10 .APT_Pricing_Key__c = internationalProduct10.Id + '~' + internationalProduct10.Productcode+'~'+'BAND 2';
            priceListItemList.add(priceListItemIP_10 );

			Apttus_Config2__PriceListItem__c priceListItemIP_11 = APT_TestUtils.createPriceListItem(priceList.id,internationalProduct11.id,'','');
            priceListItemIP_11.APT_Band__c = 'Band 2';
            priceListItemIP_11.APT_Band_Range_Max__c = 1000;
            priceListItemIP_11.APT_Pricing_Key__c = internationalProduct11.Id + '~' + internationalProduct11.Productcode+'~'+'BAND 2';
            priceListItemList.add(priceListItemIP_11);
			
			Apttus_Config2__PriceListItem__c priceListItemIP_12 = APT_TestUtils.createPriceListItem(priceList.id,internationalProduct12.id,'','');
            priceListItemIP_12.APT_Band__c = 'Band 2';
            priceListItemIP_12.APT_Band_Range_Max__c = 1000;
            priceListItemIP_12.APT_Pricing_Key__c = internationalProduct12.Id + '~' + internationalProduct12.Productcode+'~'+'BAND 2';
            priceListItemList.add(priceListItemIP_12);
			
			Apttus_Config2__PriceListItem__c priceListItemIP_13 = APT_TestUtils.createPriceListItem(priceList.id,internationalProduct13.id,'','');
            priceListItemIP_13.APT_Band__c = 'Band 3';
            priceListItemIP_13.APT_Band_Range_Max__c = 1000;
            priceListItemIP_13.APT_Pricing_Key__c = internationalProduct13.Id + '~' + internationalProduct13.Productcode+'~'+'BAND 2';
            priceListItemList.add(priceListItemIP_13);
			
			Apttus_Config2__PriceListItem__c priceListItemIP_14 = APT_TestUtils.createPriceListItem(priceList.id,internationalProduct14.id,'','');
            priceListItemIP_14.APT_Band__c = 'Band 4';
            priceListItemIP_14.APT_Band_Range_Max__c = 1000;
            priceListItemIP_14.APT_Pricing_Key__c = internationalProduct14.Id + '~' + internationalProduct14.Productcode+'~'+'BAND 2';
            priceListItemList.add(priceListItemIP_14);
			
			Apttus_Config2__PriceListItem__c priceListItemIP_15 = APT_TestUtils.createPriceListItem(priceList.id,internationalProduct15.id,'','');
            priceListItemIP_15.APT_Band__c = 'Band 5';
            priceListItemIP_15.APT_Band_Range_Max__c = 1000;
            priceListItemIP_15.APT_Pricing_Key__c = internationalProduct15.Id + '~' + internationalProduct15.Productcode+'~'+'BAND 2';
            priceListItemList.add(priceListItemIP_15);
			
            insert priceListItemList;
            
            Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = APT_TestUtils.createProductAttributeGroup('Apttus_Config2__ProductAttributeValue__c');
            insert productAttributeGroup;
            
            Apttus_Config2__ProductAttribute__c productAttribute = APT_TestUtils.createProductAttribute('APT_Zone__c', productAttributeGroup.Id);
            insert productAttribute;
            
            list<Apttus_Config2__PriceDimension__c> listPriceDimension = new list<Apttus_Config2__PriceDimension__c>();
            Apttus_Config2__PriceDimension__c priceDimension1 = APT_TestUtils.createPriceDimension('Destination Zone Code', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Destination_Zone_Code__c', productAttribute.Id);
            listPriceDimension.add(priceDimension1);
            
            Apttus_Config2__PriceDimension__c priceDimension2 = APT_TestUtils.createPriceDimension('Domestic Price Type', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Domestic_Price_Type__c', productAttribute.Id);
            listPriceDimension.add(priceDimension2);
            
            Apttus_Config2__PriceDimension__c priceDimension3 = APT_TestUtils.createPriceDimension('Weight Range Code', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Weight_Range_Code__c', productAttribute.Id);
            listPriceDimension.add(priceDimension3);
            
            Apttus_Config2__PriceDimension__c priceDimension4 = APT_TestUtils.createPriceDimension('Zone Type', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Zone_Type__c', productAttribute.Id);
            listPriceDimension.add(priceDimension4); 
            
            Apttus_Config2__PriceDimension__c priceDimension5 = APT_TestUtils.createPriceDimension('Inbound - Outbound', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Inbound_Outbound__c', productAttribute.Id);
            listPriceDimension.add(priceDimension5);
            
            Apttus_Config2__PriceDimension__c priceDimension6 = APT_TestUtils.createPriceDimension('Pickup Zone Code', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Pickup_Zone_Code__c', productAttribute.Id);
            listPriceDimension.add(priceDimension6);
            
            Apttus_Config2__PriceDimension__c priceDimension7 = APT_TestUtils.createPriceDimension('Price Type', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Price_Type__c', productAttribute.Id);
            listPriceDimension.add(priceDimension7);
            
            Apttus_Config2__PriceDimension__c priceDimension8 = APT_TestUtils.createPriceDimension('Basic Charge', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Basic_Charge__c', productAttribute.Id);
            listPriceDimension.add(priceDimension8);            
            
            Apttus_Config2__PriceDimension__c priceDimension9 = APT_TestUtils.createPriceDimension('KG Rate', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_KG_Rate__c', productAttribute.Id);
            listPriceDimension.add(priceDimension9); 
            
            Apttus_Config2__PriceDimension__c priceDimension10 = APT_TestUtils.createPriceDimension('Minimum Charge', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Minimum_Charge__c', productAttribute.Id);
            listPriceDimension.add(priceDimension10);
            
            Apttus_Config2__PriceDimension__c priceDimension11 = APT_TestUtils.createPriceDimension('Zone', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Zone__c', productAttribute.Id);
            listPriceDimension.add(priceDimension11);
            
            Apttus_Config2__PriceDimension__c priceDimension12 = APT_TestUtils.createPriceDimension('International Price Type', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
            listPriceDimension.add(priceDimension12);
            
            Apttus_Config2__PriceDimension__c priceDimension13 = APT_TestUtils.createPriceDimension('Weight Range', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'Weight_Range__c', productAttribute.Id);
            listPriceDimension.add(priceDimension13);    
            
            insert listPriceDimension;
            
            List<Apttus_Config2__PriceMatrix__c> listPM = new List<Apttus_Config2__PriceMatrix__c>();
            Apttus_Config2__PriceMatrix__c priceMatrix = APT_TestUtils.createPriceMatrix(pli.Id, priceDimension1.Id, priceDimension2.Id, priceDimension3.Id);
            listPM.add(priceMatrix);
            
            // PM for the Pli corresponding to NXF 
            Apttus_Config2__PriceMatrix__c priceMatrix1 = APT_TestUtils.createPriceMatrix(priceListItem2.Id, priceDimension6.Id, priceDimension1.Id, priceDimension8.Id);
            priceMatrix1.Apttus_Config2__Dimension4Id__c = priceDimension9.Id;
            priceMatrix1.Apttus_Config2__Dimension4ValueType__c = 'Discrete';
            priceMatrix1.Apttus_Config2__Dimension5Id__c = priceDimension10.Id;
            priceMatrix1.Apttus_Config2__Dimension5ValueType__c = 'Discrete';
            listPM.add(priceMatrix1);   
            
            // PM for the Pli corresponding to EXP 1
            Apttus_Config2__PriceMatrix__c priceMatrix2 = APT_TestUtils.createPriceMatrix(priceListItem3.Id,priceDimension4.Id, priceDimension5.Id, priceDimension6.Id);
            priceMatrix2.Apttus_Config2__Dimension4Id__c = priceDimension1.Id;
            priceMatrix2.Apttus_Config2__Dimension4ValueType__c = 'Discrete';
            priceMatrix2.Apttus_Config2__Dimension5Id__c = priceDimension7.Id;
            priceMatrix2.Apttus_Config2__Dimension5ValueType__c = 'Discrete';
            listPM.add(priceMatrix2); 
            
            // PM for the Pli corresponding to AIRLET
            Apttus_Config2__PriceMatrix__c priceMatrix3 = APT_TestUtils.createPriceMatrix(priceListItem4.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
            listPM.add(priceMatrix3);          
            
            Apttus_Config2__PriceMatrix__c priceMatrixIP_1 = APT_TestUtils.createPriceMatrix(priceListItemIP_1.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
            listPM.add(priceMatrixIP_1);          
            
            Apttus_Config2__PriceMatrix__c priceMatrixIP_2 = APT_TestUtils.createPriceMatrix(priceListItemIP_2.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
            listPM.add(priceMatrixIP_2);          
            
            Apttus_Config2__PriceMatrix__c priceMatrixIP_3 = APT_TestUtils.createPriceMatrix(priceListItemIP_3.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
            listPM.add(priceMatrixIP_3);          
            
            Apttus_Config2__PriceMatrix__c priceMatrixIP_4 = APT_TestUtils.createPriceMatrix(priceListItemIP_4.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
            listPM.add(priceMatrixIP_4);                     
			
			Apttus_Config2__PriceMatrix__c priceMatrixIP_5 = APT_TestUtils.createPriceMatrix(priceListItemIP_5.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
            listPM.add(priceMatrixIP_5);  

			Apttus_Config2__PriceMatrix__c priceMatrixIP_6 = APT_TestUtils.createPriceMatrix(priceListItemIP_6.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
            listPM.add(priceMatrixIP_6);  			
            
			Apttus_Config2__PriceMatrix__c priceMatrixIP_7 = APT_TestUtils.createPriceMatrix(priceListItemIP_7.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
            listPM.add(priceMatrixIP_7);  
			
			Apttus_Config2__PriceMatrix__c priceMatrixIP_8 = APT_TestUtils.createPriceMatrix(priceListItemIP_8.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
            listPM.add(priceMatrixIP_8);  
			
			Apttus_Config2__PriceMatrix__c priceMatrixIP_9 = APT_TestUtils.createPriceMatrix(priceListItemIP_9.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
            listPM.add(priceMatrixIP_9);  
			
			Apttus_Config2__PriceMatrix__c priceMatrixIP_10 = APT_TestUtils.createPriceMatrix(priceListItemIP_10.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
            listPM.add(priceMatrixIP_10);  
			
			Apttus_Config2__PriceMatrix__c priceMatrixIP_11 = APT_TestUtils.createPriceMatrix(priceListItemIP_11.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
            listPM.add(priceMatrixIP_11);  
			
			Apttus_Config2__PriceMatrix__c priceMatrixIP_12 = APT_TestUtils.createPriceMatrix(priceListItemIP_12.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
            listPM.add(priceMatrixIP_12);  
			
			Apttus_Config2__PriceMatrix__c priceMatrixIP_13 = APT_TestUtils.createPriceMatrix(priceListItemIP_13.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
            listPM.add(priceMatrixIP_13);  
			
			Apttus_Config2__PriceMatrix__c priceMatrixIP_14 = APT_TestUtils.createPriceMatrix(priceListItemIP_14.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
            listPM.add(priceMatrixIP_14);  
			
			Apttus_Config2__PriceMatrix__c priceMatrixIP_15 = APT_TestUtils.createPriceMatrix(priceListItemIP_15.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
            listPM.add(priceMatrixIP_15);  
			
            insert listPM;
            System.debug('Line: 1387');
            list<Apttus_Config2__PriceMatrixEntry__c> listPME = new list<Apttus_Config2__PriceMatrixEntry__c>();
            Apttus_Config2__PriceMatrixEntry__c pme1 = new Apttus_Config2__PriceMatrixEntry__c();
            pme1.Apttus_Config2__Dimension1Value__c = '1';
            pme1.Apttus_Config2__Dimension2Value__c = '2';
            pme1.Apttus_Config2__Dimension3Value__c = '3';
            pme1.Apttus_Config2__PriceMatrixId__c = priceMatrix.Id;
            pme1.Apttus_Config2__Sequence__c = 1;
            pme1.Apttus_Config2__UsageRate__c = 1;
            pme1.Apttus_Config2__AdjustmentAmount__c = 1;
            pme1.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pme1);
            
            Apttus_Config2__PriceMatrixEntry__c pme2 = new Apttus_Config2__PriceMatrixEntry__c();
            pme2.Apttus_Config2__Dimension1Value__c = '1';
            pme2.Apttus_Config2__Dimension2Value__c = '2';
            pme2.Apttus_Config2__Dimension3Value__c = '3';
            pme2.Apttus_Config2__PriceMatrixId__c = priceMatrix1.Id;
            pme2.Apttus_Config2__Sequence__c = 1;
            pme2.Apttus_Config2__UsageRate__c = 1;
            pme2.Apttus_Config2__AdjustmentAmount__c = 1;
            pme2.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pme2);
            
            Apttus_Config2__PriceMatrixEntry__c pme3 = new Apttus_Config2__PriceMatrixEntry__c();
            pme3.Apttus_Config2__Dimension1Value__c = '1';
            pme3.Apttus_Config2__Dimension2Value__c = '2';
            pme3.Apttus_Config2__Dimension3Value__c = '3';
            pme3.Apttus_Config2__PriceMatrixId__c = priceMatrix2.Id;
            pme3.Apttus_Config2__Sequence__c = 1;
            pme3.Apttus_Config2__UsageRate__c = 1;
            pme3.Apttus_Config2__AdjustmentAmount__c = 1;
            pme3.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pme3);
            
            Apttus_Config2__PriceMatrixEntry__c pme4 = new Apttus_Config2__PriceMatrixEntry__c();
            pme4.Apttus_Config2__Dimension1Value__c = '1';
            pme4.Apttus_Config2__Dimension2Value__c = '2';
            pme4.Apttus_Config2__Dimension3Value__c = '3';
            pme4.Apttus_Config2__PriceMatrixId__c = priceMatrix3.Id;
            pme4.Apttus_Config2__Sequence__c = 1;
            pme4.Apttus_Config2__UsageRate__c = 1;
            pme4.Apttus_Config2__AdjustmentAmount__c = 1;
            pme4.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pme4);         
            
            Apttus_Config2__PriceMatrixEntry__c pmeIP_1 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_1.Apttus_Config2__Dimension1Value__c = 'Zone1';
            pmeIP_1.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_1.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_1.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_1.Id;
            pmeIP_1.Apttus_Config2__Sequence__c = 1;
            pmeIP_1.Apttus_Config2__UsageRate__c = 1;
            pmeIP_1.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_1.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_1);         
            
            Apttus_Config2__PriceMatrixEntry__c pmeIP_2 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_2.Apttus_Config2__Dimension1Value__c = 'Zone2';
            pmeIP_2.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_2.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_2.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_2.Id;
            pmeIP_2.Apttus_Config2__Sequence__c = 1;
            pmeIP_2.Apttus_Config2__UsageRate__c = 1;
            pmeIP_2.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_2.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_2);         
            
            Apttus_Config2__PriceMatrixEntry__c pmeIP_3 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_3.Apttus_Config2__Dimension1Value__c = 'Zone3';
            pmeIP_3.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_3.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_3.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_3.Id;
            pmeIP_3.Apttus_Config2__Sequence__c = 1;
            pmeIP_3.Apttus_Config2__UsageRate__c = 1;
            pmeIP_3.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_3.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_3);         
            
            Apttus_Config2__PriceMatrixEntry__c pmeIP_4 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_4.Apttus_Config2__Dimension1Value__c = 'Zone4';
            pmeIP_4.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_4.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_4.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_4.Id;
            pmeIP_4.Apttus_Config2__Sequence__c = 1;
            pmeIP_4.Apttus_Config2__UsageRate__c = 1;
            pmeIP_4.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_4.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_4);         
			
			Apttus_Config2__PriceMatrixEntry__c pmeIP_5 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_5.Apttus_Config2__Dimension1Value__c = 'Zone5';
            pmeIP_5.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_5.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_5.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_5.Id;
            pmeIP_5.Apttus_Config2__Sequence__c = 1;
            pmeIP_5.Apttus_Config2__UsageRate__c = 1;
            pmeIP_5.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_5.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_5);         
			
			Apttus_Config2__PriceMatrixEntry__c pmeIP_6 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_6.Apttus_Config2__Dimension1Value__c = 'Zone6';
            pmeIP_6.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_6.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_6.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_6.Id;
            pmeIP_6.Apttus_Config2__Sequence__c = 1;
            pmeIP_6.Apttus_Config2__UsageRate__c = 1;
            pmeIP_6.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_6.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_6);         
			
			Apttus_Config2__PriceMatrixEntry__c pmeIP_6_1 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_6_1.Apttus_Config2__Dimension1Value__c = 'Zone7';
            pmeIP_6_1.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_6_1.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_6_1.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_6.Id;
            pmeIP_6_1.Apttus_Config2__Sequence__c = 1;
            pmeIP_6_1.Apttus_Config2__UsageRate__c = 1;
            pmeIP_6_1.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_6_1.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_6_1);         
			
			Apttus_Config2__PriceMatrixEntry__c pmeIP_6_2 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_6_2.Apttus_Config2__Dimension1Value__c = 'Zone8';
            pmeIP_6_2.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_6_2.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_6_2.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_6.Id;
            pmeIP_6_2.Apttus_Config2__Sequence__c = 1;
            pmeIP_6_2.Apttus_Config2__UsageRate__c = 1;
            pmeIP_6_2.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_6_2.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_6_2);         
			
			Apttus_Config2__PriceMatrixEntry__c pmeIP_6_3 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_6_3.Apttus_Config2__Dimension1Value__c = 'Zone9';
            pmeIP_6_3.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_6_3.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_6_3.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_6.Id;
            pmeIP_6_3.Apttus_Config2__Sequence__c = 1;
            pmeIP_6_3.Apttus_Config2__UsageRate__c = 1;
            pmeIP_6_3.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_6_3.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_6_3);         
			
			Apttus_Config2__PriceMatrixEntry__c pmeIP_6_4 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_6_4.Apttus_Config2__Dimension1Value__c = 'Zone10';
            pmeIP_6_4.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_6_4.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_6_4.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_6.Id;
            pmeIP_6_4.Apttus_Config2__Sequence__c = 1;
            pmeIP_6_4.Apttus_Config2__UsageRate__c = 1;
            pmeIP_6_4.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_6_4.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_6_4);         
            
			Apttus_Config2__PriceMatrixEntry__c pmeIP_7 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_7.Apttus_Config2__Dimension1Value__c = 'Zone7';
            pmeIP_7.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_7.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_7.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_7.Id;
            pmeIP_7.Apttus_Config2__Sequence__c = 1;
            pmeIP_7.Apttus_Config2__UsageRate__c = 1;
            pmeIP_7.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_7.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_7);    
			
			Apttus_Config2__PriceMatrixEntry__c pmeIP_7_1 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_7_1.Apttus_Config2__Dimension1Value__c = 'Zone1';
            pmeIP_7_1.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_7_1.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_7_1.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_7.Id;
            pmeIP_7_1.Apttus_Config2__Sequence__c = 1;
            pmeIP_7_1.Apttus_Config2__UsageRate__c = 1;
            pmeIP_7_1.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_7_1.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_7_1);    
			
			Apttus_Config2__PriceMatrixEntry__c pmeIP_7_2 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_7_2.Apttus_Config2__Dimension1Value__c = 'Zone2';
            pmeIP_7_2.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_7_2.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_7_2.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_7.Id;
            pmeIP_7_2.Apttus_Config2__Sequence__c = 1;
            pmeIP_7_2.Apttus_Config2__UsageRate__c = 1;
            pmeIP_7_2.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_7_2.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_7_2);    

			Apttus_Config2__PriceMatrixEntry__c pmeIP_7_3 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_7_3.Apttus_Config2__Dimension1Value__c = 'Zone3';
            pmeIP_7_3.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_7_3.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_7_3.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_7.Id;
            pmeIP_7_3.Apttus_Config2__Sequence__c = 1;
            pmeIP_7_3.Apttus_Config2__UsageRate__c = 1;
            pmeIP_7_3.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_7_3.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_7_3);    
			
			Apttus_Config2__PriceMatrixEntry__c pmeIP_7_4 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_7_4.Apttus_Config2__Dimension1Value__c = 'Zone4';
            pmeIP_7_4.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_7_4.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_7_4.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_7.Id;
            pmeIP_7_4.Apttus_Config2__Sequence__c = 1;
            pmeIP_7_4.Apttus_Config2__UsageRate__c = 1;
            pmeIP_7_4.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_7_4.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_7_4);    		

			Apttus_Config2__PriceMatrixEntry__c pmeIP_7_5 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_7_5.Apttus_Config2__Dimension1Value__c = 'Zone5';
            pmeIP_7_5.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_7_5.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_7_5.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_7.Id;
            pmeIP_7_5.Apttus_Config2__Sequence__c = 1;
            pmeIP_7_5.Apttus_Config2__UsageRate__c = 1;
            pmeIP_7_5.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_7_5.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_7_5);    

			Apttus_Config2__PriceMatrixEntry__c pmeIP_7_6 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_7_6.Apttus_Config2__Dimension1Value__c = 'Zone6';
            pmeIP_7_6.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_7_6.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_7_6.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_7.Id;
            pmeIP_7_6.Apttus_Config2__Sequence__c = 1;
            pmeIP_7_6.Apttus_Config2__UsageRate__c = 1;
            pmeIP_7_6.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_7_6.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_7_6);    

			Apttus_Config2__PriceMatrixEntry__c pmeIP_7_8 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_7_8.Apttus_Config2__Dimension1Value__c = 'Zone8';
            pmeIP_7_8.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_7_8.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_7_8.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_7.Id;
            pmeIP_7_8.Apttus_Config2__Sequence__c = 1;
            pmeIP_7_8.Apttus_Config2__UsageRate__c = 1;
            pmeIP_7_8.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_7_8.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_7_8);    			
		
			Apttus_Config2__PriceMatrixEntry__c pmeIP_8 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_8.Apttus_Config2__Dimension1Value__c = 'Zone8';
            pmeIP_8.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_8.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_8.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_8.Id;
            pmeIP_8.Apttus_Config2__Sequence__c = 1;
            pmeIP_8.Apttus_Config2__UsageRate__c = 1;
            pmeIP_8.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_8.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_8);         

			Apttus_Config2__PriceMatrixEntry__c pmeIP_9 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_9.Apttus_Config2__Dimension1Value__c = 'Zone9';
            pmeIP_9.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_9.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_9.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_9.Id;
            pmeIP_9.Apttus_Config2__Sequence__c = 1;
            pmeIP_9.Apttus_Config2__UsageRate__c = 1;
            pmeIP_9.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_9.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_9);         

			Apttus_Config2__PriceMatrixEntry__c pmeIP_10 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_10.Apttus_Config2__Dimension1Value__c = 'Zone1';
            pmeIP_10.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_10.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_10.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_10.Id;
            pmeIP_10.Apttus_Config2__Sequence__c = 1;
            pmeIP_10.Apttus_Config2__UsageRate__c = 1;
            pmeIP_10.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_10.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_10);         

			Apttus_Config2__PriceMatrixEntry__c pmeIP_11 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_11.Apttus_Config2__Dimension1Value__c = 'Zone2';
            pmeIP_11.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_11.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_11.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_11.Id;
            pmeIP_11.Apttus_Config2__Sequence__c = 1;
            pmeIP_11.Apttus_Config2__UsageRate__c = 1;
            pmeIP_11.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_11.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_11);         

			Apttus_Config2__PriceMatrixEntry__c pmeIP_12 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_12.Apttus_Config2__Dimension1Value__c = 'Zone3';
            pmeIP_12.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_12.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_12.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_12.Id;
            pmeIP_12.Apttus_Config2__Sequence__c = 1;
            pmeIP_12.Apttus_Config2__UsageRate__c = 1;
            pmeIP_12.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_12.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_12);         

			Apttus_Config2__PriceMatrixEntry__c pmeIP_13 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_13.Apttus_Config2__Dimension1Value__c = 'Zone4';
            pmeIP_13.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_13.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_13.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_13.Id;
            pmeIP_13.Apttus_Config2__Sequence__c = 1;
            pmeIP_13.Apttus_Config2__UsageRate__c = 1;
            pmeIP_13.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_13.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_13);         
			
			Apttus_Config2__PriceMatrixEntry__c pmeIP_14 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_14.Apttus_Config2__Dimension1Value__c = 'Zone5';
            pmeIP_14.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_14.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_14.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_14.Id;
            pmeIP_14.Apttus_Config2__Sequence__c = 1;
            pmeIP_14.Apttus_Config2__UsageRate__c = 1;
            pmeIP_14.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_14.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_14);         			
			
			Apttus_Config2__PriceMatrixEntry__c pmeIP_15 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_15.Apttus_Config2__Dimension1Value__c = 'Zone6';
            pmeIP_15.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_15.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_15.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_15.Id;
            pmeIP_15.Apttus_Config2__Sequence__c = 1;
            pmeIP_15.Apttus_Config2__UsageRate__c = 1;
            pmeIP_15.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_15.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_15);         
			
            insert listPME; 
            System.debug('Test PME Count Start: ');              
            integer  count= database.countQuery('select count() from Apttus_Config2__PriceMatrixEntry__c where Apttus_Config2__PriceMatrixId__r.Apttus_Config2__PriceListItemId__r.Apttus_Config2__ProductId__r.APT_International_Pricing__c = true');
            System.debug('Test PME Count end: ' + count);              
            
            
            Test.starttest();    
            // update product Attribute value
            //attribute1.Category__c='CAT1';
            attribute1.APT_Distribution_Type_Printpost__c = 'Local Sort Division;Same State Metro;Other State;Large Postcode Direct';               
            attribute1.APT_Domestic_Customer__c = null;
            attribute1.APT_Band__c = 'Band 2';
            attribute1.Category__c=null;
            attribute1.APT_Lodgement_Zone__c = null;
            attribute1.Apttus_Config2__LineItemId__c = null;
            attribute1.APT_Volume_Data__c = APT_Constants.OPTION_YES;

            try{
                Update attribute1;     
            }
            Catch(Exception e){
                
            }
            try{
                attribute1.Category__c = APT_Constants.CATEGORY_CAT2;
                Update attribute1;
                
            }
            Catch(Exception e){}
            try{
                attribute1.Category__c = APT_Constants.CATEGORY_CAT3;
                Update attribute1;     
               
            }
            Catch(Exception e){
                
            }
            try{
                attribute1.Category__c = APT_Constants.CATEGORY_CAT4;
                Update attribute1;     
               
            }
            Catch(Exception e){
                
            }
            try{
                attribute1.Category__c = APT_Constants.CATEGORY_CAT5;
                Update attribute1;     
               
            }
            Catch(Exception e){
                
            }
            try{
                attribute1.Category__c = APT_Constants.CATEGORY_CAT6;
                Update attribute1;     
            }
            Catch(Exception e){
                
            }
            
            for(product2 product : internationalProducts){
                try
                {
                Apttus_Config2__PriceListItem__c priceListIt = [select Id,  Apttus_Config2__ProductId__r.ProductCode from Apttus_Config2__PriceListItem__c where Apttus_Config2__ProductId__r.ProductCode =: product.ProductCode limit 1];
                
                Apttus_Config2__LineItem__c internationalLine = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
                                                                                                1, 'Product/Service', product.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
                                                                                                null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
                                                                                                'Each', 1, priceList.Id, priceListIt.Id,//Uom, term, priceList, Pli,
                                                                                                'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
                                                                                                true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
                                                                                                5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
                internationalLine.Apttus_Config2__AllowManualAdjustment__c = true;
                internationalLine.Apttus_Config2__NetPrice__c = 5225;
                internationalLine.Apttus_Config2__PrimaryLineNumber__c = 1;
                internationalLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
                insert internationalLine;
            
             
             Apttus_Config2__ProductAttributeValue__c attribute_IP = APT_TestUtils.GetAttributeValue(internationalLine.Id,'Standard',false,false,false,'Yes','B Mining',True,false);
                    
            attribute_IP.Category__c='CAT1';
            attribute_IP.APT_Postcode__c = '2000';
            attribute_IP.APT_Lodgement_Zone__c=logdZone.ID; 
            attribute_IP.APT_AirmailSmallParcelGT2kgAVGWeightKG__c = 3;
            attribute_IP.APT_Distribution_Type_Printpost__c = 'Local Sort Division;Same State Metro;Other State';
            attribute_IP.APT_Volume_Threshold_Post_BillPay__c='25,001 – 100,000';
            attribute_IP.APT_PostBillPay_Volume_threshold__c='25,001 – 100,000';
            //attribute1.Apttus_Config2__LineItemId__c = null;
            attribute_IP.APT_Volume_Data__c = APT_Constants.OPTION_YES;
            attribute1.APT_RK_Code_Applied__c = false;
            attribute_IP.APT_Domestic_Customer__c = null;
            insert attribute_IP; 
                
                attribute_IP.Category__c = APT_Constants.CATEGORY_CAT2;
                    
                    try{
                    
                        update attribute_IP;
                    }
                    catch(Exception e){}
                    if(product.ProductCode == APT_Constants.STANDARD_INTERNATIONAL_PRODUCT){
                        try{
                            attribute_IP.APT_International_Standard_Weight_Kgs__c = 1;
                            update attribute_IP;
                        }catch(Exception e){}
                        try{
                            attribute_IP.APT_International_Standard_Weight_Kgs__c = 2;
                            update attribute_IP;
                        }catch(Exception e){}
                        try{
                            attribute_IP.APT_International_Standard_Weight_Kgs__c = 10;
                            update attribute_IP;
                        }catch(Exception e){}
                    }
                    
                   else if(product.ProductCode == APT_Constants.STANDARD_SIGN_INTERNATIONAL_PRODUCT){
                        try{
                            attribute_IP.APT_International_Std_W_Sig_Weight_Kgs__c = 1;
                            update attribute_IP;
                        }catch(Exception e){}
                        try{
                            attribute_IP.APT_International_Std_W_Sig_Weight_Kgs__c = 2;
                            update attribute_IP;
                        }catch(Exception e){}
                        try{
                            attribute_IP.APT_International_Std_W_Sig_Weight_Kgs__c = 10;
                            update attribute_IP;
                        }catch(Exception e){}
                    }
                     else if(product.ProductCode == APT_Constants.ECONOMY_SIGN_INTERNATIONAL_PRODUCT){
                        try{
                            attribute_IP.APT_International_Eco_W_Sig_Weight_Kgs__c = 1;
                            update attribute_IP;
                        }catch(Exception e){}
                        try{
                            attribute_IP.APT_International_Eco_W_Sig_Weight_Kgs__c = 2;
                            update attribute_IP;
                        }catch(Exception e){}
                    }
                    else if(product.ProductCode == APT_Constants.ECONOMY_INTERNATIONAL_PRODUCT){
                        try{
                            attribute_IP.APT_International_Economy_Weight_Kgs__c = 1;
                            update attribute_IP;
                        }catch(Exception e){}
                        try{
                            attribute_IP.APT_International_Economy_Weight_Kgs__c = 2;
                            update attribute_IP;
                        }catch(Exception e){}
                    }
                    else if(product.ProductCode == APT_Constants.EXPRESS_MERCH_INTERNATIONAL_PRODUCT){
                        try{
                            attribute_IP.APT_International_Exp_Merch_Weight_Kgs__c = 1;
                            update attribute_IP;
                        }catch(Exception e){}
                        try{
                            attribute_IP.APT_International_Exp_Merch_Weight_Kgs__c = 2;
                            update attribute_IP;
                        }catch(Exception e){}
                        try{
                            attribute_IP.APT_International_Exp_Merch_Weight_Kgs__c = 10;
                            update attribute_IP;
                        }catch(Exception e){}
                    }
                     else if(product.ProductCode == APT_Constants.ECONOMY_SIGN_INTERNATIONAL_PRODUCT){
                        try{
                            attribute_IP.APT_International_Eco_W_Sig_Weight_Kgs__c = 1;
                            update attribute_IP;
                        }catch(Exception e){}
                        try{
                            attribute_IP.APT_International_Eco_W_Sig_Weight_Kgs__c = 2;
                            update attribute_IP;
                        }catch(Exception e){}
                    }
                    
                    
                }
                catch(Exception e){
                    
                }
            }
            
            //system.assert('SUCCESS' == APT_Constants.SUCCESS_LABEL);
            Test.stoptest();
            //system.assert(listInternationalPriceData.size()>0);
            //System.assertEquals(listProduct[0],'AIRMAIL_LETTERS');
            //system.assert(attribute1.Apttus_Config2__LineItemId__c !=null);      
        }
        
        double num=0;
        set<string> s11=new set<string>();
        s11.add('Zone6');
        list<APT_International_Price_Data__c> listIdpData=new list<APT_International_Price_Data__c>();
        APT_International_Price_Data__c ipd1 = APT_TestUtils.createInternationalPriceData('EXPRESS_DOCT', 'B Mining', 'BAND 2', null, 0, 2999, 10, 10, 20, 20);
        listIdpData.add(ipd1);
        string data=listIdpData[0].APT_Band__c + APT_Constants.SEPERATOR_SIMILARITY + listIdpData[0].APT_Product__c + APT_Constants.SEPERATOR_SIMILARITY + listIdpData[0].APT_Zone__c;
        map<string, list<APT_International_Price_Data__c>> mapDataPrice=new map<string,list<APT_International_Price_Data__c>>();
        mapDataPrice.put(data,listIdpData);
        
        //APT_ProductAttributeValueTriggerHandler.calculateProductRevenueforNewIntBundle(num,Null,'BAND 2','EXPRESS_DOCT',s11,'CSP',mapDataPrice,null);
        //APT_ProductAttributeValueTriggerHandler.calculateProductRevenueforNewIntBundle(num,Null,'BAND 2','EXPRESS_DOCT',s11,'CSP',mapDataPrice,null);
    }    
    
    /*
    @isTest
    public static void BeforeUpdate_EXPRESSDOCTINTERNATIONALPRODUCT_APTInternationalStandardWeightKgsc_1_Test(){
        
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
            
            //Create Opportunity
            Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
            insert opty;
            
            //Create PriceList
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = APT_TestUtils.createProductAttributeGroup('Apttus_Config2__ProductAttributeValue__c');
            insert productAttributeGroup;
            
            Product2 product = APT_TestUtils.createInternationalProduct(APT_Constants.EXPRESS_DOCT_INTERNATIONAL_PRODUCT ,APT_Constants.EXPRESS_DOCT_INTERNATIONAL_PRODUCT , 'Parcel Services');

            Apttus_Config2__PriceListItem__c priceListItem = APT_TestUtils.createPriceListItem(priceList.id,product.id,'','');
            priceListItem.APT_Band__c = 'Band 2';
            priceListItem.APT_Band_Range_Max__c = 1000;
            priceListItem.APT_Pricing_Key__c = product.Id + '~' + product.Productcode+'~'+'BAND 2';
            insert priceListItem;
            
            
            //Create Proposal
            Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
            insert Proposal;
            
            APT_Lodgement_Zone__c logdZone = APT_TestUtils.getLodgementZone('Aust Antarctic Territory','AAT');
            logdZone.APT_Post_Code_Start__c = 1000;
            logdZone.APT_Post_Code_End__c = 9000;
            insert logdZone;               
            
            
            //Create Product Configuration             
            Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
                                                                                                       proposal.Id, 'Proposal',
                                                                                                       'Ad Hoc',priceList.Id, null,
                                                                                                       'Ready For Finalization',
                                                                                                       null, Datetime.now(), true);
            
            Apttus_Config2__ProductAttribute__c productAttribute = APT_TestUtils.createProductAttribute('APT_Zone__c', productAttributeGroup.Id);
            insert productAttribute;
            
            Apttus_Config2__LineItem__c internationalLine = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
                                                                                            1, 'Product/Service', product.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
                                                                                            null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
                                                                                            'Each', 1, priceList.Id, priceListItem.Id,//Uom, term, priceList, Pli,
                                                                                            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
                                                                                            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
                                                                                            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            internationalLine.Apttus_Config2__AllowManualAdjustment__c = true;
            internationalLine.Apttus_Config2__NetPrice__c = 5225;
            internationalLine.Apttus_Config2__PrimaryLineNumber__c = 1;
            internationalLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
            insert internationalLine;
            
            Apttus_Config2__ProductAttributeValue__c attribute_IP = APT_TestUtils.GetAttributeValue(internationalLine.Id,'Standard',false,false,false,'Yes','B Mining',True,false);
            attribute_IP.Category__c='CAT1';
            attribute_IP.APT_Postcode__c = '2000';
            attribute_IP.APT_Lodgement_Zone__c=logdZone.ID; 
            attribute_IP.APT_AirmailSmallParcelGT2kgAVGWeightKG__c = 3;
            attribute_IP.APT_Distribution_Type_Printpost__c = 'Local Sort Division;Same State Metro;Other State';
            attribute_IP.APT_Volume_Threshold_Post_BillPay__c='25,001 – 100,000';
            attribute_IP.APT_PostBillPay_Volume_threshold__c='25,001 – 100,000';
            //attribute1.Apttus_Config2__LineItemId__c = null;
            attribute_IP.APT_Volume_Data__c = APT_Constants.OPTION_YES;
            attribute_IP.APT_RK_Code_Applied__c = false;
            attribute_IP.APT_Domestic_Customer__c = null;
            insert attribute_IP; 
            
            
            list<Apttus_Config2__PriceDimension__c> listPriceDimension  = new list<Apttus_Config2__PriceDimension__c> ();
            Apttus_Config2__PriceDimension__c priceDimension11 = APT_TestUtils.createPriceDimension('Zone', 'Product Attribute','Apttus_Config2__ProductAttributeValue__c', 'APT_Zone__c', productAttribute.Id);
            listPriceDimension.add(priceDimension11);
            
            Apttus_Config2__PriceDimension__c priceDimension12 = APT_TestUtils.createPriceDimension('International Price Type', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
            listPriceDimension.add(priceDimension12);
            
            Apttus_Config2__PriceDimension__c priceDimension13 = APT_TestUtils.createPriceDimension('Weight Range', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'Weight_Range__c', productAttribute.Id);
            listPriceDimension.add(priceDimension13);
            
            insert listPriceDimension;
            
            product.APT_International_Pricing__c = true;
            insert product;
            
            list<Apttus_Config2__PriceMatrix__c> listPM = new list<Apttus_Config2__PriceMatrix__c>();
            Apttus_Config2__PriceMatrix__c priceMatrixIP_1 = APT_TestUtils.createPriceMatrix(priceListItem.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
            listPM.add(priceMatrixIP_1);          
            
            list<Apttus_Config2__PriceMatrixEntry__c> listPME = new list<Apttus_Config2__PriceMatrixEntry__c>();
            Apttus_Config2__PriceMatrixEntry__c pme_1 = new Apttus_Config2__PriceMatrixEntry__c();
            pme_1.Apttus_Config2__Dimension1Value__c = 'Zone1';
            pme_1.Apttus_Config2__Dimension2Value__c = '2';
            pme_1.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pme_1.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_1.Id;
            pme_1.Apttus_Config2__Sequence__c = 1;
            pme_1.Apttus_Config2__UsageRate__c = 1;
            pme_1.Apttus_Config2__AdjustmentAmount__c = 1;
            pme_1.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pme_1);    
            
            insert listPME;	
            
            attribute_IP.Category__c = APT_Constants.CATEGORY_CAT2;
            
            Test.starttest();
            try{
                attribute_IP.APT_International_Standard_Weight_Kgs__c = 1;
                update attribute_IP;
            }catch(Exception e){}
            
            
            Test.stoptest();
            
        }			 
    }*/
	
    
    @isTest
    public static void testInternationalProduct_EXPRESS_DOCT_INTERNATIONAL_PRODUCT_Zone1(){
        Product2 internationalProduct = APT_TestUtils.createInternationalProduct(APT_Constants.EXPRESS_DOCT_INTERNATIONAL_PRODUCT ,
                                                                                      APT_Constants.EXPRESS_DOCT_INTERNATIONAL_PRODUCT , 'Parcel Services');
            internationalProduct.APT_International_Pricing__c = true;
        testMethodePCMSbundles1(internationalProduct, 'Zone 1');
    }
    
    public static void testMethodePCMSbundles1(Product2 internationalProduct, string zone)     
    {
        UserRole role = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
        insert role;

        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
                                 EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
                                 LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
                                 TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
                                 UserName=APT_Constants.EMAIL_TEST_USER, UserRoleId = role.Id);
        System.runAs(testuser) {    
            //Create Account
            Account acc = APT_TestUtils.createOrganisation();
            acc.Industry = 'Logistics';
            insert acc;
            
            //Create Opportunity
            Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
            insert opty;
            
            //Create PriceList
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            //create international product
            Product2 bundle1 = APT_TestUtils.createInternationalProduct('International Digital PCMS Bundle incl Airmail Letters',
                                                                        'InternationalDigitalPCMSBundlewithAirmail','Parcel Services');
            bundle1.ProductCode = null;
            insert bundle1;
            
            //Create Price list Item
            Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
            pli.APT_Band__c = 'Band 2';
            insert pli;
            
            //Create Proposal
            Apttus_Proposal__Proposal__c Proposal= APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
            insert Proposal;
            
            //Create Product Configuration             
            Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
                                                                                                       proposal.Id, 'Proposal',
                                                                                                       'Ad Hoc',priceList.Id, null,
                                                                                                       'Ready For Finalization',
                                                                                                       null, Datetime.now(), true);
            prodconfig.Apttus_Config2__AccountId__c =null;
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
            insert bundleLine;                  
            
            //create Logdement Zone             
            APT_Lodgement_Zone__c logdZone = APT_TestUtils.getLodgementZone('Aust Antarctic Territory','AAT');
            logdZone.APT_Post_Code_Start__c = 1000;
            logdZone.APT_Post_Code_End__c = 9000;
            insert logdZone;               
            
            //international price data
            list<APT_International_Price_Data__c> listInternationalPriceData = new list<APT_International_Price_Data__c>();
            List<String> listProduct = new List<String>{APT_Constants.PRODUCT_AIRMAILLETTER,
                APT_Constants.PRODUCT_InternationalExpressDocuments,
                APT_Constants.PRODUCT_InternationalExpressMerchandise,
                APT_Constants.PRODUCT_InternationalStandard,
                APT_Constants.PRODUCT_INTERNATIONALSTANDARDWITHSIGNATURE,
                APT_Constants.PRODUCT_InternationalEconomy,
                APT_Constants.PRODUCT_INTERNATIONALECONOMYWITHSIGNATURE};
                    
                    
                    for(string prod:listProduct)
                {
                    for(integer i=1;i<=9;i++)
                    {
                        
                        //APT_International_Price_Data__c ipd = APT_TestUtils.createInternationalPriceData(prod, 'B Mining', 'BAND 2', 'Zone'+i, 0, 2999, 10, 10, 20, 20);
                        APT_International_Price_Data__c ipd = new APT_International_Price_Data__c();
                        ipd.APT_Product__c = prod;
                        ipd.APT_Industry__c = 'B Mining';
                        ipd.APT_Band__c = 'BAND 2';
                        ipd.APT_Zone__c = 'Zone'+i;
                        ipd.APT_Band_Range_Min__c = 0;
                        ipd.APT_Band_Range_Max__c = 2999;
                        ipd.APT_CSP_Per_Item_Rate__c = 10;
                        ipd.APT_CSP_Per_Kg_Rate__c = 10;
                        ipd.APT_eParcel_Per_Item_Rate__c = 10;
                        ipd.APT_eParcel_Per_Kg_Rate__c = 10;
                        ipd.APT_Weight__c = 'up to 500g';
                        listInternationalPriceData.add(ipd);             
                        
                    } 
                }           
            
            
            
            insert listInternationalPriceData;
            
            //Create Feature Pricing              
            APT_Feature_Pricing__c featurePricing = APT_TestUtils.getFeaturePricing('Aust Antarctic Territory','CAT1','AAT','Standard','EPR2',10,1);           
            insert featurePricing;
            
            //Create product Attribute value                
            Apttus_Config2__ProductAttributeValue__c attribute1 = APT_TestUtils.GetAttributeValue(bundleLine.Id,'Standard',false,false,false,'Yes','B Mining',True,false);
            attribute1.Category__c='CAT1';
            attribute1.APT_Postcode__c = '2000';
            attribute1.APT_Lodgement_Zone__c=logdZone.ID; 
            attribute1.APT_AirmailSmallParcelGT2kgAVGWeightKG__c = 3;
            attribute1.APT_Distribution_Type_Printpost__c = 'Local Sort Division;Same State Metro;Other State';
            attribute1.APT_Volume_Threshold_Post_BillPay__c='25,001 – 100,000';
            attribute1.APT_PostBillPay_Volume_threshold__c='25,001 – 100,000';
            //attribute1.Apttus_Config2__LineItemId__c = null;
            attribute1.APT_Domestic_Customer__c = null;
            insert attribute1; 
            
            list<Product2> products = new list<Product2>();
            
            //Domestic (non startrack) product
            Product2 productCAT1STD = APT_TestUtils.createDomesticProduct('CAT1 Standard', 'CAT1Standard', 'Parcel Services', 'CAT1', 'STANDARD');
            productCAT1STD.APT_Domestic_Pricing__c = true;
            products.add( productCAT1STD);
            //Startrack Product
            Product2 productNXF = APT_TestUtils.createStarTrackProduct('Next Flight Tier 1', 'NextFlightTier1', 'Parcel Services', 'T01', 'NXF', 'Startrack');
            productNXF.APT_Domestic_Pricing__c = true;
            products.add(productNXF);
            Product2 productEXP = APT_TestUtils.createStarTrackProduct('Road Express', 'RoadExpress', 'Parcel Services', 'T01', 'EXP', 'Startrack');
            productEXP.APT_Domestic_Pricing__c = true;
            products.add(productEXP);
            //International product 1
            Product2 productAIRLET = APT_TestUtils.createInternationalProduct('Air Mail Letters', 'AIRLET', 'Parcel Services');
            productAIRLET.APT_International_Pricing__c = true;
            products.add( productAIRLET);
            
            Product2 internationalProduct1 = APT_TestUtils.createInternationalProduct(APT_Constants.EXPRESS_DOCT_INTERNATIONAL_PRODUCT ,
                                                                                      APT_Constants.EXPRESS_DOCT_INTERNATIONAL_PRODUCT , 'Parcel Services');
            internationalProduct1.APT_International_Pricing__c = true;
            products.add(internationalProduct1);
            
            Product2 internationalProduct2 = APT_TestUtils.createInternationalProduct(APT_Constants.EXPRESS_MERCH_INTERNATIONAL_PRODUCT ,
                                                                                      APT_Constants.EXPRESS_MERCH_INTERNATIONAL_PRODUCT , 'Parcel Services');
            internationalProduct2.APT_International_Pricing__c = true;
            products.add( internationalProduct2);
            
            
            
            Product2 internationalProduct4 = APT_TestUtils.createInternationalProduct(APT_Constants.STANDARD_SIGN_INTERNATIONAL_PRODUCT  ,
                                                                                      APT_Constants.STANDARD_SIGN_INTERNATIONAL_PRODUCT  , 'Parcel Services');
            internationalProduct4.APT_International_Pricing__c = true;
            products.add( internationalProduct4);
            
            Product2 internationalProduct5 = APT_TestUtils.createInternationalProduct(APT_Constants.ECONOMY_INTERNATIONAL_PRODUCT,
                                                                                      APT_Constants.ECONOMY_INTERNATIONAL_PRODUCT, 'Parcel Services');
            internationalProduct5.APT_International_Pricing__c = true;
            products.add( internationalProduct5);
            
            Product2 internationalProduct6 = APT_TestUtils.createInternationalProduct(APT_Constants.ECONOMY_SIGN_INTERNATIONAL_PRODUCT,
                                                                                      APT_Constants.ECONOMY_SIGN_INTERNATIONAL_PRODUCT, 'Parcel Services');
            internationalProduct6.APT_International_Pricing__c = true;
            products.add( internationalProduct6);
            
            Product2 internationalProduct7 = APT_TestUtils.createInternationalProduct(APT_Constants.PRODUCT_CODE_NEW_AIRMAIL_LETTERS,
                                                                                      APT_Constants.PRODUCT_CODE_NEW_AIRMAIL_LETTERS, 'Parcel Services');
            internationalProduct7.APT_International_Pricing__c = true;
            products.add( internationalProduct7);
			
			Product2 internationalProduct8 = APT_TestUtils.createInternationalProduct(APT_Constants.AIRLET_INTERNATIONAL_PRODUCT,
                                                                                      APT_Constants.AIRLET_INTERNATIONAL_PRODUCT, 'Parcel Services');
            internationalProduct8.APT_International_Pricing__c = true;
            products.add( internationalProduct8);
			
			Product2 internationalProduct9 = APT_TestUtils.createInternationalProduct(APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT,
                                                                                      APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT, 'Parcel Services');
            internationalProduct9.APT_International_Pricing__c = true;
            products.add( internationalProduct9);
			
			Product2 internationalProduct10 = APT_TestUtils.createInternationalProduct(APT_Constants.AIRPTI_INTERNATIONAL_PRODUCT,
                                                                                      APT_Constants.AIRPTI_INTERNATIONAL_PRODUCT, 'Parcel Services');
            internationalProduct10.APT_International_Pricing__c = true;
            products.add( internationalProduct10);
			
			Product2 internationalProduct11 = APT_TestUtils.createInternationalProduct(APT_Constants.AIRRPI_INTERNATIONAL_PRODUCT,
                                                                                      APT_Constants.AIRRPI_INTERNATIONAL_PRODUCT, 'Parcel Services');
            internationalProduct11.APT_International_Pricing__c = true;
            products.add( internationalProduct11);
			
			Product2 internationalProduct12 = APT_TestUtils.createInternationalProduct(APT_Constants.AIRSMPCL_INTERNATIONAL_PRODUCT,
                                                                                      APT_Constants.AIRSMPCL_INTERNATIONAL_PRODUCT, 'Parcel Services');
            internationalProduct12.APT_International_Pricing__c = true;
            products.add( internationalProduct12);
			
			Product2 internationalProduct13 = APT_TestUtils.createInternationalProduct(APT_Constants.EMSDOCT_INTERNATIONAL_PRODUCT,
                                                                                      APT_Constants.EMSDOCT_INTERNATIONAL_PRODUCT, 'Parcel Services');
            internationalProduct13.APT_International_Pricing__c = true;
            products.add( internationalProduct13);
			
			Product2 internationalProduct14 = APT_TestUtils.createInternationalProduct(APT_Constants.EMSMERCH_INTERNATIONAL_PRODUCT,
                                                                                      APT_Constants.EMSMERCH_INTERNATIONAL_PRODUCT, 'Parcel Services');
            internationalProduct14.APT_International_Pricing__c = true;
            products.add( internationalProduct14);
			
			Product2 internationalProduct15 = APT_TestUtils.createInternationalProduct(APT_Constants.EMSMER20_INTERNATIONAL_PRODUCT,
                                                                                      APT_Constants.EMSMER20_INTERNATIONAL_PRODUCT, 'Parcel Services');
            internationalProduct15.APT_International_Pricing__c = true;
            products.add( internationalProduct15);
			
            insert products;
			
            list<Product2> internationalProducts = new list<Product2> {internationalProduct};
                  
            List<Apttus_Config2__PriceListItem__c> priceListItemList = new List<Apttus_Config2__PriceListItem__c>();
            
            Apttus_Config2__PriceListItem__c priceListItemIP_3 = APT_TestUtils.createPriceListItem(priceList.id,internationalProduct.id,'','');
            priceListItemIP_3.APT_Band__c = 'Band 2';
            priceListItemIP_3.APT_Band_Range_Max__c = 1000;
            priceListItemIP_3.APT_Pricing_Key__c = internationalProduct.Id + '~' + internationalProduct.Productcode+'~'+'BAND 2';
            priceListItemList.add(priceListItemIP_3);
            
            insert priceListItemList;
            
            Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = APT_TestUtils.createProductAttributeGroup('Apttus_Config2__ProductAttributeValue__c');
            insert productAttributeGroup;
            
            Apttus_Config2__ProductAttribute__c productAttribute = APT_TestUtils.createProductAttribute('APT_Zone__c', productAttributeGroup.Id);
            insert productAttribute;
            
            list<Apttus_Config2__PriceDimension__c> listPriceDimension = new list<Apttus_Config2__PriceDimension__c>();
            Apttus_Config2__PriceDimension__c priceDimension1 = APT_TestUtils.createPriceDimension('Destination Zone Code', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Destination_Zone_Code__c', productAttribute.Id);
            listPriceDimension.add(priceDimension1);
            
            Apttus_Config2__PriceDimension__c priceDimension2 = APT_TestUtils.createPriceDimension('Domestic Price Type', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Domestic_Price_Type__c', productAttribute.Id);
            listPriceDimension.add(priceDimension2);
            
            Apttus_Config2__PriceDimension__c priceDimension3 = APT_TestUtils.createPriceDimension('Weight Range Code', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Weight_Range_Code__c', productAttribute.Id);
            listPriceDimension.add(priceDimension3);
            
            Apttus_Config2__PriceDimension__c priceDimension4 = APT_TestUtils.createPriceDimension('Zone Type', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Zone_Type__c', productAttribute.Id);
            listPriceDimension.add(priceDimension4); 
            
            Apttus_Config2__PriceDimension__c priceDimension5 = APT_TestUtils.createPriceDimension('Inbound - Outbound', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Inbound_Outbound__c', productAttribute.Id);
            listPriceDimension.add(priceDimension5);
            
            Apttus_Config2__PriceDimension__c priceDimension6 = APT_TestUtils.createPriceDimension('Pickup Zone Code', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Pickup_Zone_Code__c', productAttribute.Id);
            listPriceDimension.add(priceDimension6);
            
            Apttus_Config2__PriceDimension__c priceDimension7 = APT_TestUtils.createPriceDimension('Price Type', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Price_Type__c', productAttribute.Id);
            listPriceDimension.add(priceDimension7);
            
            Apttus_Config2__PriceDimension__c priceDimension8 = APT_TestUtils.createPriceDimension('Basic Charge', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Basic_Charge__c', productAttribute.Id);
            listPriceDimension.add(priceDimension8);            
            
            Apttus_Config2__PriceDimension__c priceDimension9 = APT_TestUtils.createPriceDimension('KG Rate', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_KG_Rate__c', productAttribute.Id);
            listPriceDimension.add(priceDimension9); 
            
            Apttus_Config2__PriceDimension__c priceDimension10 = APT_TestUtils.createPriceDimension('Minimum Charge', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Minimum_Charge__c', productAttribute.Id);
            listPriceDimension.add(priceDimension10);
            
            Apttus_Config2__PriceDimension__c priceDimension11 = APT_TestUtils.createPriceDimension('Zone', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_Zone__c', productAttribute.Id);
            listPriceDimension.add(priceDimension11);
            
            Apttus_Config2__PriceDimension__c priceDimension12 = APT_TestUtils.createPriceDimension('International Price Type', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'APT_International_Price_Type__c', productAttribute.Id);
            listPriceDimension.add(priceDimension12);
            
            Apttus_Config2__PriceDimension__c priceDimension13 = APT_TestUtils.createPriceDimension('Weight Range', 'Product Attribute', 'Apttus_Config2__ProductAttributeValue__c', 'Weight_Range__c', productAttribute.Id);
            listPriceDimension.add(priceDimension13);    
            
            insert listPriceDimension;
            
            List<Apttus_Config2__PriceMatrix__c> listPM = new List<Apttus_Config2__PriceMatrix__c>();
            
            Apttus_Config2__PriceMatrix__c priceMatrixIP_3 = APT_TestUtils.createPriceMatrix(priceListItemIP_3.Id,priceDimension11.Id,priceDimension12.Id, priceDimension13.Id);
            listPM.add(priceMatrixIP_3);          
            
            insert listPM;
            System.debug('Line: 1387');
            list<Apttus_Config2__PriceMatrixEntry__c> listPME = new list<Apttus_Config2__PriceMatrixEntry__c>();
            
            Apttus_Config2__PriceMatrixEntry__c pmeIP_3 = new Apttus_Config2__PriceMatrixEntry__c();
            pmeIP_3.Apttus_Config2__Dimension1Value__c = zone;
            pmeIP_3.Apttus_Config2__Dimension2Value__c = '2';
            pmeIP_3.Apttus_Config2__Dimension3Value__c = APT_Constants.Weight_Upto500g;
            pmeIP_3.Apttus_Config2__PriceMatrixId__c = priceMatrixIP_3.Id;
            pmeIP_3.Apttus_Config2__Sequence__c = 1;
            pmeIP_3.Apttus_Config2__UsageRate__c = 1;
            pmeIP_3.Apttus_Config2__AdjustmentAmount__c = 1;
            pmeIP_3.Apttus_Config2__PriceOverride__c = 1;
            listPME.add(pmeIP_3);         
			
            insert listPME; 
			
            
            Test.starttest();    
            // update product Attribute value
            //attribute1.Category__c='CAT1';
            attribute1.APT_Distribution_Type_Printpost__c = 'Local Sort Division;Same State Metro;Other State;Large Postcode Direct';               
            attribute1.APT_Domestic_Customer__c = null;
            attribute1.APT_Band__c = 'Band 2';
            attribute1.Category__c=null;
            attribute1.APT_Lodgement_Zone__c = null;
            attribute1.Apttus_Config2__LineItemId__c = null;
            attribute1.APT_Volume_Data__c = APT_Constants.OPTION_YES;

            try{
                Update attribute1;     
            }
            Catch(Exception e){
                
            }
            try{
                attribute1.Category__c = APT_Constants.CATEGORY_CAT2;
                Update attribute1;
                
            }
            Catch(Exception e){}
            try{
                attribute1.Category__c = APT_Constants.CATEGORY_CAT3;
                Update attribute1;     
               
            }
            Catch(Exception e){
                
            }
            try{
                attribute1.Category__c = APT_Constants.CATEGORY_CAT4;
                Update attribute1;     
               
            }
            Catch(Exception e){
                
            }
            try{
                attribute1.Category__c = APT_Constants.CATEGORY_CAT5;
                Update attribute1;     
               
            }
            Catch(Exception e){
                
            }
            try{
                attribute1.Category__c = APT_Constants.CATEGORY_CAT6;
                Update attribute1;     
            }
            Catch(Exception e){
                
            }
            
            for(product2 product : internationalProducts){
                try
                {
                Apttus_Config2__PriceListItem__c priceListIt = [select Id,  Apttus_Config2__ProductId__r.ProductCode from Apttus_Config2__PriceListItem__c where Apttus_Config2__ProductId__r.ProductCode =: product.ProductCode limit 1];
                
                Apttus_Config2__LineItem__c internationalLine = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
                                                                                                1, 'Product/Service', product.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
                                                                                                null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
                                                                                                'Each', 1, priceList.Id, priceListIt.Id,//Uom, term, priceList, Pli,
                                                                                                'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
                                                                                                true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
                                                                                                5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
                internationalLine.Apttus_Config2__AllowManualAdjustment__c = true;
                internationalLine.Apttus_Config2__NetPrice__c = 5225;
                internationalLine.Apttus_Config2__PrimaryLineNumber__c = 1;
                internationalLine.Apttus_Config2__NetAdjustmentPercent__c = -10;
                insert internationalLine;
                
             Apttus_Config2__ProductAttributeValue__c attribute_IP = APT_TestUtils.GetAttributeValue(internationalLine.Id,'Standard',false,false,false,'Yes','B Mining',True,false);
            attribute_IP.Category__c='CAT1';
            attribute_IP.APT_Postcode__c = '2000';
            attribute_IP.APT_Lodgement_Zone__c=logdZone.ID; 
            attribute_IP.APT_AirmailSmallParcelGT2kgAVGWeightKG__c = 3;
            attribute_IP.APT_Distribution_Type_Printpost__c = 'Local Sort Division;Same State Metro;Other State';
            attribute_IP.APT_Volume_Threshold_Post_BillPay__c='25,001 – 100,000';
            attribute_IP.APT_PostBillPay_Volume_threshold__c='25,001 – 100,000';
            //attribute1.Apttus_Config2__LineItemId__c = null;
            attribute_IP.APT_Volume_Data__c = APT_Constants.OPTION_YES;
            attribute1.APT_RK_Code_Applied__c = false;
            attribute_IP.APT_Domestic_Customer__c = null;
            insert attribute_IP; 
                
                attribute_IP.Category__c = APT_Constants.CATEGORY_CAT2;
                    
                    try{
                    
                        update attribute_IP;
                    }
                    catch(Exception e){}
                    if(product.ProductCode == APT_Constants.STANDARD_INTERNATIONAL_PRODUCT){
                        try{
                            attribute_IP.APT_International_Standard_Weight_Kgs__c = 1;
                            update attribute_IP;
                        }catch(Exception e){}
                        try{
                            attribute_IP.APT_International_Standard_Weight_Kgs__c = 2;
                            update attribute_IP;
                        }catch(Exception e){}
                        try{
                            attribute_IP.APT_International_Standard_Weight_Kgs__c = 10;
                            update attribute_IP;
                        }catch(Exception e){}
                    }
                    
                   else if(product.ProductCode == APT_Constants.STANDARD_SIGN_INTERNATIONAL_PRODUCT){
                        try{
                            attribute_IP.APT_International_Std_W_Sig_Weight_Kgs__c = 1;
                            update attribute_IP;
                        }catch(Exception e){}
                        try{
                            attribute_IP.APT_International_Std_W_Sig_Weight_Kgs__c = 2;
                            update attribute_IP;
                        }catch(Exception e){}
                        try{
                            attribute_IP.APT_International_Std_W_Sig_Weight_Kgs__c = 10;
                            update attribute_IP;
                        }catch(Exception e){}
                    }
                     else if(product.ProductCode == APT_Constants.ECONOMY_SIGN_INTERNATIONAL_PRODUCT){
                        try{
                            attribute_IP.APT_International_Eco_W_Sig_Weight_Kgs__c = 1;
                            update attribute_IP;
                        }catch(Exception e){}
                        try{
                            attribute_IP.APT_International_Eco_W_Sig_Weight_Kgs__c = 2;
                            update attribute_IP;
                        }catch(Exception e){}
                    }
                    else if(product.ProductCode == APT_Constants.ECONOMY_INTERNATIONAL_PRODUCT){
                        try{
                            attribute_IP.APT_International_Economy_Weight_Kgs__c = 1;
                            update attribute_IP;
                        }catch(Exception e){}
                        try{
                            attribute_IP.APT_International_Economy_Weight_Kgs__c = 2;
                            update attribute_IP;
                        }catch(Exception e){}
                    }
                    else if(product.ProductCode == APT_Constants.EXPRESS_MERCH_INTERNATIONAL_PRODUCT){
                        try{
                            attribute_IP.APT_International_Exp_Merch_Weight_Kgs__c = 1;
                            update attribute_IP;
                        }catch(Exception e){}
                        try{
                            attribute_IP.APT_International_Exp_Merch_Weight_Kgs__c = 2;
                            update attribute_IP;
                        }catch(Exception e){}
                        try{
                            attribute_IP.APT_International_Exp_Merch_Weight_Kgs__c = 10;
                            update attribute_IP;
                        }catch(Exception e){}
                    }
					 else if(product.ProductCode == APT_Constants.ECONOMY_SIGN_INTERNATIONAL_PRODUCT){
                        try{
                            attribute_IP.APT_International_Eco_W_Sig_Weight_Kgs__c = 1;
                            update attribute_IP;
                        }catch(Exception e){}
                        try{
                            attribute_IP.APT_International_Eco_W_Sig_Weight_Kgs__c = 2;
                            update attribute_IP;
                        }catch(Exception e){}
                    }
					
                    
                }
                catch(Exception e){
                    
                }
            }
            
            //system.assert('SUCCESS' == APT_Constants.SUCCESS_LABEL);
            Test.stoptest();
            //system.assert(listInternationalPriceData.size()>0);
            //System.assertEquals(listProduct[0],'AIRMAIL_LETTERS');
            //system.assert(attribute1.Apttus_Config2__LineItemId__c !=null);      
        }
        
        double num=0;
        set<string> s11=new set<string>();
        s11.add('Zone6');
        list<APT_International_Price_Data__c> listIdpData=new list<APT_International_Price_Data__c>();
        APT_International_Price_Data__c ipd1 = APT_TestUtils.createInternationalPriceData('EXPRESS_DOCT', 'B Mining', 'BAND 2', null, 0, 2999, 10, 10, 20, 20);
        listIdpData.add(ipd1);
        string data=listIdpData[0].APT_Band__c + APT_Constants.SEPERATOR_SIMILARITY + listIdpData[0].APT_Product__c + APT_Constants.SEPERATOR_SIMILARITY + listIdpData[0].APT_Zone__c;
        map<string, list<APT_International_Price_Data__c>> mapDataPrice=new map<string,list<APT_International_Price_Data__c>>();
        mapDataPrice.put(data,listIdpData);
        
        //APT_ProductAttributeValueTriggerHandler.calculateProductRevenueforNewIntBundle(num,Null,'BAND 2','EXPRESS_DOCT',s11,'CSP',mapDataPrice,null);
        //APT_ProductAttributeValueTriggerHandler.calculateProductRevenueforNewIntBundle(num,Null,'BAND 2','EXPRESS_DOCT',s11,'CSP',mapDataPrice,null);
    }    

}