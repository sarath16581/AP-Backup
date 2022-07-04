/**
 * @author Hasantha Liyanage
 * @date 2022-07-04
 * @group Chas
 * @tag EDD service
 * @tag DDS-10974
 * @domain Help & Support
 * @description EDD service estimate tests
 * @changelog
 * 2022-07-04 - Hasantha Liyanage - Created
 */
@IsTest
private class ChasEDDServiceEstimatesTest {
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
        System.assertNotEquals(null, ChasEDDServiceEstimates.getEDDEstimates('33LPL000061903000605008', '3000'));
        Test.stopTest();
    }
}