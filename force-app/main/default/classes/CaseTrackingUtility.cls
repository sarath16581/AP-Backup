/**************************************************
Type:       Utility class for Case Status Tracking objects.       
Purpose:    Handle the creating and updating of StatusTracking__c object related to the Case.
Used by:    CaseTrigger, SSSWFaxUtility class    
History:
--------------------------------------------------
23.09.2013  C. Andronaco (Bluewolf) Created. 
16.12.2013  A. Tran (Bluewolf)      Updated to handle any SSSW record types, calculate duration based 
                                    on StartDate and EndDate instead of CreatedDate and current time.
28-May-2015  scherukuwada@salesforce.com   Added LIMIT 100 
29-May-2015  C.McIntyre - Added LIMIT to open queries as part of apex audit.
21-Jul-2015  E.Shen & N.Narasappa           ----Open up case tracking for USQ case type
2018-08-08   disha.kariya@auspost.com.au    Commented out code called from Inactive Trigger
2021-05-14   naseer.abbasi@auspost.com.au   Removed references for User Support Queries Case RT                                    
**************************************************/

public without sharing class CaseTrackingUtility 
{
    private static final String AWAITING_NETWORK_STATUS = 'Awaiting Network Response';
    private static Integer counter = 0; 
    public static boolean hasStatusChanged=false;
    private static final String SSSW = 'SSSW';
    private static final Map<String,String> CASE_REC_TYPE_MAP = new Map<String,String>{ 'SSSW' => 'SSSW General'}; //record type mapping 21-Jul-2015  E.Shen & N.Narasappa
    // public static boolean newTrackingAdded {
    //   get {
    //     if(newTrackingAdded == null) {
    //       newTrackingAdded=false;
    //     }
    //     return newTrackingAdded;
    //   } private set;
    // }
    
    private static Map<String, StatusTracking__c> fieldsChangedToStatusTracking = new Map<String, StatusTracking__c>();
        
    private static Set<String> stopStatusSet = null;
    private static Set<String> closedStatusSet = null;
    private static BusinessHours defaultHours = null;
    private static Map<String,Id> bHMap = null;
            
    static Map<id, StatusTracking__c> cachedNotCompletedStatusTrackings {get{if(cachedNotCompletedStatusTrackings == null) cachedNotCompletedStatusTrackings = new Map<id, StatusTracking__c>(); return cachedNotCompletedStatusTrackings;}}
    public static List<StatusTracking__c> getNotCompletedStatusTrackingsFromCache(Set<id> keys) {
      List<StatusTracking__c> result = new List<StatusTracking__c>();
    if(!keys.isEmpty()){
      Set<id> notLoadedKeys = new Set<id>();
        for(id key: keys){
          if(cachedNotCompletedStatusTrackings.containsKey(key)){
            if(cachedNotCompletedStatusTrackings.get(key) != null) {
              result.add(cachedNotCompletedStatusTrackings.get(key));
            }
          }else{
            notLoadedKeys.add(key);
            cachedNotCompletedStatusTrackings.put(key, null);
          }
        }
        if(!notLoadedKeys.isEmpty()){
        for(StatusTracking__c r: [Select Id, Case__c, Name, Duration__c, BusinessHours__c, Fax__c, StatusValue__c, CreatedDate, StartDate__c, EndDate__c, SubsequentStatusValue__c from StatusTracking__c where Case__c in :notLoadedKeys and Duration__c = null]){
          result.add(r);
          cachedNotCompletedStatusTrackings.put(r.id, r);
        }
      }
    }
    return result;
    }
            
    public static void updateCaseStatusTracking(Map<Id,Case> oldCases, Map<Id,Case> newCases) 
    {
      system.debug('========================================= updateCaseStatusTracking ===================================\n\n');
      
    Set<Id> validRecordTypeIds = getCaseSSSWRecordTypeId();
    Map<Id, Case> shortListed = new Map<Id, Case>();               
    for (Case c : newCases.values()) {  
        
        System.debug('** c ==>'+ c);
        System.debug('** old ==>'+ oldCases.get(c.Id));
        if (validRecordTypeIds.contains(c.RecordTypeId) &&
             (oldCases.get(c.Id).OwnerId != c.OwnerId || 
                oldCases.get(c.Id).Status != c.Status || 
                (oldCases.get(c.Id).Network__c != c.Network__c && c.Status == AWAITING_NETWORK_STATUS) ||
                oldCases.get(c.Id).NetworkComments__c != c.NetworkComments__c ||
                oldCases.get(c.Id).Network_Response__c != c.Network_Response__c)) {
            shortListed.put(c.Id, c);
        }                                                           
    }
    if (!shortListed.isEmpty()) {
                    
        Map<id, StatusTracking__c> newTrackingList = new Map<id, StatusTracking__c>();
        List<StatusTracking__c> oldTracking = new List<StatusTracking__c>();
        Map<Id, List<StatusTracking__c>> allTracking = new Map<Id, List<StatusTracking__c>>();
        Map<Id, User> caseOwnerList = new Map<Id, User>();
      Map<Id, Group> caseQueueList = new Map<Id, Group>();
        
        getOwnerMap(shortListed, caseOwnerList, caseQueueList);
        
        //Retreive the Business Hours List
        if (bHMap == null) {
          bHMap = new Map<String,Id>();
          for (BusinessHours bHour: [Select Id, Name, TimeZoneSidKey from BusinessHours LIMIT 100]) {
              bHMap.put(bHour.Name, bHour.Id);     
          }
        }
        
        //Retrieve all Tracking Records for the Cases that have had an update.
        for(StatusTracking__c curTracking: getNotCompletedStatusTrackingsFromCache(shortListed.keyset())) {                
            if (allTracking.get(curTracking.Case__c) == null) {
                allTracking.put(curTracking.Case__c, new List<StatusTracking__c>());
            }
            allTracking.get(curTracking.Case__c).add(curTracking);                             
        }   
        
        
        Id statusRTId ;   //= getSSSWStatusTrackingRT();                  
        for (Id caseId : shortListed.keySet()) {
            Case newCase = shortListed.get(caseId);
            Case oldCase = oldCases.get(caseId);
            
            String fieldList = '';
            String OwnerId = newCase.OwnerId;
            String OwnerTZ = '';
            String OwnerName = '';
            
            // Eric Shen - 15-Jul-2015 : Open up for User Support Case
            String recTypeName = getRecordTypeName(newCase.RecordTypeId);
            if(String.isNotBlank(recTypeName)){
                statusRTId = getSSSWStatusTrackingRT(SSSW);
            }
            
            //Case Owner Details are for User Only          
            if (OwnerId.startsWith('005')) {
                OwnerName = caseOwnerList.get(newCase.OwnerId).Name;
                OwnerTZ = caseOwnerList.get(newCase.OwnerId).TimeZoneSidKey;
            }
        else
        {
          OwnerName = caseQueueList.get(newCase.OwnerId).Name;
        }
            // owner changed
            if (oldCase.OwnerId != newCase.OwnerId) {
              system.debug('New owner name: ' + ownerName);
              
                fieldList += 'Owner';
            }
            // status changed
            if (oldCase.Status != newCase.Status) {
                fieldList += '; Status';
            }
            // facility changed
            if (oldCase.Network__c != newCase.Network__c && newCase.Status == AWAITING_NETWORK_STATUS) {
                fieldList += '; Network';
            }
            
            //Daniel Garzon 12/05/2015. New fields for tracking. BEGIN 
            //Network Comments has changed
            if (oldCase.NetworkComments__c != newCase.NetworkComments__c) {
                fieldList += '; Network Comments';
            }
            
            //Network Response has changed
            if (oldCase.Network_Response__c != newCase.Network_Response__c) {
                fieldList += '; Network Response';
            }
            //END
            
            System.debug('fieldList : ' + fieldList);
            // A field has been specified and now a Tracking Record must be added.
            if (fieldList.length() > 0) {
                if (fieldList.startsWith(';')) {
                    //Remove the first ;, as it indicates the Owner is not first.
                    fieldList.replaceFirst('; ', '');
                }
                
                addNewTracking(newTrackingList, newCase, fieldList, OwnerName, getsopsBusinessHoursId(bHMap, OwnerTZ), statusRTId);
                
                //Associated Open Tracking Needs to be updated.                     
                if (allTracking.containsKey(caseId)) {
                    for (StatusTracking__c oldT : allTracking.get(caseId)) {
                        if (String.isBlank(oldT.SubsequentStatusValue__c) && fieldList.containsIgnoreCase('Status')) {
                          oldT.SubsequentStatusValue__c = newCase.Status;
                        }
                        oldTracking.add(oldT);
                    }
                }
            }
                            
        }
        
        List<StatusTracking__c> newTrackings = new List<StatusTracking__c>();
        for (StatusTracking__c st : newTrackingList.values()) {
          if (!fieldsChangedToStatusTracking.containsKey(st.FieldsChanged__c)) {
            fieldsChangedToStatusTracking.put(st.FieldsChanged__c, st);
            newTrackings.add(st);
          }
        }
        
        System.debug('---newTrackingList: ' + newTrackingList);
        System.debug('---newTrackings: ' + newTrackings);
        
        if (!newTrackings.isEmpty()) {     
            if (!SSSWFaxUtility.isFax) {
              for(StatusTracking__c t: newTrackings){
                system.debug('t.ownerid__c: ' + t.ownerid__c);
              }
                upsert newTrackings;
            }                    
            updateOldTracking(oldTracking);
        }
    }  
    }
    
    // Commented as this method is called in Inactive Trigger CaseTrigger
    // public static void setStatusTracking(Map<Id,Case> newMap, Map<Id,Case> oldMap){
    // //Get the stop statuses
    // if (stopStatusSet == null) {
    //       stopStatusSet = new Set<String>();
    //       for (Stop_Status__c stopStatus:[Select Name From Stop_Status__c LIMIT 100]) {
    //           stopStatusSet.add(stopStatus.Name);
    //       }
    // }

    //     //Get the default business hours (we might need it)
    //     if (defaultHours == null) {
    //       defaultHours = [select Id from BusinessHours where IsDefault=true];
    //     }

    //     //Get the closed statuses (because at the point of this trigger Case.IsClosed won't be set yet)
    //     if (closedStatusSet == null) {
    //       closedStatusSet = new Set<String>();
    //       for (CaseStatus status:[Select MasterLabel From CaseStatus where IsClosed=true]) {
    //           closedStatusSet.add(status.MasterLabel);
    //       }
    //     }
        
    //     //For any case where the status is changed, recalc the business hours in the buckets
    //     for (Case updatedCase: newMap.values()) {
    //         Case oldCase = oldMap.get(updatedCase.Id);

    //         if (oldCase.Status!=updatedCase.Status && updatedCase.Last_Status_Change__c!=null) {
    //           //CaseTrackingUtility.hasStatusChanged = true;
    //             //OK, the status has changed
    //             if (!oldCase.IsClosed) {
    //                 //We only update the buckets for open cases

    //       //On the off-chance that the business hours on the case are null, use the default ones instead
    //                 Id hoursToUse = updatedCase.BusinessHoursId!=null?updatedCase.BusinessHoursId:defaultHours.Id;

    //                 //The diff method comes back in milliseconds, so we divide by 3600000 to get hours.
    //                 Double timeSinceLastStatus = BusinessHours.diff(hoursToUse, updatedCase.Last_Status_Change__c, System.now())/3600000.0;
    //                 System.debug(timeSinceLastStatus);

    //                 //We decide which bucket to add it to based on whether it was in a stop status before
    //                 if (stopStatusSet.contains(oldCase.Status)) {
    //                     updatedCase.Time_With_Customer__c += timeSinceLastStatus;
    //                 } else {
    //                     updatedCase.Time_With_Support__c += timeSinceLastStatus;
    //                 }

    //       if (closedStatusSet.contains(updatedCase.Status)) {
    //           updatedCase.Case_Age_In_Business_Hours__c = updatedCase.Time_With_Customer__c + updatedCase.Time_With_Support__c;
    //       }
    //             }

    //             updatedCase.Last_Status_Change__c = System.now();
    //         }
    //     }
    // }
    
    // public static void setLastStatusChange(List<Case> cases){
    // for (Case c: cases) {
    //         c.Last_Status_Change__c = System.now();
    //         c.Time_With_Customer__c = 0;
    //         c.Time_With_Support__c = 0;
    //     }
    // }
    
    public static Set<Id> SSSWCaseRecordTypeIds
    {
        get {
            if (SSSWCaseRecordTypeIds == null) {
                List<RecordType> recordTypes = [select id from RecordType where SObjectType='Case' and Name like '%SSSW%'];          
                Set<Id> rtIds = new Set<Id>();
                
                for (RecordType rt : recordTypes)
                {
                    rtIds.add(rt.Id);
                }
        
                SSSWCaseRecordTypeIds = rtIds;
            }
            
            return SSSWCaseRecordTypeIds;
        }
        private set;
    }  
    
    // Commented Method as it is no more used in the class
    // public static Id getSSSWStatusRecordTypeId() 
    // {
    //     Id rtId = [select id from RecordType where SObjectType='StatusTracking__c' and Name='SSSW General' limit 1].Id; 
    //     return rtId;
    // }
    
    // public static void caseMapbyRTId(Map<Id, Case> allCases, Map<Id, Case> rTCases, Set<Id> RTIds)
    // {
    //     for (Case c : allCases.values()) 
    //     {                               
    //         if (RTIds.contains(c.RecordTypeId)) 
    //         {
    //             rTCases.put(c.Id, c);             
    //         }       
    //     }
    // }
    
    static Map<id, User> cachedUsers {get{if(cachedUsers == null) cachedUsers = new Map<id, User>(); return cachedUsers;}}
    public static List<User> getUsersFromCache(Set<id> keys) {
      List<User> result = new List<User>();
    if(!keys.isEmpty()){
      Set<id> notLoadedKeys = new Set<id>();
        for(id key: keys){
          if(cachedUsers.containsKey(key)){
            if(cachedUsers.get(key) != null) {
              result.add(cachedUsers.get(key));
            }
          }else{
            notLoadedKeys.add(key);
            cachedUsers.put(key, null);
          }
        }
        if(!notLoadedKeys.isEmpty()){
        for(User r: [Select Id, Name, TimeZoneSidKey from User where Id in:notLoadedKeys]){
          result.add(r);
          cachedUsers.put(r.id, r);
        }
      }
    }
    return result;
    }
    
    public static void getOwnerMap(Map<Id,Case> caseMap, Map<Id,User> userMap, Map<id,Group> queueMap)
    {
        //Retreive the Case Owner IDs and User Names from the Trigger Map.
        for (Case caseOwner : caseMap.values())
        {   
            userMap.put(caseOwner.OwnerId, null);
        }

        for(User ownerItem: getUsersFromCache(userMap.keyset()))
        {
            userMap.put(ownerItem.Id,ownerItem);
        }

        queueMap = Utility.getGroups('Queue');
    }
        
    //Holds status trackings created in this transaction    
    private static Map<Id, StatusTracking__c> cachedStatusTrackings = new Map<Id, StatusTracking__c>();
    
    public static void addNewTracking(Map<id, StatusTracking__c> newTrackingItems, Case changedCase, String fieldList, String ownerName, Id bHours, Id statusRTId)
    {
      
        //Check for facility
        Id facility = null;
        if (changedCase.Status == AWAITING_NETWORK_STATUS && changedCase.Network__c != null) {
            facility = changedCase.Network__c;
        } 
        
        if(newTrackingItems.get(changedCase.id) == null) {
          //Create the child record for Status Tracking. 
          string tempOwnerId = changedCase.ownerId;
          system.debug('tempOwnerId: ' + tempOwnerId);
          //Daniel Garzon 12/05/2015. New fields for tracking "NetworkCommentsValue__c" and "Network_Response__c". 
          StatusTracking__c st = cachedStatusTrackings.get(changedCase.Id);
          if (st == null) {
            st = new StatusTracking__c();
            cachedStatusTrackings.put(changedCase.Id, st);
          }
          
          st.Name = DateTime.now().format('dd-MM-yyyy hh:mm:ss a');
          st.OwnerId__c = tempOwnerId;
          st.OwnerName__c = ownerName;
          st.StatusValue__c = changedCase.Status;
          if (String.isBlank(st.Case__c)) {
            st.Case__c =  changedCase.id;
          }
          st.FieldsChanged__c = fieldList;
          st.BusinessHours__c = bHours;
          st.RecordTypeId = statusRTId;
          st.CreatedDateList__c = DateTime.now();
          st.StartDate__c = DateTime.now();
          st.network__c = facility;
          st.NetworkCommentsValue__c = changedCase.NetworkComments__c;
          st.NetworkResponseValue__c = changedCase.Network_Response__c;           
          
          if (tempOwnerId.startsWith(User.sobjectType.getDescribe().getKeyPrefix())) {
            st.Agent__c = tempOwnerId;
          }
          newTrackingItems.put(changedCase.id, st);
        }
    }
    
    public static StatusTracking__c newFaxTracking(Case changedCase, String fieldList, DateTime startDate, Id fax, String ownerTZ, String ownerName)
    {
        Id statusRTId ;//= getSSSWStatusRecordTypeId();
        
        // Eric Shen - 15-Jul-2015 : Open up for User Support Case
        String recTypeName = getRecordTypeName(changedCase.RecordTypeId);
        if(String.isNotBlank(recTypeName)){
            statusRTId = getSSSWStatusTrackingRT(SSSW);
        }
          
        //Retreive the Business Hours List
        if (bHMap == null) {
          bHMap = new Map<String,Id>();
          for (BusinessHours bHour: [Select Id, Name, TimeZoneSidKey from BusinessHours LIMIT 100])
          {
              bHMap.put(bHour.Name,bHour.Id);     
          }
        }
        Id bHours = getsopsBusinessHoursId(bHMap, ownerTZ);
            
        //Create the child record for Status Tracking. 
        StatusTracking__c newTrackingItem = new StatusTracking__c(Name = startDate.format('dd-MM-yyyy hh:mm:ss a'), 
                                                                    OwnerId__c = changedCase.OwnerId, 
                                                                    OwnerName__c = ownerName,
                                                                    StatusValue__c = changedCase.Status, 
                                                                    Case__c =  changedCase.id, 
                                                                    FieldsChanged__c = fieldList, 
                                                                    BusinessHours__c = bHours,
                                                                    RecordTypeId = statusRTId,
                                                                    CreatedDateList__c = DateTime.now(),
                                                                    StartDate__c = startDate,
                                                                    Fax__c = fax);
        
        return newTrackingItem;
    }
        
    // Commented as this method is called in Inactive Trigger CaseTrigger
    // public static void insertCaseStatusTracking(Map<Id,Case> newCases) 
    // {
    //     if (newCases.size() > 0)
    //     {
    //         Map<id, StatusTracking__c> newTrackingList = new Map<id, StatusTracking__c>();
    //         Map<Id,User> caseOwnerList = new Map<Id,User>();
    //   Map<Id, Group> caseQueueList = new Map<Id, Group>();
    //         Id statusRTId; //= getSSSWStatusRecordTypeId();
            
            

    //         String OwnerId = '';
    //         String OwnerTZ = '';
    //         String OwnerName = '';  
            
    //         //Retreive the Business Hours List
    //         if (bHMap == null) {
    //           bHMap = new Map<String,Id>();
    //           for (BusinessHours bHour: [Select Id, Name, TimeZoneSidKey from BusinessHours LIMIT 100])
    //           {
    //               bHMap.put(bHour.Name,bHour.Id);     
    //           }
    //         }
            
    //         getOwnerMap(newCases, caseOwnerList, caseQueueList);
            
    //         //System.debug('###BW###:INSERTsopsCaseList-Size:' + newCases.size());
    //         for (Case c : newCases.values()) 
    //         {   
    //             OwnerId = newCases.get( c.id ).Ownerid;
                
    //             // Eric Shen - 15-Jul-2015 : Open up for User Support Case
    //             String recTypeName = getRecordTypeName(c.RecordTypeId);
    //             if(String.isNotBlank(recTypeName)){
    //                 statusRTId = recTypeName.contains(SSSW) ? getSSSWStatusTrackingRT(SSSW) :
    //                                 recTypeName.contains(USQ) ? getSSSWStatusTrackingRT(USQ) : getSSSWStatusTrackingRT(SSSW);
    //             }
                
    //             //Case Owner Details are for User Only          
    //             if (OwnerId.startsWith('005'))
    //             {
    //                 OwnerName = caseOwnerList.get(newCases.get( c.id ).Ownerid).Name;
    //                 OwnerTZ = caseOwnerList.get(newCases.get( c.id ).Ownerid).TimeZoneSidKey;
    //             }
    //     else
    //     {
    //       OwnerName = caseQueueList.get(newCases.get( c.id ).Ownerid).Name;
    //     }
                
    //             //As this is a new Case (insert) all will require a new Case Status record to be created.
    //             addNewTracking(newTrackingList, c, 'Owner; Status', OwnerName, getsopsBusinessHoursId(bHMap, OwnerTZ), statusRTId);                   
    //         }
            
    //         if (newTrackingList.size() > 0)
    //         {
    //             upsert newTrackingList.values();
    //             newTrackingAdded = true;
    //         }
    //     }
    // } 
    
    /**
      * @description       This method returns case record type name based on id
      * @param             recTypeId - Record Type Id
      * @return            String
      * @throws            NA
      */   
    private static String getRecordTypeName(Id recTypeId){
        String retVal;
       DescribeSObjectResult result = Case.sObjectType.getDescribe();   //adjust schema.sobjectype             
        Map<Id, Schema.RecordTypeInfo> recordTypeInfo = result.getRecordTypeInfosById();
        if(recordTypeInfo.get(recTypeId) != null){
            retVal = recordTypeInfo.get(recTypeId).getName();
        }
        return retVal;
    }
    
    // get all Case Record Type Ids with Name containing 'SSSW'
    public static Set<Id> getCaseSSSWRecordTypeId(){
        Set<Id> returnIds = new Set<Id>(); 
        DescribeSObjectResult result = Schema.getGlobalDescribe().get('Case').getDescribe();                
        Map<String, Schema.RecordTypeInfo> recordTypeInfo = result.getRecordTypeInfosByName();
        for (String rtName : recordTypeInfo.keySet()) {
            if (rtName.contains('SSSW')) {  
                returnIds.add(recordTypeInfo.get(rtName).getRecordTypeId());
            }   
        }        
        return returnIds;                
    }
    
    // get Status Tracking SSSW General Record Type Id
    public static Id getSSSWStatusTrackingRT(String recType) {
        Id recTypeId;
        DescribeSObjectResult result = Schema.getGlobalDescribe().get('StatusTracking__c').getDescribe();               
        Map<String, Schema.RecordTypeInfo> recordTypeInfo = result.getRecordTypeInfosByName();
        
        // Eric Shen - 15-Jul-2015 : Open up for User Support Case
        if(CASE_REC_TYPE_MAP.get(recType) != null && recordTypeInfo.get(CASE_REC_TYPE_MAP.get(recType)) != null){
            recTypeId = recordTypeInfo.get(CASE_REC_TYPE_MAP.get(recType)).getRecordTypeId();
        }
        else{
            recTypeId = recordTypeInfo.get('SSSW General').getRecordTypeId();
        }
        return recTypeId;
        //return recordTypeInfo.get('SSSW General').getRecordTypeId();    //  Eric Shen - 15-Jul-2015 : Commented to Open up for User Support Case   
    }

    public static Id getsopsBusinessHoursId(Map<String,Id> bHours, String ownerTZ) 
    {
        //This function will only work for Sales Operations configured Business Hours. 
        Id businessHourId;
        
        if (ownerTZ != null)
        {
            if (ownerTZ.contains('Brisbane'))
            {
                businessHourId = bHours.get('SSSWBrisbane');
            }
            else if (ownerTZ.contains('Perth'))
            {
                businessHourId = bHours.get('SSSWPerth');
            }
            else if (ownerTZ.contains('Adelaide'))
            {
                businessHourId = bHours.get('SSSWAdelaide');
            }
            else if (ownerTZ.contains('Darwin'))
            {
                businessHourId = bHours.get('SSSWDarwin');
            }
            else
            {
                businessHourId = bHours.get('SSSWSydney');
            }       
        }
        else
        {
            businessHourId = bHours.get('SSSWSydney');
        }   
    
        return businessHourId;
    }   

    public static void updateOldTracking(List<StatusTracking__c> oldTracking) 
    {              
        for (StatusTracking__c oldTrackingItem : oldTracking) 
        {
            if (oldTrackingItem.EndDate__c == null) {
                oldTrackingItem.EndDate__c = DateTime.now();
            }
            
            //DateTime endTracking = oldTrackingItem.EndDate__c != null ? oldTrackingItem.EndDate__c : DateTime.now();
            double durationSeconds = 0;

            oldTrackingItem.Duration__c = BusinessHours.diff(oldTrackingItem.BusinessHours__c, oldTrackingItem.StartDate__c, oldTrackingItem.EndDate__c);
            
            //Business Hours returns milliseconds. Conver to Seconds.
            durationSeconds = oldTrackingItem.Duration__c / 1000;
            //System.debug('###BW###:durationSeconds:' + durationSeconds);

            //Seconds in Hour   
            oldTrackingItem.DurationHours__c = (integer)(durationSeconds / 3600); 
            //System.debug('###BW###:DurationHours__c:' + oldTrackingItem.DurationHours__c);
            
            //Filter Number of Hours out of total seconds.
            durationSeconds = durationSeconds - (oldTrackingItem.DurationHours__c * 3600);
            //System.debug('###BW###:DurationHours__c-Remaining:' + durationSeconds);
            
            //Seconds in Remaining Minutes  
            oldTrackingItem.DurationMins__c = (integer)(durationSeconds / 60);  
            //System.debug('###BW###:DurationMins__c:' + oldTrackingItem.DurationMins__c);
            
            //Filter Number of Minutes out of remaining seconds.
            durationSeconds = durationSeconds - (oldTrackingItem.DurationMins__c * 60);
            //System.debug('###BW###:DurationMins__c-Remaining:' + durationSeconds);
            
            //Remaining Seconds.
            oldTrackingItem.DurationSeconds__c = (integer)durationSeconds;
            //System.debug('###BW###:DurationSeconds__c:' + oldTrackingItem.DurationSeconds__c);
        }

        update oldTracking;
    }   
}