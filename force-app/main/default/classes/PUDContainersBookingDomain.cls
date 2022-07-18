/**
* @description Domain class to handle PUD Job related capability
* @author Dattaraj Deshmukh
* @date 2022-06-23
* @group Domains
* @domain PUD
* @changelog
* 2022-06-23 - Dattaraj Deshmukh - Created.
*/
public with sharing class PUDContainersBookingDomain extends ApplicationDomain{
    
    public static PUDContainersBookingDomain newInstance(List<SObject> sObjectList) {
		return (PUDContainersBookingDomain)ApplicationDomain.newInstance(PUDContainersBookingDomain.class, sObjectList);
	}

    public override List<SObject> filter(List<SObject> sObjectList){
        Id bookingContainerRecordTypeId = RecordTypesSelector.newInstance().selectByDeveloperName('PUD_Container__c', new Set<String>{'Booking_Container'}).values()[0].Id;
        List<SObject> filteredRecords = new List<SObject>();

        for(SObject bContainer : sObjectList){
            if((Id)bContainer.get('RecordTypeId') == bookingContainerRecordTypeId){
                filteredRecords.add(bContainer);
            }
        }

        return filteredRecords;
    }
	/**
	 * These are the modules that the domain may use for triggers or method execution
	 */
	public override void registerModules() {
		// these module will be available for domain operations and trigger execution
		registerModule(PUDContainerTypeSyncModule.class);
	}

	/**
	 * Trigger instantiation context
	 */
	public virtual class Constructor implements ApplicationDomain.IConstructable {
		public ApplicationDomain construct(List<SObject> sObjectList) {
			return PUDContainersBookingDomain.newInstance(sObjectList);
		}
	}
}
