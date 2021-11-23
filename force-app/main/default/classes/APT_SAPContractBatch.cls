/*------------------------------------------------------------
Author:        Mausam Padhiyar
Company:       Apttus
Description:   Process SAP Contract record and populate contract end date on related contract.
Test Class:    APT_SAPContractBatch_Test
History
<Date>      <Authors Name>     <Brief Description of Change>
15/12/16    Mausam Padhiyar     First version.
17/8/18     Melissa Carino     Added logic to populate the contract extension date in Apttus Contract level.
                                If there are child SAP records the latest contract extension date
                                will populate the contract extension date in Apttus Contract level.
------------------------------------------------------------*/
global class APT_SAPContractBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {

    // Constants for aggregate field values
    public static final String OBJECT_CONTRACT = 'APT_Apttus_Contract__c';
    public static final String MIN_DATE = 'minDate';
    public static final String MAX_EXT_DATE = 'minExtDate';

    // Set of the Id of SAPContract
    global set<Id> apttusContractSet {get; set;}
    // Set of the Error messages
    global set<String> setErrorMessage {get; set;}

    /*------------------------------------------------------------
    Author:        Melissa Carino
    Company:       Apttus
    Description:   Constructor method to instantiate set variables for errors and sap contract Id
    Inputs:        sapContractIds Set of the SAP Contract record Ids
    Returns:       void
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    15/12/16    Mausam Padhiyar      First version
    ------------------------------------------------------------*/
    global APT_SAPContractBatch(set<Id> aptTempContractSet) {
        // assign sapContractIds to setSAPContractId for batch scope
        apttusContractSet = aptTempContractSet;
        // initalize Set setErrorMessage for batch finish apex email information
        setErrorMessage = new set<String>();
    }

    /*------------------------------------------------------------
    Author:        Mausam Padhiyar
    Company:       Apttus
    Description:   Batch start to query sap contract records
    Inputs:        BC BatchableContext
    Returns:       Database.QueryLocator
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    15/12/16    Mausam Padhiyar      First version
    ------------------------------------------------------------*/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Query all sap contracts based on the sap contract Id set
        return Database.getQueryLocator([SELECT Id, APT_Mark_for_Review__c, Apttus__Contract_End_Date__c, APT_Contract_Extension_Date__c
                                         FROM Apttus__APTS_Agreement__c
                                         where Id IN :apttusContractSet
                                         AND APT_Mark_for_Review__c = false]);
    }

    /*------------------------------------------------------------
    Author:        Adrian Recio
    Company:       Accenture
    Description:   Batch execute to process matching sap contract records.
                   Latest extension date and end date from child sap contracts will roll up to the parent apttus contract record.
    Inputs:        BC BatchableContext
                   listSAPContract list of the records to process in this chunk
    Returns:       void
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    15/12/16    Mausam Padhiyar      First version
    ------------------------------------------------------------*/
    global void execute(Database.BatchableContext BC, list<Apttus__APTS_Agreement__c> parentAptContractList){
        try {
            Map<Id, Apttus__APTS_Agreement__c> parentAptContractMap = new Map<Id, Apttus__APTS_Agreement__c>();
            parentAptContractMap.putAll(parentAptContractList);
            set<Id> setAgrIdSet = parentAptContractMap.keySet();

            // Aggregate Query for the MIN Contract End Date of the Agreements
            AggregateResult[] groupedResults = [SELECT APT_Apttus_Contract__c,
                                                MIN(APT_Contract_End_Date__c) minDate,
                                                MAX(APT_Contract_Extension_Date__c) minExtDate
                                                FROM APT_SAP_Contracts__c
                                                WHERE (APT_Apttus_Contract__c IN :setAgrIdSet
                                                        AND APT_Contract_End_Date__c != null
                                                        AND SAP_Contract_Status__c = :APT_Constants.ACTIVE)
                                                GROUP BY APT_Apttus_Contract__c];

            // Map of Agreement to End Date
            Map<String,Date> agrIDtoEndDateMap = new Map<String,Date>();
            // Map of Agreement to Extension Date
            Map<String,Date> agrIDtoExtDateMap = new Map<String,Date>();
            for (AggregateResult ar : groupedResults)  {
                // Populate map of contract and its oldest sap contract end date
                agrIDtoEndDateMap.put(String.valueOf(ar.get(OBJECT_CONTRACT)),
                                      Date.valueOf(ar.get(MIN_DATE)));

                // Populate map of contract and its latest contract extension date
                agrIDtoExtDateMap.put(String.valueOf(ar.get(OBJECT_CONTRACT)),
                                      Date.valueOf(ar.get(MAX_EXT_DATE)));
            }

            system.debug('agrIDtoEndDateMap:' + agrIDtoEndDateMap);
            system.debug('agrIDtoExtDateMap:' + agrIDtoExtDateMap);

            // list of the Agreement to update
            list<Apttus__APTS_Agreement__c> agrUpdateList = new list<Apttus__APTS_Agreement__c>();

            // List of the SAP Contracts to process
            for(Apttus__APTS_Agreement__c aptAgrVar : parentAptContractList) {
                //Logic to get oldest End Date among SAP Contract records for roll up to parent contract
                if(agrIDtoEndDateMap.containsKey(aptAgrVar.Id)) {
                    system.debug('agrIDtoEndDateMap key match.');
                    system.debug('agrIDtoEndDateMap key value:' + agrIDtoEndDateMap.get(aptAgrVar.Id));
                    aptAgrVar.Apttus__Contract_End_Date__c = agrIDtoEndDateMap.get(aptAgrVar.Id);
                }

                //Logic to get latest Extension Date among SAP Contract records for roll up to parent contract
                if(agrIDtoExtDateMap.containsKey(aptAgrVar.Id)) {
                    system.debug('agrIDtoExtDateMap key match.');
                    system.debug('agrIDtoExtDateMap key value:' + agrIDtoExtDateMap.get(aptAgrVar.Id));
                    aptAgrVar.APT_Contract_Extension_Date__c = agrIDtoExtDateMap.get(aptAgrVar.Id);
                }
                system.debug('aptAgrVar.Apttus__Contract_End_Date__c:' + aptAgrVar.Apttus__Contract_End_Date__c);
                system.debug('aptAgrVar.APT_Contract_Extension_Date__c:' + aptAgrVar.APT_Contract_Extension_Date__c);
                agrUpdateList.add(aptAgrVar);
            }
            // Update the list of agreement to populate new extension and end dates based on child sap contracts
            if(agrUpdateList.size() > 0) {
                update agrUpdateList;
            }
        } catch(system.exception ex) {
            setErrorMessage.add(ex.getMessage());
        }
    }

    /*------------------------------------------------------------
    Author:        Mausam Padhiyar
    Company:       Apttus
    Description:   Batch finish to send batch execute apex email status
    Inputs:        BC BatchableContext
    Returns:       void
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    15/12/16    Mausam Padhiyar      First version
    ------------------------------------------------------------*/
    global void finish(Database.BatchableContext BC) {

        // Send Email if there is any errors in the list
        if(setErrorMessage.size() > 0) {
            // Query the job for the job errors
            AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, ExtendedStatus
                                FROM AsyncApexJob
                                WHERE Id = :BC.getJobId()];

            // add job errors in the same list
            if(a.NumberOfErrors > 0) {
                setErrorMessage.add(a.ExtendedStatus);
            }

            // Email messaging object
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            //get email addresses from the custom setting
            APT_R2T_System_Properties__c r2tSystemProperties = APT_R2T_System_Properties__c.getOrgDefaults();
            String emailAddresses;
            if(r2tSystemProperties != null) {
                if(!String.isEMpty(r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c)) {
                    emailAddresses = r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c;
                }
            }
            list<String> toAddresses = new list<String>();
            if(!String.isEmpty(emailAddresses)) {
                toAddresses = emailAddresses.split(APT_Constants.SEPERATOR_COMMA);
            }
            // Set to addresses
            mail.setToAddresses(toAddresses);

            mail.setSubject(APT_Constants.SYNC_CONTRACT_RATES_ERROR);

            //Handle Batch Error Message
            Integer iErrorCount = setErrorMessage.size();

            // Error message for the Email body
            String errorMessage;
            for(String errorMessage1 : setErrorMessage) {
                if(String.isNotBlank(errorMessage)) {
                    errorMessage += APT_Constants.SEPERATOR_NEW_LINE + errorMessage1;
                } else {
                    errorMessage = errorMessage1;
                }
            }

            //add Batch Error Message in Email
            if(String.isNotBlank(errorMessage)) {
                mail.setPlainTextBody(APT_Constants.SAP_CONTRACT_JOB_COMPLETED + iErrorCount + APT_Constants.FAILURES_ERRORS + errorMessage);
            }

            // Send Email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }
}