/**
Description: To make Approval Rejection/Submission Comments mandatory
Created By: Raviteja Epuri
Created Date: 21th Dec, 2015
Last Modified By: Krishna Velani
Last Modified Date: 19th May 2021 STP-5156 Populate OOTB Related Proposal & Related Opportunity fields on AR
*/
trigger APT_ApprovalRequestTrigger on Apttus_Approval__Approval_Request__c (before insert, after insert, after update,before update) {
    if(trigger.isBefore &&  trigger.isUpdate) {        
            String result = APT_ApprovalRequestTriggerHandler.beforeUpdateEvent(trigger.new,trigger.oldMap);
            if(result != APT_Constants.SUCCESS_LABEL){
                for(Apttus_Approval__Approval_Request__c appReq : trigger.new) {
                    appReq.Apttus_Approval__Approver_Comments__c.addError(result);
                }               
            }
        }
        if(trigger.isAfter && trigger.isUpdate) {
            list<Apttus_Approval__Approval_Request__c> listApprovalRequest=new list<Apttus_Approval__Approval_Request__c>();
            list<Apttus_Approval__Approval_Request__c> lstApprovedReq=new list<Apttus_Approval__Approval_Request__c>();
            set<Id> setLIIds =new set<Id>();
            for(Apttus_Approval__Approval_Request__c app: trigger.new){              
                if(app.Apttus_Approval__Approver_Comments__c!=trigger.oldMap.get(app.Id).Apttus_Approval__Approver_Comments__c){                  
                  lstApprovedReq.add(app);
                  setLIIds.add(app.Apttus_Approval__ChildObjectId__c);          
                }
                       
                if(app.Apttus_Approval__StepLabel__c == APT_Constants.PROPOSAL_OVERWEIGHT_ITEM 
                                || app.Apttus_Approval__StepLabel__c == APT_Constants.PROPOSAL_DGT
                                || app.Apttus_Approval__StepLabel__c == APT_Constants.PROPOSAL_DOMESTIC_OVERWEIGHT_ITEM
                                || app.Apttus_Approval__StepLabel__c== APT_Constants.PROPOSAL_INTERNATIONAL_OVERWEIGHT_ITEM
                                || app.Apttus_Approval__StepLabel__c== APT_Constants.PROPOSAL_INTERNATIONAL_ITEM
                                || app.Apttus_Approval__StepLabel__c == APT_Constants.PROPOSAL_UMS_OVERWEIGHT_ITEM){
                     
                    listApprovalRequest.add(app);
                }         
            } 
            
            String result = APT_ApprovalRequestTriggerHandler.afterUpdateEvent(listApprovalRequest); 
            if(result != APT_Constants.SUCCESS_LABEL){
                for(Apttus_Approval__Approval_Request__c appReq : trigger.new) {
                    appReq.Apttus_Approval__Approver_Comments__c.addError(result);
                }               
            }
            
            if(lstApprovedReq.size()>0){            
            result= APT_ApprovalRequestTriggerHandler.copyApprovalComments(lstApprovedReq,setLIIds);
            if(result!= APT_Constants.SUCCESS_LABEL){
                for(Apttus_Approval__Approval_Request__c appReq : trigger.new) {
                    appReq.Apttus_Approval__Approver_Comments__c.addError(result);
                } 
              }                
            }
          }
     //STP-5156 added by Krishna Velani
        if(trigger.isUpdate && trigger.isBefore) {
        //APT_ApprovalRequestTriggerHandler.UpdateOwner(trigger.new);
        APT_ApprovalRequestTriggerHandler.updateRelated(trigger.new);
       }
       // STP-6349 | field change from formula field to text area end 
       
 }