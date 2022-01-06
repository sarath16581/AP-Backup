/**
  * @author       : Dheeraj Mandavilli<dheeraj.mandavilli@auspost.com.au>
  * @date         : 01/10/2019
  * @description  : Controller class for ameAddressValidation LWC component
--------------------------------------- History --------------------------------------------------
11.09.2019    Dheeraj Mandavilli    Created
05.08.2020    Disha Kariya          Added a method searchAddressOrGeoLocation to get Address or Geo Location using AME api
17-12-2020    Jansi (avula.jansirani@auspost.com.au)   Added getCountries() method
22.02.2021    Hara Sahoo    Added getAddressDetailsFromDPID which accepts dpid to return address string
**/
public with sharing class AMEAddressValidationController1 {
    static AusPostSettings__c addressValidationSetting = AusPostSettings__c.getValues('AMEAddressValidation');

    @AuraEnabled(cacheable = true)
    public static string searchAddress(String searchTerm){
        String url = addressValidationSetting.URL2__c + '?text=' + EncodingUtil.urlEncode(searchTerm, 'UTF-8');
        //String url='https://digitalapi-stest.npe.auspost.com.au/ame/api/v1/address' + '?text=' + EncodingUtil.urlEncode(searchTerm, 'UTF-8') ;
        String body='{"id":"377eac5d-8871-4567-aad1-c38f3cc34858","maxResults":10,"predictive":true,"addresses":[{"id":"2403b1e8-4832-4d39-982f-95d706bdfb2d","text":"'+searchTerm+'"}],"detail":{"singleLine":true}}';
        system.debug('SearchTerm::'+searchTerm);
        List<AMEInitialResponse.Result> results = postRequest(url, addressValidationSetting.Token__c,body);
        List<AMEInitialResponse.Address> addressList=results[0].addresses;
        system.debug('Address in  JSON:::'+addressList);
        String jsonUpdated=JSON.serialize(addressList);
        system.debug('Updated Json:::'+jsonUpdated);
        return jsonUpdated;
    }

    @AuraEnabled(cacheable = true)
    public static string getAddressDetails(String address){
        String url = addressValidationSetting.URL3__c + EncodingUtil.urlEncode(address, 'UTF-8') + '?singleLine=true&semiStructured=true&structured=true&upu=true&geo=true&delivery=true';
        // String url= 'https://digitalapi-stest.npe.auspost.com.au/ame/api/v1/dpid' + '/85865442'+ '?singleLine=true&semiStructured=true&structured=true&upu=true&geo=true&delivery=true';
       // String url= 'https://digitalapi-stest.npe.auspost.com.au/ame/api/v1/dpid/' + EncodingUtil.urlEncode(address, 'UTF-8') +'?singleLine=true&semiStructured=true&structured=true&upu=true&geo=true&delivery=true';
        return sendRequest(url, addressValidationSetting.Token__c);
    }
    @AuraEnabled(cacheable = true)
    public static String getAddressDetailsFromDPID(String dpid){
        String url = addressValidationSetting.URL_DPID__c + EncodingUtil.urlEncode(dpid, 'UTF-8') + '?singleLine=true&semiStructured=true&structured=true&upu=true&geo=true&delivery=true';
        return sendRequest(url, addressValidationSetting.Token__c);
    }

    /**
     * @Description: Method will return Address details or Geo Locations for every Article from AME api call by passing unique Id as Article Id and '-GTA' or '-ATG'
     */
    public static Map<String, String> searchAddressOrGeoLocation(Map<String,String> geoLocations) {
        String url = addressValidationSetting.URL2__c;
        Set<String> validConfidence = new Set<String>{
                'HIGH', 'MEDIUM'
        };
        Map<String, String> articleAddressesMap = new Map<String, String>();
        //String url='https://digitalapi-stest.npe.auspost.com.au/ame/api/v1/address' + '?text=' + EncodingUtil.urlEncode(searchTerm, 'UTF-8') ;
        //String body='{"id":"377eac5d-8871-4567-aad1-c38f3cc34858","maxResults":10,"predictive":true,"addresses":[{"id":"2403b1e8-4832-4d39-982f-95d706bdfb2d","text":"'+searchTerm+'"}],"detail":{"singleLine":true}}';
        //system.debug('SearchTerm::'+searchTerm);

        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeStringField('id', '377eac5d-8871-4567-aad1-c38f3cc34858');
        gen.writeNumberField('maxResults', 1);
        gen.writeFieldName('addresses');
        gen.writeStartArray();
        for (String geoLocation : geoLocations.keySet()) {
            //gta is for Geolocation To Address
            if (geoLocation.containsIgnoreCase('-GTA')) {
                gen.writeStartObject();
                gen.writeStringField('id', geoLocation);
                gen.writeFieldName('geocoord');
                gen.writeStartObject();
                List<String> values = geoLocations.get(geoLocation).split(',');
                gen.writeStringField('latitude', values[0]);
                gen.writeStringField('longitude', values[1]);
                gen.writeEndObject();
                gen.writeEndObject();
            } else if (geoLocation.containsIgnoreCase('-ATG')) {
                //atg is for Address To Geolocation
                gen.writeStartObject();
                gen.writeStringField('id', geoLocation);
                gen.writeStringField('text', geoLocations.get(geoLocation));
                gen.writeEndObject();
            }
        }
        gen.writeEndArray();
        gen.writeFieldName('detail');
        gen.writeStartObject();
        gen.writeBooleanField('singleLine', true);
        gen.writeBooleanField('geo', true);
        gen.writeEndObject();
        gen.writeFieldName('filters');
        gen.writeStartObject();
        gen.writeStringField('addressType', 'THOROUGHFARE');
        gen.writeEndObject();
        gen.writeEndObject();
        System.debug('gen.getAsString()--->' + gen.getAsString());
//        return postRequest(url, addressValidationSetting.Token__c,gen.getAsString());
        List<AMEInitialResponse.Result> results = postRequest(url, addressValidationSetting.Token__c, gen.getAsString());
        for (AMEInitialResponse.Result result : results) {
            if (result.addresses.size() > 0) {
                if (validConfidence.contains(result.addresses[0].confidence)) {
                    if (result.id.containsIgnoreCase('-GTA') && String.isNotBlank(result.addresses[0].singleLine)) {
                        articleAddressesMap.put(result.id, result.addresses[0].singleLine);
                    } else if (result.id.containsIgnoreCase('-ATG') && result.addresses[0].geoDataList.size() > 0) {
                        articleAddressesMap.put(result.id, String.valueOf(result.addresses[0].geoDataList[0].latitude) + ',' + String.valueOf(result.addresses[0].geoDataList[0].longitude));
                    }
                } else if (result.id.containsIgnoreCase('-ATG') && result.addresses[0].geoDataList.size() > 0) {
                    //When not HIGH or MEDIUM confidence result returned then send low confidence geolocation for
                    articleAddressesMap.put(result.id, String.valueOf(result.addresses[0].geoDataList[0].latitude) + ',' + String.valueOf(result.addresses[0].geoDataList[0].longitude));
                }
            }else {
                //Add blank value if no address details received from AME
                articleAddressesMap.put(result.id, '');
            }
        }
        system.debug('Address in  JSON:::'+articleAddressesMap);
        return articleAddressesMap;
    }

    public static String sendRequest(String url, String token) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('GET');
        req.setHeader('AUTH-KEY', token);

        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res);
        system.debug('Response Body:::'+res.getBody());

        String jsonAddressString =res.getBody();
        AMEFinalResponse addrResponse = AMEFinalResponse.parse(jsonAddressString);
        List<AMEFinalResponse.Result> results=addrResponse.results;
        system.debug('Results in  JSON:::'+results);
        List<AMEFinalResponse.Address> addressAttributes=results[0].addresses;
        system.debug('Address in  JSON:::'+addressAttributes);
        string addressJSON=JSON.serialize(addressAttributes);
        system.debug('addressJSON Json:::'+addressJSON);
        return addressJSON;
    }

    public static List<AMEInitialResponse.Result> postRequest(String url, String token,String body ) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('POST');
        req.setHeader('Content-Type','application/json;charset=UTF-8');
        req.setHeader('AUTH-KEY',token);
        req.setBody(body);
        Http http = new Http();
        HTTPResponse res = http.send(req);

            System.debug(res);
            system.debug('Response Body:::'+res.getBody());

            String jsonString=res.getBody();
            AMEInitialResponse response = (AMEInitialResponse) System.JSON.deserialize(jsonString, AMEInitialResponse.class);
