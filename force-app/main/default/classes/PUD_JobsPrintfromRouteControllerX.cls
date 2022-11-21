public class PUD_JobsPrintfromRouteControllerX {
//Controller for page PUD_BookingPrint
//Created 25-11-19 Dheeraj Mandavilli
    public String routeId{get;set;} 
    public List<PUD_Job__c> jobTemplateList{get;set;}
    public date reportdate{get;set;}
    public String depotName{get;set;} 
    public string routeName{get;set;}

	// Constructor    
    public PUD_JobsPrintfromRouteControllerX(ApexPages.standardController sc){
        
        //Get Id
        routeId = Apexpages.currentPage().getParameters().get('id');
        system.debug('routeId:::'+routeId);
           
        
        //Get list of jobs
       	String query = 'SELECT Address__c,Dwell_Time_Planned__c, Display_Start_Time__c, Booking_Record_Type__c,Date__c,Booking_Location__c,Location__c, '+
            			'Route_Lookup__c,Route_Lookup__r.Name,Id,Depot__c, Depot__r.Name,Name,Job_Information__c,Comments__c,Start_Time__c, '+
                		'Booking_Type_Fx__c,Booking_Comments__c,Deliver_Product__c,Revenue_Check__c, Stop_Credit__c,Key_Number__c '+
            			'FROM PUD_Job__c WHERE Date__c = TODAY AND Route_Lookup__c= \'' + routeId + '\'' +
            			'ORDER BY Route_Lookup__c,Start_Time__c';
        reportdate = null ;
        depotName= '';
        routeName = '';
        
        
        
        jobTemplateList = Database.query(query);
        system.debug('jobTemplateList::::'+jobTemplateList);
        
        for(PUD_Job__c job: jobTemplateList){
             reportdate =  Date.valueOf(job.Date__c);
             depotName=job.Depot__r.Name;
             routeName=job.Route_Lookup__r.Name;
            	
        }

    }
}