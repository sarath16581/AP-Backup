/***
 * @author Steve L.
 * @date 2023-07-15
 * @group Tests
 * @tag Selector
 * @tag Event SObject
 * @domain Core
 * @description Test Class covering EventSelector
 * @changelog
 * 2023-07-15- Steve L - Created
 * 2020-03-03 - Steve L - added testSelectorAllRows
 */
@IsTest
private class EventsSelector_Test {
	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectString() {

		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		EventsSelector selector = EventsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom Event\\b').matcher(soql).find(), 'Resulting query does not select from Event');

		Test.stopTest();

	}

	/**
	 * Test:
	 *  Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureQueryBuilderProducesCorrectStringWithRelatedFields() {

		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		EventsSelector  selector = EventsSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();

		System.assertEquals(true, Pattern.compile('(?is)\\bfrom Event\\b').matcher(soql).find(), 'Resulting query does not select from rule info');

		Test.stopTest();
	}

	/**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	public static void testSelectorSpecificMethods() {

		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, false);
		insert accounts;

		List<Contact> contacts = ApplicationTestDataFactory.getContacts(1, accounts[0].Id, false);
		insert contacts;

		List<Event> events = new List<Event>();

		for(Integer i = 0; i < 20; i++){
			Event event = TestDataProvider.createEvent(accounts[0].Id, contacts[0].Id, 'Sales Event');
			event.Subject = 'Test' + i;
			event.Type = 'Event';
			event.Category__c = 'Sales';
			event.StartDateTime = System.now().addHours(-1);
			event.EndDateTime = System.now();
			event.ActivityDate = System.today().addDays(i);
			events.add(event);
		}
		insert events;


		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		EventsSelector selector = EventsSelector.newInstance();
		Map<Id,Event> eventMap = selector.selectByWhatId(new Set<Id>{accounts[0].Id});
		System.assertEquals(20, eventMap.size(), 'Expected result size of 20');

		eventMap = selector.selectById(new Set<Id>{events[0].Id});
		System.assertEquals(1, eventMap.size(), 'Expected 1 result');

		EventsSelector selectorWithOffset = EventsSelector.newInstance(0,1);
		eventMap = selectorWithOffset.selectById(new Set<Id>{events[0].Id, events[1].Id}, new Set<Object>{});
		System.assertEquals(1, eventMap.size(), 'Expected 1 result');

		Test.stopTest();
	}

	/**
	 * Executes a query to ensure it returns expected results with ALL ROWS
	 */
	@IsTest
	public static void testSelectorSelectAllRows() {
		final Integer eventSize = 20;
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();

		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, true);
		List<Event> events = new List<Event>{ApplicationTestDataFactory.getEvents(eventSize, accounts[0].Id,  true)[0]};

		// =====================================
		// Stubbing
		// =====================================
		ApplicationUnitOfWork mockUow = MockUtility.mockUnitOfWork();
		EventsSelector eventsSelector = (EventsSelector)MockUtility.mockSelector(EventsSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(eventsSelector.selectByWhatId((Set<Id>)fflib_Match.anyObject(),(Set<Object>)fflib_Match.anyObject(), (Boolean)fflib_Match.anyObject())).thenReturn(new Map<Id,Event>(events));
		MockUtility.Mocks.when(mockUow.registerNew((List<SObject>)fflib_Match.anyObject())).thenAnswer(new MockUtility.AnswerGenericRegisterUnitOfWorkDML());

		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Map<Id,Event> eventMap = eventsSelector.selectByWhatId(new Set<Id>{accounts[0].Id}, new Set<Object>(), true);
		System.assertEquals(events.size(), eventMap.size(), 'Expected ' + String.valueOf(eventSize) + ' result');

		Test.stopTest();
	}
}