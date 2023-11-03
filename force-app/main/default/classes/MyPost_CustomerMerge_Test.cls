/**
  * @author       : kalpita.talwadekar@auspost.com.au
  * @date         : 22/03/2016
  * @description  : test class for batch on customer merge
  */
/*******************************  History ************************************************
22/03/2016  kalpita.talwadekar@auspost.com.au   Created
21/02/2022 swati.mogadala2@auspost.com.au REQ2723596-Added Cover_type when inserting Compensation records
2023-10-02    Boris Bachovski    Refactor to use IsInactiveCustomer__c instead of is_Inactive_Customer__c
	
*******************************  History ************************************************/

@isTest
private class MyPost_CustomerMerge_Test{

	
  /** 
	* @name: testBatchMerge()
	* @desciption: test method for testing batch class for merging duplicate customers 
	* @param: NA
	* @return: NA
	*
	*/
	static testMethod void testBatchMerge() {
		//creating test data
		String recTypeId = [Select Id from RecordType where NAme='Consumer' and SobjectType='Account' limit 1].Id;
		Account accWin = TestUtility.createPersonAccount('WinAcc',recTypeId);
		accWin.FirstName ='John';
		accWin.PersonEmail = 'test@tst.com';
		accWin.Phone ='2132456';
		database.insert(accWin);
		Account accLoose = TestUtility.createPersonAccount('LooseAcc',recTypeId);
		accLoose.PersonEmail = 'test@tst.com';
		accLoose.FirstName = 'test';
		accLoose.Status__pc = 'Inactive';
		accLoose.Phone ='2132456';
		accLoose.Winning_Master_Record__pc = accWin.Id;
		database.insert(accLoose);
		
		// set the schedule execution time
		MyPost_CustomerMerge_Schedulable msc = new MyPost_CustomerMerge_Schedulable(10);
		String sch = '20 30 8 10 2 ?'; // base this on mode or whatever your params are
		
		Test.startTest();
			//run the scheduled job
			String jobID = system.schedule('Scheduled Job', sch, msc);
			system.assertnotEquals(jobID ,null); 
			 
		Test.stopTest(); 
	}
	
  /** 
	* @name: testBatchMerge2()
	* @desciption: test method for testing batch class for merging duplicate portal customers 
	* @param: NA
	* @return: NA
	*
	*/
	static testMethod void testBatchMerge2() {
		String recTypeId = [Select Id from RecordType where NAme='Consumer' and SobjectType='Account' limit 1].Id;
		String recTypeId2 = [Select Id from RecordType where NAme='Organisation' and SobjectType='Account' limit 1].Id;
		String recTypeId3 = [Select Id from RecordType where NAme='SSSW Delivery' and SobjectType='Case' limit 1].Id;
		
		Account accWin = TestUtility.createPersonAccount('WinAcc',recTypeId);
		accWin.FirstName ='John';
		accWin.PersonEmail = 'test@tst.com';
		accWin.Phone ='2132456';
		//accWin.isCustomerPortal = true;
		database.insert(accWin);
		
		
		Contact perAcc2 = [Select id from Contact where AccountId=:accWin.Id limit 1];
		
		
		Profile p = [select Id,name from Profile where Name = 'BSP Community User' limit 1];
		
		User newUser = new User(
		profileId = p.id,
		username = 'newUser@yahoo.com',
		email = 'pb@ff.com',
		emailencodingkey = 'UTF-8',
		localesidkey = 'en_US',
		languagelocalekey = 'en_US',
		timezonesidkey = 'America/Los_Angeles',
		alias='nuser',
		lastname='lastname',
		contactId = perAcc2.Id );
		insert newUser;
		
		//creating test data
		Account accLoose = TestUtility.createPersonAccount('LooseAcc',recTypeId);
		accLoose.PersonEmail = 'test@tst.com';
		accLoose.FirstName = 'test';
		//accLoose.isCustomerPortal = true;
		accLoose.Status__pc = 'Inactive';
		accLoose.Phone ='2132456';
		accLoose.Winning_Master_Record__pc = accWin.Id;
		database.insert(accLoose);
		
		Contact perAcc = [Select id from Contact where AccountId=:accLoose.Id limit 1];
		
		User newUser2 = new User(
		profileId = p.id,
		username = 'newUser2@yahoo.com',
		email = 'pb@ff.com',
		emailencodingkey = 'UTF-8',
		localesidkey = 'en_US',
		languagelocalekey = 'en_US',
		timezonesidkey = 'America/Los_Angeles',
		alias='nuser2',
		lastname='lastname2',
		contactId = perAcc.Id );
		insert newUser2;
		
		//creating test data
		Account acc2 = TestUtility.createBusinessAccount('LooseAcc',recTypeId2);
		//acc2.PersonEmail = 'test@tst.com';
		//acc2.FirstName = 'test';
		//accLoose.isCustomerPortal = true;
		acc2.Phone ='2132456';
		//acc2.Winning_Master_Record__pc = accWin.Id;
		database.insert(acc2);
		//create related recordsSSSSSS
		Contact con = testdataProvider.createContact('test',acc2.Id,'Contact');
		insert con;
		
		Case cse = TestUtility.createCase('test','new','investigation',accLoose.Id,perAcc.Id,recTypeId3);
		cse.ReferenceId__c = 'REF123';
		insert cse;
		NPSSurvey__c nps = new NPSSurvey__c(Contact__c=perAcc.Id); insert nps;
		Compensation__c comp = new Compensation__c(Case__c  =cse.Id,Contact__c=perAcc.id,Compensation_Amount__c=10,Cover_Type__c='Transit Cover'); insert comp;
		Task tsk = new Task(WhoId= perAcc.Id ,Priority= 'high'  , status='In Progress'  ,subject='tets'); insert tsk;
		Attachment att = TestUtility.createAttachment(Blob.valueOf('tetst'),accLoose.Id); att.Name='test'; insert att;
		AuthorisedContacts__c auth = new AuthorisedContacts__c(AuthorisingContact__c=perAcc.Id, Related_Contact__c=con.Id);
		//AuthorisedContacts__c auth = TestUtility.createAuthorizedContact();
		
		test.startTest(); 
			
			// set the schedule execution time
			MyPost_CustomerMerge_Schedulable msc = new MyPost_CustomerMerge_Schedulable(10);
			String sch = '20 30 8 10 2 ?'; // base this on mode or whatever your params are
			
			
			//run the scheduled job
			String jobID = system.schedule('Scheduled Job', sch, msc);
			system.assertnotEquals(jobID ,null); 
			 
		Test.stopTest(); 
	}
	
