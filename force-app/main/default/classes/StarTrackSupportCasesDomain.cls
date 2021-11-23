/**
* @description Domain class to handle StarTrack Case capability
* @author Madhusudhan
* @date 2020-06-08
* @group Domains
* @changelog
*/
public virtual inherited sharing class StarTrackSupportCasesDomain extends ApplicationDomain {
    
    public static StarTrackSupportCasesDomain newInstance(List<SObject> sObjectList) {
        return (StarTrackSupportCasesDomain)ApplicationDomain.newInstance(StarTrackSupportCasesDomain.class, sObjectList);
    }

    /**
     * These are the modules that the domain may use for triggers or method execution
     */
    public override void registerModules() {
        // these module will be available for domain operations and trigger execution
        // each module will register their trigger entry points
        // additionally, each module will specify a list of fields that it monitors changes for.
        registerModule(StarTrackCalculateCaseDepotModule.class);
        registerModule(StarTrackSupportCaseContactsModule.class);
        registerModule(StarTrackSupportCasePriorityModule.class);
        registerModule(StarTrackSupportCaseAutomationModule.class);
        registerModule(StarTrackSupportCaseOwnerModule.class);
        registerModule(StarTrackSupportCaseCustomerModule.class); 
        registerModule(StarTrackDeliveryEnquiryProcessModule.class);
    }

    /**
     * Prefilter the records passed in to ensure this domain class only processes applicable records.
     */
    public override List<SObject> filter(List<SObject> records) {
        System.debug('filter: ' + className);
        Set<Id> validRecordTypes = new RecordTypesSelector().selectByDeveloperNameLike('Case', 'StarTrack').keySet();
        List<SObject> output = new List<SObject>();
        for(SObject record : records) {
            if(validRecordTypes.contains((Id)record.get('RecordTypeId'))) {
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
            return StarTrackSupportCasesDomain.newInstance(sObjectList);
        }
    }

}