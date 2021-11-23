/**************************************************
Type:       Schedular Class for batch ContractOwnerUpdateBatch
Purpose:    The schedular run every week which calls the batch class which is responsible for the below requirement - 
1.	All migrated Ariba contracts (whose owner is currently Data Migration User) should be set to the current Account Owner (Organisation Account Manager) in Salesforce. 
2.	For the organisations that have the account manager set to ‘Holding User’, the Migrated contract owner should be set to the Opportunity Driver associated to the Ariba contract. 
3.	Where the opportunity Driver is Inactive in Salesforce, Contract owner should  = Sales Team Owner on the organisation or if that equals Holding User Manager, use the Opportunity Owner’s Manager.

History:	12/05/2017	paul.stamer@auspost.com.au     Initial schedular Build

**************************************************/
global class ContractOwnerUpdateBatch_Schedule implements Schedulable{
    global void execute(SchedulableContext sc) {
        
        Integer batchSize;
        if(APT_R2T_System_Properties__c.getInstance().BatchSize_ContractOwnUpdBatch__c == null) {
            batchSize = 100;
        }
        else {
            batchSize = (Integer) APT_R2T_System_Properties__c.getInstance().BatchSize_ContractOwnUpdBatch__c;
        }
        
        // We now call the batch class to be scheduled
        ContractOwnerUpdateBatch batchContractUpdate = new ContractOwnerUpdateBatch(); 
        
        // Parameters of ExecuteBatch(context,BatchSize)
        database.executebatch(batchContractUpdate,batchSize);
    }
}