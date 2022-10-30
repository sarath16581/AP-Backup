/* @author    : kennethleroy.mcguire3@auspost.com.au
* @date       : 04/10/2022
* @description  : Generic Domain wrapper for Austrac Membership Contact Data Object
* @test : AustracMembershipContactDomain_Test
* @changelog :
*/

public  inherited sharing class AustracMembershipContactDomain extends ApplicationDomain {

    private static final String AUSTRAC_REGISTRATION_RECORDTYPE_NAME = 'AUSTRAC Registration';
    private static Map<Id,Boolean> hasAustracMembership;
 
 
    public static AustracMembershipContactDomain newInstance(List<SObject> sObjectList) {
 
       return (AustracMembershipContactDomain)ApplicationDomain.newInstance(AustracMembershipContactDomain.class, sObjectList);
    
    }
 
    /**
     * These are the modules that the domain may use for triggers or method execution
     */
    public override void registerModules() {
       // these module will be available for domain operations and trigger execution
       // each module will register their trigger entry points
       // additionally, each module will specify a list of fields that it monitors changes for.
       
        // Generic Module for Membership Contact
        registerModule(MembershipContactModule.class);
    }
    
      /*
      * Prefilter the records passed in to ensure this domain class only processes applicable records.
      */
     public override List<SObject> filter(List<SObject> records) {
 		 system.debug('passed in records '+records);
         List<SObject> output = new List<SObject>();
         loadAustracMembershipMap(records);
         for(SObject record : records) {
             if(hasAustracMembership.get(record.Id)) {
                 output.add(record);
             }
         }
         return output;
     } 
     
     // Loads parent membership records that are relevant to this domain
     private void loadAustracMembershipMap(List<SObject> records) {
         List<SObject> unloadedRecords = getUnloadedRecords(records);
         if (unloadedRecords.isEmpty()) return;
          
         Map<Id,Membership__c> membershipMap = MembershipsSelector.newInstance().selectByRecordTypeNames(extractMembershipIds(unloadedRecords), new Set<Object>(), new Set<String>{AUSTRAC_REGISTRATION_RECORDTYPE_NAME});
         for (SObject record : unloadedRecords) {
             hasAustracMembership.put(record.id,membershipMap.containsKey((id)record.get('Membership__c')));
         }
     }
     
    // Obtains a list of MembershipContact records that have not had parent records loaded yet.
    private List<SObject> getUnloadedRecords(List<SObject> records) {
        if (hasAustracMembership == null) {
            hasAustracMembership = new Map<Id,Boolean>();
            return records;
        }
        List<SObject> notLoaded = new List<SObject>();
        for (SObject record : records) {
            if (!hasAustracMembership.containsKey(record.id))  {
                notLoaded.add(record);
            }
        }
        return notLoaded;
    }
    
     // Extracts Membership__c Ids from an uncast list of MembershipContact records
     private static Set<Id> extractMembershipIds(List<SObject> records) {
         Set<Id> membershipIds = new Set<Id>();
         for(SObject record : records) {
             Id recordId = (id)record.get('Membership__c');
             if (recordId != null) {
                 membershipIds.add((id)record.get('Membership__c'));
             }
         }
         return membershipIds;
     }
 }