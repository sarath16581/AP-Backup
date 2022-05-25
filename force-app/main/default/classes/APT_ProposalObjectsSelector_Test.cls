/* @author Pradeep Jaiswal
* @date 2022-04-26
* @group Selector
* @tag Selector
* @tag Apttus_Proposal__Proposal__c
* @domain Apttus
* @description APT_ProposalObjectsSelector_Test to validate createdDate
*/

@IsTest
public class APT_ProposalObjectsSelector_Test {
    
     //Test setupdata;
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
        
     
    }
    
    /**
* Test:
*  Ensures that the selectors method is returning the correct query result
*/
    @IsTest
    private static void testEnsureSelectorMethodsReturnCorrectResult() {
        
        // =====================================
        // Data Preparation
        // =====================================
        MockUtility.disableTriggerExecution();
        
        Contact con = [Select Id from Contact Limit 1];
        Account legacyacct = [Select Id from Account where Name = 'legacyacct' Limit 1];
        
        Opportunity opp1 = [Select Id, AccountId from Opportunity where AccountId = :legacyacct.Id Limit 1];
        Application__c app = new Application__c();
        app.Opportunity__c = opp1.Id;
        
       // Billing_Account__c billacc = [Select Id, Organisation__c from Billing_Account__c where Organisation__c =:legacyacct.Id Limit 1];
        Product2 product = [Select Id from Product2 where Name = 'Australia Post Parcel Contract' Limit 1];
        Product2 product2 = [Select Id from Product2 where Name = 'International Bundle' Limit 1];

        User u1 = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name ='System Administrator' and ID != :UserInfo.getUserId()  limit 1];
        Apttus_Proposal__Proposal__c proposal = [Select Id, CreatedDate from Apttus_Proposal__Proposal__c where Apttus_Proposal__Account__c =:legacyacct.Id Limit 1];
        proposal.Apttus_QPApprov__Approval_Status__c = APT_Constants.APPROVAL_STAGE_APPROVED;
      
        Test.startTest();
              
        APT_ProposalObjectsSelector selector = APT_ProposalObjectsSelector.newInstance(1);
        Map<Id, Apttus_Proposal__Proposal__c> results = selector.selectByConfigId(new Set<id>{proposal.Id});
        System.assertEquals(1, results.size(), 'Expected result size of 1');
        
        Test.stopTest();
        
    }
    @IsTest
    private static void testEnsureSelectorMethodsReturnCorrectResult2() {
        
        Test.startTest();
              
        APT_ProposalObjectsSelector selector = APT_ProposalObjectsSelector.newInstance();
        
        Test.stopTest();
        
    }
    
}