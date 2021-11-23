/** 
* @author Andrew Judd ajudd@salesforce.com 
* @date 2020-07-14 
* @description Controller for the Apply Roster page.  
*               Calls function to creates Service Crew Member and Service Territory Member records to assign drivers 
*               to Duty Service Resources based on data imported into object Roster__c
*
* @changelog 
* 2020-07-14 - Andrew Judd - Created 
*/
public with sharing class TDF_ApplyRosterController {

    public String rosterRecordId{get;set;}
    public String serviceTerritoryId{get;set;}
    public String rosterReferenceString{get;set;}
    public String serviceTerritoryString{get;set;}

    public TDF_ApplyRosterController(ApexPages.standardController sc){

        //Initalisation 
        Roster__c rosterRecObj = new Roster__c();
        
        //Get roster record id from page
        rosterRecordId = Apexpages.currentPage().getParameters().get('id');

        rosterRecObj = [SELECT Service_Territory__c, Service_Territory__r.Name, Roster_Reference__c FROM Roster__c WHERE Id = :rosterRecordId];

        //Set variables for functions below
        serviceTerritoryId = rosterRecObj.Service_Territory__c;
        rosterReferenceString = rosterRecObj.Roster_Reference__c;
        serviceTerritoryString = rosterRecObj.Service_Territory__r.Name;
    }

    //To go back on duty page
    public PageReference goBack(){
        PageReference pg = new PageReference('/lightning/o/Roster__c/home');
        return pg;
    }

    //Function to called on selection of Apply Roster button
    //-First validates group of roster records based on selected 'Roster Reference'
    //-If validation passes, calls service TDF_CreateServiceCrewMember.createAssignments to create SCMs
    public void applyRoster(){

        //Initialization
        Map<Id, Roster__c> rosterMap; 
        Date tomorrowDate = System.Today().addDays(1);
        Date winStartDate = Date.newInstance(2200,1,1);   //earliest start date of all route assigments
        Date winEndDate = Date.newInstance(1900,1,1);     //lastest end date of all route assignments
        //Date winEndMaxDate;     //max range assignments can be created for (set to 42 days from ealiest start)

        Date rrProcessDate;
        Date rrFirstValidDate;
        Set<String> dutyDaySet = new Set<String>();
        Set<String> driverDaySet = new Set<String>();

        Set<String> dutyDayConflictSet = new Set<String>();
        Set<String> driverDayConflictSet = new Set<String>();
        Set<String> driverAssClashConflictSet = new Set<String>();
        Set<String> dutyWithNoStartDateSet = new Set<String>();
        String conflictString = 'Conflicting assignments for the following must be resolved:';

        Set<String> rosterRecToRemoveSet = new Set<String>();
        Map<String,String> driverIdToDriverNameMap = new Map<String,String>();

        //Variables for assignment clash check
        Map<String,List<String>> driverToAssStartEndListMap = new Map<String,List<String>>();
        DateTime assStartDateTime;
        DateTime assEndDateTime;
        String assStartEndString;
        List<String> assStartEndDateList = new List<String>();        
        String thisAssStartTime;
        String prevAssEndTime = '2001010101'; //set to day time in the past

        //Get all valid Duty Assignments by roster reference (i.e. ignore any with less that tomorrow) 
        rosterMap = new Map<Id, Roster__c>([SELECT Id, Duty__c, Driver__c, Start_Date__c, End_Date__c, Service_Territory__c, 
                                                        Duty__r.Name, Duty__r.ServiceCrewId, Driver__r.Name, Duty__r.DutyStartTime__c, Start_Time_Offset__c   
                                                        FROM Roster__c 
                                                        WHERE Roster_Reference__c =:rosterReferenceString AND 
                                                        Service_Territory__c = :serviceTerritoryId 
                                                        AND End_Date__c >= :tomorrowDate] );

        //Get window start and end dates
        for(Roster__c rr : rosterMap.values()){
            //If start date earlier, record
            if(rr.Start_Date__c < winStartDate){
                winStartDate = rr.Start_Date__c;
            }
            //If end date later, record
            if(rr.End_Date__c > winEndDate){
                winEndDate = rr.End_Date__c;
            }
            //Store driver id to name
            driverIdToDriverNameMap.put(rr.Driver__c,rr.Driver__r.Name);

            //Add any duty names with no start date to the set
            if(rr.Duty__r.DutyStartTime__c == null){
                dutyWithNoStartDateSet.add(rr.Duty__r.Name);
            }
            
        }

        //if any duties with no start time
        if(dutyWithNoStartDateSet.size() > 0){
            //Advise and end
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,
                    'The following duties do not have a start date set: ' + dutyWithNoStartDateSet +
                     ' Please go to the duty service resource record and set the field Duty Start Time.'));
            return;
        }
        
        //adjust start to min of tomorrow, ignoring all assigments prior
        //-this prevents apply roster from changing assignments for today
        if(winStartDate < tomorrowDate) winStartDate = tomorrowDate;

        System.System.debug('tomorrowDate = ' + tomorrowDate);
        System.System.debug('winStartDate = ' + winStartDate);
        System.System.debug('winEndDate = ' + winEndDate);

        //Check there is not more than one assignment for duty for day for assignments from tomorrow
        for(Roster__c rr : rosterMap.values()){
            
            rrProcessDate = rr.Start_Date__c;
            rrFirstValidDate = null;

            while(rrProcessDate <= rr.End_Date__c){

                //If start date greater than today (i.e. a valid assignment)
                if(rrProcessDate > System.Today()){
                    //If duty day assignment already encountered
                    if(dutyDaySet.contains(rr.Duty__c + string.valueOf(rrProcessDate))){
                        //Then record to alert user 
                        dutyDayConflictSet.add(rr.Duty__r.Name);
                    }
                    dutyDaySet.add(rr.Duty__c + string.valueOf(rrProcessDate));

                    //If driver day assignment already encountered
                    if(driverDaySet.contains(rr.Driver__c + string.valueOf(rrProcessDate))){
                        //Then record to alert user 
                        driverDayConflictSet.add(rr.Driver__r.Name);
                    }
                    driverDaySet.add(rr.Driver__c + string.valueOf(rrProcessDate));

                    //Save first valid start date
                    if(rrFirstValidDate == null) rrFirstValidDate = rrProcessDate;

                    //##Populate map by Id and group assignment start end strings
                    //-used to determine in any new assignments will clash
                    //-add two dates to list of primative data time (String) to allow use of list sort later
                    assStartDateTime = DateTime.newInstance(rrProcessDate, rr.Duty__r.DutyStartTime__c);
                    assStartDateTime = assStartDateTime.addHours(-1);
                    assEndDateTime = assStartDateTime.addHours(11);
                    assStartEndString = assStartDateTime.format('yyMMddHHmm') + ',' + assEndDateTime.format('yyMMddHHmm');

                    if(driverToAssStartEndListMap.containsKey(rr.Driver__c)){
                        driverToAssStartEndListMap.get(rr.Driver__c).add(assStartEndString);
                    }
                    else{
                        driverToAssStartEndListMap.put(rr.Driver__c,new List<String>{assStartEndString});
                    }

                }
                rrProcessDate = rrProcessDate.addDays(1);
            }

            //If any assignment within valid date range (i.e. tomorrow or beyond)
            if(rrFirstValidDate != null){
                //update the Assignment start to this date
                //Could do this in the main function, however valid start is different for Apply Driver (today), vs Apply Roster (tommorrow)
                rr.Start_Date__c = rrFirstValidDate; 
                //if roster record has an end date greater that 42 days from its start date
                if(rr.End_Date__c > rr.Start_Date__c.addDays(42)){
                    //Then update to 42 days from the start 
                    //-this isto contain assignment creation to a maximum of 6 weeks
                    rr.End_Date__c = rr.Start_Date__c.addDays(42);
                }
            }
            //else add to set to remove at end
            else{
                rosterRecToRemoveSet.add(rr.Id);
            }
        }

        //Remove invalid assignments
        for(String key : rosterRecToRemoveSet){
            rosterMap.remove(key);
        }

        //Check for overlapping assignments (i.e. driver assigned to a late starting duty on day 1 followed by early starting duty on day 2 - where they overlap)
        //For each driver
        for(String driverId : driverToAssStartEndListMap.keySet()){

            //Get list of Start and End dates
            assStartEndDateList = driverToAssStartEndListMap.get(driverId);

            //Sort the list
            assStartEndDateList.sort();

            //Loop thru list and check if any start date time overlaps with a previous start date time
            for(String assStartEndDateRec : assStartEndDateList){
                System.debug('assStartEndDateRec =' + assStartEndDateRec);
                thisAssStartTime = assStartEndDateRec.left(10);
                //If the current start date time is prior to the end of the previous assignment
                if(thisAssStartTime < prevAssEndTime){
                    //Add to assignment conflict clash set
                    driverAssClashConflictSet.add(driverIdToDriverNameMap.get(driverId));
                }
                //set previous end time for evaluation of next record
                prevAssEndTime = assStartEndDateRec.right(10);
            }
            //reset previous end time for next driver
            prevAssEndTime = '2001010101';
        }

        //If no valid assignments
        if(rosterMap.size() == 0){
            //Display message
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'No valid assignments found!'));
        }
        //If any conflicting
        //- drivers assigned to more than one duty on the same day
        //- duties assigned to more than on driver on the same day
        //- assignments for a driver that will clash (i.e. where an assignment across midnight clashes)
        else if(dutyDayConflictSet.size() > 0 ||  driverDayConflictSet.size() > 0 || driverAssClashConflictSet.size() > 0){

            //Build conflict message and display
            if(dutyDayConflictSet.size() > 0) conflictString = conflictString + ' Duties ' + dutyDayConflictSet;
            if(driverDayConflictSet.size() > 0) conflictString = conflictString + ' Drivers ' + driverDayConflictSet;
            if(driverAssClashConflictSet.size() > 0) conflictString = conflictString + ' Drivers with assignments that will overlap ' + driverAssClashConflictSet;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,conflictString));
            
        }
        //Else ready to call function
        else{
            //Call function passing details
            System.debug('rosterMap final = ' + rosterMap);

            //Call service to create service crew member assignments
            TDF_CreateServiceCrewMember createSCM = new TDF_CreateServiceCrewMember();
            createSCM.createAssignments(rosterMap);
            
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Roster '+ rosterReferenceString + ' has been applied ('+ rosterMap.size() +')'));
            
        }
    }

    //Function to delete all Service Crew Members (Operational Duty Assignments) and Secondary Service Territory Members  by roster reference
    public void deleteAssignmentsByRosterRef(){

        Date fromDate = System.Today().addDays(1);       

        //Get all SCMs
        //-By roster reference name
        //-ST constraint included to prevent deletion of records in another territory with the same name
        //-from tomorrow on (i.e. don't delete any assignments for today or in the past)
        List<ServiceCrewMember> scmToDeleteList = [SELECT Id FROM ServiceCrewMember 
                                                    WHERE StartDate > :fromDate 
                                                    AND Roster_Record__r.Roster_Reference__c = :rosterReferenceString  
                                                    AND Roster_Record__r.Service_Territory__c = :serviceTerritoryId];

        //Get all STMs
        //-By roster reference name
        //-ST constraint included to prevent deletion of records in another territory with the same name
        //-from tomorrow on (i.e. don't delete any assignments for today or in the past)
        List<ServiceTerritoryMember> stmToDeleteList = [SELECT Id FROM ServiceTerritoryMember 
                                                    WHERE EffectiveStartDate > :fromDate 
                                                    AND Roster_Record__r.Roster_Reference__c = :rosterReferenceString  
                                                    AND Roster_Record__r.Service_Territory__c = :serviceTerritoryId];
   
        System.debug('scmToDeleteList size = ' + scmToDeleteList.size());
        System.debug('stmToDeleteList size = ' + stmToDeleteList.size());
        Integer numberDeletedInt = scmToDeleteList.size();

        delete scmToDeleteList;
        delete stmToDeleteList;

        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'All operational duty assignments for ' + rosterReferenceString + ' deleted (' + numberDeletedInt + ')'));
    }

    //Function to delete all Service Crew Members (Operational Duty Assignments) and Secondary Service Territory Members by service territory
    public void deleteAssignmentsByST(){

        Date fromDate = System.Today().addDays(1);

        //Get all SCMs
        //-By ST constraint
        //-from tomorrow on (i.e. don't delete any assignments for today or in the past)
        List<ServiceCrewMember> scmToDeleteList = [SELECT Id FROM ServiceCrewMember 
                                                    WHERE StartDate > :fromDate 
                                                    AND Roster_Record__r.Service_Territory__c = :serviceTerritoryId];
                                            
        List<ServiceTerritoryMember> stmToDeleteList = [SELECT Id FROM ServiceTerritoryMember 
                                                    WHERE EffectiveStartDate > :fromDate  
                                                    AND Roster_Record__r.Service_Territory__c = :serviceTerritoryId];
   
        System.debug('scmToDeleteList size = ' + scmToDeleteList.size());
        Integer numberDeletedInt = scmToDeleteList.size();

        delete scmToDeleteList;
        delete stmToDeleteList;
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'All operational duty assignments for ' + serviceTerritoryString + ' deleted (' + numberDeletedInt + ')'));
    }

    //Function to delete all roster records for selected roster reference
    public void deleteRosterRecordsByRosterRef(){

        //Check if there are any assignments for this roster reference
        //If so prevent delete and advice user that there are existing assigments based on this roster reference
        //This will prevent SCMs and STMs losing their roster relationship
        List<ServiceCrewMember> scmToDeleteList = [SELECT Id FROM ServiceCrewMember 
                                                    WHERE Roster_Record__r.Roster_Reference__c = :rosterReferenceString  
                                                    AND Roster_Record__r.Service_Territory__c = :serviceTerritoryId LIMIT 10000];
        
        //If found
        if(scmToDeleteList.size() > 0){
            //Display warning message
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Roster records can not be deleted as there are '+ scmToDeleteList.size() +' existing assignments related to roster reference ' + rosterReferenceString));
        }
        else{                                 

            //Get all roster records by reference and st
            //-ST constraint included to prevent deletion of records in another territory with the same name
            List<Roster__c> daToDeleteList = [SELECT Id FROM Roster__c 
                                                        WHERE Service_Territory__c = :serviceTerritoryId 
                                                        AND Roster_Reference__c = :rosterReferenceString];

            Integer numberDeletedInt = daToDeleteList.size();

            delete daToDeleteList;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'All '+ rosterReferenceString +' roster records deleted (' + numberDeletedInt + ')'));
        }
    }
    

}