/**
* @author       : arjun.singh@auspost.com.au
* @date         : 23/03/2020
* @description  : Controller Class for My Network Community landing page.It has below features.
				  a. list of different views
				  b. Filter used to dynamically get the case result
				  c. Assign to Self feature, user should be able to assign the case to himself. it will update
					 'Case Assigned to ' field on case and not the case owner   
				  d. Case result in a datatable                  
*/
/*******************************  History ************************************************
15/05/2020        arjun.singh@auspost.com.au   Updated - Included the methods for information displayed on Google Map   
19/06/2020         Hara Sahoo                  Updated - Added method to update print flag on case record
05/08/2020         Disha Kariya                Updated - Added method to get address using AME instead of google API
14/08/2020         Disha Kariya                Updated - Single AME API call to get address of delivered address and geolocation of addressee address
17/08/2020         Disha Kariya                Updated - Changes to consider attempted delivery over delivered delivery event message
29/10/2020         SaiSwetha Pingali           Updated - REQ2297137 - Updated criteria to consider last 15 days on Contact centre updated cases
29/07/2021         Neha Mehta                  Updated - REQ2547720 - Added Outside_Delivery_Radius__c,Geo_Precision__c fields in SOQL
01/11/2022         Dattaraj Deshmukh           Updated - Added logic to include CaseInvestigation__c in all queries. 
														 Added methods for StarTrack dynamic SOQL, updated existing methods to filter star track cases.
														 Added star_track_cases listview filter.
*******************************  History ************************************************/
public with sharing class MyNetworkCaseListController {
	
	public static String networkQueue = [Select Id,Name from Group where Name='SSSW Network Queue' and type = 'Queue' limit 1].Id;    
	public static Set<String> enqubTypeNotVisible = new Set<String>{'Damage to property','Staff Complaint'};    
	public static String managerRoleId = [Select Id from UserRole where Name = 'SSSW MyNetwork Manager' limit 1].Id;
	private static final Integer MAX_RESULTS = 10;
	static final String CASE_INVESTIGATION_CLOSED_STATUS = 'Closed';

	//get StarTrack case record type developer names.
	//Declaring it here as SOQL are executed dynamically.
	private static final List<String>  stRecordTypeDeveloperNames =  MyNetworkConstants.STAR_TRACK_RECORD_TYPES;
			
	public MyNetworkCaseListController() {

	}
   /**
	* @description       wrapper class to prepare the data 
	*                     used to display on MyNetwork landing page
	* @param             NA
	* @return            Void
	* @throws            NA
	*/
	public class MyNetworkCasesWrapper {
	  
		@AuraEnabled
		public Case myNetworkCase{get; set;}
		@AuraEnabled
		public String caseColor{get;set;}
		@AuraEnabled
		public String caseHoverText{get; set;}
		@AuraEnabled
		public String caseIcon{get;set;}       
		@AuraEnabled
		public String caseNum{get; set;}
		@AuraEnabled
		public String caseId{get; set;}
		@AuraEnabled
		public String casePriority{get;set;}
		@AuraEnabled
		public Boolean isStarTrackCase{get;set;}

		@AuraEnabled
		public Set<Id> updatedCaseInvestigationIds{get;set;}
		@AuraEnabled
		public Set<Id> stillUnderCaseInvestigationIds{get;set;}
		@AuraEnabled
		public Set<Id> newCaseInvestigationIds{get;set;}
		@AuraEnabled
		public List<CaseInvestigation__c> caseInvestigations{get;set;}
		@AuraEnabled
		public CaseInvestigation__c caseInvestigation{get;set;}

		

		public MyNetworkCasesWrapper(case myNetworkCaseVar, String caseIconVar, String caseColorVar, String caseHoverTextVar, String caseNumVar, String caseIdVar, String casePriorityVar){
			this.myNetworkCase = myNetworkCaseVar;            
			this.caseIcon = caseIconVar;
			this.caseColor = caseColorVar;
			this.caseHoverText = caseHoverTextVar;
			this.caseNum = caseNumVar;
			this.caseId = caseIdVar;
			this.CasePriority = casePriorityVar;
			this.isStarTrackCase = MyNetworkConstants.STAR_TRACK_RECORD_TYPES.contains(myNetworkCaseVar.RecordType.DeveloperName);

			this.updatedCaseInvestigationIds = new Set<Id>();
			this.stillUnderCaseInvestigationIds = new Set<Id>();
			this.newCaseInvestigationIds = new Set<Id>();
			this.caseInvestigations = new List<CaseInvestigation__c>();
			
		}
		public MyNetworkCasesWrapper(){
			this.updatedCaseInvestigationIds = new Set<Id>();
			this.stillUnderCaseInvestigationIds = new Set<Id>();
			this.newCaseInvestigationIds = new Set<Id>();
			this.caseInvestigations = new List<CaseInvestigation__c>();
		}

		public void addCaseInvestigationToUpdateSet(Id cInvestigationId){
			this.updatedCaseInvestigationIds.add(cInvestigationId);
		}
		public void addCaseInvestigationToStillUnderInvestigationSet(Id cInvestigationId){
			this.stillUnderCaseInvestigationIds.add(cInvestigationId);
		}
		public void addCaseInvestigationToNewSet(Id cInvestigationId){
			this.newCaseInvestigationIds.add(cInvestigationId);
		}
		public void addCaseInvestigationsToList(CaseInvestigation__c caseInvestigationRec) {
			this.caseInvestigations.add(caseInvestigationRec);
		}
		public void addCaseInvestigation(CaseInvestigation__c caseInvestigationRec) {
			this.caseInvestigation = caseInvestigationRec;
		}
		
	}
	/**
		@ Description : Update print flah on the selected case records from the UI, field checkbox__c
		@ param       : List of case Ids
		@ return      : Null
	 */
	@AuraEnabled
	public static void updatePrintedCaseFlag(List<String> caseIds) {
		List<Case> updateCase = new List<Case>();
		for (Case cs : [Select checkbox__c FROM Case where id=:caseIds])
		{
			//Check if the flag is already set to true, no action needed
			if(cs.Checkbox__c == false)
			{
				cs.Checkbox__c = true;
				updateCase.add(cs);
			}
		}
		if(!updateCase.isEmpty())
		{
			Database.update(updateCase);
		}
	}

	
	/**
		@ Description : Get all the MyNetwork Cases when user logs in to community.By default, it will fetch
						all the Cases assigned to "SSSW network Queue" and having type as either 'investigation' or 'feedback'
		@ param       : String selectedViewString as "All Cases"
		@ return      : List<MyNetworkCasesWrapper> return the wrapper of cases
	 */
	
	@AuraEnabled
	public static List<MyNetworkCasesWrapper> myNetworkCases(String selectedViewString){
		List<MyNetworkCasesWrapper> myNetworkCasesWrapperList = new List<MyNetworkCasesWrapper>();
		try{
			//get all cases where OwnerId = 'SSSW Network Queue' and 'logged in user is a part of team member'
			list<Case> caseListResult = getAllMYNetworkCases(null, null);

			//get all ST cases.
			List<Case> stCases = getStarTrackCases(null);

			//merging AP and StarTrack (ST)  cases in a single list.
			caseListResult.addAll(stCases);

			//create a wrapper of AP and ST cases
			CaseWrapper caseWrap = getNetworkQueueCases(caseListResult);

			list<Case> updatedCaseList = getUpdatedCasesBySOQL(null, null);
			
			//getContactCenterUpdatedCases() method merge network cases and updated cases. Returns single list of wrapper.
			myNetworkCasesWrapperList = getContactCenterUpdatedCases(updatedCaseList, caseWrap.myNetworkCasesWrap, caseWrap.caseIdSet, null) ;

			system.debug('myNetworkCasesWrapperList: '+myNetworkCasesWrapperList);
		}catch(Exception e){
			
			System.debug('Error in fetching the data ::'+e.getLineNumber());
			System.debug('Error in fetching the data ::'+e.getStackTraceString());
			System.debug('Error in fetching the data ::'+e.getMessage());
		}
		return myNetworkCasesWrapperList;
	}


	/**
		@ Description : inner method to get all the MyNetwork Cases on logging to MyNetwork
		@ param       : String viewTypeString as "All Cases"
		@ return      : List<case> return the wrapper of cases
	 */
	private static list<case> getAllMYNetworkCases(String filterStr, SelectedViewWithFiltersWrapper selectedViewWithFiltersWrp){

		//get cases where ownerId =: networkQueue and logged in user is case team member
		String baseQuery = baseQueryForMyNetworkCases();    
		//String caseInvestigationInnerQuery = generateCaseInvestigationInnerQuery(baseQuery, selectedViewWithFiltersWrp);
		//String formattedBaseQuery = String.format(baseQuery, new List<String>{caseInvestigationInnerQuery});

		String finalQueryString = baseQuery;
		list<Case> caseList = new list<Case>();
		
		if(filterStr != null){
			finalQueryString += filterStr ; 
		}
		finalQueryString += ' Order By Priority ASC,Sent_To_Network_Date__c ASC NULLS LAST  LIMIT 10000' ;
		System.debug('finalQueryString>>>'+finalQueryString);
		caseList = database.query(finalQueryString);
		return caseList;
	}


	 /**
		@ Description : inner method to get all the updated Cases on logging to MyNetwork
		@ param       : String viewTypeString as "All Cases"
		@ return      : List<case> return the wrapper of cases
	 */
	private static list<case> getUpdatedCasesBySOQL( String filterStr, SelectedViewWithFiltersWrapper selectedViewWithFiltersWrp) {

		//if selectedview is star track, then call star track base query.
		String baseQuery = (selectedViewWithFiltersWrp != null && selectedViewWithFiltersWrp.selectedView.equalsIgnoreCase('star_track_cases')) 
							? baseQueryForStarTrackCasesUpdateByContactCenter() : baseQueryForCasesUpdateByContactCenter();

		String finalQueryString = baseQuery;
		list<Case> caseList = new list<Case>();
		if(selectedViewWithFiltersWrp != null && selectedViewWithFiltersWrp.filter != null){
			finalQueryString += selectedViewWithFiltersWrp.filter ;
		}
		finalQueryString += ' Order By Priority ASC ,Sent_To_Network_Date__c ASC NULLS LAST  LIMIT 10000' ;
		System.debug('finalQueryString1>>>'+finalQueryString);
		caseList = database.query(finalQueryString);
		return caseList;
	}

	
	/**
		@ Description : inner method to getting the contact center updated case in wrapper format 
		@ param       : list<case> caseList, list<MyNetworkCasesWrapper> myNetworkCasesWrapperList
		@ return      : list<MyNetworkCasesWrapper>
	 */
	/**  This method checks if queried cases are valid based following criteria:
	 *      1. For AP Cases --> Last_status_change__c (DateTime Field) is within last 5 days. 
	 *                      --> AND OwnerId IS NOT 'SSSW Network Queue'. 
	 *                      --> AND Root_Cause__c = 'Awaiting Network Response'.
	 * 
	 *      2. For ST Cases -->	Last_status_change__c (DateTime Field) is within last 5 days. 
	 *                      -->         OR  Any Case Investigations 'LastContactCenterUpdate__c' (DateTime Field) is withing 5 days.)
	 * */ 
	private static list<MyNetworkCasesWrapper> getContactCenterUpdatedCases(list<case> caseList, list<MyNetworkCasesWrapper> myNetworkCasesWrapperList, Set<Id> excludeCaseSet, String selectedView){
		list<MyNetworkCasesWrapper> myNetworkCasesWrapRec = new list<MyNetworkCasesWrapper>();
		system.debug('caselist:'+caseList);
		system.debug('myNetworkCasesWrapperList:'+myNetworkCasesWrapperList);
		system.debug('excludeCaseSet:'+excludeCaseSet);
		Set<ID> processedCaseIds = new Set<Id>();

		if(myNetworkCasesWrapperList != null) {
			myNetworkCasesWrapRec = myNetworkCasesWrapperList;
		}
		for(Case cse : caseList)
		{   
			if(excludeCaseSet != null && excludeCaseSet.contains(cse.Id)) continue;

				MyNetworkCasesWrapper myNetworkCasesWrapperVar = new MyNetworkCasesWrapper();
				Boolean caseFound = false;
				//spingali - REQ2297137 updated the last_status_Change__c criteria from 1 to 15 days
				//checking if case is NOT ST case.

				system.debug('IS STAR TRACK: '+ MyNetworkConstants.STAR_TRACK_RECORD_TYPES.contains(cse.recordtype.developerName));
				if( !MyNetworkConstants.STAR_TRACK_RECORD_TYPES.contains(cse.recordtype.developerName) &&
						 cse.OwnerId != networkQueue && cse.Root_cause__c == 'Awaiting Network Response' && (cse.Last_Status_Change__c >= System.today() - 5)){
					
					myNetworkCasesWrapperVar = validationCasesUpdatedByContactCenter(cse);
					caseFound = true;
					processedCaseIds.add(cse.Id);
				}
				//check if case is ST case
				else if(MyNetworkConstants.STAR_TRACK_RECORD_TYPES.contains(cse.recordtype.developerName)) {
						String iconMapVar ;
						String colorMapVar;
						String textMapVar;
					
						//if ST case is updated withing last 5 days, consider it as updated case.
						//else, check if child case investigations are updated.
						if( cse.Last_Status_Change__c != null && cse.Last_Status_Change__c >= System.today() - 5) {
							//mark case as updated 
							myNetworkCasesWrapperVar = validationStarTrackCasesUpdatedByContactCenter(cse, null);
							system.debug('---------case wrapper---------');
							system.debug(myNetworkCasesWrapperVar.caseIcon);
							system.debug(myNetworkCasesWrapperVar.caseColor);
							system.debug(myNetworkCasesWrapperVar.caseNum);
							system.debug(myNetworkCasesWrapperVar.caseId);
							//processedCaseIds.add(cse.Id);

							caseFound = true;
						}
						 if( !cse.CaseInvestigations__r.isEmpty() ) {
							Set<ID> processedCaseInvestigationIds = new Set<Id>();

							for(CaseInvestigation__c cInv : cse.CaseInvestigations__r) {
								system.debug('CI: '+cInv);

								 myNetworkCasesWrapperVar = new MyNetworkCasesWrapper();

								//LastContactCentreUpdate__c timestamp is set when a Chatter Post is added on case investigation record by ST Contact Users.
								if(caseFound ||( cInv.LastContactCentreUpdate__c != null && (cInv.LastContactCentreUpdate__c >= System.today() - 5)) ) {
									system.debug('myNetworkCasesWrapperVar: '+myNetworkCasesWrapperVar);

									myNetworkCasesWrapperVar = validationStarTrackCasesUpdatedByContactCenter(cse, cInv);
									if(cInv.Stillunderinvestigation__c) {
										system.debug('====>1: ');
										myNetworkCasesWrapperVar.stillUnderCaseInvestigationIds.add(cInv.Id);
										system.debug('====>2: ');
									}
									else {
										system.debug('====>3: ');
										myNetworkCasesWrapperVar.updatedCaseInvestigationIds.add(cInv.Id);
										system.debug('====>4: ');
									}
								}
								else if(selectedView != 'Cases_updated') {
									//myNetworkCasesWrapperVar.addCaseInvestigationToNewSet(cInv.Id);
									myNetworkCasesWrapperVar.newCaseInvestigationIds.add(cInv.Id);
									myNetworkCasesWrapperVar = validationStarTrackCasesUpdatedByContactCenter(cse, cInv);

								}

								if(myNetworkCasesWrapperVar != null && myNetworkCasesWrapperVar.caseId != null && !processedCaseInvestigationIds.contains(cInv.Id)){
									processedCaseIds.add(cse.Id);
									myNetworkCasesWrapperVar.addCaseInvestigation(cInv);
									myNetworkCasesWrapRec.add(myNetworkCasesWrapperVar);
									processedCaseInvestigationIds.add(cInv.Id);
								}
							}
						}

						system.debug('---------case wrapper--2-------');
						system.debug(myNetworkCasesWrapperVar);
				}
				if(myNetworkCasesWrapperVar != null && myNetworkCasesWrapperVar.caseId != null && !processedCaseIds.contains(cse.Id)){
					processedCaseIds.add(cse.Id);
					myNetworkCasesWrapRec.add(myNetworkCasesWrapperVar);
				}
						  
		}
		return myNetworkCasesWrapRec;
	}
	/**
		@ Description : inner method to get  cases owned by network queue in wrapper format 
		@ param       : list<case> caseListResult
		@ return      : CaseWrapper
	 */
	private static CaseWrapper getNetworkQueueCases(list<case> caseListResult){
		list<MyNetworkCasesWrapper> myNetworkCasesWrapperList = new list<MyNetworkCasesWrapper>();
		MyNetworkCasesWrapper myNetworkCasesWrapperVar ;
		set<Id> caseIds = new set<Id>();
		Set<ID> processedCaseIds = new Set<Id>();

		for(Case cse : caseListResult)
		{   Boolean cFound = false;
			myNetworkCasesWrapperVar = new MyNetworkCasesWrapper();
			system.debug('cse.recordtype.developerName: '+cse.recordtype.developerName);
			if('Awaiting Network Response'.equalsIgnoreCase(cse.Status) && cse.type == 'Investigation'){
						myNetworkCasesWrapperVar = userRoleAndCaseColourValidation(cse);
						cFound = true;
						processedCaseIds.add(cse.Id);
			}else if(cse.type == 'Feedback'){ //this condition should only be valid for AP cases. 
				if( (cse.closedDate > System.today() - 15 )&& ('Awaiting Network Response'.equalsIgnoreCase(cse.Status) || 
					(cse.Network_Responses1__r.isEmpty() ) ||  'Awaiting Network Response'.equalsIgnoreCase(cse.Root_cause__c)  ||
					(!cse.Network_Responses1__r.isEmpty() && cse.Network_Responses1__r[0].Request_Hold_Case__c  ) ||
					(!cse.Network_Responses1__r.isEmpty() && cse.Network_Responses1__r[0].to_CCC_action__c) ||
					(!cse.Network_Responses1__r.isEmpty() && cse.Network_Responses1__r[0].to_Reassign_Network__c != null))) {
						myNetworkCasesWrapperVar = userRoleAndCaseColourValidation(cse);
						cFound = true;
						processedCaseIds.add(cse.Id);
				}
			}
			//if ST case, then add to list
			else if(MyNetworkConstants.STAR_TRACK_RECORD_TYPES.contains(cse.recordtype.developerName)) {

				system.debug('cse.recordtype.developerName Qualified: '+cse.recordtype.developerName);
				system.debug('cse.Last_Status_Change__c: '+cse.Last_Status_Change__c);
				system.debug('cse.Last_Status_Change__c >= System.today() - 5: '+(cse.Last_Status_Change__c >= System.today() - 5));
				system.debug('!cse.CaseInvestigations__r.isEmpty(): '+!cse.CaseInvestigations__r.isEmpty());

				//if ST case is updated withing last 5 days, consider it as updated case.
				//else, check if child case investigations are updated.
				// if( cse.Last_Status_Change__c >= System.today() - 5) {
				// 	//mark case as updated 
				// 	myNetworkCasesWrapperVar = validationStarTrackCasesUpdatedByContactCenter(cse, null);
				// 	cFound = true;
				// }
				if( !cse.CaseInvestigations__r.isEmpty() ) {
					Set<ID> newCaseInvIds = new Set<Id>();
					Set<ID> updatedCaseInvIds = new Set<Id>();
					Set<ID> stillUnderInvestigationCaseInvIds = new Set<Id>();
					Set<ID> processedCaseInvestigationIds = new Set<Id>();

					for(CaseInvestigation__c cInv : cse.CaseInvestigations__r) {
						
						myNetworkCasesWrapperVar = new MyNetworkCasesWrapper();

						//LastContactCentreUpdate__c timestamp is set when a Chatter Post is added on case investigation record by ST Contact Users.
						if(cInv.LastContactCentreUpdate__c != null && (cInv.LastContactCentreUpdate__c >= System.today() - 5)) {
							myNetworkCasesWrapperVar = validationStarTrackCasesUpdatedByContactCenter(cse, cInv);
							if(cInv.Stillunderinvestigation__c) {
								myNetworkCasesWrapperVar.stillUnderCaseInvestigationIds.add(cInv.Id);
								stillUnderInvestigationCaseInvIds.add(cInv.Id);
							}
							else {
								system.debug('====>5: ');
								myNetworkCasesWrapperVar.updatedCaseInvestigationIds.add(cInv.Id);
								updatedCaseInvIds.add(cInv.Id);
								system.debug('====>6: ');
							}
						}
						else {
							system.debug('====>7: ');
							system.debug('myNetworkCasesWrapperVar.newCaseInvestigationIds'+myNetworkCasesWrapperVar.newCaseInvestigationIds);
							newCaseInvIds.add(cInv.Id);
							myNetworkCasesWrapperVar.newCaseInvestigationIds.add(cInv.Id);

							myNetworkCasesWrapperVar = validationStarTrackCasesUpdatedByContactCenter(cse, cInv);
						}
					
						cFound = true;
						myNetworkCasesWrapperVar.addCaseInvestigation(cInv);
						if(myNetworkCasesWrapperVar!= null && myNetworkCasesWrapperVar.caseId != null && !processedCaseInvestigationIds.contains(cInv.Id)) {
							myNetworkCasesWrapperList.add(myNetworkCasesWrapperVar);
							caseIds.add(myNetworkCasesWrapperVar.caseId);
							processedCaseInvestigationIds.add(cInv.Id);
						}

					}

					myNetworkCasesWrapperVar.newCaseInvestigationIds = newCaseInvIds;
					myNetworkCasesWrapperVar.updatedCaseInvestigationIds = updatedCaseInvIds;
					myNetworkCasesWrapperVar.stillUnderCaseInvestigationIds = stillUnderInvestigationCaseInvIds;
				}
			}

			if(myNetworkCasesWrapperVar!= null && myNetworkCasesWrapperVar.caseId != null && !processedCaseIds.add(cse.Id)){
				myNetworkCasesWrapperList.add(myNetworkCasesWrapperVar);
				caseIds.add(myNetworkCasesWrapperVar.caseId);
				processedCaseIds.add(myNetworkCasesWrapperVar.caseId);
			}                
		}
		CaseWrapper caseWrap = new CaseWrapper(caseIds, myNetworkCasesWrapperList) ;

		system.debug('caseWrap: '+caseWrap.myNetworkCasesWrap);

		return caseWrap ;
	}

	public class CaseWrapper {
	   public  List<MyNetworkCasesWrapper> myNetworkCasesWrap;
	   public set<Id> caseIdSet;
	   public CaseWrapper(set<Id> caseIdSetVar, List<MyNetworkCasesWrapper> myNetworkCasesWrapVar){
			caseIdSet = caseIdSetVar ;
			myNetworkCasesWrap = myNetworkCasesWrapVar ;
	   }
	}

	/**
		@ Description : Base query to get the cases updated by Contact Center
		@ param       : N/A
		@ return      : Query String
	 */
	private static string baseQueryForCasesUpdateByContactCenter(){
		String soqlSelect = 'SELECT RecordTypeId, RecordType.DeveloperName, Id, OwnerId, Sent_To_Network_Date__c, Last_Status_Change__c,closedDate,Status, type, Root_cause__c, Checkbox__c, Facility_Milestones_Violated__c, CaseNumber, Priority, ReferenceID__c, Customer_Type__c, EnquirySubType__c, Address2__c, Address2Postcode__c, Network__c,Network__r.Name, PONUser__c, PONUser__r.Name, ' ;
		soqlSelect  += '(SELECT Request_Hold_Case__c,to_CCC_action__c, to_Reassign_Network__c FROM Network_Responses1__r ORDER BY CreatedDate DESC) FROM Case WHERE ';               
		soqlSelect  += ' Id IN (SELECT ParentId FROM caseteammember WHERE MemberId =  ' + '\'' + userinfo.getUserId() + '\')';
		soqlSelect  += ' AND (Root_cause__c = ' + '\'Awaiting Network Response\')';

		return soqlSelect ; 
	}
	/**
		@ Description : Base query to get all the cases owned by Network queue of type 'Investigation' and 'Feedback'
		@ param       : N/A
		@ return      : Query String
	 */
	private static String baseQueryForMyNetworkCases(){       
		String soqlSelect = 'SELECT RecordTypeId,  RecordType.DeveloperName, Id, Sent_To_Network_Date__c, Last_Status_Change__c,closedDate,Status, type, Root_cause__c, Checkbox__c, Facility_Milestones_Violated__c, CaseNumber, Priority, ReferenceID__c, Customer_Type__c, EnquirySubType__c, Address2__c, Address2Postcode__c, Network__c,Network__r.Name, PONUser__c, PONUser__r.Name, ' ;
		soqlSelect  += '(SELECT Request_Hold_Case__c,to_CCC_action__c, to_Reassign_Network__c FROM Network_Responses1__r ORDER BY CreatedDate DESC) '
					+' FROM Case WHERE OwnerId= ' + '\'' + networkQueue + '\'';       
		//soqlSelect  += ' AND type IN (\'Investigation\', \'Feedback\') ';
		soqlSelect  += ' AND Id IN (SELECT ParentId FROM caseteammember WHERE MemberId =  ' + '\'' + userinfo.getUserId() + '\')';               

		return soqlSelect ;         
	}


	
	/**
		@ Description : Used to get below details of cases
						a.Details as 'SUI' or 'NEW' or 'Updated'
		@ param       : caseRecord
		@ return      : MyNetworkCasesWrapper
	 */
	private static MyNetworkCasesWrapper  userRoleAndCaseColourValidation(case caseRecord){
		Boolean addToListFlag = false;
		String iconMapVar ;
		String colorMapVar;
		String textMapVar;
		MyNetworkCasesWrapper myNetworkCasesWrapperVar ;
		if (userinfo.getUserRoleId().contains(managerRoleId)) {
			addToListFlag = true;        
		} else if(!userinfo.getUserRoleId().contains(managerRoleId) && 
					!enqubTypeNotVisible.contains(caseRecord.EnquirySubType__c)) {
			addToListFlag = true;
		}
		if(addToListFlag){
			if(!caseRecord.Network_Responses1__r.isEmpty() && 
			caseRecord.Network_Responses1__r[0].Request_Hold_Case__c)  {               
				iconMapVar = 'SUI';
				colorMapVar = 'orange';
				textMapVar = 'Case is under investigation' ;
			} else {  // if not SUI, then flag cases as new to work on                   
				iconMapVar = 'NEW';
				colorMapVar = 'green';
				textMapVar = 'Case is awaiting action/response' ;
			}
			String casePriority = getCasePriority(caseRecord);
			myNetworkCasesWrapperVar = new MyNetworkCasesWrapper(caseRecord, iconMapVar, colorMapVar, textMapVar, caseRecord.CaseNumber, caseRecord.Id, casePriority);
		}
		return myNetworkCasesWrapperVar;
	} 
	private static String getCasePriority(case caseRecord){
		String casePriority;
		if(caseRecord.priority == 'High'){
			casePriority = '1';
		}else if(caseRecord.priority == 'Medium'){
			casePriority = '2';
		}else if(caseRecord.priority == 'Low'){
			casePriority = '3';
		}
		return casePriority ;
	}
	/**
		@ Description : Used to get below details of cases updated by contact center user
						a.Details as 'SUI' or 'NEW' or 'Updated'
		@ param       : N/A
		@ return      : Query String
	 */
	private static MyNetworkCasesWrapper  validationCasesUpdatedByContactCenter(case cse){
		Boolean addToListFlag = false;
		String iconMapVar ;
		String colorMapVar;
		String textMapVar;
		MyNetworkCasesWrapper myNetworkCasesWrapperVar ;
		if (userinfo.getUserRoleId().contains(managerRoleId)) {
			addToListFlag = true;        
		} else if(!userinfo.getUserRoleId().contains(managerRoleId) && 
					!enqubTypeNotVisible.contains(cse.EnquirySubType__c)) {
			addToListFlag = true;
		}
		if(addToListFlag){
			if('Investigation'.equalsIgnoreCase(cse.Type) || 'General Enquiry'.equalsIgnoreCase(cse.Type)){                
				iconMapVar = 'UPDATED';
				colorMapVar = 'Red';
				textMapVar = 'Case has been updated' ;
			}else if('Feedback'.equalsIgnoreCase(cse.Type) && !cse.Network_Responses1__r.isEmpty() && 
				cse.Network_Responses1__r[0].Request_Hold_Case__c) { //if SUI checked on existing response               
				iconMapVar = 'SUI';
				colorMapVar = 'orange';
				textMapVar = 'Case is under investigation' ;
			}else if('Feedback'.equalsIgnoreCase(cse.Type) && ((!cse.Network_Responses1__r.isEmpty() && 
				!cse.Network_Responses1__r[0].Request_Hold_Case__c) || cse.Network_Responses1__r.isEmpty())) { //if SUI checked on existing response               
				iconMapVar = 'UPDATED';
				colorMapVar = 'Red';
				textMapVar = 'Case has been updated' ;
			}else { // all other cases yet to be responded                
				iconMapVar = 'NEW';
				colorMapVar = 'green';
				textMapVar = 'Case is awaiting action/response' ;
			}
			String casePriority = getCasePriority(cse);
			myNetworkCasesWrapperVar = new MyNetworkCasesWrapper(cse, iconMapVar, colorMapVar, textMapVar, cse.CaseNumber, cse.Id, casePriority);
		}
		return myNetworkCasesWrapperVar;
	}
	/**
		@ Description : Method to clear the cache when user clicks on "Clear" button
		@ param       : N/A
		@ return      : N/A
	 */
	@AuraEnabled
	public static Boolean clearCache(){
		String cacheStr = '{"searchButtonClicked": false}';
		string strJsn = JSON.serialize(cacheStr);
		CacheManager.put('MYNETWORK_FILTERS', cacheStr); 
		return true;
	}

	/**
	@ Description : Method is used to get the cases based
	@               on the different combination of filters and list view seletected
	@               by the logged in user
	@ param       : String filteredString Json string of filters and selected list view
	@ return      : List<MyNetworkCasesWrapper> Cases with additional details 
	*/
	@AuraEnabled
	public static List<MyNetworkCasesWrapper> getFilteredCases(String filteredString) {
		
		List<MyNetworkCasesWrapper> myNetworkCasesWrapperList = new List<MyNetworkCasesWrapper>();
		MyNetworkCasesWrapper myNetworkCasesWrapperVar ;  
		CacheManager.put('MYNETWORK_FILTERS', filteredString); 

		String baseQuery ;
		SelectedViewWithFiltersWrapper selectedViewWithFiltersWrp = constructDynamicFilters(filteredString);
		String filterVar = selectedViewWithFiltersWrp.filter;

		if(selectedViewWithFiltersWrp.selectedView =='All_Cases') {
			
			//get all cases where OwnerId = 'SSSW Network Queue' and 'logged in user is a part of team member'
			list<Case> caseListResult = getAllMYNetworkCases(filterVar, selectedViewWithFiltersWrp);

			//get all ST cases.
			List<Case> stCases = getStarTrackCases(selectedViewWithFiltersWrp);

			//merge updated AP and StarTrack (ST) cases in a list.
			caseListResult.addAll(stCases);

			//create a wrapper
			CaseWrapper caseWrap = getNetworkQueueCases(caseListResult);

			//get updated cases for AP
			list<Case> updatedCaseList = getUpdatedCasesBySOQL(filterVar, selectedViewWithFiltersWrp);
			
			//get updated cases for ST
			//list<Case> updatedStarTrackCaseList = getUpdatedStarTrackCases(filterVar, selectedViewWithFiltersWrp);
			
			//merge updated AP and StarTrack (ST) cases in a list.
			//updatedCaseList.addAll(updatedStarTrackCaseList);

			//filter out AP and ST cases based on criteria
			//Refer to method comments for all filter criteria.
			myNetworkCasesWrapperList = getContactCenterUpdatedCases(updatedCaseList, caseWrap.myNetworkCasesWrap, caseWrap.caseIdSet, selectedViewWithFiltersWrp.selectedView);

		}else if(selectedViewWithFiltersWrp.selectedView =='Cases_updated') {

			//get updated cases for AP
			list<Case> updatedCaseList = getUpdatedCasesBySOQL(filterVar, selectedViewWithFiltersWrp);

			//get updated cases for ST
			//list<Case> updatedStarTrackCaseList = getUpdatedStarTrackCases(filterVar, selectedViewWithFiltersWrp);
			
			//get all ST cases.
			List<Case> stCases = getStarTrackCases(selectedViewWithFiltersWrp);

			//merging AP and StarTrack (ST) cases ina single list.
			updatedCaseList.addAll(stCases);

			//filter out AP and ST cases based on criteria
			//Refer to method comments for all filter criteria.
			myNetworkCasesWrapperList = getContactCenterUpdatedCases(updatedCaseList, null, null, selectedViewWithFiltersWrp.selectedView) ;
			
		}else if(selectedViewWithFiltersWrp.selectedView =='star_track_cases') { // filter star track cases and case investigations
			
			//get ST cases
			//list<Case> starTrackCases = getAllMYNetworkStarTrackCases(selectedViewWithFiltersWrp);
			List<Case> stCases = getStarTrackCases(selectedViewWithFiltersWrp);

			//create a wrapper
			CaseWrapper caseWrap = getNetworkQueueCases(stCases);
			
			//get updated cases for ST
			//list<Case> updatedCaseList = getUpdatedStarTrackCases(filterVar, selectedViewWithFiltersWrp);

			//filter out AP and ST cases based on criteria
			//Refer to method comments for all filter criteria.
			myNetworkCasesWrapperList = getContactCenterUpdatedCases(stCases, caseWrap.myNetworkCasesWrap, caseWrap.caseIdSet, selectedViewWithFiltersWrp.selectedView) ;

		}else {

			list<Case> caseListResult = getAllMYNetworkCases(filterVar, selectedViewWithFiltersWrp);
			CaseWrapper caseWrap = getNetworkQueueCases(caseListResult);
			myNetworkCasesWrapperList =caseWrap.myNetworkCasesWrap;
		}
		return myNetworkCasesWrapperList;
	}

	
	/**
	 * @Description: Wrapper class for selectedview and selected filters
	 */
	private class SelectedViewWithFiltersWrapper{
		String selectedView;
		String filter;
		Map<String, Object> selectedViewAndFiltersJsonObject;
		public SelectedViewWithFiltersWrapper(String selectedViewStr, String filterStr, Map<String, Object> selectedViewAndFiltersJson){
			selectedView = selectedViewStr ;
			filter = filterStr ;
			selectedViewAndFiltersJsonObject = selectedViewAndFiltersJson;
		}
	}
	/**
	  @Description: This method generated dynamic SOQL filter based on seleced filteres and list view
	  @Param :      String filteredString as JSON
	  @Return :     SelectedViewWithFiltersWrapper
	  */
	private static SelectedViewWithFiltersWrapper constructDynamicFilters(String filteredString){
		Boolean isPrinted;
		String isPrintedVal;
		Boolean includeIsPrintedCheck= false;
		String addressePostcodeVal;
		String caseNumberVal;
		String enquirySubTypeVal;
		String priorityVal;
		String selectedNetworkRecrdIdVal;
		String selectedProductCategoryVal;
		String selectedlistview;
		String dynamicFilter ;
		Boolean searchButtonClickedFlag;
		Boolean isStarTrackCaseFilterSelected = false;

		Map<string,object> filtersMap = (Map<string,object>)JSON.deserializeUntyped(filteredString);
		for(string strKey: filtersMap.keySet()){
			if(strKey.equalsIgnoreCase('addressePostcodeVal')){
				addressePostcodeVal = (String)filtersMap.get('addressePostcodeVal');
			}else if(strKey.equalsIgnoreCase('caseNumberVal')){
				caseNumberVal = (String)filtersMap.get('caseNumberVal');
			}else if(strKey.equalsIgnoreCase('enquirySubTypeVal')){
				enquirySubTypeVal = (String)filtersMap.get('enquirySubTypeVal');
			}else if(strKey.equalsIgnoreCase('isPrinted')){
				isPrintedVal = (String)filtersMap.get('isPrinted');
			}else if(strKey.equalsIgnoreCase('priorityVal')){
				priorityVal = (String)filtersMap.get('priorityVal');
			}else if(strKey.equalsIgnoreCase('selectedNetworkRecrdIdVal')){
				selectedNetworkRecrdIdVal = (String)filtersMap.get('selectedNetworkRecrdIdVal');
			}else if(strKey.equalsIgnoreCase('selectedProductCategoryVal')){
				selectedProductCategoryVal = (String)filtersMap.get('selectedProductCategoryVal');
			}else if(strKey.equalsIgnoreCase('selectedlistview')){
				selectedlistview = (String)filtersMap.get('selectedlistview');
			}else if(strKey.equalsIgnoreCase('searchButtonClicked')){
				searchButtonClickedFlag = (Boolean)filtersMap.get('searchButtonClicked');
			}
			else if(strKey.equalsIgnoreCase('isStarTrackSearch')){
				isStarTrackCaseFilterSelected = (Boolean)filtersMap.get('isStarTrackSearch');
			}
		}
		if(isPrintedVal.equalsIgnoreCase('Yes')){
			isPrinted = true;
			includeIsPrintedCheck = true;
		}else if(isPrintedVal.equalsIgnoreCase('No')){
			isPrinted = false;
			includeIsPrintedCheck = true;
		}      
		if(searchButtonClickedFlag){
			if(!String.isBlank(caseNumberVal) ){
				dynamicFilter = ' AND (caseNumber ='  + '\'' + caseNumberVal + '\')';
			}else{
					if( !String.isBlank(addressePostcodeVal) && addressePostcodeVal != '--Select--'){
						//dynamicFilter = ' AND (Address2Postcode__c ='  + '\'' + addressePostcodeVal + '\')'; 
					   String postCodeValues = postCodeParsing(addressePostcodeVal);
					   if(postCodeValues.contains(',')){
						dynamicFilter = ' AND (Address2Postcode__c  IN ' + postCodeValues + ')';
					   }else{
						dynamicFilter = ' AND (Address2Postcode__c  = ' + postCodeValues + ')';
					   }
					   
					}
					if( !String.isBlank(enquirySubTypeVal ) && enquirySubTypeVal != '--Select--'){

						//if StarTrack case field is selected then select 'Enquiry_Type__c' field.
						//if AP enquiry values are selected then filter based on 'EnquirySubType__c'.
						String enquiryField = isStarTrackCaseFilterSelected ? 'Enquiry_Type__c' : 'EnquirySubType__c';

						String filterVar = ' AND ( '+ enquiryField+'= ' + '\'' + String.escapeSingleQuotes(enquirySubTypeVal) + '\')' ;
						if(dynamicFilter != null){
							dynamicFilter += filterVar ;
						} else{
							dynamicFilter = filterVar ;
						}
					}
					if(includeIsPrintedCheck){
						String printFilterVar = ' AND (Checkbox__c =' +  isPrinted + ')' ;
						if(dynamicFilter != null){
							dynamicFilter += printFilterVar ;
						} else{
							dynamicFilter = printFilterVar ;
						}
					}
					if(!String.isBlank(priorityVal) && priorityVal != '--Select--'){
						String priorityFilterVar = ' AND (Priority =' + '\'' + String.escapeSingleQuotes(priorityVal) + '\')' ;
						if(dynamicFilter != null){
							dynamicFilter += priorityFilterVar ;
						} else{
							dynamicFilter = priorityFilterVar ;
						}
					}
					if(!String.isBlank(selectedNetworkRecrdIdVal)  && selectedNetworkRecrdIdVal != '--Select--'){
						String filterVar = ' AND (Network__c =' + '\'' + String.escapeSingleQuotes(selectedNetworkRecrdIdVal) + '\')' ;
						if(dynamicFilter != null){
							dynamicFilter += filterVar ;
						} else{
							dynamicFilter = filterVar ;
						}
					}
					system.debug('isStarTrackCaseFilterSelected: '+isStarTrackCaseFilterSelected);
					system.debug('selectedProductCategoryVal: '+selectedProductCategoryVal);
					
					if(!isStarTrackCaseFilterSelected && !String.isBlank(selectedProductCategoryVal) && selectedProductCategoryVal != '--Select--'){

						String filterVar = ' AND (ProductCategory__c =' + '\'' + String.escapeSingleQuotes(selectedProductCategoryVal) + '\')' ;
						if(dynamicFilter != null){
							dynamicFilter += filterVar ;
						} else{
							dynamicFilter = filterVar ;
						}
					}
				}
		}
		if(!String.isBlank(selectedlistview) && selectedlistview != '--Select--'){
			String listViewFilterVar ;
			String facilityReportedDamages = 'Facility reported damages';
			String enterpriseVar = 'Enterprise';
			
			if(selectedlistview.equalsIgnoreCase('My_Cases')){
				listViewFilterVar = ' AND (PONUser__c = ' + '\'' + userinfo.getUserId() + '\')';                 
			}else if(selectedlistview.equalsIgnoreCase('Facility_reported')){
				listViewFilterVar = ' AND (EnquirySubType__c = ' + '\'' + String.escapeSingleQuotes(facilityReportedDamages) + '\')';                 
			}else if(selectedlistview.equalsIgnoreCase('Enterprise_customers')){
				listViewFilterVar = ' AND (contact.SLA__c = '  + '\'' + enterpriseVar + '\')';             
			}else if( (isStarTrackCaseFilterSelected && !String.isBlank(selectedProductCategoryVal) && selectedProductCategoryVal != '--Select--') 
						|| selectedlistview.equalsIgnoreCase('star_track_cases')){ // filter out ST cases based on record types.
				listViewFilterVar = ' AND (RecordType.DeveloperName IN:stRecordTypeDeveloperNames)';             
			}
		   if(listViewFilterVar != null){
				if(dynamicFilter != null){
					dynamicFilter += listViewFilterVar ;
				} else {
					dynamicFilter = listViewFilterVar ;
				}
			}
		}
		SelectedViewWithFiltersWrapper selectedViewWithFiltersWrap = new SelectedViewWithFiltersWrapper(selectedlistview, dynamicFilter, filtersMap);
		return selectedViewWithFiltersWrap ;
	}
	/**
	  @Description: Multiple postcode can be used to search the cases.This method is used
					to parse the pasre the postcode to be used as filter criteria
	  @Param :      String postCodeVar
	  @Return :     String after parse of Postcodes
	  */
	private Static String postCodeParsing(String postCodeVar){
		List<String> postCodesList = new List<String>();
		String postCodeFilter ;
		postCodesList = postCodeVar.split(',');
		integer counter = 0;
		for(String postCodeStr : postCodesList){
			if(postCodeFilter != null){
				postCodeFilter +=  ','+ '\'' + postCodeStr.trim() + '\'';
				counter++;
			}else{
				postCodeFilter = '\'' + postCodeStr.trim() + '\'';
			}
		}
		if(counter > 0){
			postCodeFilter = '(' + postCodeFilter + ')';
		}    
		return postCodeFilter;
	}

	/**
	 @ Description : Method returns all the related Event Messages for a specific case
	 @Param      : String caseRecordId
	 @Return     : list<EventMessage__c>  
	*/
   @AuraEnabled(cacheable=true)
   public static EventMessagesWithSortingDetails getRelatedEventMessages(Id recordId){
		list<EventMessageWithGeoCode> eventMessageList = new list<EventMessageWithGeoCode>();
		list<EventMessage__c>  sortingRelatedEventMessage = new list<EventMessage__c>();
		Boolean sortingEventMessageFound = false;
		Set<String> sortingEventCodeSet = new Set<String>();
		EventMessagesWithSortingDetails eventMessagesWithSortingDetailsVar ;

		String sObjectTypeName = recordId.getSObjectType().getDescribe().getName();
		Case caseRecord;
		CaseInvestigation__c caseInvestigation;
		Id articleId;

		
		for(MyNetworkSortingEventTypes__mdt mdtVar :[Select  MasterLabel From MyNetworkSortingEventTypes__mdt]){
			sortingEventCodeSet.add(mdtVar.MasterLabel);
		}

		//if record is of the type = CASE, query case details
		if(sObjectTypeName.equalsIgnoreCase('Case')) {
			//caseRecord = [Select Id, ArticleTest__c,RecordType.DeveloperName From Case Where Id =: recordId LIMIT 1];
			caseRecord = CasesSelector.newInstance().selectById(new Set<Id>{recordId}, new Set<Object>{CasesSelector.Options.WITH_RECORDTYPE}).values()[0];
		}
		//if record is of the type = CaseInvestigation, query case investigation details
		else if(sObjectTypeName.equalsIgnoreCase('CaseInvestigation__c')) {
			//caseInvestigation = [Select Id, Article__r.Id, Article__c from CaseInvestigation__c where Id =: recordId LIMIT 1];
			caseInvestigation = CaseInvestigationsSelector.newInstance().selectById(new Set<Id>{recordId}, new Set<Object>{CaseInvestigationsSelector.Options.WITH_ARTICLES}).values()[0];
		}

		
		if(recordId != null){

			//If record ID is of the type = Case Investigation then it's article ID should be passed.
			//If record ID is of the type = Case, then it's Article id should be passed.
			articleId = (sObjectTypeName.equalsIgnoreCase('CaseInvestigation__c') && caseInvestigation.Article__r.Id !=null) ?
				(caseInvestigation.Article__r.Id) : (caseRecord.ArticleTest__c != null ? caseRecord.ArticleTest__c : null);

			if(articleId != null){
				for(EventMessage__c ev:[Select Id, EventGeoLocation__Longitude__s, EventGeoLocation__Latitude__s, 
													StatusText__c, EventDescription__c, ActualDateTime__c, 
													Event_Location__c, PlannedDateTime__c, PlannedLocation__c, 
													DriverContract__c, RoundNo__c, Event_Comment__c, SignatoryName__c, 
													EventSource__c, SenderID__c, EventType__c,Container_ID__c
													,SortOutputStatus__c, SortOutputReason__c, SortInductMode__c,
													OCRVCSResultSource__c, OCRVCSResultStatus__c, OCRVCSRejectStatus__c,
													OCRVCS_DPID__c, OCRVCSPostcode__c, OCRVCS_OS_Zone__c, DefaultHeight__c,
													Height__c,Length__c,Width__c,Weight__c,
													DefaultLength__c, DefaultWidth__c, DefaultWeight__c, PhysicalContainerID__c,VISALabelLine1__c,
													VISALabelLine2__c, DeliveryNetworkState__c, DeliveryNetworkPostcode__c, RoutingResultSource__c,
													Article__c,Article__r.Name, Article__r.ProductCategory__c, Article__r.SubProduct__c,
													DeviceID__c,Machine_Device_Name__c, SortDest__c, Logical_Destination_Name__c,
													SortOutputComp__c, Actual_Destination_Name__c, DeviceUser__c,Outside_Delivery_Radius__c,Geo_Precision__c
														From EventMessage__c where Article__c =:articleId order by ActualDateTime__c desc]){
					String geoLocationStr ;
					if(ev.EventGeoLocation__Longitude__s != null && ev.EventGeoLocation__Latitude__s != null){
						geoLocationStr =  ev.EventGeoLocation__Latitude__s + ',' + ev.EventGeoLocation__Longitude__s;                        
						eventMessageList.add(new EventMessageWithGeoCode(geoLocationStr, true,ev));
					}else{
						eventMessageList.add(new EventMessageWithGeoCode(geoLocationStr,false ,ev));
					}
					if(sortingEventCodeSet.contains(ev.EventType__c) ){
						sortingEventMessageFound = true;
						sortingRelatedEventMessage.add(ev);
					}
				}
			}
		}
			eventMessagesWithSortingDetailsVar  = new  EventMessagesWithSortingDetails(sortingRelatedEventMessage, eventMessageList);
		return eventMessagesWithSortingDetailsVar;    
   }
   public class EventMessagesWithSortingDetails{
		@AuraEnabled
		public list<EventMessage__c> sortingEventMessage {get;set;}
		@AuraEnabled
		public list<EventMessageWithGeoCode> eventMessageWithGeoCodeList {get;set;}
		public EventMessagesWithSortingDetails(list<EventMessage__c> sortingEventMessageVar, list<EventMessageWithGeoCode> eventMessageWithGeoCodeListVar){
			sortingEventMessage = sortingEventMessageVar ;
			eventMessageWithGeoCodeList = eventMessageWithGeoCodeListVar;
		}
   }
   public class EventMessageWithGeoCode{
	   @AuraEnabled
	   public String geoLocation{get;set;}
	   @AuraEnabled
	   public Boolean geoLocationFound{get;set;}
	   @AuraEnabled
	   public EventMessage__c eventMessageRecord{get;set;}


	   public EventMessageWithGeoCode(String geoLocationStr, Boolean geoLocationFoundVar, EventMessage__c eventMessageRecordStr){
		geoLocation = geoLocationStr;
		geoLocationFound = geoLocationFoundVar;
		eventMessageRecord = eventMessageRecordStr;
	   }
   }
   /**
	*@Description : Method returns the cache stored in platform cache
	 @Param      : n/a
	 @Return     : Returns the string stored in platform cache 'MYNETWORK_FILTERS'
	*/
   @AuraEnabled
	public static String getFiltersData(){
		String cachedFiltersCached = (String)CacheManager.get('MYNETWORK_FILTERS');
		return cachedFiltersCached;
	}
	

	
	public class AssignToSelfWrapper{
		@AuraEnabled
		public Boolean hasError{get; set;}
		@AuraEnabled
		public String resultValue{get;set;}
		public AssignToSelfWrapper(Boolean hasErrorVar, String resultVarStr){
			hasError = hasErrorVar;
			resultValue = resultVarStr;
		}
	}


	public class RecordDetailsWrapper{
		@AuraEnabled
		public String sObjectTypeName{get; set;}
		@AuraEnabled
		public Case caseRecord{get;set;}

		public RecordDetailsWrapper(String sObjectTypeNameVar, Case caseRecordVar){
			this.sObjectTypeName = sObjectTypeNameVar;
			this.caseRecord = caseRecordVar;
		}
	}

	


	/**
	 @Description : Method used to get the selected case details and 
					used on case detail page to display the details
	 */
	@AuraEnabled
	public static case getSelectedCases(Id recordId){
		Case cRecord = new Case();
		if(recordId != null){
			if(recordId.getSObjectType().getDescribe().getName().equalsIgnoreCase('Case')) {
				// cRecord = [Select id, CaseNumber, Status, ContactId, Subject, EnquirySubType__c, ReferenceID__c,
				// 			CreatedDate, Primary_Name__c, Address1__c, Secondary_Contact__c, Address2__c, OwnerId, 
				// 			LastModifiedDate, Description, 
				// 			(SELECT Name, Id, CreatedDate, Article__r.Name, Priority__c, Status__c, Network__c, Network__r.Name from CaseInvestigations__r Where 
				// 			Status__c != : CASE_INVESTIGATION_CLOSED_STATUS)
				// 			from Case where Id =: recordId];
				cRecord = CasesSelector.newInstance().selectById(new Set<Id>{recordId}, new Set<Object>{CasesSelector.Options.WITH_CHILD_INVESTIGATIONS, CaseInvestigationsSelector.Options.WITH_ARTICLES}).values()[0];
			} 
			else if(recordId.getSObjectType().getDescribe().getName().equalsIgnoreCase('CaseInvestigation__c')) {
				
				//query case investigation for case Id.
				CaseInvestigation__c caseInvestigation = CaseInvestigationsSelector.newInstance().
															selectById(new Set<Id>{recordId}, new Set<Object>{CaseInvestigationsSelector.Options.WITH_ARTICLES})
															.values()[0];
				cRecord = CasesSelector.newInstance().
										selectById(new Set<Id>{caseInvestigation.Case__c}, new Set<Object>{CasesSelector.Options.WITH_CHILD_INVESTIGATIONS,
											CaseInvestigationsSelector.Options.WITH_ARTICLES})
										.values()[0];
			}
		}
		return cRecord;
	}

	/**
	 @Description : This method is used to display differnt messages related to a case  
	 */
	@AuraEnabled
	public static list<CaseMessage> getCaseMessages(Id caseRecordId){
		list<CaseMessage> caseMessageList = new list<CaseMessage>();

		if(caseRecordId.getSObjectType().getDescribe().getName().equalsIgnoreCase('Case')) {
				// Case caseRecord = [Select Id, Facility_Milestones_Violated__c, Root_cause__c, Owner.Name, Status, type From Case where Id=: caseRecordId];
			Case caseRecord = CasesSelector.newInstance().selectById(new Set<Id>{caseRecordId}, new Set<Object> {CasesSelector.Options.WITH_OWNER}).values()[0];

			if(caseRecord.Root_cause__c == 'Awaiting Network Response' &&  (caseRecord.Owner.Name != 'SSSW Network Queue' || 
			(caseRecord.Owner.Name == 'SSSW Network Queue' && caseRecord.Status!= 'Awaiting Network Response' )) ){
					if(caseRecord.status == 'Closed' ){
						if(caseRecord.type !=  'Feedback')
							caseMessageList.add(new CaseMessage('Case', 'This case is now closed. No further action is required.')) ;
					}else{
						caseMessageList.add(new CaseMessage('Case', 'This case has received further information and is now under review by the Customer Contact Centre.')) ;
					}
			}

			list<Network_Response__c> nrList = [Select id from Network_Response__c where (RelatedCase__c =: caseRecordId OR Related_Case__c =: caseRecordId)  AND Request_Hold_Case__c = false limit 1];
			if(!nrList.isEmpty()){
				caseMessageList.add(new CaseMessage('Network Response', 'Please review existing network responses before updating case.')) ;
			}
		}
		

		 
		return caseMessageList ;
	}

	public class CaseMessage{
		@AuraEnabled
		public String messageType{get; set;}
		@AuraEnabled
		public String messageString{get;set;}

		public CaseMessage(String messageTypeVar, String messageStringVar){
			messageType = messageTypeVar;
			messageString = messageStringVar;
		}
	}
	/**
	 * @Description : This method is used to get the address information to plot on google map.
	 *               1. Addressee address is fetched from Case Addressee Address
	 *               2. Manifest address is fetched from Article Address
	 *               3. Delivered address is fetched from Event Message of certain event code types
	 */
	//This method is passed either case id or case investigation id based on the placement of its component.
	//If CI id is passed then additional query is introduced to pass relevant Case Id.
	@AuraEnabled
	public static  SafeLocationDetails getSafeDropInformation(Id recordId){
		Boolean isValidManifestAddress = false;
		Boolean isValidAddresseeAddress = false;
		Boolean isValidDeliveredAddress = false;
		Boolean isValidAttemptedAddress = false;
		String  deliveredLatitude ;
		String  deliveredLongitute ;
		String  attemptedLatitude ;
		String  attemptedLongitute ;
		SafeLocationDetails safeLocationDetail ;
		AddressDetails addresseeAddressDetails = new AddressDetails();
		AddressDetails manifestAddresssDetails = new AddressDetails();
		AddressDetails deliveredAddresssDetails = new AddressDetails();
		AddressDetails attemptedAddresssDetails = new AddressDetails();
		Set<String> eventTypes = new Set<String>();
		Set<String> attemptedEventTypes = new Set<String>();
		Map<String, String> getAddressOrGeoLocationAME = new Map<String, String>();
		Map<String, String> addressType = new Map<String, String>();
		CaseInvestigation__c caseInvestigation;
		String sObjectTypeName;
		Id caseRecordId;
		try{

			//get SObject type as this component is called from Case Detail and Case Investigation detail page on mynetwork community.
			sObjectTypeName = recordId.getSObjectType().getDescribe().getName();
			
			//if recordId is of the type = CaseInvestigation, query case investigation details
			if(sObjectTypeName.equalsIgnoreCase('CaseInvestigation__c')) {
				caseInvestigation = CaseInvestigationsSelector.newInstance().selectById(new Set<Id>{recordId}).values()[0];
				caseRecordId = caseInvestigation.Case__c;
			}
			else { 
				caseRecordId = recordId;
			}

			Case caseRecord = [Select Id, ArticleTest__c, ArticleTest__r.ReceiverAddressLine1__c, ArticleTest__r.ReceiverAddressLine2__c, ArticleTest__r.ReceiverCity__c,
				ArticleTest__r.ReceiverState__c, ArticleTest__r.ReceiverPostcode__c, ArticleTest__r.ReceiverCountry__c,
				Address2__c, ArticleTest__r.ReceiverAddress__c
				From Case Where Id =: caseRecordId];
			if(caseRecord.ArticleTest__c != null ){

				if((caseRecord.Address2__c != null)){
					String addressValue = caseRecord.Address2__c.trim();
					//Add to map to get geo location based on address (ATG) from AME
					getAddressOrGeoLocationAME.put(caseRecord.Id+'-ATG', addressValue);

					
				}

				if((caseRecord.ArticleTest__r.ReceiverAddressLine1__c != null || caseRecord.ArticleTest__r.ReceiverAddressLine2__c != null) && (caseRecord.ArticleTest__r.ReceiverCity__c != null || caseRecord.ArticleTest__r.ReceiverState__c != null || caseRecord.ArticleTest__r.ReceiverPostcode__c != null || caseRecord.ArticleTest__r.ReceiverCountry__c != null)){
					isValidManifestAddress = true;
					String streetStr ;
					if(caseRecord.ArticleTest__r.ReceiverAddressLine1__c != null){
						streetStr = caseRecord.ArticleTest__r.ReceiverAddressLine1__c;
					}
					if(caseRecord.ArticleTest__r.ReceiverAddressLine2__c != null){
						streetStr = streetStr==null?caseRecord.ArticleTest__r.ReceiverAddressLine2__c:streetStr+caseRecord.ArticleTest__r.ReceiverAddressLine2__c;
					}
					manifestAddresssDetails.streetName = streetStr;
					manifestAddresssDetails.streetCity = caseRecord.ArticleTest__r.ReceiverCity__c ;
					manifestAddresssDetails.streetState = caseRecord.ArticleTest__r.ReceiverState__c ;
					manifestAddresssDetails.streetPostCode = caseRecord.ArticleTest__r.ReceiverPostcode__c ;
					manifestAddresssDetails.streetCountry = caseRecord.ArticleTest__r.ReceiverCountry__c ;
					manifestAddresssDetails.combinedAddress = caseRecord.ArticleTest__r.ReceiverAddress__c ;
				}

				for(EventMessageTypeMapping__mdt evType: [Select MasterLabel, Category__c From EventMessageTypeMapping__mdt Where Category__c IN ('AttemptedDelivery','Delivered')]){
					eventTypes.add(evType.MasterLabel);
					//Create a set of string for attempted delivery scan
					if(evType.Category__c.equalsIgnoreCase('AttemptedDelivery')){
						attemptedEventTypes.add(evType.MasterLabel);
					}
				}
				for(EventMessage__c ev:[Select Id, EventGeoLocation__Latitude__s, EventGeoLocation__Longitude__s, EventType__c From EventMessage__c
										Where (Article__c =:caseRecord.ArticleTest__c AND EventType__c IN: eventTypes AND EventGeoLocation__Latitude__s != null AND EventGeoLocation__Longitude__s != null) order by createdDate DESC]){

					//Moved if condition into SOQL so as to fetch event messages only with geo locations
//                    if(ev.EventGeoLocation__Latitude__s != null && ev.EventGeoLocation__Longitude__s != null){
						//Add to map to get address based on geo location (GTA) from AME
						getAddressOrGeoLocationAME.put(ev.Id+'-GTA', String.valueOf(ev.EventGeoLocation__Latitude__s)+','+String.valueOf(ev.EventGeoLocation__Longitude__s));
						if(attemptedEventTypes.contains(ev.EventType__c)){
							//If event Type is Attempted Delivery
							addressType.put(ev.Id+'-GTA', 'attempted');
							attemptedLatitude = String.valueOf(ev.EventGeoLocation__Latitude__s) ;
							attemptedLongitute = String.valueOf(ev.EventGeoLocation__Longitude__s);
						}else {
							//If event type is Delivered
							addressType.put(ev.Id+'-GTA', 'delivered');
							deliveredLatitude = String.valueOf(ev.EventGeoLocation__Latitude__s) ;
							deliveredLongitute = String.valueOf(ev.EventGeoLocation__Longitude__s);
						}
//                    }
				}

				if(!getAddressOrGeoLocationAME.isEmpty()){
					//Make a single call to AME instead of 2 separate calls
					Map<String, String> resultFromAME = AMEAddressValidationController1.searchAddressOrGeoLocation(getAddressOrGeoLocationAME);
					for(String resultKey : resultFromAME.keySet()) {
						//Check if the response has value for address
						if (String.isNotBlank(resultFromAME.get(resultKey))) {
							if (resultKey.containsIgnoreCase('-GTA')) {
								if (addressType.containsKey(resultKey) && addressType.get(resultKey).equalsIgnoreCase('delivered')) {
									System.debug('addressType.get(resultKey)--->' + addressType.get(resultKey));
									deliveredAddresssDetails.combinedAddress = resultFromAME.get(resultKey);
									deliveredAddresssDetails.latitudeValue = deliveredLatitude;
									deliveredAddresssDetails.longitudeValue = deliveredLongitute;
									isValidDeliveredAddress = true;
								} else if (addressType.containsKey(resultKey) && addressType.get(resultKey).equalsIgnoreCase('attempted')) {
									System.debug('addressType.get(resultKey)--->' + addressType.get(resultKey));
									attemptedAddresssDetails.combinedAddress = resultFromAME.get(resultKey);
									attemptedAddresssDetails.latitudeValue = attemptedLatitude;
									attemptedAddresssDetails.longitudeValue = attemptedLongitute;
									isValidAttemptedAddress = true;
								}
							} else if (resultKey.containsIgnoreCase('-ATG')) {
								addresseeAddressDetails.combinedAddress = getAddressOrGeoLocationAME.get(resultKey);
								addresseeAddressDetails.latitudeValue = resultFromAME.get(resultKey).split(',')[0];
								addresseeAddressDetails.longitudeValue = resultFromAME.get(resultKey).split(',')[1];
								isValidAddresseeAddress = true;
							}
						}
					}
				}
				System.debug(isValidDeliveredAddress + ' , '+ isValidAddresseeAddress + ' , ' + isValidManifestAddress + ' , ' + isValidAttemptedAddress);
				safeLocationDetail = new SafeLocationDetails(
						(isValidAddresseeAddress && (isValidDeliveredAddress || isValidAttemptedAddress) ? true : false),
						(isValidAddresseeAddress && isValidAttemptedAddress ? attemptedAddresssDetails : null),
						(isValidAddresseeAddress && (isValidDeliveredAddress || isValidAttemptedAddress) ? addresseeAddressDetails : null),
						(isValidAddresseeAddress && (isValidDeliveredAddress || isValidAttemptedAddress) && isValidManifestAddress ? manifestAddresssDetails : null),
						(isValidAddresseeAddress && isValidDeliveredAddress ? deliveredAddresssDetails : null)
				);

			}    
		}catch(Exception e){
			System.debug('Error in fetching the data of Event message'+e.getMessage());
		}
		system.debug('safeLocationDetail--->'+safeLocationDetail);
		return safeLocationDetail ;
	}
	/**
	 * @Description : This method is used to get the google map details for Event messages havin geolocation associated.
	 */
	@AuraEnabled
	public static GeoLocationWithAddress getAddressFromGeoLocationForEventMessage(String eventRecordId){
		String latitudeStr ;
		String longitudeStr ;
		GeoLocationWithAddress geoLocationWithAddressWrap;
		try{
			EventMessage__c eventMessage = [Select Id, EventGeoLocation__Latitude__s, EventGeoLocation__Longitude__s From EventMessage__c where Id=: eventRecordId];
			
			if(eventMessage.EventGeoLocation__Latitude__s != null && eventMessage.EventGeoLocation__Longitude__s != null){
				latitudeStr = String.valueOf(eventMessage.EventGeoLocation__Latitude__s).trim() ;
				longitudeStr = String.valueOf(eventMessage.EventGeoLocation__Longitude__s).trim() ;
//                geoLocationWithAddressWrap = getAddressFromGeoLocation(latitudeStr, longitudeStr);
				Map<String, String> resultFromAME = AMEAddressValidationController1.searchAddressOrGeoLocation(new Map<String, String>{eventMessage.Id + '-GTA' => latitudeStr + ',' + longitudeStr});
				geoLocationWithAddressWrap = new GeoLocationWithAddress(latitudeStr, longitudeStr, resultFromAME.get(eventMessage.Id + '-GTA'));
			}    
		}catch(Exception e){
			geoLocationWithAddressWrap = new GeoLocationWithAddress(latitudeStr, longitudeStr, null);
		}
		return geoLocationWithAddressWrap;
	}

	public class GeoLocationWithAddress{
		@AuraEnabled
		public String geoLatitdue{get; set;}
		@AuraEnabled
		public String geoLongitude{get; set;}
		@AuraEnabled
		public String addressValue{get; set;}

		public GeoLocationWithAddress(String geoLatitudeVar, String geoLongitudeVar , String addressValueVar){
			geoLatitdue = geoLatitudeVar ;
			geoLongitude = geoLongitudeVar ;
			addressValue = addressValueVar ;
		}
	}
	/**
	 * @Description : Wrapper class for Address Details used in plotting the details on google map
	 */
	public class SafeLocationDetails{
		@AuraEnabled
		public Boolean isValid{get;set;}
		@AuraEnabled
		public AddressDetails attemptedAddress{get;set;}
		@AuraEnabled
		public AddressDetails addresseeAddress{get;set;}
		@AuraEnabled
		public AddressDetails manifestAddress{get;set;}
		@AuraEnabled
		public AddressDetails deliveredAddress{get;set;}
		public SafeLocationDetails(Boolean isValidVar, AddressDetails attemptedAddressVar, AddressDetails addresseeAddressVar, AddressDetails manifestAddressVar, AddressDetails deliveredAddressVar){
			isValid = isValidVar;
			attemptedAddress = attemptedAddressVar;
			addresseeAddress = addresseeAddressVar;
			manifestAddress = manifestAddressVar;
			deliveredAddress = deliveredAddressVar;
		}                  
	}

	public class AddressDetails{
		@AuraEnabled
		public String streetName{get;set;}   
		@AuraEnabled
		public String streetCity{get;set;}
		@AuraEnabled
		public String streetState{get;set;}
		@AuraEnabled
		public String streetPostCode{get;set;}
		@AuraEnabled
		public String streetCountry{get;set;}
		@AuraEnabled
		public String combinedAddress{get;set;}
		@AuraEnabled
		public String latitudeValue{get;set;}
		@AuraEnabled
		public String longitudeValue{get;set;}
		public AddressDetails(){
		}
	}
	@AuraEnabled
	public static List<SObject> getMyNetworkPortalUser(String searchTerm, String fieldList, String sobjectName, String fieldsToSearch) {
	   String queryString = getQueryString(searchTerm, fieldList, sobjectName, fieldsToSearch);
	   String profileName = 'MyNetwork Portal';
	   queryString += ' AND Profile.Name =' + '\'' +String.escapeSingleQuotes(profileName) + '\'';
	   queryString += ' AND isActive = true';
	   queryString += ' LIMIT ' + MAX_RESULTS;
		try {
			return Database.query(queryString);
		} catch (Exception ex) {
			throw new AuraHandledException(ex.getMessage());
		}   
	}
	private static String getQueryString(String searchTerm, String fieldList, String sobjectName, String fieldsToSearch) {
		fieldList = String.isBlank(fieldList) ? 'Id' : fieldList;
		List<String> listOfFieldsToSearch = String.isBlank(fieldsToSearch) ? new List<String>() : fieldsToSearch.split(',');
		String whereClause;
		whereClause = getWhereClause(searchTerm, listOfFieldsToSearch);
		String query = 'SELECT ' 
					 + fieldList
					 + ' FROM ' 
					 + sobjectName
					 + whereClause ;
		return query;
	}

	private static String getWhereClause(String searchTerm, List<String> listOfFieldsToSearch) {
		String searchKey = '%' + searchTerm + '%';
		String whereClause = ' WHERE (';
		if(listOfFieldsTosearch == null || listOfFieldsTosearch.isEmpty()) listOfFieldsTosearch = new List<String>{'Name'};
		for (Integer i = 0; i < listOfFieldsToSearch.size(); i++) {
			String field = listOfFieldsToSearch[i];
			whereClause += field; 
			whereClause += ' LIKE \''+String.escapeSingleQuotes(searchKey)+'\'';
			if (i + 1 < listOfFieldsToSearch.size()) whereClause += ' OR ';
		}
		whereClause += ')';
		return whereClause;
	}

	
	/**
	 * @desc: This method generate inner query for case investigation ONLY for ST case..
	 *      : When ST Product category is selected, records need to be filtered based on Case Investigation's article ID.
	 *      : When AP Product category is selected, records need to be filltered based on Case.ProductCategory. 
	 */
	private static string generateCaseInvestigationInnerQuery(String baseQuery, SelectedViewWithFiltersWrapper selectedViewWithFiltersWrp) {
		String innerQueryFilter='';
		String selectedProductCategoryVal;

		if(selectedViewWithFiltersWrp != null ) {
			selectedProductCategoryVal = (String)selectedViewWithFiltersWrp.selectedViewAndFiltersJsonObject.get('selectedProductCategoryVal');
		}

		if(selectedViewWithFiltersWrp != null 
			&& selectedViewWithFiltersWrp.selectedViewAndFiltersJsonObject.get('isStarTrackSearch') != null 
			&& (Boolean) selectedViewWithFiltersWrp.selectedViewAndFiltersJsonObject.get('isStarTrackSearch')
				&& selectedProductCategoryVal != null && selectedProductCategoryVal != '--Select--') {
			innerQueryFilter = ' WHERE Article__r.ProductCategory__c = \''+String.escapeSingleQuotes(selectedProductCategoryVal)+'\' ';
		}
		String generateCaseInvestigationInnerQuery = '( SELECT Name, Id, CreatedDate, Article__r.Name, Priority__c, LastContactCentreUpdate__c from CaseInvestigations__r '+innerQueryFilter +' ) ';

		return generateCaseInvestigationInnerQuery;
	}

	
	/**
	 @desc      : Generic method used to update 'PONUser__c' field on case and 'OwnerId' field on Case Investigations.
	 @Param     : Case and Case Investigation recordsIds, SelectedUserId from LWC component for 'Assign to user' and 
					Boolean flag to assign to self.
	 @Return    : AssignToSelfWrapper, Return the assigned user or error message if there is any issue while case update               
	 */

	 @AuraEnabled
	 public static AssignToSelfWrapper assignSelectedRecords(String recordIds, String selectedUserId, Boolean isAssignSelf){
		 Boolean errWhileUpdate = false;
		 String ErrMsg;
		 AssignToSelfWrapper assignToSelfWrap ;
		 String userName;
		 try{   
 
			 //get caseids and caseinvestigationids 
			 List<Object> rList = (List<Object>)Json.deserializeUntyped(recordIds);
			 
			 Set<Id> caseIdSet = new set<Id>();  
			 Set<Id> caseInvestigationIdSet = new set<Id>();  
 
			 //loop through list of ids and identify SObjectType.
			 //As different fields need to be updated, identification of SObjectType is required.
			 for(Object recId : rList) {
				 Id rId = (Id)recId ;
 
				 //check rId SOBJECT TYPE
				 if(rId.getSObjectType().getDescribe().getName().equalsIgnoreCase('Case')) {
					 caseIdSet.add(rId);
				 } 
				 else if(rId.getSObjectType().getDescribe().getName().equalsIgnoreCase('CaseInvestigation__c')) {
					 caseInvestigationIdSet.add(rId);
				 }
			 }
			
			 List<SObject> recordListToUpdate = new List<SObject>();
 
			 //identifying user id to update on records.
			 Id userId = isAssignSelf ? UserInfo.getUserId() : selectedUserId;
 
			 //loop through Case ids and updated PONUser__c field.
			 for(Id caseId: caseIdSet) {
				 
				 //add case record in recordsToUpdate list
				 recordListToUpdate.add(new Case(PONUser__c = userId, Id = caseId));
			 }
 
			 if(!caseInvestigationIdSet.isEmpty()) {
 
				 //loop through CI ids and assign new ownerId.
				 for(Id caseInvestigationId : caseInvestigationIdSet) {
					 //add case investigation record in recordsToUpdate list
					 recordListToUpdate.add(
						 new CaseInvestigation__c(Id = caseInvestigationId, OwnerId = userId, Status__c = MyNetworkConstants.CASE_INVESTIGATION_IN_PROGRESS_STATUS));
				 }
			 }
			 
 
			 if(!recordListToUpdate.isEmpty()) {			    
				 
				 //update records ;
				 Database.SaveResult[] srList = ApplicationDatabase.getInstance().dmlUpdate(recordListToUpdate);
 
 
				 //get user name if AssignTo user is other than logged in user
				 userName = isAssignSelf ? UserInfo.getName() : UsersSelector.newInstance().selectById(new Set<Id>{selectedUserId}).values()[0].Name;
			 }else {
				 errWhileUpdate = true;
				 ErrMsg = 'There was an issue when assigning the record. Please contact your System Administrator';
			 }
 
		 }catch(Exception e) {
			 errWhileUpdate = true;
			 ErrMsg = 'There was an issue when assigning the record. Please contact your System Administrator';
			 System.debug('Err>>>'+e.getMessage());
		 }
		 if(errWhileUpdate) {
			 assignToSelfWrap = new AssignToSelfWrapper(errWhileUpdate, ErrMsg);
		 }else {
			 errWhileUpdate = false;
			 assignToSelfWrap = new AssignToSelfWrapper(errWhileUpdate, userName);
		 }
		 return assignToSelfWrap;
	 }

	 
	/**
		@ Description : Base query to get all the cases owned by Network queue of type 'Investigation' and 'Feedback'
		@ param       : N/A
		@ return      : Query String
		*/
	private static String baseQueryForMyNetworkCaseWithCaseInvestigationArticles() {       
		String soqlSelect = 'SELECT RecordTypeId,  RecordType.DeveloperName, Id, Sent_To_Network_Date__c, Last_Status_Change__c,closedDate,Status, type, Root_cause__c, Checkbox__c, Facility_Milestones_Violated__c, CaseNumber, Priority, ReferenceID__c, Customer_Type__c, EnquirySubType__c, Address2__c, Address2Postcode__c, Network__c,Network__r.Name, PONUser__c, PONUser__r.Name, ' ;
		soqlSelect  += '(SELECT Request_Hold_Case__c,to_CCC_action__c, to_Reassign_Network__c FROM Network_Responses1__r ORDER BY CreatedDate DESC), '
					+ '( SELECT Name, Id, CreatedDate, Article__r.Name, Priority__c, LastContactCentreUpdate__c from CaseInvestigations__r '
					+'    ) '
					+' FROM Case WHERE OwnerId= ' + '\'' + networkQueue + '\'';       

		soqlSelect  += ' AND Id IN (SELECT ParentId FROM caseteammember WHERE MemberId =  ' + '\'' + userinfo.getUserId() + '\')';               

		return soqlSelect ;         
	}

	
	private static string baseQueryForStarTrackCases() {
		String soqlSelect = 'SELECT  RecordTypeId,  RecordType.DeveloperName, Id, OwnerId, Sent_To_Network_Date__c, Last_Status_Change__c,closedDate,Status, type, Root_cause__c, Checkbox__c, Facility_Milestones_Violated__c, CaseNumber, Priority, ReferenceID__c, Customer_Type__c, EnquirySubType__c, Address2__c, Address2Postcode__c, Network__c,Network__r.Name, PONUser__c, PONUser__r.Name, ' ;
		soqlSelect  += ' {0} '
					+' FROM Case WHERE OwnerId= ' + '\'' + networkQueue + '\'';       
		soqlSelect  += ' AND Id IN (SELECT ParentId FROM caseteammember WHERE MemberId =  ' + '\'' + userinfo.getUserId() + '\')';  
		
		return soqlSelect;
			
	}

	private static string baseQueryForStarTrackCasesUpdateByContactCenter() {
		String soqlSelect = 'SELECT RecordTypeId,  RecordType.DeveloperName, Id, OwnerId, Sent_To_Network_Date__c, Last_Status_Change__c,closedDate,Status, type, Root_cause__c, Checkbox__c, Facility_Milestones_Violated__c, CaseNumber, Priority, ReferenceID__c, Customer_Type__c, EnquirySubType__c, Address2__c, Address2Postcode__c, Network__c,Network__r.Name, PONUser__c, PONUser__r.Name, ' ;
		soqlSelect  += '{0} FROM Case WHERE ';               
		soqlSelect  += ' Id IN (SELECT ParentId FROM caseteammember WHERE MemberId =  ' + '\'' + userinfo.getUserId() + '\')';
		
		return soqlSelect;
			
	}

	
	/**
	@ Description : method to get all the star track updated Cases 
	@ param       : 
	@ return      : List<case> return the wrapper of cases
	*/
	private static list<case> getUpdatedStarTrackCases( String filterStr, SelectedViewWithFiltersWrapper selectedViewWithFiltersWrp) {

		//if selectedview is star track, then call star track base query.
		String baseQuery = baseQueryForStarTrackCasesUpdateByContactCenter();
		String caseInvestigationInnerQuery = generateCaseInvestigationInnerQuery(baseQuery, selectedViewWithFiltersWrp);
		String formattedBaseQuery = String.format(baseQuery, new List<String>{caseInvestigationInnerQuery});

		String finalQueryString = baseQuery;
		list<Case> caseList = new list<Case>();
		if(selectedViewWithFiltersWrp != null && selectedViewWithFiltersWrp.filter != null){
			formattedBaseQuery += selectedViewWithFiltersWrp.filter ;
		}
		formattedBaseQuery += ' Order By Priority ASC ,Sent_To_Network_Date__c ASC NULLS LAST  LIMIT 10000' ;
		System.debug('formattedBaseQuery>>>'+formattedBaseQuery);
		caseList = database.query(formattedBaseQuery);
		return caseList;
	}

	
	//get st cases
	private static list<case> getAllMYNetworkStarTrackCases(SelectedViewWithFiltersWrapper selectedViewWithFiltersWrp){
		String baseQuery = baseQueryForStarTrackCases();
		String caseInvestigationInnerQuery = generateCaseInvestigationInnerQuery(baseQuery, selectedViewWithFiltersWrp);
		String formattedBaseQuery = String.format(baseQuery, new List<String>{caseInvestigationInnerQuery});

		String finalQueryString = baseQuery;
		list<Case> caseList = new list<Case>();
		
		if(selectedViewWithFiltersWrp != null && selectedViewWithFiltersWrp.filter != null){
			formattedBaseQuery += selectedViewWithFiltersWrp.filter  ; 
		}
		formattedBaseQuery += ' Order By Priority ASC,Sent_To_Network_Date__c ASC NULLS LAST  LIMIT 10000' ;
		System.debug('formattedBaseQuery>>>'+formattedBaseQuery);
		caseList = database.query(formattedBaseQuery);
		return caseList;
	}

	
	@AuraEnabled(cacheable=true)
	public static Map<String, String> getListViewValues() { 
		Map<String, String> listViewValues = new Map<String, String>();
		
		return (MyNetworkConstants.MY_NETWORK_PORTAL_LIST_VIEWS);
	}

	/**
	@description: method used to get case record id when a component is rendered on CI detail page
	*/

	@AuraEnabled
	public static RecordDetailsWrapper getCaseRecord(Id recordId) {
		Case cRecord;
		String sObjectTypeName = recordId.getSObjectType().getDescribe().getName();
		if(sObjectTypeName.equalsIgnoreCase('CaseInvestigation__c')) {
			//query case investigation for case Id.
			CaseInvestigation__c caseInvestigation = CaseInvestigationsSelector.newInstance().
														selectById(new Set<Id>{recordId}, new Set<Object>{CaseInvestigationsSelector.Options.WITH_ARTICLES})
														.values()[0];
			cRecord = CasesSelector.newInstance().
						selectById(new Set<Id>{caseInvestigation.Case__c}, new Set<Object>{CasesSelector.Options.WITH_CHILD_INVESTIGATIONS,
						CaseInvestigationsSelector.Options.WITH_ARTICLES})
						.values()[0];
		}
		else if(sObjectTypeName.equalsIgnoreCase('Case')) {
			cRecord = CasesSelector.newInstance().selectById(new Set<Id>{recordId}, new Set<Object>{CasesSelector.Options.WITH_CHILD_INVESTIGATIONS, CaseInvestigationsSelector.Options.WITH_ARTICLES}).values()[0];
		} 

		RecordDetailsWrapper tw = new RecordDetailsWrapper(sObjectTypeName, cRecord);
		return tw;
	}

	/**
	 @Description : Returns short list of Case Enquiry Subtype and Product Category picklist fields
	*/
	@AuraEnabled(cacheable=true)
	public static List<myNetworkPickListFieldValues__mdt> getpickListValues() {
		list<myNetworkPickListFieldValues__mdt> picklistValueList = new list<myNetworkPickListFieldValues__mdt>();
		for(myNetworkPickListFieldValues__mdt mdtVar :[Select FieldName__c, MasterLabel From myNetworkPickListFieldValues__mdt order by MasterLabel asc]) {
			picklistValueList.add(mdtVar);
		}
		return picklistValueList;
	}

	/**
		@ Description	: Used to get star track cases. 
		@ param			: SelectedViewWithFiltersWrapper
		@ return		: List<Case>
	 */
	//get st cases
	@TestVisible
	private static list<case> getStarTrackCases(SelectedViewWithFiltersWrapper selectedViewWithFiltersWrp){
		//get case investigations where logged in user is a part of network assigned on CaseINvestigation.
		List<Case> starTrackCases = new List<Case>();

		//get all list of network users where logged in user is a part of
		Set<Id> networkIds = new Set<Id>();

		for(Facility_User__c fUser :  NetworkUsersSelector.newInstance().selectByUserId(new Set<Id>{userinfo.getuserid()}).values()) {
			networkIds.add(fUser.Network__c);
		}

		if(!networkIds.isEmpty()) {
			Set<Id> caseIds = new Set<Id>();
			Set<Id> caseInvestigationIds = new Set<Id>();
			
			Set<Id> updatedCaseIds = new Set<Id>();
			Set<Id> updatedCaseInvestigationIds = new Set<Id>();
			
			//get all CI records where network ID in networkIds set.
			for(CaseInvestigation__c cInv : CaseInvestigationsSelector.newInstance().selectOpenCaseInvestigationsByNetworkId(networkIds, new Set<Object>{CaseInvestigationsSelector.Options.WITH_NETWORKS}).values()){
				
				if(selectedViewWithFiltersWrp != null && selectedViewWithFiltersWrp.selectedView == 'Case_updated') {
					updatedCaseIds.add(cInv.case__c);
					updatedCaseInvestigationIds.add(cInv.Id);
				}
				else {
					caseIds.add(cInv.case__c);
					caseInvestigationIds.add(cInv.Id);
				}
			}

			//merging two sets.
			if(!updatedCaseIds.isEmpty()) {
				caseIds.addAll(updatedCaseIds);
			} 
			if(!updatedCaseInvestigationIds.isEmpty()) {
				caseInvestigationIds.addAll(updatedCaseInvestigationIds);
			} 
			
			

			//get cases with child case investigations.
			//Ids of child case investigations are passed to query selective child case investigations.
			starTrackCases = CasesSelector.newInstance().selectByIdWithCaseInvestigations(caseIds, caseInvestigationIds, new Set<Object>{CasesSelector.Options.WITH_RECORDTYPE, CaseInvestigationsSelector.Options.WITH_ARTICLES}).values();
		}
		return starTrackCases;
	}

	/**
		@ Description : Used to get below details of StarTrack Cases updated by contact center user
						a.Details as 'SUI' or 'NEW' or 'Updated'
		@ param       : N/A
		@ return      : Query String
	 */
	@TestVisible
	private static MyNetworkCasesWrapper  validationStarTrackCasesUpdatedByContactCenter(case cse, CaseInvestigation__c cInv){
		String iconMapVar ;
		String colorMapVar;
		String textMapVar;
		MyNetworkCasesWrapper myNetworkCasesWrapperVar ;

		//check case investigation record
		if(cInv != null && cInv.LastContactCentreUpdate__c != null && (cInv.LastContactCentreUpdate__c >= System.today() - 5)) {
									
			iconMapVar = cInv.Stillunderinvestigation__c ? 'SUI' : 'UPDATED';
			colorMapVar = cInv.Stillunderinvestigation__c ? 'orange' : 'Red';
			textMapVar =  cInv.Stillunderinvestigation__c ? 'Case is under investigation' : 'Case has been updated';
		}
		//check st case condition
		else if( cse.Last_Status_Change__c != null && cse.Last_Status_Change__c >= System.today() - 5) {
			//mark case as updated 
			iconMapVar = 'UPDATED';
			colorMapVar = 'Red';
			textMapVar = 'Case has been updated';
		}
		else {
			iconMapVar = 'NEW';
			colorMapVar = 'green';
			textMapVar = 'Case is awaiting action/response' ;
		}
		String casePriority = getCasePriority(cse);
		myNetworkCasesWrapperVar = new MyNetworkCasesWrapper(cse, iconMapVar, colorMapVar, textMapVar, cse.CaseNumber, cse.Id, casePriority);
	
		return myNetworkCasesWrapperVar;
	}
	
 
}