/**
 * @author Seth Heang
 * @group Tests
 * @tag ScheduledAction__c SObject
 * @domain Core
 * @description Test class for ApplicationScheduledAction
 * @changelog
 * 2024-07-26 - Seth Heang - Created
 */
@IsTest
public class ApplicationScheduledActionTest {

	/**
	 * @description create a subclass and extend the abstract class for code coverage
	 */
	private class MockApplicationScheduledAction extends ApplicationScheduledAction {
		protected override Map<Id, Boolean> validate(Map<Id, SObject> parentRecords, ApplicationUnitOfWork uow) {
			return new Map<Id, Boolean>();
		}

		public override List<ScheduledAction__c> add(Map<Id, SObject> parentRecords, ApplicationUnitOfWork uow) {
			return new List<ScheduledAction__c>();
		}

		public override void remove(List<Id> actionRecordIds, ApplicationUnitOfWork uow) {
		}
	}

	/**
	 * @description Test GetName() for code coverage
	 */
	@IsTest
	static void testGetName() {
		ApplicationScheduledAction action = new MockApplicationScheduledAction();
		String className = action.getName();
		System.assertEquals('ApplicationScheduledAction', className);
	}

	/**
	 * @description Test execute() for code coverage
	 */
	@IsTest
	static void testExecute() {
		ApplicationScheduledAction action = new MockApplicationScheduledAction();
		try {
			action.execute(new List<Id>());
			System.assert(false, 'Exception should have been thrown');
		} catch (ApplicationScheduledAction.ApplicationScheduledActionException e) {
			System.assert(true, 'Exception have been thrown');
		}
	}

	/**
	 * @description Test setup() for code coverage
	 */
	@IsTest
	static void testSetup() {
		ApplicationScheduledAction action = new MockApplicationScheduledAction();
		Map<Id, SObject> parentRecords = new Map<Id, SObject>();
		ApplicationUnitOfWork uow = MockUtility.mockUnitOfWork();
		try {
			action.setup(parentRecords, uow, true);
			System.assert(false, 'Exception should have been thrown');
		} catch (ApplicationScheduledAction.ApplicationScheduledActionException e) {
			System.assert(true, 'Exception have been thrown');
		}

		System.assert(true, 'No logic in this method, calling for code coverage');
	}

	/**
	 * @description Test revalidate() for code coverage
	 */
	@IsTest
	static void testRevalidate() {
		ApplicationScheduledAction action = new MockApplicationScheduledAction();
		Map<Id, SObject> parentRecords = new Map<Id, SObject>();
		ApplicationUnitOfWork uow = MockUtility.mockUnitOfWork();
		try {
			action.revalidate(parentRecords, uow);
			System.assert(false, 'Exception should have been thrown');
		} catch (ApplicationScheduledAction.ApplicationScheduledActionException e) {
			System.assert(true, 'Exception have been thrown');
		}

		System.assert(true, 'No logic in this method, calling for code coverage');
	}
}