/**
 * @changelog
 * 2017-03-07 - Adrian A - Test class for disputeditemtriggerhandler
 * 2021-06-18 - Ranjeewa Silva - Added new test methods on recalculating product sub category on after update.
 */
@isTest
private class DisputedItemTriggerHandlerTest{
    
    /* Test Method for Disputed Item Trigger Handler Class */
    public static testMethod void testDisputeItemTriggerHandler(){
        try{
            // Create Test Case
            Case cs = I2CTestDataBuilder.createCase();
            insert cs;
    
            // Create Test Disputed Items without existing CA
            List<Disputed_Item__c> diListWithoutCA = I2CTestDataBuilder.createDisputeItem(cs);
    
            // Create Test Disputed Items with existing CA
            List<Disputed_Item__c> diListwithCA = I2CTestDataBuilder.createDisputeItem(cs);
    
            Test.startTest();
                insert diListWithoutCA; // populateCreditApproval
    
                Map<Id, Disputed_Item__c> diWithoutCAMap = new Map<Id, Disputed_Item__c>(); 
                diWithoutCAMap.putAll(diListWithoutCA);
    
                List<Credit_Approval__c> caList = [Select Id ,(Select Id from Disputed_Items__r) from Credit_Approval__c];
    
                for(Credit_Approval__c caVar: caList){
                    for(Disputed_Item__c diVar: caVar.Disputed_Items__r){
                        system.assertEquals(true, diWithoutCAMap.containsKey(diVar.Id));
                    }
                }
    
                insert diListwithCA; // disputeCAConnect // mapCA
    
                Map<Id, Disputed_Item__c> diCAMapCombined = new Map<Id, Disputed_Item__c>(); 
                diCAMapCombined.putAll(diListWithoutCA);
                diCAMapCombined.putAll(diListwithCA);
    
                //caList = [Select Id ,(Select Id from Disputed_Items__r) from Credit_Approval__c];
    
                for(Credit_Approval__c caVar: caList){
                    for(Disputed_Item__c diVar: caVar.Disputed_Items__r){
                        system.assertEquals(true, diCAMapCombined.containsKey(diVar.Id));
                    }
                }
    
                for(Disputed_Item__c diVar: diListWithoutCA){
                    diVar.Product__c = 'Road';
                }
    
                for(Disputed_Item__c diVar: diListwithCA){
                    diVar.Product__c = 'Road';
                }
    
                update diListWithoutCA;
                update diListwithCA; // deletebyParentCAUpdate // recalculateCATotalsbyPFUpdate
    
                List<Credit_Approval__c> caNewList = [Select Id , Product_Family__c, (Select Id from Disputed_Items__r) from Credit_Approval__c];
    
                //system.assertEquals(1, caNewList.size());
    
                Id existId;
    
                for(Credit_Approval__c caVar: caNewList){
                    existId = caVar.Id;
                    system.assertEquals('Road', caVar.Product_Family__c);
                    system.assertEquals(10, caVar.Disputed_Items__r.size());
                }
    
                delete diListWithoutCA;
                delete diListwithCA; // deleteParentCA
    
                List<Credit_Approval__c> noCAList = [Select Id from Credit_Approval__c where Id = :existId];            
                Test.stopTest();
                system.assertEquals(0, noCAList.size());
        }catch(Exception e){
            e.getStackTraceString();    
        }
    }

