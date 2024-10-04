/**
  * @author	Nathan Franklin
  * @date 2018-10-28
  * @description Trigger for handling LiveChatTranscript object
  * @changelog
  * 2024-08-01 - Nathan Franklin - Uplifted to module framework
  */
trigger LiveChatTranscriptTrigger on LiveChatTranscript (before insert, before update, after insert, after update) {
    (new LiveChatTranscriptAutomationTrigHandler()).dispatch();
}