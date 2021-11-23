/***
 * @author Ranjeewa Silva
 * @date 2021-06-04
 * @group Tests
 * @domain Customer Resolutions
 * @description Test Class covering CustomerResCreditApproversModule
 * @changelog
 * 2021-06-04 - Ranjeewa Silva - Created
 */

@IsTest
private class CustomerResCreditApproversModule_Test {
    @IsTest
    static void testEnsureBeforeUpdatePopulateApproversFromCreditApprovalMatrix() {

        // =====================================
        // Data Preparation
        // =====================================
        ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CreditApprovalTriggerHandler.getUnitOfWorkSObjectTypes());

        //-------------------------------------------------------------------------------------------------------------
        // Credit Approval Matrix - Non-Discretionary - Data Setup
        // Record #                 | Credit Type       | Product Family    | Product Sub Category  | From Credit Amount    | To Credit Amount
        // creditApprovalMatrix[0]  | Non-Discretionary | default           | default               | 0                     | 100
        // creditApprovalMatrix[1]  | Non-Discretionary | default           | default               | 100.01                | 10000
        // creditApprovalMatrix[2]  | Non-Discretionary | default           | default               | 10000.01              | 1000000
        // creditApprovalMatrix[3]  | Non-Discretionary | Product1          | default               | 0                     | 1000000
        // creditApprovalMatrix[4]  | Non-Discretionary | Product2          | P2_SubCategory1       | 0                     | 1000000
        // creditApprovalMatrix[5]  | Non-Discretionary | Product2          | P2_SubCategory2       | 0                     | 1000000
        //-------------------------------------------------------------------------------------------------------------
        List<CreditApprovalMatrix__c> creditApprovalMatrixNonDiscretionaryCredit = getCreditApprovalMatrixTestData('Non-Discretionary');

        //-------------------------------------------------------------------------------------------------------------
        // Credit Approval Matrix - Discretionary Credit - Data Setup
        // Record #                 | Credit Type           | Product Family    | Product Sub Category  | From Credit Amount    | To Credit Amount
        // creditApprovalMatrix[0]  | Discretionary Credit  | default           | default               | 0                     | 1000000
        //-------------------------------------------------------------------------------------------------------------
        List<CreditApprovalMatrix__c> creditApprovalMatrixDiscretionaryCredit = ApplicationTestDataFactory.getCreditApprovalMatrixRecords(1, true, 'Discretionary Credit', CustomerResCreditApprovalMatrixDomain.DEFAULT_PRODUCT_FAMILY, CustomerResCreditApprovalMatrixDomain.DEFAULT_PRODUCT_SUB_CATEGORY);
        creditApprovalMatrixDiscretionaryCredit[0].FromCreditAmount__c = 0;
        creditApprovalMatrixDiscretionaryCredit[0].ToCreditAmount__c = 1000000;
        creditApprovalMatrixDiscretionaryCredit[0].Approver_1__c = ApplicationTestDataFactory.getUsers(1, true)[0].Id;
        creditApprovalMatrixDiscretionaryCredit[0].Approver1Role__c = 'Approver1 Role';

        List<Credit_Approval__c> creditApprovals = ApplicationTestDataFactory.getCreditApprovals(5, true);
        // creditApprovals[0] has CreditType = 'Non-Discretionary', Product = 'XYZ', Product Sub Category = 'XYZ_SC1', Credit Amount = 2000
        // expected to be linked to creditApprovalMatrixNonDiscretionaryCredit[1]
        creditApprovals[0].Type__c = 'Non-Discretionary';
        creditApprovals[0].Product_Family__c = 'XYZ';
        creditApprovals[0].Product_Sub_Category__c = 'XYZ_SC1';
        creditApprovals[0].Credit_Amount__c = 2000;

        // creditApprovals[1] has CreditType = 'Non-Discretionary', Product = 'Product1', Product Sub Category = 'XYZ_SC1', Credit Amount = 2000
        // expected to be linked to creditApprovalMatrixNonDiscretionaryCredit[3]
        creditApprovals[1].Type__c = 'Non-Discretionary';
        creditApprovals[1].Product_Family__c = 'Product1';
        creditApprovals[1].Product_Sub_Category__c = 'XYZ_SC1';
        creditApprovals[1].Credit_Amount__c = 500;

