/**************************************************
* @Test GenerateOPCBatchable_Test
Type: Apex Batchable Job Class for Generation of Opportunity Product Classification (OPC)
Purpose:Generates the Opportunity Product Classification (OPC) record from their source revenue schedule(s) and 
finds any matching actual revenue against it from the current financial year and last financial year
Used By:
History:
--------------------------------------------------
10.08.2012M. Isidro (Cloud Sherpas) Created
15.08.2012M. Isidro (Cloud Sherpas) Consolidation of logic flow and OPCUtility Class
28.08.2012M. isidro (Cloud Sherpas) Fixed null error exception on Revenue Schedule
30.08.2012M. Isidro (Cloud Sherpas) Added Revenue Schedule that are reclassified but previously flagged as under review
04.09.2012M. Isidro (Cloud Sherpas) Added test coverage
11.09.2012M. Isidro (Cloud Sherpas) Fixed heap size too large error
04.10.2012M. Isidro (Cloud Sherpas) Added code to exclude Revenue Schedule where Opportunity Stage is not equal to Closed Won 
11.10.2012M. Isidro (Cloud Sherpas) Added filter to exclude OPC records under review by Sales Manager
15.10.2012R. Enojas (Salesforce)Added code to clear OPCs whose Revenue Schedules have been deleted due to 'Product Error' (CR 27)
19.12.2012	R. Enojas (Salesforce)		Changed date criteria on batch scope to start from July 1st of the CFY
28/06/2022 KMcGuire	Modified for including related account sales in OPC classification
5/07/2023 KMcGuire Modified for OPCUtil refactoring.
31/08/2023 KMcGuire Modified for extension of test class
**************************************************/

