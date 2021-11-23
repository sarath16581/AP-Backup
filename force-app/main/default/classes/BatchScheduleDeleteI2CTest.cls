/**
* Author: 		Angelo Rivera
* Name: 		BatchScheduleDeleteI2CTest
* Description: 	Test Class for BatchScheduleDeleteI2CTemporaryDocuments
* Revision History
* 07-12-2017 	1.0		AP.Rivera		Created
**/
@isTest
private class BatchScheduleDeleteI2CTest {
	
	@isTest static void test_BacthSchedule() {
        
        Test.startTest();
        
        BatchScheduleDeleteI2CTemporaryDocuments batchScheduleDeleteDoc = new BatchScheduleDeleteI2CTemporaryDocuments();
        String sch = '0 0 0,2,4,6,8,10,12,14,16,18,20,22 ? * *';
        System.schedule('Test batchScheduleDeleteDoc', sch, batchScheduleDeleteDoc );
        
        Test.stopTest(); 
	}
}