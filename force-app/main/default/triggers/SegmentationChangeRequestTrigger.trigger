/**************************************************
Type:       Trigger for Segmentation_Change_Request__c Object
Purpose:    Derives the Sales Segment for a Segmentation_Change_Request__c from a reference data object
History:
--------------------------------------------------
26.06.2012    M. Isidro (Cloud Sherpas)         Created
03.08.2012    Richard Enojas (Salesforce.com    Updated to include filtering based on SCR status (New/Recalled/Rejected)
13.02.2017    Eric Shen                         Consolidate SCCR Trigger to a framework
**************************************************/
trigger SegmentationChangeRequestTrigger on Segmentation_Change_Request__c (before insert, after insert,
 before update, after update,  before delete, after delete) {
if (!SystemSettings__c.getInstance().Disable_Triggers__c) {
        /*   if (trigger.isBefore && trigger.isInsert || trigger.isBefore && trigger.isUpdate){
            List<Segmentation_Change_Request__c> scrlist = new List<Segmentation_Change_Request__c>();
            for (Segmentation_Change_Request__c scr : trigger.new){
                if (scr.Approval_Status__c == 'New' || scr.Approval_Status__c == 'Recalled' || scr.Approval_Status__c == 'Rejected')
                    scrlist.add(scr);
            }
            
            if(!scrlist.isEmpty())
                SegmentationUtil.updateSalesSegment(scrlist);
        }     */  

    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
   //14-Feb-17 Eric Shen prevent duplicate SCCR records raised by same person for same customer in submitted or approved stage         
       SegmentationUtil.alertOnlyOneSubmitterPerAccount(Trigger.new);
        } 
        if (Trigger.isUpdate) {
  //14-Feb-17 Eric Shen will make the rejection comments mandatory. 
        SegmentationUtil.segmentationRequireRejectionComment(Trigger.new);
        }
        if (Trigger.isDelete) {
      // Call class logic here!
        }
    }

    if (Trigger.IsAfter) {
        if (Trigger.isInsert) {
      // Call class logic here!
         } 
    if (Trigger.isUpdate) {
      // Call class logic here!
        }
    if (Trigger.isDelete) {
      // Call class logic here!
        }
}  

}

}