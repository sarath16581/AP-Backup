/**
 * @description This Batch class is used to empty the CEPARC__DataArchiva_Purge_Cache__c object
 *              which temporarily stores the records to be purged from Big Object.
 * @author naveen.rajanna@auspost.com.au
 * @since 2021-10-26 
 */
global class DataArchivaDeletePurgeCacheBatch implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id FROM CEPARC__DataArchiva_Purge_Cache__c';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        try {
            delete scope;
        } catch(Exception e) {
        }
    }
    global void finish(Database.BatchableContext BC) {}
}