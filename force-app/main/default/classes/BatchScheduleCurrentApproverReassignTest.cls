/**
 * Date             Version          Owner              Desription
 * 01-Aug-17         1.0            Bharat P        Test class for BatchScheduleCurrentApproverReassignment
 */
@isTest
public class BatchScheduleCurrentApproverReassignTest {

    /* Test Method for Schedule of Batch Class for Reassignment of the Current Approver*/
    public static testMethod void testBatchScheduleApproverReassignment(){
		try{
        	Test.startTest();
            String sch = '0 0 0,2,4,6,8,10,12,14,16,18,20,22 ? * *';
            System.schedule('Test batchScheduleCAReassign', sch, new BatchScheduleCurrentApproverReassignment());        
        	Test.stopTest();            
        }catch(Exception e){
            e.getStackTraceString();    
        }
    }
}