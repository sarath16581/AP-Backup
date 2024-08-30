/**
 * @description Test class that covers ApplicationEmailService and related classes
 * @author Carlo Inting
 * @date 2024-08-20
 */
@IsTest
private class ApplicationEmailService_Test {
    
	@IsTest
	public static void testQueueEmailNotification() {
		ApplicationEmailService testService = ApplicationEmailService.getInstance();

		List<Account> testAccounts = ApplicationTestDataFactory.getAccounts(2, true);

		// queue an email notification
		testService.queueEmailNotification(testAccounts[0].Id, Account.sObjectType, 'Test_Alert_1');
		System.assertEquals(1, testService.getRegistrySize(), '1 entry should be in the registry');

		// queue another email notification for different record
		testService.queueEmailNotification(testAccounts[1].Id, Account.sObjectType, 'Test_Alert_1');
		System.assertEquals(2, testService.getRegistrySize(), '2 entries should be in the registry because second notification has a different record id');

		// queue another email notification for same record, but different email alert
		testService.queueEmailNotification(testAccounts[1].Id, Account.sObjectType, 'Test_Alert_2');
		System.assertEquals(3, testService.getRegistrySize(), '3 entries should be in the registry because third notification uses a different email alert');

		// queue another email notification for same record and same alert
		testService.queueEmailNotification(testAccounts[0].Id, Account.sObjectType, 'Test_Alert_1');
		System.assertEquals(3, testService.getRegistrySize(), '3 entries should be in the registry because this notification is the same as the first');
		
		// queue another email notification for a different sObject
		Contact testContact = (ApplicationTestDataFactory.getContacts(1, testAccounts[0].Id, true))[0];
		testService.queueEmailNotification(testContact.Id, Contact.sObjectType, 'Test_Alert_1');
		System.assertEquals(4, testService.getRegistrySize(), '4 entries should be in the registry because this notification is for a different object');

		// test queueing a null email notification
		Boolean emailServiceExceptionCaught = false;
		try {
			testService.queueEmailNotification(null);
		} catch (ApplicationEmailService.EmailServiceException e) {
			emailServiceExceptionCaught = true;
		}
		System.assert(emailServiceExceptionCaught, 'EmailServiceException should have been thrown because a null argument was provided');	
	}

	@IsTest
	public static void testRegistryManagement() {

		ApplicationEmailService testService = ApplicationEmailService.getInstance();

		List<Account> testAccounts = ApplicationTestDataFactory.getAccounts(5, true);
		
		for (Account acc : testAccounts) {
			testService.queueEmailNotification(new ApplicationFlowEmailType(acc.Id, Account.sObjectType, 'Test_Email'));
		}
		
		System.assertEquals(5, testService.getRegistrySize(), 'All 5 Account emails should have been added to the registry');

		List<ApplicationFlowEmailType> emailNotifications = testService.getRegistryValues();
		System.assertEquals(5, emailNotifications.size(), '5 email notifications should have been retrieved from the registry');
		// get the third email notification
		String registryKeyToRemove = emailNotifications.get(2).generateRegistryKey();
		System.assert(testService.emailNotificationRegistry.containsKey(registryKeyToRemove), 'email registry key should be in registry');

		// remove it from registry
		ApplicationFlowEmailType removedEmail = testService.removePendingEmailNotification(registryKeyToRemove);
		System.assert(removedEmail != null, 'Removed email should have been returned');
		System.assertEquals(removedEmail.generateRegistryKey(), registryKeyToRemove, 'Removed email should have a matching registry key');
		System.assertEquals(4, testService.getRegistrySize(), '4 emails should remain in registry');
		System.assert(!testService.emailNotificationRegistry.containsKey(registryKeyToRemove), 'Email should not exist in registry');

		// attempt to remove registry key again
		removedEmail = testService.removePendingEmailNotification(registryKeyToRemove);
		System.assert(removedEmail == null, 'Nothing should have been returned since email does not exist in registry');

		// remove all emails from registry
		emailNotifications = testService.removeAllPendingEmailNotifications();

		System.assertEquals(4, emailNotifications.size(), 'The remaining 4 emails should have been removed and returned');
		System.assertEquals(0, testService.getRegistrySize(), 'The registry should be empty');
	}

