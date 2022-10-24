/**
* @author Nathan Franklin
* @date 2021-01-12
* @group Tests
* @tag Selector
* @tag Line Item SObject
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2021-05-12 - Shashwat.Nath@auspost.com.au - Created
* 2022-07-28 - Nasir Jawed - Added code for covering LineItem to provide correct record.
*/
@IsTest
public with sharing class LineItemsSelector_Test {
    /**
     * Test:
     *  Ensures that the selectors QueryBuilder is generating the correct output
     */
    @IsTest
    public static void testEnsureQueryBuilderProducesCorrectString() {

        // =====================================
        // Data Preparation
        // =====================================
        // None!

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        LineItemsSelector  selector = LineItemsSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{LineItemsSelector.Options.WITH_PRODUCT_ATTRIBUTE_VALUE});
        String soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Apttus_Config2__LineItem__c\\b').matcher(soql).find(), 'Resulting query does not select from Line Item');

        Test.stopTest();

    }

    /**
     * Test:
     *  Ensures that the selectors QueryBuilder is generating the correct output
     */
    @IsTest
    public static void testEnsureQueryBuilderProducesCorrectStringWithRelatedFields() {

        // =====================================
        // Data Preparation
        // =====================================
        // None!

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        LineItemsSelector selector = LineItemsSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{LineItemsSelector.Options.WITH_PRODUCT_ATTRIBUTE_VALUE});
        String soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?is)Apttus_Config2__AttributeValueId__r\\..*?\\bfrom Apttus_Config2__LineItem__c\\b').matcher(soql).find(), 'Resulting query does not select product Attribute fields');
        Test.stopTest();

    }
    /**
     * Executes a query to ensure it returns expected results with actual inserted data
     */
    @IsTest
    public static void testSelectorIntegration() {

        // =====================================
        // Data Preparation
        // =====================================
        MockUtility.disableTriggerExecution();

          Contact con = APT_TestUtils.createContact();
            con.MailingCity = 'Melbourne';
            con.MailingState = 'VIC';
            con.MailingStreet = 'Flinders Street';
            con.MailingPostalCode = '3000'; 
            insert con;
            
            //Creating account test data
            Account tempacct = APT_TestUtils.createOrganisation();
            insert tempacct;
            
            //Creating Opportunity Test Data
            Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
            insert opp;
            
            //Creating Pricelist test data
            Apttus_Config2__PriceList__c  priceList =APT_TestUtils.createPriceList();
            insert priceList;
            
            //Creating proposal test data
            Apttus_Proposal__Proposal__c quote = APT_TestUtils.getQuoteProposal(tempacct.id,opp.Id,'Proposal','Test',priceList.id);
            quote.Expected_Revenue_Start_Date__c = System.today() + 2;
            insert quote;
            
            //Inserting product test data
            Product2 bundle1 = APT_TestUtils.createInternationalProduct(APT_Constants.PRODUCT_NAME_EPARCEL,'APOST001','Postal Services');
            bundle1.Non_contracted__c = false;
            insert bundle1;
            
            //Inserting product test data 2
            Product2 bundle2 = APT_TestUtils.createInternationalProduct(APT_Constants.PRODUCT_NAME_EPARCEL,'APOST002','Postal Services');
            bundle2.APT_Sync_with_Opportunity__c = true;
            bundle2.Apttus_Config2__HasOptions__c = true;
            bundle2.Non_contracted__c = true;
            bundle2.Apttus_Config2__ConfigurationType__c = 'Bundle';
            insert bundle2;
            
            //Inserting product configuration test data
            Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtils.getProductConfiguration('Product Configuration', 1, 
            quote.Id, 'Proposal','Ad Hoc',priceList.Id, null,'Ready For Finalization',null, Datetime.now(), true);
            insert prodconfig;
            
            //Inserting PLI test data
            Apttus_Config2__PriceListItem__c pli= APT_TestUtils.createPriceListItem(priceList.ID,bundle1.ID,'C Manufacturing','BAND 2');
            insert pli;
            
            //Inserting Line Item test data
            Apttus_Config2__LineItem__c bundleLine = APT_TestUtils.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
            1, 'Product/Service', bundle2.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
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
            
        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        
        LineItemsSelector selector = LineItemsSelector.newInstance(1);
        Map<Id, Apttus_Config2__LineItem__c> results = selector.selectById(new Set<Id>{bundleLine.id});
        System.assertEquals(1, results.size(), 'Result count was wrong');

        results = selector.selectById(new Set<Id>{bundleLine.id}, new Set<Object>{LineItemsSelector.Options.WITH_PRODUCT_ATTRIBUTE_VALUE});
        System.assertEquals(1, results.size(), 'Result count was wrong');
        
        List<Apttus_Config2__LineItem__c> resultList = new List<Apttus_Config2__LineItem__c>();
        resultList = selector.selectByProdConfId(new set<ID>{(ID)prodConfig.id});
         System.assertEquals(1, results.size(), 'Result count was wrong');
        

        Test.stopTest();

    }
    
      /**
     * Test:
     *  Ensures that the selectors QueryBuilder is generating the correct output
     */
    @IsTest
    public static void testEnsureQueryBuilderProducesCorrectStringWithFieldOverrides() {

        // =====================================
        // Data Preparation
        // =====================================
        // None!

        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        LineItemsSelector  selector1 = LineItemsSelector.newInstance(0, new Set<SObjectField>{Apttus_Config2__LineItem__c.Name});

        LineItemsSelector  selector = LineItemsSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
                Apttus_Config2__LineItem__c.SObjectType => new Set<SObjectField>{Apttus_Config2__LineItem__c.Name}
        });
        QueryBuilder qb = selector.newQueryBuilder(new Set<Object>{LineItemsSelector.Options.WITH_PRODUCT_ATTRIBUTE_VALUE});
        String soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?ism)Name.*?\\bfrom Apttus_Config2__LineItem__c\\b').matcher(soql).find(), 'Resulting query does not select Name field: ' + soql);

        Test.stopTest();

    }
    
     /**
     * Test:
     *  Ensures that the selectors QueryBuilder is generating the correct output by using the Configuration id and getting
     * the correct output for Bundle Product/Service
     */
    
     @IsTest
    public static void testEnsureQueryBuilderProducesRecordWithConfigurationID() {
         // =====================================
        // Data Preparation
        // =====================================
        Account legacyacct = APT_TestUtils.createOrganisation();
        legacyacct.Legacy_Id__c = '60000000';
        legacyacct.Name = 'legacyacct';     
        insert legacyacct;    
        
        //Create Opportunity       
        Opportunity opp1 = APT_TestUtils.createOpportunity(legacyacct.id);     
        opp1.Is_Superseded_Opportunity__c = true;             
        insert opp1;
        
        Apttus_Config2__PriceList__c priceList = APT_TestUtils.createPriceList();
        insert priceList;
        
        Apttus_Proposal__Proposal__c proposal = APT_TestUtils.getQuoteProposal(legacyacct.id,opp1.Id,'Proposal','Test',priceList.id);
        insert proposal;        
        
        
        Apttus_Config2__ProductConfiguration__c prodConfig = APT_TestDataFactory.getAPTProductConfig(1, null, null, false)[0];
        prodConfig.Apttus_QPConfig__Proposald__c =proposal.id;
        prodConfig.Apttus_Config2__Status__c ='New';
        insert prodConfig;
        
        prodConfig.Apttus_Config2__Status__c ='Finalized';
        update prodConfig;
        
        product2 prod= new product2();
        prod.Name='Australia Post Parcel Contract';
        prod.ProductCode='APPC';
        prod.Family='APPC';
        prod.APT_Apttus_Product_Classification__c='APPC';
        prod.IsActive=true;
        prod.Apttus_Config2__ConfigurationType__c='Bundle';
        insert prod;
        
        Apttus_Config2__LineItem__c lineItem = APT_TestDataFactory.getAPTLineItem(1, null, null, false)[0];  
        lineItem.Apttus_Config2__LineType__c = 'Product/Service'; 
        lineItem.Apttus_Config2__ProductId__c= prod.id;
        lineItem.Apttus_Config2__Description__c='Australia Post Parcel Contract';
        lineItem.Apttus_Config2__ConfigurationId__c=prodConfig.id;
        insert lineItem;
        
        Test.startTest();
        //Getting the Line item record by passing the prod config id and checking the result
        LineItemsSelector  selector = LineItemsSelector.newInstance();
        List<Apttus_Config2__LineItem__c> LineItemRec=selector.selectByProdConfId(new set<ID>{(ID)prodConfig.id});
        System.assertEquals(1,LineItemRec.size(), 'Resulting query give lineitem record as 1');
        
        //Getting the Line item record by passing the prod config id and checking the result       
        List<Apttus_Config2__LineItem__c> LineItemProdService=selector.selectByProdConfigAndLineType(
            new set<ID>{(ID)prodConfig.id},
            new set<String>{'Product/Service'},
            new Set<Object>{LineItemsSelector.Options.WITH_PRODUCT_ATTRIBUTE_VALUE});
        System.assertEquals(1,LineItemProdService.size(), 'Resulting query give lineitem record as 1');  
        Test.stopTest();

    }
}