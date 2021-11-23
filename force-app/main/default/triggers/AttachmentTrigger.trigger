/******************************************************************************************
    
    Author:         Stephen James Laylo
    Date Created:   04/02/2015
    Description:    Trigger for Attachment Object
    
    Change Log:
    Date:          Author:                  Description:
    04/02/2016     Stephen James Laylo      Created
    14/03/2016	   Lyndon Lavapie			Added after delete event
    19/12/2016     Davey Yu                 Added validation if attachment trigger is enabled to run
*******************************************************************************************/
trigger AttachmentTrigger on Attachment (before insert, after insert, before update, after update, after delete) {
    //Added by DYU Dec 2016 - Check if trigger is allowed to run
    if (!SystemSettings__c.getInstance().Disable_Attachment_Trigger__c) { 
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                AttachmentTriggerHandler.preventNewAttachments(Trigger.new);
                //AttachmentTriggerHandler.renameGeneratedAttachmentsOfAgreementDocument(Trigger.new);
            }
            
            if (Trigger.isUpdate) {
                AttachmentTriggerHandler.preventNewAttachments(Trigger.new);
                //AttachmentTriggerHandler.renameGeneratedAttachmentsOfAgreementDocument(Trigger.new);
            }
        }
        
        if (Trigger.isAfter) {
            if (Trigger.isInsert) {
                AttachmentTriggerHandler.stampAgreementDocumentGeneratedDate(Trigger.new);
            }
            
            if (Trigger.isUpdate) {
                AttachmentTriggerHandler.stampAgreementDocumentGeneratedDate(Trigger.new);
            }
            
            if (Trigger.isDelete){
                AttachmentTriggerHandler.createActivityHistoryForDeletedAgreeentDocumentAttachment(Trigger.Old);
                // Modified by: conrad.c.v.borbon on September 20, 2018 - START
                // Description: Change added to reference linkExistingFiles method.
                //              Method will execute file linking from apttus contract to clone
                //              sf contract after the attachments are all deleted.
                AttachmentTriggerHandler.linkExistingFiles(Trigger.Old);
                // modified by conrad.c.v.borbon on September 20, 2018 - END
            }
        }
    }
}