/***
 * Utility class for CSQ related operations.
 * 
 * 
 * @author	Paul Perry
 * @since	2023-10-10
 */
public inherited sharing class CSQUtility {
	/***
	 * Tasks related to pickup location records when task gets completed:
	 * - update related pickup location status when Pending
	 * - send out notification to CSQ creator
	 * @param oldMap old task records by task Id
	 * @param newMap new task records by task Id
	 */
	public static void updatePickUpLocation(Map<Id,SObject> oldMap, Map<Id,SObject> newMap) {
		Set<Id> pickupLocationIds = new Set<Id>();

		for (Task tsk :(List<Task>)newMap.values()) {
			// Filter out any task other than:
			// - Status changing to 'Completed'
			// - Related to Pick_Up_Locations
			// - Subject: 'Pending Information'
			Boolean qualifies = 
				tsk.Subject.endsWith('Pending Information')
				&& tsk.Status == 'Completed'
				&& tsk.WhatId?.getSObjectType() == Pick_Up_Location__c.SObjectType
				&& isChanged(tsk, oldMap.get(tsk.Id), Task.Status);

			if (qualifies) {
				pickupLocationIds.add(tsk.WhatId);
			}
		}

		if (!pickupLocationIds.isEmpty()) {
			Map<Id,Pick_Up_Location__c> pulMap = (Map<Id,Pick_Up_Location__c>)PickUpLocationSelector.newInstance().selectById(
				pickupLocationIds,
				new Set<Object>{
					PickUpLocationSelector.Options.WITH_PENDING_TASKS,
					PickUpLocationSelector.Options.FILTER_STATUS_PENDING_INFORMATION
				}
			);

			List<Pick_Up_Location__c> updatedPULList = new List<Pick_Up_Location__c>();

			for (Id pulId :pulMap.keySet()) {
				Pick_Up_Location__c pul = pulMap.get(pulId);

				if (pul.Tasks == null || pul.Tasks.isEmpty()) {
					updatedPULList.add(new Pick_Up_Location__c(
						Id = pul.Id,
						Pick_up_Location_Status__c = 'Received Information'
					));
				} else {
					pulMap.remove(pulId);
				}
			}

			if (!updatedPULList.isEmpty()) {
				// Invoke update first
				ApplicationDatabase.getInstance().dmlUpdate(updatedPULList);
				// Email uses LastModifiedUser as per oparation above
				sendReceivedNotification(pulMap.values());
			}
		}
	}

	public static final String INSTANCEURL = URL.getSalesforceBaseUrl().toExternalForm();
	public static final String USERNAME = UserInfo.getName();
	public static final String EMAILHTMLBODY = String.join(new String[] {
		'Hello , ',
		'',	
		'{0} has updated the Pick-Up Location\'s status to Information Received.',
		'',
		'Pick-Up Location: {1}/{2}',
		'',
		'View Report showing all <a href="{1}/{3}">Pick-Up Locations having status set to Information Received</a>.',
		'',
		'Thanks, ',
		'',
		'Salesforce Team '
	}, '<br/>\r\n');
	public static final String EMAILPLAINBODY = String.join(new String[] {
		'Hello, ',
		'',	
		'{0} has updated the Pick-Up Location\'s status to Information Received.',
		'',
		'Pick-Up Location: {1}/{2}',
		'',
		'View Report showing all Pick-Up Locations having status set to Information Received:\r\n{1}/{3}',
		'',
		'Thanks, ',
		'',
		'Salesforce Team '
	}, '\r\n');
	public static final String REPORTNAME_RECEIVEDINFO = 'Pick-Up Locations: Received Information';
	
	public static Id receivedPickupLocsReportId {
		get {
			if (receivedPickupLocsReportId == null) {
				CustomsSettingsSelector settingsSelector = CustomsSettingsSelector.newInstance(
					Report.SObjectType,
					new Set<SObjectField>{ Report.Id, Report.Name }
				);

				receivedPickupLocsReportId = ((Map<String,SObject>)settingsSelector.selectByNames(
					new Set<String> { REPORTNAME_RECEIVEDINFO }
				)).get(REPORTNAME_RECEIVEDINFO).Id;
			}

			return receivedPickupLocsReportId;
		}
		set;
	}

	/***
	 * Send out notifications to CSQ record creator
	 * @param pulList List of Pick-Up Location records 
	 * @return  `List<Messaging.SendEmailResult>`
	 */
	public static List<Messaging.SendEmailResult> sendReceivedNotification(List<Pick_Up_Location__c> pulList) {
		List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
		Set<Id> userIds = new Set<Id>();

		for (Pick_Up_Location__c pul :pulList) {
			userIds.add(pul.OwnerId__c);
		}

		Map<Id,User> userMap = UsersSelector.newInstance().selectById(userIds);

		for (Pick_Up_Location__c pul :pulList) {
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			mail.setToAddresses(new List<String>{
				userMap.get(pul.OwnerId__c).Email
			});
			mail.setSubject(pul.CSQ__r.Name + ' - Information Received');
			mail.setHtmlBody(String.format(
				EMAILHTMLBODY,
				new Object[] { USERNAME, INSTANCEURL, pul.Id, receivedPickupLocsReportId })
			);
			mail.setPlainTextBody(String.format(
				EMAILPLAINBODY,
				new Object[] { USERNAME, INSTANCEURL, pul.Id, receivedPickupLocsReportId })
			);
			mail.setUseSignature(false);
			mail.setBccSender(false);
			mail.setSaveAsActivity(false);
			emails.add(mail);
		}

		return Messaging.sendEmail(emails);
	}

	// Generic tooling
	/***
	 * Tooling to make if-statement conditions more readable
	 * @param newRec updated record
	 * @param oldRec original record
	 * @param field updated field
	 * @return  `Boolean` whether or not the value got updated
	 */
	public static Boolean isChanged(SObject newRec, SObject oldRec, SObjectField field) {
		return oldRec == null || oldRec.get(field) != newRec.get(field);
	}
}