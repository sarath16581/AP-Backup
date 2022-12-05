/*** 
 * @description
 * Domain Module to update Case fields that are used in Omni Skills Routing, performed in isBefore so it is available for Case skills mapping.
 * This is related to SSSW, so only SSSW Cases are processed.
 * Domain Modules should NEVER be called directly. Domain modules should be exposed and called via the corresponding domain class
 * 
 * @author Noel Lim
 * @date 2022-09-20
 * @group Domain
 * @domain Routing 
 * @changelog
 * 2022-09-20 - Noel Lim - Created
 */

public inherited sharing class CaseSkillBasedRoutingModule extends ApplicationDomain.Module  {
    
    private static Set<Id> validRecTypes;
    public static final String SERVICESLA_CONSUMER = 'Consumer';

    /*
     * Creates a new instance of the utility to facilitate dependency injection for mocking
     * @return the new instance
     */
    public static CaseSkillBasedRoutingModule newInstance() {
        return (CaseSkillBasedRoutingModule)Application.Utilities.newInstance(CaseSkillBasedRoutingModule.class);
    }
    
    // Constructor
    public CaseSkillBasedRoutingModule() {
        // Setup which triggers this module should respond to
        getTriggerEvents().enableBeforeInsert().enableBeforeUpdate();        
    }
    /**
     * Called when a new Case is being inserted
     */
    public override void onBeforeInsert(List<SObject> records, ApplicationUnitOfWork uow) {
        try {
            populateCustomerQueueType(filterToOnlySSSWCases(records), null , uow);
            
        } catch (Exception ex) {
            // Error Logged to Exception object for analysis
            ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), 'CaseSkillRouting', CaseSkillBasedRoutingModule.class.getName(), 'onBeforeInsert', 'Case', ApplicationLogger.LoggingLevel.ERROR);
        }
    }
    /**
     * Called when a Case is being updated.
     */
    public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
        try {
            populateCustomerQueueType(filterToOnlySSSWCases(records), existingRecords, uow);
            
        } catch (Exception ex) {
            // Error Logged to Exception object for analysis
            ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(ex), 'CaseSkillRouting', CaseSkillBasedRoutingModule.class.getName(), 'onBeforeUpdate', 'Case', ApplicationLogger.LoggingLevel.ERROR);
        }
    }

    /*
     * This method populates the Case field CustomerQueueType based on the Case Contact's Account.
     * @param records the list of updated or new records from the trigger.
     * @param existingRecords a Map of the pre-update records from the trigger. 
     * @param uow instance of UnitOfWork to flag records for DML operations
     */
    private void populateCustomerQueueType(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow){
        
        Set<Id> contactIds = new Set<Id>();
        List<Case> caseToProcess = new List<Case>();
        

        for (Case cs : (List<Case>) records) {

            if(existingRecords == null || 
                (existingRecords.isEmpty() == false &&
                    cs.ContactId != ((Case)existingRecords.get(cs.Id)).ContactId)
            ){                    
                
                caseToProcess.add(cs);      
                if(cs.ContactId != null){
                    contactIds.add(cs.ContactId);  
                }                     
            }            
        }

        if(caseToProcess.isEmpty() == false){
            
            Map<Id, Contact> contactsMap = new Map<Id, Contact>();
            if(contactIds.isEmpty() == false){
                contactsMap = ContactsSelector.newInstance().selectById(contactIds, new Set<Object>{ContactsSelector.Options.WITH_ACCOUNT});
            } 

            for(Case cs : caseToProcess){
                Contact contact = contactsMap.get(cs.ContactId);
                cs.CustomerQueueType__c = (contact != null && contact.Account != null && String.isEmpty(contact.Account.ServiceSLA__c) == false)  ? contact.Account.ServiceSLA__c : SERVICESLA_CONSUMER;                
            }
        }
    }

    /*
     * This method returns a list of Case records that are related to SSSW
     * @param caseRecords the list of Cases to filter to SSSW only
     */
    private List<SObject> filterToOnlySSSWCases(List<SObject> caseRecords){
        if(validRecTypes == null){
            validRecTypes =  Utility.getRecordTypeIds(String.valueOf(Case.getsObjectType()),SSSWConstants.SSSW_APP);
        }
        
        List<SObject> ssswCases = new List<SObject>();
        
        for (Case c : (List<Case>) caseRecords) {
            if(Utility.isValidRecordType(validRecTypes,c.RecordTypeId)){
                ssswCases.add(c);
                
            }                
        }

        return ssswCases;
    }

    /**
     * Module instantiation context. This allows us to dynamically instantiate this module within ApplicationModule
     */
    public class Constructor implements ApplicationDomain.IConstructableModule {
        public ApplicationDomain.Module construct() {
            return (ApplicationDomain.Module) CaseSkillBasedRoutingModule.newInstance();
        }
    }

}