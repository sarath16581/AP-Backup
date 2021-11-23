/** 
* @author Andrew Judd ajudd@salesforce.com 
* @date 2020-08-12
* @domain Field Service  
* @description Service to expose delete work as custom action 'Delete Work' from the FSL Gantt
*
* @changelog 
* 2020-08-12 - Andrew Judd - Created 
*/
global class TDF_DeleteWorkAction implements FSL.CustomGanttServiceResourceAction {

    global String action(Id resourceId, Id stmId, Datetime ganttStartDate, Datetime ganttEndDate, Map<String, Object> additionalParameters) {

		//Initialize
		String resultString;
        Date startDate;
        WorkOrder woRec;
        List<WorkOrder> woListDelete = new List<WorkOrder>();
        String dutyName;
		
        //Get start date from the gantt
        startDate = Date.newInstance(ganttStartDate.year(), ganttStartDate.month(), ganttStartDate.day());
        
        //Get all work order via SAs assigned to the selected duty for the current day
        //Not in status Dispatch, In Progress or Completed
        List<AssignedResource> assResList = [SELECT Id, ServiceAppointment.Work_Order__c, ServiceResource.Name  
                                                FROM AssignedResource
                                             	WHERE ServiceResourceId = :resourceId 
                                             	AND ServiceAppointment.Work_Order__r.Duty_Day__c = :startDate 
                                            	AND ServiceAppointment.Status != 'Completed' 
                                             	AND ServiceAppointment.Status != 'In Progress' 
                                             	AND ServiceAppointment.Status != 'Dispatched'];

        //If work orders assigned to the resource a returned                                         
        if(assResList.size() > 0){

            //Create work order delete list
            for(AssignedResource assRes : assResList){
                woRec = new WorkOrder(Id = assRes.ServiceAppointment.Work_Order__c);
                woListDelete.add(woRec);
                dutyName = assRes.ServiceResource.Name;
            }
            
            //Delete records
        	delete woListDelete;
        	return 'Work Orders deleted (' + assResList.size() + ') from '+ dutyName + ' on ' + ganttStartDate.format('dd MMM');
        }
        else{
            return 'No Work Orders found to delete on ' + ganttStartDate.format('dd MMM');
        }
    }
}