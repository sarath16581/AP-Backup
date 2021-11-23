/** 
* @author Andrew Judd ajudd@salesforce.com 
* @date 2020-07-27
* @domain Field Service 
* @description Service to validate and dispatch work orders
*               Called from:
*               - TDF_DispatchWorkAction, from by Dispatch and Undispatch Action in FSL Gantt on Service Resource
*               - TDF_DispatchWorkScheduler 
*               - TDF_UndispatchWorkActionGantt in FSL Gantt on selected service appointments 
*
* @changelog 
* 2020-07-14 - Andrew Judd  - Created 
* 2020-09-02 - Andrew Judd  - Changed retrieve of SR record in dispatch work to prevent error when not duty
*                           - Added validation of connected jobs
* 2020-09-04 - Andrew Judd  - Changed retrieve of SR record in undispatch work to prevent error when not duty
* 2020-09-16 - Andrew Judd  - Removed set of gantt label on Dispatch and unset on Undispatch (now only done on FFD completion)
*                           - Added Pin on Dispatch and Unpin and Undispatch
*                           - Added new function undispatchGantt for new action
* 2020-09-16 - Andrew Judd  - Added related duty name to the validation message and added new line between records in message
* 2020-09-17 - Andrew Judd  - Change duty undispatch to only undispatch jobs in status Dispatched
* 2020-09-22 - Andrew Judd  - Added sort of WOLIs for connected job validation
* 2020-10-08 - Andrew Judd  - Add check to see if duty start time is set before adjusting the duty assignment.
* 2020-10-18 - Andrew Judd  - Post deployment fix - Changed logic to adjust the Service Crew Member record directly, instead of calling
*                               TDF_CreateServiceCrewMember.create assignment with the offset value.  This approach is simpler and more accurate
*                               reducing the likelyhood for jobs to be dispatched without a driver assignment
*/
public with sharing class TDF_DispatchWork {
    
    //Public function to call dispatch from Action
    public static String dispatch(Id srId){
        
        //Initialize
        Datetime currentDateTime  = System.Now();
        
        //Times assume dispatch triggered within no more that 12 hrs after the start of the first job
        //and no more the 20 hrs before the start of the last job
        //note that there is logic below to halt dispatch if a second FFD is encountered more that 12 hrs in the future
        Datetime fromSADateTime  = currentDateTime.addHours(-12);  
        Datetime toSADateTime = currentDateTime.addHours(20);
    
        Datetime ffdDateTime;
        Datetime scmStartDateTime;

        String dispFromString;
        String dispToString;
        Long minutesToFFD;
        Integer dispatchedInt = 0;
        List<ServiceAppointment> saList;
        List<ServiceAppointment> saUpdateList = new List<ServiceAppointment>();
        List<ServiceCrewMember> scmList;
        List<ServiceCrewMember> scmClashList;
        ServiceAppointment saUpdateRec;

        //Id territoryId;
        String driverIdString;
        String driverNameString;
        Id scmId;
        //Date dutyDay;
        Date endDate;
        Integer minutesBtwnFFDAndSCMInt;
        Integer minutesBtwnFFDAndDutyStart; 
        Roster__c rosterRecord;
        Map<Id, Roster__c> rosterMap;
        ServiceResource srObj;
        Set<Id> woIdSet = new Set<Id>();
        List<WorkOrderLineItem> woliList;
        Set<String> saDifDutyColSet = new Set<String>();
        Set<String> saDifDutyDelSet = new Set<String>();
        Set<String> saDelBeforeColSet = new Set<String>();
        String conIssueMessageString = '';

        Datetime earliestSchedStartDateTime;
        Datetime latestSchedEndDateTime;

        //Get Crew SR Details
        ServiceResource[] srList = [SELECT Name, ServiceCrewId, DutyStartTime__c, FSL__GanttLabel__c  
                                    FROM ServiceResource 
                                    WHERE Id =: srId 
                                    AND ResourceType = 'C' LIMIT 1];
        
        //If crew found, assign to object
        if(srList.size() > 0){
            srObj = srList[0];
        }

        //#Retrieve and process Service Appointments 
        //If a crew SR found
        if(srObj != null){
        
            //Get Service Appointments to update status to 'Dispatched'
            //Get all records, regardless of status, within window 12 hrs from now (note that all in the past should have been dispatched), and forward 20 hrs
            saList = [  SELECT Id, SchedStartTime, SchedEndTime, Status, Work_Order__c, Work_Order__r.Duty_Day__c, ServiceTerritoryId, Work_Order__r.RecordType.DeveloperName  
                        FROM ServiceAppointment 
                        WHERE Id IN (SELECT ServiceAppointmentId FROM AssignedResource
                        WHERE ServiceResourceId = : srId  
                        AND ServiceAppointment.SchedStartTime > :fromSADateTime 
                        AND ServiceAppointment.SchedStartTime < :toSADateTime) 
                        ORDER BY SchedStartTime ASC];
            
            //If some SAs returned
            if(saList.size() > 0){            
                //Process all 
                for(ServiceAppointment sa : saList){
                    
                    //If FDD encountered  
                    if(sa.Work_Order__r.RecordType.DeveloperName == 'Fit_For_Duty'){
                        
                        //Calculate the number of minutes from now to the FFD start time 
                        minutesToFFD = (sa.SchedStartTime.getTime() - currentDateTime.getTime())/60000;
                        //18.10.2020 TDF Enhance fix - comment out as not required
                        //territoryId = sa.ServiceTerritoryId;

                        //If the FFD is more than 12 hrs (720 min) in to future, then end as we have probably hit the next day duty so end
                        if(minutesToFFD > 720){
                            break;
                        }
                        else{
                            //Record the FFD time 
                            ffdDateTime = sa.SchedStartTime;
                            //Store duty date for roster call (if assignment needs to be updated)
                            //18.10.2020 TDF Enhance Post Deploy fix - comment out as not required
                            //dutyDay = sa.Work_Order__r.Duty_Day__c; 
                        }
                    }
                    //If status is scheduled
                    if(sa.Status == 'Scheduled'){
                        //Update the status to dispatched
                        //sa.Status = 'Dispatched';

                        //18.10.2020 TDF Enhance fix
                        //Record the schedule window
                        //If the recorded earliest scheduled start is after this record's start
                        if(earliestSchedStartDateTime > sa.SchedStartTime || earliestSchedStartDateTime == null){
                            //Then record this earlier start date time
                            earliestSchedStartDateTime = sa.SchedStartTime;
                        }
                        //If the recorded lastest scheduled end is before this record's start
                        if(latestSchedEndDateTime < sa.SchedEndTime || latestSchedEndDateTime == null){
                            //Then record this later end date time
                            latestSchedEndDateTime = sa.SchedEndTime;
                        }
                        
                        //Create record to add - note that ROW LOCK error seems to occur when setting Service Appointment against an SA
                        saUpdateRec = new ServiceAppointment(   Id = sa.Id, 
                                                                Status = 'Dispatched',
                                                                FSL__Pinned__c = true);
                        
                        //Add record to List to update                         
                        saUpdateList.add(saUpdateRec);

                        //Store start, end times, and count for message
                        if(dispatchedInt == 0) dispFromString = sa.SchedStartTime.format();
                        dispToString = sa.SchedStartTime.format();
                        dispatchedInt ++;

                        //Store the WO Id
                        woIdSet.add(sa.Work_Order__c);

                    }
                }
            }
            //Else none found
            else{
                //Return no SAs message
                return 'No Service Appointments found for Duty ' + srObj.Name + ' in window ' + fromSADateTime.format() + ' to ' + toSADateTime.format();
            }
            // if(ffdDateTime == null) ffdDateTime = saList.get(0).SchedStartTime;
            //#Validation of FFD
            //If no FFD in the schedule to dispatch
            if(ffdDateTime == null){
                //Return no assigned driver message
                return 'No Fit For Duty found for Duty ' + srObj.Name + '.  Please schedule an initial Fit For Duty and dispatch work. ';
            }

            //#Validation of connected jobs
            //Here we need to check that for all WOLIs connected to the WOs in the schedule: 
            //-1. None are connected to jobs assigned to another duty, and
            //-2. No deliver activity occurs before its related collect. 
            //If any work orders to process
            if(woIdSet.size()>0){

                //Get all WOLIs for work orders to be dispatched
                woliList = [SELECT  Id, Collect_From_Work_Order__c, Collect_From_Work_Order__r.Primary_SA__r.SchedStartTime, 
                                    Collect_From_Work_Order__r.Primary_SA__r.Primary_SR__c, Collect_From_Work_Order__r.Location.Name,
                                    Collect_From_Work_Order__r.Primary_SA__r.Primary_SR__r.Name, Skip_Validation__c,
                                    Deliver_To_Work_Order__c, Deliver_To_Work_Order__r.Primary_SA__r.SchedStartTime, 
                                    Deliver_To_Work_Order__r.Primary_SA__r.Primary_SR__c, Deliver_To_Work_Order__r.Location.Name, 
                                    Deliver_To_Work_Order__r.Primary_SA__r.Primary_SR__r.Name 
                            FROM WorkOrderLineItem 
                            WHERE Collect_From_Work_Order__c IN :woIdSet 
                            OR Deliver_To_Work_Order__c IN :woIdSet 
                            ORDER BY Collect_From_Work_Order__r.Primary_SA__r.SchedStartTime, Deliver_To_Work_Order__r.Primary_SA__r.SchedStartTime];

                //For all WOLIs returned
                for(WorkOrderLineItem woli : woliList){
                    if(woli.Skip_Validation__c) continue;
                    //If the woli has both collect and deliver populated (i.e. is connected), then perform checks
                    if(woli.Collect_From_Work_Order__c != null && woli.Deliver_To_Work_Order__c != null){
                        //If collect SR not same as selected duty
                        if(woli.Collect_From_Work_Order__r.Primary_SA__r.Primary_SR__c != srId){
                            //Add to set of deliveries with connected collect with issue 
                            saDifDutyDelSet.add(    woli.Deliver_To_Work_Order__r.Primary_SA__r.SchedStartTime.format() 
                                                    + ':'+ woli.Collect_From_Work_Order__r.Location.Name  
                                                    + ' (' + woli.Collect_From_Work_Order__r.Primary_SA__r.Primary_SR__r.Name + ')');
                        }
                        //If deliver SR not same as selected duty
                        if(woli.Deliver_To_Work_Order__r.Primary_SA__r.Primary_SR__c != srId){
                            //Add to set of collects with connected deliver with issue
                            saDifDutyColSet.add(    woli.Collect_From_Work_Order__r.Primary_SA__r.SchedStartTime.format() 
                                                    + ':' + woli.Deliver_To_Work_Order__r.Location.Name 
                                                    + ' (' + woli.Deliver_To_Work_Order__r.Primary_SA__r.Primary_SR__r.Name + ')');
                        }
                        //If the deliver occurs before the collect
                        if(woli.Deliver_To_Work_Order__r.Primary_SA__r.SchedStartTime < woli.Collect_From_Work_Order__r.Primary_SA__r.SchedStartTime){
                            //And the job's deliver and collect are both on this duty (i.e. exclude cross duty jobs here - as that needs to be addressed first)
                            if(woli.Collect_From_Work_Order__r.Primary_SA__r.Primary_SR__c == srId && woli.Deliver_To_Work_Order__r.Primary_SA__r.Primary_SR__c == srId){
                                //Add to set incorrectly ordered collect/deliver
                                saDelBeforeColSet.add(woli.Deliver_To_Work_Order__r.Primary_SA__r.SchedStartTime.format() + ':' + woli.Deliver_To_Work_Order__r.Location.Name);
                            }
                        }
                    }
                }
            }
            //18.10.2020 TDF Enhance fix
            else{
                //Return no work orders to dispatch message if none found
                return 'No work found to dispatch.';
            }

            //If any issues detected, display message
            if(saDifDutyDelSet.size()>0 || saDifDutyColSet.size()>0 || saDelBeforeColSet.size()>0){
                if(saDifDutyDelSet.size()>0){
                    //Build the deliver issue message string to display
                    conIssueMessageString = conIssueMessageString + 'These delivers are related to a collect on a different duty: <br/>';
                    for(String jobString : saDifDutyDelSet){
                        conIssueMessageString = conIssueMessageString + jobString + '<br/> ';
                    }
                }
                if(saDifDutyColSet.size()>0){
                    //Build the collect issue message string to display
                    conIssueMessageString = conIssueMessageString + 'These collects are related to a deliver on a different duty: <br/>';
                    for(String jobString : saDifDutyColSet){
                        conIssueMessageString = conIssueMessageString + jobString + '<br/> ';
                    }
                }
                if(saDelBeforeColSet.size()>0){
                    //Build the collect deliver order issue message string to display
                    conIssueMessageString = conIssueMessageString + 'These delivers occur before their related collect: <br/>';
                    for(String jobString : saDelBeforeColSet){
                        conIssueMessageString = conIssueMessageString + jobString + '<br/> ';
                    }
                }
                return conIssueMessageString;
            }

            //#Validation duty resourced
            //Confirm duty is resourced (i.e has a service crew member assigned)
            //Query for service crew member based on the FFD time
            //Adjust by 4 hours to cater for possible change to earler start of duty from original scheduled time
            //Note that the SCM is created with a start time of 1 hr prior to duty start time
            scmList = [ SELECT Id, ServiceResourceId, StartDate, ServiceResource.Name, EndDate   
                        FROM ServiceCrewMember 
                        WHERE ServiceCrewId = :srObj.ServiceCrewId 
                        AND StartDate < :ffdDateTime.addHours(4) 
                        AND EndDate > :ffdDateTime.addHours(4)];

            //If duty not resourced (i.e. no service crew member)
            if(scmList.size() == 0){
                //Return no assigned driver message
                return 'Duty ' + srObj.Name + ' does not have a driver assigned.  Please assign a driver then dispatch work.';
            }
            //Else duty is resourced
            else{
                //If more than one assignment
                if(scmList.size() > 1){
                    //Return more than one driver assigned
                    return 'Duty ' + srObj.Name + ' has more than one driver assigned.  Please reassign a driver then dispatch work.';
                }
                //Else only one assignment
                else{
                    //Get scm details to determine if it is aligned with the work schedule
                    scmId = scmList[0].Id;
                    driverIdString = scmList[0].ServiceResourceId;
                    scmStartDateTime = scmList[0].StartDate;
                    driverNameString = scmList[0].ServiceResource.Name;  

                    //Get minutes between FFD start and SCM start
                    minutesBtwnFFDAndSCMInt = Integer.valueOf((ffdDateTime.getTime() - scmStartDateTime.getTime())/60000);

                    //18.10.2020 TDF Enhance fix
                    //If the SCM does not cover the schedule window
                    if(scmList[0].StartDate > earliestSchedStartDateTime || scmList[0].EndDate < latestSchedEndDateTime){
                        //If it starts after
                        if(scmList[0].StartDate > earliestSchedStartDateTime){
                            //Then adjust start time
                            scmList[0].StartDate = earliestSchedStartDateTime;
                        }
                        //If it ends before
                        if(scmList[0].EndDate < latestSchedEndDateTime){
                            //Then adjust end time
                            scmList[0].EndDate = latestSchedEndDateTime;
                        }
                        
                        //Check for any clashing Service Crew Member records for this driver, excluding the actual assignment
                        //The base package validation does not allow a service resource to have overlapping assignments
                        scmClashList = [SELECT Id FROM ServiceCrewMember 
                                        WHERE ServiceResourceId = :driverIdString 
                                        AND Id != :scmId 
                                        AND ((StartDate < :latestSchedEndDateTime AND StartDate > :earliestSchedStartDateTime) 
                                        OR  (EndDate > :earliestSchedStartDateTime AND EndDate < :latestSchedEndDateTime))];

                        //If clashing records found
                        if(scmClashList.size() > 0){
                            //Then delete these 
                            delete scmClashList;
                        }

                        //Then update the Service Crew Member record to cover the scheduled period
                        update scmList;
                    }

                }

                //18.10.2020 TDF Enhance fix - Comment out this entire section as now replaced with adjustment of existing Service Crew Member as per logic above
                /*
                //If FFD is before the Assignment start time or more than 65 mins after the Assignment start time
                if(minutesBtwnFFDAndSCMInt < 0 || minutesBtwnFFDAndSCMInt > 65){
                    
                    //Then reassign driver to duty with the required offset
                    //This adjusts SCM and Secondary Territory (if applicable) start and end times to align with actual schedule
                    //to ensure driver is assigned to all jobs
                    //1. get offset minutes between ffd and duty start time (on the SR record)
                    //-Get timezone from Service Territory
                    String dutyTimeZoneString = [SELECT OperatingHours.TimeZone FROM ServiceTerritory WHERE Id = :territoryId].OperatingHours.TimeZone;

                    //-Get the number of minutes between the user's timezone and the Service Territory Timezone - to adjust the duty start time below
                    Integer offsetMins = Integer.valueOf(TDF_WorkOrderUtility.getOffsetHours(dutyTimeZoneString) * 60);
                    
                    //Check start time is set against the duty
                    if(srObj.DutyStartTime__c == null){
                        //Return duty start time not set
                        return 'Duty ' + srObj.Name + ' does not have a Duty Start Time set. Go to the Service Resource record and set a time in the field Duty Start Time.';
                    }

                    //-Get start date time of duty in GMT timezone with duty day from the FFD and the start time from the duty SR based on users timezone
                    DateTime dutyStartDateTime = DateTime.newInstance(dutyDay, srObj.DutyStartTime__c);
                    System.debug('dutyStartDateTime pre = ' + dutyStartDateTime);
                    
                    //-apply the offset to adjust to the service territory time zone
                    dutyStartDateTime = dutyStartDateTime.addMinutes(offsetMins);

                    //-Calculate the number of minutes between FFD Start and Duty Start
                    minutesBtwnFFDAndDutyStart = Integer.valueOf((ffdDateTime.getTime() - dutyStartDateTime.getTime())/60000);

                    //2. call the apply roster/create scm with usual details and offset time
                    //-Set up a roster record to pass to create assignments function
                    rosterRecord = new Roster__c(
                        Duty__c = srId,
                        Driver__c = driverIdString,
                        Start_Date__c = dutyDay,
                        End_Date__c = dutyDay,
                        Service_Territory__c = territoryId,
                        Roster_Reference__c = 'Gantt Dispatch Adjustment ' + Datetime.now().format('dd/MM/yyyy HH:mm:ss'),
                        Gantt_Assignment__c = true,
                        Start_Time_Offset__c = minutesBtwnFFDAndDutyStart);

                    //-Insert roster record
                    insert rosterRecord;

                    //-Build map to pass to function  
                    rosterMap = new Map<Id, Roster__c>([SELECT Id, Duty__c, Driver__c, Start_Date__c, End_Date__c, Service_Territory__c,
                                                                Duty__r.Name, Duty__r.ServiceCrewId, Driver__r.Name, Duty__r.DutyStartTime__c, Start_Time_Offset__c   
                                                                FROM Roster__c 
                                                                WHERE Id = :rosterRecord.Id]);
                    
                    //-Call service to create Service Crew Member and Service Territory Member assignments
                    TDF_CreateServiceCrewMember createSCM = new TDF_CreateServiceCrewMember();
                    createSCM.createAssignments(rosterMap);
                }    
                */  
                //18.10.2020 TDF Enhance fix - Comment out end          
            }
            
            //If all validation passed dispatch work - Update records with status changed to Dispatched
            update saUpdateList;

            //Set gantt label to the driver name
            //srObj.FSL__GanttLabel__c = driverNameString;
            //update srObj;

            //Display confirmation message
            return 'Work dispatched (' + dispatchedInt + ') for duty ' + srObj.Name + ' to driver ' + driverNameString + '  from ' + dispFromString + ' to ' + dispToString;

        }
        //Else if no crew sr found (e.g. dispatach selected against a driver)
        //-Assumes we will not dispatch work for non crew based solution
        //-This will may require a different list view for non crew based territories
        else{
            //return message with error
            return 'No Duty Service resource with service crew found.';
        }
      
    }

    //Function to set jobs for duty from Dispatched to Scheduled for gantt action Undispatch
    public static String undispatch(Id srId){
        
        //Initialize
        Datetime currentDateTime  = System.Now();
        Datetime fromSADateTime  = currentDateTime.addHours(-12);  
        Integer undispatchedInt = 0;
        ServiceResource srObj;
        List<ServiceAppointment> saList;

        //Get Crew SR Details
        ServiceResource[] srList = [SELECT Name, ServiceCrewId, DutyStartTime__c, FSL__GanttLabel__c  
                                    FROM ServiceResource 
                                    WHERE Id =: srId 
                                    AND ResourceType = 'C' LIMIT 1];
        
        //If service resource found, assign to object
        if(srList.size() > 0){
            srObj = srList[0];
        }                                

        //Retrieve and process Service Appointments 
        //If a crew SR found
        if(srObj != null){
        
            //Get  Dispatched Service Appointments to update status to 'Scheduled'
            //within window 12 hrs prior to now and into the future
            saList = [  SELECT Id, Status 
                        FROM ServiceAppointment 
                        WHERE Id IN (SELECT ServiceAppointmentId FROM AssignedResource
                        WHERE ServiceResourceId = : srId  
                        AND ServiceAppointment.SchedStartTime > :fromSADateTime ) 
                        AND Status IN ('Dispatched')];
            
            //If SAs returned
            if(saList.size() > 0){
                //Set status back to Scheduled, and unpin
                for(ServiceAppointment sa : saList){
                    sa.Status = 'Scheduled';
                    sa.FSL__Pinned__c = false;
                    undispatchedInt = undispatchedInt + 1;
                }
                //Update SAs
                update saList;
            }
            
            //Set gantt label to null
            //srObj.FSL__GanttLabel__c = null;
            //update srObj;

            //Display confirmation message
            return 'Work undispatched (' + undispatchedInt + ') for duty ' + srObj.Name;       
        }
        else{
            return 'No Duty Service resource with service crew found.';  
        }
    }

    //Function to set jobs selected in gantt from Dispatched to Scheduled for gantt action Undispatch
    public static String undispatchGantt(List<Id> saIdList){
        
        Integer undispatchedInt = 0;
        //Get  Dispatched Service Appointments to update status to 'Scheduled'
        //based on set of selected ids passed in
        List<ServiceAppointment> saList = [  SELECT Id, Status, FSL__Pinned__c  
                                                FROM ServiceAppointment 
                                                WHERE Id IN :saIdList 
                                                AND Status IN ('Dispatched') 
                                                LIMIT 50];
            
        //If SAs returned
        if(saList.size() > 0){
            //Set status back to Scheduled, and unpin
            for(ServiceAppointment sa : saList){
                sa.Status = 'Scheduled';
                sa.FSL__Pinned__c = false;
                undispatchedInt = undispatchedInt + 1;
            }
            //Update SAs
            update saList;

            return 'Work undispatched (' + undispatchedInt + ')';
        }
        else{
            return 'No Work in status Dispatched found to undispatch.';
        }
    }
}