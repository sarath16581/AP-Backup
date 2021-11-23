/** 
* @author Andrew Judd ajudd@salesforce.com 
* @date 2020-07-14 
* @description Controller for the Assign Driver to Duty page available from the Assign Driver action in the FSL Gantt
*               Provides the ability to assign a driver to a duty via the TDF_CreateServiceCrewMember class
*
* @changelog 
* 2020-07-14 - Andrew Judd - Created 
*/
public with sharing class TDF_AssignDriverToDutyController {
    
    public Date startDate{get;set;}
    public Date endDate{get;set;}
    
    public Id selectedDutyId{get;set;}
    public Id selectedDutySTMId{get;set;}
    public Id selectedDriverId{get;set;}
    public Id territoryId{get;set;}
    
    public String startGantt{get;set;}
    public String endGantt{get;set;}
    public String srName{get;set;}
    public String selectedSRType{get;set;}
    public String selectListSRType{get;set;}
    
    public String selectedSRForAssignment{get;set;}
    public List<SelectOption> srToAssignSelectList{get;set;}
    public List<SelectOption> srSelectList{get;set;}
    public Time selectedDutyStartTime {get;set;}

    public TDF_AssignDriverToDutyController(){
        
        //Initialization
        //Get selected duty, duty stm, dates from gantt
        selectedDutyId = Apexpages.currentPage().getParameters().get('id');
        selectedDutySTMId = Apexpages.currentPage().getParameters().get('stm');
        startGantt = Apexpages.currentPage().getParameters().get('start');
        endGantt = Apexpages.currentPage().getParameters().get('end');

        ServiceResource srRecord = new ServiceResource();
        srRecord = [SELECT Name, ResourceType, DutyStartTime__c FROM ServiceResource WHERE Id = :selectedDutyId];
        
        //Set default dates (from and to) based on gantt dates
        String[] startGanttSplit = startGantt.split('-');
        startDate = Date.newInstance(Integer.valueOf(startGanttSplit[2]),Integer.valueOf(startGanttSplit[0]),Integer.valueOf(startGanttSplit[1]));

        //String[] endGanttSplit = endGantt.split('-');
        //endDate = Date.newInstance(Integer.valueOf(endGanttSplit[2]),Integer.valueOf(endGanttSplit[0]),Integer.valueOf(endGanttSplit[1]));    
        endDate = startDate;

        //Get Territory from stm
        territoryId = [SELECT ServiceTerritory.TopLevelTerritoryId FROM ServiceTerritoryMember WHERE Id = :selectedDutySTMId].ServiceTerritory.TopLevelTerritoryId;

        //Get duty details
        srName = srRecord.Name;
        selectedSRType = srRecord.ResourceType; //i.e either C (Crew) or T (Driver)
        selectedDutyStartTime = srRecord.DutyStartTime__c;

        //set the select list type to the opposing value
        if(selectedSRType == 'C'){
            selectListSRType = 'T';
        }
        else{
            selectListSRType = 'C';
        }
       
        //Get List of SRs to assign (driver/duty)
        selectedSRForAssignment = '';
        srToAssignSelectList = new List<SelectOption>(); 
        srToAssignSelectList.add(new SelectOption('','--- None ---'));
        srSelectList = new List<SelectOption>(); 
        Map<String, String> srMap = new Map<String, String>(); 
        
        //Get drivers/dutys assigned to territory
        for(ServiceTerritoryMember objSTM : [SELECT ServiceResourceId, ServiceResource.Name 
                            FROM ServiceTerritoryMember 
                            WHERE TerritoryType = 'P' AND ServiceTerritoryId = :territoryId  
                            AND ServiceTerritory.IsActive = true 
                            AND ServiceResource.ResourceType = :selectListSRType 
                            AND ServiceResource.IsActive = true 
                            //TODO:Add date for currently (or gantt date) assigned primary                 
                            ORDER BY ServiceResource.Name ASC LIMIT 1000]){
            srMap.put(objSTM.ServiceResourceId, objSTM.ServiceResource.Name);
        }
        
        //Add users to user select list
        for(String srId : srMap.keySet()){
            srSelectList.add(new SelectOption(srId, srMap.get(srId)));
        }
        
        //As to driver select list        
        srToAssignSelectList.addAll(srSelectList);
        
    }
    
    //Method to assign a select SR (driver/duty) to a duty/driver
    public PageReference assignDriver(){
        
        Roster__c rosterRecord; //record to store values to pass to function and record history of event
        Map<Id, Roster__c> rosterMap; //map to pass to create assignments service
        String dutyIdString;
        String driverIdString;
        Set<String> startTimeDispatchedSet = new Set<String>();
        Set<String> dutiesWithDispatchedSet = new Set<String>();
        //Datetime currentDateTime = System.Now();

        //show error message if Start Date is greater then End Date
        if(endDate < startDate){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'End Date must be equal to or greater than the Start Date'));
            return null;                
        }

        //If selected record from gantt is a duty (Crew)
        if(selectedSRType == 'C'){
            dutyIdString = selectedDutyId;
            driverIdString = selectedSRForAssignment;
        }
        //Else a driver
        else{
            dutyIdString = selectedSRForAssignment;
            driverIdString = selectedDutyId;
            selectedDutyStartTime = [SELECT DutyStartTime__c FROM ServiceResource WHERE Id = :dutyIdString].DutyStartTime__c;
        }

        //Show error message is selected duty does not have a start time
        //if duty has no start time
        if(selectedDutyStartTime == null){
            //Advise and end
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,
                    'The selected duty does not have a start time set. Please go to the duty service resource record and set the field Duty Start Time.'));
            return null;
        }

        //Check if any SAs have been dispatached for selected period
        //If so cancel and display message
        //This is required as it is the Dispatch process that assigns the driver based on the Service Crew Member record
        //Completed jobs are ignored as they are done - a new driver may need to take over a duty 
        List<AssignedResource> sasDispatchedList = [SELECT Id, ServiceAppointment.SchedStartTime 
                                                    FROM AssignedResource 
                                                    WHERE ServiceResourceId = :dutyIdString 
                                                    AND ServiceAppointment.Status IN ('Dispatched', 'In Progress')
                                                    AND (ServiceAppointment.Work_Order__r.Duty_Day__c >= :startDate
                                                    AND ServiceAppointment.Work_Order__r.Duty_Day__c <= :endDate) 
                                                    ORDER BY ServiceAppointment.SchedStartTime ];
        
        //If any Service Appointments found in dispatched or beyond status
        if(sasDispatchedList.size() > 0){
            //Get string of start time of jobs
            for(AssignedResource assRes : sasDispatchedList){
                startTimeDispatchedSet.add(assRes.ServiceAppointment.SchedStartTime.format());
            }
            //Then display message that there are jobs that have been dispatched and assigned
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,
                    'The Duty jobs at '+ startTimeDispatchedSet + ' have already been dispatched to another driver for the selected date range. Check the date range or set all Dispatched and In Progress jobs to Scheduled and then assign the new driver.'));
            return null;
        }

        //Check that the driver is not currently assigned to another duty with dispatched work for the date range
        sasDispatchedList.clear();
        sasDispatchedList = [SELECT Id, ServiceCrew.Name  
                                FROM AssignedResource 
                                WHERE ServiceResourceId = :driverIdString  
                                AND ServiceAppointment.Status IN ('Dispatched', 'In Progress')  
                                AND ServiceAppointment.Work_Order__r.Duty_Day__c >= :startDate 
                                AND ServiceAppointment.Work_Order__r.Duty_Day__c <= :endDate];

        //If any dispatches SAs found assigned to this driver, then display message and end
        if(sasDispatchedList.size() > 0){
            //Get string of duties
            for(AssignedResource assRes : sasDispatchedList){
                dutiesWithDispatchedSet.add(assRes.ServiceCrew.Name);
            }
            //Then display message that there are jobs that have been dispatched and assigned
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,
                    'The selected driver is currently assigned to the following duties '+ dutiesWithDispatchedSet + ' with dispatched work. Please select Undispatach against the duties before assigning this driver.'));
            return null;  
        }


        System.System.debug('dutyIdString = ' + dutyIdString);
        System.System.debug('driverIdString = ' + driverIdString);
        
        //Set up a roster record to pass to create assignments function
        rosterRecord = new Roster__c(
                        Duty__c = dutyIdString,
                        Driver__c = driverIdString,
                        Start_Date__c = startDate,
                        End_Date__c = endDate,
                        Service_Territory__c = territoryId,
                        Roster_Reference__c = 'Gantt Assignment ' + Datetime.now().format('dd/MM/yyyy HH:mm:ss'),
                        Gantt_Assignment__c = true);

        //Insert roster record
        insert rosterRecord;

        //Build map to pass to function
        rosterMap = new Map<Id, Roster__c>([SELECT Id, Duty__c, Driver__c, Start_Date__c, End_Date__c, Service_Territory__c,
                                                        Duty__r.Name, Duty__r.ServiceCrewId, Driver__r.Name, Duty__r.DutyStartTime__c, Start_Time_Offset__c  
                                                        FROM Roster__c 
                                                        WHERE Id = :rosterRecord.Id]);

        //System.Debug('rosterMap = ' + rosterMap);
        System.Debug('selectedSRForAssignment = ' + selectedSRForAssignment);

        //Call service to create Service Crew Member and Service Territory Member assignments
        TDF_CreateServiceCrewMember createSCM = new TDF_CreateServiceCrewMember();
        createSCM.createAssignments(rosterMap);
        
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Driver assigned to duty successfully!'));
    
        return null;
        
    } 

}