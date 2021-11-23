/**************************************************
Type:       	Apex Schedulable Batch Job Class for Revenues Rollup of Opportunity Product Classification (OPC)
@Description:	Roll up the Total Schedule Revenue to Date and the Total Actual Revenue to Date from Opportunity Product Classification (OPC)
				to the associated Opportunity, so that the Account Manager or Sales Manager can see daily snapshots of the Sales performance
				It is scheduled to be run daily.
History:
--------------------------------------------------
29.10.2020  seth.heang@auspost.com.au   Created
**************************************************/
global without sharing class OPCRevenuesRollUpSchedulable implements Schedulable {

    /**
      * @description       execute method, Runs OPCRevenuesRollUpBatchable Job
      * @param             SchedulableContext
      * @return            void
      */ 
    global void execute(SchedulableContext sc) {
        // Call OPC Revenue Roll Up Batch Job and set batch size to 2000
        OPCRevenuesRollUpBatchable rollUpOPCBatch = new OPCRevenuesRollUpBatchable();
        Database.executeBatch(rollUpOPCBatch, 2000);
    }  
}