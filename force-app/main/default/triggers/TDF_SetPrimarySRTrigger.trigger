/** 
* @author Andrew Judd
* @date 2018-06-19
* @domain Field Service 
* @description  Trigger to set Primary SR on ServiceAppointment
*
* @changelog 
* 2020-09-21 - Andrew Judd - Deactivated and Moved to standard trigger handler construct as follows:
*                               AssignedResourceTrigger
*                                   >AssignedResourceTriggerHandler
*                                       >TDF_AssignedResourceTriggerHandler.setServiceAppointmentPrimarySR
*/
trigger TDF_SetPrimarySRTrigger on AssignedResource (after insert, after update) {
    // if(Trigger.isAfter){

    //     if(Trigger.isInsert || Trigger.isUpdate){
            
    //         //Trigger to set Primary SR on ServiceAppointment. Created for Transport reporting 19.06.2018
    //         Map<String, String> primarySRMap = new Map<String, String>();
    //         Set<String> serviceAppointments = new Set<String>();
          
    //         //Loop through inserted Assigned Resource records
    //         for(AssignedResource objAssRes : Trigger.New){                               
                
    //             //If insert or SRId has changed
    //             if(Trigger.isInsert || (Trigger.isUpdate && Trigger.oldMap.get(objAssRes.Id).ServiceResourceId != objAssRes.ServiceResourceId)){
    //                 //Step 1: Build map with SAId and SRId
    //                 primarySRMap.put(objAssRes.ServiceAppointmentId,objAssRes.ServiceResourceId); 
                    
    //                 //Step 2: Create a set of all SA records to set primary on
    //                 serviceAppointments.add(objAssRes.ServiceAppointmentId);
    //             }
    //         }
            
    //         //Step 3: Get all SA records to set primary on
    //         List<ServiceAppointment> svcApptList = [SELECT Id, Primary_SR__c FROM ServiceAppointment WHERE Id IN :serviceAppointments];
            
    //         //Step 4: Loop through SA list and set Primary SR from map
    //         for(ServiceAppointment objSA : svcApptList)
    //         {
    //             objSA.Primary_SR__c = primarySRMap.get(objSA.Id);
    //         }
            
    //         if(svcApptList.size() > 0){
    //             update svcApptList;
    //         }
    //     }
    // }
}