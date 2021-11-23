/**
  * @author       : snigdha.sahu@auspost.com.au
  * @date         : 07/09/2015    
  * @description  : This Class is to sync Volume and Revenue fields between SAPContracts and Agreement records
  */
/*******************************  History ************************************************
07/09/2015  snigdha.sahu@auspost.com.au   Created
    
*******************************  History ************************************************/
global without sharing class SAPContracts_Agreements_Batchable implements Database.Batchable<SObject> {

    
    /* Private Variables */
    private String query;
    
	/** 
      * @name: SAPContracts_Agreements_Batchable()
      * @desciption: batch class constructor
      * @param: Database.BatchableContext
      * @return: Database.QueryLocator
      *
      */
    global SAPContracts_Agreements_Batchable() {
              
        
        /* Query all records from the SAPContracts table which have been updated Today*/
		
		query = 'Select APT_Apttus_Contract__c, APT_SAP_Contract_Number_temp__c, APT_Contract_Volume__c, APT_Contracted_Revenue__c, APT_Current_Quote_Indicator__c '
		+ 'FROM APT_SAP_Contracts__c WHERE LastModifiedDate = TODAY and APT_Apttus_Contract__c <> null ';
    }
	
	/** 
      * @name: start()
      * @desciption: start method to run the query and get the results
      * @param: Database.BatchableContext
      * @return: Database.QueryLocator
      *
      */
	global Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug(System.LoggingLevel.DEBUG, '##DEBUG: START - query: ' + query);
        return Database.getQueryLocator(query);
    }

    /** 
      * @name: finish()
      * @desciption: method to perform tasks once the batch is complete
      * @param: NA
      * @return: NA
      *
      */
    global void finish(Database.BatchableContext BC) {
        system.debug('*** FINISH:');    
    }   
	
	/** 
      * @name: execute()
      * @desciption: execution for syncing of volume and revenue fields and Contract Number value
      * @param: Database.BatchableContext BC, List<SObject> customersToMerge
      * @return: NA
      *
      */
	global void execute(Database.BatchableContext BC, List<SObject> sapContractList) {
		//Map for Agreement Ids and related SAPContracts
        Map<Id, List<APT_SAP_Contracts__c>> mapAgreementToContracts = new Map<Id, List<APT_SAP_Contracts__c>>();
        //List<APT_SAP_Contracts__c> contractListForAgreement = new List<APT_SAP_Contracts__c>();
        Set<Id> agreementIdList = new Set<Id>{};
		
            
		try {
				for  (APT_SAP_Contracts__c contractRec : (List<APT_SAP_Contracts__c>) sapContractList) {   
                    //Update the SAP Contract Number with the 'temp sap contract number' to get the value incase it is updated
                    
                    if(!String.isBlank( contractRec.APT_SAP_Contract_Number_temp__c ))  {
                        contractRec.APT_SAP_Contract_Number__c = contractRec.APT_SAP_Contract_Number_temp__c;
                    }
                    
                    if ( contractRec.APT_Apttus_Contract__c != null)  {
                         agreementIdList.add(contractRec.APT_Apttus_Contract__c); // fetch the agreement Ids based on the SAPContract List
                         if ( !mapAgreementToContracts.containsKey(contractRec.APT_Apttus_Contract__c)) {
                            
                             mapAgreementToContracts.put(contractRec.APT_Apttus_Contract__c , new List< APT_SAP_Contracts__c>());
                         }                        
                      
                         mapAgreementToContracts.get(contractRec.APT_Apttus_Contract__c).add(contractRec);
                    }
                    
                }
            	// Updated by Adrian Recio
            	// Date 29/06/2017
            	// Added TotalOPLItemPrice field for value assignment
                List<Apttus__APTS_Agreement__c>agreementList = new List<Apttus__APTS_Agreement__c>([SELECT Id, APT_Contract_Volume__c,  Apttus__Total_Contract_Value__c,
                                                                                                    Apttus_QPComply__RelatedProposalId__r.APT_TotalOPLineItemPrice__c
                                                                                                    FROM Apttus__APTS_Agreement__c WHERE Id in : agreementIdList]);
                
                for (Apttus__APTS_Agreement__c ag: agreementList ) {   
                    system.debug('SAPContractsUtility : ag.Id ' + ag.Id);
                    
                    for (APT_SAP_Contracts__c con: mapAgreementToContracts.get(ag.Id)) {
                        system.debug('SAPContractsUtility : con.APT_Current_Quote_Indicator__c ' + con.APT_Current_Quote_Indicator__c);
                        
                        if('Y'.equalsIgnoreCase(con.APT_Current_Quote_Indicator__c)) {
                            system.debug('Inside : APT_Current_Quote_Indicator__c = Y condition');
                            ag.APT_Contract_Volume__c = con.APT_Contract_Volume__c;
                            // Updated by Adrian Recio
                            // Date 29/06/2017
                            // Description: Assignment updated and new value will be based on OP total related to contract
                            //ag.Apttus__Total_Contract_Value__c = ag.APT_Contracted_Revenue__c;
                            ag.Apttus__Total_Contract_Value__c = ag.Apttus_QPComply__RelatedProposalId__r.APT_TotalOPLineItemPrice__c;
                            
                        }
                        else {
                            if (ag.APT_Contract_Volume__c == null || ag.APT_Contract_Volume__c == 0 )  {
                                system.debug('Inside : APT_Contract_Volume__c = 0 condition');
                                ag.APT_Contract_Volume__c = con.APT_Contract_Volume__c;
                            }
                            if (ag.Apttus__Total_Contract_Value__c == null)  {   
                                system.debug('Inside : Apttus__Total_Contract_Value__c = null condition');
                                // Updated by Adrian Recio
                                // Date 29/06/2017
                                // Description: Assignment updated and new value will be based on OP total related to contract
                                //ag.Apttus__Total_Contract_Value__c = ag.APT_Contracted_Revenue__c;
                            	ag.Apttus__Total_Contract_Value__c = ag.Apttus_QPComply__RelatedProposalId__r.APT_TotalOPLineItemPrice__c;
                            }
                        } 
                    }
                }
            Database.upsert(sapContractList);
            if ( agreementList != null) {
                database.upsert(agreementList);
            }
        }       
		catch(Exception exp) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), 'R2T', 
                                                    'SAPContracts_Agreements_Batchable', 'execute', 
                                                    null, LoggingLevel.ERROR);
        }
	
	}
    
}