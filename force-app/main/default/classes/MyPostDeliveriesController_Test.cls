/**********************************************************************************
Description: Test class to cover MyPostDeliveriesController functionality.
***********************************************************************************/
@isTest
global class MyPostDeliveriesController_Test {

    @testSetup static void setup() {
        //Create an Account.
        Account acc = new Account(FirstName = 'James', LastName = 'Bond' , PersonEmail = 'J.Bond@austposttest.com.au', APCN__pc='123456789');
        Insert acc;

        //Insert AusPost setting
        AusPostSettings__c oa = new AusPostSettings__c();
        oa.Password__c = 'w@X2mb?SbMi%';
        oa.Username__c = 'sssw_sts';
        oa.URL__c = 'https://digitalapi-ptest.npe.auspost.com.au/auth/token';
        oa.URL2__c = 'https://digitalapi-ptest.npe.auspost.com.au/qac/pobLease/';
        oa.Name = 'SAP_SearchByProductParameters';
        insert oa;

    }

    /**
     * Test Method for Parcel Loacker Both
     */
    Static testMethod void testParcelLockerBoth() {
        test.startTest();
        Account acc = [SELECT id, APCN__pc FROM ACCOUNT limit 1];
        MyPostPreferences__x dp = new MyPostPreferences__x(APCN__c = '123456789' , HeightLessThan15M__c = 'Y', HeightMoreThan05M__c = 'Y', SafeDropInstruction__c = '');
        MyPostDeliveriesController.allPostPreferences.add(dp);
        ApexPages.StandardController stdCont = new ApexPages.standardController(acc);
        MyPostDeliveriesController ext = new MyPostDeliveriesController(stdCont);
        System.assertEquals(System.Label.ParcelLockerBoth, ext.message);
        test.stopTest();
    }

    /**
     * Test Method for Parcel Locker Above 5m
     */
    Static testMethod void testParcelLockerAbove() {
        test.startTest();
        Account acc = [SELECT id, APCN__pc FROM ACCOUNT limit 1];
        MyPostPreferences__x dp2 = new MyPostPreferences__x(APCN__c = '123456789' , HeightLessThan15M__c = 'Y', HeightMoreThan05M__c = 'N', SafeDropInstruction__c = '');
        MyPostDeliveriesController.allPostPreferences.add(dp2);
        ApexPages.StandardController stdCont = new ApexPages.standardController(acc);
        MyPostDeliveriesController ext = new MyPostDeliveriesController(stdCont);
        System.assertEquals(System.Label.ParcelLockerAbove, ext.message);
        test.stopTest();
    }

    /**
     * test method for delivery Preference Update
     */
    Static testMethod void testDeliveryPreferenceAndParcelLockerNA() {
        Account acc = [SELECT id, APCN__pc FROM ACCOUNT limit 1];
        MyPostPreferences__x dp2 = new MyPostPreferences__x(APCN__c = '123456789' , HeightLessThan15M__c = 'N', HeightMoreThan05M__c = 'N', SafeDropInstruction__c = 'at the front door');
        MyPostDeliveriesController.allPostPreferences.add(dp2);
        ApexPages.StandardController stdCont = new ApexPages.standardController(acc);
        MyPostDeliveriesController ext = new MyPostDeliveriesController(stdCont);
        //Populate picklist values
        ext.getselectedPreferences();

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MyPostHttpMock());
        //Click on edit button and open editable view
        ext.editMethod();
        //Set new delivery Preference
        ext.selectedDelPref = 'P';
        //click on save button and close the editable view
        ext.saveToSAP();
        //Click on edit button and open editable view
        ext.editMethod();
        //Click on Cancel button to cancel changes
        ext.cancel();
        //Click on edit button and open editable view
        ext.editMethod();
        //click on save button without updating Delivery Preference
        ext.saveToSAP();
        System.assertEquals(System.Label.ParcelLockerNA, ext.message);
        test.stopTest();
    }

    /**
     * Test Method for Parcel Loacker Below
     */
    Static testMethod void testParcelLockerBelow() {
        test.startTest();
        Account acc = [SELECT id, APCN__pc FROM ACCOUNT limit 1];
        MyPostPreferences__x dp2 = new MyPostPreferences__x(APCN__c = '123456789' , HeightLessThan15M__c = 'N', HeightMoreThan05M__c = 'Y', SafeDropInstruction__c = '');
        MyPostDeliveriesController.allPostPreferences.add(dp2);
        ApexPages.StandardController stdCont = new ApexPages.standardController(acc);
        MyPostDeliveriesController ext = new MyPostDeliveriesController(stdCont);
        System.assertEquals(System.Label.ParcelLockerBelow, ext.message);
        test.stopTest();
    }

    // HTTP Mock Class
    global class MyPostHttpMock implements HttpCalloutMock {
        global HttpResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            if(req.getEndpoint().endsWith('pobLease/')){
                res.setHeader('Content-Type', 'application/json');
                res.setHeader('x-csrf-token', 'token');
                //res.setStatus('OK');
                res.setStatusCode(200);
                res.setHeader('Set-Cookie', 'SAP_SESSIONID_TC0_031=testing');
                res.setBody('{"foo":"bar"}');
                return res;
            }
            else{
                res.setHeader('Content-Type', 'application/json');
                //res.setStatus('OK');
                res.setStatusCode(204);
                res.setHeader('Set-Cookie', 'SAP_SESSIONID_TC0_031=testing');
                res.setBody('{"foo":"bar"}');
                return res;
            }
        }
    }
}