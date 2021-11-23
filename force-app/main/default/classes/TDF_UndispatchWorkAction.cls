/** 
* @author Andrew Judd ajudd@salesforce.com 
* @date 2020-08-11
* @domain Field Service 
* @description  Service to call undispatch work from custom FSL Gantt action 'Undispatch Work' on the selected Service Resource record
*
* @changelog 
* 2020-08-11 - Andrew Judd - Created 
*/
global class TDF_UndispatchWorkAction implements FSL.CustomGanttServiceResourceAction {

    global String action(Id resourceId, Id stmId, Datetime ganttStartDate, Datetime ganttEndDate, Map<String, Object> additionalParameters) {

		//Initialize
		String resultString;

		//Call dispatch work function to undispatch        
		resultString = TDF_DispatchWork.undispatch(resourceId);
        
        //Get result to display
		return resultString;
        
    }

}