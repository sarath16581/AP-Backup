/**
* @author Nathan Franklin
* @date 2021-01-12
* @group Tests
* @tag Selector
* @tag Product Attribute Value SObject
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2021-05-12 - Shashwat.Nath@auspost.com.au - Created
*/
@IsTest
public with sharing class ProductAttributeValueSelector_Test{
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

        ProductAttributeValueSelector  selector = ProductAttributeValueSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Apttus_Config2__ProductAttributeValue__c\\b').matcher(soql).find(), 'Resulting query does not select from Product Attribute Value Object');

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
            
            Apttus_Config2__ProductAttributeValue__c prodAtt = new Apttus_Config2__ProductAttributeValue__c();
            prodAtt.Apttus_Config2__LineItemId__c = bundleLine.id;
            insert prodAtt;
               
        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        
        ProductAttributeValueSelector selector = ProductAttributeValueSelector.newInstance(1);
        Map<Id, Apttus_Config2__ProductAttributeValue__c > results = selector.selectById(new Set<Id>{prodAtt.id});
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
        ProductAttributeValueSelector selector1 = ProductAttributeValueSelector.newInstance(0, new Set<SObjectField>{Apttus_Config2__ProductAttributeValue__c.APT_StarTrack_Service_Type__c});

        ProductAttributeValueSelector selector = ProductAttributeValueSelector.newInstance(0, new Map<SObjectType, Set<SObjectField>>{
                Apttus_Config2__ProductAttributeValue__c.SObjectType => new Set<SObjectField>{Apttus_Config2__ProductAttributeValue__c.APT_StarTrack_Service_Type__c}
        });
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();
        System.assertEquals(true, Pattern.compile('(?ism)APT_StarTrack_Service_Type__c.*?\\bfrom Apttus_Config2__ProductAttributeValue__c\\b').matcher(soql).find(), 'Resulting query does not select payload field: ' + soql);

        Test.stopTest();

    }
}