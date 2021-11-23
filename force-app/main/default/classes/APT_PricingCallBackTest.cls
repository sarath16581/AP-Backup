/**
 * @description       : This test class is written for APT_PricingCallBack
 * @author            : Mansi Shah
 * @group             : 
 * @last modified on  : 05-28-2021
 * @last modified by  : Mansi Shah
 * Modifications Log 
 * Ver   Date         Author       Modification
 * 1.0   05-28-2021   Mansi Shah   Initial Version
**/
@isTest
public class APT_PricingCallBackTest {
       
    @TestSetup
    static void makeData(){
        Profile p = [SELECT Id FROM Profile WHERE Name='BG Base'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        insert testuser;

        //create config custom class properties
        Apttus_Config2__ConfigCustomClasses__c configCustomClassesProperty = new Apttus_Config2__ConfigCustomClasses__c();
        configCustomClassesProperty.Name = 'Config Custom Classes';
        configCustomClassesProperty.Apttus_Config2__PricingCallbackClass__c = 'APT_PricingCallBack';
        insert configCustomClassesProperty;
        
        Apttus_Config2__ConfigLineItemCustomFields__c configLine1 = new Apttus_Config2__ConfigLineItemCustomFields__c();
        configLine1.Name = '1';
        configLine1.Apttus_Config2__CustomFieldNames__c = 'APT_Cascade_Adjustments__c,APT_Rate_Card_Key__c,APT_Pricing_Reason__c,APT_Competitors__c,Apttus_Config2__OptionId__c,Apttus_Config2__ParentBundleNumber__c,APT_New__c, Apttus_CQApprov__Approval_Status__c';
        configLine1.Apttus_Config2__CustomFieldNames2__c = 'Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.APT_International_CO__c,Apttus_Config2__ProductId__r.Name,Apttus_Config2__AdjustmentType__c,Apttus_Config2__AttributeValueId__c,Apttus_Config2__AttributeValueId__r.APT_Band__c';
        configLine1.Apttus_Config2__CustomFieldNames3__c = 'Apttus_Config2__ConfigurationId__r.APT_Created_On__c,APT_Is_Band_Changed__c,Apttus_Config2__ConfigurationId__r.APT_Is_Cloned__c,APT_New_Renew__c,APT_For_Price_Change__c';
        configLine1.Apttus_Config2__CustomFieldNames5__c = 'Apttus_Config2__AttributeValueId__r.APT_RK_Code_Applied__c,Apttus_Config2__ProductId__r.APT_Product_type__c,Apttus_Config2__AttributeValueId__r.APT_Post_Code_Suburb__c';
        configLine1.Apttus_Config2__CustomFieldNames4__c = 'Apttus_Config2__AttributeValueId__r.APT_Band_Original_Value__c,APT_Band__c,Apttus_Config2__IsPrimaryLine__c,Apttus_Config2__LineType__c,APT_Product_Name__c, Apttus_Config2__PriceListItemId__c,APT_Is_Higher_Band_Offered__c';
        
        Apttus_Config2__ConfigLineItemCustomFields__c configLine2 = new Apttus_Config2__ConfigLineItemCustomFields__c();
        configLine2.Name = '2';
        configLine2.Apttus_Config2__CustomFieldNames__c = 'Apttus_Config2__OptionId__r.Name, APT_Amendment__c,APT_Added_LP__c,Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__r.APT_Contract_Id__c,Apttus_Config2__AttributeValueId__r.Revenue_Committment__c,APT_Is_OPC_deleted__c';
        configLine1.Apttus_Config2__CustomFieldNames2__c = 'Apttus_Config2__AttributeValueId__r.APT_LPD_Total_Service_Fee__c';
        //configLine1.Apttus_Config2__CustomFieldNames3__c = 'Apttus_Config2__AttributeValueId__r.APT_LPD_Calculate_Frequency_Days__c';
        configLine1.Apttus_Config2__CustomFieldNames5__c = 'Apttus_Config2__AttributeValueId__r.APT_Cubic_Factor__c,Apttus_Config2__ProductId__r.ProductCode';
               
        insert new List<Apttus_Config2__ConfigLineItemCustomFields__c>{configLine1, configLine2};
            
        // insert display action

           System.runAs(testuser) {
            Account acc = APT_TestUtils.createOrganisation();
            insert acc;
            
             List<Opportunity> listOfOpportunities = new List<Opportunity>();
            //Create Opportunity
            Opportunity opty = APT_TestUtils.createOpportunity(acc.Id);
            opty.type = 'New Customer';
            listOfOpportunities.add(opty);
                
            Opportunity opty1 = APT_TestUtils.createOpportunity(acc.Id);
            opty1.type = 'New Customer';
            listOfOpportunities.add(opty1);
               
            insert listOfOpportunities;                
            
            //Create PriceList
            Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
            insert priceList;
            
            List<Apttus_Proposal__Proposal__c> listOfProposals = new List<Apttus_Proposal__Proposal__c>();
            Apttus_Proposal__Proposal__c proposal = APT_TestUtils.getQuoteProposal(acc.ID,opty.ID,'Proposal','Quote', priceList.ID);
            listOfProposals.add(proposal);
            
            Apttus_Proposal__Proposal__c proposal1 = APT_TestUtils.getQuoteProposal(acc.ID,opty1.ID,'Proposal','Quote', priceList.ID);
            listOfProposals.add(proposal1);
               
            insert listOfProposals;
            
            List<Apttus_Config2__ProductConfiguration__c> listOfProductConfig = new List<Apttus_Config2__ProductConfiguration__c>();
               
            Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration 1', 1, 
                                                                    proposal.Id, 'Proposal','Ad Hoc',priceList.Id, null,'Ready For Finalization',null, Datetime.now(), true);
            listOfProductConfig.add(prodconfig);
               
            Apttus_Config2__ProductConfiguration__c prodconfig1 = APT_TestUtils.getProductConfiguration('Product Configuration 2', 1, 
                                                                    proposal.Id, 'Proposal','Ad Hoc',priceList.Id, null,'Ready For Finalization',null, Datetime.now(), true);
            listOfProductConfig.add(prodconfig1);
               
            Apttus_Config2__ProductConfiguration__c prodconfig2 = APT_TestUtils.getProductConfiguration('Product Configuration 3', 1, 
                                                                    proposal.Id, 'Proposal','Ad Hoc',priceList.Id, null,'Ready For Finalization',null, Datetime.now(), true);
            listOfProductConfig.add(prodconfig2);
               
            Apttus_Config2__ProductConfiguration__c prodconfig3 = APT_TestUtils.getProductConfiguration('Product Configuration 4', 1, 
                                                                    proposal.Id, 'Proposal','Ad Hoc',priceList.Id, null,'Ready For Finalization',null, Datetime.now(), true);
            listOfProductConfig.add(prodconfig3);
            insert listOfProductConfig;
               
            List<Product2> listOfProducts = new List<Product2>();
            Product2 bundle1 = APT_TestUtils.createDomesticProduct(APT_Constants.PRODUCT_NAME_LOCAL_PICKUP_DELIVERY,'LPDC','Others',null,null);
            bundle1.Non_contracted__c = false;
            listOfProducts.add(bundle1);
               
            Product2 bundle2 = APT_TestUtils.createDomesticProduct(APT_Constants.PRODUCT_CODE_POST_BILLPAY,'LPDC','Others',null,null);
            bundle2.Non_contracted__c = false;
            listOfProducts.add(bundle2);
               
           Product2 bundle3 =APT_TestUtils.createInternationalProduct(APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE,'InternationalBundle','Parcel Services');
            //product2.APT_Product_type__c = 'International';
               
            listOfProducts.add(bundle3);   
            
                
            Product2 option2 = new Product2();
            option2.Name = 'Post Bill Pay Option';
            option2.Family = 'Product & Innovation';
            option2.APT_Apttus_Product_Classification__c = 'Postal Services';
            option2.IsActive = true;
            option2.APT_Domestic_Pricing__c = true;
            option2.Apttus_Config2__ConfigurationType__c = 'Option';
            option2.APT_Cascade_Adjustments__c = true;
            listOfProducts.add(option2);
            insert listOfProducts;
            
            //Create Price list Item
            Apttus_Config2__PriceListItem__c pli = APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
            insert pli;
            
            List<Apttus_Config2__LineItem__c> listOfLineItems = new List<Apttus_Config2__LineItem__c>(); 
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
            listOfLineItems.add(bundleLine);
               
                           
            Apttus_Config2__LineItem__c bundleLine1 = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, false,//Config Id, grpId, LineNum, isPrimary
            1, 'Product/Service', bundle2.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
            null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            bundleLine1.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine1.Apttus_Config2__NetPrice__c = 5225;
            bundleLine1.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine1.Apttus_Config2__NetAdjustmentPercent__c = -10;
            listOfLineItems.add(bundleLine1);
               
            Apttus_Config2__LineItem__c bundleLine3 = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
            1, APT_Constants.LINE_TYPE_PRODUCT_SERVICE, bundle3.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
            null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            bundleLine3.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine3.Apttus_Config2__NetPrice__c = 5225;
            bundleLine3.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine3.Apttus_Config2__NetAdjustmentPercent__c = -10;
            
            listOfLineItems.add(bundleLine3);

            Apttus_Config2__LineItem__c bundleLine4 = APT_TestUtils.getConfigLineItem(prodconfig1.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
            1, APT_Constants.LINE_TYPE_PRODUCT_SERVICE, bundle3.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
            null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            bundleLine4.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine4.Apttus_Config2__NetPrice__c = 5225;
            bundleLine4.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine4.Apttus_Config2__NetAdjustmentPercent__c = -10;
            
            listOfLineItems.add(bundleLine4);
               
            Apttus_Config2__LineItem__c bundleLine5 = APT_TestUtils.getConfigLineItem(prodconfig2.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
            1, APT_Constants.LINE_TYPE_PRODUCT_SERVICE, bundle3.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
            null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            bundleLine3.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine3.Apttus_Config2__NetPrice__c = 5225;
            bundleLine3.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine3.Apttus_Config2__NetAdjustmentPercent__c = -10;
            
            listOfLineItems.add(bundleLine5);
               
            Apttus_Config2__LineItem__c bundleLine6 = APT_TestUtils.getConfigLineItem(prodconfig3.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
            1, APT_Constants.LINE_TYPE_PRODUCT_SERVICE, bundle3.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
            null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable 
            'Each', 1, priceList.Id, pli.Id,//Uom, term, priceList, Pli,
            'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
            true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod, 
            5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            bundleLine3.Apttus_Config2__AllowManualAdjustment__c = true;
            bundleLine3.Apttus_Config2__NetPrice__c = 5225;
            bundleLine3.Apttus_Config2__PrimaryLineNumber__c = 1;
            bundleLine3.Apttus_Config2__NetAdjustmentPercent__c = -10;
            
            listOfLineItems.add(bundleLine6);


            insert listOfLineItems;
                       
            List<Apttus_Config2__LineItem__c> liLineItems = [Select Id,name,Apttus_Config2__PriceListItemId__c from Apttus_Config2__LineItem__c LIMIT 10];
             
            List<Apttus_Config2__ProductAttributeValue__c> listOfPAV = new List<Apttus_Config2__ProductAttributeValue__c>();
               

               
      Apttus_Config2__ProductAttributeValue__c newPAV = new Apttus_Config2__ProductAttributeValue__c();
            newPAV.APT_LPD_Distance_Facility_Provided_In_Km__c = 17;
            //newPAV.APT_LPD_Multiple_Frequency__c = 'Ad hoc';
            newPAV.APT_LPD_Service_Type__c = 'Delivery Service';
            newPAV.Apttus_Config2__LineItemId__c = liLineItems[2].id;
      newPAV.APT_Band__c = APT_Constants.BAND_1;
            newPAV.APT_Band_Original_Value__c = APT_Constants.BAND_1;
            listOfPAV.add(newPAV); 

            Apttus_Config2__ProductAttributeValue__c newPAV1 = new Apttus_Config2__ProductAttributeValue__c();
            newPAV1.APT_LPD_Distance_Facility_Provided_In_Km__c = 17;
           // newPAV1.APT_LPD_Multiple_Frequency__c = 'Ad hoc';
            newPAV1.APT_LPD_Service_Type__c = 'Delivery Service';
            newPAV1.Apttus_Config2__LineItemId__c = liLineItems[2].id;
      newPAV1.APT_Band__c = APT_Constants.BAND_1;
            newPAV1.APT_Band_Original_Value__c = APT_Constants.BAND_2;
            listOfPAV.add(newPAV1); 
               
            Apttus_Config2__ProductAttributeValue__c newPAV2 = new Apttus_Config2__ProductAttributeValue__c();
            newPAV2.APT_LPD_Distance_Facility_Provided_In_Km__c = 17;
            //newPAV2.APT_LPD_Multiple_Frequency__c = 'Ad hoc';
            newPAV2.APT_LPD_Service_Type__c = 'Delivery Service';
            newPAV2.Apttus_Config2__LineItemId__c = liLineItems[2].id;
      newPAV2.APT_Band__c = APT_Constants.BAND_2;
            newPAV2.APT_Band_Original_Value__c = APT_Constants.BAND_3;
            listOfPAV.add(newPAV2); 
               
            Apttus_Config2__ProductAttributeValue__c newPAV3 = new Apttus_Config2__ProductAttributeValue__c();
            newPAV3.APT_LPD_Distance_Facility_Provided_In_Km__c = 17;
            //newPAV3.APT_LPD_Multiple_Frequency__c = 'Ad hoc';
            newPAV3.APT_LPD_Service_Type__c = 'Delivery Service';
            newPAV3.Apttus_Config2__LineItemId__c = liLineItems[2].id;
      newPAV3.APT_Band__c = APT_Constants.BAND_3;
            newPAV3.APT_Band_Original_Value__c = APT_Constants.BAND_4;
            listOfPAV.add(newPAV3); 

            insert listOfPAV;
            
               List<Apttus_Config2__LineItem__c> listOfLIs = new List<Apttus_Config2__LineItem__c>();
               Apttus_Config2__LineItem__c liLineItem1 = new Apttus_Config2__LineItem__c(Id=liLineItems[0].id);
               liLineItem1.Apttus_Config2__AttributeValueId__c = newPAV.Id;
               liLineItem1.Apttus_Config2__AdjustmentType__c = 'Markup Amount';
               liLineItem1.Apttus_Config2__BasePriceOverride__c = 1;
               liLineItem1.Apttus_Config2__PricingStatus__c = APT_Constants.LABEL_LINE_STATUS;
               liLineItem1.APT_New__c = false;
               liLineItem1.APT_Amendment__c = true;
               listOfLIs.add(liLineItem1);
               
                Apttus_Config2__LineItem__c liLineItem2 = new Apttus_Config2__LineItem__c(Id=liLineItems[1].id);
               liLineItem2.Apttus_Config2__AttributeValueId__c = newPAV.Id;
               liLineItem2.Apttus_Config2__AdjustmentType__c = 'Markup Amount';
               liLineItem2.Apttus_Config2__BasePriceOverride__c = 1;
               liLineItem2.Apttus_Config2__IsPrimaryLine__c = true;
               liLineItem2.Apttus_Config2__PricingStatus__c = APT_Constants.LABEL_LINE_STATUS;
               liLineItem2.APT_New__c = false;
               liLineItem2.APT_Amendment__c = true;
               
               listOfLIs.add(liLineItem2);
               
               Apttus_Config2__LineItem__c liLineItem3 = new Apttus_Config2__LineItem__c(Id=liLineItems[2].id);
               liLineItem3.Apttus_Config2__AttributeValueId__c = newPAV.Id;
               liLineItem3.Apttus_Config2__AdjustmentType__c = 'Markup Amount';
               liLineItem3.Apttus_Config2__ParentBundleNumber__c = 1;
               liLineItem3.Apttus_Config2__PricingStatus__c = APT_Constants.LABEL_LINE_STATUS;
               liLineItem3.APT_New__c = false;
               liLineItem3.APT_Amendment__c = true;
               liLineItem3.Apttus_Config2__AdjustmentType__c = APT_Constants.OFFER_HIGHER_BAND;
               listOfLIs.add(liLineItem3);

               Apttus_Config2__LineItem__c liLineItem4 = new Apttus_Config2__LineItem__c(Id=liLineItems[3].id);
               liLineItem4.Apttus_Config2__AttributeValueId__c = newPAV1.Id;
               liLineItem4.Apttus_Config2__AdjustmentType__c = 'Markup Amount';
               liLineItem4.Apttus_Config2__ParentBundleNumber__c = 1;
               liLineItem4.Apttus_Config2__PricingStatus__c = APT_Constants.LABEL_LINE_STATUS;
               liLineItem4.APT_New__c = false;
               liLineItem4.APT_Amendment__c = true;
               listOfLIs.add(liLineItem4);
               
               Apttus_Config2__LineItem__c liLineItem5 = new Apttus_Config2__LineItem__c(Id=liLineItems[4].id);
               liLineItem5.Apttus_Config2__AttributeValueId__c = newPAV2.Id;
               liLineItem5.Apttus_Config2__AdjustmentType__c = 'Markup Amount';
               liLineItem5.Apttus_Config2__ParentBundleNumber__c = 1;
               liLineItem5.Apttus_Config2__PricingStatus__c = APT_Constants.LABEL_LINE_STATUS;
               liLineItem5.APT_New__c = false;
               liLineItem5.APT_Amendment__c = true;
               listOfLIs.add(liLineItem5);
               
               Apttus_Config2__LineItem__c liLineItem6 = new Apttus_Config2__LineItem__c(Id=liLineItems[5].id);
               liLineItem5.Apttus_Config2__AttributeValueId__c = newPAV3.Id;
               liLineItem5.Apttus_Config2__AdjustmentType__c = 'Markup Amount';
               liLineItem5.Apttus_Config2__ParentBundleNumber__c = 1;
               liLineItem5.Apttus_Config2__PricingStatus__c = APT_Constants.LABEL_LINE_STATUS;
               liLineItem5.APT_New__c = false;
               liLineItem5.APT_Amendment__c = true;
               listOfLIs.add(liLineItem6);
               
               
               update listOfLIs;
        }
    }
    

    
    @isTest
    public static void testLPDProduct(){
        Apttus_Config2__ProductConfiguration__c oProductConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c where Name  = 'Product Configuration 1'];
        
        Test.startTest();
        try{
            Apttus_CpqApi.CPQ.UpdatePriceRequestDO objUpdatePriceRequestDO = new Apttus_CpqApi.CPQ.UpdatePriceRequestDO();
            objUpdatePriceRequestDO.CartId = oProductConfig.Id;
            System.debug('prodconfig '+oProductConfig);
            Apttus_CpqApi.CPQ.UpdatePriceResponseDO result = Apttus_CpqApi.CPQWebService.updatePriceForCart(objUpdatePriceRequestDO);
            //System.debug(LoggingLevel.ERROR,'##### APTS_UnitTestMethod.repriceCart() objUpdatePriceResponseDO:' + result);
          
            //Apttus_Config2__LineItem__c oLineItem = [SELECT ID,Apttus_Config2__BasePriceOverride__c 
                                                    // FROM Apttus_Config2__LineItem__c 
                                                    // WHERE Apttus_Config2__ConfigurationId__c =:oProductConfig.Id];
            //System.assertEquals(oLineItem.Apttus_Config2__BasePriceOverride__c,17);
         }
         Catch(Exception e){
              System.debug('Error occured '+e.getMessage()+ e.getLineNumber()+e.getStackTraceString());
         }
        Test.stopTest();
    }   
    
     @isTest
    public static void testLPDProduct_1(){
        Apttus_Config2__ProductConfiguration__c oProductConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c where Name  = 'Product Configuration 1'];
        
        Test.startTest();
        try{
            Apttus_CpqApi.CPQ.UpdatePriceRequestDO objUpdatePriceRequestDO = new Apttus_CpqApi.CPQ.UpdatePriceRequestDO();
            objUpdatePriceRequestDO.CartId = oProductConfig.Id;
            System.debug('prodconfig '+oProductConfig);
            Apttus_CpqApi.CPQ.UpdatePriceResponseDO result = Apttus_CpqApi.CPQWebService.updatePriceForCart(objUpdatePriceRequestDO);
            //System.debug(LoggingLevel.ERROR,'##### APTS_UnitTestMethod.repriceCart() objUpdatePriceResponseDO:' + result);
          
            //Apttus_Config2__LineItem__c oLineItem = [SELECT ID,Apttus_Config2__BasePriceOverride__c 
                                                    // FROM Apttus_Config2__LineItem__c 
                                                    // WHERE Apttus_Config2__ConfigurationId__c =:oProductConfig.Id];
            //System.assertEquals(oLineItem.Apttus_Config2__BasePriceOverride__c,17);
         }
         Catch(Exception e){
              System.debug('Error occured '+e.getMessage()+ e.getLineNumber()+e.getStackTraceString());
         }
        Test.stopTest();
    }
    
    @isTest
    public static void testLPDProduct_2(){
        Apttus_Config2__ProductConfiguration__c oProductConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c where Name  = 'Product Configuration 2'];
        
        Test.startTest();
        try{
            Apttus_CpqApi.CPQ.UpdatePriceRequestDO objUpdatePriceRequestDO = new Apttus_CpqApi.CPQ.UpdatePriceRequestDO();
            objUpdatePriceRequestDO.CartId = oProductConfig.Id;
            System.debug('prodconfig '+oProductConfig);
            Apttus_CpqApi.CPQ.UpdatePriceResponseDO result = Apttus_CpqApi.CPQWebService.updatePriceForCart(objUpdatePriceRequestDO);
            //System.debug(LoggingLevel.ERROR,'##### APTS_UnitTestMethod.repriceCart() objUpdatePriceResponseDO:' + result);
          
            //Apttus_Config2__LineItem__c oLineItem = [SELECT ID,Apttus_Config2__BasePriceOverride__c 
                                                    // FROM Apttus_Config2__LineItem__c 
                                                    // WHERE Apttus_Config2__ConfigurationId__c =:oProductConfig.Id];
            //System.assertEquals(oLineItem.Apttus_Config2__BasePriceOverride__c,17);
         }
         Catch(Exception e){
              System.debug('Error occured '+e.getMessage()+ e.getLineNumber()+e.getStackTraceString());
         }
        Test.stopTest();
    }
    public static void testLPDProduct_3(){
        Apttus_Config2__ProductConfiguration__c oProductConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c where Name  = 'Product Configuration 3'];
        
