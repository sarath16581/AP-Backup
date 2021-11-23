trigger TDF_ServiceAppointmentTrigger on ServiceAppointment (after insert) {

    if(Trigger.isAfter){

        if(Trigger.isInsert){
            //Trigger to set Primary SA on Work Order. Created for Transport reporting 19.06.2018
            Map<String, String> parentSAMap = new Map<String, String>();
            Set<String> parentRecords = new Set<String>();
          
            //Loop through inserted SAs
            for(ServiceAppointment objServiceAppointment : Trigger.New){                              
                //Step 1: Build map with parentId and SAId
                parentSAMap.put(objServiceAppointment.ParentRecordId,objServiceAppointment.Id);       
                //Step 2: Create a set of all Parent records to evaluate
                parentRecords.add(objServiceAppointment.ParentRecordId);          
            }
            
            //Step 3: Get all parent records that are Work Orders
            List<WorkOrder> workOrderList = [SELECT Id, Primary_SA__c FROM WorkOrder WHERE Id IN :parentRecords];
            
            //Step 4: Loop through work order list and set Primary SA from map
            for(WorkOrder objWorkOrder : workOrderList)
            {
                objWorkOrder.Primary_SA__c = parentSAMap.get(objWorkOrder.Id);
            }
            
            if(workOrderList.size() > 0){
                update workOrderList;
            }
        }
    }
}