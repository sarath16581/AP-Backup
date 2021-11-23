/*Created By: Haider Raza*/
/*Created On: 02/08/2013*/
/*Purpose: Schedule class to be executed in order to update the Current Year field on Target and Revenue.*/


global with sharing class batchClassFixTargetANDRevenue implements Database.Batchable<SObject>{ 
    global String query;
    global Database.QueryLocator start(Database.BatchableContext info){ 
        query='SELECT Id, Name, Current_Last_Year__c, ';
        query+='Current_Year__c, Financial_Year__c ';
        query+=' FROM Budget_and_Revenue__c';
        query+=' WHERE Current_Last_Year__c=\'LAST YEAR\'';
        query+=' AND Current_Year__c=true';
//        query+=' LIMIT 100';
        return Database.getQueryLocator(query); 
    }     
    global void execute(Database.BatchableContext info, List<Budget_and_Revenue__c> scope){
        List<Budget_and_Revenue__c> brToUpdate = new List<Budget_and_Revenue__c>();
        for(Budget_and_Revenue__c br : scope){ 
            brToUpdate.add(br);
        } 
        try{
            update brToUpdate; 
        }catch(Exception e){
            System.debug('ERROR:' + e);         
        }
    }     
    global void finish(Database.BatchableContext info){ 
        // Send an email to the Apex job's submitter notifying of job completion.
       Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
       String[] toAddresses = new String[] {'haider.raza@auspost.com.au'};
       mail.setToAddresses(toAddresses);
       mail.setSubject('Target and Revenue been fixed.');
       mail.setPlainTextBody
           ('The batch Apex job processed.');
       Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    
    } 
}