        Test.startTest();
        try{
            Apttus_CpqApi.CPQ.UpdatePriceRequestDO objUpdatePriceRequestDO = new Apttus_CpqApi.CPQ.UpdatePriceRequestDO();
            objUpdatePriceRequestDO.CartId = oProductConfig.Id;
            System.debug('prodconfig '+oProductConfig);
            Apttus_CpqApi.CPQ.UpdatePriceResponseDO result = Apttus_CpqApi.CPQWebService.updatePriceForCart(objUpdatePriceRequestDO);
            //System.debug(LoggingLevel.ERROR,'##### APTS_UnitTestMethod.repriceCart() objUpdatePriceResponseDO:' + result);
          
            //Apttus_Config2__LineItem__c oLineItem = [SELECT ID,Apttus_Config2__BasePriceOverride__c 
                                                    // FROM Apttus_Config2__LineItem__c 
                                                    // WHERE Apttus_Config2__ConfigurationId__c =:oProductConfig.Id];
            //System.assertEquals(oLineItem.Apttus_Config2__BasePriceOverride__c,17);
         }
         Catch(Exception e){
              System.debug('Error occured '+e.getMessage()+ e.getLineNumber()+e.getStackTraceString());
         }
        Test.stopTest();
    }
    
    @isTest
    public static void testPostBillPayProduct(){
        List<Apttus_Config2__ProductConfiguration__c> oProductConfig = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c LIMIT 2];
        
        Test.startTest();
        try{
            Apttus_CpqApi.CPQ.UpdatePriceRequestDO objUpdatePriceRequestDO = new Apttus_CpqApi.CPQ.UpdatePriceRequestDO();
            objUpdatePriceRequestDO.CartId = oProductConfig[1].Id;
            System.debug('prodconfig '+oProductConfig);
            Apttus_CpqApi.CPQ.UpdatePriceResponseDO result = Apttus_CpqApi.CPQWebService.updatePriceForCart(objUpdatePriceRequestDO);
           // System.debug(LoggingLevel.ERROR,'##### APTS_UnitTestMethod.repriceCart() objUpdatePriceResponseDO:' + result);
         }
         Catch(Exception e){
              System.debug('Error occured '+e.getMessage()+ e.getLineNumber()+e.getStackTraceString());
         }
        Test.stopTest();
    }    
    
}