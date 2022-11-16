/**
 * @description Domain class to handle the Consumer Customer Capability on the User trigger
 * @author Naveen Rajanna
 * @date 2022-10-28
 * @group Domains
 * @changelog
 * 2022-10-28	Naveen Rajanna - created - REQ2992462
 */
public inherited sharing class ConsumerUserDomain extends ApplicationDomain {
	private static final Set<Id> FILTER_CONSUMER_PROFILE_IDS = new Set<Id>{
		Application.Cache.profileIds.get('DDC Consumer Community User'),
		Application.Cache.profileIds.get('Consumer Community Temp Access User')
	};

	public static ConsumerUserDomain newInstance(List<SObject> sObjectList) {
		return (ConsumerUserDomain) ApplicationDomain.newInstance(ConsumerUserDomain.class, sObjectList);
	}

	/**
	 * These are the modules that the domain may use for triggers or method execution
	 */
	public override void registerModules() {
		// these module will be available for domain operations and trigger execution
		// each module will register their trigger entry points
		// additionally, each module will specify a list of fields that it monitors changes for.
		registerModule(ConsumerUserContactAutomationModule.class);
	}

	/**
	 * Prefilter the records passed in to ensure this domain class only processes applicable records.
	 * @param records User records in Trigger.New
	 * @return  `List<SObject>` filtered user records
	 */
	public override List<SObject> filter(List<SObject> records) {
		// filter user records which are community users and belonging to Consumer profiles
		List<SObject> output = new List<SObject>();
		for (SObject record : records) {
			if (
				ConsumerUserDomain.FILTER_CONSUMER_PROFILE_IDS.contains((Id) record.get('ProfileId')) &&
				!String.isEmpty(String.valueOf(record.get('ContactId')))
			) {
				output.add(record);
			}
		}
		return output;
	}
}
