/**
* Author: Angelo Rivera
* Name: BatchScheduleCreditApprovalEscalation
* Description: Schedule Batch Class BatchCreditApprovalEscalation.
* Revision History
* 07-12-2017 	1.0		AP.Rivera		Created
**/

global without sharing class BatchScheduleCreditApprovalEscalation implements Schedulable{
	global void execute(SchedulableContext sc){       
        // We now call the batch class to be scheduled
        BatchCreditApprovalEscalation b = new BatchCreditApprovalEscalation ();       
        //Parameters of ExecuteBatch(context,BatchSize)
        database.executebatch(b,100);
	}
}