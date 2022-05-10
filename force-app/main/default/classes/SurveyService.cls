/***
 * @author Ken McGuire
 * @date 2022-04-26
 * @description Enques Survey invitations for a specified SObject according to entry criteria as specified in metadata. 
 * @changelog
 */
public inherited sharing class SurveyService {

   	/*
	 * Creates a new instance of the utility to facilitate dependency injection for mocking
	 * @return the new instance
	 */
	public static SurveyService getInstance() {
        
		return (SurveyService) Application.Utilities.getInstance(SurveyService.class);

	}
    
    // Manages the entry conditions for survey invitations
    EntryConditions surveyEntryConditions{
        get {
            if (surveyEntryConditions == null) surveyEntryConditions = EntryConditions.getInstance();
            return surveyEntryConditions;
        }
        set;
    }
    
        // Maps a Survey Name to an environment specific Survey Invitation Id
    private Map<String,Integer> surveyInvitationIdMap {
        get {
            if (surveyInvitationIdMap == null) surveyInvitationIdMap = new Map<String,Integer>();
            return surveyInvitationIdMap;
        }
        set;
    }
   	
    // Maps a specified SObject API Name to the list of Survey names that are applicable to that SObject. 
	private Map<String, List<String>> sObjectSurveyMap{
        get {
            if (sObjectSurveyMap == null) sObjectSurveyMap = new Map<String, List<String>>();
            return sObjectSurveyMap;
        }
        set;
    } 

	// Maps an SObject API Name to another map which links the Id of a record to a Survey Name in the case that 
	// entry criteria have been met by the record for the Survey.
	private Map<String,Map<Id,String>> enquedSurveyInvitationsMap{
        get {
            if (enquedSurveyInvitationsMap == null) enquedSurveyInvitationsMap = new Map<String,Map<Id,String>>();
            return enquedSurveyInvitationsMap;
        }
        set;
    }

    //Maps a specified sObject API Name to a list of metadata which defines surveys and their entry critera
	@TestVisible private Map<String,List<SurveyInvitation__mdt>> surveysMetadataMap{
        get {
            if (surveysMetadataMap == null) surveysMetadataMap = new Map<String,List<SurveyInvitation__mdt>>();
            return surveysMetadataMap;
        }
        set;
    }
    
	//Maps the metadata API Name to the metadata which defines static entry criteria for SOBjects
	@TestVisible private Map<String,EntryCondition__mdt> staticEntryConditionsMetadataMap{
        get {
            if (staticEntryConditionsMetadataMap == null) staticEntryConditionsMetadataMap = new Map<String,EntryCondition__mdt>();
            return staticEntryConditionsMetadataMap;
        }
        set;
    }
    
    /*
	 * Adds qualifying records to the queue of survey invitations to be sent out.
	 * @param records The specified SObject records to test
	 * @param records The existing record values in the case of updates
	 * @return a list of record Ids for those records which have been enqued for survey inviations
	 */
	public Set<Id> enqueSurveyInvitations(List<SObject> records, Map<Id, SObject> existingRecords) {
		
        Set<id> recordsAdded = new Set<Id>();
    	    
        if (recordsInvalid(records)) return recordsAdded; 
        
      	string sObjectApiName = string.ValueOf(records[0].id.getSobjectType());
        string staticEntryConditionsName = getStaticEntryConditionsName(sObjectApiName);
        boolean isFiltered = staticEntryConditionsName != null;
       	List<SObject> filteredRecords =  isFiltered ?  getStaticFilteredSurveyInvitations(records, existingRecords,staticEntryConditionsName) : records;
		if (filteredRecords.size()==0) return recordsAdded;
        
        if (!sObjectSurveyMap.containsKey(sObjectApiName)) createSurveyEntryConditionsMap(sObjectApiName);
     	List<String> surveys = sObjectSurveyMap.get(sObjectApiName);
        if (surveys.size()==0) return recordsAdded;
        
        if (!enquedSurveyInvitationsMap.containsKey(sObjectApiName)) enquedSurveyInvitationsMap.put(sObjectApiName,new Map<Id,String>());
        
		for (SObject currentRecord : filteredRecords) {
            // isFiltered negates the need to check if the remaining conditions have changed to meet entry conditions 
        	SObject existingRecord =  isFiltered || existingRecords == null ? null : existingRecords.get(currentRecord.Id);
            if (enqueSurveyInvitation(currentRecord,existingRecord,sObjectApiName)) recordsAdded.add(currentRecord.id);
        }
        
        return recordsAdded;

	}
    // sendInvitations method overloading
    public void sendInvitations(Map<Id,SObject> enquedRecordUpdates) {
        list<SObject> records = enquedRecordUpdates.values();
        if (recordsInvalid(records)) return;
        String sObjectApiName = String.ValueOf(records[0].id.getSobjectType());
        sendInvitations(sObjectApiName,enquedRecordUpdates);
    }
    
    // sendInvitations method overloading
    public void sendInvitations(String sObjectApiName) {
        sendInvitations(sObjectApiName,new Map<Id,SObject>());
    }
    
    /*
	 * Adds a qualifying record to the queue of survey invitations to be sent out.
	 * @param record The specified SObject record to test
	 * @return true if the record has met a survey entry condition, otherwise false
	 */
	private Boolean enqueSurveyInvitation(SObject record, SObject existingRecord, string sObjectApiName) {
        
        Map<Id,String> enquedSurveyInvitations = enquedSurveyInvitationsMap.get(sObjectApiName);
        
        if(enquedSurveyInvitations.containsKey(record.Id))
            return false;

        String surveyToSend = getFirstEntry(record,existingRecord,sObjectApiName);

        if (surveyToSend == null)
            return false;

		enquedSurveyInvitations.put(record.Id,surveyToSend);
        return true;
	}
    
    /*
	 * Iterates through all the surveys associatd with the specified SObject 
	 * and returns the first survey for a record that has changed in order to meet the entry criteria.
	 * @param record the SObject record to test for survey entry criteria.
	 * @param existingRecord the SObject records existing value in the case of an update
	 * @return The name of the first survey meeting entry criteria. Null if no survey entry criteria are met.
	 */
	private String getFirstEntry(SObject record, SObject existingRecord, String sObjectApiName) {		

		for (String currentSurveyName : sObjectSurveyMap.get(sObjectApiName)) {
			// On update, ensure that the record has changed from not meeting criteria to meeting criteria.
			if (hasChangedToMeetEntryConditions(record, existingRecord, currentSurveyName)) {
				return currentSurveyName;
			} 
		}
        
		return null;
	}
    
    
    /*
	 * Pre-filters records on the basis of static entry conditions that must be met before further
	 * tests are done to assess if any records meet entry criteria for any survey.
	 * @param records The specified SObject records to test
	 * @param records The existing record values in the case of updates
	 * @return a list of record Ids for those records which have been enqued for survey inviations
	 */
    private List<SObject> getStaticFilteredSurveyInvitations(List<SObject> records, Map<Id, SObject> existingRecords, String staticEntryConditionsName) {


        
       
        
        List<SObject> filteredRecords = new List<SObject>();
        
        for (SObject currentRecord : records) {

        	SObject existingRecord =  existingRecords == null ? null : existingRecords.get(currentRecord.Id);

            if (hasChangedToMeetEntryConditions(currentRecord,existingRecord, staticEntryConditionsName)) filteredRecords.add(currentRecord);
        }

        return filteredRecords;
	}
             
    /*
	 * determines if a record has changed to meet entry conditions
	 * @param record the SObject record to test for survey entry criteria.
	 * @param existingRecord the SObject records existing value in the case of an update
	 * @return truie if a record has changed to meet entry critera.
	 */
    private Boolean hasChangedToMeetEntryConditions(SObject record, SObject existingRecord, String surveyEntryConditionsName) {

		return surveyEntryConditions.meetsEntryConditions(surveyEntryConditionsName,record) && (existingRecord== null || surveyEntryConditions.meetsEntryConditions(surveyEntryConditionsName,existingRecord)==false);

	}

	/*
	 * Provides the environmental specific Survey Invitation ID for a specified Survey
	 * @param surveyInvitationName A user friendly name for the survey obtained from a list-type custom setting.
	 * @return the environmental specific Survey Invitation Id corresponding to the Survey Invitation Name
	 */
	private Integer getSurveyInvitationId(String surveyInvitationName) {

		if (surveyInvitationIdMap == null)
            surveyInvitationIdMap = new Map<String,Integer>();

        if (!surveyInvitationIdMap.containsKey(surveyInvitationName)) {
            SurveyInvitationIdMap__c invitationIdMap = SurveyInvitationIdMap__c.getValues(surveyInvitationName);
            if (invitationIdMap != null) surveyInvitationIdMap.put(surveyInvitationName, (Integer)invitationIdMap.SurveyInvitationId__c);
        }
           
		return surveyInvitationIdMap.get(surveyInvitationName);
	}
    
	/* Ensures that the SOBject records passed in for entry condition are appropriate for
	 * Survey entry criteria evaluation.
    * @param id The salesforce Id for a record passed in
    * @return true if the records ARE NOT valid.
    */
    
    private Boolean recordsInvalid(List<SObject> records) {
        
         return records == null || records.size()==0 || records[0].id == null;
        
    }
    
    /*
	 * Maps the records for which surveys are to be sent out with their 
	 * corresponding invitation Ids and enques them for sending.
	 * @param enquedRecordUpdates a map of record updates to execute on the successful sending of survey invitations 
	 * @return a list of record ids that have been successfully enqued
	 */
	private void sendInvitations(String sObjectApiName,Map<Id,SObject> enquedRecordUpdates) {
		// the difference between 'enquedRecordUpdates' and 'enquedSurveyInvitaions' is this:-
		// enqued survey invitations maps an object id to a corresponding survey for records that have previously met entry criteria.
		// enqued record updates maps an an object id to a corresponding SObject update to be applied once
		// the survey invitaitons have been sent out.
		
        if (!enquedSurveyInvitationsMap.containsKey(sObjectApiName)) return;
       	Map<Id,String> enquedSurveyInvitations = enquedSurveyInvitationsMap.get(sObjectApiName);
        
		if(enquedSurveyInvitations.size()==0) return;

		Map<Id,Integer> surveyInvitationMap = new Map<Id,Integer>();

        // records to update will contain a subset of enqued Record Updates, being only those records
		// which are included in the enqued survey invitations being sent out.
		Map<Id,SObject> recordsToUpdate = new Map<Id,SObject>();

		for (Id currentObjectId : enquedSurveyInvitations.keySet()) {

			// get the environment specific survey Id and add to the queue
			String surveyToSend = enquedSurveyInvitations.get(currentObjectId);
			surveyInvitationMap.put(currentObjectId, getSurveyInvitationId(surveyToSend));

			// record updates will only be sent if they have a corresponding enqued record.
            if (enquedRecordUpdates.containsKey(currentObjectId)) {
				recordsToUpdate.put(currentObjectId,enquedRecordUpdates.get(currentObjectId));
			}
		}

		if(surveyInvitationMap.size()>0) {

			SendSurveyInvitationsQueueable qb = new SendSurveyInvitationsQueueable(surveyInvitationMap,recordsToUpdate);
			System.enqueueJob(qb);

		}
	}

	/*
	* Initalises the surveys and entry criteria for the specified SObject
	*/
	private void createSurveyEntryConditionsMap(String sObjectApiName) {

		loadSurveyMetadata(sObjectApiName);
        List<SurveyInvitation__mdt> surveysMetadata = surveysMetadataMap.get(sObjectApiName);
		List<String> surveyNames = new List<String>();

		for(SurveyInvitation__mdt currentSurveyInvitation : surveysMetadata) {

			try {

				Map<String, Object> entryConditionsMap = (Map<String, Object>)JSON.deserializeUntyped(currentSurveyInvitation.EntryCondition__r.EntryConditionsJSON__c);

				surveyEntryConditions.createEntryConditions(currentSurveyInvitation.Label,entryConditionsMap,currentSurveyInvitation.EntryCondition__r.ConditionRequirements__c);
				surveyNames.add(currentSurveyInvitation.Label);

			} catch (Exception ex) {

				UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
				SurveyService.class.getName(), SSSWConstants.SSSW_APP, 
				SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);

			}
		}
        sObjectSurveyMap.put(sObjectApiName,surveyNames);
	}
    
	/*
	* A fast load of metadata specifying static entry conditions that all SObjects must meet
	* The entry conditions JSON in this case must be less than 255 characters and
	* The Metadata API name must match exactly 'Static_[objectAPIName]_Survey'. Example 'Static_Case_Survey' 
	*/
	private void createStaticEntryConditions(String staticEntryConditionsName) {

        if (!staticEntryConditionsMetadataMap.containsKey(staticEntryConditionsName)) 
            staticEntryConditionsMetadataMap.put(staticEntryConditionsName,EntryCondition__mdt.getInstance(staticEntryConditionsName));
		
        EntryCondition__mdt staticEntryConditionsMetadata = staticEntryConditionsMetadataMap.get(staticEntryConditionsName); 
		if(staticEntryConditionsMetadata == null) return;
    	
        try {
            
        	Map<String, Object> entryConditionsMap = (Map<String, Object>)JSON.deserializeUntyped(staticEntryConditionsMetadata.EntryConditionsJSON__c);
            surveyEntryConditions.createEntryConditions(staticEntryConditionsName,entryConditionsMap,staticEntryConditionsMetadata.ConditionRequirements__c);
        
		} catch (Exception ex) { // TODO Exception logging needs bulkificated. Can use ApplicationLogger class when its deployed into Production

            UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), SSSWConstants.SSSW_APP, 
            SurveyService.class.getName(), SSSWConstants.SSSW_APP, 
            SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
        
		}
	}
    

	/*
	* Queries the metadata for surveys and entry criteria that are relevant to the specified SObject.
	* @param SObjectName  the API name of the data object to test as specified in survey metadata
	*/
	private void loadSurveyMetadata(String sObjectApiName) {
		
        if(surveysMetadataMap.containsKey(sObjectApiName)) return;
        
		List<SurveyInvitation__mdt> surveysMetadata = [SELECT Label,EntryCondition__r.ConditionRequirements__c,EntryCondition__r.EntryConditionsJSON__c 
				FROM SurveyInvitation__mdt 
			   	WHERE DataObjectAPIName__c =  :sObjectApiName];
        
        surveysMetadataMap.put(sObjectApiName,surveysMetadata);
	}

    private String getStaticEntryConditionsName(String SObjectApiName) {
       
       string staticEntryConditionsName = 'Static_'+SObjectApiName+'_Survey';
       if (!surveyEntryConditions.isCreated(staticEntryConditionsName)) createStaticEntryConditions(staticEntryConditionsName); 
       if (!surveyEntryConditions.hasEntryConditions(staticEntryConditionsName)) return null;
		return staticEntryConditionsName;
        
    }
    
    /*========================================================================================
    * Send Survey Invitations Queueable subclass
    * ========================================================================================*/
    
	// @description Sends specified survey invitations by consuming a MaritzCX Invocable Managed Class
	public inherited sharing class SendSurveyInvitationsQueueable implements Queueable {

    	// Maps the SObjectId associated with a survey to the environmental specific MaritzCX Id for the survey invitation to be sent out.
		Map<Id,Integer> surveyInvitationMap;
		Map<Id,SObject> recordsToUpdate;

		public SendSurveyInvitationsQueueable(Map<Id,Integer> surveyInvitationMap, Map<Id,SObject> recordsToUpdate) {

			this.surveyInvitationMap = surveyInvitationMap;
			this.recordsToUpdate = recordsToUpdate;

		}

		// Populates the managed class parameters with the SObject Id and their respective Survey Invitation Ids and sends.
		public void execute(QueueableContext context) {
			
			execute(surveyInvitationMap,recordsToUpdate);

		}
        
		@TestVisible
		private void execute(Map<Id,Integer> surveyInvitationMap,Map<Id,SObject> recordsToUpdate) {

			List<MaritzCX.SendInvitationsInvocableCls.SendInvitationsParameter> inviteParameters = new List<MaritzCX.SendInvitationsInvocableCls.SendInvitationsParameter>();

            for (Id currentObjectId : surveyInvitationMap.keySet()) {

				MaritzCX.SendInvitationsInvocableCls.SendInvitationsParameter parameter = new MaritzCX.SendInvitationsInvocableCls.SendInvitationsParameter();
				parameter.recordId = currentObjectId;
				parameter.mcxInvitationSettingId = (Integer)surveyInvitationMap.get(currentObjectId);
				inviteParameters.add(parameter);
			}

			try {

				// This is a void function with no results returned
				MaritzCX.SendInvitationsInvocableCls.sendInviations(inviteParameters);

				if (recordsToUpdate != null && recordsToUpdate.size()>0) {

					ApplicationDatabase.getInstance().dmlUpdate(recordsToUpdate.values());
				}

			} catch (Exception ex) {

				UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), 
				SSSWConstants.SSSW_APP, SurveyService.SendSurveyInvitationsQueueable.class.getName(), 
				SSSWConstants.SSSW_APP, SSSWConstants.CASE_TRIGGER, LoggingLevel.ERROR);
				
			}
		}
	}
}