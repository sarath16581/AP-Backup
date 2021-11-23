/**************************************************
Description:    Trigger
History:
--------------------------------------------------
2018-10-28  nathan.franklin@auspost.com.au  Created
**************************************************/
trigger LiveChatTranscriptTrigger on LiveChatTranscript (before insert, after update) {
    LiveChatTranscriptTriggerHandler.execute();
}