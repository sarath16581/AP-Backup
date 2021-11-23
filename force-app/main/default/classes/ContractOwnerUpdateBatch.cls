/**************************************************
Type:       Batch Class.
Purpose:    

1.  All migrated Ariba contracts (whose owner is currently Data Migration User) should be set to the current Account Owner (Organisation Account Manager) in Salesforce. 
2.  For the organisations that have the account manager set to ‘Holding User’, the Migrated contract owner should be set to the Opportunity Driver associated to the Ariba contract. 
3.  Where the opportunity Driver is Inactive or a Holding User in Salesforce, Contract owner should  = Sales Team Owner on the organisation or if that equals Holding User Manager, use the Opportunity Owner’s Manager.
4.  If Account and Opportunity are null for the Contract, then do not update the contract owner

History:    4/12/2017  Adrian Recio     Initial Batch Build

**************************************************/

global without sharing class ContractOwnerUpdateBatch implements Database.Batchable<sObject>{
    
    //local variables
    private final String QUERY_STR;
    
    public set<string> categorySet = new set<string>();
    public set<string> statusSet = new set<string>();

    //constructor
    global ContractOwnerUpdateBatch() {
        
        categorySet.add('In Effect');
        statusSet.add('Activated');
        
        QUERY_STR = 'SELECT Ownerid, Apttus__Account__r.OwnerId, Apttus__Related_Opportunity__r.OwnerId,Apttus__Primary_Contact__c,APT_System_User__c, '
            + 'Apttus__Related_Opportunity__r.owner.isactive, Apttus__Account__r.Sales_Director__c, Apttus__Account__r.Sales_Director__r.IsActive ' 
            + 'FROM Apttus__APTS_Agreement__c '
            + 'WHERE (Apttus__Status_Category__c IN :categorySet or Apttus__Status__c IN :statusSet) and APT_OwnerEqualsAccountOwner__c = False'; 
        
        system.debug('--> Query --> '+QUERY_STR);
    }
        
    //start method
    global Database.QueryLocator start(Database.BatchableContext BC){
        system.debug('--> Final Query in Start--> '+QUERY_STR);
        return Database.getQueryLocator(QUERY_STR);
    }
    
    //execute method
    global void execute(Database.BatchableContext BC, List<Apttus__APTS_Agreement__c> contracts){
        List<Apttus__APTS_Agreement__c>  contractsWithAccMgrHoldingUser = new List<Apttus__APTS_Agreement__c>();
        String holdingUserId = APT_R2T_System_Properties__c.getInstance().APT_HoldingUserID__c;
        
        system.debug('Holding User Id:' + holdingUserId);
        
        // Creating a list to update all the contracts owners
        for (Apttus__APTS_Agreement__c c : contracts) {
            
            system.debug('Agreement Val:' + c);
            system.debug('c.Apttus__Account__r.OwnerId:' + c.Apttus__Account__r.OwnerId);
            system.debug('c.Apttus__Related_Opportunity__r.ownerId:' + c.Apttus__Related_Opportunity__r.ownerId);
            system.debug('c.Apttus__Account__r.Sales_Director__c:' + c.Apttus__Account__r.Sales_Director__c);
            system.debug('c.Apttus__Related_Opportunity__r.Owner.IsActive:' + c.Apttus__Related_Opportunity__r.Owner.IsActive);
            
            //check if Account and Opportunity are null, do nothing
            if(c.Apttus__Account__c == null && c.Apttus__Related_Opportunity__c == null){
                //do nothing  
            }
            //update contract owners
            else {
                //update contract owner with account owner if account owner is not a holding user
                if(c.Apttus__Account__c != null 
                   && c.Apttus__Account__r.OwnerId != null 
                   && c.Apttus__Account__r.OwnerId != holdingUserId) {
                       c.OwnerId = c.Apttus__Account__r.OwnerId;
                   }
                //if account owner is null or a holding user
                else if ((c.Apttus__Account__c != null 
                          && c.Apttus__Account__r.OwnerId != null 
                          && c.Apttus__Account__r.OwnerId == holdingUserId)
                         || c.Apttus__Account__c == null) {
                             //look for related opportunity driver to update contract owner
                             if(c.Apttus__Related_Opportunity__c != null 
                                && c.Apttus__Related_Opportunity__r.ownerId != null 
                                && c.Apttus__Related_Opportunity__r.Owner.IsActive
                                && c.Apttus__Related_Opportunity__r.ownerId != holdingUserId) {
                                    c.OwnerId = c.Apttus__Related_Opportunity__r.ownerId;
                                }
                             //look for sales team owner to update the contract owner
                             else if ((c.Apttus__Related_Opportunity__c == null ||
                                       c.Apttus__Related_Opportunity__r.Owner.IsActive == false ||
                                       c.Apttus__Related_Opportunity__r.ownerId == holdingUserId)
                                      
                                      && c.Apttus__Account__c != null
                                      && c.Apttus__Account__r.Sales_Director__c != null
                                      && c.Apttus__Account__r.Sales_Director__r.IsActive
                                      && c.Apttus__Account__r.Sales_Director__c != holdingUserId) {
                                          
                                          c.OwnerId = c.Apttus__Account__r.Sales_Director__c; 
                                          
                              
                         	}// If Else
                }// If Else
              //Update the system user if it is blank to avoid a validation rule
              if(c.APT_System_User__c == null && c.Apttus__Primary_Contact__c != null) {
                    c.APT_System_User__c = c.Apttus__Primary_Contact__c;
              }
              // add the contract record in the final list of contracts to be updated
              contractsWithAccMgrHoldingUser.add(c);
            }//end - else 
        }//end - for
        
        system.debug('--> Size --> '+contractsWithAccMgrHoldingUser.size());
        //update the apttus contract records
        Database.update(contractsWithAccMgrHoldingUser);
    }
    
    //finish method
    global void finish(Database.BatchableContext BC){
        AsyncApexJob a = [Select Id, Status,ExtendedStatus,NumberOfErrors,JobItemsProcessed,TotalJobItems,CreatedBy.Email
                          from AsyncApexJob where Id =:BC.getJobId()];
        
        String toAddressEmail  = APT_R2T_System_Properties__c.getInstance().CRMSupportUserEmail__c;
        if(!String.isEmpty(toAddressEmail)) {
            String[] toAddresses = new String[] {toAddressEmail};
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(toAddresses);
            mail.setSubject('Contract Owner Update Batch ' + a.Status);
            mail.setPlainTextBody('Total batches processed ' + a.TotalJobItems +
                                  ' with '+ a.NumberOfErrors + ' failures.');
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }
}