/**
* @author Dheeraj Mandavilli
* @date 2020-08-05
* @group PUD Project
* @tag Controller
* @tag PUD_Job__c
* @domain Interoperability PUD Project
* @description Controller class to fectch Job records from PUD_Job__c object.
* NOTE: This class is used by PUD_JobPrintFromBooking VF Page upon clicking "Print Today's Job" from Booking Detail Page. 
* 2020-08-05 - Dheeraj Mandavilli - Created
*/
public with sharing class PUD_BookingPrintControllerX {
    
    public String bookingId{get;set;} 
    public List<PUD_Job__c> jobTemplateList{get;set;}
    public String reportdate{get;set;}
    public String depotName{get;set;} 
    public String routeName{get;set;}
    public String depotType{get;set;}
    public String depotPhone{get;set;}
    private Integer sYear =0;
    private Integer sMonth = 0;
    private Integer sDay = 0;
    private Integer sHour =0;
    private Integer sMins = 0;
    private Integer sSecs = 0;
    private DateTime myDate = null;
    
    // Constructor    
    public PUD_BookingPrintControllerX(ApexPages.standardController sc){
        
        //Get Id
        bookingId = Apexpages.currentPage().getParameters().get('id');
        
        //Initialize Variables
        reportdate = '';
        depotName= '';
        routeName = '';
        depotType = '';
        depotPhone='';
        
        //Print Date on Duty Board with Current date and time in "DD-MM-YYY HH:MM:SS" format
        myDate = datetime.now();
        sYear = myDate.year();
        sMonth = myDate.month();
        sDay = myDate.day();
        sHour = myDate.hour();
        sMins = myDate.minute();
        sSecs = myDate.second();
        reportdate = sDay +'-'+sMonth +'-'+sYear+' '+shour+':'+sMins+':'+sSecs;
        
        
        //Get list of jobs with anything other than permanent record type
        List<PUD_Job__c> result =[SELECT Address__c,Dwell_Time_Planned__c, Start_Time__c, Booking_Record_Type__c,Date__c,Booking_Location__c,Location__c,
                                  Route_Lookup__c,Route_Lookup__r.Name,Id,Depot__c, Depot__r.Name,Name,Job_Information__c,Comments__c,Location_Information__c,
                                  Booking_Type_Fx__c,Booking_Comments__c,Deliver_Product__c,Revenue_Check__c, Stop_Credit__c,Key_Number__c,Booking__c
                                  FROM PUD_Job__c WHERE Date__c = TODAY AND Booking__c= :bookingId ORDER BY Start_Time__c];
        
        //Point the result list to jobtemplateList
        jobTemplateList = result;
        
        for(PUD_Job__c job: jobTemplateList){
            routeName=job.Route_Lookup__r.Name;  
        }
    }
    
}