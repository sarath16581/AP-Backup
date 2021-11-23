/**
 * @description       : This class is used by LWC component to retrieve the Auto Suggestions
 *                      from Google Place APIs
 * @author            : Ankur Gandhi
 * @last modified on  : 05-20-2021
 * @last modified by  : ankur.gandhi@auspost.com.au
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   03-15-2021   ankur.gandhi@auspost.com.au          Initial Version
**/
public without sharing class GoolgeMapsAutocompleteController {

    public static final String GMAPS_API_KEY_SETTING_NAME = 'Google_Maps_API_Key';
    public static final String GMAPS_PLACE_API_URL_SETTING_NAME = 'Google_Maps_Place_API_URL';

    @AuraEnabled(cacheable = true)
    public static string getAutoComplete(String input, String types, String components, string languages, string radius) {
        String url = getTextValueFromBCASettings(GMAPS_PLACE_API_URL_SETTING_NAME) + '/autocomplete/json?input='
            + EncodingUtil.urlEncode(input, 'UTF-8')
            + '&components=' + components
            + '&types=' + types
            + '&language=' + languages
            + '&radius=' + radius
            + '&key=' + getTextValueFromBCASettings(GMAPS_API_KEY_SETTING_NAME);

        PlaceAutocompleteResponse results = PlaceAutocompleteResponse.parse(makeAPICall(url));
        System.debug('Parse Results :: ' + results);
        return JSON.serialize(results);
    }

    @AuraEnabled(cacheable = true)
    public static string getPlaceDetails(String placeId) {
        String url = getTextValueFromBCASettings(GMAPS_PLACE_API_URL_SETTING_NAME) + '/details/json?place_id=' + placeId
            + '&key=' + getTextValueFromBCASettings(GMAPS_API_KEY_SETTING_NAME);

        PlaceDetailsResponse results = PlaceDetailsResponse.parse(makeAPICall(url));
        System.debug('Parse Results :: ' + results);
        return JSON.serialize(results);
    }

    //Makes the REST API Call
    private static string makeAPICall(string url) {

        Http http = new Http();
        HttpRequest httpRequest = new HttpRequest();
        HttpResponse httpResponse = new HttpResponse();
        httpRequest.setMethod('GET');
        httpRequest.setEndpoint(url);
        httpRequest.setTimeout(120000);
        httpResponse = http.send(httpRequest); 

        if (httpResponse.getStatusCode() == 200){
            System.debug('Result from Google API :: ' + httpResponse.getBody());
            return httpResponse.getBody();    
        }

        return '';
    }

    //Get the maps api url from bca custom settings.
    private static String getTextValueFromBCASettings(String settingName) {

        Set<SObjectField> fields = new Set<SObjectField>{BCA_Settings__c.Name, BCA_Settings__c.Text_Value__c};
        CustomsSettingsSelector settingsSelector = CustomsSettingsSelector.newInstance(BCA_Settings__c.SObjectType, fields);

        List<BCA_Settings__c> settings = (List<BCA_Settings__c>) settingsSelector.selectByNames(new Set<String> {settingName}).values();

        if(settings.size() == 1)
        {
            return settings[0].Text_Value__c;
        }
        return null;
    }


    public class MockHttpGoogleMapsResponseGenerator implements HttpCalloutMock {
        // Implement this interface method
        public HTTPResponse respond(HTTPRequest req) {

            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"userToken":"token"}');
            res.setStatusCode(200);
            return res;
        }
    }
}