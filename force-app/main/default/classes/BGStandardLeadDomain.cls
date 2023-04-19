/**
* @description Domain class to handle BG Standard Lead capability
* @author Pratyush Chalasani
* @date 2023-03-27
* @group Domains
* @changelog
*/
public inherited sharing class BGStandardLeadDomain extends ApplicationDomain {
		public static BGStandardLeadDomain newInstance(List<SObject> sObjectList) {
			return (BGStandardLeadDomain)ApplicationDomain.newInstance(BGStandardLeadDomain.class, sObjectList);
		}
	
		/**
		 * These are the modules that the domain may use for triggers or method execution
		 */
		public override void registerModules() {
			// these module will be available for domain operations and trigger execution
			// each module will register their trigger entry points
			// additionally, each module will specify a list of fields that it monitors changes for.
			registerModule(BGStandardLeadModule.class);
		}
	
		/**
		 * Prefilter the records passed in to ensure this domain class only processes applicable records.
		 */
		public override List<SObject> filter(List<SObject> records) {
			Set<Id> validRecordTypes = new RecordTypesSelector().selectByDeveloperName('Lead', new Set<String>{'BG_Standard'}).keySet();
			List<SObject> output = new List<SObject>();
			for(SObject record : records) {
				if(validRecordTypes.contains((Id)record.get('RecordTypeId'))) {
					output.add(record);
				}
			}
			return output;
		}
}