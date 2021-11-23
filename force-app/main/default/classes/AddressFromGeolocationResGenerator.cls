/**
* @author       : arjun.singh@auspost.com.au
* @date         : 
* @description  : Mock Class for Google Map Api Call. It will return  mock Address as response based on geolocation provided 
*/
/*******************************  History ************************************************
04/06/2020  arjun.singh@auspost.com.au  created        
*****************************************************************************************/
@isTest
global class AddressFromGeolocationResGenerator implements HttpCalloutMock{
    global HTTPResponse respond(HTTPRequest req) {        
        // Create a fake response
        
        HttpResponse res = new HttpResponse();
        String serviceJson = '{ "results" : [ { "formatted_address" : "2A Coolawin Rd, Avalon Beach NSW 2107, Australia", "geometry" : { "location" : { "lat" : -33.6363166, "lng" : 151.3239372 }, "location_type" : "ROOFTOP", "viewport" : { "northeast" : { "lat" : -33.6349676197085, "lng" : 151.3252861802915 }, "southwest" : { "lat" : -33.6376655802915, "lng" : 151.3225882197085 } } }, "place_id" : "ChIJy8cHgitTDWsRCMNkwGOgfVc", "plus_code" : { "compound_code" : "987F+FH Avalon Beach NSW, Australia", "global_code" : "4RRH987F+FH" }, "types" : [ "street_address" ] } ], "status" : "OK" }';
        String errJson = '{"code":"400","status":"ValidationFailed","message":"Not able to fetch data"}';  
        res.setHeader('Content-Type', 'application/json');
        if(TestDataProvider.httpStatus == 200) res.setBody(serviceJson);
        else res.setBody(errJson);
        res.setStatusCode(TestDataProvider.httpStatus);
        return res;
    }
}