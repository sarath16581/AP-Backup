/** 
* @author Andrew Judd ajudd@salesforce.com 
* @date 2020-09-21
* @domain Field Service  
* @description Handler to process changes to Assigned Resource detected in AssignedResourceTrigger
*
* @changelog 
* 2020-09-22 - Andrew Judd - Changed recursion prevention to record inserts and updates separately
* 2020-09-29 - Andrew Judd - Added set of Service_Resource__c as the primary Driver Service resource on the SA
* 2021-10-13 - Alvin Zhou  - Allow the assign to user will automatically assigning to the service crew. Add new methods:
*                               checkServiceCrew (List<SObject> records)
*                               reassignServiceResource (Map<String, AssignedResource> assignedResources)
*                               checkServiceCrew (List<SObject> records, Map<Id, SObject> oldRecords) 
* 2021-10-25 - Alvin Zhou  - Used to skip the validations for the dispatch validations 
*
*/
public with sharing class TDF_AssignedResourceTriggerHandler {
    
    //Initialise var to store set of Ids processed in the transation
    //Note that the FSL managed package reports the Insert event after the Update event
    //and the update event has no change in the SR, resulting it no detection of SR set
    //To manage this we record processed inserts and updates separately, and process each once
    Public static Set<Id> assResIdInsertProcessedSet = new Set<Id>();
    Public static Set<Id> assResIdUpdateProcessedSet = new Set<Id>();

    
    public void checkServiceCrew(List<SObject> records) {
        // Firstly grab the sa id => aR to check if 
        // the service appointment id has got the C type crew
        Map<String, AssignedResource> saId2AR = new Map<String, AssignedResource>(); 
        for(AssignedResource record: (List<AssignedResource>) records) {
            // Grab the service resource whose resource type is not "C"
            if(record.Service_Resource_Type__c != 'C') {
                saId2AR.put(record.ServiceAppointmentId, record);
            } 
        }
        // One more ran to make sure the bulkify scenario 
        // when a list of assigned resource that has got same serviceappointment with 2 or more assigned resoruce
        for(AssignedResource record: (List<AssignedResource>) records) {
            // Grab the service resource whose resource type is not "C"
            if(record.Service_Resource_Type__c == 'C') {
                saId2AR.remove(record.ServiceAppointmentId);
            } 
        }
        // Query for the same service appointments to see 
        // if the service appointment has already got Crew Service Resources.
        if(!saId2AR.isEmpty()) {
            List<AssignedResource> crewAssignedResources = [Select Id, ServiceAppointmentId 
                from AssignedResource where Service_Resource_Type__c = 'C' 
                and ServiceAppointmentId in: saId2AR.keySet()];
            // If there is one related assigned resource that has got the C type related,
            // Just remove from the map saId2AR.
            for(AssignedResource record: crewAssignedResources) {
                saId2AR.remove(record.ServiceAppointmentId);
            }

            Map<String, List<AssignedResource>> assignedResources = new Map<String, List<AssignedResource>>();

            for(AssignedResource record: saId2AR.values()) {
                List<AssignedResource> resources = new List<AssignedResource>();
                resources.add(record);
                if(assignedResources.containsKey(record.ServiceResourceId)) {
                    resources = assignedResources.get(record.ServiceResourceId);
                }
                assignedResources.put(record.ServiceResourceId, resources);
            }
            if(!assignedResources.isEmpty()) {
                reassignServiceResource(assignedResources);
            }
            
        }

    }
    // used to reconnect the assigned services with crew type of the assigned resource.
    public void reassignServiceResource(Map<String, List<AssignedResource>> assignedResources) {
        if(!assignedResources.isEmpty()) {
            // Query the Service Crew Member records that connect the assigned resource.
            List<ServiceCrewMember> members = [Select Id, ServiceResourceId, StartDate, EndDate, ServiceCrewId
             from ServiceCrewMember where ServiceResourceId =: assignedResources.keySet()];
            List<String> crewIds = new List<String>();
             for(ServiceCrewMember member: members) {
                crewIds.add(member.ServiceCrewId);
            }
            if(!crewIds.isEmpty()) {
                List<ServiceResource> crewList = [Select Id, ServiceCrewId from ServiceResource where ServiceCrewId in: crewIds];
                Map<String, String> crewMap = new Map<String, String>();
                for(ServiceResource crew: crewList) {
                    crewMap.put(crew.ServiceCrewId, crew.Id);
                }
                for(ServiceCrewMember member: members) {
                    String serviceResourceId = member.ServiceResourceId;
                    for(AssignedResource assignedRecord: assignedResources.get(serviceResourceId) ) {
                        if(assignedRecord.Scheduled_Start__c >= member.StartDate && assignedRecord.Scheduled_Start__c <= member.EndDate) {
                            assignedRecord.ServiceCrewId = member.ServiceCrewId;
                            assignedRecord.ServiceResourceId = crewMap.get(member.ServiceCrewId);
                        }
                    }
                }
            }
        }
    }



    public void checkServiceCrew(List<SObject> records, Map<Id, SObject> oldRecords) {
        Map<String, List<AssignedResource>> assignedResources = new Map<String, List<AssignedResource>>(); 
        for(AssignedResource record: (List<AssignedResource>) records) {
            AssignedResource oldRecord = (AssignedResource) oldRecords.get(record.Id);
            if(record.ServiceResourceId != oldRecord.ServiceResourceId && 
                record.Service_Resource_Type__c != 'C') {
                List<AssignedResource> resources = new List<AssignedResource>();
                if(assignedResources.containsKey(record.ServiceResourceId)) {
                    resources = assignedResources.get(record.ServiceResourceId);
                }
                resources.add(record);
                assignedResources.put(record.ServiceResourceId, resources);
            } 
        }
        if(!assignedResources.isEmpty()) {
            reassignServiceResource(assignedResources);
        }
    }
    //The purpose of this function is to set the primary service resource against the service appointment in field Primary_SR__c, and
    //the driver service resource in field Service_Resource__c
    //If there is more than one assigned resource, then the duty service resource must be set as the primary.  
    //In other words a driver service resource can only be the primary if no duty is assigned to the service appointment.
    public void setServiceAppointmentPrimarySR(List<AssignedResource> assResList,Map<Id,AssignedResource> oldMap){

        //Initilise
        Map<Id,Id> saIdToDriverSRIdMap = new Map<Id,Id>();
        Map<Id,Id> saIdToDutySRIdMap = new Map<Id,Id>();
        Set<Id> saIdSet = new Set<Id>();
        Set<Id> saWithDutyAssignedSet = new Set<Id>();
        Boolean saToUpdate = false;
        Boolean assResProcessed = false;

        //Loop through inserted Assigned Resource records
        for(AssignedResource objAssRes : assResList){ 
            //If insert
            if(oldMap == null){
                //If record in insert processed set
                if(assResIdInsertProcessedSet.contains(objAssRes.Id) == true){
                    //Set processed flag to true
                    assResProcessed = true;
                }
                //Record insert processed
                assResIdInsertProcessedSet.add(objAssRes.Id);
            }
            //Else update
            else{
                //If record in update processed set
                if(assResIdUpdateProcessedSet.contains(objAssRes.Id) == true){
                    //Set processed flag to true
                    assResProcessed = true;
                }
                //Record update processed
                assResIdUpdateProcessedSet.add(objAssRes.Id);
            }

            //If Assigned Resource insert or update not processed in this transaction, or if test running
            if(assResProcessed == false || Test.isRunningTest()){

                //If insert (old map null) or if update and service resource has changed
                if(oldMap == null || (oldMap.get(objAssRes.Id).ServiceResourceId != objAssRes.ServiceResourceId)){

                    //1. Add details to respective maps
                    //If assignment is for a driver (technician)
                    if(objAssRes.Service_Resource_Type__c == 'T'){
                        //Add service appointent and driver service resource id to map, and record service appointment
                        saIdToDriverSRIdMap.put(objAssRes.ServiceAppointmentId,objAssRes.ServiceResourceId);
                        saIdSet.add(objAssRes.ServiceAppointmentId);
                    }
                    //Else if assignment is for a duty (crew)
                    else if(objAssRes.Service_Resource_Type__c == 'C'){
                        //Add service appointent and duty service resource id to map, and record service appointment
                        saIdToDutySRIdMap.put(objAssRes.ServiceAppointmentId,objAssRes.ServiceResourceId);
                        saIdSet.add(objAssRes.ServiceAppointmentId);
                    }
                }
            }
        }

        //If service appointment records to check
        if(saIdSet.size() > 0){

            //If any driver assignments
            if(saIdToDriverSRIdMap.size() > 0){

                //For all service appointments with a new or updated driver assignment, which already have a duty assigned
                for(AssignedResource assRes : [SELECT ServiceAppointmentId 
                                                FROM AssignedResource 
                                                WHERE ServiceAppointmentId IN :saIdToDriverSRIdMap.keySet() 
                                                AND Service_Resource_Type__c = 'C']){

                    //Record Id in set of service appointments that currently have a duty asignment
                    saWithDutyAssignedSet.add(assRes.ServiceAppointmentId);
                }
            }

            //Get all service appointments to set primary against 
            List<ServiceAppointment> saList = [SELECT Id, Primary_SR__c, Service_Resource__c FROM ServiceAppointment WHERE Id IN :saIdSet];
            
            //If there are service appointment records to update
            if(saList.size() > 0){

                //For all service appointments
                for(ServiceAppointment sa : saList){

                    //If a duty is being assigned
                    if(saIdToDutySRIdMap.containsKey(sa.Id) == true){
                        //Then set this duty as the primary
                        sa.Primary_SR__c = saIdToDutySRIdMap.get(sa.Id);
                        saToUpdate = true;
                    }
                    //Else duty is not being assigned
                    else{
                        //If service appointment does not have an exsting duty assignment
                        if(saWithDutyAssignedSet.contains(sa.Id) == false){
                            //Then set this driver as the primary
                            sa.Primary_SR__c = saIdToDriverSRIdMap.get(sa.Id);
                            //saToUpdate = true;
                        }
                        //And set the Driver Service Resource field
                        sa.Service_Resource__c = saIdToDriverSRIdMap.get(sa.Id);
                        saToUpdate = true;
                    }
                }
                //If any changes to apply
                if(saToUpdate == true){
                    //Update record
                    update saList;
                }
            }
        }
    }
    // Used to skip the validations for the dispatch jobs
    public void skipValidations(List<SObject> records,Map<Id, SObject> oldRecords) {
        List<String> serviceAppointmentIds = new List<String>();
        
        for(AssignedResource record: (List<AssignedResource>)records) {
            AssignedResource oldRecord = (AssignedResource) oldRecords.get(record.Id);
            if(record.ServiceResourceId != oldRecord.ServiceResourceId) {
                serviceAppointmentIds.add(record.ServiceAppointmentId);
            }
        }

        if(!serviceAppointmentIds.isEmpty()) {
            // Query for the work order to see if 
            // there are any work order line items
            List<String> parentIds = new List<String>();

            List<ServiceAppointment> appointments = [Select Id, ParentRecordId from ServiceAppointment 
                where Id in: serviceAppointmentIds];
            for(ServiceAppointment record: appointments) {
                parentIds.add(record.ParentRecordId);
            }

            List<WorkOrder> workOrders = [Select Id, 
                (select Id, Skip_Validation__c from Deliver_To_Work_Order_Line_Items__r),
                (select Id, Skip_Validation__c from Collect_From_Work_Order_Line_Items__r) from WorkOrder 
                where Id in: parentIds
            ];
            Map<Id, WorkOrderLineItem> lineItems = new Map<Id, WorkOrderLineItem>();
            for(WorkOrder wk: workOrders) {
                for(WorkOrderLineItem item: wk.Deliver_To_Work_Order_Line_Items__r) {
                    item.Skip_Validation__c = true;
                    lineItems.put(item.Id, item);
                }
                for(WorkOrderLineItem item: wk.Collect_From_Work_Order_Line_Items__r) {
                    item.Skip_Validation__c = true;
                    lineItems.put(item.Id, item);
                }
            }
            if(!lineItems.isEmpty()) {
                update lineItems.values();
            }
        }
    }
}