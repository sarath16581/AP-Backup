/**
 * Created by nmain on 4/22/2016.
 */
// if you dont use 'SeeAllData' then you wont be able to read the custom settings that store the Service Details.
@isTest(SeeAllData=true)
private class SmartSpeakRestAPI_Test {

    static testMethod void testBehavior() {
        test.startTest();

        test.setMock(HttpCalloutMock.class, new testHttpCalloutMock());

        MpbHspCallMeBackRestController controller = new MpbHspCallMeBackRestController();
        SmartSpeakRestAPI smartSpeakRestAPI = new SmartSpeakRestAPI();
        controller.retrieveUserAndContact();

        system.debug('TEST CLASS - controller.loginContactId:' + controller.loginContactId);
        system.debug('controller.smartSpeakRestAPI.timeout: '+controller.smartSpeakRestAPI.timeout);

        controller.requestMethod = 'POST';
        controller.requestBody = '';
        controller.callout();

        test.stopTest();

    }
}