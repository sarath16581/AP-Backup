/**
Description: This apex class is the test class for the handler class: APT_LineItemTriggerHandler
Last Modified By: Seth Heang - seth.p.heang@accenture.com
Last Modified Date: 13/01/2020 | Add test class to cover APT_updateConfig method and OverWrite_LPD_NetPrice method
Last Modified By: Mathew Jose- mathew.joseg@auspost.com.au
Last Modified Date: 30/06/2021 | Added & Commented test methods to cover the new methods added / removed to the trigger handler. 
**/

@isTest
private class APT_LineItemTriggerHandlerTest {

    //Setting up the test data
    @TestSetup
    static void createData(){

            // Setup test data
            Contact con = APT_TestUtils.createContact();
            insert con;
            
            Account tempacct = APT_TestUtils.createOrganisation();
            insert tempacct;
            
            Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
            insert opp;
            
            Product2 product =APT_TestUtils.createDomesticProduct('Local Pickup and Delivery Services','LPDC','Others',null,null);
            product.APT_Product_type__c = 'Local Pickup and Delivery Services';
            insert product;
            
            Product2 product2 =APT_TestUtils.createDomesticProduct('International Digital PCMS Bundle incl Airmail Letters','LPDC','Others',null,null);
            product2.APT_Product_type__c = 'Local Pickup and Delivery Services';
            insert product2;
            
            Apttus_Config2__PriceList__c  priceList =APT_TestUtils.createPriceList();
            insert priceList;
            
            Id priceBookId=Test.getStandardPricebookId();
            PricebookEntry  priceBookEntry = APT_TestUtils.getPricebookEntry(priceBookId,product.Id);
            insert priceBookEntry;
            
            OpportunityLineItem oppLineItem = new OpportunityLineItem(Quantity=2,OpportunityId=opp.Id,TotalPrice =45678,PricebookEntryId=priceBookEntry.Id,Contract_Start_Date__c=System.Today(),Contract_End_Date__c=System.Today()+1 );
            oppLineItem.Classification__c = 'New Business'; 
            insert oppLineItem;

            Id amendmentRecordTypeId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get('Amendment Quote').getRecordTypeId();
            system.debug('amendmentRecordTypeId+' + amendmentRecordTypeId);   

            Apttus_Proposal__Proposal__c quote = APT_TestUtils.getQuoteProposal(tempacct.id,opp.Id,'Proposal','Test',priceList.id);
            quote.Expected_Revenue_Start_Date__c = System.today() + 2;
            quote.recordTypeId = amendmentRecordTypeId;
            insert quote;
            
            APT_R2T_System_Properties__c sysProperties = new APT_R2T_System_Properties__c(APT_Default_Price_List_ID__c=priceList.id);
            insert sysProperties;
            

            
            // Setup generic product configuration
            Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtil2.getProductConfiguration('Product Configuration', 1,
                                                                                                    quote.Id, 'Proposal','Ad Hoc',
                                                                                                    priceList.Id, null,'New',null,
                                                                                                    Datetime.now(), true);
            
            insert prodconfig;
            
            Apttus_Config2__PriceListItem__c pli2 = APT_TestUtil2.createPriceListItem(priceList.ID,product.ID,'C Manufacturing','BAND 2');
            insert pli2;
            
            // Local Pickup Configuration Line Item
            Apttus_Config2__LineItem__c localPickupCLI = APT_TestUtil2.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
                                                                                        1, 'Product/Service', product.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
                                                                                        null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable
                                                                                        'Each', 1, priceList.Id, pli2.Id,//Uom, term, priceList, Pli,
                                                                                        'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
                                                                                        true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod,
                                                                                        5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc

            
            localPickupCLI.Apttus_Config2__AdjustmentType__c = '';
            localPickupCLI.Apttus_Config2__AdjustmentAmount__c = 100;
            localPickupCLI.APT_Rate_Card_Key__c = 'abcd';
            insert localPickupCLI;

            // International Bundle Configuration Line Item
            Apttus_Config2__LineItem__c internationalBundleCLI = APT_TestUtil2.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
                                                                                                1, 'Product/Service', product2.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
                                                                                                null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable
                                                                                                'Each', 1, priceList.Id, pli2.Id,//Uom, term, priceList, Pli,
                                                                                                'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
                                                                                                true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod,
                                                                                                5225, 0, 5225, 'TestaPTTUSINT');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            
            internationalBundleCLI.Apttus_Config2__AddedBy__c='Constraint Rule'; 
            internationalBundleCLI.Apttus_Config2__ConstraintCheckStatus__c='Auto Added';
            insert internationalBundleCLI;
        


    }       

    //Method to test the rate card key update
    @IsTest
    public static void rateCardKeyUpdateTest(){

        Apttus_Config2__LineItem__c localPickupCLI = [SELECT APT_Rate_Card_Key__c, Apttus_Config2__AdjustmentType__c, Apttus_Config2__AdjustmentAmount__c, APT_New__c
                                                        FROM Apttus_Config2__LineItem__c 
                                                        WHERE Apttus_Config2__Description__c = 'TestaPTTUS' Limit 1];
        test.StartTest();
        localPickupCLI.APT_Rate_Card_Key__c = 'bcdef'; 
        update localPickupCLI;
        test.stopTest();
        System.AssertEquals([SELECT APT_New__c FROM Apttus_Config2__LineItem__c WHERE Apttus_Config2__Description__c = 'TestaPTTUS' Limit 1].APT_New__c, true);                                               
    }
    //Method to test the price change

    @IsTest
    public static void priceChangeTest(){

        Apttus_Config2__LineItem__c localPickupCLI = [SELECT APT_Rate_Card_Key__c, Apttus_Config2__AdjustmentType__c, Apttus_Config2__AdjustmentAmount__c, APT_New__c,
                                                        Apttus_Config2__ConfigurationId__r.APT_Created_On__c,APT_New_Amend__c
                                                        FROM Apttus_Config2__LineItem__c 
                                                        WHERE Apttus_Config2__Description__c = 'TestaPTTUS' Limit 1];
        System.debug('Created On::'+localPickupCLI.Apttus_Config2__ConfigurationId__r.APT_Created_On__c);
        System.debug('New Amend::'+localPickupCLI.APT_New_Amend__c);                                                  
        test.StartTest();
        localPickupCLI.Apttus_Config2__AdjustmentAmount__c = 200; 
        localPickupCLI.APT_New_Amend__c = false;
        update localPickupCLI;
        test.stopTest();
        System.AssertEquals([SELECT APT_Is_Band_Changed__c FROM Apttus_Config2__LineItem__c WHERE Apttus_Config2__Description__c = 'TestaPTTUS' Limit 1].APT_Is_Band_Changed__c, true);                                               
    }

     //Method to test the line item deletion as part of the APT_updateConfig method
    @IsTest
	public static void APT_updateConfigTest(){
        Apttus_Config2__LineItem__c internationalBundleCLI = [SELECT APT_Rate_Card_Key__c, Apttus_Config2__AdjustmentType__c, Apttus_Config2__AdjustmentAmount__c, APT_New__c
                                                        FROM Apttus_Config2__LineItem__c 
                                                        WHERE Apttus_Config2__Description__c = 'TestaPTTUSINT' Limit 1];
        test.StartTest();  
        delete internationalBundleCLI;
        test.StopTest();
        System.AssertEquals([SELECT Count() FROM Task WHERE Subject like 'An auto added International PCMS%' and Status='Completed'],1);                                                                                              

    }

    // Commenting the below test method as the overWriteNetPriceLPD method was moved from trigger to the pricing callback.

    /*public static testMethod void testOverWriteNetPriceLPD(){

        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {
            // Setup test data
            Contact con = APT_TestUtils.createContact();
            insert con;
            
            Account tempacct = APT_TestUtils.createOrganisation();
            insert tempacct;
            
            Opportunity opp = APT_TestUtils.createOpportunity(tempacct.id);
            insert opp;
            
            Product2 product =APT_TestUtils.createDomesticProduct('Local Pickup and Delivery Services','LPDC','Others',null,null);
            product.APT_Product_type__c = 'Local Pickup and Delivery Services';
            insert product;
            
            Product2 product2 =APT_TestUtils.createDomesticProduct('International Digital PCMS Bundle incl Airmail Letters','LPDC','Others',null,null);
            product2.APT_Product_type__c = 'Local Pickup and Delivery Services';
            insert product2;
            
            Apttus_Config2__PriceList__c  priceList =APT_TestUtils.createPriceList();
            insert priceList;
            
            Id priceBookId=Test.getStandardPricebookId();
            PricebookEntry  priceBookEntry = APT_TestUtils.getPricebookEntry(priceBookId,product.Id);
            insert priceBookEntry;
            
            OpportunityLineItem oppLineItem = new OpportunityLineItem(Quantity=2,OpportunityId=opp.Id,TotalPrice =45678,PricebookEntryId=priceBookEntry.Id,Contract_Start_Date__c=System.Today(),Contract_End_Date__c=System.Today()+1 );
            oppLineItem.Classification__c = 'New Business'; 
            insert oppLineItem;
            
            Apttus_Proposal__Proposal__c quote = APT_TestUtils.getQuoteProposal(tempacct.id,opp.Id,'Proposal','Test',priceList.id);
            quote.Expected_Revenue_Start_Date__c = System.today() + 2;
            insert quote;
            
            APT_R2T_System_Properties__c sysProperties = new APT_R2T_System_Properties__c(APT_Default_Price_List_ID__c=priceList.id);
            insert sysProperties;
            
            Id renewalRecordTypeId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get('Renewal Quote').getRecordTypeId();
            system.debug('renewalRecordTypeId+' + renewalRecordTypeId);
            
            // Setup agreement object
            Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
            aptContract.Apttus__Related_Opportunity__c =opp.id;
            aptContract.Apttus_QPComply__RelatedProposalId__c =quote.id;
            aptContract.Apttus__Contract_End_Date__c = System.today() + 360;
            insert aptContract;
            
            // Setup generic product configuration
            Apttus_Config2__ProductConfiguration__c prodconfig = APT_TestUtil2.getProductConfiguration('Product Configuration', 1,
                                                                                                    quote.Id, 'Proposal','Ad Hoc',
                                                                                                    priceList.Id, null,'New',null,
                                                                                                    Datetime.now(), true);
            
            insert prodconfig;
            
            Apttus_Config2__PriceListItem__c pli2 = APT_TestUtil2.createPriceListItem(priceList.ID,product.ID,'C Manufacturing','BAND 2');
            insert pli2;
            
            // Local Pickup Configuration Line Item
            Apttus_Config2__LineItem__c localPickupCLI = APT_TestUtil2.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
                                                                                        1, 'Product/Service', product.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
                                                                                        null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable
                                                                                        'Each', 1, priceList.Id, pli2.Id,//Uom, term, priceList, Pli,
                                                                                        'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
                                                                                        true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod,
                                                                                        5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            // International Bundle Configuration Line Item
            Apttus_Config2__LineItem__c internationalBundleCLI = APT_TestUtil2.getConfigLineItem(prodconfig.Id, null, 1, true,//Config Id, grpId, LineNum, isPrimary
                                                                                                1, 'Product/Service', product2.Id, true, null,//ItemSeq, lineType, bundleId, customizable, productOptionId
                                                                                                null, null, null, 1, true,//optionId, class Id, class hierarchy, qty, qty Modifiable
                                                                                                'Each', 1, priceList.Id, pli2.Id,//Uom, term, priceList, Pli,
                                                                                                'One Time', 'Per Unit', 'Standard Price', 'One Time',//priceType, priceMethod, chargeType, frequency
                                                                                                true, true, 5500, 5500, 'Per Unit',//allowManualAdj, allocateGroupAdj, listPrice, basePrice, basePriceMethod,
                                                                                                5225, 0, 5225, 'TestaPTTUS');//baseExtPrice, optionPrice, extendedPrice, lineDesc
            
            localPickupCLI.Apttus_Config2__AdjustmentType__c = '';
            internationalBundleCLI.Apttus_Config2__AddedBy__c='Constraint Rule'; 
            internationalBundleCLI.Apttus_Config2__ConstraintCheckStatus__c='Auto Added';
            Test.startTest();
            insert localPickupCLI;
            insert internationalBundleCLI;
            Apttus_Config2__ProductAttributeValue__c newPAV = new Apttus_Config2__ProductAttributeValue__c();
            // Setup Product pricing details or product attribute value for 'Local Pickup and Delivery Services' Product
            newPAV.APT_LPD_Distance_Facility_Provided_In_Km__c = 17;
            newPAV.APT_LPD_Multiple_Frequency__c = 'Ad hoc';
            newPAV.APT_LPD_Service_Type__c = 'Delivery Service';
            newPAV.Apttus_Config2__LineItemId__c = localPickupCLI.id;
            insert newPAV;
            
            // Query Total Service Fee formula field 
            double totalFee = [Select APT_LPD_Total_Service_Fee__c from Apttus_Config2__ProductAttributeValue__c where id =: newPAV.id].APT_LPD_Total_Service_Fee__c;
            
            // simulate the apttus pricing feature that update NetPrice field upon click 'Validate' button in apttus cart
            localPickupCLI.Apttus_Config2__NetPrice__c = 0;
            update localPickupCLI;
            
            // Query the latest Apttus NetPrice field of the product
            double netPrice = [Select Apttus_Config2__NetPrice__c from Apttus_Config2__LineItem__c where id =: localPickupCLI.id].Apttus_Config2__NetPrice__c;
            delete internationalBundleCLI;
            Test.stopTest();
            
            // Check that Total Service Fee is equal to NetPrice, due to trigger overwriting NetPrice's value with Total Service Fee's value
            System.assertEquals(totalFee,netPrice);

        }
    }*/
}