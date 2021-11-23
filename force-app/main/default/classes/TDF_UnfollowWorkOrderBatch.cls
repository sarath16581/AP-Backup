global class TDF_UnfollowWorkOrderBatch implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {     
        //AJ 24.09.18 Changed range from 1 to 3 days
        String query = 'SELECT ParentRecordId, SchedStartTime, SchedEndTime, (SELECT Id, ServiceResourceId, ServiceResource.RelatedRecordId FROM ServiceResources) FROM ServiceAppointment WHERE ParentRecord.Type = '+'\''+'WorkOrder'+ '\' and SchedStartTime = LAST_N_DAYS:3';
        System.debug('query -> '+query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<ServiceAppointment> serviceAppointmentList){
        
        for(ServiceAppointment objSA : serviceAppointmentList){
        TDF_AutoFollowHelper.unfollowScheduler(objSA);
        }
    }    
    
    global void finish(Database.BatchableContext bc){
        
    }    
}