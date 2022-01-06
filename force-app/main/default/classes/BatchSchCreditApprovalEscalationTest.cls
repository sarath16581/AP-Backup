/**
 * Date             Version          Owner              Desription
 * 08-Sep-17         1.0            Bharat P        Test class for BatchScheduleCreditApprovalEscalation
 */
@isTest
public class BatchSchCreditApprovalEscalationTest{
    
    /* Test Method for Schedule of Batch Class for Credit Approval Escalation*/
    public static testMethod void testBatchScheduleCAEscalation(){
    	try{
    		Test.startTest();
        	String sch = '0 0 0,2,4,6,8,10,12,14,16,18,20,22 ? * *';
        	System.schedule('Test batchScheduleCAEscalate', sch, new BatchScheduleCreditApprovalEscalation());        
        	Test.stopTest();            
    	}catch(Exception e){
        	e.getStackTraceString();    
    	}
    }
}