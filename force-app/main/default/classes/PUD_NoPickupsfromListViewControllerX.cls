/**
* @author Dheeraj Mandavilli
* @date 2020-05-25
* @group PUD Project
* @tag Controller
* @tag PUD_Booking_Exception__c
* @domain Interoperability PUD Project
* @description Controller class to fectch job exceptions/No Pickups records from PUD_Booking_Exception__c object.
* NOTE: This class is used by PUD_JobExcpPrintfromListView VF Page upon clicking "Print All No-Pickup" from Routes List View. 
* 2020-05-25 - Dheeraj Mandavilli - Created
* 2020-06-09 - Dheeraj Mandavilli - Updated SOQL from Dyanmic to Static,fixed class name,comments and identation.
* 2020-07-20 - Dheeraj Mandavilli - Added a filter condition which checks the day of week is active and excludes records from being printed on Duty Board.
*/
public with sharing class PUD_NoPickupsfromListViewControllerX {
    public String depotId{get;set;} 
    public List<PUD_Booking_Exception__c> jobTemplateList{get;set;}
    public Map<String,List<PUD_Booking_Exception__c>> routeJobMap {get;set;}
    public Set<String> routeKeys{get;set;}
    public String reportdate{get;set;}
    public String reporttime{get;set;}
    public String depotName{get;set;}
    public List<String> selectedRouteIDs{get;set;}
    private Integer sYear =0;
    private Integer sMonth = 0;
    private Integer sDay = 0;
    private Integer sHour =0;
    private Integer sMins = 0;
    private Integer sSecs = 0;
    private DateTime mydate;
    private String dayOfWeek;
    
    
    // Constructor    
    public PUD_NoPickupsfromListViewControllerX(ApexPages.StandardSetController sc){
        
        //Identify the selected records from Listview
        selectedRouteIDs = new List<String>{};
            for(PUD_Route__c rts : (PUD_Route__c[])sc.getSelected()){
                selectedRouteIDs.add(rts.Id);
            }        
        /*Get default Network Depot for current user from Public group in which he is member Start */
        String currentUserId = UserInfo.getUserId();
        List<GroupMember> groupMemberList = new List<GroupMember>();
        Id depotId = null;
        
        //Refactored the code to eliminated extra query
        //get public group Names for current user
        groupMemberList = [SELECT  Group.Name FROM GroupMember WHERE UserOrGroupId=:currentUserId];
        Set<String> groupNameSet = new Set<String>();
        
        //loop trough the Public groups members for Public group Ids
        for(GroupMember objCGM : groupMemberList){
            groupNameSet.add(objCGM.Group.Name);
        }
        
        if(groupNameSet.size() > 0){
            //get network/depot details from Network Object
            List<Network__c> networkList =[SELECT Id,Name FROM Network__c WHERE Name IN : groupNameSet];
            //get first Depot name and assign it to Booking by storing in a variable
            if(networkList.size()>0){                        
                depotId = networkList[0].Id;
            } 
        }
        
        //Print Date on Duty Board with Current date in "DD-MM-YYY HH:MM:SS" format
        mydate = null;
        myDate = datetime.now();
        dayOfWeek=myDate.format('EEEE');
        sYear = myDate.year();
        sMonth = myDate.month();
        sDay = myDate.day();
        sHour = mydate.hour();
        sMins = mydate.minute();
        sSecs = mydate.second();
        
        try{ 
            
            List<PUD_Booking_Exception__c> jobTemplateList = [SELECT Id,Name,Start_Date__c, End_Date__c,Booking__r.Location__c,Booking__r.Booking_Location_Address__c ,Booking__r.Booking_Type__c,
                                                              Booking__r.City__c,Booking__r.Booking_Comments__c,Booking__r.Depot__c,Booking__r.Depot__r.Name,Booking__r.Route_Lookup__r.Name,
                                                              Booking__r.Route_Lookup__c,Monday__c,Tuesday__c,Wednesday__c,Thursday__c,Friday__c,Saturday__c,Sunday__c
                                                              FROM PUD_Booking_Exception__c WHERE Booking__r.Depot__c= :depotId AND Start_Date__c < = TODAY AND End_Date__c > = TODAY
                                                              AND Booking__r.Route_Lookup__r.Id IN :selectedRouteIDs ORDER BY Booking__r.Route_Lookup__c];
            
            reportdate = null ;
            reporttime = null;
            depotName= '';
            reportdate = sDay +'-'+sMonth +'-'+sYear+' '+shour+':'+sMins+':'+sSecs; 
            
            List<PUD_Booking_Exception__c> recFilterList = new List<PUD_Booking_Exception__c>();
            
            /*This condition checks if the Checkbox is active for specific day of week and filters the records from appearing
			on duty board.*/
            for(PUD_Booking_Exception__c jobExp: jobTemplateList){   
                if((dayOfWeek == 'Monday' && jobExp.Monday__c == true)||
                   (dayOfWeek == 'Tuesday' && jobExp.Tuesday__c == true)||
                   (dayOfWeek == 'Wednesday' && jobExp.Wednesday__c == true)||
                   (dayOfWeek == 'Thursday' && jobExp.Thursday__c == true)||
                   (dayOfWeek == 'Friday' && jobExp.Friday__c == true)||
                   (dayOfWeek == 'Saturday' && jobExp.Saturday__c == true)||
                   (dayOfWeek == 'Sunday' && jobExp.Sunday__c == true))
                {
                    recFilterList.add(jobExp);
                }
                depotName=jobExp.Booking__r.Depot__r.Name;
            }
            
            routeJobMap = new Map<String, List<PUD_Booking_Exception__c>>();
            
            routeJobMap = createMap(recFilterList,routeJobMap);
            
        }
        catch(Exception Ex){
            system.debug('Error Logged::::'+Ex);
        }
    }
    
    /**
* Returns a Map with Route Number and Jobs associated to it the VF Page.
* <p>
* @param  List of Booking Exception records 
* @param  Route Job Map
* @return   Map with Route and Jobs
*/
    @TestVisible private static Map<String,List<PUD_Booking_Exception__c>> createMap(List<PUD_Booking_Exception__c> jobTemplateList, Map<String,List<PUD_Booking_Exception__c>> routeJobMap){
        
        for(PUD_Booking_Exception__c job: jobTemplateList){
            List<PUD_Booking_Exception__c> routeJobs = new List<PUD_Booking_Exception__c>();
            
            if(routeJobMap.get(job.Booking__r.Route_Lookup__r.Name) == null){
                routeJobMap.put(job.Booking__r.Route_Lookup__r.Name,new List<PUD_Booking_Exception__c>());
            }
            routeJobs= routeJobMap.get(job.Booking__r.Route_Lookup__r.Name);
            routeJobs.add(job);
            
        }
        return routeJobMap;
    }
    
}