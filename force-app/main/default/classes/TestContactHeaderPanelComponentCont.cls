/**************************************************
Type:       Test class for the ContactHeaderPanelComponentCont class
Purpose:    Tests if the page works for both Contact and Person Account. 
			Also tests if the AverageCallTime is calculatd correctly.
       
History:
--------------------------------------------------
22.01.2014  Mohamed.Atheek@bluewolf.com  Created                                               
**************************************************/

@isTest
private class TestContactHeaderPanelComponentCont {

    static testMethod void testWithContact() {
    	//setting up test data
        Account acc = TestDataProvider.createAndSaveBusinessAccount('BusAcc', Constants.RECORDTYPE_NAME_ACCOUNT_BUSINESS_ACCOUNT);
        Contact cont = TestDataProvider.createAndSaveContact('test', acc.Id, Constants.RECORDTYPE_NAME_CONTACT_UNVERIFIED);
        
        Task t1 = TestDataProvider.createTask(null, cont.Id, Constants.RECORDTYPE_NAME_TASK_SSSWCALL);
        t1.CallDurationInSeconds = 55;
        
        Task t2 = TestDataProvider.createTask(null, cont.Id, Constants.RECORDTYPE_NAME_TASK_SSSWCALL);
        t2.CallDurationInSeconds = 75;
        
        insert new List<Task>{t1, t2};
        
        Test.startTest();
        
        ContactHeaderPanelComponentCont contr = new ContactHeaderPanelComponentCont();
        contr.recId = cont.Id;
        
        Test.stopTest();
        
        //asserting the results
        System.assertEquals(cont.Id, contr.contId);
        System.assertNotEquals(null, contr.contactRec);
        System.assert(!contr.isPersonAccount);
        System.assertEquals('1:05 mins', contr.averageCallTime);
    }
    
    static testMethod void testWithPersonAccount() {
        Account acc = TestDataProvider.createAndSavePersonAccount('PersAcc', Constants.RECORDTYPE_NAME_ACCOUNT_PERSONACCOUNT);
        Id personContId = [SELECT PersonContactId FROM Account WHERE Id = :acc.Id].PersonContactId;
        
        Test.startTest();
        
        ContactHeaderPanelComponentCont contr = new ContactHeaderPanelComponentCont();
        contr.recId = acc.Id;       
        
        Test.stopTest();
        
        System.assertEquals(personContId, contr.contId);
        System.assertNotEquals(null, contr.contactRec);
        System.assert(contr.isPersonAccount); 
    }
}