/**
* @author       : haraprasad.sahoo@auspost.com.au
* @date         : 14/08/2020
* @description  : Test class for Testing scenarios on chasSafeDropController
* History
--------------------------------------------------
26/05/2020 - Hara Sahoo Created
*/
@isTest
public class chasSafeDropControllerTest {
    @testSetup public static void setup(){
        AusPostSettings__c addressValidationSetting = new AusPostSettings__c(); 
        addressValidationSetting.Name = 'AMEAddressValidation';
        addressValidationSetting.Token__c = 'O63igHoZbTNBIPQFRAxbjbPaMQHyoHNR';
        addressValidationSetting.URL2__c = 'https://digitalapi-stest.npe.auspost.com.au/ame/api/v1/address?text=';
        addressValidationSetting.URL_DPID__c = 'https://digitalapi-stest.npe.auspost.com.au/ame/api/v1/dpid/' + '85865442' +'?singleLine=true&semiStructured=true&structured=true&upu=true&geo=true&delivery=true';
        insert addressValidationSetting;
    }
    
    public static  ChasSafeDropController.ResponseWrapper testsearchTrackingNumberSetup(StaticResourceCalloutMock mock, String consType, Integer returnCode) {
        
        // Data Preparation - Insert custom setting
        Consumer_Help_and_Support__c setting = new Consumer_Help_and_Support__c(
            End_Point_Safedrop_Service_URL__c = 'https://digitalapi-ptest.npe.auspost.com.au/safedropimage/v1/articles/',
            Safedrop_API_Key__c = 'ecc702f2',
            Safedrop_Connection_Time_Out__c = '10000',
            AP_Channel_Name__c = 'HelpSupport',
            SetupOwnerId = UserInfo.getOrganizationId()
        );
        insert setting;
        
        ChasSafeDropController.ResponseWrapper a = new ChasSafeDropController.ResponseWrapper();
        a.safeDropGuid='d2b85736-816c-4e78-8eb6-b32cf9c00d21';
        a.statusCode=returnCode;
        mock.setStaticResource(consType);
        mock.setStatusCode(returnCode);
        mock.setHeader('Content-Type', 'application/json');
        
        return a;
        
    }
    
    public static testMethod void testMRSWith200SuccessfulResponse() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        testsearchTrackingNumberSetup(mock,'CHAS_MRSService',200);
        
        Test.startTest();
        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);
        
        chasSafeDropController.responseWrapper response = chasSafeDropController.getSafeDropGuid('trackingnumber');
        
        Test.stopTest();
        System.assertEquals(200,response.statusCode);
    }
    public static testMethod void testMRSWith204SuccessfulResponse() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        testsearchTrackingNumberSetup(mock,'CHAS_MRSService',204);
        
        Test.startTest();
        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);
        
        chasSafeDropController.responseWrapper response = chasSafeDropController.getSafeDropGuid('trackingnumber');
        
        Test.stopTest();
        System.assertEquals(204,response.statusCode);
    }
    public static testMethod void testgetAMEAddressString() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AMEAddressValidationController1_Test.webServiceMockResponse2());
        String json = chasSafeDropController.getAMEAddressString('44481778');
        system.assert(String.isNotEmpty(json));
        Test.stopTest();
    }
    
    
    /**
*	Scenario: Api call to Safe Drop is made and returns a successful response.
*/
    @IsTest
    public static void testRetrieveSafeDropImageSuccessResponse() {
        
        // =====================================
        // Data Preparation
        SafeDropUtility_Test.insertAuthSettings();
        // =====================================
        // None!
        
        // =====================================
        // Stubbing
        // =====================================
        SafeDropUtility mockSafeDropUtility = (SafeDropUtility)MockUtility.mockUtility(SafeDropUtility.class);
        
        // set up our responses
        MockUtility.Mocks.startStubbing();
        MockUtility.Mocks.when(mockSafeDropUtility.getHttpRequest(fflib_Match.anyString())).thenReturn(new HttpRequest());
        MockUtility.Mocks.stopStubbing();
        
        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        
        // Invoke the continuation
        Continuation cont = (Continuation)chasSafeDropController.getSafeDropImage('TEST');
        
        
        // setup the continuation mock provider
        String requestLabel = new List<String>(cont.getRequests().keySet())[0];
        chasSafeDropController.ContinuationState state = new chasSafeDropController.ContinuationState();
        state.httpRequestLabel = requestLabel;
        state.safeDropGuid = 'Test';
        SafeDropUtility_Test.setSuccessContinuationResponse(requestLabel);
        String response = (String)chasSafeDropController.callback(state);
        Test.stopTest();
        
        System.assertEquals(false, response == null, 'Expected no errors but instead got: ' + response);
    }
}