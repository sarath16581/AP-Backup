/**************************************************
Description:    Controller class for generating POD document for myNetwork community
History:
--------------------------------------------------
2020-05-12 - Hara Sahoo Created
2021-06-22 - Ranjeewa Silva - Updated to retrieve event message attachments and store as attachment records
                              if not already available in Salesforce. Previously only safe drop attachments were supported.
**************************************************/
public with sharing class MyNetworkPODSafedrop {
    public String pageError {get;set;}
    public class ContinuationState {
        public String httpRequestLabel;
        public String attachmentGUID; // attachment guid
        public Boolean isSafeDrop; // flag indicating if attachment guid is safe drop
        public String eventMessageId;
    }
    @RemoteAction
    public static Object getArticleImageList(String eventMessageId) {
        EventMessage__c eventMessage = getEventMessage(eventMessageId);
        if(eventMessage != null && (!String.isEmpty(eventMessage.Safe_Drop_GUID__c) || (!String.isEmpty(eventMessage.AttachmentGUID__c)))) {
            // check to see if a safe drop image or event message attachment already exists so it doesn't need to be requested again
            if(!eventMessage.Attachments.isEmpty()) {
                for(Attachment attachment : eventMessage.Attachments) {

                    // safe drop image attachments are named 'safedrop-image.jpg'
                    // other event message attachments are named 'em-attachment-<attachment_guid>.jpg'
                    if((String.isNotBlank(eventMessage.Safe_Drop_GUID__c) && attachment.Name == SafeDropUtility.SAFE_DROP_ATTACHMENT_NAME)
                            || (String.isNotBlank(eventMessage.AttachmentGUID__c) && String.isNotBlank(attachment.Name)
                                && attachment.Name.startsWith(EventMessageUtil.EVENT_MESSAGE_ATTACHMENT_PREFIX)
                                && attachment.Name.contains(eventMessage.AttachmentGUID__c))) {

                        // attachment already exists. no need to do retrieve again.
                        return 'OK';
                    }
                }
            }
            String guid = String.isNotBlank(eventMessage.Safe_Drop_GUID__c) ? eventMessage.Safe_Drop_GUID__c : eventMessage.AttachmentGUID__c;
            try {
                
                // Create a chained Continuation for the HTTPRequest
                // This is used for async requests
                Continuation chainedContinuation = null;
                chainedContinuation  = new Continuation(60);
                chainedContinuation.continuationMethod = 'callback';
                HttpRequest req = SafeDropUtility.getSafeDropHttpRequest(guid);
                
                // add the object state to transfer to the continuation callback
                ContinuationState state = new ContinuationState();
                state.httpRequestLabel = chainedContinuation.addHttpRequest(req);
                state.attachmentGUID = guid;
                state.eventMessageId = eventMessageId;
                state.isSafeDrop = String.isNotBlank(eventMessage.Safe_Drop_GUID__c);

                chainedContinuation.state =  state;
                // Return it to the system for processing
                return chainedContinuation;
            } catch (Exception e) {
                // there was an error either receiving a response from the server or processing it on our end.
                // display this error to the user
                String pageError = 'EXCEPTION\nType: ' + e.getTypeName() + '\nMessage: ' + e.getMessage() + '\nLine Number: ' + String.valueOf(e.getLineNumber()) + '\n\nStack:\n' + e.getStackTraceString();
                return pageError;
            }
        } else
        {
            return 'OK';
        }
        
    }
    

    
    /**
* This is the callback for the async callout.
* This is returned to the javascript client that invoked the getArticleImage method
*/
    public static Object callback(Object state) {
        ContinuationState continuationState = (ContinuationState)state;
        System.debug(continuationState);
        
        HttpResponse resp = Continuation.getResponse(continuationState.httpRequestLabel);
        
        String responseBody = resp.getBody();
        System.Debug(responseBody);
        
        // parse the json
        System.debug('SAFE-DROP API RAW REPONSE: ' + responseBody);
        SafeDropUtility.SafeDropApiResponse response = SafeDropUtility.parseResponse(responseBody, resp);
        System.debug('SAFE-DROP API PARSED REPONSE: ' + response);
        
        if(response.isError) {
            // display this error message to the user
            return response.errorMessage;
        } else {
            // add the safe drop image as an attachment to the event message and report back to the page that it's ok to redirect to the PDF
            Id eventMessageId = continuationState.eventMessageId;
            String guid = continuationState.attachmentGUID;
            
            System.debug('Continuation Details: ' + eventMessageId + ', ' + guid);

            // save attachment to the event message
            EventMessageUtil.attachArticleImage(eventMessageId, (Blob)EncodingUtil.base64Decode(response.imageBody), continuationState.attachmentGUID, continuationState.isSafeDrop);

            // return an OK response so the redirect proxy page will continue onto the PDF generation page
            return 'OK';
        }
    }
    
    private static EventMessage__c getEventMessage(String eventMessageId) {
        List<EventMessage__c> eventMessages = [Select Id, Article__r.Billing_Account__c, Article__r.Billing_Account__r.Organisation__c, Article__r.Billing_Account__r.Id, Article__r.Billing_Account__r.LEGACY_ID__c,
                                               Article__r.Billing_Account__r.Source_System__c, Article__r.Consignment__c, Article__r.Consignment__r.Billing_Account__c,
                                               EventType__c, Safe_Drop_GUID__c, AttachmentGUID__c, AttachmentType__c,
                                               (SELECT Id, ParentId, Name FROM Attachments ORDER BY CreatedDate DESC LIMIT 1)
                                               FROM EventMessage__c
                                               WHERE Id = :eventMessageId
                                               LIMIT 1];
        return (eventMessages.isEmpty() ? null : eventMessages[0]);
    }
    
 
}