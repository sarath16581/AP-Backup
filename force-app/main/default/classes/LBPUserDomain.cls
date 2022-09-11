/**
* @description Domain class to handle the Local Business Partner capbility on the User trigger
* @author Nathan Franklin
* @date 2022-08-24
* @group Domains
* @changelog
*/
public inherited sharing class LBPUserDomain extends ApplicationDomain {

	static final Id communityUserProfileId {
		get {
			if(communityUserProfileId == null) {
				communityUserProfileId = ProfilesSelector.newInstance().selectByName(new Set<String>{'LPO Partner Community User'}).values()[0].Id;
			}
			return communityUserProfileId;
		}
		private set;
	}

	public static LBPUserDomain newInstance(List<SObject> sObjectList) {
		return (LBPUserDomain)ApplicationDomain.newInstance(LBPUserDomain.class, sObjectList);
	}

	/**
	 * These are the modules that the domain may use for triggers or method execution
	 */
	public override void registerModules() {
		// these module will be available for domain operations and trigger execution
		// each module will register their trigger entry points
		// additionally, each module will specify a list of fields that it monitors changes for.
		registerModule(LBPUserPermissionsModule.class);
	}

	/**
	 * Prefilter the records passed in to ensure this domain class only processes applicable records.
	 */
	public override List<SObject> filter(List<SObject> records) {

		List<SObject> output = new List<SObject>();
		for(SObject record : records) {
			if(record.get('ProfileId') == communityUserProfileId && !String.isEmpty(String.valueOf(record.get('ContactId')))) {
				output.add(record);
			}
		}
		return output;
	}

}