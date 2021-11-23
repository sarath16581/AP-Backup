/*------------------------------------------------------------
Author:        Mausam Padhiyar
Company:       Apttus
Description:   SAP Contract Job to populate contract end date on related contract
               How to execute?
               system.schedule('SAP Contracts Job', '0 8 19 15 12 ?', new APT_SAPContractSchedule());
Test Class:    APT_SAPContractBatch_Test
History
<Date>      <Authors Name>     <Brief Description of Change>
15/12/16    Mausam Padhiyar     First version.
------------------------------------------------------------*/
global class APT_SAPContractSchedule implements Schedulable {
    /*------------------------------------------------------------
    Author:        Mausam Padhiyar
    Company:       Apttus
    Description:   Execute method of schedulable class.
                   Method will call the batchable class APT_SAPContractBatch to sync
                   child sap contract values to apttus contract that has new child sap contract records.
    Inputs:        SchedulableContext SC
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    15/12/16    Mausam Padhiyar      First version
    ------------------------------------------------------------*/
    global void execute(SchedulableContext SC) {

        // Set of parent apttus contract Ids
        set<Id> apttusContractSet = new set<Id>();

        // Query all sap contracts that is system or user modified for the last 1 day onwards
        for(APT_SAP_Contracts__c sapContract : [SELECT APT_Apttus_Contract__c
                                                FROM APT_SAP_Contracts__c
                                                WHERE SystemModStamp >= LAST_N_DAYS:1
                                                AND APT_Apttus_Contract__c != null
                                                limit 50000]) {
            // Populate set
            apttusContractSet.add(sapContract.APT_Apttus_Contract__c);
        }

        // If there are sap contract Ids, execute APT_SAPContractBatch
        if(apttusContractSet.size() > 0) {
            APT_SAPContractBatch controller = new APT_SAPContractBatch(apttusContractSet);
            database.executeBatch(controller, 1);
        }
    }
}