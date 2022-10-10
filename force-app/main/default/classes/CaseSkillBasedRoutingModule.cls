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
	 * This method populates the Case field CustomerQueueType based on the Case Account.
	 * @param records the list of updated or new records from the trigger.
	 * @param existingRecords a Map of the pre-update records from the trigger. 
     * @param uow instance of UnitOfWork to flag records for DML operations
	 */
    private void populateCustomerQueueType(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow){
        
        Map<Id,Case> accountIdCaseMapping = new Map<Id,Case>();

        for (Case c : (List<Case>) records) {

            if (String.IsEmpty(c.AccountId) == true) {
                c.CustomerQueueType__c = SERVICESLA_CONSUMER;
            } else {
                //for updates, only process Cases with a changed AccountId
                if(
                    existingRecords == null || 
                    (existingRecords.isEmpty() == false &&
                     c.AccountId != ((Case)existingRecords.get(c.Id)).AccountId)
                ){                    
                    accountIdCaseMapping.put(c.AccountId,c);
                } 
            }
        }

        if(accountIdCaseMapping.isEmpty() == false){
            for(Account acct : (AccountsSelector.newInstance().selectById(accountIdCaseMapping.keySet())).values()){
                Case cs = accountIdCaseMapping.get(acct.Id);
                if(cs != null){
                    cs.CustomerQueueType__c = String.isEmpty(acct.ServiceSLA__c) ? SERVICESLA_CONSUMER : acct.ServiceSLA__c;
                }               
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