/** 
* @author Andrew Judd ajudd@salesforce.com 
* @date 2020-08-01
* @domain Field Service 
* @description Class for the Close Message action available from the Service Appointment list (left hand panel) from the FSL Gantt
*               Calls the function to clear the 'Add Message Recieved' text on the subject and set the Response and Active messaging flags to false
*
* @changelog 
* 2020-08-01 - Andrew Judd - Created 
*/
global class TDF_MessageCloseAction implements FSL.CustomGanttServiceAppointmentAction {
 
    global String action(List<Id> serviceAppointmentsIds, Datetime ganttStartDate, Datetime ganttEndDate, Map<String, Object> additionalParameters) {
       
        List<Boolean> controlFlagsResetList = new List<Boolean>{false,false,false};
        Map<Id,List<Boolean>> woIdWithControlFlagsMap = new Map<Id,List<Boolean>>();

        //Get selected sas with wo id
        List<ServiceAppointment> saList = [SELECT Id, ParentRecordId FROM ServiceAppointment WHERE Id in : serviceAppointmentsIds];

        //For all the selected service appointments
        for (ServiceAppointment sa : saList) {
            //add them to the input map
            woIdWithControlFlagsMap.put(sa.ParentRecordId,controlFlagsResetList.clone());
        }

        //If records to process
        if(woIdWithControlFlagsMap.size() > 0){
            //Call the function with input map
            TDF_UpdateServiceAppointmentOnMessage.updateSASubjectAndFlags(woIdWithControlFlagsMap);
        }

        //return confirmation message to the notification
        return 'Messaging on the Service Appointment now closed.';
    }
}