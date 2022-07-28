/***
 * @description
 * This is an ApplicationDomain for use in ApplicationDomain_Test
 *
 * @author Nathan Franklin
 * @date 2020-07-27
 * @group Core
 * @domain Core
 * @changelog
 * 2022-04-28 - Nathan Franklin - Remove IConstructable interfaces
 */
@IsTest
public class ApplicationTestDomain2_Test extends ApplicationDomain {

	// used to report back from the module which records where changed
	public static Map<Id, Set<SObjectField>> moduleBeforeUpdateChangedValues;
	public static Map<Id, Set<SObjectField>> moduleAfterUpdateChangedValues;

	public static Integer moduleOnBeforeInsertCalled = 0;
	public static Integer moduleOnAfterInsertCalled = 0;
	public static Integer moduleOnBeforeUpdateCalled = 0;
	public static Integer moduleOnAfterUpdateCalled = 0;
	public static Integer moduleOnBeforeDeleteCalled = 0;
	public static Integer moduleOnAfterDeleteCalled = 0;

	/**
	 * These are the modules that the domain may use for triggers or method execution
	 */
	public override void registerModules() {
		registerModule(ApplicationTestDomainModuleAllAfter_Test.class);
		registerModule(ApplicationTestDomainModuleAllBeforeTest.class);
	}

	public override List<SObject> filter(List<SObject> records) {
		List<SObject> output = new List<SObject>();
		for(SObject record : records) {
			if(record.get('Name') == 'Test Name 1') {
				output.add(record);
			}
		}
		return output;
	}
}