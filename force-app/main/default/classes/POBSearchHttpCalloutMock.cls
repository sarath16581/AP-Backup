global class POBSearchHttpCalloutMock implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"d":{"results":[{"__metadata":{"id":"http://hxaix29.hq.auspost.com.au:8000/crm_consumer_management/v1/BusinessPartners(\'1123456789\')","uri":"http://hxaix29.hq.auspost.com.au:8000/crm_consumer_management/v1/BusinessPartners(\'1123456789\')","type":"zgw_consumer_management_srv.BusinessPartner","properties":{"ConsumerInfo":{"associationuri":"http://hxaix29.hq.auspost.com.au:8000/crm_consumer_management/v1/BusinessPartners(\'1123456789\')/$links/ConsumerInfo"},"BusinessPartnerType":{"associationuri":"http://hxaix29.hq.auspost.com.au:8000/crm_consumer_management/v1/BusinessPartners(\'1123456789\')/$links/BusinessPartnerType"}}},"BusinessPartnerID":"1123456789","BusinessPartnerTypeID":"1","ConsumerInfo":{"__deferred":{"uri":"http://hxaix29.hq.auspost.com.au:8000/crm_consumer_management/v1/BusinessPartners(\'1123456789\')/ConsumerInfo"}},"BusinessPartnerType":{"__deferred":{"uri":"http://hxaix29.hq.auspost.com.au:8000/crm_consumer_management/v1/BusinessPartners(\'1123456789\')/BusinessPartnerType"}}}]}}');
        response.setStatusCode(200);
        return response; 
    }
}