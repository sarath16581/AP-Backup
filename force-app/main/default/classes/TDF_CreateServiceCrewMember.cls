/** 
* @author Andrew Judd ajudd@salesforce.com 
* @date 2020-07-27 
* @description Service to Create and Delete Service Crew and Service Territory Members records
*
* @changelog 
* 2020-06-15 - Andrew Judd - Created
* 2020-08-05 - Andrew Judd - Added condition to not delete expired STMs and SCMs when called in queueable context 
*/
public with sharing class TDF_CreateServiceCrewMember {

    public Map<String,ServiceCrewMember> deleteSCMMap = new Map<String,ServiceCrewMember>();
    public Map<String,ServiceTerritoryMember> deleteSTMMap = new Map<String,ServiceTerritoryMember>();
    
    public void createAssignments(Map<Id, Roster__c> rosterMap){   

        //Initialisation
        Id serviceTerritoryId;
        Set<String> dutyIdSet = new Set<String>();
        Set<String> driverIdSet = new Set<String>();
        Date earliestRRStartDate = Date.newInstance(2200,1,1);  //earliest start date of all route assigments
        Date latestRREndDate = Date.newInstance(1900,1,1);     //lastest end date of all route assignments

        String dutyTimeZoneString;
        Integer offsetMins;

        //Varibles for SCM start and end date times
        DateTime scmStartDateTime;
        DateTime scmEndDateTime;

        Date rrProcessDate = System.Today().addDays(-7);
        Integer rrStartTimeOffset;

        Boolean isUnassign = false;

        //Map<Id,Id> dutySRIdToCrewIdMap = new Map<Id,Id>();
        Map<String,String> svcCrewIdToDutySRIdMap = new Map<String,String>();

        List<ServiceCrewMember> existingSCMList;
        List<ServiceCrewMember> newSCMList = new List<ServiceCrewMember>(); //full list of all new SCMs required - used to check STMs
        List<ServiceCrewMember> insertSCMList = new List<ServiceCrewMember>(); //list of SCMs to insert
        Set<String> existingSCMKeySet = new Set<String>();

        List<ServiceTerritoryMember> existingDriverSTMList;
        Set<String> existingDriverSTMKeySet = new Set<String>();

        List<ServiceTerritoryMember> dutySTMList;
        Map<String,List<ServiceTerritoryMember>> dutyIdTodutySTMMap = new Map<String,List<ServiceTerritoryMember>>();
        String keyId;
        List<ServiceTerritoryMember> insertSTMList = new List<ServiceTerritoryMember>();

        String newSCMKey;
        String newSTMKey;

        //Get Duty Ids, Driver Ids, and min and max start dates, service territory and service crew to duty from input
        for(Roster__c rr : rosterMap.values()){
            serviceTerritoryId = rr.Service_Territory__c;
            dutyIdSet.add(rr.Duty__c);
            driverIdSet.add(rr.Driver__c);
            if(rr.Start_Date__c < earliestRRStartDate) earliestRRStartDate = rr.Start_Date__c;
            if(rr.End_Date__c > latestRREndDate) latestRREndDate = rr.End_Date__c;

            //If roster record driver is null
            if(rr.Driver__c == null) isUnassign = true;
            
            //Build map of duty to Service crew to provide dutySRId when building existingSCMKey
            svcCrewIdToDutySRIdMap.put(rr.Duty__r.ServiceCrewId,rr.Duty__c);
            
        }


        //Get timezone from ST
        dutyTimeZoneString = [SELECT OperatingHours.TimeZone FROM ServiceTerritory WHERE Id = :serviceTerritoryId].OperatingHours.TimeZone;

        System.debug('dutyIdSet = ' + dutyIdSet);
        System.debug('driverIdSet = ' + driverIdSet);
        System.debug('earliestRRStartDate = ' + earliestRRStartDate);
        System.debug('latestRREndDate = ' + latestRREndDate);

        System.debug('svcCrewIdToDutySRIdMap = ' + svcCrewIdToDutySRIdMap); 



        //--Service Crew Members--
        //Get all existing SCMs by duty OR driver within the maximum window (with some buffer either side - 2 days)
        //-ServiceResourceId > driverSRId
        //-ServiceCrewId with svcCrewIdToDutySRIdMap > dutySRId
        existingSCMList = [SELECT Id, ServiceResourceId, ServiceCrewId, StartDate, EndDate, Roster_Record__c  
                            FROM ServiceCrewMember 
                            WHERE   (ServiceCrewId IN :svcCrewIdToDutySRIdMap.keySet() OR 
                                    ServiceResourceId IN :driverIdSet) 
                            AND StartDate < :latestRREndDate.addDays(2) AND EndDate >= :earliestRRStartDate.addDays(-2) 
                            LIMIT 50000];

        System.debug('existingSCMList = ' + existingSCMList);  
        
        //Create existing SCM keyset
        //-This will be referenced on creation of new list, such that if exact same SCM already exists then no need to insert again
        //-Key is DutySRId | DriverSRId | StartDateTime | EndDateTime | RosterRecord
        for(ServiceCrewMember scm : existingSCMList){
            //Build key and add to set
            existingSCMKeySet.add(svcCrewIdToDutySRIdMap.get(scm.ServiceCrewId) + scm.ServiceResourceId + 
                                    string.valueOf(scm.StartDate) + string.valueOf(scm.EndDate) + 
                                    scm.Roster_Record__c);
        }

        //Get list of any exipred SCMs to delete
        //-all SCMs created via this service (i.e. Roster_Record__c not null), for the territory
        //-and expired more than 7 days ago
        //-this map will be used to store any addition clashing records to delete
        //Note that this is not done if function called in Queueable or Future context as that will likely result in a conflicts when parallel requests do the same thing 
        if(System.IsBatch() == false && System.isFuture() == false){
            for(ServiceCrewMember scm : [SELECT Id FROM ServiceCrewMember 
                                            WHERE Roster_Record__c != null 
                                            AND Roster_Record__r.Service_Territory__c = :serviceTerritoryId 
                                            AND EndDate < :rrProcessDate]){
                deleteSCMMap.put(scm.Id, scm);
            }
        }
        
        System.debug('deleteSCMMap = ' + deleteSCMMap);  

        //--Service Territory Members--
        //Get all existing secondary STMs within the maximum window (with some buffer either side - 2 days)
        //-by driver > to find any driver stm clashes - for deletion
        //-by duty (via the roster record) > to find any stms for the duty being assigned that are assigned to another driver - for deletion
        existingDriverSTMList = [SELECT Id, ServiceResourceId, ServiceTerritoryId,  EffectiveStartDate, EffectiveEndDate, Roster_Record__c, 
                            Roster_Record__r.Duty__c  
                            FROM ServiceTerritoryMember
                            WHERE TerritoryType = 'S'   
                            AND (ServiceResourceId IN :driverIdSet OR Roster_Record__r.Duty__c IN :dutyIdSet) 
                            AND EffectiveStartDate < :latestRREndDate.addDays(2) 
                            AND (EffectiveEndDate >= :earliestRRStartDate.addDays(-2) OR EffectiveEndDate = null)
                            AND ServiceTerritory.IsActive = true 
                            LIMIT 10000];

        //Get all secondary STMs by duty within the maximum window
        //-These will be used to determine the secondary territories assigned to duties that need to be applied to the assigned drivers
        dutySTMList = [SELECT Id, ServiceResourceId, ServiceTerritoryId, EffectiveStartDate, EffectiveEndDate  
                            FROM ServiceTerritoryMember
                            WHERE TerritoryType = 'S'   
                            AND ServiceResourceId IN :dutyIdSet
                            AND EffectiveStartDate < :latestRREndDate.addDays(2) 
                            AND (EffectiveEndDate >= :earliestRRStartDate.addDays(-2) OR EffectiveEndDate = null)
                            AND ServiceTerritory.IsActive = true 
                            LIMIT 10000];

        //Get list of any exipred STMs to delete
        //-all Secondary STM for the territory, expired more than 7 days ago
        //-assigned to drivers (T = Technician) i.e don't delete expired crew STMs
        //-this map will be used to store any addition clashing records to delete
        //Note that this is not done if function called in Queueable or Future context as that will likely result in a conflicts when parallel requests do the same thing 
        if(System.IsBatch() == false && System.isFuture() == false){
            for(ServiceTerritoryMember stm : [SELECT Id FROM ServiceTerritoryMember 
                                                WHERE TerritoryType = 'S' 
                                                AND ServiceResource.ResourceType = 'T' 
                                                AND ServiceTerritory.TopLevelTerritoryId = :serviceTerritoryId 
                                                AND EffectiveEndDate < :rrProcessDate]){
                deleteSTMMap.put(stm.Id, stm);
            }
        }

        //System.debug('existingDriverSTMList = ' + existingDriverSTMList);
        //System.debug('dutySTMList = ' + dutySTMList);

        //Create existing driver STM keyset
        //-This will be referenced on creation of new list, such that if exact same STM already exists for the driver then no need to insert again
        //-Key is SRId | STId | StartDateTime | EndDateTime | RosterRecord
        for(ServiceTerritoryMember stm : existingDriverSTMList){
            //Build key and add to set
            existingDriverSTMKeySet.add(string.valueOf(stm.ServiceResourceId) + string.valueOf(stm.ServiceTerritoryId) + 
                                    string.valueOf(stm.EffectiveStartDate) + string.valueOf(stm.EffectiveEndDate) +
                                    string.valueOf(stm.Roster_Record__c));
        }

        System.debug('existingDriverSTMKeySet = ' + existingDriverSTMKeySet);

        //Create dutyIdTodutySTMMap by arranging dutySTMList by Duty Id and List of STMs
        //- to improve efficently of create insertSTMList logic below
        //- as only need only assess records associated to the Duty being processed
        for(ServiceTerritoryMember stm : dutySTMList){
            
            //For each Service Territory Member record
            keyId = stm.ServiceResourceId; //get the duty SR Id

            //Populate map by Id and group of records
            if(dutyIdTodutySTMMap.containsKey(keyId)){
                dutyIdTodutySTMMap.get(keyId).add(stm);
            }
            else{
                dutyIdTodutySTMMap.put(keyId,new List<ServiceTerritoryMember>{stm});
            }
        }

        System.debug('dutyIdTodutySTMMap = ' + dutyIdTodutySTMMap);

        //Get the number of minutes between the user's timezone and the Service Territory Timezone - to convert the datatimes below to gmt
        offsetMins = Integer.valueOf(TDF_WorkOrderUtility.getOffsetHours(dutyTimeZoneString) * 60);  //Note that we convert to minutes to get as an integer value

        //Loop thru duty assignments
        //-build list of new Service Crew Member records to insert for driver
        //-build list of new Service Territory Member records to insert for the driver
        for(Roster__c rr : rosterMap.values()){

            rrProcessDate = rr.Start_Date__c;
            rrStartTimeOffset = Integer.valueOf(rr.Start_Time_Offset__c); //number of minutes to offset start time from duty start time. Only set in Dispatch Work
            system.debug('rrStartTimeOffset = '+ rrStartTimeOffset);

            //Loop thru days
            while(rrProcessDate <= rr.End_Date__c){

                //Start and End Date time of the member record in GMT relative to users timezone                
                scmStartDateTime = DateTime.newInstance(rrProcessDate, rr.Duty__r.DutyStartTime__c);             
                
                //Apply any timezone offset changes and remove 1hr from start and add 14 hrs to end for buffer
                scmStartDateTime = scmStartDateTime.addMinutes(offsetMins);
                
                //If addition offset set against the roster record (i.e. during dispatch where the FFD has strayed from the duty start time)
                if(rrStartTimeOffset != 0 && rrStartTimeOffset != null){
                    //Then apply this also
                    scmStartDateTime = scmStartDateTime.addMinutes(rrStartTimeOffset);
                }

                scmStartDateTime = scmStartDateTime.addHours(-1);
                scmEndDateTime = scmStartDateTime.addHours(14);

                //Create key for new Service Crew Member assignment
                newSCMKey = string.valueOf(rr.Duty__c) + string.valueOf(rr.Driver__c) + 
                            string.valueOf(scmStartDateTime) + string.valueOf(scmEndDateTime) + rr.Id;

                //Create new SCM records
                ServiceCrewMember newSCMRec = new ServiceCrewMember(

                    ServiceCrewId = rr.Duty__r.ServiceCrewId,
                    ServiceResourceId = rr.Driver__c,
                    StartDate = scmStartDateTime, 
                    EndDate = scmEndDateTime,
                    Roster_Record__c = rr.Id);
                
                //Add to new SCM List
                newSCMList.add(newSCMRec);

                //If a matching record does not already exist in system
                if(!existingSCMKeySet.contains(newSCMKey)){
                    //Then add SCM record to insert list
                    insertSCMList.add(newSCMRec);
                }

                //Create key for new Service Territory Member assignment
                //If this duty has any active secondary STMs
                if(dutyIdTodutySTMMap.containsKey(rr.Duty__c)){
                    
                    //Loop thru the duty's STMs
                    for(ServiceTerritoryMember dutySTM : dutyIdTodutySTMMap.get(rr.Duty__c)){
                        
                        //If the STM is valid for the current process day
                        if(dutySTM.EffectiveStartDate <= scmEndDateTime && (dutySTM.EffectiveEndDate >= scmStartDateTime || dutySTM.EffectiveEndDate == null)){
                            //Create key for new Service Territory Member assignment

                            newSTMKey = string.valueOf(rr.Driver__c) + string.valueOf(dutySTM.ServiceTerritoryId) + 
                                        string.valueOf(scmStartDateTime) + string.valueOf(scmEndDateTime) +
                                        string.valueOf(rr.Id);

                            //If a matching record does not already exist
                            if(!existingDriverSTMKeySet.contains(newSTMKey)){
                                //Then create a new secondary STM record in list
                                ServiceTerritoryMember newSTMRec = new ServiceTerritoryMember(
                                    ServiceResourceId = rr.Driver__c,
                                    ServiceTerritoryId = dutySTM.ServiceTerritoryId,
                                    EffectiveStartDate = scmStartDateTime, 
                                    EffectiveEndDate = scmEndDateTime,
                                    TerritoryType = 'S', 
                                    Roster_Record__c = rr.Id);
                                insertSTMList.add(newSTMRec);
                            }
                        }
                    }
                }
                //increment date
                rrProcessDate = rrProcessDate.addDays(1);
            }
        }

        System.debug('newSCMList = ' + newSCMList);
        System.debug('insertSTMList = ' + insertSTMList);

        //--Go thru new SCMs and STMs and remove any conflicts (by either duty or driver)--

        //a) STMs
        //i. Function to inspect all existing secondary STMs for drivers with a change in assignment, and delete any that are now not applicable.
        //- The newSCMList is used here since not all duties have a secondary Service Territory. 
        //- For example a driver might be assigned off a duty with a secondary territory (e.g. High Priority), to one without. 
        //- In that scenario there will be no new STM for this driver as a basis to do the check, and they will be left with STMs relating to their previously assigned duty.
        //- However every driver in the roster will be assigned a duty (SCM), and the duty start and end will align with the STM, so we use this to check.
        existingSTMsToDeleteByDriver(newSCMList, existingDriverSTMList, svcCrewIdToDutySRIdMap, isUnassign);

        //Clear newSCMList as now not required
        newSCMList.clear();
        
        //ii. Function to check for any existing STMs that clash with STMs being inserted. If found, delete the existing one
        //- For example a driver might be assigned from an early duty to a later duty, both with with High Priority secondary territory.
        //- In this case the STM for the early duty should be removed 
        //- by Driver then by Duty
        existingSTMsToDelete(insertSTMList,existingDriverSTMList, rosterMap, 'Driver');
        existingSTMsToDelete(insertSTMList,existingDriverSTMList, rosterMap, 'Duty'); 

        //b) SCMs
        //i. Function to identify existing SCM records that clash with new SCM records and add to the public SCM delete map
        //- by Driver then by Duty
        existingSCMsToDelete(insertSCMList,existingSCMList,'Driver');
        existingSCMsToDelete(insertSCMList,existingSCMList,'Duty');

        //System.debug('deleteSCMMap = ' + deleteSCMMap);
        //System.debug('deleteSCMMap values = ' + deleteSCMMap.values());
        
        System.debug('>>Existing SCM Count = ' + existingSCMList.size());
        System.debug('>>Existing Driver STM Count = ' + existingDriverSTMList.size());
        System.debug('>>Delete SCM Count = ' + deleteSCMMap.size());
        System.debug('>>Delete STM Count = ' + deleteSTMMap.size());
        System.debug('>>Insert SCM Count = ' + insertSCMList.size());
        System.debug('>>Insert STM Count = ' + insertSTMList.size());

        //Delete existing SCMs that clash
        delete deleteSCMMap.values();

        //Delete existing STMs that clash or have been orphaned
        delete deleteSTMMap.values();

        //If not unassign (only possible from gantt)
        if(isUnassign == false){

            //Insert new SCMs
            insert insertSCMList;

            //Insert new STMs
            insert insertSTMList;
        }
        

    }

    //SCM BY DUTY/DRIVER CHECK - remove clashing records
    //Function to identify existing SCM records that clash with new SCM records and add to the public delete map
    public void existingSCMsToDelete(List<ServiceCrewMember> insertSCMList, List<ServiceCrewMember> existingSCMList, String contextString){
        
        String keyId;
        Map<String,List<ServiceCrewMember>> existingSCMByIdMap = new Map<String,List<ServiceCrewMember>>();
 
        //1. Group existing SCM List by Id (Duty/Driver)
        //- to improve efficently of conflict check logic 
        //- as conflict check need only search across records assigned to the same service crew (Duty) or service resource (Driver)
        //- depending on context

        //For each Service Crew Member record
        for(ServiceCrewMember scm : existingSCMList){

            //Get key based on context
            if(contextString == 'Duty'){
                keyId = scm.ServiceCrewId; //get by service crew (duty)
            }
            else{
                keyId = scm.ServiceResourceId; //get by service resource (driver)
            }

            //Populate map by Id and group of records
            if(existingSCMByIdMap.containsKey(keyId)){
                existingSCMByIdMap.get(keyId).add(scm);
            }
            else{
                existingSCMByIdMap.put(keyId,new List<ServiceCrewMember>{scm});
            }
        }
        
        //2. Check for clashing records
        //For each new SCM record
        for(ServiceCrewMember insertSCM : insertSCMList){

            //Get key based on context
            if(contextString == 'Duty'){
                keyId = insertSCM.ServiceCrewId; //get by service crew (duty)
            }
            else{
                keyId = insertSCM.ServiceResourceId; //get by service resource (driver)
            }

            //If there are existing SCMs assigned to this duty/driver
            if(existingSCMByIdMap.containsKey(keyId)){
                
                //Loop thru all existing SCMs assigned to this duty/driver
                for(ServiceCrewMember existingSCM : existingSCMByIdMap.get(keyId)){
                    
                    //If the existing SCM clashes with the new SCM record
                    //Note that we have removed identical records from the new list above 
                    //to prevent the system from deleting and then inserting the same thing
                    if(existingSCM.StartDate <= insertSCM.EndDate && existingSCM.EndDate >= insertSCM.StartDate){
                        //Then add SCM to the delete map
                        deleteSCMMap.put(existingSCM.Id,existingSCM);
                    }
                }
            }
        }
    }

    //STM BY DRIVER CHECK - remove orphans
    //Function to check for any existing STMs than might now exist against drivers that have been unassigned from duty that had an STM requirement
    //-function organises all existing STMs by Driver
    //-then loops through all new SCMs by Driver
    //-if the driver has an existing STM that overlaps with their SCM assignment
    //-if the STM duty is different to the SCM duty
    //-then delete it

    public void existingSTMsToDeleteByDriver(List<ServiceCrewMember> newSCMList, List<ServiceTerritoryMember> existingDriverSTMList, 
                                            Map<String,String> svcCrewIdToDutySRIdMap, Boolean isUnassign){

        String stmDriverId;
        String scmDriverId;

        //Organise STMs by duty
        Map<String,List<ServiceTerritoryMember>> existingSTMByDriverMap = new Map<String,List<ServiceTerritoryMember>>();

        //For each existing Service Territory Member record
        for(ServiceTerritoryMember stm : existingDriverSTMList){

            //Get the driver from the stm - as they driver will have been assigned off a duty
            stmDriverId = stm.ServiceResourceId;
            
            //Populate map with all STM records by driver
            if(existingSTMByDriverMap.containsKey(stmDriverId)){
                existingSTMByDriverMap.get(stmDriverId).add(stm);
            }
            else{
                existingSTMByDriverMap.put(stmDriverId,new List<ServiceTerritoryMember>{stm});
            }
        }

        //Loop thru each newSCM (as there will always be one for driver-duty-day)
        for(ServiceCrewMember newSCM : newSCMList){

            //If not unassign
            if(isUnassign == false){
                //Get the driver id of the SCM
                scmDriverId = newSCM.ServiceResourceId;
            }
            else{
                //if unassign get driver id from the stm (as the STM driver will be null)
                //- note there will only be one roster record (single driver) in unassign scenario 
                scmDriverId = stmDriverId;
            }
            
            //Get all existing STMs by duty
            if(existingSTMByDriverMap.containsKey(scmDriverId)){
                
                //Loop thru all existing STMs assigned to this Driver
                for(ServiceTerritoryMember existingSTM : existingSTMByDriverMap.get(scmDriverId)){

                    //If the STM time overlaps with the SCM time
                    if(existingSTM.EffectiveStartDate <= newSCM.EndDate && 
                        (existingSTM.EffectiveEndDate >= newSCM.StartDate || existingSTM.EffectiveEndDate == null)){
                        
                        //If STM duty is not the same as the SCM duty - then this must be an old STM (i.e. one for the duty than have been assign off)
                        //Or if is unassign call (where the duties will be the same but driver is being removed)
                        if((existingSTM.Roster_Record__r.Duty__c != svcCrewIdToDutySRIdMap.get(newSCM.ServiceCrewId)) || isUnassign == true){

                            //Add to STM to the delete map
                            deleteSTMMap.put(existingSTM.Id,existingSTM);

                        }
                    }
                }
            }
        }
    }

    //STM BY DUTY CHECK - check for clashes
    //Function to identify existing driver STM records that clash with new driver STM records and add to the public delete map
    public void existingSTMsToDelete(List<ServiceTerritoryMember> insertSTMList, List<ServiceTerritoryMember> existingDriverSTMList, Map<Id, Roster__c> rosterMap, String contextString){
        
        String keyId;
        Map<String,List<ServiceTerritoryMember>> existingDriverSTMByIdMap = new Map<String,List<ServiceTerritoryMember>>();

        //1. Group existing STM List by Driver
        //- to improve efficently of conflict check logic 
        //- as conflict check needs only search across records assigned to the same service resource (Driver)

        //For each existing Service Territory Member record
        for(ServiceTerritoryMember stm : existingDriverSTMList){

            //Get key based on context
            if(contextString == 'Duty'){
                keyId = stm.Roster_Record__r.Duty__c; //get by duty (via Roster Record)
            }
            else{
                keyId = stm.ServiceResourceId; //get by service resource (driver)
            }

            //Populate map by Id and group of records
            if(existingDriverSTMByIdMap.containsKey(keyId)){
                existingDriverSTMByIdMap.get(keyId).add(stm);
            }
            else{
                existingDriverSTMByIdMap.put(keyId,new List<ServiceTerritoryMember>{stm});
            }
        }

        //System.debug('existingDriverSTMByIdMap = ' + existingDriverSTMByIdMap);

        //2. Check for clashing records
        //For each new STM record
        for(ServiceTerritoryMember newSTM : insertSTMList){

            //Get key based on context
            if(contextString == 'Duty'){
                //get by Duty via the roster record
                //TODO: Consider adding a new seperate look up field (or text field) on the STM to record duty id directly
                //Rather than get via rr. Since if rr is deleted or modified, outcome will be unexpected
                keyId = rosterMap.get(newSTM.Roster_Record__c).Duty__c; 
            }
            else{
                keyId = newSTM.ServiceResourceId; //get by service resource (driver)
            }

            //If there are existing STMs assigned to this driver/duty
            if(existingDriverSTMByIdMap.containsKey(keyId)){
                
                //Loop thru all existing STMs assigned to this Driver/Duty
                for(ServiceTerritoryMember existingSTM : existingDriverSTMByIdMap.get(keyId)){
                    
                    //If the existing STM clashes with the new STM record for the same Secondary Territory
                    //Note that we have removed identical records from the insert list above 
                    //to prevent the system from deleting and then inserting the same thing
                    if(existingSTM.EffectiveStartDate <= newSTM.EffectiveEndDate && 
                        (existingSTM.EffectiveEndDate >= newSTM.EffectiveStartDate || existingSTM.EffectiveEndDate == null) &&
                        existingSTM.ServiceTerritoryId == newSTM.ServiceTerritoryId){
                        //Then add SCM to the delete map
                        deleteSTMMap.put(existingSTM.Id,existingSTM);
                    }
                }
            }
        }
    }
}