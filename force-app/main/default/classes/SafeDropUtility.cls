/**
 * @deprecated NOTE: No new methods should be added to this class. New methods should be added to DeliveryProofService
 *
 * @author Nathan Franklin
 * @date
 * @group Articles
 * @tags Cases, SSSW, Articles, Safe Drop, SAP-EM
 * @domain Articles
 * @test SafeDropUtility_Test
 * @description
 * @changelog
 * 2020-03-16 - Nathan Franklin - Added aura attributes to the SafeDropApiResponse class
 * 2020-04-10 - Nathan Franklin - Added instance variable for mocking
 * 2020-04-10 - Nathan Franklin - changed getSafeDropEvents to use the new metadata type
 * 2021-09-09 - seth.heang@auspost.com.au - Uplift SF API version to 52
 * 2021-10-15 - Nathan Franklin - Added new instance method to wrap attachSafeDropImage for apex mocking
 */
public with sharing class SafeDropUtility {

//    public static final String ELIGIBILITY_SENDERNAME = 'Salesforce';
//    public static final String ELIGIBILITY_LOCATION = 'at a safe place on premises';

    /**
	 * Grabs an instance of this class
	 * Using Application.Utilities allows us to override this interface with a mock class for unit testing
	 */
    public static SafeDropUtility getInstance() {
        return (SafeDropUtility)Application.Utilities.getInstance(SafeDropUtility.class);
    }

    public final static String SAFE_DROP_ATTACHMENT_NAME = 'safedrop-image.jpg';

    /************************************************************
	 * Class instance methods
	 *      These wrap the legacy static methods
	 *      in order to provide proper mocking
	 ************************************************************/
    public HttpRequest getHttpRequest(String guidId) {
        return SafeDropUtility.getSafeDropHttpRequest(guidId);
    }

    /**
     * Attach a safe drop image to a record in Salesforce
     * This should be called after a safedrop image has been remotely requested if there is a need to cache the image locally
     */
    public Attachment attachSafeDropToRecord(Id recordId, Blob imageBody) {
        return SafeDropUtility.attachSafeDropImage(recordId, imageBody);
    }



    /************************************************************
	 * Static methods
	 ************************************************************/

    public static Set<String> getSafeDropEvents() {
        Set<String> eventTypes = new Set<String>();
        for(EventMessageTypeMapping__mdt eventType : EventMessageUtil.getEventMessageTypes().values()) {
            if(eventType.IsSafeDrop__c) {
                eventTypes.add(eventType.Label);
            }
        }
        return eventTypes;
    }

    public static Set<String> getSafeDropAttachmentTypes() {
        return new Set<String>{'SAFE_DROP_PICTURE', 'NO_SIG_REQUIRED'};
    }

    // NOTE: This can be removed in JUL-2022
    //    /**
    //     * Checks to see whether a safe drop image is already attached to the case
    //     */
    //    public static Boolean safeDropAttachmentExists(Id caseId) {
    //        List<Attachment> attachs = [Select Id, Name From Attachment
    //                                        Where ParentId = :caseId
    //                                        And Name like 'safedrop-%'];
    //        return attachs.size() > 0;
    //    }
    //
    //    /**
    //     * This will search through event messages for a particular article to retrieve the Safe drop Guid if it exists
    //     * This assumes that event messages have been downloaded and stored in SF
    //     *
    //     * When EventMessages are received, we process the message and grab out attachments that match SAFE_DROP_PICTURE
    //     * A Safe Drop GUID is stored based on this rule which means we don't need to worry about event message types
    //     *      We only deal with events where the Safe Drop GUID exists
    //     */
    //    public static String getSafeDropGuidId(String articleReferenceId) {
    //        List<EventMessage__c> messages = [Select Id, Safe_Drop_GUID__c From EventMessage__c
    //                                            Where Safe_Drop_GUID__c != null
    //                                            And Article__r.TrackingID__c =: articleReferenceId];
    //        String output;
    //        if(messages.size() > 0) {
    //            output = messages[0].Safe_Drop_GUID__c;
    //        }
    //        return output;
    //    }

    public static Map<String, String> getAPIDetails() {
        // Grab login details from the logins custom settings
        // NOTE: SafeDropAPI
        List<AusPostSettings__c> logins = [Select URL__c, Username__c, Password__c, Token__c  From AusPostSettings__c Where Name = 'SafeDropAPI' And IsActive__c = true];
        if(logins.size() == 0) {
            return null;
        }

        String username = logins[0].Username__c;
        String password = logins[0].Password__c;

        String url = (String.isEmpty(logins[0].URL__c) ? '' : (logins[0].URL__c.right(1) == '/' ? logins[0].URL__c.left(logins[0].URL__c.length() - 1) : logins[0].URL__c)) + '?bucket_name='+ logins[0].Token__c;

        Map<String, String> output = new Map<String, String>();
        output.put('username', logins[0].Username__c);
        output.put('password', logins[0].Password__c);
        output.put('url', url);

        // set http basic auth headers
        Blob headerValue = Blob.valueOf(logins[0].Username__c + ':' + logins[0].Password__c);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        System.Debug(authorizationHeader);

        output.put('auth', authorizationHeader);

        return output;
    }

    public static HttpRequest getSafeDropHttpRequest(String guidId) {
        // Grab login details from the logins custom settings
        // NOTE: SafeDropAPI
        Map<String, String> login = getAPIDetails();
        if(login == null) {
            return null;
        }

        String url = login.get('url');
        url += '&object_id=' + EncodingUtil.urlEncode(guidId, 'UTF-8') + '.JPG';

        System.Debug('>>> Safe Drop Request URL: ' + url);

        HttpRequest req = new HttpRequest();
        req.setTimeout(25000);
        req.setHeader('Authorization', login.get('auth'));
        req.setEndpoint(url);
        req.setMethod('GET');
        return req;
    }

    /**
     * After the response is received back from the API, parse it into a class to return back to the client
     */
    public static SafeDropApiResponse parseResponse(String responseBody, HttpResponse httpResp) {
        SafeDropApiResponse response = new SafeDropApiResponse();

        Map<String, Object> o;
        try {
            o = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
        } catch(Exception e) {
            o = new Map<String, Object>();
        }

        // always check for an error first in the request regardless of the response code.
        String error = '';
        Map<String, Object> oDocument = (Map<String, Object>)getProp(o, 'document', false);
        Object oError = getProp(oDocument, 'error', false); // List<Object> [{},{}]

        if(oError != null) {
            for(Object err : (List<Object>)oError) {
                Map<String, Object> mErr = (Map<String,Object>)err;

                error = (!String.isEmpty(error) ? ', ' : '');

                String code = String.valueOf(getProp(mErr, 'code'));
                String name = String.valueOf(getProp(mErr, 'name'));
                String message = String.valueOf(getProp(mErr, 'message'));

                String lineError = '';
                if(!String.isEmpty(code) && code == 'AS-9007') {
                    lineError = 'Document Not Found';
                } else {
                    if(!String.isEmpty(code)) lineError += code;
                    if(!String.isEmpty(name)) lineError += (!String.isEmpty(lineError) ? ', ' : '') + name;
                    if(!String.isEmpty(message)) lineError += (!String.isEmpty(lineError) ? ', ' : '') + message;
                }

                error += 'ERROR: ' + lineError;
            }
        } else if (httpResp.getStatusCode() >= 2000 && String.isEmpty(error)) {
            // continuation error
            error = getContinuationError(httpResp.getStatusCode());
        } else if(httpResp.getStatusCode() >= 300 && String.isEmpty(error)) {
            // since the status code returned is not a 2xx it means the request failed.
            // return a generic HTTP status error because the error JSON object doesn't exist
            error = (httpResp.getStatus() == null ? 'An Error Occurred' : httpResp.getStatus()) + ' (' + String.valueOf(httpResp.getStatusCode()) + ')';
        }

        // if the error message has been populated from above then return that rather than proceeding
        System.Debug('IS ERROR? >> ' + error);
        if(!String.isEmpty(error)) {
            response.isError = true;
            response.errorMessage = error;
        } else {
            // grab the document if it exists in the response
            // not getprop handles null gracefully
            Map<String, Object> objectDetails = (Map<String, Object>)getProp(oDocument, 'object_details', false);
            String content = String.valueOf(getProp(objectDetails, 'object_content'));

            // the object content doesn't exist in the response
            if(String.isEmpty(content)) {
                response.isError = true;
                response.errorMessage = 'Image content not found.';
            } else {
                // set the response which is a base 64 image string.
                response.imageBody = content;
            }
        }

        return response;
    }

    public static Attachment attachSafeDropImage(Id caseId, Blob imageBody) {
        Attachment attachment = new Attachment(ParentId = caseId, Body = imageBody, ContentType = 'image/jpg', Name = SAFE_DROP_ATTACHMENT_NAME, IsPrivate = false);
        insert attachment;

        System.Debug('>>> Inserted Safe Drop Attachment: ');
        System.Debug(attachment);

        return attachment;
    }

    private static String getContinuationError(Integer statusCode) {
        Map<Integer, String> errors = new Map<Integer, String>();
        errors.put(2000,'The timeout was reached, and the server didn’t get a chance to respond.');
        errors.put(2001,'There was a connection failure.');
        errors.put(2002,'Exceptions occurred.');
        errors.put(2003,'The response hasn’t arrived (which also means that the Apex asynchronous callout framework hasn’t resumed).');
        errors.put(2004,'The response size is too large (greater than 1 MB).');

        if(errors.get(statusCode) == null) {
            return String.valueOf(statusCode) + ': An error occurred.';
        } else {
            return errors.get(statusCode);
        }
    }

    /**
     * Grab a property out of JSON object
     */
    private static Object getProp(Map<String, Object> obj, String prop, Boolean returnAsString) {
        if (obj == null) {
            if (returnAsString) {
                return '';
            } else {
                return null;
            }
        }

        if (obj.keySet().contains(prop)) {
            return obj.get(prop);
        } else {
            if (returnAsString) {
                return '';
            } else {
                return null;
            }
        }
    }
    private static Object getProp(Map<String, Object> obj, String prop) {
        return getProp(obj, prop, true);
    }

    public class SafeDropApiResponse {
        @AuraEnabled public Boolean isError = false;
        @AuraEnabled public String errorMessage = '';
        @AuraEnabled public String imageBody = '';
        @AuraEnabled public Id attachmentId = null;

        public SafeDropApiResponse() { }

        public SafeDropApiResponse(Boolean isError, String errorMessage, String imageBody) {
            this.isError = isError;
            this.errorMessage = errorMessage;
            this.imageBody = imageBody;
        }
    }

//    public class EligibilityResult {
//        @AuraEnabled public String status;
//        @AuraEnabled public String reason;
//    }

}