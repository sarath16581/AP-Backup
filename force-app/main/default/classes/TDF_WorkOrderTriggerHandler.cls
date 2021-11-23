/**
  * @author       : naseer.abbasi@auspost.com.au
  * @date         : 12/18/2020 (DEV)
  * @description  : Trigger handler for Work Orders
--------------------------------------- History --------------------------------------------------
* 20-Jan-2021   naseer.abbasi@auspost.com.au    created   
**/

public class TDF_WorkOrderTriggerHandler {
    public TDF_WorkOrderTriggerHandler() {}

    /**
     * Set the Attachment Count field on the Work Order
     * @param - old map & new map
     * @return - NA
     */
    public static void setAttachmentCount(Map<Id, WorkOrder> oldMap, Map<Id, WorkOrder> newMap) {
        Set<Id> workOrderSet = new Set<Id>();
        
        // map of total attachment for each work order record in context
        Map<Id, Decimal> attachmentCountMap = new Map<Id, Decimal>();
        
        for(WorkOrder wOrder : newMap.Values()) {
            if(oldMap.get(wOrder.Id).Status != 'Completed' && wOrder.Status == 'Completed') {
                workOrderSet.add(wOrder.Id);
            }
        }

        if(!workOrderSet.isEmpty()) {
            for(AggregateResult ar : [SELECT LinkedEntityId, count(Id) attachmentCount from ContentDocumentLink WHERE LinkedEntityId in :workOrderSet GROUP BY LinkedEntityId]) {
                attachmentCountMap.put((Id)ar.get('LinkedEntityId'), (Decimal)ar.get('attachmentCount'));
            }

            // updating Attachent_Count__c 
            for(WorkOrder wOrder : newMap.Values()) {
                if(attachmentCountMap.ContainsKey(wOrder.Id)) {
                    wOrder.Attachment_Count__c = attachmentCountMap.get(wOrder.Id);
                }else {
                    wOrder.Attachment_Count__c = 0;
                }         
            }
        }
    }
}