/*
@Description        : Batch class to identify all the activated apttus contract in the system and link the related files with
					  respective sf contract if it is not shared already
================================ Modification Log =============================== 
Developer Name  Date            Comments
Ramtej          27/03/2019      Created
Ramtej			24/06/2019		Removed Scheduled method to link files which is pushed to daily batch job instead which picks records range from custom setting
*/
global with sharing class APT_ContractFileShareBatch implements Database.Batchable<SObject>, Database.Stateful { 

    global Database.QueryLocator start(Database.BatchableContext bc){ 
        //Query to get all the activated apttus contracts
        string queryString = 'SELECT Id, Parent_Agreement__r.Apttus__Status_Category__C, Parent_Agreement__r.Apttus__Status__C ' +
            'FROM Contract WHERE Parent_Agreement__c != null AND Parent_Agreement__r.Apttus__Status_Category__C=\'In Effect\' ' +
            'AND Parent_Agreement__r.Apttus__Status__C=\'Activated\'';
        Apttus_Contract_File_Share_Schedule_date__c filesShareScheduleDate = Apttus_Contract_File_Share_Schedule_date__c.getOrgDefaults();
        //custom setting to check if date range should be applied
        if(filesShareScheduleDate.Date_check_required_to_run_batch__c && filesShareScheduleDate.File_Share_From_Date__c != null){
            string monthString = string.valueOf(filesShareScheduleDate.File_Share_From_Date__c.month());
            if(filesShareScheduleDate.File_Share_From_Date__c.month() < 10){
                monthString = '0'+monthString;
            }
            string dayString = string.valueOf(filesShareScheduleDate.File_Share_From_Date__c.day());
            if(filesShareScheduleDate.File_Share_From_Date__c.day() < 10){
                dayString = '0'+dayString;
            }
            string dateCompareString = filesShareScheduleDate.File_Share_From_Date__c.year()+'-'+monthString+'-'+dayString;
            //pick the contracts which has been activated after the date defined in custom setting
            queryString += 'AND Parent_Agreement__r.Apttus__Activated_Date__c >= '+dateCompareString;
        }
        queryString += ' ORDER BY Parent_Agreement__r.LastModifiedDate';
        system.debug('queryString '+queryString);
        return Database.getQueryLocator(queryString); 
    }
    
    global void execute(Database.BatchableContext bc, List<Contract> sfContractList){
        //use the existing method in scheduler to link the files of apttus contracts batch wise
        APT_ContractFileShareScheduler fileSharelinkClass = new APT_ContractFileShareScheduler();
        fileSharelinkClass.contractList = sfContractList;
        system.debug('sfContractList '+sfContractList);
        fileSharelinkClass.linkFiles();
    }
    
    global void finish(Database.BatchableContext bc){ 
        //update the date in custom setting so that next batch run will pick up the contracts activated after this date
     	Apttus_Contract_File_Share_Schedule_date__c filesShareScheduleDate = Apttus_Contract_File_Share_Schedule_date__c.getOrgDefaults();
        filesShareScheduleDate.File_Share_From_Date__c = system.today();
        update filesShareScheduleDate;
    }
}