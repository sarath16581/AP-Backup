/**
  * @author       : arjun.singh@auspost.com.au
  * @date         : 19/06/2020
  * @description  : Mock class for location api and used in ChasPreferredLocationControllerTest
--------------------------------------- History --------------------------------------------------
23.0.62020    arjun.singh@auspost.com.au    Created
 */
@isTest
global class ChasPreferredLocationApiMockGenerator implements HttpCalloutMock{
    global HTTPResponse respond(HTTPRequest req) {        
        // Create a fake response
        
        HttpResponse res = new HttpResponse();
        String serviceJson = '{"points": [{"location_code": "325032_PO","partner_code": "AP","name": "MELB FRANKLIN ST POST SHOP","type": "PO","description": "Post Office","phone_number": "13 13 18","fax_number": "(03)9639 7754","address": {"address_line_1": "Ground Floor 58 Franklin Street","suburb": "MELBOURNE",';
        serviceJson += '"state": "VIC","postcode": "3000","country_name": "Australia","country_code": "AU"},"geo_location": {"lat": -37.80778,"lon": 144.96095},"delivery_point_id": 38236466,"work_centre_id": 325032,"hours": [';
        serviceJson += '{"type": "HOURS","weekday": "0","start_time": "00:00","end_time": "00:00"},{"type": "HOURS","weekday": "1","start_time": "00:00","end_time": "00:00"';
        serviceJson += '},{"type": "HOURS","weekday": "2","start_time": "00:00","end_time": "00:00"},{"type": "HOURS","weekday": "3","start_time": "00:00","end_time": "00:00"' ;
        serviceJson += '},{"type": "HOURS","weekday": "4","start_time": "00:00","end_time": "00:00"},{"type": "HATCH","weekday": "0","start_time": "07:00","end_time": "10:00"';
        serviceJson += '},{"type": "HATCH","weekday": "1","start_time": "07:00","end_time": "10:00"},{"type": "HATCH","weekday": "2","start_time": "07:00","end_time": "10:00"},' ;
        serviceJson += '{"type": "HATCH","weekday": "3","start_time": "07:00","end_time": "10:00"},{"type": "HATCH","weekday": "4","start_time": "07:00","end_time": "10:00"}]}]}';
        String errJson = '{"code":"400","status":"ValidationFailed","message":"Not able to fetch data"}';  
        res.setHeader('Content-Type', 'application/json');
        if(TestDataProvider.httpStatus == 200) res.setBody(serviceJson);
        else res.setBody(errJson);
        res.setStatusCode(TestDataProvider.httpStatus);
        return res;
    }
}