/**
  * @author       : Dheeraj Mandavilli<dheeraj.mandavilli@auspost.com.au>
  * @date         : 01/10/2019
  * @description  : Controller class for ameAddressValidation LWC component
--------------------------------------- History --------------------------------------------------
11.09.2019    Dheeraj Mandavilli    Created
12.08.2020    Disha Kariya          Added a mock class for searchAddressByGeoCode and searchGeoLocationByAddress called from MyNetworkCaseListControllerTest
24.04.2021    Hara Sahoo            Added test method to get adrress by passing dpid LookupController_getAddressDetailsFromDPID
02.06.2021    Jansi Rani            Added test method to test getcountries method.
**/
@isTest
global class AMEAddressValidationController1_Test {
    @testSetup public static void setup(){
        AusPostSettings__c setting = new AusPostSettings__c(); 
        setting.Name = 'AMEAddressValidation';
        setting.Token__c = 'O63igHoZbTNBIPQFRAxbjbPaMQHyoHNR';
        setting.URL2__c = 'https://digitalapi-stest.npe.auspost.com.au/ame/api/v1/address?text=';
        setting.URL3__c = 'https://digitalapi-stest.npe.auspost.com.au/ame/api/v1/dpid/' + '85865442' +'?singleLine=true&semiStructured=true&structured=true&upu=true&geo=true&delivery=true';
        setting.URL_DPID__c = 'https://digitalapi-stest.npe.auspost.com.au/ame/api/v1/dpid/' + '85865442' +'?singleLine=true&semiStructured=true&structured=true&upu=true&geo=true&delivery=true';
        insert setting;
    }
    
    @isTest 
    public static void LookupController_searchAddress(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new WebServiceMockResponseSingleLine());
        String json2 = AMEAddressValidationController1.searchAddress('55 Collins');
        Test.stopTest();
        System.assertNotEquals('', json2, 'Result not returned from mock');
    }
    
    @isTest
    public static void LookupController_getAddressDetails(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new WebServiceMockResponse2());
        //String url = AMEAddressValidationController1.getAddressDetails('55 Collins');
        String json1=AMEAddressValidationController1.getAddressDetails('85865442');
        Test.stopTest();
        System.assertNotEquals('', json1, 'Result not returned from mock');
    }
    @isTest
    public static void LookupController_getAddressDetailsFromDPID(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new webServiceMockResponse2());
        String json1=AMEAddressValidationController1.getAddressDetailsFromDPID('44481778');
        Test.stopTest();
    }
    
    global class WebServiceMockResponseSingleLine implements HttpCalloutMock{
        global HttpResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('{"id":"377eac5d-8871-4567-aad1-c38f3cc34858","results":[{"id":"2403b1e8-4832-4d39-982f-95d706bdfb2d","references":[],"addresses":[{"singleLine":"55 COLLINS RD LOCH VIC 3945","score":226.16925,"dpid":85865442,"confidence":"LOW"},{"singleLine":"55 COLLINS ST KIAMA NSW 2533","score":226.16925,"dpid":58460623,"confidence":"LOW"},{"singleLine":"55 COLLINS ST ENFIELD SA 5085","score":226.16925,"dpid":88605057,"confidence":"LOW"},{"singleLine":"55 COLLINS RD MELTON VIC 3337","score":226.16925,"dpid":95494763,"confidence":"LOW"},{"singleLine":"55 COLLINS PDE HACKHAM SA 5163","score":226.16925,"dpid":77886069,"confidence":"LOW"},{"singleLine":"55 COLLINS ST BELMORE NSW 2192","score":226.16925,"dpid":60954644,"confidence":"LOW"},{"singleLine":"55 COLLINS ST SUNBURY VIC 3429","score":226.16925,"dpid":76830952,"confidence":"LOW"},{"singleLine":"55 COLLINS RD ST IVES NSW 2075","score":226.16925,"dpid":30183561,"confidence":"LOW"},{"singleLine":"55 COLLINS RD YANDINA QLD 4561","score":226.16925,"dpid":68636744,"confidence":"LOW"},{"singleLine":"55 COLLINS ST CORRIMAL NSW 2518","score":226.16925,"dpid":71683068,"confidence":"LOW"}]}]}');        
            return res;
        } 
    }
    
     global class WebServiceMockResponse2 implements HttpCalloutMock{
        global HttpResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('{"id":"5e35c199-2ebf-42ac-ab1b-835b54efa4c2","results":[{"id":"75d04573-a9e1-414e-ace8-9845ff8f4be8","references":[],"addresses":[{"singleLine":"500 HAY ST PERTH WA 6000","score":1,"semiStructured":{"addressLines":["DISTRICT COURT OF WA","500 HAY ST"],"locality":"PERTH","state":"WA","postcode":"6000","countryName":"AUSTRALIA","countryCode":"AU"},"deliveryData":{"postcodeDID":"6000","localityDID":7608,"groupDID":123842,"roundDID":602862,"sectionDID":404527,"dpid":82496590,"sectionSequence":1260,"deliveryPointSequence":1,"deliveryOfficeRoundId":15,"phantom":false,"addressType":"THOROUGHFARE","thoroughfareAddressType":"PRIMARY","secondaryCount":0,"deliveryPointCategory":"BUSINESS"},"structured":{"locality":"PERTH","state":"WA","postcode":"6000","countryName":"AUSTRALIA","countryCode":"AU","thoroughfareName":"HAY","thoroughfareNumber1":"500","thoroughfareType":"ST","deliveryPointIdentifier":82496590,"buildingAliases":["DISTRICT COURT BUILDING","DISTRICT COURT OF WA"],"buildingName":"DISTRICT COURT OF WA"},"upu":{"addressLines":["DISTRICT COURT OF WA","500 HAY ST","PERTH WA 6000"]},"geoDataList":[{"featureType":"CENTROID","latitude":-31.95522663,"longitude":115.86339423}],"dpid":82496590,"confidence":"HIGH"}]}]}');
            return res;
        }
    }

    global class WebServiceMockResponseGeo implements HttpCalloutMock{
        global HttpResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            Map<String, Object> reqBody = (Map<String, Object>)JSON.deserializeUntyped(req.getBody());
            List<Object> addresses = (List<Object>)reqBody.get('addresses');
            Map<String, Object> details = (Map<String, Object>)reqBody.get('detail');
            System.debug('req--->'+req.getBody());
            System.debug('details--->'+details);
            System.debug('addresses--->'+addresses);
            if(details.containsKey('geo')) {
                String resBody = '{"id": "81431e55-86df-4ee6-aa53-2285dfe5f3fb","results":[';
                for(Integer i= 0; i<addresses.size(); i++) {
                    Map<String, Object> address = (Map<String, Object>) addresses[i];
                    System.debug('address.get(\'id\')--->'+address.get('id'));
                    resBody = resBody + '{\n' +
                            '"id": "' + address.get('id') + '",\n' +
                            '"references": [],\n' +
                            '"addresses": [\n' +
                                '{\n' +
                                '"singleLine": "Test Address",\n' +
                                '"score": 956.7472,\n' +
                                '"geoDataList": [\n' +
                                    '{\n' +
                                    '"featureType": "CENTROID",\n' +
                                    '"confidence": "HIGH",\n' +
                                    '"latitude": -37.82022851,\n' +
                                    '"longitude": 144.96652446\n' +
                                    '}\n' +
                                '],\n' +
                                '"dpid": 66114695,\n' +
                                '"confidence": "HIGH"\n' +
                                '}\n' +
                            ']\n' +
                        '}' + (i<(addresses.size()-1) ? ',' : '') ;
                }
                resBody = resBody + ']}';
                res.setBody(resBody);
            } else if(details.containsKey('singleLine')) {
                String resBody = '{"id": "81431e55-86df-4ee6-aa53-2285dfe5f3fb","results":[';
                for(Integer i= 0; i<addresses.size(); i++) {
                    Map<String, Object> address = (Map<String, Object>) addresses[i];
                    System.debug('address--->'+address);
                    resBody = resBody + '{\n' +
                            '"id": "' + address.get('id') + '",\n' +
                            '"references": [],\n' +
                            '"addresses": [\n' +
                            '{\n' +
                            '"singleLine": "3 SOUTHGATE AVE SOUTHBANK VIC 3006",\n' +
                            '"score": 956.7472,\n' +
                            '"dpid": 66114695,\n' +
                            '"confidence": "HIGH"\n' +
                            '}\n' +
                            ']\n' +
                            '}' + (i<(addresses.size()-1) ? ',' : '') ;
                }
                resBody = resBody + ']}';
                res.setBody(resBody);
            }
            return res;
        }
    }
        
    @isTest
    public static void getCountriesTest(){
        // =====================================
        // Data Preparation
        // =====================================
        CountryCodes__c countryCodes = new CountryCodes__c();
        countryCodes.Name = 'Australia';
        countryCodes.Alpha2__c = 'AU';
        countryCodes.Alpha3__c = 'AUS';
        
        insert countryCodes;
        
        Test.startTest();
        AMEAddressValidationController1.getCountries();
        Test.stopTest();
        
    }
}