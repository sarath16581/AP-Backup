/************************************************************************************
Description:    Test class to cover CaseTriggerHandler_IToC Trigger functionality
History:
-------------------------------------------------------------------------------------
2017-05-16  Adrian A  Created
2018-06-05  TDO-16 : rahul.kapoor@coroma.com.au Refactored comments and indentation,
            added tests for Closing a case to populate Adjustment Record with CA with
            Approved/Rejected status, Closing a case to populate Adjustment Record
            with Non-Discretionary type and Approved/Rejected Status.
*************************************************************************************/
@isTest
public class CaseTriggerHandler_IToCTest {

    @testSetup
    static void setupTestData() {
        SystemSwitch__c setting = new  SystemSwitch__c(Name = 'blah', ObjectTriggersToBeDisabled__c = 'Case', DisableTriggers__c = true);
        insert setting;

        //Create a test account.
        Account testAccount  = TestDataProvider.createAccount('Test Adjustment Account', 1)[0];
        insert testAccount;

        //Update Legacy Id.
        testAccount.Legacy_Id__c = '60000000';
        Database.update(testAccount);

        //Create a test billing account.
        Billing_Account__c testBillingAccount = new Billing_Account__c();
        testBillingAccount.Organisation__c = testAccount.Id;
        testBillingAccount.Name = 'Test Adjustment Billing Account';
        testBillingAccount.Legacy_Id__c = '60000000';
        insert testBillingAccount;

        //Create a Case to support adjustment creation.
        Case testCase = I2CTestDataBuilder.createCase();
        testCase.Related_Billing_Account__c = testBillingAccount.Id;
        testCase.Billing_Number__c = '123456';

        insert testCase;
    }

    /*************************************************************
    *  Scenario:
    *      Closing a case to populate Adjustment Record without CA.
    **************************************************************/
    public static testmethod void populateAdjustmentRecordWithoutCA(){
        //We have only one case record.
        Case testCase = [SELECT Id, Status, Billing_Number__c, Related_Billing_Account__c
                         FROM CASE
                         LIMIT 1];

        test.startTest();

        //Create disputed items without credit approvals.
        Disputed_Item__c disputedItemParcel = new Disputed_Item__c();
        disputedItemParcel.Case__c = testCase.Id;
        disputedItemParcel.Product__c = 'Parcels';
        disputedItemParcel.Product_Sub_Category__c = 'Local marketplaces';
        disputedItemParcel.Product_Desciption__c = 'Test Parcels Dispute';
        disputedItemParcel.Disputed_Reason__c = 'Duplicate Billing';
        disputedItemParcel.Service_Date__c = Date.newInstance(2017, 02, 09);
        disputedItemParcel.Type__c = 'Non-Discretionary';

        //Insert only one disputed item, this will create a Credit_Approval__c.
        insert disputedItemParcel;

        Disputed_Item__c dispItemCheck = [SELECT id, Credit_Approval__c
                                          FROM Disputed_Item__c
                                          WHERE id =: disputedItemParcel.Id
                                          LIMIT 1];

        //We need to close the disputedItemParcel.
        dispItemCheck.status__c = 'Verified Claim';
        //Credit Amount must be greater than zero for verified claims.
        dispItemCheck.Proposed_Credit__c = 10;
        dispItemCheck.Reason__c = 'Manifest Not Posted';
        dispItemCheck.Reason_Category__c = 'Delivery Issue';
        dispItemCheck.Resolution_Code__c = 'RES00002';
        dispItemCheck.AP_Profit_Centre_Code__c = 'MEL';
        dispItemCheck.Service_Type__c = 'EXP';
        dispItemCheck.Product_Code__c ='AP-1212';
        dispItemCheck.Invoice_Number__c = '1111111';
        update dispItemCheck;

        //Associated credit approvals, we have only one credit approval record.
        Credit_Approval__c creditApproval = [SELECT Id, Status__c
                                             FROM Credit_Approval__c
                                             LIMIT 1];

        //Update credit approval record's status as Approved
        creditApproval.Status__c = 'Approved';
        update creditApproval;

        //Make the case ready to close.
        testCase.Status = 'Closed';
        update testCase;

        test.stopTest();

        Integer adjustmentCount = [SELECT COUNT() FROM Adjustment__c];

        System.assertEquals(1,adjustmentCount,
                'CaseTriggerHandler_IToCTest_populateAdjustmentRecordWithoutCA : Adjustment record should be created');
    }

