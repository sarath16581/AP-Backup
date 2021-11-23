/**************************************************
Description:    Utility class for manager interactions with LiveChatTranscript
History:
--------------------------------------------------
2018-10-28  nathan.franklin@auspost.com.au  Created
2018-11-19  nathan.franklin@auspost.com.au  Bug fixes in picking up records on insert
2019-07-01  rajesh.punjabi@mav3rik.com Added functionality to creat feeditem for LiveChatTranscript.
05/08/2021 Prerna Rahangdale : A new method upDateIpAddress added to overide the Standard Ip address
 with the Custom visitorId Address the smart speak chatbot payload, the Standard Ip address was populating the
  SS application Server address
**************************************************/
public with sharing class LiveChatTranscriptUtility {

    // this is to prevent cases from being added to a future callout more than once.
    private static Set<Id> recursiveCasesProcessed = new Set<Id>();

    /**
     * TRIGGER: LiveChatTranscript
     *
     * When a live chat is initiated, a case will generally be created by the agent
     * Most times, these cases will be created during a live chat engagement.
     * Since Omni is not enabled, a transcript is only created AFTER the chat ENDs so we need to link the case to the transcript only AFTER the transcript is created.
     * NOTE: This MAY NOT be required if OMNI is ever enabled since livechattranscript records are created at the start of the chat and there is code in the case trigger to handle this
     */
    public static void linkCreatedCaseToTranscript(List<LiveChatTranscript> transcripts) {
        try {
            Map<String, LiveChatTranscript> chatKeyMappings = new Map<String, LiveChatTranscript>();

            for(LiveChatTranscript transcript : transcripts) {
                // only link a case to the transcript if a case is not already linked to it.
                // NOTE: This also protects us when a case is created/updated with a chat key for a LiveChatTranscript record that already exists
                //          This will prevent unnecessary processing
                if(transcript.CaseId == null) {
                    chatKeyMappings.put(transcript.ChatKey, transcript);
                }
            }

            // for all the LiveChatTranscript records that are being inserted without an existing case id
            if(!chatKeyMappings.isEmpty()) {
                List<Case> caseList = [SELECT Id, ChatKey__c FROM Case
                                        WHERE ChatKey__c In :chatKeyMappings.keySet() Order By CreatedDate DESC LIMIT 1];
                if (!caseList.isEmpty()) {
                    Map<String, Id> chatKeyCaseMappings = new Map<String, Id>();
                    for(Case chatCase : caseList) {
                        chatKeyCaseMappings.put(chatCase.ChatKey__c, chatCase.Id);
                    }

                    for(LiveChatTranscript transcript : chatKeyMappings.values()) {
                        // only link a case if it exists!
                        if(chatKeyCaseMappings.keySet().contains(transcript.ChatKey)) {
                            transcript.CaseId = chatKeyCaseMappings.get(transcript.ChatKey);
                        }
                    }
                }
            }
        } catch(Exception exp) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, LiveChatTranscriptUtility.class.getName(), 'linkCreatedCaseToTranscript', 'LiveChatTranscriptTrigger', LoggingLevel.ERROR);
        }

    }

    /**
     * TRIGGER: Case Trigger
     *
	 * PRIMARY ENTRY POINT to linking a case to an existing LiveChatTranscript
	 * When a live chat is initiated, a case will generally be created by the agent
     * Most times, these cases will be created during a live chat engagement, however, sometimes these cases will be created after the live chat finishes.
     * This is called from CaseTriggerHandler to search for an existing LiveChatTranscript record and link the case to it.
	 */
    public static void linkCreatedCaseToTranscript(Map<Id, Case> newCaseMap) {
        linkCreatedCaseToTranscript(newCaseMap, null);
    }

    /**
     * TRIGGER: Case Trigger
     *
	 * PRIMARY ENTRY POINT to linking a case to an existing LiveChatTranscript
	 * When a live chat is initiated, a case will generally be created by the agent
     * Most times, these cases will be created during a live chat engagement, however, sometimes these cases will be created after the live chat finishes.
     * This is called from CaseTriggerHandler to search for an existing LiveChatTranscript record and link the case to it.
	 */
    public static void linkCreatedCaseToTranscript(Map<Id, Case> newCaseMap, Map<Id, Case> oldCaseMap) {
        try {
            Map<Id, Case> processableCases = new Map<Id, Case>();

            // find a list of cases where the chatkey has changed (mainly will be a case create only, but leave support in for update, just in case)
            for(Id caseId : newCaseMap.keySet()) {
                if(!recursiveCasesProcessed.contains(caseId)
                        && ((!String.isEmpty(newCaseMap.get(caseId).ChatKey__c) && oldCaseMap == null)
                                || (oldCaseMap != null && newCaseMap.get(caseId).ChatKey__c != oldCaseMap.get(caseId).ChatKey__c))) {
                    processableCases.put(caseId, newCaseMap.get(caseId));
                }
            }

            if(!processableCases.isEmpty()) {
                // stop these records from being processed more than once.
                recursiveCasesProcessed.addAll(processableCases.keySet());

                //make sure we always execute this in an async context
                if (System.isFuture() || System.isBatch() || System.isScheduled()) {
                    linkCreatedCaseToTranscriptCurrentContext(processableCases.values());
                } else {
                    // call the link case as a future to return the interface quickly
                    linkCreatedCaseToTranscriptFuture(processableCases.keySet());
                }
            }

        } catch(Exception exp){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, LiveChatTranscriptUtility.class.getName(), 'linkCreatedCaseToTranscript', SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
        }
    }

    /**
     * Loop through each case that was passed in and check if there is a corresponding LiveChatTranscript record without a case currently assigned to it.
     */
    @future
    private static void linkCreatedCaseToTranscriptFuture(Set<Id> caseIds) {
        List<Case> cases = [Select Id, ChatKey__c From Case
                                Where Id In :caseIds];

        // now we are in async context, update the LiveChatTranscript record based on the chatkey in the case
        linkCreatedCaseToTranscriptCurrentContext(cases);
    }

    /**
     * Loop through each case that was passed in and check if there is a corresponding LiveChatTranscript record without a case currently assigned to it.
     */
    private static void linkCreatedCaseToTranscriptCurrentContext(List<Case> cases) {
        try {
            Map<String, Id> chatKeyCases = new Map<String, Id>();
            for(Case chatKeyCase : cases) {
                chatKeyCases.put(chatKeyCase.ChatKey__c, chatKeyCase.Id);
            }

            // loop through each transcript and set the caseid
            List<LiveChatTranscript> transcripts = [Select Id, ChatKey From LiveChatTranscript
                                                        Where ChatKey In :chatKeyCases.keySet() And CaseId = null];
            for(LiveChatTranscript transcript : transcripts) {
                transcript.CaseId = chatKeyCases.get(transcript.ChatKey);
            }

            // save the LiveChatTranscript for the case Id we have linked
            update transcripts;
        } catch(Exception exp){
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, LiveChatTranscriptUtility.class.getName(), 'linkCreatedCaseToTranscriptCurrentContext', SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
        }
    }

    
    /*@author: rajesh.punjabi@mav3rik.com
     *@description: create live chat feeditem.*/

    public static void addLiveChatTranscripttoFeedItem(List<LiveChatTranscript> lstLiveChatTrans){
        String sURL = URL.getSalesforceBaseUrl().toExternalForm();
        for(LiveChatTranscript lct : (List<LiveChatTranscript>) RecursionUtility.getUnprocessedRecords('LiveChatTranscriptFeedItem', lstLiveChatTrans, new Set<String>{'Status'})) {
            if(lct.Status == 'Completed' && !String.isBlank(lct.CaseId)){
                ConnectAPIUtility.createFeedItemforLiveChat(lct.CaseId, Utility.convertTextoRichText(lct.Body), lct.Id);
        	}
        }
    }


    public static void upDateIpAddress(List<LiveChatTranscript> newTranscripts){
        for(LiveChatTranscript newTranscript : newTranscripts){
                if(newTranscript.Visitor_Ip_Address__c != null) {
                    newTranscript.IpAddress = newTranscript.Visitor_Ip_Address__c;
                    newTranscript.Location = '';
                    newTranscript.VisitorNetwork = '';
                }
            }
        }
    }