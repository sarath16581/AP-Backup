/**
 * Created by hasantha on 27/09/2018.
 */
@isTest
public with sharing class Cognition_IAsynchApexContinuationTest {

    @testSetup
    static void testData(){
        Id RecTypeId = Schema.SObjectType.Authorization_Rule__c.getRecordTypeInfosByName().get('Cognition Rules').getRecordTypeId();
        CustomerCognitionSettings__c settings = CustomerCognitionSettings__c.getOrgDefaults();
        settings.MaxAccountsforInternal__c = 10;
        settings.AuthorizationRuleRecordTypeID__c = RecTypeId;
        settings.BasicAuthnHeader__c = 'U0ZDdXN0b21lckNvZ25pdGlvblBURVNUOiRGQ3VzdEMwZ25pdGkwbg';
        upsert settings CustomerCognitionSettings__c.Id;

        List < CognitionAPIs__c > ListSettings = new List < CognitionAPIs__c > ();
        
        //setup ConsignmentInfo endpoint custome setting
        CognitionAPIs__c setting = new CognitionAPIs__c();
        setting.Name = 'ConsignmentInfo';
        setting.API_Name__c = 'Cognition/v1/ConsignmentInfo';
        setting.Error_Message__c = 'Unable to fetch Consignment details';
        setting.Timeout__c = 15000;
        ListSettings.add(setting);
        
        //setup PickupInfo endpoint custome setting
        CognitionAPIs__c setting9 = new CognitionAPIs__c();
        setting9.Name = 'PickupInfo';
        setting9.API_Name__c = 'Cognition/v1/PickupInfo';
        setting9.Error_Message__c = 'Unable to fetch Pickup booking details';
        ListSettings.add(setting9);
        
        //setup CustomerDetails endpoint custome setting
        CognitionAPIs__c setting1 = new CognitionAPIs__c();
        setting1.Name = 'CustomerDetails';
        setting1.API_Name__c = 'Cognition/v1/CustomerDetails';
        setting1.Error_Message__c = 'Unable to fetch Consignment details';
        ListSettings.add(setting1);
        
        //setup Consignmentsignment ReportData endpoint custome setting
        CognitionAPIs__c setting2 = new CognitionAPIs__c();
        setting2.Name = 'ConsignmentReportData';
        setting2.API_Name__c = 'Cognition/v1/ReportData';
        setting2.Error_Message__c = 'Unable to fetch report data';
        setting2.Timeout__c = 15000;
        ListSettings.add(setting2);
        
        //setup SubmitQuery endpoint custome setting
        CognitionAPIs__c setting3 = new CognitionAPIs__c();
        setting3.Name = 'SubmitQuery';
        setting3.API_Name__c = 'Cognition/v1/SubmitQuery';
        setting3.Error_Message__c = 'Error while requesting data';
        ListSettings.add(setting3);
        
        //setup CustomerSummary endpoint custome setting
        CognitionAPIs__c setting4 = new CognitionAPIs__c();
        setting4.Name = 'CustomerSummary';
        setting4.API_Name__c = 'Cognition/v1/CustomerSummary';
        setting4.Error_Message__c = 'Error while getting customer summary data';
        ListSettings.add(setting4);
        
        //setup QueryStatus endpoint custome setting
        CognitionAPIs__c setting5 = new CognitionAPIs__c();
        setting5.Name = 'QueryStatus';
        setting5.API_Name__c = 'Cognition/v1/QueryStatus';
        setting5.Error_Message__c = 'Error while getting consignment status';
        ListSettings.add(setting5);
        
        //setup Timeout endpoint custome setting
        CognitionAPIs__c setting6 = new CognitionAPIs__c();
        setting6.Name = 'Timeout';
        setting6.API_Name__c = 'Cognition/v1/ReceiverETA';
        setting6.Error_Message__c = 'Unable to fetch Consignment details';
        setting6.Timeout__c = 4000;
        ListSettings.add(setting6);
        
        //setup CustomersNotFound endpoint custome setting
        CognitionAPIs__c setting7 = new CognitionAPIs__c();
        setting7.Name = 'CustomersNotFound';
        setting7.Error_Message__c = 'No customers were found.';
        ListSettings.add(setting7);
        
        //setup ReceiverETA endpoint custome setting
        CognitionAPIs__c setting8 = new CognitionAPIs__c();
        setting8.Name = 'ReceiverETA';
        setting8.API_Name__c = 'Cognition/v1/ReceiverETA';
        setting8.Error_Message__c = 'Error while getting consignment status';
        ListSettings.add(setting8);

        insert ListSettings;
    }

    /**
     * Testing of consignment info request, Consignment details.
     * details will be displayed when a user does a search through a search box
     */
    @isTest static void testContinuation_ConsignmentInfo(){
        list<string> sLst  = new list<String>{'2d0a3541-12f7-97f2-dcc9-79e4cffba600','50623188ABCD',''};
        StaticResource StaticResourceConsignmentInfo = [select id, body from StaticResource Where Name = 'Cognition_Test_ConsignmentInfo'];
        String resourceConsignmentInfo = StaticResourceConsignmentInfo.body.toString();
        Test.startTest();
        Continuation conti =  (Continuation)AsynchApexContinuationController.invoke('Cognition_IAsynchApexContinuationImpl','ConsignmentInfo',sLst,true);
        Map<String, HttpRequest> requests = conti.getRequests();
        String requestLabel = requests.keyset().iterator().next();
        HttpResponse response = new HttpResponse();
        response.setBody(resourceConsignmentInfo);
        Test.setContinuationResponse(requestLabel, response);
        AsynchApexContinuationController.statInfo sInfo = new AsynchApexContinuationController.statInfo();
        sInfo.continuationId = requestLabel;
        sInfo.classname = 'Cognition_IAsynchApexContinuationImpl';
        sInfo.params = sLst;
        object rtnObj = AsynchApexContinuationController.restCallback(sInfo);

        test.stopTest();

        // test response call back
        Cognition_IAsynchApexContinuationImpl conAsyncImpl = new Cognition_IAsynchApexContinuationImpl();
        HttpRequest req = new HttpRequest();
        list<String> strLst = new list<String>{'1'};
        conAsyncImpl.setHTTPRequest(req, 'Cognition_IAsynchApexContinuationImpl','ConsignmentInfo',sLst);
        
        //biuld mock response
        HttpResponse httpResp = new HttpResponse();
    	Cognition_IAsynchApexContinuationImpl.HttpResponseInfo testInfo = new Cognition_IAsynchApexContinuationImpl.HttpResponseInfo();
    	Cognition_DataModel.CustomerViewConInfo temp = new Cognition_DataModel.CustomerViewConInfo();
    	temp.Consignment = '1';
    	testInfo.payload = JSON.serialize(temp);
    	testInfo.methodName = 'ConsignmentInfo';
    	httpResp.setBody(JSON.serialize(testInfo));
    	//biuld mock response end 
    	
    	Object objTmp = conAsyncImpl.parseResponse(httpResp);
    	
    	System.assert(((Cognition_DataModel.CustomerViewConInfo)objTmp).Consignment == '1');
    }

    /**
     * Testing of Customer Details request, this is to populate markers and the basic consignment details on the map,
     * method is being called after a selecting a customer from the customer dropdown
     * uses custom built Async mechanism to call the endpoints (Continuous, calls cannot be directly called from lightning as of current version)
     */
    @isTest static void testContinuation_CustomerDetails(){
        list<string> sLst  = new list<String>{'2d0a3541-12f7-97f2-dcc9-79e4cffba600', '0' ,'1000'};
        StaticResource StaticResourceCustomerDetailsInfo = [select id, body from StaticResource Where Name = 'Cognition_Test_CustomerDetails'];
        String resourceCustomerDetailsInfo = StaticResourceCustomerDetailsInfo.body.toString();
        Test.startTest();
        Continuation conti =  (Continuation)AsynchApexContinuationController.invoke('Cognition_IAsynchApexContinuationImpl','CustomerDetails',sLst,true);
        Map<String, HttpRequest> requests = conti.getRequests();
        String requestLabel = requests.keyset().iterator().next();
        HttpResponse response = new HttpResponse();
        response.setBody(resourceCustomerDetailsInfo);
        Test.setContinuationResponse(requestLabel, response);
        AsynchApexContinuationController.statInfo sInfo = new AsynchApexContinuationController.statInfo();
        sInfo.continuationId = requestLabel;
        sInfo.classname = 'Cognition_IAsynchApexContinuationImpl';
        sInfo.params = sLst;
        object rtnObj = AsynchApexContinuationController.restCallback(sInfo);
        System.assert(rtnObj == null,'Error returning API payload' );
        test.stopTest();

        // test response call back
        Cognition_IAsynchApexContinuationImpl conAsyncImpl = new Cognition_IAsynchApexContinuationImpl();
        HttpRequest req = new HttpRequest();
        list<String> strLst = new list<String>{'1'};
        conAsyncImpl.setHTTPRequest(req, 'Cognition_IAsynchApexContinuationImpl','CustomerDetails',sLst);
        HttpResponse httpResp = new HttpResponse();
    	Cognition_IAsynchApexContinuationImpl.HttpResponseInfo testInfo = new Cognition_IAsynchApexContinuationImpl.HttpResponseInfo();
    	
    	//biuld mock response
    	Cognition_DataModel.CustomerViewDetailRequest cvdr = new Cognition_DataModel.CustomerViewDetailRequest();
    	cvdr.RequestGUID = '2d0a3541-12f7-97f2-dcc9-79e4cffba600';
    	cvdr.Type = 1;
    	cvdr.Action = 2;
    	cvdr.FromSeq = 0;
    	cvdr.ToSeq = 600;
    	cvdr.ClientIpAddress = '::1';
    	cvdr.ClientUserName = 'test';
    	
    	Cognition_DataModel.cls_ConInfo cc = new Cognition_DataModel.cls_ConInfo();
    	cc.Consignment = 'HESZ11768613';
        cc.BookingNbr = '';
        cc.Type = 2;  
        cc.EventDateTime = 'Date(1516060882000+1100)'; 
        cc.Latitude = -37.75667618908637;
        cc.Longitude = 145.05924945; 
        
        Cognition_DataModel.cls_ConInfo[] ccArr = new Cognition_DataModel.cls_ConInfo[]{cc};
        
    	Cognition_DataModel.CustomerViewDetailResponseV2 temp = new Cognition_DataModel.CustomerViewDetailResponseV2();
    	temp.Request = cvdr;
    	temp.ConInfo = ccArr;

    	testInfo.payload = JSON.serialize(temp);
    	testInfo.methodName = 'CustomerDetails';
    	httpResp.setBody(JSON.serialize(testInfo));
    	//biuld mock response end

    	Object objTmp = conAsyncImpl.parseResponse(httpResp);
    	
    	System.assert(((Cognition_DataModel.CustomerDetailsResponse)objTmp).conInfo.size()==1);
    }

    /**
     * Testing of pickup info request, Pickup booking details.
     * details will be displayed when a user does a search through a search box,
     * uses custom built Async mechanism to call the endpoints (Continuous, calls cannot be directly called from lightning as of current version)
     */
    @isTest static void testContinuation_PickupInfo(){
    	list<string> sLst  = new list<String>{'2d0a3541-12f7-97f2-dcc9-79e4cffba600','5291790',''};
    	StaticResource StaticResourcePickupInfo = [select id, body from StaticResource Where Name = 'Cognition_Test_PickupInfo'];
    	String resourcePickupInfo = StaticResourcePickupInfo.body.toString();
    	Test.startTest();
    	Continuation conti =  (Continuation)AsynchApexContinuationController.invoke('Cognition_IAsynchApexContinuationImpl','PickupInfo',sLst,true);
    	Map<String, HttpRequest> requests = conti.getRequests();
    	String requestLabel = requests.keyset().iterator().next();
    	HttpResponse response = new HttpResponse();
    	response.setBody(resourcePickupInfo);
    	Test.setContinuationResponse(requestLabel, response);
    	AsynchApexContinuationController.statInfo sInfo = new AsynchApexContinuationController.statInfo();
    	sInfo.continuationId = requestLabel;
    	sInfo.classname = 'Cognition_IAsynchApexContinuationImpl';
    	sInfo.params = sLst;
    	object rtnObj = AsynchApexContinuationController.restCallback(sInfo);
    	System.assert(rtnObj == null,'Error returning API payload' );
    	test.stopTest();
    
    	// test response call back
    	Cognition_IAsynchApexContinuationImpl conAsyncImpl = new Cognition_IAsynchApexContinuationImpl();
    	HttpRequest req = new HttpRequest();
    	list<String> strLst = new list<String>{'1'};
    	conAsyncImpl.setHTTPRequest(req, 'Cognition_IAsynchApexContinuationImpl','PickupInfo',sLst);
    	
    	//biuld mock response
    	HttpResponse httpResp = new HttpResponse();
    	Cognition_IAsynchApexContinuationImpl.HttpResponseInfo testInfo = new Cognition_IAsynchApexContinuationImpl.HttpResponseInfo();
    	Cognition_DataModel.CustomerViewPickupInfo testPickup = new Cognition_DataModel.CustomerViewPickupInfo();
    	testPickup.BookingNbr = '5291790';
    	testInfo.payload = JSON.serialize(testPickup);
    	testInfo.methodName = 'PickupInfo';
    	testInfo.errorList = new String[]{'test','test1'};
    	testInfo.params = new String[]{'test','test1'};
    	testInfo.className = 'test';
    	httpResp.setBody(JSON.serialize(testInfo));
    	//biuld mock response end 
    	
    	Object objTmp = conAsyncImpl.parseResponse(httpResp);
    	System.assert(((Cognition_DataModel.CustomerViewPickupInfo)objTmp).BookingNbr == '5291790');
    	
    	CustomerCognitionSettings__c testSetting = Cognition_IAsynchApexContinuationImpl.customerCognitionSettings;
    	System.assert(testSetting != null);
    }
}