    /*************************************************************
    *  Scenario:
    *      Closing a case to populate Adjustment Record with CA.
    **************************************************************/
    public static testmethod void populateAdjustmentRecordWithCA(){
        //We have only one case record.
        Case testCase = [SELECT Id, Status, Billing_Number__c, Related_Billing_Account__c
                         FROM CASE
                         LIMIT 1];

        test.startTest();

        //Create disputed items without credit approvals.
        Disputed_Item__c disputedItemParcel = new Disputed_Item__c();
        disputedItemParcel.Case__c = testCase.Id;
        disputedItemParcel.Product__c = 'Parcels';
        disputedItemParcel.Product_Sub_Category__c = 'Local marketplaces';
        disputedItemParcel.Product_Desciption__c = 'Test Parcels Dispute';
        disputedItemParcel.Disputed_Reason__c = 'Duplicate Billing';
        disputedItemParcel.Service_Date__c = Date.newInstance(2017, 02, 09);
        disputedItemParcel.Type__c = 'Discretionary Credit';

        //Insert only one disputed item, this will create a Credit_Approval__c.
        insert disputedItemParcel;

        Disputed_Item__c dispItemCheck = [SELECT id, Credit_Approval__c
                                          FROM Disputed_Item__c
                                          WHERE id =: disputedItemParcel.Id
                                          LIMIT 1];

        //We need to close the disputedItemParcel.
        dispItemCheck.status__c = 'Verified Claim';
        //Credit Amount must be greater than zero for verified claims.
        dispItemCheck.Proposed_Credit__c = 10;
        dispItemCheck.Reason__c = 'Manifest Not Posted';
        dispItemCheck.Reason_Category__c = 'Delivery Issue';
        dispItemCheck.Resolution_Code__c = 'RES00002';
        dispItemCheck.AP_Profit_Centre_Code__c = 'MEL';
        dispItemCheck.Service_Type__c = 'EXP';
        dispItemCheck.Product_Code__c ='AP-1212';
        dispItemCheck.Invoice_Number__c = '1111111';
        update dispItemCheck;

        //Associated credit approvals, we have only one credit approval record.
        Credit_Approval__c creditApproval = [SELECT Id, Status__c
                                             FROM Credit_Approval__c
                                             LIMIT 1];

        //Update credit approval record's status as Approved
        creditApproval.Status__c = 'Approved';
        update creditApproval;

        //Make the case ready to close.
        testCase.Status = 'Closed';
        update testCase;

        test.stopTest();

        Integer adjustmentCount = [SELECT COUNT() FROM Adjustment__c];

        System.assertEquals(1,adjustmentCount,
                'CaseTriggerHandler_IToCTest_populateAdjustmentRecordWithCA : Adjustment record should be created');
    }

