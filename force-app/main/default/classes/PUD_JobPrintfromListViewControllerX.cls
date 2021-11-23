/**
* @author Dheeraj Mandavilli
* @date 2019-11-28
* @group PUD Project
* @tag Controller
* @tag PUD_Job__c
* @domain Interoperability PUD Project
* @description Controller class to fectch job records from PUD_Job__c object.
* NOTE: This class is used by PUD_JobPrint VF Page upon clicking "Print All Jobs" from Routes List View Page. 
* 2019-11-28 - Dheeraj Mandavilli - Created
* 2020-05-25 - Dheeraj Mandavilli - Refactored the Logic to Fetch Depot Id from Logged in User
* 2020-06-10 - Dheeraj Mandavilli - Included Time of Print Logic.
*/
public with sharing class PUD_JobPrintfromListViewControllerX {
    public String depotId{get;set;} 
    public List<PUD_Job__c> jobTemplateList{get;set;}
    public Map<String,List<PUD_Job__c>> routeJobMap {get;set;}
    public Set<String> routeKeys{get;set;}
    public String reportdate{get;set;}
    public String depotName{get;set;}
    public List<String> selectedRouteIDs{get;set;}
    private Integer sYear =0;
    private Integer sMonth = 0;
    private Integer sDay = 0;
    private Integer sHour =0;
    private Integer sMins = 0;
    private Integer sSecs = 0;
    private DateTime myDate = null;
    
    // Constructor    
    public PUD_JobPrintfromListViewControllerX(ApexPages.StandardSetController sc){
        
        //Identify the selected records from Listview
        selectedRouteIDs = new List<String>{};
            for(PUD_Route__c rts : (PUD_Route__c[])sc.getSelected()){
                selectedRouteIDs.add(rts.Id);
            }
        
        //Get default Network Depot for current user from Public group in which he is member Start
        String currentUserId = UserInfo.getUserId();
        List<GroupMember> groupMemberList = new List<GroupMember>();
        Id depotId = null;
        
        //Refactored the code to eliminated extra query
        //get public group Names for current user
        groupMemberList = [SELECT  Group.Name FROM GroupMember WHERE UserOrGroupId=:currentUserId];
        system.debug('groupMemberList:::'+groupMemberList);
        Set<String> groupNameSet = new Set<String>();
        
        //loop trough the Public groups members for Public group Ids
        for(GroupMember objCGM : groupMemberList){
            groupNameSet.add(objCGM.Group.Name);
            system.debug('groupNameSet:::'+groupNameSet);
        }
        
        if(groupNameSet.size() > 0){
            //get network/depot details from Network Object
            List<Network__c> networkList =[SELECT Id,Name FROM Network__c WHERE Name IN : groupNameSet];
            system.debug('networkList:::'+networkList);
            //get first Depot name and assign it to Booking by storing in a variable
            if(networkList.size()>0){                        
                depotId = networkList[0].Id;
                system.debug('depotId:::'+depotId);
            } 
        }
        
        //Initialize Variables        
        reportdate = null ;
        depotName= '';
        
        //Print Date on Duty Board with Current date and time in "DD-MM-YYY HH:MM:SS" format
        myDate = datetime.now();
        sYear = myDate.year();
        sMonth = myDate.month();
        sDay = myDate.day();
        sHour = myDate.hour();
        sMins = myDate.minute();
        sSecs = myDate.second();
        reportdate = sDay +'-'+sMonth +'-'+sYear+' '+shour+':'+sMins+':'+sSecs;
        
        try{ 
            //Get list of jobs for all routes of all record types
            List<PUD_Job__c> jobTemplateList = [SELECT Address__c,Dwell_Time_Planned__c, Display_Start_Time__c, Booking_Record_Type__c,Date__c,Booking_Location__c,Location__c,
                                                Route_Lookup__c,Route_Lookup__r.Name,Route_Lookup__r.Id,Id,Depot__c, Depot__r.Name,Name,Job_Information__c,Comments__c,Key_Number__c,Start_Time__c,
                                                Booking_Type_Fx__c,Booking_Comments__c,Deliver_Product__c,Revenue_Check__c, Stop_Credit__c,Location_Information__c
                                                FROM PUD_Job__c WHERE Date__c = TODAY AND Depot__c= :depotId
                                                AND Route_Lookup__r.Id IN :selectedRouteIDs ORDER BY Route_Lookup__c,Start_Time__c];
            
            for(PUD_Job__c job: jobTemplateList){      
                depotName=job.Depot__r.Name;
            }
            
            routeJobMap = new Map<String, List<PUD_Job__c>>();
            
            routeJobMap = createMap(jobTemplateList,routeJobMap);
            
        }
        catch(Exception Ex){
            system.debug('Error Logged::::'+Ex);
        }
    }
    
    @TestVisible private static Map<String,List<PUD_Job__c>> createMap(List<PUD_Job__c> jobTemplateList, Map<String,List<PUD_Job__c>> routeJobMap){
        
        for(PUD_Job__c job: jobTemplateList){
            List<PUD_Job__c> routeJobs = new List<PUD_Job__c>();
            
            if(routeJobMap.get(job.Route_Lookup__r.Name) == null){
                routeJobMap.put(job.Route_Lookup__r.Name,new List<PUD_Job__c>());
            }
            routeJobs= routeJobMap.get(job.Route_Lookup__r.Name);
            routeJobs.add(job);
            
        }
        return routeJobMap;
    }
}