//            List<AMEInitialResponse.Result> results=response.results;
//            system.debug('Results in  JSON:::'+results);
//            List<AMEInitialResponse.Address> addressList=results[0].addresses;
//            system.debug('Address in  JSON:::'+addressList);
//            String JsonUpdated=JSON.serialize(addressList);
//            system.debug('Updated Json:::'+JsonUpdated);

        return response.results;
    }
    /**
    * Get List of the countries for address LWC cmp
    * */
    @AuraEnabled(cacheable = true)
    public static List<SelectOptionCustom> getCountries() {
        // this function generates picklist values
        List<SelectOptionCustom> options = new List<SelectOptionCustom>();
        Map<String, CountryCodes__c> countries = CountryCodes__c.getAll();
        List<String> countryCodes = new List<String>();
        countryCodes.addAll(countries.keySet());
        countryCodes.sort();
        for( String countryCode : countryCodes){
            CountryCodes__c country = countries.get(countryCode);
            options.add(new SelectOptionCustom(country.Name,country.Name));
        }
        return options;
    }
    
    
    /**
    * Custom select Option: Added this because standard SelectOption class is not supported by LWC
    * */
    public class SelectOptionCustom {
        public SelectOptionCustom(String value, String label) {
            this.value = value;
            this.label = label;
            this.disabled = false;
            this.escapeItem = false;
        }
        
        /*public SelectOptionCustom(String value, String label, Boolean isDisabled) {
            this.value = value;
            this.label = label;
            this.disabled = isDisabled;
            this.escapeItem = false;
        }*/
        
        @AuraEnabled public String label { get;set; }
        @AuraEnabled public String value { get;set; }
        @AuraEnabled public Boolean disabled { get;set; }
        @AuraEnabled public Boolean escapeItem { get;set; }
        
    }
}