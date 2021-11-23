//Trigger used for Inventory Adjustments
trigger TDF_WorkOrderTrigger on WorkOrder (before update, after update){

    List<WorkOrder> workOrderList = new List<WorkOrder>();

    if(Trigger.isAfter){

        if(Trigger.isUpdate){
            
            for(WorkOrder objWorkOrder : Trigger.New){ 
                if(Trigger.oldMap.get(objWorkOrder.Id).Status != 'Completed' && objWorkOrder.Status == 'Completed'){
                    workOrderList.add(objWorkOrder);                
                }
                //AJ 31.07.18 Added. If PDC Copy set (done in flow TDF_Pre_Departure_Check) and Status = 'In Progress'
                if(Trigger.oldMap.get(objWorkOrder.Id).PDC_Copy__c == false && objWorkOrder.PDC_Copy__c == true){
                    if(objWorkOrder.Status == 'In Progress'){
                        workOrderList.add(objWorkOrder); 
                    }    
                }                
            }
            System.debug('workOrderList ->'+workOrderList+' Size->'+workOrderList.size());
            //AJ 19.06.18 Added condition to only call if size > 0
            if(workOrderList.size() > 0){
                TDF_WorkOrderTriggerUtility objWOUtil = new TDF_WorkOrderTriggerUtility(workOrderList);
                objWOUtil.workOrderUpdateMethod();
            }
        }
    }

    if(Trigger.isBefore) {
        if(Trigger.isUpdate) {
            TDF_WorkOrderTriggerHandler.setAttachmentCount(trigger.oldMap, trigger.newMap);
        }
    }
}