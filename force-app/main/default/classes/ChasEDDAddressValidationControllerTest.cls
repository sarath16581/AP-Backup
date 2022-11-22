/**
 * @author Hasantha Liyanage
 * @date 2022-08-10
 * @group Chas
 * @tag EDD service
 * @tag DDS-11627
 * @domain Help & Support
 * @description calculated EDD service estimate tests
 * @changelog
 * 2022-08-10 - Hasantha Liyanage - Created
 */
@IsTest
private class ChasEDDAddressValidationControllerTest {
    public static  ChasApexController.ConsignmentDetails testsearchTrackingNumberSetup(StaticResourceCalloutMock mock, String consType) {

        List< Consumer_Help_and_Support__c> customSettingList = new List< Consumer_Help_and_Support__c>();
        //-- setting some key and service URL as it wont hit a call for service from test cases
        Consumer_Help_and_Support__c setting = new Consumer_Help_and_Support__c();
        setting.API_Key_v2__c = 'ecc702f2-278a-4b84-aa1e-3e7dea3c6246';
        setting.Connection_Time_Out__c = 60000;
        setting.End_Point_1Track_Service_URL_v2__c ='https://digitalapi-ptest.npe.auspost.com.au/consignment-internal/v2/articles';
        setting.EDD_Service_API_Key__c = 'kjkjkjjklk';
        setting.EDD_Service_Connection_Time_Out__c = 50000;
        setting.End_Point_URL_EDD_Service__c ='https://digitalapi-stest.npe.auspost.com.au/shipment-edd/v1/shipments/';
        setting.EDDQueryParams__c='?postcode';
        setting.AP_Channel_Name__c ='HelpSupport';
        setting.SetupOwnerId=UserInfo.getOrganizationId();
        customSettingList.add(setting);
        //-- Inserting Custom setting
        insert customSettingList;

        ChasApexController.TrackingNumberDetails a = new ChasApexController.TrackingNumberDetails();
        a.articleType=null;
        a.deliveredByDateOrEDD=null;
        a.eddStatus = null;
        a.itemType = null;
        a.recipientCountry = null;
        a.senderCountry = null;
        a.trackingNumSerachStatusCode= null;
        a.trackingNumSerachStatusMsg = null;
        a.duplicateCase = null;
        a.latestEventLocation = 'LAVERTON VIC, 3028';
        a.latestEventLocationMessage = 'Delivered - Left in a safe place';
        a.enqSubtype = null;
        a.enqType = null;
        a.trackStatusValue = null;
        a.safedropDelivered = '2020-06-28 16:02:10';
        a.isReturnToSender = true;
        //Safedrop ineligible
        a.deliveryChoicesSafeDropIneligibilityCode = false;

        List<ChasApexController.TrackingNumberDetails> trackingNumberDetails = new List<ChasApexController.TrackingNumberDetails>();
        trackingNumberDetails.add(a);
        ChasApexController.ConsignmentDetails cons = new ChasApexController.ConsignmentDetails();
        cons.trackingNumberDetails = trackingNumberDetails;

        mock.setStaticResource(consType);
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');

        return cons;

    }
    // CHAS_NoEDD- EDD Service Estimates
    @IsTest
    public static void testEDDServiceEstimates_NoEDDFound() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        testsearchTrackingNumberSetup(mock,'CHAS_NoEDD');
        Test.startTest();
        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);
        ChasApexController.searchTrackingNumber('33LPL000061903000605008');
        Map <String,String> missingItemWizardData = new Map <String,String>();
        missingItemWizardData.put('trackingId','33LPL000061903000605008');
        missingItemWizardData.put('recipientPostcode','3000');
        System.assertNotEquals(null, ChasEDDAddressValidationController.getEDDEstimates('33LPL000061903000605008', '3000'));
        Test.stopTest();
    }
}