/**
* @author Seth Heang
* @date 2021-05-12
* @group Tests
* @tag Selector
* @tag APT_Sub_Account__c SObject
* @domain Core
* @description A very simple selector class that sits in the base domain
* @changelog
* 2020-12-18 - Seth Heang - Created
*/
@IsTest
private with sharing class SubAccountRequestsSelector_Test {

    /**
     * Test:
     *  Ensures that the selectors QueryBuilder is generating the correct output
     */
    @IsTest
    private static void testEnsureQueryBuilderProducesCorrectString() {

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

        SubAccountRequestsSelector selector = SubAccountRequestsSelector.newInstance();
        QueryBuilder qb = selector.newQueryBuilder();
        String soql = qb.toSoqlString();

        System.assertEquals(true, Pattern.compile('(?is)\\bfrom APT_Sub_Account__c\\b').matcher(soql).find(), 'Resulting query does not select from opportunity product classification');

        Test.stopTest();

    }
    
    /**
     * Test:
     *  Ensures that the selectors QueryBuilder is generating the correct output
     */
    @IsTest
    private static void testEnsureQueryBuilderProducesCorrectStringWithRelatedFields() {

        // =====================================
        // Data Preparation
        // =====================================
        MockUtility.disableTriggerExecution();

        //Id recTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('SSSWRouting__c', new Set<String>{'Credit_DSR_Routing'}).values()[0].Id;
        //SSSWRouting__c ssswCreditDSR = ApplicationTestDataFactory.getSSSWRoutings(1, recTypeId, 'M12', 'seth@test.com', 'Legal Recovery Team', 'Credit Person Code', false)[0];
        //insert ssswCreditDSR;
        
        
        APT_Charge_Account__c chargeAccountRequest = ApplicationTestDataFactory.getApttusChargeAccountRequest(1,false)[0];
        insert chargeAccountRequest;
        
        APT_Sub_Account__c subAccountRequest = ApplicationTestDataFactory.getSubAccountRequest(1,'Test1',false)[0];
        subAccountRequest.Lodgement_Point_to_Work_Centre_Code__c = 'Melbourne:123456:3336';
        subAccountRequest.Is_Parcel_Send_Login_Required__c = 'No';
        subAccountRequest.APT_eLMS_Enabled__c = 'Yes';
        subAccountRequest.APT_eParcel_Enabled__c = 'Yes';
        //subAccountRequest.SubAccountContact__c = contact.id;
		subAccountRequest.APT_Postal_Address_Street_Name__c = '123 Test St';
        subAccountRequest.APT_Postal_Address_Suburb__c = 'Melbourne';
		subAccountRequest.APT_Postal_Address_State__c = 'VIC';
        subAccountRequest.APT_Postal_Address_Street_Postcode__c = '3000';
        subAccountRequest.Name = 'Seth 1';
        subAccountRequest.APT_Account_Name_2__c = 'Seth Trading Name';
        subAccountRequest.APT_Charge_Account__c = chargeAccountRequest.Id;
        subAccountRequest.APT_Sub_Account_Request_Status__c = 'Pending Charge Account';
        insert subAccountRequest;
        
        // =====================================
        // Stubbing
        // =====================================
        // None!

        // =====================================
        // Testing
        // =====================================
        Test.startTest();
		
        SubAccountRequestsSelector selector = SubAccountRequestsSelector.newInstance(1);
        
        
        Map<Id, APT_Sub_Account__c> resultsBySARID = selector.selectById(new Set<id>{subAccountRequest.Id});
        System.assertEquals(1, resultsBySARID.size(), 'Expected result size of 1');
        Map<Id, APT_Sub_Account__c> resultsByCARID = selector.selectByChargeAcountRequestIdAndStatus(new Set<id>{chargeAccountRequest.Id},new Set<String>{'Pending Charge Account'});
        //Map<Id, SSSWRouting__c> results = selector.selectByRecordTypeId(new Set<id>{recTypeId});
        System.assertEquals(1, resultsByCARID.size(), 'Expected result size of 1');

        Test.stopTest();

    }
}