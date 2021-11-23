/**
 * Created by nmain on 4/22/2016.
 */
public with sharing class testHttpCalloutMock implements HttpCalloutMock
{

    //A single method that acts as a webservice to simulate 3rd party services
    public HTTPResponse respond(HTTPRequest req)
    {
        //Look at the httpRequest that was sent via Apex to possibly determine how we will respond
        system.debug('testHttpCalloutMock.respond: ' +req.getBody());
        system.debug('testHttpCalloutMock.respond: ' +req.getMethod());
        system.debug('testHttpCalloutMock.respond: ' +req.getEndpoint());

        //Instantiate a new httpResponse
        httpResponse res = new httpResponse();

        //Set the Status
        res.setStatus('OK');

        //Set the StatusCode
        res.setStatusCode(200);

        //Set the Body to the serialized form of the instance of the stackExchangeAPI.responseResource
        res.setBody('success:ok');

        //Return the httpResponse
        return res;
    }

}