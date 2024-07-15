/**
*  This test class is for CaseUtility.
*
@author Yuanyuan Zhang
@created 2014-07-16
@version 1.0
@since 30.0
*
@changelog
* 2014-07-16 Yuanyuan Zhang <yuanyuan.zhang@bluewolf.com>
* - Created
* - Test coverage  97%
* 2021-09-06	seth.heang@auspost.com.au   Uplift SF API version to 52
* 2024-07-15	 Paul Perry  Case Hand-off banner changes
*/
@isTest
private class ExpectedResponseQueueManagementExt_Test {
    
     @testSetup
    static void testDateCreation() {
            
        Contact con = TestDataProvider.createTestContact();
        insert con;
        
        Article__c art = new Article__c();
        art.Name = '123';
        art.ArticleLodgementDate__c = date.today();
        art.SenderPostcode__c = '123';
        art.ReceiverPostcode__c = '3002';
        art.ArticleType__c = 'Regular Parcel';
        insert art;
        
        Case case1 = new Case();
        case1.ContactId = con.Id;
        case1.Type = 'Feedback';
        case1.Subject = 'Newsdd';
        case1.Status = 'Awaiting Customer Response';
        case1.ProductCategory__c = 'Travel & ID';
        case1.EnquirySubType__c = 'Product Support';
        case1.ProductSubCategory__c = 'KeyPass';
        case1.ArticleTest__c = art.Id;
        case1.Network_Response__c = 'test';
        insert case1;
        
        StatusTracking__c st = TestDataProvider.createTestStatusTracking();
        st.Case__c = case1.Id;
        st.StatusValue__c = 'Awaiting Network Response';
        insert st;  
            
    }

    /**********************************************************************
     *  Scenario:
     *      Method to initialize the landing screen of myNetwork with investigation case and select specific case
     **********************************************************************/
    @isTest
    static void  myUnitTest() {
        
        Case case1 = [Select id, status from case limit 1];
        
        ExpectedResponseQueueManagement__c eq = TestDataProvider.createTestExpectedResponseQueueManagement();
        
        Test.startTest();
        
            ApexPages.StandardController stdCtl = new ApexPages.StandardController(case1);   
            ExpectedResponseQueueManagementExt ext = new ExpectedResponseQueueManagementExt(stdCtl);
            TestDataProvider.preventTrigger = true;
            ext.yesSystemUpdateClicked();
            ext.noSystemUpdateClicked();
            ext.yesStillWaitingClicked();
            //ext.noStillWaitingClicked();
            ext.rateResponse();
            
            ExpectedResponseQueueManagementExt.getChildCaseId(case1.Id);
            
        Test.stopTest();
        
        system.assertEquals('Awaiting Customer Response', case1.Status,
                            'when awaiting response clicked status remains unchanged.');
    }
    
    /**********************************************************************
     *  Scenario:
     *      Method to initialize the landing screen of myNetwork with investigation case and select specific case
     **********************************************************************/
    @isTest
    static void myUnitTest2() {
        
        Case case1 = [Select id, status from case limit 1];
        case1.status = 'Customer Responded';
        update case1;
                
        StatusTracking__c st = TestDataProvider.createTestStatusTracking();
        st.Case__c = case1.Id;
        st.StatusValue__c = 'Customer Responded';
        insert st;
        
        ExpectedResponseQueueManagement__c eq = TestDataProvider.createTestExpectedResponseQueueManagement();
        
        Test.startTest();
            
            ApexPages.StandardController stdCtl = new ApexPages.StandardController(case1);   
            ExpectedResponseQueueManagementExt ext = new ExpectedResponseQueueManagementExt(stdCtl);
            TestDataProvider.preventTrigger = true;
            ext.yesSystemUpdateClicked();
            ext.noSystemUpdateClicked();
            ext.yesStillWaitingClicked();
            ext.noStillWaitingClicked();
            ext.rateResponse();
            
            ExpectedResponseQueueManagementExt.getChildCaseId(case1.Id);
            
        Test.stopTest();
        
        system.assertEquals('Customer Responded', case1.Status,
                        'Not awaiting response, so status stays customer responded' );
    }
    
    /**********************************************************************
     *  Scenario:
     *      Method to initialize the landing screen of myNetwork with investigation case and select specific case
     **********************************************************************/
    @isTest
    static void myUnitTest3() {
        
        Case case1 = [Select id, status from case limit 1];
        case1.status = 'Network Responded';
        update case1;
        
        StatusTracking__c st = TestDataProvider.createTestStatusTracking();
        st.Case__c = case1.Id;
        st.StatusValue__c = 'Network Responded';
        insert st;
        
        ExpectedResponseQueueManagement__c eq = TestDataProvider.createTestExpectedResponseQueueManagement();
        
        Test.startTest();
            
            ApexPages.StandardController stdCtl = new ApexPages.StandardController(case1);   
            ExpectedResponseQueueManagementExt ext = new ExpectedResponseQueueManagementExt(stdCtl);
            TestDataProvider.preventTrigger = true;
            ext.yesSystemUpdateClicked();
            ext.noSystemUpdateClicked();
            ext.noStillWaitingClicked();
            ext.yesStillWaitingClicked();
            ext.rateResponse();
            
            ExpectedResponseQueueManagementExt.getChildCaseId(case1.Id);
            
        Test.stopTest();
        
        system.assertEquals('Network Responded', case1.Status,
                            'when awaiting response clicked status changes to Network Responded.');
		System.assertEquals(false, ext.isCaseTransfer, 'Test case has not been transferred');
    }
    
}