/**
 * Controller class for generating POD document for BSP community
 *
 * @author kalpita.talwadekar
 * @date 2018-11-19
 * @changelog
 * 2018-11-19 nathan.franklin@auspost.com.au Add security features and server side image saving.
 * 2019-04-28 nathan.franklin@auspost.com.au Updated to support new accessRules for BAM
 * 2021-10-26 - Nathan Franklin - Allowed for multiple attachements to be selected for an event message
 */
public with sharing class POD_SafeDropController extends bspBase {

    private static bspBase instance = null;

    public class ContinuationState {
        public String httpRequestLabel;
        public String safeDropGuid;
        public String eventMessageId;
    }

    //current Event Scan record
    private EventMessage__c em;

    //variables for attachment display based on POD type
    public String attachIdSign {get;set;}
    public String attSafeDrop {get;set;}

    //booleans for POD type
    public boolean hasDeliveredWithSignature {get;set;}
    public boolean hasDeliveredWithSafeDrop {get;set;}

    // page vars
    public String pageError { get; set; }
    public Boolean isValidUser {get;set;}
    
    /**
    * Constructor to fetch current record details of event scan along with attachments associated
    * 
    */
    public POD_SafeDropController(ApexPages.StandardController controller) {
        //based on selected scan event fetch the required field details
        em = getEventMessage(controller.getRecord().Id);

        // make sure the user can view this article/consignment
        isValidUser = validateUser(em.Id);

        if(!isValidUser) {
            pageError = bspBase.getErrorMessage(BspConstants.ERROR_NOT_AUTHORISED_PAGE);
        }
    }

    /**
    * Method to display the proof of delivery on UI
    * this is used as an page action of POD_SafeDrop.page
    */
    public void init(){
        //re-setting the POD booleans
        hasDeliveredWithSignature = false;
        hasDeliveredWithSafeDrop = false;

        //loop through attachments on event message if any
        for(Attachment att: em.Attachments) {
            //check if it is an Delivered with Signature attachment based on the Name
            if(att.Name.startswith('Signature')) {
                //set the boolean for UI render
                hasDeliveredWithSignature = true;
                //set the attachment ID
                attachIdSign=att.Id;
            }
            //check if it is an Delivered in a Safe Place attachment based on the Name
            if(att.Name.startswith(SafeDropUtility.SAFE_DROP_ATTACHMENT_NAME)) {
                //set the boolean for UI render
                hasDeliveredWithSafeDrop = true;

                //set the attachment ID
                attSafeDrop = att.Id;
            }
        }
    }

    /**
     * Use the API to pull back the filtered out image.
     * The API blacks out faces and text.
     */
    @RemoteAction
    public static Object getArticleImage(Id eventMessageId) {
         if(validateUser(eventMessageId)) {
             //query the current event scan record
             EventMessage__c eventMessage = getEventMessage(eventMessageId);

             if(eventMessage != null && !String.isEmpty(eventMessage.Safe_Drop_GUID__c)) {

                 // check to see if a safe drop image already exists so it doesn't need to be requested again
                 if(!eventMessage.Attachments.isEmpty()) {
                     for(Attachment attachment : eventMessage.Attachments) {
                         if(attachment.Name == SafeDropUtility.SAFE_DROP_ATTACHMENT_NAME) {
                             return 'OK';
                         }
                     }
                 }

                 // no safe drop image has been previously downloaded
                 // proceed to invoke a continuation to load the safe drop image from AWS through the digital repository API
                 String guid = eventMessage.Safe_Drop_GUID__c;
                 try {
                     HttpRequest req = SafeDropUtility.getSafeDropHttpRequest(guid);

                     // Create a Continuation for the HTTPRequest
                     // This is used for async requests
                     Continuation con = new Continuation(60);
                     con.continuationMethod = 'callback';

                     // add the object state to transfer to the continuation callback
                     ContinuationState state = new ContinuationState();
                     state.httpRequestLabel = con.addHttpRequest(req);
                     state.safeDropGuid = guid;
                     state.eventMessageId = eventMessageId;

                     con.state =  state;

                     // Return it to the system for processing
                     return con;
                 } catch (Exception e) {
                     // there was an error either receiving a response from the server or processing it on our end.
                     // display this error to the user
                     String error = 'EXCEPTION\nType: ' + e.getTypeName() + '\nMessage: ' + e.getMessage() + '\nLine Number: ' + String.valueOf(e.getLineNumber()) + '\n\nStack:\n' + e.getStackTraceString();
                     return error;
                 }
             } else {
                 // continue on to next step because there is no safe drop guid
                 return 'OK';
             }
         } else {
             return bspBase.getErrorMessage(BspConstants.ERROR_NOT_AUTHORISED_PAGE);
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
            String guid = continuationState.safeDropGuid;

            System.debug('Continuation Details: ' + eventMessageId + ', ' + guid);

            // Save the attachment to the event message
            SafeDropUtility.attachSafeDropImage(eventMessageId, (Blob)EncodingUtil.base64Decode(response.imageBody));

            // return an OK response so the redirect proxy page will continue onto the PDF generation page
            return 'OK';
        }
    }
     
    /**
     * Validate whether the current user can access the requested event message
     * The billing account linked to the article must be in the list of users accessible billing accounts
     */
    public static Boolean validateUser(Id eventMessageId) {

        //Get Event Message & Billing Account
        EventMessage__c eventMessage = getEventMessage(eventMessageId);

        //Get Billing Account Id either from Article or from Consignment.
        if(eventMessage == null) {
            return false;
        } else {
            return getInstance().isArticleAccessible(eventMessage.Article__r);
        }
    }

    private static EventMessage__c getEventMessage(Id eventMessageId) {
        List<EventMessage__c> eventMessages = [Select Id, Article__r.Billing_Account__c, Article__r.Billing_Account__r.Organisation__c, Article__r.Billing_Account__r.Id, Article__r.Billing_Account__r.LEGACY_ID__c,
                                                        Article__r.Billing_Account__r.Source_System__c, Article__r.Consignment__c, Article__r.Consignment__r.Billing_Account__c,
                                                        EventType__c, Safe_Drop_GUID__c,
                                                    (SELECT Id, ParentId, Name FROM Attachments ORDER BY CreatedDate DESC)
                                                FROM EventMessage__c
                                                WHERE Id = :eventMessageId
                                                LIMIT 1];
        return (eventMessages.isEmpty() ? null : eventMessages[0]);
    }

    private static bspBase getInstance() {
        if(instance == null) {
            instance = new bspBase();
        }
        return instance;
    }
   
}