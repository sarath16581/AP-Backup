/**************************************************
Description:    Handles all the specific functionality when the LiveAgentTranscript trigger fires
@Test LiveChatTranscriptTriggerTest
History:
--------------------------------------------------
2018-10-28  nathan.franklin@auspost.com.au  Created
2021-08-05	Prerna Rahangdale : A new method upDateIpAddress added to overide the Standard Ip address with the Custom visitorId Address the smart speak chatbot payload, the Standard Ip address was populating the SS application Server address
2024-08-23	George Nguyen	Added newInstance(...) to enable mocking of legacy calls. 
**************************************************/
public with sharing class LiveChatTranscriptTriggerHandler {

	public static LiveChatTranscriptTriggerHandler getInstance() {
		return (LiveChatTranscriptTriggerHandler) Application.Utilities.getInstance(LiveChatTranscriptTriggerHandler.class);
	}

	public void executeLegacy() {
		LiveChatTranscriptTriggerHandler.execute();
	}
    
    public static void execute(){		
        if(Trigger.isBefore) {
            // invoke of before handler
            beforeHandler();
        }
        else if(Trigger.isAfter) {
            // invoke of after handler
            afterHandler();
        }
    }
    
    private static void beforeHandler(){
        // Check for type of operation
        if(Trigger.isInsert) {
            // This will find any case created during a Live Chat engagement and link it back to the transcript.
            // This is necessary because without OMNI, LiveChatTranscript records are only created after the Live Chat engagement
            LiveChatTranscriptUtility.linkCreatedCaseToTranscript((List<LiveChatTranscript>)Trigger.new);
            LiveChatTranscriptUtility.upDateIpAddress((List<LiveChatTranscript>)Trigger.new);
        }
    }
    
    private static void afterHandler() { 
        if(Trigger.IsUpdate){
           LiveChatTranscriptUtility.addLiveChatTranscripttoFeedItem((List<LiveChatTranscript>)Trigger.New);
        }
    }
}