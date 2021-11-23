/**
  * @author       : Snigdha.Sahu@auspost.com.au
  * @date         : 17/08/2016
  * @description  : Utilty for SAPContractsTrigger.
  */

public with sharing class SAPContractsUtility {
    /**
      * @description       This method syncs the volume and revenue values from SAP Contract Object to Apttus Agreement Object based on business rules. 
      * @param             Trigger values     
      * @return            Void
      * @throws            NA
      */
    
    public void syncVolumeRevenue(List<APT_SAP_Contracts__c> sapContractList) {
       
        //Map for Agreement Ids and related SAPContracts
        Map<Id, List<APT_SAP_Contracts__c>> mapAgreementToContracts = new Map<Id, List<APT_SAP_Contracts__c>>();
        //List<APT_SAP_Contracts__c> contractListForAgreement = new List<APT_SAP_Contracts__c>();
        Set<Id> agreementIdList = new Set<Id>{};
        try{        
                for  (APT_SAP_Contracts__c contractRec : sapContractList) {   
                    //added by kalpita for #1530
                    //update the SAP Contract Number with the 'temp sap contract number' to get the value incase it is updated
                    if(!String.isBlank( contractRec.APT_SAP_Contract_Number_temp__c ))  {
                        contractRec.APT_SAP_Contract_Number__c = contractRec.APT_SAP_Contract_Number_temp__c;
                    }
                    
                    if ( contractRec.APT_Apttus_Contract__c != null)  {
                        agreementIdList.add(contractRec.APT_Apttus_Contract__c); // fetch the agreement Ids based on the SAPContract List
                         if ( !mapAgreementToContracts.containsKey(contractRec.APT_Apttus_Contract__c)) {
                             //contractListForAgreement.add(contractRec);
                             mapAgreementToContracts.put(contractRec.APT_Apttus_Contract__c , new List< APT_SAP_Contracts__c>());
                         }
                         
                         //mapAgreementToContracts.put(contractRec.APT_Apttus_Contract__c , contractListForAgreement);
                         mapAgreementToContracts.get(contractRec.APT_Apttus_Contract__c).add(contractRec);
                    }
                }
                List<Apttus__APTS_Agreement__c>agreementList = new List<Apttus__APTS_Agreement__c>([SELECT Id, APT_Contract_Volume__c,  Apttus__Total_Contract_Value__c FROM Apttus__APTS_Agreement__c WHERE Id in : agreementIdList]);
                
                for (Apttus__APTS_Agreement__c ag: agreementList ) {   
                    system.debug('SAPContractsUtility : ag.Id ' + ag.Id);
                    
                    for (APT_SAP_Contracts__c con: mapAgreementToContracts.get(ag.Id)) {
                        system.debug('SAPContractsUtility : con.APT_Current_Quote_Indicator__c ' + con.APT_Current_Quote_Indicator__c);
                        
                        if('Y'.equalsIgnoreCase(con.APT_Current_Quote_Indicator__c)) {
                            system.debug('Inside : APT_Current_Quote_Indicator__c = Y condition');
                            ag.APT_Contract_Volume__c = con.APT_Contract_Volume__c;
                            ag.Apttus__Total_Contract_Value__c = con.APT_Contracted_Revenue__c;
                            
                        }
                        else {
                            if (ag.APT_Contract_Volume__c == null || ag.APT_Contract_Volume__c == 0 )  {
                                system.debug('Inside : APT_Contract_Volume__c = 0 condition');
                                ag.APT_Contract_Volume__c = con.APT_Contract_Volume__c;
                            }
                            if (ag.Apttus__Total_Contract_Value__c == null)  {   
                                system.debug('Inside : Apttus__Total_Contract_Value__c = null condition');
                                ag.Apttus__Total_Contract_Value__c = con.APT_Contracted_Revenue__c;
                            }
                        } 
                    }
                }
            
            if ( agreementList != null) {
                database.upsert(agreementList);
            }
        }       
        catch(Exception exp) {
            // Error Logged to Exception object for analysis
            UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
                                                    SAPContractsUtility.class.getName(), 'syncVolumeRevenue', 
                                                    'SAPContractsTrigger', LoggingLevel.ERROR);
        }
            
        
        
    }    
    
}