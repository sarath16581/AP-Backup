/****************************************************************************************
Author:         N/A
Description:    ScheduledJobTokenRequest
History:
-----------------------------------------------------------------------------------------
28-06-2018      heguang.miao@coroma.com.au	        Updated [TDO-144] Optimise test cases.
*****************************************************************************************/

@isTest
private class TestScheduledJobTokenRequest {

    @testSetup
    static void testDataSetup() {
        // Inject settings
        AusPostSettings__c settings = new AusPostSettings__c(
                Token__c = 'ABC',
                Name = 'AddressValidation',
                URL__c = 'https://digitalapi-pdev.npe.auspost.com.au/auth/token'
        );

        settings.ApplicationName__c = 'APP NAME';
        settings.AppKey__c = 'APP KEY';
        settings.ServiceName__c = 'SERVICE NAME';
        settings.TokenDuration__c = '100';
        insert settings;
    }

    /**
     * SCENARIO: execute the job and get token refreshed
     */
    @IsTest
    static void ScheduledJobTokenRequest_execute() {

        // Mock the http response which generates a token
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Get the current user
        Id myId = Id.valueOf(UserInfo.getUserId());
        Id myProfileId = Id.valueOf(UserInfo.getProfileId());
        User currentUser = [SELECT Id FROM User WHERE Id != :myId AND ProfileId = :myProfileId AND IsActive = true LIMIT 1];

        System.runAs(currentUser) {
            Test.startTest();

            // NOTE: In the original class, updateToken is bypassed. Here we have to manually call this method
            AddressValidationService.updateToken();
            Test.stopTest();

            AusPostSettings__c settings = AusPostSettings__c.getValues('AddressValidation');

            System.assertEquals('token', settings.Token__c,
                    'ScheduledJobTokenRequest_execute : token should be refreshed based on http response');
        }
    }
    /**
     * SCENARIO: schedule a job
     */
    @isTest
    static void ScheduledJobTokenRequest_schedule() {
        // Get the current user
        Id myId = Id.valueOf(UserInfo.getUserId());
        Id myProfileId = Id.valueOf(UserInfo.getProfileId());
        User currentUser = [SELECT Id FROM User WHERE Id != :myId AND ProfileId = :myProfileId AND IsActive = true LIMIT 1];

        System.runAs(currentUser) {
            Test.startTest();
            String jobId = ScheduledJobTokenRequest.schedule();
            Test.stopTest();

            System.assertNotEquals(null, jobId,
                    'ScheduledJobTokenRequest_schedule : a job should be scheduled');
        }
    }
}