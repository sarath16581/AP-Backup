/**************************************************
Type:       Test class for the ContactActivityHistoryChartComponentCont class
Purpose:    Tests if the chart data is created correctly
       
History:
--------------------------------------------------
23.01.2014  Mohamed.Atheek@bluewolf.com  Created                                               
**************************************************/

@isTest
private class TestContactActivityHistoryChartCompCont 
{

    static testMethod void testChartData() 
    {
        Account acc = TestDataProvider.createAndSaveBusinessAccount('BusAcc', Constants.RECORDTYPE_NAME_ACCOUNT_BUSINESS_ACCOUNT);
        Contact cont = TestDataProvider.createAndSaveContact('test', acc.Id, Constants.RECORDTYPE_NAME_CONTACT_UNVERIFIED);
        
        //creating two call tasks in the current month
        Task t1 = TestDataProvider.createTask(null, cont.Id, Constants.RECORDTYPE_NAME_TASK_SSSWCALL);
        t1.CallDurationInSeconds = 55;
        
        Task t2 = TestDataProvider.createTask(null, cont.Id, Constants.RECORDTYPE_NAME_TASK_SSSWCALL);
        t2.CallDurationInSeconds = 75;
        
        insert new List<Task>{t1, t2};
        
        Test.startTest();
        
        ContactActivityHistoryChartComponentCont contr = new ContactActivityHistoryChartComponentCont();
        contr.contId = cont.Id;
        
        String chartData = contr.callChartData;
        System.assert(chartData.indexOf(ChartMonths.getMonthName(System.today().month())) >= 0);//chart data should include the current month
        System.assert(chartData.indexOf('2') >= 0);//chart data should include the 2 call task data we created
        
        Test.stopTest();
    }
}