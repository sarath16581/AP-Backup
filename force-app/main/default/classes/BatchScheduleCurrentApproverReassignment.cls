/**
 * Date             Version          Owner              Desription
 * 26-July-17         1.0           Bharat P        Initial Version - Schedule Batch Class BatchUpdateCurrentApproverReassignment.		
 */
global class BatchScheduleCurrentApproverReassignment implements Schedulable{
    
    global void execute(SchedulableContext sc){      
        //Parameters of ExecuteBatch(context,BatchSize)
        database.executebatch(new BatchUpdateCurrentApproverReassignment(), 100);
	}
}