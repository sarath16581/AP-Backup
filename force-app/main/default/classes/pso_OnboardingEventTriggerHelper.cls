/**************************************************
Description:  Onboarding Event trigger Helper class, this class works on platform event

History:
--------------------------------------------------
2019-03-19  hasantha.liyanage@auspost.com.au Created

**************************************************/

public without sharing class pso_OnboardingEventTriggerHelper {


    public static final String TYPE_CSSO = 'CSSO';
    public static final String STATUS_STARTED = 'Started';
    public static final String STATUS_FULFILLED = 'Fulfilled';
    public static final String STATUS_SUCCESS = 'Success';
    public static final String STATUS_ERROR = 'Error';
    public static final String STATUS_PENDING = 'Pending';
    public static final String STATUS_PROVISIONING = 'provisioning';

    /**
     * trigger helper class for ExternalOnboardingEvent platform event trigger,
     * this will be executed when the platform event is being recived from Camunda, and
     * will update the ExternalOnboardingRequest__c related record with recieved information.
     *
     * @param events
     */
    public static void updateExternalOnboardingRequests(List<ExternalOnboardingEvent__e> events) {
        try {

            Set<String> externalRequestIds = new Set<String>();
            //collect the external onboarding request ids stored in RequestNumber__c on the event
            for (ExternalOnboardingEvent__e event : events) {
                externalRequestIds.add(event.RequestNumber__c);
            }
            // retrieve the related External Onboarding Request record to update
            List<BAMExternalOnboardingRequest__c> requests = [
                    SELECT Contact__c, Request_Date__c, Response_Payload__c, Response_Date__c, Request_Payload__c, Status__c, Application_Name__c, Id
                    FROM BAMExternalOnboardingRequest__c
                    WHERE id =: externalRequestIds AND RecordType.DeveloperName = 'PS'
            ];

            // update the relevant External Onboarding Request accordingly
            for (ExternalOnboardingEvent__e event : events) {
                // if the event is BAM related, let's ignore it in this context
                if(event.IsBam__c) {
                    continue;
                }
                for (BAMExternalOnboardingRequest__c request : requests) {
                    // if the request is found update with the corresponding information
                    if(request.Id == event.RequestNumber__c) {
                        request.Response_Date__c = System.now();
                        request.Response_Payload__c = event.ResponseText__c;
                        // status has to be updated based on the status sent through PE
                        // TODO: see notes below;
                        // there are multiple types(Type__c) Camunda send to salesforce, but we do consider only the type = "provisioning"
                        // in order to capture the completed/success response and we do not record the other types sent through at the moment,
                        // types provisioning, CSSO and AccountLoading are main processes in Camunda, this has been included in the API for future improvements.
                        if (STATUS_STARTED.equalsIgnoreCase(event.Status__c)) {
                            request.StartedResponseReceived__c = event.CreatedDate;
                            request.status__c = STATUS_PENDING;
                            // when the type is CSSO and the CSSO started recived from Camunda, user need to see the status as CSSO in progress
                            if (TYPE_CSSO.equalsIgnoreCase(event.Type__c)) {
                                request.CSSOStartedDateTime__c = event.CreatedDate;
                            }
                            // once the CSSO is completed update the completed date, this will cause to hide the CSSO message to the user
                        } else if (STATUS_FULFILLED.equalsIgnoreCase(event.Status__c) && TYPE_CSSO.equalsIgnoreCase(event.Type__c)) {
                            request.CSSOFulfilledDateTime__c = event.CreatedDate;
                        } else if (STATUS_FULFILLED.equalsIgnoreCase(event.Status__c) && STATUS_PROVISIONING.equalsIgnoreCase(event.Type__c)) {
                            request.status__c = STATUS_SUCCESS;
                            request.SuccessResponseReceived__c = event.CreatedDate;
                        } else if (STATUS_ERROR.equalsIgnoreCase(event.Status__c)) {
                            request.status__c = STATUS_ERROR;
                            request.ErrorResponseReceived__c = event.CreatedDate;
                        }
                    }
                }
            }
            update requests;

        }catch(Exception exp){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), 'Platform Event',
                    CaseTriggerHelper.class.getName(), 'updateExternalOnboardingRequests',
                    'ExternalOnboardingEvent__e trigger', LoggingLevel.ERROR);
        }
    }
}