        // creditApprovals[2] has CreditType = 'Non-Discretionary', Product = 'Product2', Product Sub Category = 'P2_SubCategory2', Credit Amount = 1500
        // expected to be linked to creditApprovalMatrixNonDiscretionaryCredit[5]
        creditApprovals[2].Type__c = 'Non-Discretionary';
        creditApprovals[2].Product_Family__c = 'Product2';
        creditApprovals[2].Product_Sub_Category__c = 'P2_SubCategory2';
        creditApprovals[2].Credit_Amount__c = 1500;

        // creditApprovals[3] has CreditType = 'Discretionary Credit', Product = 'Product2', Product Sub Category = 'P2_SubCategory2', Credit Amount = 1500
        // expected to be linked to creditApprovalMatrixDiscretionaryCredit[0]
        creditApprovals[3].Type__c = 'Discretionary Credit';
        creditApprovals[3].Product_Family__c = 'Product2';
        creditApprovals[3].Product_Sub_Category__c = 'P2_SubCategory2';
        creditApprovals[3].Credit_Amount__c = 1500;

        // creditApprovals[4] has CreditType = 'Discretionary Credit', Product = 'Product2', Product Sub Category = 'P2_SubCategory2', Credit Amount = 1500000
        // expected to error out as credit amount is outside the bands
        creditApprovals[4].Type__c = 'Discretionary Credit';
        creditApprovals[4].Product_Family__c = 'Product2';
        creditApprovals[4].Product_Sub_Category__c = 'P2_SubCategory2';
        creditApprovals[4].Credit_Amount__c = 1500000;

        List<Credit_Approval__c> oldCreditApprovals = new List<Credit_Approval__c>{creditApprovals[0].clone(true), creditApprovals[1].clone(true), creditApprovals[2].clone(true), creditApprovals[3].clone(true), creditApprovals[4].clone(true)};

        // set the credit aproval Ready For Approval flag to true
        creditApprovals[0].Ready_For_Approval__c = true;
        creditApprovals[1].Ready_For_Approval__c = true;
        creditApprovals[2].Ready_For_Approval__c = true;
        creditApprovals[3].Ready_For_Approval__c = true;
        creditApprovals[4].Ready_For_Approval__c = true;

        // =====================================
        // Stubbing
        // =====================================
        CreditApprovalMatrixSelector mockCreditApprovalMatrixSelector = (CreditApprovalMatrixSelector)MockUtility.mockSelector(CreditApprovalMatrixSelector.class);

