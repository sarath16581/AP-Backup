global class SendCustomerNotificationHttpCalloutMock implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"token":"49434a56-d97c-482d-98e5-6e9f41f768c8","registered":false,"known":false,"loggedin":false,"emailSent":true,"code":0}');
        response.setStatusCode(200);
        return response; 
    }
}