/**
 * @description Domain class to handle common logic for all APR__c object recors belonging to StarTrack record type
 * @author Naveen Rajanna
 * @date 2022-04-15
 * @group Domains
 * @changelog
 * 2022-04-15	Naveen Rajanna	REQ2811129 - created
 */

public inherited sharing class StarTrackAPRDomain extends ApplicationDomain {

	public static StarTrackAPRDomain newInstance(List<SObject> sObjectList) {
		return (StarTrackAPRDomain) ApplicationDomain.newInstance(StarTrackAPRDomain.class, sObjectList);
	}

	/**
	 * These are the modules that the domain may use for triggers or method execution
	 */
	public override void registerModules() {
		// these module will be available for domain operations and trigger execution
		// each module will register their trigger entry points
		// additionally, each module will specify a list of fields that it monitors changes for.
		registerModule(StarTrackAPRAutomationModule.class);
	}

	/**
	 * Prefilter the records passed in to ensure this domain class only processes applicable records.
	 */
	public override List<SObject> filter(List<SObject> records) {
		List<SObject> output = new List<SObject>();
		for (SObject record : records) {
			if (APRConstants.RECTYPE_ID_STARTRACK.equals((Id)record.get('RecordTypeId'))) {
				output.add(record);
			}
		}
		return output;
	}

	/**
	 * Trigger instantiation context
	 */
	public virtual class Constructor implements ApplicationDomain.IConstructable {
		public ApplicationDomain construct(List<SObject> sObjectList) {
			return StarTrackAPRDomain.newInstance(sObjectList);
		}
	}
}