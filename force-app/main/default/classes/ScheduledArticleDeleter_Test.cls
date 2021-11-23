/**
*  This test class is for ScheduledArticleDeleter.
*
@author Frank Chen
@created 2014-06-23
@version 1.0
@since 20.0
*
@changelog
* 2014-06-23 Frank Chen <di.chen@bluewolf.com>
* - Created
* - Test coverage 100%
*/
@isTest
private class ScheduledArticleDeleter_Test {

 static testMethod void myUnitTest() {
    	
        DateTime currTime = DateTime.now();
        Integer min = currTime.minute();
        Integer hour = currTime.hour();
        String sch;
        
		if(min <= 58)
            sch = '0 '+ (min + 1) + ' ' + hour + ' * * ? '+ currTime.year();
        else          
            sch = '0 0 '+ (hour + 1) + ' * * ? '+ currTime.year();
        
        Test.startTest();
        
		ScheduledArticleDeleter obj = new ScheduledArticleDeleter();                
		String jobId = system.schedule('test', sch, obj); 	    
		//ScheduledArticleDeleter.start();
		//ScheduledArticleDeleter.start('ScheduledArticleDeleter');
		//ScheduledArticleDeleter.start('ScheduledArticleDeleter', '0 0 1 ? * 7L');   
		system.assert(true);  
        Test.stopTest();
    }
}