    /*******************************************************************************
    *  Scenario:
    *      Closing a case to populate Adjustment Record with CA with Rejected Status.
    ********************************************************************************/
    public static testmethod void populateAdjustmentWithCARejectedStatus(){
        //We have only one case record.
        Case testCase = [SELECT Id, Status, Billing_Number__c, Related_Billing_Account__c
                         FROM CASE
                         LIMIT 1];

        test.startTest();

        //Create disputed items without credit approvals.
        Disputed_Item__c disputedItemParcel = new Disputed_Item__c();
        disputedItemParcel.Case__c = testCase.Id;
        disputedItemParcel.Product__c = 'Parcels';
        disputedItemParcel.Product_Sub_Category__c = 'Local marketplaces';
        disputedItemParcel.Product_Desciption__c = 'Test Parcels Dispute';
        disputedItemParcel.Disputed_Reason__c = 'Duplicate Billing';
        disputedItemParcel.Service_Date__c = Date.newInstance(2017, 02, 09);
        disputedItemParcel.Type__c = 'Discretionary Credit';

        //Insert only one disputed item, this will create a Credit_Approval__c.
        insert disputedItemParcel;

        Disputed_Item__c dispItemCheck = [SELECT id, Credit_Approval__c
                                          FROM Disputed_Item__c
                                          WHERE id =: disputedItemParcel.Id
                                          LIMIT 1];

        //We need to close the disputedItemParcel.
        dispItemCheck.status__c = 'Verified Claim';
        //Credit Amount must be greater than zero for verified claims.
        dispItemCheck.Proposed_Credit__c = 10;
        dispItemCheck.Reason__c = 'Manifest Not Posted';
        dispItemCheck.Reason_Category__c = 'Delivery Issue';
        dispItemCheck.Resolution_Code__c = 'RES00002';
        dispItemCheck.AP_Profit_Centre_Code__c = 'MEL';
        dispItemCheck.Service_Type__c = 'EXP';
        dispItemCheck.Product_Code__c ='AP-1212';
        dispItemCheck.Invoice_Number__c = '1111111';
        update dispItemCheck;

        //Associated credit approvals, we have only one credit approval record.
        Credit_Approval__c creditApproval = [SELECT Id, Status__c
                                             FROM Credit_Approval__c
                                             LIMIT 1];

        //Update credit approval record's status as Rejected
        creditApproval.Status__c = 'Rejected';
        update creditApproval;

        //Make the case ready to close.
        testCase.Status = 'Closed';
        update testCase;

        test.stopTest();

        Integer adjustmentCount = [SELECT COUNT() FROM Adjustment__c];

        System.assertEquals(0,adjustmentCount,
                'CaseTriggerHandler_IToCTest_populateAdjustmentWithCARejectedStatus : Adjustment record should not be created');
    }

    /***************************************************************************************************
    *  Scenario:
    *      Closing a case to populate Adjustment Record with Non-Discretionary Type and Rejected Status.
    ****************************************************************************************************/
    public static testmethod void populateAdjustmentWithNonDiscretionaryTypeRejected(){
        //We have only one case record.
        Case testCase = [SELECT Id, Status, Billing_Number__c, Related_Billing_Account__c
                         FROM CASE
                         LIMIT 1];

        test.startTest();

        //Create disputed items without credit approvals.
        Disputed_Item__c disputedItemParcel = new Disputed_Item__c();
        disputedItemParcel.Case__c = testCase.Id;
        disputedItemParcel.Product__c = 'Parcels';
        disputedItemParcel.Product_Sub_Category__c = 'Local marketplaces';
        disputedItemParcel.Product_Desciption__c = 'Test Parcels Dispute';
        disputedItemParcel.Disputed_Reason__c = 'Duplicate Billing';
        disputedItemParcel.Service_Date__c = Date.newInstance(2017, 02, 09);
        disputedItemParcel.Type__c = 'Non-Discretionary';

        //Insert only one disputed item, this will create a Credit_Approval__c.
        insert disputedItemParcel;

        Disputed_Item__c dispItemCheck = [SELECT id, Credit_Approval__c
                                          FROM Disputed_Item__c
                                          WHERE id =: disputedItemParcel.Id
                                          LIMIT 1];

        //We need to close the disputedItemParcel.
        dispItemCheck.status__c = 'Verified Claim';
        //Credit Amount must be greater than zero for verified claims.
        dispItemCheck.Proposed_Credit__c = 10;
        dispItemCheck.Reason__c = 'Manifest Not Posted';
        dispItemCheck.Reason_Category__c = 'Delivery Issue';
        dispItemCheck.Resolution_Code__c = 'RES00002';
        dispItemCheck.AP_Profit_Centre_Code__c = 'MEL';
        dispItemCheck.Service_Type__c = 'EXP';
        dispItemCheck.Product_Code__c ='AP-1212';
        dispItemCheck.Invoice_Number__c = '1111111';
        update dispItemCheck;

        //Associated credit approvals, we have only one credit approval record.
        Credit_Approval__c creditApproval = [SELECT Id, Status__c
                                             FROM Credit_Approval__c
                                             LIMIT 1];

        //Update credit approval record's status as Rejected
        creditApproval.Status__c = 'Rejected';
        update creditApproval;

        //Make the case ready to close.
        testCase.Status = 'Closed';
        update testCase;

        test.stopTest();

        Integer adjustmentCount = [SELECT COUNT() FROM Adjustment__c];

        System.assertEquals(0,adjustmentCount,
                'CaseTriggerHandler_IToCTest_populateAdjustmentWithNonDiscretionaryTypeRejected : Adjustment record should not be created');
    }

