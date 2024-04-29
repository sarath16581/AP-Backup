/*
* Controller for LWC Opportunity Closure
* Description: This Controller will retrieve and update opportunity for the Opportunity Closure. 
* User Story: STP-603, STP-605
* @changelog
* 2017-10-17 - Lavanya Kavuri (lkavuri@salesforce.com) - Created
* 2023-06-11 - Ken McGuire - cleanup
* 2023-08-07 - Ranjeewa Silva - Fixed an issue where validation error messages are displayed with special characters (e.g. &quot;)
******************************************************************************************
*/

public with sharing class OpportunityClosureController {

	/*
	* Method: Validate Opportunity Stage
	* Description: This method is used to throw any validation errors when closing the opportunity without actually saving the record.
	*/

	@AuraEnabled
	public static string validateOpportunityStage(String stageName, String nextSteps, String closeComments, String closeReason, String recordId){
		SavePoint sp = Database.setSavePoint();
		List<Opportunity> optyList = [SELECT Id, Name, Amount, StageName, CloseDate, Closed_Reason__c, Closed_Comments__c FROM Opportunity WHERE Id =: recordId];
		List<Opportunity> updateList = new List<Opportunity>();
		for(Opportunity op: optyList)
		{
			op.Closed_Comments__c = closeComments;
			op.Closed_Reason__c = closeReason;
			op.StageName = stageName;
			op.Next_Step__c = nextSteps;
			op.Hidden_Restrict_Path_Closure__c = true;
			updateList.add(op);
		}
		

		Database.SaveResult[] svResult = Database.update(updateList, false );
		Integer i = 0;
		for(Database.SaveResult res : svResult)
		{
			if(!res.isSuccess())
			{
				for(Database.Error err : res.getErrors())
				{
					throw new AuraHandledException(err.getMessage().unescapeHtml4());
				}
			}
			else {
					Database.rollback(sp);
			}
		}
		return null;
	}
	
	/*
	* Method: Update Opportunity Stage 
	* Description: This method is used to Close the Opportunity and update any relevant fields. 
	*/

	@AuraEnabled
	public static String updateOpportunityStage(String stageName, String nextSteps, String closeComments, String closeReason, String recordId){
		List<Opportunity> optyList = [SELECT Id, Name, Amount, StageName, CloseDate, Closed_Reason__c, Closed_Comments__c FROM Opportunity WHERE Id =: recordId];
		List<Opportunity> updateList = new List<Opportunity>();

		try 
		{
			for(Opportunity opts: optyList)
			{
				opts.Closed_Comments__c = closeComments;
				opts.Closed_Reason__c = closeReason;
				opts.StageName = stageName;
				opts.Next_Step__c = nextSteps;
				opts.Hidden_Restrict_Path_Closure__c = true;
				updateList.add(opts);
			}
		
			update updateList;
		}
		catch(Exception e)
		{
			System.debug(Logginglevel.ERROR, e.getMessage());
			throw new AuraHandledException(e.getMessage());
		}
		return null;
	}
	
	/*
	* Method: Get Open Deal Support Requests 
	* Description: This method is used to retrieve all the Open DSR Records for a particular opportunity
	*/

	@AuraEnabled
	public static List<DealSupportWrapper> getOpenDealSupportRequests(String optyId){
		List<Deal_Support_Request__c> lstRecords = new List<Deal_Support_Request__c>(); 
		List<DealSupportWrapper> wrapperList = new List<DealSupportWrapper>();

		List<RecordType> implRecordIdsList = new List<RecordType>(); 
		List<RecordType> dealRecordIdsList = new List<RecordType>(); 

		implRecordIdsList = [Select Id, Name From RecordType where sobjecttype = 'Deal_Support_Request__c' and name LIKE '%Implementation%'];
		dealRecordIdsList = [Select Id, Name From RecordType where sobjecttype = 'Deal_Support_Request__c' and name LIKE 'Deal Enablement%'];

		Set<Id> recordTypeIds = new Set<Id>(); 
		if(!implRecordIdsList.isEmpty())
		{
			for(RecordType rec: implRecordIdsList)
			{
				recordTypeIds.add(rec.Id);
			}
		}

		if(!dealRecordIdsList.isEmpty())
		{
			for(RecordType rec: dealRecordIdsList)
			{
				recordTypeIds.add(rec.Id);
			}
		}

		lstRecords = [Select Id, Name, Stage__c, Opportunity__c, RecordType.Name, (Select Status from ProcessInstances) 
		from Deal_Support_Request__c 
		where 
		Stage__c NOT IN('Completed', 'Closed') 
		and 
		RecordTypeId NOT IN: recordTypeIds
		and
		Opportunity__c =: optyId]; 
		
		for(Deal_Support_Request__c dsr: lstRecords)
		{
			DealSupportWrapper wrapperRec = new DealSupportWrapper();
			wrapperRec.Id = dsr.Id;
			wrapperRec.Name = dsr.Name;
			wrapperRec.Stage = dsr.Stage__c;
			wrapperRec.Type = dsr.RecordType.Name;
			for(ProcessInstance pr: dsr.ProcessInstances)
			{
				wrapperRec.ApprovalStatus = pr.Status;
			}
			wrapperList.add(wrapperRec);
		}
		return wrapperList;
	}
	/*
	* Method: Close Deal Support Requests
	* Description: This method is used to close the selected DSR Records for the Opportunity.
	*/

	@AuraEnabled
	public static string closeDealSupportRequests(List<DealSupportWrapper> dsrList) {
	
		List<Deal_Support_Request__c> updateDSRRecords = new List<Deal_Support_Request__c>(); 
		System.debug('dsr List passed =' + dsrList);
		Set<Id> failedIds = new Set<Id>(); 
		Map<Id, String> errorMessageMap = new Map<Id,String>();

		for(DealSupportWrapper dsr: dsrList)
		{
			System.debug('DSR List Value=' + dsr); 
			Deal_Support_Request__c dsrRec = new Deal_Support_Request__c();
			dsrRec.Id = dsr.Id;
			dsrRec.Stage__c = 'Closed';
			dsrRec.Status__c = 'Cancelled';
			System.debug('DSR Rec Value =' + dsrRec);
			updateDSRRecords.add(dsrRec);
		}
		Database.SaveResult[] svResult = Database.update(updateDSRRecords, false );
		Integer i = 0;
		// OperationWithLimitsInLoop: Avoid operations in loops that may hit governor limits
		// Not fixed because pre-existing.
		for(Database.SaveResult res : svResult)
		{
			if(!res.isSuccess())
			{
				for(Database.Error err : res.getErrors())
				{
					for(DealSupportWrapper dsr : dsrList)
					{
						if(dsr.Id == updateDSRRecords.get(i).Id)
						{
							throw new AuraHandledException(dsr.Name + ' cannot be closed at this stage. Please contact the relevant DSR Team to' +
							' close this Request. Uncheck this record to proceed with Opportunity Closure.');
						}
					}
				}
			}
		}
		return null;
	}

	@AuraEnabled
	public static Boolean recalculateRevenue(String oppId) {
		return opcNavToBulkEditController.recalculateRevenue(oppId);
	}

	/*
	* This wrapper is used to show the DSR's as a lightning data table in the UI. 
	*/
	public class DealSupportWrapper {
		@AuraEnabled public String Id {get;set;}
		@AuraEnabled public String Name {get;set;}
		@AuraEnabled public String Stage {get;set;}
		@AuraEnabled public String Type {get;set;}
		@AuraEnabled public String ApprovalStatus {get;set;}
	}
}