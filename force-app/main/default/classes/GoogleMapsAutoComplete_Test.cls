/**
 * Created by vcheng on 26/04/2021.
 */

@IsTest
private class GoogleMapsAutoComplete_Test {
    /*
    @TestSetup
    static void testSetup() {
        List<BCA_Settings__c> bcaSettings = new List<BCA_Settings__c>();

        BCA_Settings__c apiUrl = new BCA_Settings__c();
        apiUrl.Name = GoolgeMapsAutocompleteController.GMAPS_PLACE_API_URL_SETTING_NAME;
        apiUrl.Text_Value__c = 'test url';
        bcaSettings.add(apiUrl);
        BCA_Settings__c apiKey = new BCA_Settings__c();
        apiKey.Name = GoolgeMapsAutocompleteController.GMAPS_API_KEY_SETTING_NAME;
        apiKey.Text_Value__c = 'test key';
        bcaSettings.add(apiKey);

        insert bcaSettings;
    }

     */


    @IsTest
    static void testGetAutoCompleteSearch() {

        String input= '55 Collins street, Melbourne VIC, Australia';
        String types = 'geocode';
        String components = 'country:AU';
        String languages = 'en-AU';
        String radius = '10000';

        BCA_Settings__c apiUrl = new BCA_Settings__c();
        apiUrl.Name = GoolgeMapsAutocompleteController.GMAPS_PLACE_API_URL_SETTING_NAME;
        apiUrl.Text_Value__c = 'test url';


        // =====================================
        // Stubbing
        // =====================================

        // settings
        CustomsSettingsSelector settingsSelector = (CustomsSettingsSelector)MockUtility.mockSelector(CustomsSettingsSelector.class);

        // set up our responses
        Test.setMock(HttpCalloutMock.class, new GoolgeMapsAutocompleteController.MockHttpGoogleMapsResponseGenerator());

        // set up our responses
        MockUtility.Mocks.startStubbing();

        // Database
        MockUtility.Mocks.when(settingsSelector.selectByNames((Set<String>)fflib_Match.anyObject()))
                .thenReturn(new Map<String, BCA_Settings__c>{
                GoolgeMapsAutocompleteController.GMAPS_PLACE_API_URL_SETTING_NAME => apiUrl
        });
        MockUtility.Mocks.stopStubbing();


        // =====================================
        // Testing
        // =====================================
        Test.startTest();
        String gSearch = GoolgeMapsAutocompleteController.getAutoComplete(input, types, components, languages, radius);
        System.assertNotEquals(null, gSearch, 'Expected a result for getAutoComplete:' + gSearch);
        String gPlaces = GoolgeMapsAutocompleteController.getPlaceDetails('abcd');
        System.assertNotEquals(null, gPlaces, 'Expected a getPlaceDetails:' + gPlaces);

        Test.stopTest();
    }
}