	@IsTest
	public static void testEmailDispatch() {

		ApplicationEmailService testService = ApplicationEmailService.getInstance();
		List<Account> testAccounts = ApplicationTestDataFactory.getAccounts(10, true);
		
		for (Account acc : testAccounts) {
			testService.queueEmailNotification(new ApplicationFlowEmailType(acc.Id, Account.sObjectType, 'Test_Email'));
		}

		System.assertEquals(10, testService.getRegistrySize(), 'All 10 Account emails should have been added to the registry');

		List<ApplicationFlowEmailType> emailNotifications = testService.getRegistryValues();

		// dispatch one email notification
		ApplicationFlowEmailType emailToDispatch = emailNotifications.get(8);
		testService.dispatchPendingEmailNotification(emailToDispatch.generateRegistryKey());
		System.assertEquals(9, testService.getRegistrySize(), '1 email should have been removed from the registry');

		// attempt to register the email notification again
		testService.queueEmailNotification(emailToDispatch);
		System.assertEquals(9, testService.getRegistrySize(), 'The email should not be queued because it has already been dispatched');

		// dispatch all emails
		testService.dispatchAllPendingEmailNotifications();
		System.assertEquals(0, testService.getRegistrySize(), 'The registry should be cleared');
	}

	@IsTest
	public static void testDispatchHistory() {
		ApplicationEmailService testService = ApplicationEmailService.getInstance();
		List<Account> testAccounts = ApplicationTestDataFactory.getAccounts(3, true);
		
		for (Account acc : testAccounts) {
			testService.queueEmailNotification(new ApplicationFlowEmailType(acc.Id, Account.sObjectType, 'Test_Email'));
		}

		ApplicationFlowEmailType testEmail = testService.getRegistryValues()[0];

		System.assertEquals(3, testService.getRegistrySize(), '3 emails should be in registry');

		// remove email from registry
		testService.removePendingEmailNotification(testEmail.generateRegistryKey());
		System.assertEquals(2, testService.getRegistrySize(), '1 email should be removed');

		// add it back
		testService.queueEmailNotification(testEmail);
		System.assertEquals(3, testService.getRegistrySize(), 'Email should be added back since it has not been dispatched yet');

		// dispatch email
		testService.dispatchPendingEmailNotification(testEmail.generateRegistryKey());
		System.assertEquals(2, testService.getRegistrySize(), '1 email should be removed since it has been dispatched');

		// add it back
		testService.queueEmailNotification(testEmail);
		System.assertEquals(2, testService.getRegistrySize(), 'Email should be not be added back since it already been dispatched');
	}

	@IsTest
	public static void testEmailNotificationGrouping() {
		ApplicationEmailService testService = ApplicationEmailService.getInstance();

		List<Account> testAccounts = ApplicationTestDataFactory.getAccounts(5, true);
		List<Contact> testContacts = ApplicationTestDataFactory.getContacts(10, testAccounts[0].Id, true);
		List<Case> testCases = ApplicationTestDataFactory.getCases(15, true);

		for (Account acc : testAccounts) {
			testService.queueEmailNotification(acc.Id, Account.sObjectType, 'Test_Account_Email');
		}

		for (Contact con : testContacts) {
			testService.queueEmailNotification(con.Id, Contact.sObjectType, 'Test_Contact_Email');
		}

		for (Case cas : testCases) {
			testService.queueEmailNotification(cas.Id, Case.sObjectType, 'Test_Case_Email');
		}

		System.assertEquals(30, testService.getRegistrySize(), 'All 30 emails should have been registered');

		List<ApplicationFlowEmailType> emails = testService.getRegistryValues();

		List<ApplicationFlowEmailTypeObjectCollection> groupedEmails = testService.generateFlowEmailTypeObjectCollections(emails);

		System.assertEquals(3, groupedEmails.size(), '3 object collections should have been generated');
		
		Map<String, ApplicationFlowEmailTypeObjectCollection> groupedEmailsByObjectName = new Map<String, ApplicationFlowEmailTypeObjectCollection>();
		for (ApplicationFlowEmailTypeObjectCollection objCollection : groupedEmails) {
			groupedEmailsByObjectName.put(objCollection.objectType, objCollection);
		}

		System.assert(groupedEmailsByObjectName.get('Account') != null, 'Account collection should exist');
		System.assertEquals(5, groupedEmailsByObjectName.get('Account').emailNotifications.size(), '5 Account emails should be in collection');
		
		System.assert(groupedEmailsByObjectName.get('Contact') != null, 'Contact collection should exist');
		System.assertEquals(10, groupedEmailsByObjectName.get('Contact').emailNotifications.size(), '10 Contact emails should be in collection');
		
		System.assert(groupedEmailsByObjectName.get('Case') != null, 'Case collection should exist');
		System.assertEquals(15, groupedEmailsByObjectName.get('Case').emailNotifications.size(), '15 Case emails should be in collection');
		

	}
}