global class GenerateOPCBatchable implements Database.Batchable<SObject> {

	public static final String CLASSNAME = 'GenerateOPCBatchable';
	public static final String ORGID = UserInfo.getOrganizationId(); 
	public Boolean testRun = false;

	global GenerateOPCBatchable() {
		// Left blank for legacy code
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		Database.QueryLocator loc = Database.getQueryLocator([
		SELECT Id, Opportunity__r.AccountId, Product__c, Classification_c__c, CalendarYear__c, Opportunity__c,
		Financial_Year__c, Opportunity_Product_Classification__c, Product__r.Name, Opportunity__r.Customer_Name__c, 
		Contract_Start_Date__c, Contract_End_Date__c,Multi_Year__c, Exception_Override__c, Hidden_1st_of_Multi_Year__c,
		Jan_Claimed_Revenue__c, Feb_Claimed_Revenue__c, Mar_Claimed_Revenue__c,
		Apr_Claimed_Revenue__c, May_Claimed_Revenue__c, Jun_Claimed_Revenue__c,
		Jul_Claimed_Revenue__c, Aug_Claimed_Revenue__c, Sep_Claimed_Revenue__c,
		Oct_Claimed_Revenue__c, Nov_Claimed_Revenue__c, Dec_Claimed_Revenue__c,
		Jan_NRT_Adjustment__c, Feb_NRT_Adjustment__c, Mar_NRT_Adjustment__c,
		Apr_NRT_Adjustment__c, May_NRT_Adjustment__c, Jun_NRT_Adjustment__c,
		Jul_NRT_Adjustment__c, Aug_NRT_Adjustment__c, Sep_NRT_Adjustment__c,
		Oct_NRT_Adjustment__c, Nov_NRT_Adjustment__c, Dec_NRT_Adjustment__c
		FROM Revenue_Schedule__c
		WHERE (Opportunity__r.AccountId <> null 
		AND Opportunity__r.StageName = 'Closed Won'
		AND Product__c <> null
		AND Classification_c__c <> null
		AND CalendarYear__c <> null
		AND Financial_Year__c <> null
		AND Opportunity__c <> null)
		AND ((((Opportunity_Product_Classification__r.Hidden_Under_Review__c = false)
		OR (Opportunity_Product_Classification__r.Hidden_Renewal_Missing_Growth__c = true)
		OR (Opportunity_Product_Classification__r.Hidden_Under_Review__c = true AND (Reclassified__c = true)))
		AND (Opportunity_Product_Classification__r.Under_Review_by_Sales_Manager__c = false)))
		AND ((Contract_End_Date__c >= :getStartOfFinancialYear()) OR (Exception_Override__c = true))
		ORDER BY Opportunity__r.AccountId, Product__c, Classification_c__c, Financial_Year__c]);
        return loc;
	}



	global void execute(Database.BatchableContext bc, list<Revenue_Schedule__c> scope)
	{
		try
		{ 
			if(scope != null && scope.size() > 0)
		{
			this.executeRevenueSchedule(scope);
		}
		}
			catch(Exception ex)
		{
			UTIL_LoggingService.logHandledException(ex, ORGID, 'Generate OPC Batchable', CLASSNAME, 'execute', null, LoggingLevel.ERROR);
		}
	}

	public void executeRevenueSchedule(List<Revenue_Schedule__c> revenueSchedules) { 
		//Convert the list of Revenue_Schedule__c in scope to a map.
		Map<Id, Revenue_Schedule__c> revenueScheduleMap = new Map<Id, Revenue_Schedule__c>(revenueSchedules);
		// Maps revenue schedules that are either renewal or upsell to a schedule UID
		Map<String, String> renewalUpsellMap = new Map<String, String>();

		Map<String, Opp_Product_Classification__c> idOPCMap = new Map<String, Opp_Product_Classification__c>();
		Map<String, Revenue_Schedule__c> idRSMap = new Map<String, Revenue_Schedule__c>();
		Map<String, Id> uniqueIdopcIdMap = new Map<String, Id>();

		Map<String, Revenue_Schedule__c> opcIdRSMap = new Map<String, Revenue_Schedule__c>();
		List<Opp_Product_Classification__c> opcList = new List<Opp_Product_Classification__c>();
		List<Case> caseList = new List<Case>(); 

		Map<String, Opp_Product_Classification__c> idOPCExistingMap = new Map<String, Opp_Product_Classification__c>();
		List<Opp_Product_Classification__c> insertOPCList = new List<Opp_Product_Classification__c>();
		List<Opp_Product_Classification__c> updateOPCList = new List<Opp_Product_Classification__c>();
		List<Opp_Product_Classification__c> requeryOPCList = new List<Opp_Product_Classification__c>();

		List<String> acctIdList = new List<String>();
		List<String> prodIdList = new List<String>();

		List<String> opcIdList = new List<String>();

        List<RecordType> rc = [SELECT Id FROM RecordType WHERE IsActive = true AND SobjectType='Case' AND Name='OPC Exception' Limit 1];
        
		String rtId = rc.size()== 1 ? rc[0].id : null;

		for (Revenue_Schedule__c rs : revenueScheduleMap.values()) {
			String opcId = rs.Opportunity_Product_Classification__c;

			if (opcId != '' && opcId != null) {
				opcIdList.add( opcId );
			}

			String accountId = rs.Opportunity__r.AccountId;

			if (accountId != '' && accountId != null) {
				acctIdList.add( accountId );
			} 

			String prodId = rs.Product__c;

			if (prodId != '' && prodId != null) {
				prodIdList.add( prodId );
			} 
		} 

		// Delete all OPC records related to the Revenue Schedule records in scope
		if (!opcIdList.isEmpty()) {
			OPCUtility.deleteOPCList(opcIdList);
		}

		// For CR 27, delete all OPC records related to Revenue Schedule records that have been deleted due to 'Product Error'
		// Only delete OPCs in the context of the Organisations within scope and those that do not have any Revenue Schedules 
		List<Id> addlOPCList = new List<Id>(); 

		for (Opp_Product_Classification__c addlOPC : [SELECT Id, Account__c, Under_Review_by_Sales_Manager__c 
														FROM Opp_Product_Classification__c 
														WHERE Account__c in :acctIdList
														AND Id NOT IN (SELECT Opportunity_Product_Classification__c FROM Revenue_Schedule__c)])
		{
			if (addlOPC.Under_Review_by_Sales_Manager__c <> true) {
				addlOPCList.add(addlOPC.Id);
			}
			
		}
		if (!addlOPCList.isEmpty()) {
		OPCUtility.deleteOPCList(addlOPCList);
	}
	OPCUtility.appendGrowthClassifications(revenueScheduleMap.values(), renewalUpsellMap);
	// Create OPC from Revenue Schedule/s
	OPCUtility.createOPCMap(revenueScheduleMap.values(), idOPCMap, idRSMap);

	// After this method is executed, input parameters should be updated

	// Check if OPC records already exist
	// New OPCs will be inserted and existing OPCs will be aggregated
	OPCUtility.checkIfOPCExist(idOPCMap, idOPCExistingMap, insertOPCList, updateOPCList);


	// After this method is executed, input parameters should be updated 

	// Relate the related Revenue Schedule to the new OPC records
	OPCUtility.relateRevenueScheduleToOPC(insertOPCList, revenueScheduleMap.values(), uniqueIdopcIdMap, opcIdRSMap);


	// Create Budget and Revenue Map
		///////////
	OPCUtility.calculateParentAccountRevenueMap(acctIdList,prodIdList);
			

	// Check for exceptions
	if (!insertOPCList.isEmpty()) {
		requeryOPCList = OPCUtility.requeryOPCList(insertOPCList);
		OPCUtility.checkForException(requeryOPCList,OPCUtility.parentAccountRevenueMap,opcIdRSMap, caseList, rtId, revenueScheduleMap.values());
	}
	}

	global void finish(Database.BatchableContext BC) 
	{ 
		// Left blank for legacy code
	}
    
   	private static Date getStartOfFinancialYear() {
	// Get the current date
			Date currentDate = Date.today();

			// Get the current year
			Integer currentYear = currentDate.year();

			// Set the start date of the financial year to January 1st of the current year
			Date startOfFinancialYear = Date.newInstance(currentYear, 1, 1);

			// If the current date is before the start of the financial year, subtract a year from the start date
			if (currentDate < startOfFinancialYear) {
				startOfFinancialYear = startOfFinancialYear.addYears(-1);
			}
		return startOfFinancialYear;
	}

}