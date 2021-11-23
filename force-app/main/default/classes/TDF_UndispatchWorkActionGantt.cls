/** 
* @author Andrew Judd ajudd@salesforce.com 
* @date 2020-09-16
* @domain Field Service 
* @description  Service to call undispatch work from custom FSL Gantt action 'Undispatch Work' on selected service appointments in the Gantt chart
*
* @changelog 
* 2020-09-16 - Andrew Judd - Created 
*/
global class TDF_UndispatchWorkActionGantt implements FSL.CustomGanttServiceAppointmentAction {

    global String action(List<Id> serviceAppointmentsIds, Datetime strGanttStartDate, Datetime strGanttEndDate, Map<String, Object> additionalParameters) {

        //Initialize
        String resultString;
        
        //Call undispatch work function to undispatch        
        resultString = TDF_DispatchWork.undispatchGantt(serviceAppointmentsIds);
        
        //Get result to display
        return resultString;

    }
}