/**
* @author       : 
* @date         : 
* @description  : Mock Class for EDD Integrataion. This class is used in test class EDDWidgetController_Test to 
*                 test the EDD Integration  
*/
/*******************************  History ************************************************
12/09/2019  arjun.singh@auspost.com.au  created        
*****************************************************************************************/
@isTest
global class EDDMockHttpResponseGenerator implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        String serviceJson = '{"items":[{"id":"a0f30bd3-18a3-4b38-8ee1-04d96cc50efb","type": "Service","code": "REGULAR","category" : "DOMESTIC_LETTER","items": [{"id": "1bb2e537-24b1-4d22-a644-90556620358e","type": "DeliveryEstimate","code": "FIXED","minimum": 4,"maximum": 7,"estimate": "Delivered in 4-7 days","unit": "Day"}]}]} ';
        String errJson = '{"code":"400","status":"ValidationFailed","message":"Bad request: invalid inputs.","field_error":[{"code":"CPDT-002-PARAM_INVALID","defaultMessage":"A domestic postcode must consist of 4 numeric digits.","field":"fromPostcode","rejectedValue":"adsfadfs"}]}';        
        res.setHeader('Content-Type', 'application/json');
        if(TestDataProvider.httpStatus == 200) res.setBody(serviceJson);
        else res.setBody(errJson);
        res.setStatusCode(TestDataProvider.httpStatus);
        return res;
    }
}