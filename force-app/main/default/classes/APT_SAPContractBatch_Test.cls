/*------------------------------------------------------------------------
Author:         Melissa Carino
Company:        Accenture
Description:    Test class for APT_SAPContractBatch to process SAP Contract record
                and populate the contract extension date in Apttus Contract level.
                If there are child SAP records the latest contract extension date
                will populate the contract extension date in Apttus Contract level.
History
<Date>        <Authors Name>      <Brief Description of Change>
18/08/18      Melissa Carino    First version.
----------------------------------------------------------------------------*/
@isTest
private class APT_SAPContractBatch_Test{

    public static final string MSA_RECORTYPE = 'MSA & Service Schedule';
    public static final string INSIGNATURE_STATUS_CATEGORY = 'In Signature';
    public static final string RECONCILED_STATUS = 'Reconciled';

    /*------------------------------------------------------------
    Author:        Melissa Carino
    Company:       Accenture
    Description:   Setup data to create test apttus contract and multiple sap contract with different extension date and end dates
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    22-Oct-2018  Melissa Carino     Created setup data initial version
    ------------------------------------------------------------*/
    @testSetup static void setup(){

        APT_R2T_System_Properties__c r2tSystemProperties = new APT_R2T_System_Properties__c();
        r2tSystemProperties.APT_PricingBatchStatusEmailNotification__c = 'test@testuser.com';
        insert r2tSystemProperties;

        // Create test account
        Account accVar = APT_TestUtil2.createOrganisation();
        insert accVar;

        // Create test contact
        Contact conVar = APT_TestUtil2.createContact();
        conVar.AccountId = accVar.Id;
        insert conVar;


        // Create test opportunity
        Opportunity oppVar = APT_TestUtil2.createOpportunity(accVar);
        insert oppVar;

        // Create test agreement
        Apttus__APTS_Agreement__c aptContract = APT_TestUtil2.createAgreement(accVar,
                                                                              conVar,
                                                                              oppVar,
                                                                              new Apttus_Proposal__Proposal__c(),
                                                                              RECONCILED_STATUS,
                                                                              INSIGNATURE_STATUS_CATEGORY,
                                                                              MSA_RECORTYPE);
        aptContract.Apttus__Contract_End_Date__c = Date.today();
        aptContract.Apttus__Contract_Start_Date__c = Date.today() - 365;
        aptContract.APT_Contract_Extension_Date__c = null;
        aptContract.APT_Mark_for_Review__c = false;
        insert aptContract;

        // Create test sap contract with varying end date and extension date
        List<APT_SAP_Contracts__c> aptSAPConList = new List<APT_SAP_Contracts__c>();
        APT_SAP_Contracts__c sapContract = APT_TestUtil2.createSAPContract(aptContract);
        sapContract.APT_SAP_Contract_Number__c = '0000001';
        sapContract.APT_Contract_Extension_Date__c = Date.today() + 40;
        sapContract.APT_Contract_Start_Date__c = Date.today() - 365;
        sapContract.APT_Contract_End_Date__c = Date.today() + 30;
        aptSAPConList.add(sapContract);
        APT_SAP_Contracts__c sapContract1 = APT_TestUtil2.createSAPContract(aptContract);
        sapContract1.APT_SAP_Contract_Number__c = '0000002';
        sapContract1.APT_Contract_Extension_Date__c = Date.today() + 30;
        sapContract1.APT_Contract_Start_Date__c = Date.today() - 365;
        sapContract1.APT_Contract_End_Date__c = Date.today() + 20;
        aptSAPConList.add(sapContract1);
        APT_SAP_Contracts__c sapContract2 = APT_TestUtil2.createSAPContract(aptContract);
        sapContract2.APT_SAP_Contract_Number__c = '0000003';
        sapContract2.APT_Contract_Extension_Date__c = Date.today() + 20;
        sapContract2.APT_Contract_Start_Date__c = Date.today() - 365;
        sapContract2.APT_Contract_End_Date__c = Date.today() + 10;
        aptSAPConList.add(sapContract2);
        insert aptSAPConList;
    }

    /*------------------------------------------------------------
    Author:        Adrian Recio
    Company:       Accenture
    Description:   Scenario: Execute sap contract batch to roll up values to agreement based on child sap contract records.
                   Outcome: Oldest contract end date from child sap contract should roll up to its parent apttus contract
                            Latest contract extension date from child sap contract should roll up to its parent apttus contract
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    22-Oct-2018  Adrian Recio    Initial version
    ------------------------------------------------------------*/
    static testMethod void validateContractMassClone() {
        // Query parent apttus contract
        Apttus__APTS_Agreement__c aptContract = [Select Apttus__Contract_End_Date__c, APT_Contract_Extension_Date__c,
                                                    (Select Id, APT_Contract_End_Date__c, APT_Contract_Extension_Date__c
                                                    from SAPContracts__r)
                                                 from Apttus__APTS_Agreement__c];

        Date oldestEndDate;
        Date latestExtDate;

        // Identify oldest end date and latest extension date based on current test data
        for(APT_SAP_Contracts__c sapCVar: aptContract.SAPContracts__r){
            if(sapCVar.APT_Contract_End_Date__c < oldestEndDate || oldestEndDate == null){
                oldestEndDate = sapCVar.APT_Contract_End_Date__c;
            }

            if(sapCVar.APT_Contract_Extension_Date__c > latestExtDate || latestExtDate == null){
                latestExtDate = sapCVar.APT_Contract_Extension_Date__c;
            }
        }

        Test.startTest();
        // Execute batch to process sap contract
        Set<Id> aptIdSet = new Set<Id>();
        aptIdSet.add(aptContract.Id);

        // Schedule batch
        Datetime dt = Datetime.now().addMinutes(1);
        String CRON_EXP = '0 '+ dt.minute() + ' * ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
        String jobId = System.schedule('APT_SAPContractSchedule_ScheduleApexClassTest',  CRON_EXP, new APT_SAPContractSchedule());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(CRON_EXP, ct.CronExpression, 'Cron expression should be ' + CRON_EXP);
        System.assertEquals(0, ct.TimesTriggered);

        // Test email message 
        APT_SAPContractBatch controller = new APT_SAPContractBatch(aptIdSet);
        controller.setErrorMessage.add('Test message.');
        Database.executeBatch(controller, 200);

        Test.stopTest();

        // Re-query parent apttus contract after batch run
        aptContract = [Select Apttus__Contract_End_Date__c, APT_Contract_Extension_Date__c from Apttus__APTS_Agreement__c];

        // Check that oldest end date is populated
        system.assertEquals(oldestEndDate, aptContract.Apttus__Contract_End_Date__c, 'Check that oldest end date is populated');

        // Check that latest extension date is populated
        system.assertEquals(latestExtDate, aptContract.APT_Contract_Extension_Date__c, 'Check that latest extension date is populated');
    }


}