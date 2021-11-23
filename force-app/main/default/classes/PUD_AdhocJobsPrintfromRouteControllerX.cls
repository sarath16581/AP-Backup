/**
* @author Dheeraj Mandavilli
* @date 2019-11-19
* @group PUD Project
* @tag Controller
* @tag PUD_Job__c
* @domain Interoperability PUD Project
* @description Controller class to fectch job records from PUD_Job__c object.
* NOTE: This class is used by PUD_AdhocJobsPrint VF Page upon clicking "Print Adhoc and Perm with variations" from Routes Detail Page. 
* 2019-11-19 - Dheeraj Mandavilli - Created
* 2020-05-25 - Dheeraj Mandavilli - Updated SOQL to accomdate new cosmetic changes on Vf page
* 2020-06-10 - Dheeraj Mandavilli - Included Time of Print Logic.
*/
public with sharing class PUD_AdhocJobsPrintfromRouteControllerX {
    public String routeId{get;set;} 
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
    public PUD_AdhocJobsPrintfromRouteControllerX(ApexPages.standardController sc){
        
        //Get Id
        routeId = Apexpages.currentPage().getParameters().get('id');
        
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
        List<PUD_Job__c> list1 =[SELECT Address__c,Dwell_Time_Planned__c, Start_Time__c, Booking_Record_Type__c,Date__c,Booking_Location__c,Location__c,
                                 Route_Lookup__c,Route_Lookup__r.Name,Id,Depot__c, Depot__r.Name,Name,Job_Information__c,Comments__c,Location_Information__c,
                                 Booking_Type_Fx__c,Booking_Comments__c,Deliver_Product__c,Revenue_Check__c, Stop_Credit__c,Key_Number__c
                                 FROM PUD_Job__c WHERE Date__c = TODAY AND Route_Lookup__c= :routeId AND Booking_Record_Type__c !='Other'
                                 ORDER BY Route_Lookup__c,Start_Time__c];
        
        //Create temp list2
        List<PUD_Job__c> list2=new List<PUD_Job__c>();
        //Create a result list
        List<PUD_Job__c> result=new List<PUD_Job__c>();   
        
        
        //Filter the job records with permanent record type with neither stop credit and revenu check turned off
        for(PUD_Job__c jobrec:list1){
            if(jobrec.Booking_Record_Type__c == 'Permanent Pickup/Delivery' && jobrec.Stop_Credit__c == false && jobrec.Revenue_Check__c == false){
                list2.add(jobrec);
            }else{
                result.add(jobrec);
            }
        } 
        
        //Point the result list to jobtemplateList
        jobTemplateList = result;
        
        for(PUD_Job__c job: jobTemplateList){
            depotName=job.Depot__r.Name;
            routeName=job.Route_Lookup__r.Name;  
        }
    }
}