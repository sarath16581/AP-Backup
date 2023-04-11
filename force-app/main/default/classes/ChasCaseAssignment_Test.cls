/**************************************************
Type:	   Test class for ChasCaseAssignment
History:
--------------------------------------------------
2023-02-16	Noel Lim	Class comment added, Update method setupTestData to remove queues being decommissioned
2023-04-05	Noel Lim	Update method setupTestData, var groupNames to contain only the queues tested in testmethod test_AssignCase

**************************************************/

@isTest
public class ChasCaseAssignment_Test {

	public static String TEST_NETWORK_ORG_ID = '1248777';

	@testSetup
	public static void setupTestData()
	{
		List<String> groupNames = new List<String>{				
				ChasCaseAssignment.SSSW_NETWORK_QUEUE
		};

		Profile adminProf = [select Id from Profile where Name = 'System Administrator'];

		// use runAs to bypass the DML with Group limitations
		System.runAs(TestUtility.createUser('Admin',adminProf.id,null)) {

			//Create the related Groups
			List<Group> groupsToAdd = new List<Group>();
			for (String gn : groupNames) {
				groupsToAdd.add(new Group(Name = gn, Type = 'Queue'));
			}
			insert groupsToAdd;

			//Create the related queues
			List<QueueSobject> queuesToAdd = new List<QueueSobject>();
			for (Group g : groupsToAdd) {
				queuesToAdd.add(new QueueSobject(QueueID = g.id, SobjectType = 'Case'));
			}
			insert queuesToAdd;

			// create a network
			Network__c network = new Network__c();
			network.Name = 'Melbourne Dead Mail';
			network.Org_ID__c = TEST_NETWORK_ORG_ID;
			network.Contact_Facility__c = ChasCaseAssignment.CONTACT_VIA_MY_NETWORK;
			insert network;

		}
	}

	@isTest
	public static void test_AssignCase()
	{
		List<Group> groupNetwork = [SELECT Id, Name FROM Group WHERE developerName =: ChasCaseAssignment.SSSW_NETWORK_QUEUE];
		Id queueId = groupNetwork[0].Id;

		// create a new Case for testing getRecordTypeId static method
		Case testCase = TestDataProvider.createTestCase();
		//testCase.ReferenceID__c = 'SSSWCase';
		insert testCase;
		Id caseId = testCase.Id;

		Test.startTest();

		ChasCaseAssignment assignJob = new ChasCaseAssignment(testCase, TEST_NETWORK_ORG_ID);
		System.enqueueJob(assignJob);
		Test.stopTest();

		List<Case> results = [
				SELECT Id, OwnerId
				FROM Case
				WHERE Id =: caseId
		];
		System.assertEquals(results[0].OwnerId, queueId, 'Expected Case to be assigned to Network Queue, ' + results[0]);
	}
}