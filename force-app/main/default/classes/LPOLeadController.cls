/* @author Mav3rik
 * @date 2020-10-27
 * @group Lead
 * @tag Lead
 * @domain Core
 * @description Controller class for lpoCreateNewLead lwc component
 * @changelog
 * 2020-10-27 - Mav3rik - Created
 */
public class LPOLeadController {

    /**
     * @description Inserts a new Lead and validates for Lead duplicates
     * If allowSave, override the duplicate rule and insert the new record
     * otherwise, throws exception with the duplicate record value
     *
     * ## leadRecord (Lead): leadRecord - The lead to be inserts
     * @@ Return String: Returns the Lead Record Id
     */
    @AuraEnabled
    public static String saveLead(Lead leadRecord){
        // DMLOptions that override duplicate rule when inserting
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;
        dml.DuplicateRuleHeader.RunAsCurrentUser = true;
        Database.SaveResult saveResult = Database.insert(leadRecord, dml);
        String exMessage;
        if (!saveResult.isSuccess()) {
            for (Database.Error error : saveResult.getErrors()) {
                System.debug(error);
                exMessage = error.getMessage();
            }
            AuraHandledException ex = new AuraHandledException(exMessage);
            throw ex;
        }
        return saveResult.getId();
    }
    
    /**
     * @description Updates a Lead Record
     *
     * ## leadRecord (Lead): leadRecord - The lead to be updated
     * @@ Return Lead: Return The updated lead record
     */
    @AuraEnabled
    public static Lead updateLead(Lead leadRecord){
        try {
            List<Database.SaveResult> saveResult = ApplicationDatabase.getInstance().dmlUpdate(new List<Lead>{leadRecord});
            return leadRecord;
        } catch(Exception e) {
            throw e;
        }
    }

    /**
     * getDuplicateRecordDetails 
     *
     * ## idList (List<Id>): idList
     * @@ Return List<SObject>: Return description
     */
    public static List<SObject> getDuplicateRecordDetails(List<Id> idList) {
        List<SObject> results = new List<SObject>();
        // check the SObject
        String type = idList[0].getSobjectType().getDescribe().getName();
        switch on type {
            when 'Lead' {
                results = [SELECT Id, Name, Address FROM Lead WHERE Id IN :idList LIMIT 3];
            }
            when 'Contact' {
                results = [SELECT Id, Name, MailingAddress FROM Contact WHERE Id IN :idList LIMIT 3];
            }
            when 'Account' {
                results = [SELECT Id, Name, BillingAddress FROM Account WHERE Id IN :idList LIMIT 3];
            }
        }
        return results;
    }
  
    /**
     * @description Check for duplicate records using the FindDuplicates class
     * Exact match: FindDuplicates will return a list of records that is going to be parsed as JSON as part of the exception message
     * Fuzzy match: FindDuplicates can check which objects are triggering the duplicate rule but there are no records/error returned
     * Return the error (and JSON records) as an AuraHandledException
     *
     * ## leadRecord (Lead): leadRecord - The lead to be checked
     * @@ Return Boolean: If there are no duplicates, return true. Else, only exceptions is returned
     */
    @AuraEnabled
    public static Boolean checkDuplicates(Lead leadRecord){
        String delim = '|'; // Do not change without updating lpoCreateNewLead.js as well
        String exMessage;
        List<SObject> queryResults = new List<SObject>();
  
        // Since we are only checking a single leadRecord, we just grab the first FindDuplicateResult
        Datacloud.FindDuplicatesResult foundDuplicateResult = Datacloud.FindDuplicates.findDuplicates(new List<SObject>{leadRecord})[0];
        // Grab the first DuplicateResult since there's only one duplicate rule in place
        Datacloud.DuplicateResult duplicateResult = foundDuplicateResult.getDuplicateResults()[0];
        String errorMessage = duplicateResult.getErrorMessage();
        // Loop through the rules to check if there's any returned records
        Datacloud.MatchResult[] matchResults = duplicateResult.getMatchResults();
        for (Datacloud.MatchResult matchResult : matchResults) {
            Datacloud.MatchRecord[] matchRecords = matchResult.getMatchRecords();
            if (matchRecords.size() == 0) {
                break;
            }
            List<Id> idList = new List<Id>();
            for(Datacloud.MatchRecord matchRecord : matchRecords) {
                SObject record = matchRecord.getRecord();
                idList.add(record.Id);
            }
            queryResults.addAll(getDuplicateRecordDetails(idList));
        }

        if (queryResults.size() == 0) {
            if(String.isBlank(errorMessage)) {
                return true;
            }
            // Case where there is nothing returned but duplicate error exists
            exMessage = 'Duplicate records may exist, are you sure you want to proceed?';
        }
        // Case where there is duplicate error and some records are returned -> return error
        else {
            exMessage = 'Lead duplicate has been found. ' + errorMessage + delim + JSON.serialize(queryResults);
        }
        AuraHandledException ex = new AuraHandledException(exMessage);
        ex.setMessage(exMessage);
        throw ex;
    }
  }