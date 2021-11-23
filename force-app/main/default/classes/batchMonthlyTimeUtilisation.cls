/**************************************************
Type:       Apex  Batch Job Class for Monthly Time Utilisation
Purpose:    At the end of each month, generate Monthly Time Utilisation records for aggregation purpose
Used By:    UST
History:    Brett Ashworth requests this feature. 
--------------------------------------------------
06-10-2015  Eric Shen (AusPost)    Time Utilisation batch class 
**************************************************/


global class batchMonthlyTimeUtilisation implements Database.Batchable<sObject>
{
    
    // SOQL query from Timesheet Register object so all registered users can have their monthly TU records to be created. 
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
    String query = 'SELECT OwnerID FROM Timesheet_Register__c where Owner.IsActive=True ';  
        return Database.getQueryLocator(query);
    }
   
    global void execute(Database.BatchableContext BC, List<Timesheet_Register__c> TimeRegistries)
    
    
    {    //create a set for IDs to contain unique values
         Set <Id> oids = New Set <ID>();
         
         // loop through Timesheet Register object to get all owner IDs
        for(Timesheet_Register__c tr : TimeRegistries)
         {
            oids.add(tr.ownerID);
            
         }
         
         //Create a list for Monthly TIme Utilisation object 
         List<Monthly_Time_Utilisation__c> MTU =New List<Monthly_Time_Utilisation__c>();
         
       
         //get first day of next Month
         Date firstDayOfnextMonth = System.today().addMonths(1).toStartOfMonth();
         //Loop through set IDs
         for(Id pId : oids)
         {
             //create a sObject for Monthly Time Utilisation 
         Monthly_Time_Utilisation__c  mt = New Monthly_Time_Utilisation__c();
            //assign values to the sObject record and then add to the list. 
            mt.OwnerId=pId;
            mt.Month_Indicator__c =firstDayOfnextMonth;
            
            MTU.add(mt);
     
         }
         Database.Insert(MTU , false) ;
    }   
    global void finish(Database.BatchableContext BC)
    {
    }
}