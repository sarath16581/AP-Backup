@isTest
global class HttpResponseMockGenerator implements HttpCalloutMock {
    
    public String xEndpoint {get;set;}
    public String xMethod {get;set;}
    public String xHeaderType {get;set;}
    public String xHeaderContext {get;set;}
    public String xBody {get;set;}
    public Boolean success {get;set;}
    public Integer successCode {get;set;}
    public Integer errorCode {get;set;}
    
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        //System.assertEquals('http://example.com/example/test', req.getEndpoint());
        //System.assertEquals('GET', req.getMethod());
        
        // Create a fake response
        //HttpResponse res = new HttpResponse();
        //res.setHeader('Content-Type', 'application/json');
        //res.setBody('{"example":"test"}');
        //res.setStatusCode(200);
        
        // Optionally, only send a mock response for a specific endpoint
        // and method.
        System.assertEquals(xEndpoint, req.getEndpoint());
        System.assertEquals(xMethod, req.getMethod());
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader(xHeaderType,xHeaderContext);
        res.setBody(xBody);
        if (success)
            res.setStatusCode(successCode);
        else
            res.setStatusCode(errorCode);
        return res;
    }
}