/**************************************************
Description:       Created for use in the StarTrack CCTR project. API will be consumed by SmartSpeak to push new cases when an IVR response is marked as successful.
History:
--------------------------------------------------
2018-04-02  kalpita.talwadekar@auspost.com.au Created
2018-04-11  nathan.franklin@auspost.com.au Updated
2018-04-26  dilshan.egodawela@auspost.com.au Updated
2018-05-26  nathan.franklin@auspost.com.au Tidying up code and adding TODO items
2018-06-01  nathan.franklin@auspost.com.au small formatting tidyups
2020-07-13  saiswetha.pingali@auspost.com.au REQ2202261 - case purpose for IVR is replaced with 'In transit' for 'Late Delivery'
**************************************************/
@RestResource(urlMapping='/v1.0/IVR/StarTrack/Successful')
global with sharing class ResourceV1IVRStarTrackSuccessful {

    //wrapper class to hold fields that are being returned via the rest service
    private class CaseRecord {
        private string id { get; set; }
        private string caseNumber { get; Set; }
    }

    /**
     * Creates a new case based on the successful IVR response.
     * @param
     *      consignmentIdentifier
     *      callerType
     *      requestBody = {"consignmentIdentifier":"12345","callerType":"Sender","callerId":"unavailable"}
     */
    @HttpPut
    global static void put() {
        RestRequest request = RestContext.request;

        // convert JSON string into map of params
        Map<String, String> params = getParams(RestContext.request.requestBody.toString());

        String consignmentIdentifier = params.get('consignmentIdentifier');
        String callerType = params.get('callerType');
        String callerId = params.get('callerId') == 'unavailable' ? '' : params.get('callerId');
        System.Debug(consignmentIdentifier);
        
        try {
            //Call Search Consignment to update/create Article record in Salesforce
            //This is required to get the latest details on the consignment.
            StarTrackConsignmentSearchUtil.ConsignmentWrapper conwrap = StarTrackConsignmentSearchUtil.searchConsignment(consignmentIdentifier, 'UNIQUEEXTERNALID', Date.today(), Date.today(), Date.today(), 'test');

            //if the search run successfully
            System.Debug(conwrap);

            if (!conwrap.articleList.isEmpty()) {

                // articleList[0] will contain the consignment just retrieved
                Article__c article = conwrap.articleList[0];
                Date edd = article.ExpectedDeliveryDate__c;

                //get the case recordtype id 
                String stRecType = [Select Id from RecordType where DeveloperName = :StarTrack_Constants.CASE_DELIVERY_DEVNAME_RT and SObjectType = 'Case' limit 1].Id;

                //Create Case
                Case ivrSTCase = new Case(Status = 'Closed', Origin = 'IVR', ResolutionCode__c = 'Resolved - Scanning Available', RecordTypeId = stRecType,
                                            Recent_Caller_Phone_Number__c = callerId, Direction__c = 'Inbound', Recent_Caller_Type__c = callerType,
                                            Recent_Caller_First_Name__c = '', Recent_Caller_Last_Name__c = '', Related_Billing_Account__c = article.Billing_Account__c,FCR__c = true);

                //Enter Enquiry Type and  Call Purpose based on EDD and  Consignment Delivery status
                if (article.Consignment_Summary_Status__c != 'Delivered') {
                    ivrSTCase.Enquiry_Type__c = System.today() <= edd ? 'Delivery Update' : System.today() > edd ? 'Delivery update' : 'Delivery update';
                    //ivrSTCase.Call_Purpose__c = System.today() <= edd ? 'Delivery in Progress' : System.today() > edd ? 'Late Delivery' : 'Delivery in Progress';
                    //pingalis - REQ2202261 - Case purpose 'Late Delivery' is replaced with 'In Transit' 
                    ivrSTCase.Call_Purpose__c = System.today() <= edd ? 'Delivery in Progress' : System.today() > edd ? 'In Transit' : 'Delivery in Progress';
                } else {
                    //if the Consignment was delivered
                    ivrSTCase.Enquiry_Type__c = 'Delivery Update';
                    ivrSTCase.Call_Purpose__c = 'Delivered';
                }

                //Link the Consignment to the newly created case
                ivrSTCase.ArticleTest__c = article.Id;

                //insert  case
                Database.SaveResult saveResult = Database.insert(ivrSTCase, false);
                
                //on successful case creation send success response code
                if (saveResult.isSuccess()) {
                    //get the record type for new AuthorisedContact record
                    Id startrackRT = Schema.SObjectType.AuthorisedContacts__c.getRecordTypeInfosByName().get(StarTrack_Constants.STRELCONT_RT).getRecordTypeId();

                    //insert new AuthContact record
                    Database.insert(new AuthorisedContacts__c(RecordTypeId = startrackRT, Case__c = ivrSTCase.Id, Contact_Phone_Number__c = ivrSTCase.Recent_Caller_Phone_Number__c,
                                                                Contact_Type__c = ivrSTCase.Recent_Caller_Type__c, First_Name__c = ivrSTCase.Recent_Caller_First_Name__c,
                                                                Last_Name__c = ivrSTCase.Recent_Caller_Last_Name__c));

                    //Create call log task
                    StarTrackCreateCallLogActivity.createLogACallRecord(new List<Id>{ivrSTCase.Id});

                    //quary for the newly created case to get the Casenumber and Id that will be retunred with the response.
                    Case newCase = [select Id,CaseNumber from Case where Id = :ivrSTCase.Id];

                    //initialise response wrapper
                    CaseRecord record = new CaseRecord();
                    record.id = newCase.Id;
                    record.caseNumber = newCase.CaseNumber;

                    // return serialised response to caller
                    ResourceAPIService.serializeResponse(new ResourceAPIService.ResourceResponse(true, null, record), 200);
                } else {
                    //log the dml results
                    UTIL_LoggingService.logDmlResults(new List<Database.Saveresult>{saveResult}, null, new List<Case>{ivrSTCase}, 'StarTrack API',
                                                        ResourceV1IVRStarTrackSuccessful.class.getName(), 'Create Case on Successful IVR response', '', LoggingLevel.ERROR);

                    //process the error response
                    String error = '';
                    for(Database.Error err : saveResult.getErrors()) {
                        error += err.getMessage() + '\n';
                    }
                    // return serialised response to caller
                    ResourceAPIService.serializeResponse(new ResourceAPIService.ResourceResponse(false, error, null), 500);
                }
            } else {
                // return a consignment not found error
                ResourceAPIService.serializeResponse(new ResourceAPIService.ResourceResponse(false, 'consignment not found', null), 500);
            }
        } catch (Exception e) {
            //log the caught exception and return error response
            UTIL_LoggingService.logHandledException(e, UserInfo.getOrganizationId(), 'StarTrack API',
                                                    ResourceV1IVRStarTrackSuccessful.class.getName(), 'Create Case on Successful IVR response',
                                                    null, LoggingLevel.ERROR);

            // return serialised response to caller
            ResourceAPIService.serializeResponse(new ResourceAPIService.ResourceResponse(false, e.getMessage(), null), 500);
        }

    }

    /**
     * Convert the params JSON params received from the body into a map
     */
    private static Map<String, String> getParams(String requestBody) {
        try {
            Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(requestBody);

            // make sure we only retrieve the params needed from the body.
            // makes sure the params are returned as strings
            Map<String, String> output = new Map<String, String>();
            output.put('consignmentIdentifier', String.valueOf(params.get('consignmentIdentifier')));
            output.put('callerType', String.valueOf(params.get('callerType')));
            output.put('callerId', String.valueOf(params.get('callerId')));

            return output;
        } catch (Exception e) {
            System.Debug('>> Param Conversion Exception: ' + e);
            return null;
        }
    }

}