    @IsTest
    private static void testRecalculateCreditApprovalProductSubCategoryOnUpdatingStatusToVerifiedClaim() {
        List<Case> cases = ApplicationTestDataFactory.getCases(1, false);
        Id creditDisputeCaseRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('Case', new Set<String>{'Enterprise_Credit_Dispute_Claim'}).values()[0].Id;
        cases[0].RecordTypeId = creditDisputeCaseRecordTypeId;
        insert(cases);


        Id disputedItemRecordTypeId_SAP = RecordTypesSelector.newInstance().selectByDeveloperName('Disputed_Item__c', new Set<String>{'SAP_ERP'}).values()[0].Id;
        List<Disputed_Item__c> disputedItems = ApplicationTestDataFactory.getDisputedItems(5, cases[0].Id,false);
        for (Disputed_Item__c disputedItem: disputedItems) {
            disputedItem.RecordTypeId = disputedItemRecordTypeId_SAP;
            disputedItem.Status__c = 'New';
        }

        insert(disputedItems);

        Test.startTest();

        // disputedItems[0] - Product = 'Letters', Product Sub Category = 'Presort Letters', Type__c = 'Discretionary Credit'
        populateFieldsRequiredForVerification(disputedItems[0], 'Discretionary Credit','Letters', 'Presort Letters', 100);
        // disputedItems[1] - Product = 'Parcels', Product Sub Category = 'Local marketplaces', Type__c = 'Discretionary Credit'
        populateFieldsRequiredForVerification(disputedItems[1], 'Discretionary Credit', 'Parcels', 'Local marketplaces',200);
        // disputedItems[2] - Product = 'Parcels', Product Sub Category = 'Local marketplaces', Type__c = 'Non-Discretionary'
        populateFieldsRequiredForVerification(disputedItems[2], 'Non-Discretionary', 'Parcels', 'Local marketplaces', 1250);
        // disputedItems[3] - Product = 'Parcels', Product Sub Category = '3PL', Type__c = 'Non-Discretionary'
        populateFieldsRequiredForVerification(disputedItems[3], 'Non-Discretionary', 'Parcels', '3PL', 1200);
        // disputedItems[4] - Product = 'Parcels', Product Sub Category = '3PL', Type__c = 'Non-Discretionary'
        populateFieldsRequiredForVerification(disputedItems[4], 'Non-Discretionary', 'Parcels', '3PL', 100);

        disputedItems[0].Status__c = 'Verified Claim';
        disputedItems[1].Status__c = 'Verified Claim';
        disputedItems[2].Status__c = 'Verified Claim';
        disputedItems[3].Status__c = 'Verified Claim';
        update(disputedItems);

        Test.stopTest();

        Map<Id, Disputed_Item__c> updatedRecords = new Map<Id, Disputed_Item__c>([Select Id, Credit_Approval__c, Credit_Approval__r.Product_Sub_Category__c From Disputed_Item__c Where Case__c = :cases[0].Id]);

        // verify parent credit approval records are updated accordingly
        System.assertEquals(disputedItems[0].Product_Sub_Category__c,updatedRecords.get(disputedItems[0].Id).Credit_Approval__r.Product_Sub_Category__c, 'Expected the parent credit approval to have the same product sub category as the disputed item');
        System.assertEquals(disputedItems[1].Product_Sub_Category__c,updatedRecords.get(disputedItems[1].Id).Credit_Approval__r.Product_Sub_Category__c, 'Expected the parent credit approval to have the same product sub category as the disputed item');
        // disputedItems[2], disputedItems[3] and disputedItems[4] should be linked to the same credit approval. Product Sub Category should be
        // set to the Product Sub Category with the highest aggregate credit amount. i.e. '3PL' as aggregated credit amount is 1300.
        System.assert(updatedRecords.get(disputedItems[2].Id).Credit_Approval__c == updatedRecords.get(disputedItems[3].Id).Credit_Approval__c, 'Expected only one credit approval record to be created, but got more.');
        System.assert(updatedRecords.get(disputedItems[2].Id).Credit_Approval__c == updatedRecords.get(disputedItems[4].Id).Credit_Approval__c, 'Expected only one credit approval record to be created, but got more.');
        System.assertEquals(disputedItems[3].Product_Sub_Category__c,updatedRecords.get(disputedItems[2].Id).Credit_Approval__r.Product_Sub_Category__c, 'Expected the parent credit approval to have the product sub category with the higher proposed credit');
        System.assertEquals(disputedItems[3].Product_Sub_Category__c,updatedRecords.get(disputedItems[3].Id).Credit_Approval__r.Product_Sub_Category__c, 'Expected the parent credit approval to have the product sub category with the higher proposed credit');
        System.assertEquals(disputedItems[3].Product_Sub_Category__c,updatedRecords.get(disputedItems[4].Id).Credit_Approval__r.Product_Sub_Category__c, 'Expected the parent credit approval to have the product sub category with the higher proposed credit');
    }