	/** 
	* @name: testBatchMerge3()
	* @desciption: test method for testing batch class for merging duplicate portal customers 
	* @param: NA
	* @return: NA
	*
	*/
	static testMethod void testBatchMerge3() {
		String recTypeId = [Select Id from RecordType where NAme='Consumer' and SobjectType='Account' limit 1].Id;
		String recTypeId2 = [Select Id from RecordType where NAme='Organisation' and SobjectType='Account' limit 1].Id;
		String recTypeId3 = [Select Id from RecordType where NAme='SSSW Delivery' and SobjectType='Case' limit 1].Id;
		
		Account accWin = TestUtility.createPersonAccount('WinAcc',recTypeId);
		accWin.FirstName ='John';
		accWin.PersonEmail = 'test@tst.com';
		accWin.Phone ='2132456';
		//accWin.isCustomerPortal = true;
		database.insert(accWin);
		
		
		Profile p = [select Id,name from Profile where Name = 'BSP Community User' limit 1];
		
		/*
		Contact perAcc2 = [Select id from Contact where AccountId=:accWin.Id limit 1];
		
		User newUser = new User(
		profileId = p.id,
		username = 'newUser@yahoo.com',
		email = 'pb@ff.com',
		emailencodingkey = 'UTF-8',
		localesidkey = 'en_US',
		languagelocalekey = 'en_US',
		timezonesidkey = 'America/Los_Angeles',
		alias='nuser',
		lastname='lastname',
		contactId = perAcc2.Id );
		insert newUser;
		*/
		
		//creating test data
		Account accLoose = TestUtility.createPersonAccount('LooseAcc',recTypeId);
		accLoose.PersonEmail = 'test@tst.com';
		accLoose.FirstName = 'test';
		//accLoose.isCustomerPortal = true;
		accLoose.Status__pc = 'Inactive';
		accLoose.Phone ='2132456';
		accLoose.Winning_Master_Record__pc = accWin.Id;
		database.insert(accLoose);
		
		Contact perAcc = [Select id from Contact where AccountId=:accLoose.Id limit 1];
		
		User newUser2 = new User(
		profileId = p.id,
		username = 'newUser2@yahoo.com',
		email = 'pb@ff.com',
		emailencodingkey = 'UTF-8',
		localesidkey = 'en_US',
		languagelocalekey = 'en_US',
		timezonesidkey = 'America/Los_Angeles',
		alias='nuser2',
		lastname='lastname2',
		contactId = perAcc.Id );
		insert newUser2;
		
		//creating test data
		Account acc2 = TestUtility.createBusinessAccount('LooseAcc',recTypeId2);
		//acc2.PersonEmail = 'test@tst.com';
		//acc2.FirstName = 'test';
		//accLoose.isCustomerPortal = true;
		acc2.Phone ='2132456';
		//acc2.Winning_Master_Record__pc = accWin.Id;
		database.insert(acc2);
		//create related records
		Contact con = testdataProvider.createContact('test',acc2.Id,'Contact');
		insert con;
		
		Case cse = TestUtility.createCase('test','new','investigation',acc2.Id,perAcc.Id,recTypeId3);
		cse.ReferenceId__c = 'REF123';
		insert cse;
		NPSSurvey__c nps = new NPSSurvey__c(Contact__c=perAcc.Id); insert nps;
		Compensation__c comp = new Compensation__c(Case__c  =cse.Id, Contact__c=perAcc.id,Compensation_Amount__c=10,Cover_Type__c='Transit Cover'); insert comp;
		Task tsk = new Task(WhoId= perAcc.Id ,Priority= 'high'  , status='In Progress'  ,subject='tets'); insert tsk;
		Attachment att = TestUtility.createAttachment(Blob.valueOf('tetst'),accLoose.Id); att.Name='test'; insert att;
		AuthorisedContacts__c auth = new AuthorisedContacts__c(AuthorisingContact__c=con.Id, Related_Contact__c=accLoose.Id);
		//AuthorisedContacts__c auth = TestUtility.createAuthorizedContact();
		
		test.startTest(); 
			
			// set the schedule execution time
			MyPost_CustomerMerge_Schedulable msc = new MyPost_CustomerMerge_Schedulable(10);
			String sch = '20 30 8 10 2 ?'; // base this on mode or whatever your params are
			
			
			//run the scheduled job
			String jobID = system.schedule('Scheduled Job', sch, msc);
			system.assertnotEquals(jobID ,null); 
			 
		Test.stopTest(); 
	}
   
}