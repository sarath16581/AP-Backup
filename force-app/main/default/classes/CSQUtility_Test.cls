@isTest
public with sharing class CSQUtility_Test {
    @isTest
	public static void csqUtilitytest() {
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
				'Name' => CSQUtility.REPORTNAME_RECEIVEDINFO
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

		CSQUtility.updatePickUpLocation(
			new Map<Id,Task>{ oldTask.Id => oldTask },
			new Map<Id,Task>{ newTask.Id => newTask }
		);

		fflib_ArgumentCaptor updateRecordsCaptor = fflib_ArgumentCaptor.forClass(List<Pick_Up_Location__c>.class);

		((ApplicationDatabase)MockUtility.Mocks.verify(mockDatabase, 1)).dmlUpdate(
			(List<Pick_Up_Location__c>)updateRecordsCaptor.capture()
		);

		List<Object> updateRecords = (List<Object>)updateRecordsCaptor.getAllValues();

		System.debug(updateRecords);

		List<Pick_Up_Location__c> updateRecords1 = (List<Pick_Up_Location__c>)updateRecords[0];
    }



	// public inherited sharing class CSQUtilities {

	// 	public static void updatePickUpLocation(Map<Id,SObject> oldMap, Map<Id,SObject> newMap) {
	// 		Set<Id> pickupLocationIds = new Set<Id>();
	
	// 		for (Task tsk :(List<Task>)newMap.values()) {
	// 			// Filter out any task other than:
	// 			// - Status changing to 'Completed'
	// 			// - Related to Pick_Up_Locations
	// 			// - Subject: 'Pending Information'
	// 			Boolean qualifies = 
	// 				tsk.Subject.endsWith('Pending Information')
	// 				&& tsk.Status == 'Completed'
	// 				&& tsk.WhatId?.getSObjectType() == Pick_Up_Location__c.SObjectType
	// 				&& isChanged(tsk, oldMap.get(tsk.Id), Task.Status);
	
	// 			if (qualifies) {
	// 				pickupLocationIds.add(tsk.WhatId);
	// 			}
	// 		}
	
	// 		if (!pickupLocationIds.isEmpty()) {
	// 			Map<Id,Pick_Up_Location__c> pulMap = (Map<Id,Pick_Up_Location__c>)PickUpLocationSelector.newInstance().selectById(
	// 				pickupLocationIds,
	// 				new Set<Object>{
	// 					PickUpLocationSelector.Options.WITH_PENDING_TASKS,
	// 					PickUpLocationSelector.Options.FILTER_STATUS_PENDING_INFORMATION
	// 				}
	// 			);
	
	// 			List<Pick_Up_Location__c> updatedPULList = new List<Pick_Up_Location__c>();
	
	// 			for (Id pulId :pulMap.keySet()) {
	// 				Pick_Up_Location__c pul = pulMap.get(pulId);
	
	// 				if (pul.Tasks == null || pul.Tasks.isEmpty()) {
	// 					updatedPULList.add(new Pick_Up_Location__c(
	// 						Id = pul.Id,
	// 						Pick_up_Location_Status__c = 'Received Information'
	// 					));
	// 				} else {
	// 					pulMap.remove(pulId);
	// 				}
	// 			}
	
	// 			if (!updatedPULList.isEmpty()) {
	// 				// Invoke update first
	// 				ApplicationDatabase.getInstance().dmlUpdate(updatedPULList);
	// 				// Email uses LastModifiedUser as per oparation above
	// 				sendReceivedNotification(pulMap.values());
	// 			}
	// 		}
	// 	}
	
	// 	public static final String INSTANCEURL = URL.getSalesforceBaseUrl().toExternalForm();
	// 	public static final String USERNAME = UserInfo.getName();
	// 	public static final String EMAILHTMLBODY = String.join(new String[] {
	// 		'Hello , ',
	// 		'',	
	// 		'{0} has updated the Pick-Up Location\'s status to Information Received.',
	// 		'',
	// 		'Pick-Up Location: {1}/{2}',
	// 		'',
	// 		'View Report showing all <a href="{1}/{3}">Pick-Up Locations having status set to Information Received</a>.',
	// 		'',
	// 		'Thanks, ',
	// 		'',
	// 		'Salesforce Team '
	// 	}, '<br/>\r\n');
	// 	public static final String EMAILPLAINBODY = String.join(new String[] {
	// 		'Hello, ',
	// 		'',	
	// 		'{0} has updated the Pick-Up Location\'s status to Information Received.',
	// 		'',
	// 		'Pick-Up Location: {1}/{2}',
	// 		'',
	// 		'View Report showing all Pick-Up Locations having status set to Information Received:\r\n{1}/{3}',
	// 		'',
	// 		'Thanks, ',
	// 		'',
	// 		'Salesforce Team '
	// 	}, '\r\n');
		
	// 	public static Id receivedPickupLocsReportId {
	// 		get {
	// 			if (receivedPickupLocsReportId == null) {
	
	// 				final String reportName = 'Pick-Up Locations: Received Information';
	
	// 				CustomsSettingsSelector settingsSelector = CustomsSettingsSelector.newInstance(
	// 					Report.SObjectType,
	// 					new Set<SObjectField>{ Report.Id, Report.Name }
	// 				);
	
	// 				receivedPickupLocsReportId = ((Map<String,SObject>)settingsSelector.selectByNames(
	// 					new Set<String> { reportName }
	// 				)).get(reportName).Id;
	// 			}
	
	// 			return receivedPickupLocsReportId;
	// 		}
	// 		set;
	// 	}
	
	// 	public static List<Messaging.SendEmailResult> sendReceivedNotification(List<Pick_Up_Location__c> pulList) {
	// 		List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
	// 		Set<Id> userIds = new Set<Id>();
	
	// 		for (Pick_Up_Location__c pul :pulList) {
	// 			userIds.add(pul.OwnerId__c);
	// 		}
	
	// 		Map<Id,User> userMap = UsersSelector.newInstance().selectById(userIds);
	
	// 		for (Pick_Up_Location__c pul :pulList) {
	// 			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
	// 			mail.setToAddresses(new List<String>{
	// 				userMap.get(pul.OwnerId__c).Email
	// 			});
	// 			mail.setSubject(pul.CSQ__r.Name + ' - Information Received');
	// 			mail.setHtmlBody(String.format(
	// 				EMAILHTMLBODY,
	// 				new Object[] { USERNAME, INSTANCEURL, pul.Id, receivedPickupLocsReportId })
	// 			);
	// 			mail.setPlainTextBody(String.format(
	// 				EMAILPLAINBODY,
	// 				new Object[] { USERNAME, INSTANCEURL, pul.Id, receivedPickupLocsReportId })
	// 			);
	// 			mail.setUseSignature(false);
	// 			mail.setBccSender(false);
	// 			mail.setSaveAsActivity(false);
	// 			emails.add(mail);
	// 		}
	
	// 		return Messaging.sendEmail(emails);
	// 	}
	
	// 	// Generic tooling
	// 	public static Boolean isChanged(SObject newRec, SObject oldRec, SObjectField field) {
	// 		return oldRec == null || oldRec.get(field) != newRec.get(field);
	// 	}
	
	// 	public static Boolean isChanged(SObject newRec, SObject oldRec, Set<SObjectField> fields) {
	// 		Boolean result = false;
	
	// 		for (SObjectField field :fields) {
	// 			result = isChanged(newRec, oldRec, new Set<SObjectField>{ field });
	
	// 			if (result) {
	// 				break;
	// 			}
	// 		}
	
	// 		return result;
	// 	}
	// }
}