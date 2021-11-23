/*------------------------------------------------------------
Author:          Melissa Carino
Description:     Batch class to mass clone Apttus Contract to SF Contract
Test Class:      BatchAgreementToSFContractTest

History
<Date>         <Authors Name>           <Brief Description of Change>
09/07/2018     Melissa Carino           Initial batch version to perform mass Apttus Contract cloning to SF Contract
15/10/2018     Melissa Carino           Added Send Email Notification on Finish method
------------------------------------------------------------*/

global class BatchAgreementToSFContract implements Database.Batchable<sObject>, Database.Stateful {
    public static final string INEFFECT_STATUS_CATEGORY = 'In Effect';
    public static final string ACTIVATED_STATUS = 'Activated';
    public String query; //variable for query
    public Set<String> SuccessSet = new Set<String>(); //Variable to store Success Id;
    public Set<String> ErrorSet  = new Set<String>(); //Variable to store Error Msg;
    @TestVisible static Integer emailLimits = 0;

    global Database.QueryLocator start(Database.BatchableContext bc) {

        // Build Apttus Contract query string
        Map <String, String> mapFieldsAPTContract = AgreementToSFContractTriggerHandler.getObjectMapping('Apttus__APTS_Agreement__c');
        List<String> APTContractFieldsList = new List<String>(mapFieldsAPTContract.keySet());
        String fieldToQuery = String.join(APTContractFieldsList, ',');

        //Get all records from Contract so we can get the Apttus ID already cloned
        //List<Contract> ListExistingRec =  [Select Parent_Agreement__c From Contract];

        //Build parent Apttus contract Id set
        /*
        Set<ID> IDs_ExistingRec = new Set<ID>();
        for (Contract rec : ListExistingRec){
            IDs_ExistingRec.add(rec.Parent_Agreement__c);
        }
		*/

        // Build query string for Apttus Contract
        query = 'SELECT RecordTypeId, Id, Name, CreatedDate,' + fieldToQuery + ' ';
        query += 'FROM Apttus__APTS_Agreement__c ' ;
        query += 'WHERE Apttus__Status_Category__c=\'' + INEFFECT_STATUS_CATEGORY + '\' ';
        query += 'AND Apttus__Status__c=\'' + ACTIVATED_STATUS + '\' ';
        query += 'AND ID NOT IN (Select Parent_Agreement__c from Contract)';
        //query += 'AND ID NOT IN :IDs_ExistingRec';
        system.debug(query);

        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<Apttus__APTS_Agreement__c> APTContractList){
        system.debug('List size value:' + APTContractList.size());
        // Call clone method to mass clone Apttus Contracts to SF Contract
        Database.UpsertResult[] results = AgreementToSFContractTriggerHandler.cloneApttusContract(APTContractList);
        // Handling of Error Msg and Success Id
        for(Database.UpsertResult resultRec:results) {
            system.debug('resultRec '+resultRec);
            if(resultRec.isSuccess()) 
                SuccessSet.add(resultRec.Id);
            List<Database.Error> errors = resultRec.getErrors();
            for(Database.Error errorRec:Errors) {
                ErrorSet.add(errorRec.getMessage());
            }
            system.debug('ErrorSet '+ErrorSet);
        }
    }

    global void finish(Database.BatchableContext bc){
        // Execute any post-processing operations
        
        // Fetch the ID of the AsyncApexJob representing this batch job  
        // from Database.BatchableContext.    
        // Query the AsyncApexJob object to retrieve the current job's information.  
        
        AsyncApexJob a = [Select Id, Status,ExtendedStatus,NumberOfErrors,
                            JobItemsProcessed, TotalJobItems, CreatedBy.Email
                            from AsyncApexJob
                            where Id =:bc.getJobId()];
        
        //Get the Job Id
        system.debug('Job Id' +bc.getJobId());
        
            
        // Send an email to the Apex job's submitter notifying of job completion.  
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {a.CreatedBy.Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Batch Cloning of Apttus Contract to SF Contract ' + a.Status);
       // mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems +
       // ' batches with '+ a.NumberOfErrors + ' failures.');
        
        // Creating of Html Body for Email
        String htmlBody = '<p>The batch Apex job processed ' + a.TotalJobItems +
        ' batches with '+ a.NumberOfErrors + ' failures.</p>';
       
        //Success ID Iteration for Html Body
        if(SuccessSet != null){
            HtmlBody += '<br/> <p> Success Id are : </p>';
            for(String SuccessRec : SuccessSet){
                HtmlBody += '<p>'+SuccessRec+'</p>';
            }
        } 
        
        //Error Msg Iteration for Html Body
        if(ErrorSet != null){
            HtmlBody += '<br/> <p> Error Msg are : </p>';
            for(String errorRec : ErrorSet){
                HtmlBody += '<p>'+errorRec+'</p>';
            }
        }
        
        
        mail.setHtmlBody(htmlBody);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        
        system.debug(toAddresses);
        system.debug('Batch Cloning of Apttus Agreement To Salesforce Contract is Finish.');
        //system.assert(false, Limits.getEmailInvocations());
        emailLimits = Limits.getEmailInvocations();
    }
}