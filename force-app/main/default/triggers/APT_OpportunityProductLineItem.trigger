/**

Created By: Himanshu Jain 
Created Date:8th Mar, 2016
Last Modified By:
Last Modified Date:
*/
trigger APT_OpportunityProductLineItem on OpportunityLineItem (before delete) {
     if (trigger.isBefore && trigger.isDelete){
        String errormessage = Label.APT_Error_Message_for_Opportunity_Lineitem;
        List<OpportunityLineItem> toBeDeletedOLI = new List<OpportunityLineItem>();
        List<Profile> PROFILE = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
        String MyProflieName = PROFILE[0].Name;
         /* Shashwat.Nath@Auspost.com has commented the below line of code on 09/09/2020 to remove the profile clause because the going forward the 
            there would be automated deletion of Opportunity Products linked to non primary proposals for all the users */
            
        for(OpportunityLineItem oli : trigger.old){
           /* if(oli.APT_Is_Apttus_Opportunity_Line_item__c && !oli.APT_Apttus_Delete_Override__c && MyProflieName!= 'System Administrator') {
                oli.addError(errormessage);
            }*/
            
             /* Shashwat.Nath @auspost.com code ends */
            if(oli.APT_Is_Apttus_Opportunity_Line_item__c && !oli.APT_Apttus_Delete_Override__c) {
                oli.addError(errormessage);
           } 
        }
     }
}