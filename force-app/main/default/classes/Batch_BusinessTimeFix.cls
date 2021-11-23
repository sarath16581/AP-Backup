/**
  * @author       : nandan.narasappa@auspost.com.au
  * @date         : 17/12/2015
  * @description  : Batch class to fix INC0650131 issue to update business hour for status tracking records
  */
global without sharing class Batch_BusinessTimeFix implements Database.Batchable<sObject>{
    
    private String queryString; // query to fetch records in scope
    
    /**
      *   @Method <This method executes batch one time to fetch status tracking records with 
      *             no business hour & calculate time spent based on business hour>
      *   @param <query - Customer offer query>
      *   @return <NA>
      *   @throws exception - <Method is not throwing exception>
      */
    /**
      * @description       This method executes batch one time to fetch status tracking records with 
      *                    no business hour & calculate time spent based on business hour
      * @param             NA 
      * @return            Void
      * @throws            Method might throw exception which is handled in batch execute method
      */  
    public static void executeBatch(){
        String query = 'SELECT Case__c, Name,OwnerId__c, Duration__c, BusinessHours__c, Fax__c, StatusValue__c,CreatedDate, StartDate__c, EndDate__c, SubsequentStatusValue__c FROM StatusTracking__c WHERE StatusValue__c != \'Closed\' AND BusinessHours__c = null AND Duration__c = null ';
        Batch_BusinessTimeFix batchJob = new Batch_BusinessTimeFix(query);
        Database.executeBatch(batchJob);
    }
    
    /**
      *   @Method <Constructor - initializing the query>
      *   @param <query - Customer offer query>
      *   @return <NA>
      *   @throws exception - <Method is not throwing exception>
      */
    global Batch_BusinessTimeFix(String query){
        queryString = query;
    }
    
    /**
      *   @Method <Start method returning query locator for customer offers>
      *   @param <currentScope - Database.BatchableContext>
      *   @return <Database.QueryLocator>
      *   @throws exception - <Method is not throwing exception>
      */
    global Database.QueryLocator start(Database.BatchableContext currentScope){
         return Database.getQueryLocator(queryString);
    }
    
    /**
      *   @Method <Execute method for deleting expired Customer Offers and updating offers from bulk upload>
      *   @param <currentScope - Database.BatchableContext, trackingList - list of status tracking records>
      *   @return <void>
      *   @throws exception - <Method is not throwing exception>
      */
    global void execute(Database.BatchableContext currentScope, List<StatusTracking__c> trackingList){                        
        System.debug('*** trackingList ==>'+ trackingList);
        if(!trackingList.isEmpty()){
            updateOldTrackings(trackingList);
        }
    }
    
    /**
      *   @Method <Finish method for post processing the Customer Offers>
      *   @param <currentScope - Database.BatchableContext>
      *   @return <void>
      *   @throws exception - <Method is not throwing exception>
      */
    global void finish(Database.BatchableContext currentScope){
    
    }
    
    
    /**
      * @description       This method returns the updated open case tracking records with duration & subsequent status value
      * @param             trackingMap - Map<Id,List<StatusTracking__c>>,caseMap - Map<Id,Case>, fieldMap - Map<Id,String>
      * @return            List<StatusTracking__c>
      * @throws            Method might throw exception which is handled by invoked method
      */
    private static void updateOldTrackings(List<StatusTracking__c> trackingList){
        List<StatusTracking__c> updatedTrackingList = new List<StatusTracking__c>();
        Set<Id> ownerIds = new Set<Id>();
        Map<Id,String> userTimeZoneMap = new Map<Id,String>();
        Map<String,Id> businessHourMap =  Utility.getBussinessHourMap();    // get business hours for SSSW application
        for(StatusTracking__c tracking : trackingList){
            ownerIds.add(tracking.OwnerId__c);
        }
        System.debug('*** ownerIds ==>'+ ownerIds);
        if(!ownerIds.isEmpty()){
            for(User usr : [SELECT Id,TimeZoneSidKey FROM User WHERE Id IN: ownerIds]){
                userTimeZoneMap.put(usr.Id,usr.TimeZoneSidKey);
            }
            System.debug('*** userTimeZoneMap ==>'+ userTimeZoneMap);
            System.debug('*** businessHourMap ==>'+ businessHourMap);
            for(StatusTracking__c tracking : trackingList){
                Id businessHourId = userTimeZoneMap.containsKey(tracking.OwnerId__c) && businessHourMap.containsKey(userTimeZoneMap.get(tracking.OwnerId__c)) ? 
                                    businessHourMap.get(userTimeZoneMap.get(tracking.OwnerId__c)) : businessHourMap.get(SSSWConstants.DEF_TZKEY);
                System.debug('*** businessHourId ==>'+ businessHourId);
                tracking.BusinessHours__c = businessHourId;
                // Duration Calculation
                Double durationInSecs = 0;
                // get diff based on business hours                    
                tracking.Duration__c = (tracking.BusinessHours__c != null) ? 
                                            BusinessHours.diff(tracking.BusinessHours__c, tracking.StartDate__c, tracking.EndDate__c)
                                            : tracking.Duration__c;
                if(tracking.Duration__c != null){
                    durationInSecs = tracking.Duration__c / 1000;   // convert milliseconds to seconds
                    tracking.DurationHours__c = (Integer) durationInSecs / 3600 ;   // convert seconds to hours
                    durationInSecs = durationInSecs - (tracking.DurationHours__c * 3600);   // get remaining seconds
                    tracking.DurationMins__c  = (Integer) durationInSecs / 60   ;   // convert seconds to hours
                    durationInSecs = durationInSecs - (tracking.DurationMins__c * 60);  // get remaining seconds
                    tracking.DurationSeconds__c = (Integer) durationInSecs; // set remaining seconds
                }
                updatedTrackingList.add(tracking);
            }
            System.debug('*** updatedTrackingList ==>'+ updatedTrackingList);
            if(!updatedTrackingList.isEmpty()){
                Database.update(updatedTrackingList,false);
            }
        }

    }
}