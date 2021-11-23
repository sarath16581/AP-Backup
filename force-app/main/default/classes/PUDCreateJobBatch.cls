/**
* @description Batchable class to create new set jobs from bookings based on an input date range:
*
* Called from:
*        - PUDCreateJobBatchScheduler schedule
*
* @changelog
* 2019-08-27 - ajudd@salesforce.com - Created
* 2021-08-31 - Ranjeewa Silva - Updated to use PUDUtility.getInstance() to create a new instance
* 2021-09-17 - Ranjeewa Silva - Chained batch job that sync current day's job to dispatch system
*/
public class PUDCreateJobBatch implements Database.Batchable<sObject>{
    
    public Date dateFrom = PUDUtility.DATE_FROM;
    public Date dateTo = PUDUtility.DATE_TO;
    public Boolean bolRefreshAll;

    public PUDCreateJobBatch(Boolean refAll){
        bolRefreshAll=refAll; //If true - refereshs all jobs (i.e. does full compare of new and existing). If false - only adds new jobs 
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        //Get Booking detail to pass to execute
        return Database.getQueryLocator([SELECT Id, Effective_Date_Calc__c, Expiry_Date_Calc__c
                                         FROM PUD_Booking__c 
                                         WHERE isDeleted=false]);
    }
    
    public void execute(Database.BatchableContext BC, List<PUD_Booking__c> PUDBookingList){
        try{
            System.debug('Booking input size = ' +  PUDBookingList.size());
            System.debug('RefreshAll = ' + bolRefreshAll);
            
            Set<Id> bookingIdSet = new Set<Id>(); //Ids of valid bookings based on date range

            //For all bookings in batch. 
            for(Integer i = PUDBookingList.size() - 1; i >= 0; i--) {
                
                //If Booking is active within the job create date range
                //The effective date is prior to date to (i.e. not a future booking), and the expiry date is after today (i.e. booking hasnt expired)
                If(PUDBookingList[i].Effective_Date_Calc__c <= dateTo && (PUDBookingList[i].Expiry_Date_Calc__c >= dateFrom || PUDBookingList[i].Expiry_Date_Calc__c == null)){
                    //Add booking id to set
                    bookingIdSet.add(PUDBookingList[i].Id);
                }
            }      
                
            System.debug('Bookings to process = ' +  bookingIdSet.size());
    
            //If bookings to process
            If(bookingIdSet.size() > 0){

                PUDUtility.getInstance().createJobs(bookingIdSet, bolRefreshAll);

            }//end bookings to process
            
        } catch(Exception exp) {
			//Log error to Exception object for analysis
			UTIL_LoggingService.logHandledException(exp, UserInfo.getOrganizationId(), PUDConstants.PICKUP_BOOKING_APP, PUDCreateJobBatch.class.getName(), 'execute', null, LoggingLevel.ERROR);
		}
    }
    
    public void finish(Database.BatchableContext BC){
        // get the batch size configured in custom settings. defaults to 200 if configuration is not available.
        Pickup_Booking_Settings__c pickupBookingSettings = Pickup_Booking_Settings__c.getInstance();
        Integer batchSize = (pickupBookingSettings?.PUDSendJobToDispatchSystemBatchSize__c != null ? Integer.valueOf(pickupBookingSettings.PUDSendJobToDispatchSystemBatchSize__c) : 200);
        Database.executeBatch(new PUDSendJobToDispatchSystemBatch(), batchSize);
    }

}