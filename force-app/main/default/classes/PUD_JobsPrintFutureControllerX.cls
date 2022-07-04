/**
* @author Dheeraj Mandavilli
* @date 2020-03-25
* @group PUD Project
* @tag Controller
* @tag PUD_Job__c
* @domain Interoperability PUD Project
* @description Controller class to fectch job records from PUD_Job__c object.
* NOTE: This class is used by PUD_FutureJobsPrintView VF Page upon clicking "Print Route" from Routes Detail Page. 
* 2020-03-25 - Dheeraj Mandavilli - Created
* 2020-05-25 - Dheeraj Mandavilli - Updated SOQL to accomdate new cosmetic changes on Vf page
* 2020-06-10 - Dheeraj Mandavilli - Included Time of Print Logic.
*/

public with sharing class PUD_JobsPrintFutureControllerX {
    public date datename{get;set;}
    public string dateval{get;set;}
    public List<PUD_Job__c> jobTemplateList{get;set;}
    public String routeRecId{get;set;}
    public String depotName{get;set;}
    public string routeName{get;set;}
    public String printtype { get; private set;}
    public boolean adhoc {get;set;}
    public string sdate {get;set;}
    private Integer sYear =0;
    private Integer sMonth = 0;
    private Integer sDay = 0;
    private Integer sHour =0;
    private Integer sMins = 0;
    private Integer sSecs = 0;
    private DateTime myDate = null;


    // Constructor    
    public PUD_JobsPrintFutureControllerX(ApexPages.standardController sc){

        //Get Id from Url
        routeRecId = Apexpages.currentPage().getParameters().get('id');

        //Get Date String from Url
        dateval =  Apexpages.currentPage().getParameters().get('date');

        //Get Date Value from Date String
        datename = Date.valueOf(dateval);

        //Print Date on Duty Board with Current date and time in "DD-MM-YYY HH:MM:SS" format
        myDate = datetime.now();
        sYear = datename.year();
        sMonth = datename.month();
        sDay = datename.day();
        sHour = myDate.hour();
        sMins = myDate.minute();
        sSecs = myDate.second();
        sdate = sDay +'-'+sMonth +'-'+sYear+' '+shour+':'+sMins+':'+sSecs;

        //Get Type from Url
        printtype = Apexpages.currentPage().getParameters().get('type');

        //Initialize Variables
        depotName= '';
        routeName = '';
        adhoc = false;

        //Determine the type from and call accurate methods
        if(printtype == 'Perm'){
            jobTemplateList=getPermJobRecords(routeRecId,datename);
        }else if(printtype == 'Adhoc'){
            jobTemplateList=getAdhocJobRecords(routeRecId,datename);
            adhoc = true;
        }else{
            jobTemplateList=getAllJobRecords(routeRecId,datename);
        }

        //Populate Fields on Header
        for(PUD_Job__c job: jobTemplateList){
            depotName=job.Depot__r.Name;
            routeName=job.Route_Lookup__r.Name;
        }
    }

    @TestVisible private List<PUD_Job__c> getPermJobRecords(string routeId,date dateVal){

        //Get list of jobs for all record types
        List<PUD_Job__c> list1 = [SELECT Address__c,Street__c,City__c, State__c,Post_Code__c ,Dwell_Time_Planned__c, Display_Start_Time__c, Booking_Record_Type__c,Date__c,Location__c,
                                  Route_Lookup__c,Route_Lookup__r.Name,Id,Depot__c, Depot__r.Name,Depot__r.Email__c,Depot__r.Phone_Number__c,Name,Job_Information__c,Comments__c,Start_Time__c,
                                  Booking_Type_Fx__c,Booking_Comments__c,Deliver_Product__c,Revenue_Check__c, Stop_Credit__c,Key_Number__c,Location_Information__c,Booking_Location__c
                                  FROM PUD_Job__c WHERE Date__c = :dateVal AND Route_Lookup__c= :routeId
                                  ORDER BY Route_Lookup__c,Start_Time__c];

        //Create temp list2
        List<PUD_Job__c> list2=new List<PUD_Job__c>();
        //Create a result list
        List<PUD_Job__c> result=new List<PUD_Job__c>();

        //Filter the job records with permanent record type with neither stop credit and revenue check turned off
        for(PUD_Job__c jobrec:list1){
            if(jobrec.Booking_Record_Type__c == 'Adhoc Pickup/Delivery' || jobrec.Booking_Record_Type__c == 'Dependent Delivery' || jobrec.Booking_Record_Type__c == 'MPB Pickup' ){
                list2.add(jobrec);
            }else{
                result.add(jobrec);
            }
        }
        return result;
    }

    @TestVisible private List<PUD_Job__c> getAdhocJobRecords(string routeId,date dateVal){

        //Get list of jobs with anything other than permanent record type
        List<PUD_Job__c> list1 = [SELECT Address__c,Street__c,City__c, State__c,Post_Code__c ,Dwell_Time_Planned__c, Start_Time__c,Display_Start_Time__c,Location__c,Booking_Record_Type__c,
                                  Route_Lookup__c,Route_Lookup__r.Name,Id,Depot__c, Depot__r.Name,Depot__r.Email__c,Depot__r.Phone_Number__c,Name,Job_Information__c,Comments__c,Date__c,Booking_Location__c,
                                  Booking_Type_Fx__c,Booking_Comments__c,Deliver_Product__c,Revenue_Check__c, Stop_Credit__c,Key_Number__c,Location_Information__c
                                  FROM PUD_Job__c WHERE Date__c = :dateVal AND Route_Lookup__c = :routeId AND Booking_Record_Type__c != 'Other'
                                  ORDER BY Route_Lookup__c,Start_Time__c];

        //Create temp list2
        List<PUD_Job__c> list2=new List<PUD_Job__c>();
        //Create a result list
        List<PUD_Job__c> result=new List<PUD_Job__c>();

        //Filter the job records with permanent record type with neither stop credit nor revenue check turned off
        for(PUD_Job__c jobrec:list1){
            if(jobrec.Booking_Record_Type__c == 'Permanent Pickup/Delivery' && jobrec.Stop_Credit__c == false && jobrec.Revenue_Check__c == false){
                list2.add(jobrec);
            }else{
                result.add(jobrec);
            }
        }
        return result;
    }

    @TestVisible private List<PUD_Job__c> getAllJobRecords(string routeId,date dateVal){

        //Get list of jobs for all record types
        List<PUD_Job__c> result = [SELECT Address__c,Street__c,City__c, State__c,Post_Code__c,Dwell_Time_Planned__c, Display_Start_Time__c, Booking_Record_Type__c,Date__c,Location__c,
                                   Route_Lookup__c,Route_Lookup__r.Name,Id,Depot__c, Depot__r.Name,Depot__r.Email__c,Depot__r.Phone_Number__c,Name,Job_Information__c,Comments__c,Start_Time__c,
                                   Booking_Type_Fx__c,Booking_Comments__c,Deliver_Product__c,Revenue_Check__c, Stop_Credit__c,Key_Number__c,Location_Information__c,Booking_Location__c
                                   FROM PUD_Job__c WHERE Date__c = :dateVal AND Route_Lookup__c= :routeId
                                   ORDER BY Route_Lookup__c,Start_Time__c];
        return result;
    }
}