/** 
* @author Andrew Judd ajudd@salesforce.com 
* @date 2020-07-27
* @domain Field Service 
* @description Service all call of dispatch work from custom gantt action 'Dispatch Work' in FSL Gantt
*
* @changelog 
* 2020-07-14 - Andrew Judd - Created 
*/
global class TDF_DispatchWorkAction implements FSL.CustomGanttServiceResourceAction {

    global String action(Id resourceId, Id stmId, Datetime ganttStartDate, Datetime ganttEndDate, Map<String, Object> additionalParameters) {

		//Initialize
		String resultString;

		//Call dispatch work function        
		resultString = TDF_DispatchWork.dispatch(resourceId);
        
        //Get result to display
		return resultString;
        
    }
}