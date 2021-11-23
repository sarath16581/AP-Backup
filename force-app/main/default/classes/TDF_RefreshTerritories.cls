/*
 * Created by nmain on 7/02/2018.
 * Updated by ajudd on 26/02/2018 - Added conditions to support call with no Service Territory Id
 * Updated by ajudd on 3/3/2018 - Enhanced performance with simplification of getKey
 * Updated by ajudd on 3/3/2018 - Make @future
 * Updated by ajudd on 4/3/2018 - Enhanced performance via map for  Sub Ter 
 * Updated by ajudd on 4/3/2018 - Add restrict inserts to 500
 */

global class TDF_RefreshTerritories {
    @future

    //Get list of all FFD appts for the ST within date range for the supplied Service Territory Id.
    public static void RefreshByServiceTerritoryId(String serviceTerritoryId){

        //#### 
        TDF_Settings__c objTDFSetting = TDF_Settings__c.getOrgDefaults();
        Integer refreshTerritoryExpiry = Integer.valueof(objTDFSetting.Refresh_Territory_Expiry__c)*-1;
        Integer endDateTimeOffsetInt = Integer.valueof(objTDFSetting.Assignment_End_Date_Time_Offset__c);
        Integer startDateTimeOffsetInt = Integer.valueof(objTDFSetting.Assignment_Start_Date_Time_Offset__c)*-1;
        Boolean refreshAllTerritories = Boolean.valueof(objTDFSetting.Refresh_All_Territories__c);
        Integer firstAssignmentOffsetInt = refreshTerritoryExpiry-30;
        //####

        System.debug('>>>>>> Start TDF_RefreshTerritories--> - RefreshByServiceTerritoryId() - serviceTerritoryId: ' +serviceTerritoryId);
        
        String strQry = '';
        
        //If custom setting Refresh_All_Territories = true, then clear serviceTerritoryId
        //When true, call from button is then same as scheduled call.
        if(refreshAllTerritories)
            serviceTerritoryId = null;
       
        //Get list of Active Sub Territories to provide ID for Secondary Territory
        List<ServiceTerritory> subTerList = new List<ServiceTerritory>();
        strQry = strQry + 'SELECT Id, Name, ParentTerritory.Id, ParentTerritory.Name, Territory_Hours__c ';
        //strQry = strQry + ', Name, ParentTerritory.Name ';
        strQry = strQry + 'FROM ServiceTerritory ';
        strQry = strQry + 'WHERE Territory_Hours__c != null AND IsActive  = true AND ParentTerritory.Id != null ';
        //If ST not null, then constrain by STs
        if(serviceTerritoryId != null)
           strQry = strQry + 'AND ParentTerritory.Id = :serviceTerritoryId';
        
        //debug query string
        //System.debug('AJJJ strQry = ' + strQry);
        
        subTerList = Database.query(strQry);
        strQry = '';                                  
        
        //If more than one Sub Territory found, continue, else end
        if(subTerList.size() > 0){
            
            //--Build Map of SubTer list with Key = TerId&TerHrs and Code = SubTerId
            //Define SubTer map
            Map<String, String> subTerHrsMap = new Map<String, String>();
            
            //Loop through Sub Ter List
            for(ServiceTerritory subTer : subTerList)
            {
                //Get Ter Hrs String
                List<String> lstTerHrs = subTer.Territory_Hours__c.split(',');
                
                //Loop through Ter Hrs String
                for (String strTerHr : lstTerHrs) {
                    //System.debug('Key:Ter+Hrs = '+subTer.ParentTerritory.Id + strTerHr.trim() + 'Code:SubTer = '+subTer.Id);
                    
                    //Build Map
                    subTerHrsMap.put(subTer.ParentTerritory.Id + strTerHr.trim(),subTer.Id);
                }   
            }
        
            //--Get all FFD SAs from now - Refresh Territory Expiry and beyond. Only for ST passed in, not cancelled, and for Active SRs
            List<AssignedResource> assResList = new List<AssignedResource>();  
            Date nowMinusRefreshTerritoryExpiryDate = Date.today().addDays(refreshTerritoryExpiry);
            strQry = strQry + 'SELECT Id, ServiceAppointment.ParentRecord.Id, ServiceAppointment.ParentRecord.RecordType.DeveloperName, ServiceResourceId, ServiceAppointment.ID, ServiceAppointment.SchedStartTime, ServiceAppointment.ServiceTerritory.Id, ServiceAppointment.ServiceTerritory.Name, ServiceAppointment.ServiceTerritory.OperatingHours.TimeZone ';
            strQry = strQry + 'FROM AssignedResource ';
            strQry = strQry + 'WHERE ServiceAppointment.ParentRecord.RecordType.DeveloperName = \'Fit_For_Duty\' ';
            strQry = strQry + 'AND ServiceAppointment.SchedStartTime > :nowMinusRefreshTerritoryExpiryDate ';
            strQry = strQry + 'AND ServiceAppointment.Status <> \'Cancelled\' '; 
            strQry = strQry + 'AND ServiceResource.IsActive = true ';
            //If ST not null, then constrain by STs
            if(serviceTerritoryId != null)
                strQry = strQry + 'AND ServiceAppointment.ServiceTerritory.Id = :serviceTerritoryId ';
            strQry = strQry + 'ORDER BY ServiceResourceId, ServiceAppointment.SchedStartTime';
            
            assResList = Database.query(strQry);
            strQry = '';
  
            //Debug Sub Ter List
            //for (ServiceTerritory servTer : subTerList)
            //    system.debug('*** subTerList --> Id:' +servTer.Id+', Sub Territory Name:'+servTer.Name+', Parent Terr Id:' +servTer.ParentTerritory.Id+ ', Parent Territory:' +servTer.ParentTerritory.Name+ ', Hours:' +servTer.Territory_Hours__c);
    
            //Populate missing fields in assResList
            List<assignmentResourceWrapper> assResListWrapper = new List<assignmentResourceWrapper>();
            //Loop thru assResList (Loop 1)
            for (AssignedResource ar : assResList)
            {
                assignmentResourceWrapper arw = new assignmentResourceWrapper();
                // Set the fields from assResList
                arw.AssignmentResourceId = ar.Id;
                arw.ServiceResourceId = ar.ServiceResourceId;
                arw.ServiceAppointmentId = ar.ServiceAppointment.Id;
                arw.SchedStartTime = ar.ServiceAppointment.SchedStartTime;
                arw.ServiceTerritoryId = ar.ServiceAppointment.ServiceTerritory.Id;
                arw.ServiceTerritoryName = ar.ServiceAppointment.ServiceTerritory.Name;
                arw.ServiceTerritoryTimeZone = ar.ServiceAppointment.ServiceTerritory.OperatingHours.TimeZone;
                //Set the calculated fields
                arw.AssignedStart = ar.ServiceAppointment.SchedStartTime.addHours(startDateTimeOffsetInt);
                arw.AssignedEnd = ar.ServiceAppointment.SchedStartTime.addHours(endDateTimeOffsetInt);
                arw.StartHour = ar.ServiceAppointment.SchedStartTime.format('HH',arw.ServiceTerritoryTimeZone);
                
                //Get SubTer for Ter&Hrs from Map. If not found will return null
                arw.SubTerritoryId = subTerHrsMap.get(arw.ServiceTerritoryId + arw.StartHour);
    
                assResListWrapper.add(arw);
            }
      
            // Debug our assResList Entries
            //for (assignmentResourceWrapper arw : assResListWrapper)
            //    arw.debug('assResList');
            
            //Get all current Secondary 'Territory Hour' STM records for all drivers (within Territory if constrained) 
            List <ServiceTerritoryMember> currentSvcTerMemList = new List <ServiceTerritoryMember>();
            strQry = strQry + 'SELECT Id, ServiceResourceId, ServiceTerritory.Id, EffectiveStartDate, EffectiveEndDate, TerritoryType ';
            strQry = strQry + 'FROM ServiceTerritoryMember ';
            strQry = strQry + 'WHERE ServiceTerritory.Territory_Hours__c != null ';
            strQry = strQry + 'AND ServiceResource.IsActive = true ';
            strQry = strQry + 'AND TerritoryType = \'S\' ';
            //If ST not null, then constrain by STs
            if(serviceTerritoryId != null)
                strQry = strQry + 'AND ServiceTerritory.ParentTerritory.Id = :serviceTerritoryId ';    
            
            currentSvcTerMemList = Database.query(strQry);
            strQry = '';      
    
            List <territoryMemberWrapper> currentSvcTerMemWrapperList = new List <territoryMemberWrapper>();
            // Populate the wrapper class and set the Key member
            for (ServiceTerritoryMember stm : currentSvcTerMemList) {
                territoryMemberWrapper currTerrMem = new territoryMemberWrapper();
                currTerrMem.id = stm.Id;
                currTerrMem.ServiceResourceId = stm.ServiceResourceId;
                currTerrMem.EffectiveStartDate = stm.EffectiveStartDate;
                currTerrMem.EffectiveEndDate = stm.EffectiveEndDate;
                currTerrMem.ServiceTerritoryId = stm.ServiceTerritoryId;            
                currTerrMem.key = currTerrMem.getKey(); //AJ 3.3.18 Enhance - Populate key for current STM List up front, instead of in Compare function
                currentSvcTerMemWrapperList.add(currTerrMem); 
            }
    
            // Debug currentSvcTerMemWrapperList Entries
            //for (territoryMemberWrapper stm : currentSvcTerMemWrapperList) {
            //    stm.debug('currentSvcTerMemList');
            //}
    
            //Build  newSvcTerMemList
            List <territoryMemberWrapper> newSvcTerMemList = new List <territoryMemberWrapper>();
            DateTime dtAssignedStartPrev = DateTime.newInstance(0);
            DateTime dtAssignedEndPrev = DateTime.newInstance(0);
            String strSubTerIdPrev = ''; //initialise
            String strSRIdPrev = '';
            Integer iNew = 0; //counter of new records created
            for (Integer i=0; i<assResListWrapper.size(); i++)
            {
               
                //If this record has a Sub Ter Id found for it, then continue, else move to next
                //if(assResListWrapper[i].SubTerritoryId != '') //Changed with Map change
                if(assResListWrapper[i].SubTerritoryId != null)
                { 
                                  
                    territoryMemberWrapper newTerrMem = new territoryMemberWrapper();
        
                    //If this record has same SR and SubTer as the previous one, and not on first new record, then don't create new record - instead extend EndDate of previous record
                    if (assResListWrapper[i].SubTerritoryId == strSubTerIdPrev && assResListWrapper[i].ServiceResourceId == strSRIdPrev && iNew > 0)
                        newSvcTerMemList[iNew - 1].EffectiveEndDate = assResListWrapper[i].AssignedEnd;
                    //If sub ter is not same as previous, create a new member record
                    else
                    {
                        newTerrMem.ServiceResourceId = assResListWrapper[i].ServiceResourceId;
                        //newTerrMem.EffectiveStartDate = assResListWrapper[i].AssignedStart;
                        newTerrMem.EffectiveEndDate = assResListWrapper[i].AssignedEnd;
                        newTerrMem.ServiceTerritoryId = (Id)assResListWrapper[i].SubTerritoryId;
        
                        //1 ###StartDate Push back for First record
                        //If this is the first record for the driver (i.e. the SRId has now changed)
                        //Then Set start date of current record (first one for the Driver) to Now - 30 days + the Refresh Expiry
                        //This ensures the the same STM is created for a driver each run, even when the first appt is up to 30 days from now                   
                        if (newTerrMem.ServiceResourceId != strSRIdPrev)
                            newTerrMem.EffectiveStartDate = assResListWrapper[i].AssignedStart.AddDays(firstAssignmentOffsetInt);
                        else{
                            newTerrMem.EffectiveStartDate = assResListWrapper[i].AssignedStart;
                        }
        
                        newSvcTerMemList.add(newTerrMem);
                        
                        //first make sure not on first driver
                        if (strSRIdPrev != ''){
                            //Make sure not on first new record
                            if(iNew > 0){
                                //This different driver to previous record
                                if (newTerrMem.ServiceResourceId != strSRIdPrev){
                                   //2 ###Set EndDate Clear for Last record
                                   //Set end date of last record for previous driver as open
                                   newSvcTerMemList[iNew - 1].EffectiveEndDate = null;
                                   }
                                //This and previous record have same driver
                                else{
                                   //Compare last STM end date to start date of this STM
                                   if(newSvcTerMemList[iNew - 1].EffectiveEndDate > newTerrMem.EffectiveStartDate){
                                       //3 ###Prevent Overlap
                                       //Set End of previous to the current start (to prevent overlaps)
                                       newSvcTerMemList[iNew - 1].EffectiveEndDate = newTerrMem.EffectiveStartDate;
                                   }
                                }
                            }
                        }
        
                        iNew += 1;
                    }
                    
                    //Store current values to compare with next
                    dtAssignedStartPrev = assResListWrapper[i].AssignedStart;
                    dtAssignedEndPrev = assResListWrapper[i].AssignedEnd;
                    strSubTerIdPrev = assResListWrapper[i].SubTerritoryId;
                    strSRIdPrev = assResListWrapper[i].ServiceResourceId;
                    
                }
                //Debug Sub Territory not set. Note that this is ok if ST does not have need for Sub Territories
                else{
                    System.debug('RT_ERROR: Sub Territory not set for Territory ' + assResListWrapper[i].ServiceTerritoryName + ' > Start Hour = ' + assResListWrapper[i].StartHour);
                }

            }
    
            //Finally, if there is at least one record, set last record end date to Null
            if (iNew > 0)
                newSvcTerMemList[iNew-1].EffectiveEndDate = null;
                
            //AJ 3.3.18 Enhance - Populate key for new STM list up front, instead of in Compare function
            for(territoryMemberWrapper tm : newSvcTerMemList){
                tm.key  = tm.getKey();
            }
    
            //Debug newSvcTerMemList
            //for ( territoryMemberWrapper tm : newSvcTerMemList)
            //    tm.debug('newSvcTerMemList');
            
            //Destroy assRes Lists
            assResList.clear();
            assResListWrapper.clear(); 
           
            //--1 Build list of Service Territory Members to delete
            //Get all current STM assignments not in new STM assignments and delete these            
            List <territoryMemberWrapper> deleteSvcTerMemList = new List <territoryMemberWrapper>();
            List<ServiceTerritoryMember> servTerMemberDeleteList = new List<ServiceTerritoryMember>();
            deleteSvcTerMemList = compareCurrentToNewSvcTerMemLists( currentSvcTerMemWrapperList,  newSvcTerMemList, false);
            
            //Add delete list to STMObject
            for ( territoryMemberWrapper tm : deleteSvcTerMemList) {
                //tm.debug('deleteSvcTerMemList'); //Debug deletes
                servTerMemberDeleteList.add(tm.getSTMObjectForDelete());
            }
            System.debug('*** TDF_RefreshTerritories--> Deleting servTerMemberDeleteList: ' + servTerMemberDeleteList.size());
            
            //Delete STM records
            Delete(servTerMemberDeleteList);
            System.debug('*** TDF_RefreshTerritories--> Deleting Completed!');
            
            //Destroy delete list
            servTerMemberDeleteList.clear();

            //--2 Build list of Service Territory Members to insert
            //Get all new STM assignments not in current STM assignments and insert these     
            List <territoryMemberWrapper> insertSvcTerMemList = new List <territoryMemberWrapper>();
            List<ServiceTerritoryMember> servTerMemberInsertList = new List<ServiceTerritoryMember>();
            insertSvcTerMemList = compareCurrentToNewSvcTerMemLists( newSvcTerMemList,currentSvcTerMemWrapperList, true);
            
            //Destroy new and current lists
            newSvcTerMemList.clear();
            currentSvcTerMemWrapperList.clear();
            
            //Add insert list to STMObject
            for ( territoryMemberWrapper tm : insertSvcTerMemList) {             
                //tm.debug('insertSvcTerMemList'); //debug inserts
                servTerMemberInsertList.add(tm.getSTMObject());
            }
            System.debug('*** TDF_RefreshTerritories--> Inserting servTerMemberInsertList: '+servTerMemberInsertList.size());
            
            //Insert STM Records
            Database.Insert(servTerMemberInsertList);
            System.debug('*** TDF_RefreshTerritories--> Inserting Completed!');
            
            //Destroy insert list
            servTerMemberInsertList.clear();
        }
              
        System.debug('<<<<<< END TDF_RefreshTerritories--> - RefreshByServiceTerritoryId() - serviceTerritoryId: ' +serviceTerritoryId);

    }

    //
    // Compare the list of New Service Territory Members with the List of Current Service Territory Members to determine which records to insert and delete.
    //
    public static List <territoryMemberWrapper>  compareCurrentToNewSvcTerMemLists( List <territoryMemberWrapper> list1,  List <territoryMemberWrapper> list2, Boolean isInsert)
    {

        Map<String, territoryMemberWrapper> membersMap1 = new Map<String, territoryMemberWrapper>();
        Map<String, territoryMemberWrapper> membersMap2 = new Map<String, territoryMemberWrapper>();

        //Create map of list2 to look up on
        for(territoryMemberWrapper o : list2)
        {
            membersMap2.put(o.key, o);
        }

        List <territoryMemberWrapper> membersInList1ButNotList2 = new List <territoryMemberWrapper>();
        
        Integer iNewSTM = 0;
        
        //Loop through list1 and see if in list2. If so add to output list
        for(territoryMemberWrapper o : list1)
        {
            if (!membersMap2.containsKey(o.key) && iNewSTM < 500){ //AJ 3.3.18 Enhance. Restrict inserts to 500 max
                membersInList1ButNotList2.add(o);
                if(isInsert)
                    iNewSTM += 1;  
            }
        }

        return membersInList1ButNotList2;
    }

    public class assignmentResourceWrapper {
        public String AssignmentResourceId { get; set; }
        public String ServiceResourceId { get; set; }
        public String ServiceAppointmentId { get; set; }
        public DateTime SchedStartTime { get; set; }
        public String ServiceTerritoryId { get; set; }
        public String ServiceTerritoryName { get; set; }
        public String ServiceTerritoryTimeZone { get; set; }
        public String StartHour { get; set; }
        public DateTime AssignedStart { get; set; }
        public DateTime AssignedEnd { get; set; }
        public String SubTerritoryId { get; set; }
        public String key {get;set; }

        public assignmentResourceWrapper() {
            AssignmentResourceId = '';
            ServiceResourceId = '';
            ServiceAppointmentId = '';
            SchedStartTime = DateTime.Now();
            ServiceTerritoryId = '';
            ServiceTerritoryName = '';
            ServiceTerritoryTimeZone = '';
            StartHour = '';
            AssignedStart = DateTime.Now();
            AssignedEnd = DateTime.Now();
            SubTerritoryId = '';
            key = '';
        }
        
        //arw debug
        public void debug(String context) {
           System.Debug('*** ' + context + ', SRId:' + AssignmentResourceId + ', SchedStartTime:' + SchedStartTime + ', Territory Id:' + ServiceTerritoryId + ', Start Hour:' + StartHour + ', Assign Start:' + AssignedStart + ', Assign End:' + AssignedEnd + ', Sub Ter Id:' + SubTerritoryId);
       }
     
    }

    public class territoryMemberWrapper{
        public Id id { get; set; }
        public String ServiceResourceId { get; set; }
        public DateTime EffectiveStartDate { get; set; }
        public DateTime EffectiveEndDate { get; set; }
        public String ServiceTerritoryId { get; set; }
        public String key {get;set; }
        public ServiceTerritoryMember STMObject {get;set; }
        public ServiceTerritory STObject {get;set; }

        public territoryMemberWrapper(){
            ServiceResourceId = '';
            ServiceTerritoryId = '';
            EffectiveStartDate = DateTime.Now();
            EffectiveEndDate = DateTime.Now();
            key = '';
            STMObject = new ServiceTerritoryMember();
            STObject = new ServiceTerritory();
        }

        public ServiceTerritoryMember getSTMObject(){
            STMObject.Id = this.Id;
            STMObject.ServiceResourceId = this.ServiceResourceId;
            STMObject.EffectiveStartDate = this.EffectiveStartDate;
            STMObject.EffectiveEndDate = this.EffectiveEndDate;
            STMObject.TerritoryType = 'S';
            STMObject.ServiceTerritoryId = this.ServiceTerritoryId;
            return STMObject;
        }

        public ServiceTerritoryMember getSTMObjectForDelete(){
            STMObject.Id = this.Id;
            return STMObject;
        }

        public String getKey(){
            //####
            TDF_Settings__c objTDFSetting = TDF_Settings__c.getOrgDefaults();
            Integer refreshTerritoryExpiry = Integer.valueof(objTDFSetting.Refresh_Territory_Expiry__c)*-1;
            //####
            String AssignedStartKeyValue = '';
            //If start date of assignment is prior to Refresh Expiry (e.g. 7 days prior) then use 1970 value
            //This prevents the need to unnessarily delete and insert a new record for first STM record
            if(EffectiveStartDate < DateTime.Now().addDays(refreshTerritoryExpiry))
                AssignedStartKeyValue = String.valueOf(DateTime.newInstance(0));
            else
                AssignedStartKeyValue = String.valueOf(EffectiveStartDate);

            return ServiceResourceId+AssignedStartKeyValue+EffectiveEndDate+ServiceTerritoryId;

        }

        //stm debug
        public void debug(String context){
            System.Debug('*** ' +context+ ' --> KEY: ' + key + ', SvcTerMemId: ' +Id+ ', ServiceResourceId:' +ServiceResourceId+ ', ServiceTerritoryId:' +ServiceTerritoryId+ ', EffectiveStartDate:' +EffectiveStartDate+ ', EffectiveEndDate:' +EffectiveEndDate);
        }

    }

}