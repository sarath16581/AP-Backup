/***
 * @description Test class for Notifications.
 * @author Ranjeewa Silva
 * @date 2024-01-22
 * @changelog
 * 2023-01-22 - Ranjeewa Silva - created
 */
@IsTest
private class Notifications_Test {

	@IsTest
	static void testSendSingleNotification() {
		// =====================================
		// Data Preparation
		// =====================================
		Account organisation = ApplicationTestDataFactory.getAccounts(1, true)[0];
		Map<Id, User> users = new Map<Id, User>(ApplicationTestDataFactory.getUsers(5, true));

		// =====================================
		// Stubbing
		// =====================================
		// None

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		try {
			Notifications.newInstance()
					.add(Notifications.create()
							.setNotificationTypeId(Notifications.DEFAULT_CUSTOM_NOTIFICATION_TYPE_ID)
							.setTitle('test')
							.setBody('test body')
							.setRecipientIds(users.keySet())
							.setTargetId(organisation.Id)
							.setSenderId(UserInfo.getUserId()))
					.send();
		} catch (Exception e) {
			Assert.fail('Unexpected exception in sending custom notification : ' + e.getMessage());
		}

		Test.stopTest();
	}

	@IsTest
	static void testSendMultipleNotifications() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Account> organisations = ApplicationTestDataFactory.getAccounts(3, true);
		List<User> users = ApplicationTestDataFactory.getUsers(3, true);

		// =====================================
		// Stubbing
		// =====================================
		// None

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		try {
			Notifications notificationSender = Notifications.newInstance();
			for (Integer i=0; i < organisations.size(); i++) {
				notificationSender.add(Notifications.create()
						.setNotificationTypeId(Notifications.DEFAULT_CUSTOM_NOTIFICATION_TYPE_ID)
						.setTitle('test')
						.setBody('test body')
						.setRecipientIds(new Set<Id>{users[i].Id})
						.setTargetId(organisations[i].Id)
						.setSenderId(UserInfo.getUserId()));
			}
			notificationSender.send();
		} catch (Exception e) {
			Assert.fail('Unexpected exception in sending custom notification : ' + e.getMessage());
		}
		Test.stopTest();
	}
}