        // set up our responses
        MockUtility.Mocks.startStubbing();
        List<CreditApprovalMatrix__c> approvalMatrixResults = new List<CreditApprovalMatrix__c>(creditApprovalMatrixNonDiscretionaryCredit);
        approvalMatrixResults.addAll(creditApprovalMatrixDiscretionaryCredit);
        MockUtility.Mocks.when(mockCreditApprovalMatrixSelector.selectByCreditTypeAndProductInOrder((Set<String>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(approvalMatrixResults);
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        CustomerResCreditApproversModule module = CustomerResCreditApproversModule.newInstance();
        module.onBeforeUpdate(creditApprovals, new Map<Id, Credit_Approval__c>(oldCreditApprovals), uow);

        Test.stopTest();

        ((CreditApprovalMatrixSelector)MockUtility.Mocks.verify(mockCreditApprovalMatrixSelector, 1)).selectByCreditTypeAndProductInOrder((Set<String>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject());

        // creditApproval[0] - No Credit Approval Matrix records available for the Product and Product Sub Category of creditApproval[0]
        // ensure that creditApproval[0] is linked to appropriate credit approval matrix record with Product=default and Product Sub-Category=default
        System.assertEquals(creditApprovalMatrixNonDiscretionaryCredit[1].Id, creditApprovals[0].CreditApprovalMatrix__c, 'Expected creditApproval record to be linked to Credit Approval Matrix with Product=default and Product Sub Category=default');
        System.assertEquals(creditApprovalMatrixNonDiscretionaryCredit[1].Approver_1__c, creditApprovals[0].Approver_1__c, 'Expected approvers on creditApproval record to be populated based on credit approval matrix');
        System.assertEquals(creditApprovalMatrixNonDiscretionaryCredit[1].Approver_2__c, creditApprovals[0].Approver_2__c, 'Expected approvers on creditApproval record to be populated based on credit approval matrix');
        System.assertEquals(creditApprovalMatrixNonDiscretionaryCredit[1].Approver1Role__c, creditApprovals[0].Approver1Role__c, 'Expected approver roles on creditApproval record to be populated based on credit approval matrix');
        System.assertEquals(creditApprovalMatrixNonDiscretionaryCredit[1].Approver2Role__c, creditApprovals[0].Approver2Role__c, 'Expected approver roles on creditApproval record to be populated based on credit approval matrix');

        // creditApproval[1] - Credit Approval Matrix record available for the Product but not for the Product Sub Category
        // ensure that creditApproval[1] is linked to appropriate credit approval matrix record with Product=Product1 and Product Sub-Category=default
        System.assertEquals(creditApprovalMatrixNonDiscretionaryCredit[3].Id, creditApprovals[1].CreditApprovalMatrix__c, 'Expected creditApproval record to be linked to Credit Approval Matrix with Product=Product1 and Product Sub Category=default');
        System.assertEquals(creditApprovalMatrixNonDiscretionaryCredit[3].Approver_1__c, creditApprovals[1].Approver_1__c, 'Expected approvers on creditApproval record to be populated based on credit approval matrix');
        System.assertEquals(creditApprovalMatrixNonDiscretionaryCredit[3].Approver1Role__c, creditApprovals[1].Approver1Role__c, 'Expected approver roles on creditApproval record to be populated based on credit approval matrix');

        // creditApproval[2] - Credit Approval Matrix record available for the Product and Product Sub Category
        // ensure that creditApproval[2] is linked to appropriate credit approval matrix record
        System.assertEquals(creditApprovalMatrixNonDiscretionaryCredit[5].Id, creditApprovals[2].CreditApprovalMatrix__c, 'Expected creditApproval record to be linked to Credit Approval Matrix with specific Product and Product Sub Category');
        System.assertEquals(creditApprovalMatrixNonDiscretionaryCredit[5].Approver_1__c, creditApprovals[2].Approver_1__c, 'Expected approvers on creditApproval record to be populated based on credit approval matrix');
        System.assertEquals(creditApprovalMatrixNonDiscretionaryCredit[5].Approver1Role__c, creditApprovals[2].Approver1Role__c, 'Expected approver roles on creditApproval record to be populated based on credit approval matrix');

        // creditApproval[3] - Credit Approval Matrix record not available for the Product and Product Sub Category for Credit Type = 'Discretionary Credit'
        // ensure that creditApproval[3] is linked to credit approval matrix record with Product=default, Product Sub Category=default
        System.assertEquals(creditApprovalMatrixDiscretionaryCredit[0].Id, creditApprovals[3].CreditApprovalMatrix__c, 'Expected creditApproval record to be linked to Credit Approval Matrix with specific Product and Product Sub Category');
        System.assertEquals(creditApprovalMatrixDiscretionaryCredit[0].Approver_1__c, creditApprovals[3].Approver_1__c, 'Expected approvers on creditApproval record to be populated based on credit approval matrix');
        System.assertEquals(creditApprovalMatrixDiscretionaryCredit[0].Approver1Role__c, creditApprovals[3].Approver1Role__c, 'Expected approver roles on creditApproval record to be populated based on credit approval matrix');

        // creditApproval[4] - Credit Approval Matrix record not available. Credit amount outside the bands.
        // ensure that creditApproval[4] has errored out
        System.assertEquals(true, creditApprovals[4].hasErrors(), 'Expected creditApproval record to error out');
        System.assertEquals(null, creditApprovals[4].CreditApprovalMatrix__c, 'Expected creditApproval record to error out');
    }

    @IsTest
    static void testEnsureBeforeUpdatePopulateApproversFromCreditApprovalMatrix_SalesTeamOverride() {

        // =====================================
        // Data Preparation
        // =====================================
        ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CreditApprovalTriggerHandler.getUnitOfWorkSObjectTypes());

        // Sales_Segment_Reference__c is does not currently support selectors
        // therefore need DML in test case
        List<User> approverUsers = ApplicationTestDataFactory.getUsers(5, false);
        insert(approverUsers);

        // setup approverUser[3] to be the manager of approverUser[2]
        // approverUser[2] and approverUser[3] will be used as approvers on Sales Team roles
        approverUsers[2].ManagerId = approverUsers[3].Id;
        update(approverUsers[2]);

        Sales_Segment_Reference__c salesSegment = new Sales_Segment_Reference__c();
        salesSegment.Sales_Team_Owner_Type__c = Label.I2C_Sales_Director;
        salesSegment.Sales_Director__c = approverUsers[2].Id;
        salesSegment.Sales_Segment__c = 'Team1';
        insert(salesSegment);

        //-------------------------------------------------------------------------------------------------------------
        // Credit Approval Matrix - Discretionary Credit - Data Setup
        // Record #                 | Credit Type           | Product Family    | Product Sub Category  | From Credit Amount    | To Credit Amount
        // creditApprovalMatrix[0]  | Discretionary Credit  | default           | default               | 0                     | 1000000
        //-------------------------------------------------------------------------------------------------------------
        List<CreditApprovalMatrix__c> creditApprovalMatrixDiscretionaryCredit = ApplicationTestDataFactory.getCreditApprovalMatrixRecords(1, true, 'Discretionary Credit', CustomerResCreditApprovalMatrixDomain.DEFAULT_PRODUCT_FAMILY, CustomerResCreditApprovalMatrixDomain.DEFAULT_PRODUCT_SUB_CATEGORY);
        creditApprovalMatrixDiscretionaryCredit[0].FromCreditAmount__c = 0;
        creditApprovalMatrixDiscretionaryCredit[0].ToCreditAmount__c = 1000000;
        creditApprovalMatrixDiscretionaryCredit[0].Approver_1__c = approverUsers[0].Id; //setup default approver in credit approval matrix
        creditApprovalMatrixDiscretionaryCredit[0].Approver1Role__c = CustomerResCreditApproversModule.DYNAMIC_APPROVER_ROLE_SALES_DIRECTOR;
        creditApprovalMatrixDiscretionaryCredit[0].Approver_2__c = approverUsers[1].Id; //setup default approver in credit approval matrix
        creditApprovalMatrixDiscretionaryCredit[0].Approver2Role__c = CustomerResCreditApproversModule.DYNAMIC_APPROVER_ROLE_GM_OF_SALES;
        creditApprovalMatrixDiscretionaryCredit[0].Approver_3__c = approverUsers[4].Id; //setup default approver in credit approval matrix
        creditApprovalMatrixDiscretionaryCredit[0].Approver3Role__c = 'Approver3 Role';

        List<Credit_Approval__c> creditApprovals = ApplicationTestDataFactory.getCreditApprovals(1, true);
        creditApprovals[0].Type__c = 'Discretionary Credit';
        creditApprovals[0].Product_Family__c = 'Product2';
        creditApprovals[0].Product_Sub_Category__c = 'P2_SubCategory2';
        creditApprovals[0].Credit_Amount__c = 1500;
        creditApprovals[0].Sales_Team__c = salesSegment.Sales_Segment__c;

        List<Credit_Approval__c> oldCreditApprovals = new List<Credit_Approval__c>{creditApprovals[0].clone(true)};

        // set the credit aproval Ready For Approval flag to true
        creditApprovals[0].Ready_For_Approval__c = true;

        // =====================================
        // Stubbing
        // =====================================
        CreditApprovalMatrixSelector mockCreditApprovalMatrixSelector = (CreditApprovalMatrixSelector)MockUtility.mockSelector(CreditApprovalMatrixSelector.class);

        // set up our responses
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockCreditApprovalMatrixSelector.selectByCreditTypeAndProductInOrder((Set<String>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(creditApprovalMatrixDiscretionaryCredit);
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        CustomerResCreditApproversModule module = CustomerResCreditApproversModule.newInstance();
        module.onBeforeUpdate(creditApprovals, new Map<Id, Credit_Approval__c>(oldCreditApprovals), uow);

        Test.stopTest();

        ((CreditApprovalMatrixSelector)MockUtility.Mocks.verify(mockCreditApprovalMatrixSelector, 1)).selectByCreditTypeAndProductInOrder((Set<String>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject());

        // ensure that approvers in credit approval matrix are overriden by approvers in sales team
        System.assertEquals(creditApprovalMatrixDiscretionaryCredit[0].Id, creditApprovals[0].CreditApprovalMatrix__c, 'Expected creditApproval record to be linked to Credit Approval Matrix with specific Product and Product Sub Category');
        System.assertEquals(salesSegment.Sales_Director__c, creditApprovals[0].Approver_1__c, 'Expected approvers on creditApproval record to be populated based on sales team');
        System.assertEquals(creditApprovalMatrixDiscretionaryCredit[0].Approver1Role__c, creditApprovals[0].Approver1Role__c, 'Expected approver roles on creditApproval record to be populated based on credit approval matrix');
        System.assertEquals(approverUsers[3].Id, creditApprovals[0].Approver_2__c, 'Expected approvers on creditApproval record to be populated based on credit approval matrix');
        System.assertEquals(creditApprovalMatrixDiscretionaryCredit[0].Approver2Role__c, creditApprovals[0].Approver2Role__c, 'Expected approver roles on creditApproval record to be populated based on credit approval matrix');
        System.assertEquals(creditApprovalMatrixDiscretionaryCredit[0].Approver_3__c, creditApprovals[0].Approver_3__c, 'Expected approvers on creditApproval record to be populated based on credit approval matrix');
        System.assertEquals(creditApprovalMatrixDiscretionaryCredit[0].Approver3Role__c, creditApprovals[0].Approver3Role__c, 'Expected approver roles on creditApproval record to be populated based on credit approval matrix');
    }

    @IsTest
    static void testEnsureBeforeUpdatePopulateApproversFromCreditApprovalMatrix_SalesTeamOwnedByHoldingUser() {

        // =====================================
        // Data Preparation
        // =====================================
        ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CreditApprovalTriggerHandler.getUnitOfWorkSObjectTypes());

        // Sales_Segment_Reference__c is does not currently support selectors
        // therefore need DML in test case
        List<User> approverUsers = ApplicationTestDataFactory.getUsers(5, false);
        // make  approverUser[0] the 'Holding User Manager'
        approverUsers[0].FirstName = 'Holding User';
        approverUsers[0].LastName = 'Manager';

        //make approverUsers[2] inactive
        approverUsers[2].IsActive = false;
        insert(approverUsers);

        // setup approverUsers[2] to be the manager of approverUser[1]
        // approverUsers[2] and approverUsers[1] will be used as approvers on Sales Team roles
        approverUsers[1].ManagerId = approverUsers[2].Id;
        update(approverUsers[1]);

        // salesTeamOne is owned by approverUsers[0]. i.e. Holding User
        Sales_Segment_Reference__c salesTeamOne = new Sales_Segment_Reference__c();
        salesTeamOne.Sales_Team_Owner_Type__c = Label.I2C_Sales_Director;
        salesTeamOne.Sales_Director__c = approverUsers[0].Id;
        salesTeamOne.Sales_Segment__c = 'Team1';

        // salesTeamTwo is owned by approverUsers[1]
        Sales_Segment_Reference__c salesTeamTwo = new Sales_Segment_Reference__c();
        salesTeamTwo.Sales_Team_Owner_Type__c = Label.I2C_Sales_Director;
        salesTeamTwo.Sales_Director__c = approverUsers[1].Id;
        salesTeamTwo.Sales_Segment__c = 'Team2';

        insert new List<Sales_Segment_Reference__c>{salesTeamOne, salesTeamTwo};

        //-------------------------------------------------------------------------------------------------------------
        // Credit Approval Matrix - Discretionary Credit - Data Setup
        // Record #                 | Credit Type           | Product Family    | Product Sub Category  | From Credit Amount    | To Credit Amount
        // creditApprovalMatrix[0]  | Discretionary Credit  | default           | default               | 0                     | 1000000
        //-------------------------------------------------------------------------------------------------------------
        List<CreditApprovalMatrix__c> creditApprovalMatrixDiscretionaryCredit = ApplicationTestDataFactory.getCreditApprovalMatrixRecords(1, true, 'Discretionary Credit', CustomerResCreditApprovalMatrixDomain.DEFAULT_PRODUCT_FAMILY, CustomerResCreditApprovalMatrixDomain.DEFAULT_PRODUCT_SUB_CATEGORY);
        creditApprovalMatrixDiscretionaryCredit[0].FromCreditAmount__c = 0;
        creditApprovalMatrixDiscretionaryCredit[0].ToCreditAmount__c = 1000000;
        creditApprovalMatrixDiscretionaryCredit[0].Approver_1__c = approverUsers[3].Id; //setup default approver in credit approval matrix
        creditApprovalMatrixDiscretionaryCredit[0].Approver1Role__c = CustomerResCreditApproversModule.DYNAMIC_APPROVER_ROLE_SALES_DIRECTOR;
        creditApprovalMatrixDiscretionaryCredit[0].Approver_2__c = approverUsers[4].Id; //setup default approver in credit approval matrix
        creditApprovalMatrixDiscretionaryCredit[0].Approver2Role__c = CustomerResCreditApproversModule.DYNAMIC_APPROVER_ROLE_GM_OF_SALES;


        // set up two credit approvals. one for each sales team
        List<Credit_Approval__c> creditApprovals = ApplicationTestDataFactory.getCreditApprovals(2, true);
        creditApprovals[0].Type__c = 'Discretionary Credit';
        creditApprovals[0].Product_Family__c = 'Product2';
        creditApprovals[0].Product_Sub_Category__c = 'P2_SubCategory2';
        creditApprovals[0].Credit_Amount__c = 1500;
        creditApprovals[0].Sales_Team__c = salesTeamOne.Sales_Segment__c;

        creditApprovals[1].Type__c = 'Discretionary Credit';
        creditApprovals[1].Product_Family__c = 'Product2';
        creditApprovals[1].Product_Sub_Category__c = 'P2_SubCategory2';
        creditApprovals[1].Credit_Amount__c = 1500;
        creditApprovals[1].Sales_Team__c = salesTeamTwo.Sales_Segment__c;

        List<Credit_Approval__c> oldCreditApprovals = new List<Credit_Approval__c>{creditApprovals[0].clone(true), creditApprovals[1].clone(true)};

        // set the credit aproval Ready For Approval flag to true
        creditApprovals[0].Ready_For_Approval__c = true;
        creditApprovals[1].Ready_For_Approval__c = true;

        // =====================================
        // Stubbing
        // =====================================
        CreditApprovalMatrixSelector mockCreditApprovalMatrixSelector = (CreditApprovalMatrixSelector)MockUtility.mockSelector(CreditApprovalMatrixSelector.class);

        // set up our responses
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockCreditApprovalMatrixSelector.selectByCreditTypeAndProductInOrder((Set<String>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())).thenReturn(creditApprovalMatrixDiscretionaryCredit);
        MockUtility.Mocks.stopStubbing();

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        CustomerResCreditApproversModule module = CustomerResCreditApproversModule.newInstance();
        module.onBeforeUpdate(creditApprovals, new Map<Id, Credit_Approval__c>(oldCreditApprovals), uow);

        Test.stopTest();

        ((CreditApprovalMatrixSelector)MockUtility.Mocks.verify(mockCreditApprovalMatrixSelector, 1)).selectByCreditTypeAndProductInOrder((Set<String>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject(), (Set<String>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject());

        // creditApproval[0] is in a Sales Team owned by 'Holding User'
        // ensure that approvers in credit approval matrix are used when the sales team is owned by 'Holding User'
        System.assertEquals(creditApprovalMatrixDiscretionaryCredit[0].Id, creditApprovals[0].CreditApprovalMatrix__c, 'Expected creditApproval record to be linked to Credit Approval Matrix with specific Product and Product Sub Category');
        System.assertEquals(creditApprovalMatrixDiscretionaryCredit[0].Approver_1__c, creditApprovals[0].Approver_1__c, 'Expected approvers to be populated based on credit approval matrix when sales team is owned by holding user');
        System.assertEquals(creditApprovalMatrixDiscretionaryCredit[0].Approver1Role__c, creditApprovals[0].Approver1Role__c, 'Expected approver roles on creditApproval record to be populated based on credit approval matrix');
        System.assertEquals(creditApprovalMatrixDiscretionaryCredit[0].Approver_2__c, creditApprovals[0].Approver_2__c, 'Expected approvers to be populated based on credit approval matrix when sales team is owned by holding user');
        System.assertEquals(creditApprovalMatrixDiscretionaryCredit[0].Approver2Role__c, creditApprovals[0].Approver2Role__c, 'Expected approver roles on creditApproval record to be populated based on credit approval matrix');

        // creditApproval[1] is in a Sales Team where sales team owner's manager is inactive.
        // ensure that approvers in credit approval matrix are used when a user based on sales team is inactive
        System.assertEquals(creditApprovalMatrixDiscretionaryCredit[0].Id, creditApprovals[1].CreditApprovalMatrix__c, 'Expected creditApproval record to be linked to Credit Approval Matrix with specific Product and Product Sub Category');
        System.assertEquals(salesTeamTwo.Sales_Director__c, creditApprovals[1].Approver_1__c, 'Expected approvers to be populated based on sales team');
        System.assertEquals(creditApprovalMatrixDiscretionaryCredit[0].Approver1Role__c, creditApprovals[1].Approver1Role__c, 'Expected approver roles on creditApproval record to be populated based on credit approval matrix');
        // user based on sales team approverUsers[3] is not active - should fall back to approver configured in matrix
        System.assertEquals(creditApprovalMatrixDiscretionaryCredit[0].Approver_2__c, creditApprovals[1].Approver_2__c, 'Expected approvers to be populated based on credit approval matrix when the user based on sales team is not active');
        System.assertEquals(creditApprovalMatrixDiscretionaryCredit[0].Approver2Role__c, creditApprovals[1].Approver2Role__c, 'Expected approver roles on creditApproval record to be populated based on credit approval matrix');

    }

    @IsTest
    static void testEnsureBeforeUpdatePopulateActualApproverUsersOnCompletion() {

        // =====================================
        // Data Preparation
        // =====================================
        ApplicationUnitOfWork uow = ApplicationUnitOfWork.newInstance(CreditApprovalTriggerHandler.getUnitOfWorkSObjectTypes());

        // Sales_Segment_Reference__c is does not currently support selectors
        // therefore need DML in test case
        List<User> approverUsers = ApplicationTestDataFactory.getUsers(5, true);

        List<Credit_Approval__c> creditApprovals = ApplicationTestDataFactory.getCreditApprovals(2, true);

        creditApprovals[0].Approver1Complete__c = CustomerResCreditApprovalsDomain.APPROVAL_STEP_STATUS_APPROVED;
        creditApprovals[0].ActualApprover1User__c = approverUsers[0].Id;
        creditApprovals[0].Approver2Complete__c = CustomerResCreditApprovalsDomain.APPROVAL_STEP_STATUS_PENDING;
        creditApprovals[0].Approver3Complete__c = CustomerResCreditApprovalsDomain.APPROVAL_STEP_STATUS_PENDING;

        creditApprovals[1].Approver1Complete__c = CustomerResCreditApprovalsDomain.APPROVAL_STEP_STATUS_APPROVED;
        creditApprovals[1].ActualApprover1User__c = approverUsers[1].Id;
        creditApprovals[1].Approver2Complete__c = CustomerResCreditApprovalsDomain.APPROVAL_STEP_STATUS_APPROVED;
        creditApprovals[1].ActualApprover2User__c = approverUsers[2].Id;
        creditApprovals[1].Approver3Complete__c = CustomerResCreditApprovalsDomain.APPROVAL_STEP_STATUS_APPROVED;
        creditApprovals[1].ActualApprover3User__c = approverUsers[3].Id;

        List<Credit_Approval__c> oldCreditApprovals = new List<Credit_Approval__c>{creditApprovals[0].clone(true), creditApprovals[1].clone(true)};

        // set the creditAprovals[0].Approver2Complete__c to 'Approved' from 'Pending'
        creditApprovals[0].Approver2Complete__c = CustomerResCreditApprovalsDomain.APPROVAL_STEP_STATUS_APPROVED;

        // set the creditAprovals[1].Approver3Complete__c to 'Pending' from 'Approved'
        creditApprovals[1].Approver3Complete__c = CustomerResCreditApprovalsDomain.APPROVAL_STEP_STATUS_PENDING;

        // =====================================
        // Stubbing
        // =====================================
        // None

        // =====================================
        // Testing
        // =====================================
        Test.startTest();

        CustomerResCreditApproversModule module = CustomerResCreditApproversModule.newInstance();
        module.onBeforeUpdate(creditApprovals, new Map<Id, Credit_Approval__c>(oldCreditApprovals), uow);

        Test.stopTest();

        // ensure ActualApprover2User__c is populated on approval
        System.assertEquals(UserInfo.getUserId(), creditApprovals[0].ActualApprover2User__c, 'Expected current user to be set as actual approver user on approval');
        System.assertEquals(approverUsers[0].Id, creditApprovals[0].ActualApprover1User__c, 'Expected previous approver users to remain unchanged on a subsequent approval');

        // ensure ActualApprover3User__c is reset on revoking the approval
        System.assertEquals(null, creditApprovals[1].ActualApprover3User__c, 'Expected actual approver user to reset when approval is revoked.');
    }

    private static List<CreditApprovalMatrix__c> getCreditApprovalMatrixTestData(String creditType) {

        List<User> approverUsers = ApplicationTestDataFactory.getUsers(6, true);

        //-------------------------------------------------------------------------------------------------------------
        // Test Data Setup
        // Record #                 | Product Family    | Product Sub Category  | From Credit Amount    | To Credit Amount
        // creditApprovalMatrix[0]  | default           | default               | 0                     | 100
        // creditApprovalMatrix[1]  | default           | default               | 100.01                | 10000
        // creditApprovalMatrix[2]  | default           | default               | 10000.01              | 1000000
        // creditApprovalMatrix[3]  | Product1          | default               | 0                     | 1000000
        // creditApprovalMatrix[4]  | Product2          | P2_SubCategory1       | 0                     | 1000000
        // creditApprovalMatrix[5]  | Product2          | P2_SubCategory2       | 0                     | 1000000
        //-------------------------------------------------------------------------------------------------------------


        List<CreditApprovalMatrix__c> creditApprovalMatrix = ApplicationTestDataFactory.getCreditApprovalMatrixRecords(6, true, creditType, CustomerResCreditApprovalMatrixDomain.DEFAULT_PRODUCT_FAMILY, CustomerResCreditApprovalMatrixDomain.DEFAULT_PRODUCT_SUB_CATEGORY);

        // 3 bands product = 'default' and product sub category = 'default'
        creditApprovalMatrix[0].FromCreditAmount__c = 0;
        creditApprovalMatrix[0].ToCreditAmount__c = 100;
        creditApprovalMatrix[0].Approver_1__c = approverUsers[0].Id;
        creditApprovalMatrix[0].Approver1Role__c = 'Approver1 Role';

        creditApprovalMatrix[1].FromCreditAmount__c = 100.01;
        creditApprovalMatrix[1].ToCreditAmount__c = 10000;
        creditApprovalMatrix[1].Approver_1__c = approverUsers[0].Id;
        creditApprovalMatrix[1].Approver1Role__c = 'Approver1 Role';
        creditApprovalMatrix[1].Approver_2__c = approverUsers[1].Id;
        creditApprovalMatrix[1].Approver2Role__c = 'Approver2 Role';

        creditApprovalMatrix[2].FromCreditAmount__c = 10000.01;
        creditApprovalMatrix[2].ToCreditAmount__c = 1000000;
        creditApprovalMatrix[2].Approver_1__c = approverUsers[0].Id;
        creditApprovalMatrix[2].Approver1Role__c = 'Approver1 Role';
        creditApprovalMatrix[2].Approver_2__c = approverUsers[1].Id;
        creditApprovalMatrix[2].Approver2Role__c = 'Approver2 Role';
        creditApprovalMatrix[2].Approver_3__c = approverUsers[2].Id;
        creditApprovalMatrix[2].Approver3Role__c = 'Approver3 Role';

        // 1 band for product = 'Product1' and product sub category = 'default'
        creditApprovalMatrix[3].FromCreditAmount__c = 0;
        creditApprovalMatrix[3].ToCreditAmount__c = 1000000;
        creditApprovalMatrix[3].Approver_1__c = approverUsers[3].Id;
        creditApprovalMatrix[3].Approver1Role__c = 'Approver1 Role';
        creditApprovalMatrix[3].Product_Family__c = 'Product1';
        creditApprovalMatrix[3].Product_Sub_Category__c = CustomerResCreditApprovalMatrixDomain.DEFAULT_PRODUCT_SUB_CATEGORY;

        // 1 band for product = 'Product2' and product sub category = 'P2_SubCategory1'
        creditApprovalMatrix[4].FromCreditAmount__c = 0;
        creditApprovalMatrix[4].ToCreditAmount__c = 1000000;
        creditApprovalMatrix[4].Approver_1__c = approverUsers[4].Id;
        creditApprovalMatrix[4].Approver1Role__c = 'Approver1 Role';
        creditApprovalMatrix[4].Product_Family__c = 'Product2';
        creditApprovalMatrix[4].Product_Sub_Category__c = 'P2_SubCategory1';

        // 1 band for product = 'Product2' and product sub category = 'P2_SubCategory2'
        creditApprovalMatrix[5].FromCreditAmount__c = 0;
        creditApprovalMatrix[5].ToCreditAmount__c = 1000000;
        creditApprovalMatrix[5].Approver_1__c = approverUsers[5].Id;
        creditApprovalMatrix[5].Approver1Role__c = 'Approver1 Role';
        creditApprovalMatrix[5].Product_Family__c = 'Product2';
        creditApprovalMatrix[5].Product_Sub_Category__c = 'P2_SubCategory2';

        return creditApprovalMatrix;
    }
}