    /***************************************************************************************************
    *  Scenario:
    *      Closing a case to populate Adjustment Record with Non-Discretionary Type and Approved Status.
    ****************************************************************************************************/
    public static testmethod void populateAdjustmentWithNonDiscretionaryTypeApproved(){
        //We have only one case record.
        Case testCase = [SELECT Id, Status, Billing_Number__c, Related_Billing_Account__c
        FROM CASE
        LIMIT 1];

        test.startTest();

        //Create disputed items without credit approvals.
        Disputed_Item__c disputedItemParcel = new Disputed_Item__c();
        disputedItemParcel.Case__c = testCase.Id;
        disputedItemParcel.Product__c = 'Parcels';
        disputedItemParcel.Product_Sub_Category__c = 'Local marketplaces';
        disputedItemParcel.Product_Desciption__c = 'Test Parcels Dispute';
        disputedItemParcel.Disputed_Reason__c = 'Duplicate Billing';
        disputedItemParcel.Service_Date__c = Date.newInstance(2017, 02, 09);
        disputedItemParcel.Type__c = 'Non-Discretionary';

        //Insert only one disputed item, this will create a Credit_Approval__c.
        insert disputedItemParcel;

        Disputed_Item__c dispItemCheck = [SELECT id, Credit_Approval__c
        FROM Disputed_Item__c
        WHERE id =: disputedItemParcel.Id
        LIMIT 1];

        //We need to close the disputedItemParcel.
        dispItemCheck.status__c = 'Verified Claim';
        //Credit Amount must be greater than zero for verified claims.
        dispItemCheck.Proposed_Credit__c = 10;
        dispItemCheck.Reason__c = 'Manifest Not Posted';
        dispItemCheck.Reason_Category__c = 'Delivery Issue';
        dispItemCheck.Resolution_Code__c = 'RES00002';
        dispItemCheck.AP_Profit_Centre_Code__c = 'MEL';
        dispItemCheck.Service_Type__c = 'EXP';
        dispItemCheck.Product_Code__c ='AP-1212';
        dispItemCheck.Invoice_Number__c = '1111111';
        update dispItemCheck;

        //Associated credit approvals, we have only one credit approval record.
        Credit_Approval__c creditApproval = [SELECT Id, Status__c
        FROM Credit_Approval__c
        LIMIT 1];

        //Update credit approval record's status as Rejected
        creditApproval.Status__c = 'Approved';
        update creditApproval;

        //Make the case ready to close.
        testCase.Status = 'Closed';
        update testCase;

        test.stopTest();

        Integer adjustmentCount = [SELECT COUNT() FROM Adjustment__c];

        System.assertEquals(1,adjustmentCount,
                'CaseTriggerHandler_IToCTest_populateAdjustmentWithNonDiscretionaryTypeApproved : Adjustment record should be created');
    }
}