    @IsTest
    private static void testRecalculateCreditApprovalProductSubCategoryOnUpdatingAttributesOnVerifiedClaims() {
        List<Case> cases = ApplicationTestDataFactory.getCases(1, false);
        Id creditDisputeCaseRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('Case', new Set<String>{'Enterprise_Credit_Dispute_Claim'}).values()[0].Id;
        cases[0].RecordTypeId = creditDisputeCaseRecordTypeId;
        insert(cases);


        Id disputedItemRecordTypeId_SAP = RecordTypesSelector.newInstance().selectByDeveloperName('Disputed_Item__c', new Set<String>{'SAP_ERP'}).values()[0].Id;
        List<Disputed_Item__c> disputedItems = ApplicationTestDataFactory.getDisputedItems(5, cases[0].Id,false);
        for (Disputed_Item__c disputedItem: disputedItems) {
            disputedItem.RecordTypeId = disputedItemRecordTypeId_SAP;
            disputedItem.Status__c = 'New';
        }

        insert(disputedItems);

        // disputedItems[0] - Product = 'Letters', Product Sub Category = 'Presort Letters', Type__c = 'Discretionary Credit'
        populateFieldsRequiredForVerification(disputedItems[0], 'Discretionary Credit','Letters', 'Presort Letters', 100);
        // disputedItems[1] - Product = 'Parcels', Product Sub Category = 'Local marketplaces', Type__c = 'Non-Discretionary'
        populateFieldsRequiredForVerification(disputedItems[1], 'Non-Discretionary', 'Parcels', 'Local marketplaces', 1250);
        // disputedItems[2] - Product = 'Parcels', Product Sub Category = '3PL', Type__c = 'Non-Discretionary'
        populateFieldsRequiredForVerification(disputedItems[2], 'Non-Discretionary', 'Parcels', '3PL', 1200);
        // disputedItems[3] - Product = 'Parcels', Product Sub Category = '3PL', Type__c = 'Discretionary Credit'
        populateFieldsRequiredForVerification(disputedItems[3], 'Non-Discretionary', 'Letters', 'Presort Letters', 150);
        // disputedItems[4] - Product = 'Parcels', Product Sub Category = '3PL', Type__c = 'Discretionary Credit'
        populateFieldsRequiredForVerification(disputedItems[4], 'Non-Discretionary', 'Letters', 'Presort Letters', 100);


        disputedItems[0].Status__c = 'Verified Claim';
        disputedItems[1].Status__c = 'Verified Claim';
        disputedItems[2].Status__c = 'Verified Claim';
        disputedItems[3].Status__c = 'Verified Claim';
        disputedItems[4].Status__c = 'Verified Claim';
        update(disputedItems);

        Test.startTest();

        // update product sub category of disputedItems[0] => should result in updating product sub category of the credit approval
        disputedItems[0].Product_Sub_Category__c = 'Direct Entry Letters';

        // update Proposed Credit of disputedItems[1] => should result in updating product sub category of the credit approval to disputedItems[2].Product_Sub_Category__c
        disputedItems[1].Proposed_Credit__c = 1100;

        // update Product and Product Sub Category on disputedItem[3] = > Should update the product category on credit approval
        disputedItems[3].Product__c = 'Business Credit Account Facilities';
        disputedItems[3].Product_Sub_Category__c = 'Late Payment Charge';

        update(disputedItems);

        Test.stopTest();

        Map<Id, Disputed_Item__c> updatedRecords = new Map<Id, Disputed_Item__c>([Select Id, Credit_Approval__c, Credit_Approval__r.Product_Sub_Category__c From Disputed_Item__c Where Case__c = :cases[0].Id]);

        // verify parent credit approval records are updated accordingly
        System.assertEquals(disputedItems[0].Product_Sub_Category__c,updatedRecords.get(disputedItems[0].Id).Credit_Approval__r.Product_Sub_Category__c, 'Expected the parent credit approval to have the same product sub category as the disputed item');
        // disputedItems[1] and disputedItems[2] should be linked to the same credit approval. Product Sub Category should be
        // updated to the Product Sub Category with the highest aggregate credit amount. i.e. '3PL' as aggregated credit amount is 1200.
        //System.assertEquals(disputedItems[2].Product_Sub_Category__c,updatedRecords.get(disputedItems[1].Id).Credit_Approval__r.Product_Sub_Category__c, 'Expected the parent credit approval to have the product sub category with the higher proposed credit');
        //System.assertEquals(disputedItems[2].Product_Sub_Category__c,updatedRecords.get(disputedItems[2].Id).Credit_Approval__r.Product_Sub_Category__c, 'Expected the parent credit approval to have the product sub category with the higher proposed credit');

        // disputedItems[3] and disputedItems[4] were previously linked to the same credit approval. With the update to the Product Family
        // on disputedItem[3] - it should now:
        //  - link disputedItem[3] to a new credit approval and set Product Sub Category from disputedItem[3]
        //  - update Product Subcategory of the previous credit approval (now only linked to disputedItem[4]) and set Product Sub Category from disputedItem[4]
        System.assertEquals(disputedItems[3].Product_Sub_Category__c,updatedRecords.get(disputedItems[3].Id).Credit_Approval__r.Product_Sub_Category__c, 'Expected the parent credit approval to have the same product sub category as the disputed item');
        System.assertEquals(disputedItems[4].Product_Sub_Category__c,updatedRecords.get(disputedItems[4].Id).Credit_Approval__r.Product_Sub_Category__c, 'Expected the parent credit approval to have the same product sub category as the disputed item');
    }

    private static void populateFieldsRequiredForVerification(Disputed_Item__c disputedItem, String creditType, String productFamily, String productSubCategory, Decimal proposedCredit) {
        disputedItem.Product__c = productFamily;
        disputedItem.Product_Sub_Category__c = productSubCategory;
        disputedItem.Type__c = creditType;
        disputedItem.AP_Profit_Centre_Code__c = 'test';
        disputedItem.Product_Code__c = 'test';
        disputedItem.Resolution_Code__c = 'test';
        disputedItem.Reason_Category__c = 'Accounting adjustment';
        disputedItem.Reason__c = 'Customer Account Transfer';
        disputedItem.Proposed_Credit__c = 100;
        disputedItem.Product_Desciption__c = 'Test Parcels Dispute';
        disputedItem.Disputed_Reason__c = 'Duplicate Billing';
        disputedItem.Service_Date__c = Date.newInstance(2017, 02, 09);
    }
}