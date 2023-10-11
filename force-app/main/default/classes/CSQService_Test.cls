/***
 * Service class for CSQ related operations.
 * 
 * @author	Paul Perry
 * @since	2023-10-10
 * @test	CSQService_Test
 */@isTest
public with sharing class CSQService_Test {
    /***
	 * Updating a pickup status to pending information initiates a process
	 * where a task is created and assigned to the related CSQ record's creator
	 * 
	 * When this task gets completed, the pickup location status gets updated to 
	 * Information received and a notification will be sent out to the creator
	 * informing them that the approval process can continue
	 */
	@isTest
	public static void csqServicetest() {
		// Construct CSQ record with embedded child records
		Id pickUpLocId = fflib_IDGenerator.generate(Pick_Up_Location__c.SObjectType);
		Id userId = UserInfo.getUserId();

		Pick_Up_Location__c pickUpLoc = (Pick_Up_Location__c)ApplicationTestDataFactory.setUnwritableFields(
			new Pick_Up_Location__c(
				Id = pickUpLocId,
				Pick_up_Location_Status__c = 'Pending Information'
			),
			new Map<String,Object>{
				'OwnerId__c' => userId,
				'CSQ__r' => ApplicationTestDataFactory.setUnwritableFields(
					new Customer_Scoping_Questionnaire__c(),
					new Map<String,Object>{ 'Name' => 'CSQ-123456' }
				)
			}
		);

		Task oldTask = new Task(
			Id = fflib_IDGenerator.generate(Task.SObjectType),
			Status = 'Not Started',
			WhatId = pickUpLocId,
			Subject = 'CSQ-123456 - Pending Information'
		);

		Task newTask = new Task(
			Id = oldTask.Id,
			Status = 'Completed',
			WhatId = pickUpLocId,
			Subject = 'CSQ-123456 - Pending Information'
		);

		List<User> userMock = new List<User>{
			(User)ApplicationTestDataFactory.setUnwritableFields(
				new User(Id = userId, Email = 'test@example.com'),
				new Map<String,Object>{ 'Name' => 'Test' }
			)
		};

		List<Pick_Up_Location__c> pickUpLocMock = (List<Pick_Up_Location__c>)fflib_ApexMocksUtils.makeRelationship(
			List<Pick_Up_Location__c>.class,
			new List<Pick_Up_Location__c>{ pickUpLoc },
			Task.WhatId,
			new List<List<SObject>>{ new List<SObject>() }
		);

		Report reportMock =(Report)ApplicationTestDataFactory.setUnwritableFields(
			new Report(),
			new Map<String, Object> {
				'Id' => fflib_IDGenerator.generate(Report.SObjectType),
				'Name' => CSQService.REPORTNAME_RECEIVEDINFO
			}
		);

		PickUpLocationSelector mockPULSelector = (PickUpLocationSelector)MockUtility.mockSelector(PickUpLocationSelector.class);
		CustomsSettingsSelector mockCSSelector = (CustomsSettingsSelector)MockUtility.mockSelector(CustomsSettingsSelector.class);
		UsersSelector mockUserSelector = (UsersSelector)MockUtility.mockSelector(UsersSelector.class);
		
		ApplicationDatabase mockDatabase = MockUtility.mockDatabase();

		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(
			mockPULSelector.selectById((Set<Id>)fflib_Match.anyObject(), (Set<Object>)fflib_Match.anyObject())
		).thenReturn(
			(Map<Id,Pick_Up_Location__c>)new Map<Id,Pick_Up_Location__c>(pickUpLocMock)
		);

		MockUtility.Mocks.when(
			mockCSSelector.selectByNames((Set<String>)fflib_Match.anyObject())
		).thenReturn(
			(Map<String,Report>)new Map<String,Report>{ reportMock.Name => reportMock }
		);

		MockUtility.Mocks.when(mockUserSelector.selectById((Set<Id>)fflib_Match.anyObject())).thenReturn(new Map<Id,User>(userMock));
		MockUtility.Mocks.when(mockDatabase.dmlUpdate((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericDMLUpdated());
		MockUtility.Mocks.stopStubbing();

		Test.startTest();

		CSQService.updatePickUpLocation(
			new Map<Id,Task>{ oldTask.Id => oldTask },
			new Map<Id,Task>{ newTask.Id => newTask }
		);

		fflib_ArgumentCaptor updateRecordsCaptor = fflib_ArgumentCaptor.forClass(List<Pick_Up_Location__c>.class);

		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, 1)).dmlUpdate(
			(List<Pick_Up_Location__c>)updateRecordsCaptor.capture()
		);

		List<Object> updateRecords = (List<Object>)updateRecordsCaptor.getAllValues();
		List<Pick_Up_Location__c> updateRecords1 = (List<Pick_Up_Location__c>)updateRecords[0];

		System.assertEquals(
			'Received Information',
			updateRecords1[0].Pick_up_Location_Status__c,
			'Status update missing'
		);
    }	
}