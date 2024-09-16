/**************************************************
* @Test OPCUtility_Test
Type: Utility Class for Opportunity Product Classification (OPC)
Purpose:
Used By:
History:
--------------------------------------------------
10.08.2012M. Isidro (Cloud Sherpas) Created
13.08.2012M. Isidro (Cloud Sherpas) Converted GenerateOPCBatch Schedulable Class methods to methods of this Class
15.08.2012M. Isidro (Cloud Sherpas) Consolidation of logic flow and OPCUtility Class
22.08.2012M. Isidro (Cloud Sherpas) Do not update growth field when Revenue Schedule is in the future
Do not raise a Case for New Customer, Cross Sell and Win Back if exception is found AND the Revenue Schedule Multi-year flag is set
31.08.2012M. Isidro (Cloud Sherpas) Added checking for null values (Revenues)
04.09.2012M. Isidro (Cloud Sherpas) Added test coverage
11.09.2012M. Isidro (Cloud Sherpas) Fixed heap size too large error
12.09.2012M. Isidro (Cloud Sherpas) Changed logic of query of existing OPC records
26.09.2012M. Isidro (Cloud Sherpas) Modified test coverage (Removed @isTest(seeAllData=true), added test data)
09.10.2012M. Isidro (Cloud Sherpas) Added custom settings for Classifications (With LFY and No LFY)
15.10.2012R. Enojas (Salesforce)Added logic to purge OPCs as part of the deleteOPCList method
18.10.2012R. Enojas (Salesforce)Added logic to aggregate NRT adjustments for OPCs with multiple related schedules
23.11.2012R. Enojas (Salesforce)Added step in CheckForException to update OPC with actual revenue when it's not the 1st of a multi-year scenario
30.04.2013Haider Raza (Aus Post)Commented the code to create the OPC Cases of type "Renewal Classification found for product but no Growth record exist"
10.09.2013C.McIntyre (Salesforce) OPC Validation Rebuild - removed legacy OPC validation code (primarily in checkforexception).
12.06.2014A. Yeo (Aus Post) Comment out to fix OPC flag issue, Case 91816, SFDC Case 10541274. Comment out code.
02/06/2020shashwat.a.nath@accenture.comFix added to bypass the opportunity creation restriction in Classic and Restrict_Using_Path_Button_for_Closure
28/06/2022 KMcGuire			 Modified for including related account sales in OPC classification
29/2/2023 Ken McGurie	allow for OPC override and forward planning
17/5/2023 Ken McGurire Modified for related products
**************************************************/
public without sharing class OPCUtility {
	public static final String[] months = new String[] { 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' };
	public static final String FIELD_SUFFIX_SCHEDULE_AMOUNT = '_Schedule_Amount__c';
	public static final String FIELD_SUFFIX_NRT_ADJUSTMENT = '_NRT_Adjustment__c';
	public static final String FIELD_SUFFIX_CLAIMED_REVENUE = '_Claimed_Revenue__c';
	public static final String FIELD_SUFFIX_GROWTH = '_Growth__c';
	public static final String FIELD_SUFFIX_GROUP_GROWTH = '_Group_Growth__c';
	public static final String FIELD_SUFFIX_ACTUAL_AMOUNT = '_Actual_Amount__c';
	public static final String FIELD_SUFFIX_GROUP_ACTUAL_AMOUNT = '_Group_Actual_Amount__c';
	public static final String CLASSIFICATION_GROWTH = 'Growth';
	public static final String CLASSIFICATION_RENEWAL = 'Renewal';
	public static final String YES = 'YES';
	public static Map<String, ParentAccountRevenue> parentAccountRevenueMap;

	/**
	This method deletes Opp_Product_Classification__c records that are not under review by Sales Manager and have matching Ids in the given list.
	It also purges the deleted records from the recycle bin.
	@param opcIdList A list of Ids of Opp_Product_Classification__c records to be deleted
	**/
	public static void deleteOPCList(List<String> opcIdList) {
		List<Opp_Product_Classification__c> delOPCList = [SELECT Id FROM Opp_Product_Classification__c where Under_Review_by_Sales_Manager__c = false and Id in : opcIdList];
		
		if (!delOPCList.isEmpty()) {
			
			delete delOPCList;

			// Added to purge OPC records
			Database.emptyRecycleBin(delOPCList);

			delOPCList.clear();
		}
	}

	/**********************************
	Description: This function appends growth classifications to a map of unique revenue schedule IDs to a classification
	based on the provided list of revenue schedules.
	If a revenue schedule has a classification of 'Growth' and its unique ID is not already present in the renewal Upsell Map,
	it is added to the map with a value of 'RENEWAL'.
	@param revenueScheduleList - A list of Revenue_Schedule__c objects to iterate over
	@param renewalUpsellMap - A map of unique IDs to classification values to append to
	@return by reference append to renewalUpsellMap param.
	Date Author What Changed
	2023-03-23 Ken McGuire Created
	****************************/
	public static void appendGrowthClassifications(List<Revenue_Schedule__c> revenueScheduleList, Map<String, String> renewalUpsellMap) {
		
		for (Revenue_Schedule__c revenueSchedule: revenueScheduleList) {
			if (revenueSchedule.Classification_c__c == CLASSIFICATION_GROWTH) {
				String uniqueId = createRevenueScheduleOpcUid(revenueSchedule);
				if (!renewalUpsellMap.containsKey(uniqueId)) {
					renewalUpsellMap.put(uniqueId, CLASSIFICATION_RENEWAL);
				}
			}
		}
	}

	/**********************************
	@description: Creates a map of unique identifiers for revenue schedules and for associated opportunity product classifications.
	@paramrsList: List<Revenue_Schedule__c> - the list of revenue schedules to create the map for
	@paramidOPCMap: Map<String, Opp_Product_Classification__c> - the map of opportunity product classifications to update or populate
	@paramidRSMap: Map<String, Revenue_Schedule__c> - the map of revenue schedules to update or populate
	@return by reference changes to idOPCMap and idRSMap params
	DateAuthorWhat Changed
	2023-03-23 Ken McGuire Created
	*********************************/
	public static void createOPCMap(List<Revenue_Schedule__c> rsList, Map<String, Opp_Product_Classification__c> idOPCMap, Map<String, Revenue_Schedule__c> idRSMap) {
		
		for (Revenue_Schedule__c rs: rsList) {
			String uniqueId = createRevenueOPCLinkUid(rs);
			// populate opc map
			Opp_Product_Classification__c opc = idOPCMap.containsKey(uniqueId) ? 
												addOPC(idOPCMap.get(uniqueId), rs): 
												populateOPC(new Opp_Product_Classification__c(), rs);
			idOPCMap.put(uniqueId, opc);
			
			// populate revenue schedule map
			if (!idRSMap.containsKey(uniqueId)) {
				idRSMap.put(uniqueId, rs);
			}
		}
	}

	/**********************************
	Description: Checks if an Opp_Product_Classification__c record exists, and if it does,
	updates the existing record. If it does not exist, inserts a new record.
	@param idOPCMap A map of Opp_Product_Classification__c records to check.
	@param idOPCExistingMap A map of existing Opp_Product_Classification__c records to compare with idOPCMap.
	@param insertOPCList A list of new Opp_Product_Classification__c records to be inserted.
	@param updateOPCList A list of existing Opp_Product_Classification__c records to be updated.
	@return None.
	Date Author What Changed
	2023-03-23 Ken McGuire Created
	**********************************/
	public static void checkIfOPCExist(Map<String, Opp_Product_Classification__c> idOPCMap, Map<String, Opp_Product_Classification__c> idOPCExistingMap, List<Opp_Product_Classification__c> insertOPCList, List<Opp_Product_Classification__c> updateOPCList) {
		// build sets for soql
		Set<String> sAccount = new Set<String>();
		Set<String> sProduct = new Set<String>();
		Set<String> sClass = new Set<String>();
		Set<String> sFY = new Set<String>();

		for (Opp_Product_Classification__c opcNew: idOPCMap.values()) {
			sAccount.add(opcNew.Account__c);
			sProduct.add(opcNew.Product__c);
			sClass.add(opcNew.Classification__c);
			sFY.add(opcNew.Financial_Year__c);
		}

		// build OPC map
		for (Opp_Product_Classification__c opcExisting: getOppProductClassification(sAccount, sProduct, sClass, sFY)) {
			String uniqueId = createRevenueOPCLinkUid(opcExisting);
			if (!idOPCExistingMap.containsKey(uniqueId)) {
				idOPCExistingMap.put(uniqueId, opcExisting);
			}
		}

		// Compare New OPC Map and Existing OPC Map (idOPCMap - New OPC records)
		for (Opp_Product_Classification__c opcNew: idOPCMap.values()) {
			String uniqueId = createRevenueOPCLinkUid(opcNew);
			Opp_Product_Classification__c opcExisting = idOPCExistingMap.get(uniqueId);

			if (opcExisting == null) {
				insertOPCList.add(opcNew);
			} else {
				updateExistingOPC(opcExisting, opcNew);
				updateOPCList.add(opcExisting);
			}
		}

		if (!updateOPCList.isEmpty()) {
			// update updateOPCList;
			Database.SaveResult[] SR = Database.update(updateOPCList, false);
			SR.clear();
		}

		if (!insertOPCList.isEmpty()) {
			// insert insertOPCList;
			Database.SaveResult[] SR = Database.insert(insertOPCList, false);
			SR.clear();
		}
	}

	/**********************************
	Description: This function returns the sum of two decimal numbers or null if both numbers are negative. If only one number is negative, it returns the positive number.
	@param arg1 - The first decimal number to add
	@param arg2 - The second decimal number to add
	@return The sum of the two numbers or null if both numbers are negative.
	Date Author What Changed
	2023-03-23 Ken McGuire Created
	****************************/
	public static Decimal sumPositiveValues(Decimal arg1, Decimal arg2) {

		if (arg1 >= 0 && arg2 >= 0) {
			return (arg1 + arg2);
		} else if (arg1 >= 0 && arg2 < 0) {
			return arg1;
		} else if (arg1 < 0 && arg2 >= 0) {
			return arg2;
		}
		return null;

	}

	/**********************************
	Description: computes growth by calculating the difference between two decimal values
	@param arg1 - The first decimal number to add
	@param arg2 - The second decimal number to add
	@return The sum of the two numbers or null if both numbers are negative.
	Date Author What Changed
	2023-03-23 Ken McGuire Created
	****************************/
	public static Decimal calculateGrowth(Decimal currentAmount, Decimal previousAmount) {
		
		if (currentAmount >= 0) {
			return previousAmount >= 0 ? currentAmount - previousAmount : currentAmount;
		}
		return null;
	}

	/**********************************
	Description: Adds the scheduled amount and NRT values of a new Opp_Product_Classification__c record into an existing OPC record.
	@param opcExisting The existing Opp_Product_Classification__c record to update.
	@param opcNew The new Opp_Product_Classification__c record containing the schedule and NRT adjustment amounts to add to the existing record.
	@return By reference change to the existing record.
	Date Author What Changed
	2023-03-23 Ken McGuire Created
	****************************/
	public static void updateExistingOPC(Opp_Product_Classification__c opcExisting, Opp_Product_Classification__c opcNew) {
		
		for (String month: months) {
			String scheduleAmountFieldName = month + FIELD_SUFFIX_SCHEDULE_AMOUNT;
			Decimal existingValue = (Decimal)opcExisting.get(scheduleAmountFieldName);
			Decimal newValue = (Decimal)opcNew.get(scheduleAmountFieldName);
			opcExisting.put(scheduleAmountFieldName, sumPositiveValues(existingValue, newValue));

			String nrtFieldName = month + FIELD_SUFFIX_NRT_ADJUSTMENT;
			existingValue = (Decimal)opcExisting.get(nrtFieldName);
			newValue = (Decimal)opcNew.get(nrtFieldName);
			opcExisting.put(nrtFieldName, sumPositiveValues(existingValue, newValue));
		}

	}

	/**********************************
	Description: adds the claimed revenue and NRT values from a Revenue Schedule to an associated OPC record
	@parameter opc - Opp_Product_Classification__c record to update
	@parameter rs - Revenue_Schedule__c record containing revenue and NRT adjustment data
	@returns the updated Opp_Product_Classification__c record
	Date Author What Changed
	2023-03-23 Ken McGuire Created
	****************************/
	public static Opp_Product_Classification__c addOPC(Opp_Product_Classification__c opc, Revenue_Schedule__c rs) {
		
		opc.Account__c = rs.Opportunity__r.AccountId;
		opc.Product__c = rs.Product__c;
		opc.Classification__c = rs.Classification_c__c;
		opc.Financial_Year__c = rs.CalendarYear__c;
		opc.Opportunity__c = rs.Opportunity__c;
		opc.Hidden_1st_of_Multi_Year__c = rs.Hidden_1st_of_Multi_Year__c == 'YES';

		for (String month: months) {
			String claimedRevenueFieldName = month + FIELD_SUFFIX_CLAIMED_REVENUE;
			String scheduleAmountFieldName = month + FIELD_SUFFIX_SCHEDULE_AMOUNT;
			Decimal claimedRevenue = (Decimal)rs.get(claimedRevenueFieldName);
			Decimal scheduleAmount = (Decimal)opc.get(scheduleAmountFieldName);
			opc.put(scheduleAmountFieldName, sumPositiveValues(scheduleAmount, claimedRevenue));

			String nrtFieldName = month + FIELD_SUFFIX_NRT_ADJUSTMENT;
			Decimal rsNRT = (Decimal)rs.get(nrtFieldName);
			Decimal opcNRT = (Decimal)opc.get(nrtFieldName);
			opc.put(nrtFieldName, sumPositiveValues(opcNRT, rsNRT));
		}

		return opc;
	}

	/**********************************
	Description: Populates an Opp_Product_Classification__c object with values from a Revenue_Schedule__c object.
	@param opc: Opp_Product_Classification__c object to be populated.
	@param rs: Revenue_Schedule__c object to be used as a source of values.
	@return Opp_Product_Classification__c object populated with values from the Revenue_Schedule__c object.
	Date Author What Changed
	2023-03-23 Ken McGuire Created
	**********************************/
	public static Opp_Product_Classification__c populateOPC(Opp_Product_Classification__c opc, Revenue_Schedule__c rs) {
		
		opc.Account__c = rs.Opportunity__r.AccountId;
		opc.Product__c = rs.Product__c;
		opc.Classification__c = rs.Classification_c__c;
		opc.Financial_Year__c = rs.CalendarYear__c;
		opc.Opportunity__c = rs.Opportunity__c;

		opc.Hidden_1st_of_Multi_Year__c = rs.Hidden_1st_of_Multi_Year__c == 'YES';

		MapMonthBasedFields(rs, FIELD_SUFFIX_CLAIMED_REVENUE, opc, FIELD_SUFFIX_SCHEDULE_AMOUNT);
		MapMonthBasedFields(rs, FIELD_SUFFIX_NRT_ADJUSTMENT, opc, FIELD_SUFFIX_NRT_ADJUSTMENT);

		return opc;

	}

	/**********************************
	Description: Populates OPC financial fields based on Relevant Revenue Schedule Amounts.
	@param opc: Opp_Product_Classification__c object to be populated.
	@param accountRevenueMap: contains revenue schedule amount summaries.
	@param opcRevenueSchedueMap: Maps OPC records to corresponding Revenue Schedule data.
	@return Opp_Product_Classification__c object populated by reference with values from the Revenue_Schedule__c object.
	Date Author What Changed
	2023-03-23 Ken McGuire Created
	**********************************/
	public static void populateOpcCalculatedFields(Opp_Product_Classification__c opc, Map<String, ParentAccountRevenue> accountRevenueMap, Map<String, Revenue_Schedule__c> opcRevenueSchedueMap) {
		// the term "this calendar year" means the OPC financial year of the current OPC record rather than the current date today.
		Integer thisYear = Integer.ValueOf(opc.Financial_Year__c);
		Integer lastYear = thisYear - 1;
		Integer yearBeforeLast = thisYear - 2;
		// If there is no account revenue for this calendar year then do not undertake any calcuations
		String thisYearYearRevenueKey = constructRevenueKey(opc.Account__c, opc.Product__c, String.ValueOf(thisYear));
		
		if (!accountRevenueMap.containsKey(thisYearYearRevenueKey)) {
			return;
		}

		// check to see if we have last year's calendar year revenue
		String lastYearRevenueKey = constructRevenueKey(opc.Account__c, opc.Product__c, String.ValueOf(lastYear));
		Boolean hasLastYearRevenue = accountRevenueMap.containsKey(lastYearRevenueKey);

		// check to see if we have the year before last year's calendar year revenue
		String yearBeforelastRevenueKey = constructRevenueKey(opc.Account__c, opc.Product__c, String.ValueOf(yearBeforeLast));
		Boolean hasYearBeforeLastYearRevenue = accountRevenueMap.containsKey(yearBeforelastRevenueKey);

		// OPC financials are based on the financial year, which means that
		// OPC financials run from July of the previous calendar year up to June of the current calendar year
		// OPC growth values need to be calculated from the account revenue which is based on the calendar year.

		// get current year revenue and get previous years revenue if they exist.
		ParentAccountRevenue accountRevenueCurrentCalendarYear = accountRevenueMap.get(thisYearYearRevenueKey);
		ParentAccountRevenue accountRevenueLastCalendarYear = hasLastYearRevenue ? accountRevenueMap.get(lastYearRevenueKey) : null;
		ParentAccountRevenue accountRevenueCalendarYearBeforeLast = hasYearBeforeLastYearRevenue ? accountRevenueMap.get(yearBeforelastRevenueKey) : null;

		// current date and contract start and end dates
		// help determine which OPC fields should be calcuated.
		YearMonth currentYearMonth = new YearMonth(Date.today());
		Revenue_Schedule__c revenueSchedule = opcRevenueSchedueMap.get(opc.Id);
		YearMonth contractStart = new YearMonth(revenueSchedule.Contract_Start_Date__c);
		YearMonth contractEnd = new YearMonth(revenueSchedule.Contract_End_Date__c);

		// Consruct logic that is used to help determine which OPC fields get calculated
		String noLFY = getNoLFYClassifications();
		boolean isNoLFY = String.isEmpty(noLFY) || String.isEmpty(opc.Classification__c) ? false : noLFY.contains(opc.Classification__c);
		boolean isRenewal = opc.Classification__c == CLASSIFICATION_RENEWAL;
		boolean isGrowth = opc.Classification__c == CLASSIFICATION_GROWTH;
		boolean isMultiYear = revenueSchedule.Multi_Year__c == YES;
		boolean isFirstYear = thisYear == contractStart.getYear();
		// determine fields to calculate
		boolean calculateGrowth = isGrowth || (isNoLFY && !isRenewal);
		boolean calcuateActual = isNoLFY && (!isMultiYear || (isMultiYear && !isFirstYear));
		// if no fields are to be calculated, return
		if (!calculateGrowth && !calcuateActual) {
			return;
		}

		// one of the tweleve months in the OPC fields
		YearMonth calculationYearMonth;
		// The current revenue that is relevant to the OPC month
		ParentAccountRevenue currentRevenueToUse;
		// the previous year revenue that is relevant to the OPC month
		ParentAccountRevenue priorRevenueToUse;

		// iterate over the 12 months in the financial year of the OPC and determine whether
		// OPC Actuals or Growth may be calculated for each of those months.
		for (integer calculationMonth = 1; calculationMonth <= 12; calculationMonth++) {
			string calculationMontName = months[calculationMonth - 1];
			if (calculationMonth < 7) {
				// the first six months of the OPC financial year correspond
				// to the first six months of the revenue schedule of the same year
				calculationYearMonth = new YearMonth(thisYear,calculationMonth);
				currentRevenueToUse = accountRevenueCurrentCalendarYear;
				priorRevenueToUse = accountRevenueLastCalendarYear;
			} else {
				// the last six months of the OPC financial year correspond
				// with the last six months of the revenue schedule of the previous year
				calculationYearMonth = new YearMonth(lastYear,calculationMonth);
				currentRevenueToUse = accountRevenueLastCalendarYear;
				priorRevenueToUse = accountRevenueCalendarYearBeforeLast;
			}
			// Only populate fields for months that fall in between the contract start and end dates
			// and there is current revenue that can be used
			if (calculationYearMonth.isBetween(contractStart, contractEnd) && currentRevenueToUse != null) {
				// set opc actual amount to the current scheduled amount.
				double currentRevenue = currentRevenueToUse.getRevenue(calculationMonth, false);
				double currentRevenueGrouped = currentRevenueToUse.getRevenue(calculationMonth, true);
				if (calcuateActual) {
					opc.put(calculationMontName + FIELD_SUFFIX_ACTUAL_AMOUNT, currentRevenue);
					opc.put(calculationMontName + FIELD_SUFFIX_GROUP_ACTUAL_AMOUNT, currentRevenueGrouped);
				}

				// only populate growth fields in the case that the current year and month is in the past
				if (calculateGrowth && calculationYearMonth.isBefore(currentYearMonth)) {
					// set the growth based on the difference between the scheduled amount of the previous and current years.
					double priorRevenue = priorRevenueToUse == null ? 0 : priorRevenueToUse.getRevenue(calculationMonth, false);
					double priorRevenueGrouped = priorRevenueToUse == null ? 0 : priorRevenueToUse.getRevenue(calculationMonth, true);
					opc.put(calculationMontName + FIELD_SUFFIX_GROWTH, calculateGrowth(currentRevenue, priorRevenue));
					opc.put(calculationMontName + FIELD_SUFFIX_GROUP_GROWTH, calculateGrowth(currentRevenueGrouped, priorRevenueGrouped));
				}
			}
		}
	}

	/**********************************
	* Description: Relates Revenue Schedule records to Opportunity Product Classification records.
	* @parameter opcList - List of Opp_Product_Classification__c records
	* @parameter rsList - List of Revenue_Schedule__c records
	* @parameter uniqueIdopcIdMap - Map<String, Id> to store the mapping of unique Ids to OPC Ids
	* @parameter opcIdRSMap - Map<String, Revenue_Schedule__c> to store the mapping of OPC Ids to Revenue Schedule records
	* This method updates the Revenue Schedule records with the associated OPC, linking them together based on unique identifiers.
	* It also retrieves related fields for the OPC records and creates a mapping of OPC Ids to Revenue Schedule records for further reference.
	* Database.SaveResult[] SR is used to update the rsList with the modified records.
	* Contract Start and End Date information is stored in the opcIdRSMap for OPC Ids present in the Revenue Schedule records.
	* Date Author What Changed
	* 2023-05-18 Ken McGure Documented
	********************************/
	public static void relateRevenueScheduleToOPC(List<Opp_Product_Classification__c> opcList, List<Revenue_Schedule__c> rsList, Map<String, Id> uniqueIdopcIdMap,
		Map<String, Revenue_Schedule__c> opcIdRSMap) {
		// Update Revenue Schedule records with the associated OPC
		Set<String> opcIdList = new Set<String>();
		// create map to link opc with Revenue Schedule
		for (Opp_Product_Classification__c opc: opcList) {
			opcIdList.add(opc.Id);
			uniqueIdopcIdMap.put(createRevenueOPCLinkUid(opc), opc.Id);
		}

		// Query OPC records to include related fields
		if (!opcIdList.isEmpty()) {
			opcList = getOppProductClassification(opcIdList);
		}

		// Update Revenue Schedule records with the corresponding OPC Ids for reference
		// This joins revenue schedule calendar year with OPC Finanical Year.
		for (Revenue_Schedule__c rs: rsList) {
			String uniqueId = createRevenueOPCLinkUid(rs);

			if (uniqueIdopcIdMap.containsKey(uniqueId)) {
				rs.Opportunity_Product_Classification__c = uniqueIdopcIdMap.get(uniqueId);
			}
		}

		if (!rsList.isEmpty()) {
			// update rsList;
			Database.SaveResult[] SR = Database.update(rsList, false);

			SR.clear();

			// Create OPC Id to Revenue Schedule Map to get Contract Start and End Date
			for (Revenue_Schedule__c rs: rsList) {
				if (rs.Opportunity_Product_Classification__c != null) {
					if (!opcIdRSMap.containsKey(rs.Opportunity_Product_Classification__c)) {
						opcIdRSMap.put(rs.Opportunity_Product_Classification__c, rs);
					}
				}
			}
		}
	}

	/**********************************
	* Description: Relates Revenue Schedule records to Opportunity Product Classification records.
	* @parameter opcList - List of Opp_Product_Classification__c records
	* @parameter rsList - List of Revenue_Schedule__c records
	* This method matches Revenue Schedule records with corresponding Opportunity Product Classification records based on specific criteria.
	* It updates the Revenue Schedule records with the corresponding OPC Ids, linking them together.
	* Date Author What Changed
	* 2023-05-18 Ken McGuire Documented
	********************************/
	public static void relateRevenueScheduleToOPC1(List<Opp_Product_Classification__c> opcList, List<Revenue_Schedule__c> rsList) {
		
		Set<String> opcIds = new Set<String>();

		for (Opp_Product_Classification__c opc: opcList) {
			opcIds.add(opc.Id);
		}

		// Query OPC records to include related fields
		if (!opcIds.isEmpty()) {
			opcList = getOppProductClassification(opcIds);
		}

		// Loop through each Revenue Schedule record
		for (Revenue_Schedule__c rs: rsList) {
			// Loop through each related OPC record and check if there's a match
			for (Opp_Product_Classification__c opc: opcList) {
				if (rs.Opportunity__r.AccountId == opc.Account__c && rs.Product__c == opc.Product__c && rs.Classification_c__c == opc.Classification__c) {
					// If there's a match, update the Revenue Schedule record with the corresponding OPC Id
					rs.Opportunity_Product_Classification__c = opc.Id;
					break;
				}
			}
		}

		// Update the Revenue Schedule records
		if (!rsList.isEmpty()) {
			Database.update(rsList, false);
		}
	}

	/**********************************
	* Description: Retrieves the value of the "With_LFY__c" field from the BatchJobSettings__c custom setting.
	* This method returns the value as a String.
	* Date Author What Changed
	* 2023-05-18 Ken McGuire Documented
	********************************/
	public static String getWithLFYClassifications() {
		String sWithLFY = BatchJobSettings__c.getInstance().With_LFY__c;
		return (sWithLFY);
	}

	/**********************************
	* Description: Retrieves the value of the "No_LFY__c" field from the BatchJobSettings__c custom setting.
	* This method returns the value as a String.
	* Date Author What Changed
	* 2023-05-18 Ken McGuire Documented
	********************************/
	public static String getNoLFYClassifications() {
		String sNoLFY = BatchJobSettings__c.getInstance().No_LFY__c;
		return (sNoLFY);
	}

	/**********************************
	* Description: Checks for exceptions related to Opportunity Product Classification records.
	* @parameter opcList - List of Opp_Product_Classification__c records
	* @parameter idBARMap - Map<String, ParentAccountRevenue> to store the mapping of Ids to ParentAccountRevenue objects
	* @parameter opcIdRSMap - Map<String, Revenue_Schedule__c> to store the mapping of OPC Ids to Revenue Schedule records
	* @parameter caseList - List of Case records
	* @parameter rtId - String representing the Case record type Id
	* @parameter rsList - List of Revenue_Schedule__c records
	* This method populates the calculated fields of the Opp_Product_Classification__c records using the idBARMap and opcIdRSMap.
	* It then updates the opcList with the modified records using Database.update method.
	* The requeryOPCList method is used to retrieve and return the updated opcList based on the OPC Ids.
	* Date Author What Changed
	* 2023-05-18 Ken McGuire Documented
	********************************/
	public static void checkForException(List<Opp_Product_Classification__c> opcList, Map<String, ParentAccountRevenue> idBARMap, Map<String, Revenue_Schedule__c> opcIdRSMap, List<Case> caseList,
		
		String rtId, List<Revenue_Schedule__c> rsList) {
		for (Opp_Product_Classification__c opc: opcList) {
			populateOpcCalculatedFields(opc, idBARMap, opcIdRSMap);
		}
		// update opcList;
		Database.SaveResult[] SR = Database.update(opcList, false);

	}

	/**
	 * This method re-queries the provided list of Opp_Product_Classification__c records from the database.
	 * 
	 * Given a list of Opp_Product_Classification__c records, it extracts their Ids, checks for non-null and non-empty conditions,
	 * and re-queries the records from the database using these Ids. It returns the re-queried list of Opp_Product_Classification__c records.
	 * If the given list is null or if it doesn't contain any records, the method returns null.
	 * 
	 * The purpose of this method is to refresh the list of Opp_Product_Classification__c records to include any updates that
	 * might have occurred to the records in the database after they were initially queried. This is particularly useful
	 * in scenarios where these records might have been updated by other processes or triggers in the interim.
	 *
	 * @param opcList The list of Opp_Product_Classification__c records to re-query. This list can be null or empty.
	 * @return A refreshed list of Opp_Product_Classification__c records re-queried from the database, or null if the input list is null or empty.
	 */
	public static List<Opp_Product_Classification__c> requeryOPCList(List<Opp_Product_Classification__c> opcList) {
		if (opcList == null) {
			return null;
		}
			
		Set<String> opcIds = new Set<String>();

		for (Opp_Product_Classification__c opc: opcList) {
			opcIds.add(opc.Id);
		}

		if (opcIds.size() == 0) {
			return null;
		}
			
		return getOppProductClassification(opcIds);

	}

	/**********************************
	* Description: maps fields prefixed with months from one data object to another
	* @parameter mapFromObject - the source object
	* @parameter mapFromField - the source object field postfix
	* @parameter mapToObject - the destination object
	* @parameter mapToField - the destination field
	* @returns by reference populates the map to field on the map to object with the map from field on the map from object.
	Date Author What Changed
	2023-03-23 Ken McGuire Created
	********************************/
	public static void MapMonthBasedFields(SObject mapFromObject, String mapFromField, SObject mapToObject, String mapToField) {
		
		for (String month: months) {
			String mapFromFieldName = month + mapFromField;
			string mapToFieldName = month + mapToField;
			mapToObject.put(mapToFieldName, mapFromObject.get(mapFromFieldName));
		}

	}

	/**********************************
	Description: calculates totals for account revenue by product by year for specified acocunts and specified products.
	@param accountIdList : the accounts to calculate revenue summaries for
	@param prodIdList : the products to limit the calculation to
	@returnresults are stored in a local key, value map suitable for lazy loading,
						where the key is a composite of account, product and year and the value is a parent account revenue data structure.
	Date Author What Changed
	2023-03-23 Ken McGuire Created
	2023-04-17 - added product replacement logic
	****************************/
	public static void calculateParentAccountRevenueMap(List<String> acctIdList, List<String> revenueSchedueProductIds) {
		
		if (parentAccountRevenueMap != null) {
			return;
		}
			
		Set<String> accountIdSet = new Set<String>(acctIdList);
		Set<Id> productIdSet = new Set<Id>();
		for(String s : revenueSchedueProductIds){
			productIdSet.add((Id)s);
		}
		Map<String, String> parentChildAccountIdMap = getParentChildAccountIdMap(accountIdSet);
		accountIdSet.addAll(parentChildAccountIdMap.keySet());
		// get all revenue data for all relevant accounts
		List<Budget_and_Revenue__c> budgetAndRevenues = getBudgetAndRevenue(accountIdSet);
		// Determine all the products associated with the revenue data
		Set<Id> productsWithRevenue = new Set<Id>();
		for (Budget_and_Revenue__c currentRecord: budgetAndRevenues) {
			productsWithRevenue.add(currentRecord.Product__c);
		}
		// retrieve any replacement products where
		// the products with revenue (related product) has been replaced with a parent product (in the revenue schedue products)
		Map<String, Set<String>> productReplacementIdMap = getReplacementProductIdMap(productsWithRevenue, productIdSet);
		calculateParentAccountRevenueMap(parentChildAccountIdMap, productReplacementIdMap, budgetAndRevenues);
	}

	/**********************************
	Description: calculates totals for account revenue by product by year for specified accounts..
	@param accountIdSet : the accounts to calculate revenue summaries for
	@returnresults are stored in a local key, value map suitable for lazy loading,
						where the key is a composite of account, product and year and the value is a parent account revenue data structure.
	Date Author What Changed
	2023-03-23 Ken McGuire Created
	2023-04-17 - added product replacement logic
	****************************/
	public static void calculateParentAccountRevenueMap(Set<String> accountIdSet, Set<String> opportunityProductIds) {
		
		if (parentAccountRevenueMap != null) {
			return;
		}
		Set<Id> productIdSet = new Set<Id>();
		for(String s : opportunityProductIds){
			productIdSet.add((Id)s);
		}
		// Add child accounts to the list of accounts that revenue data is required for
		Map<String, String> parentChildAccountIdMap = getParentChildAccountIdMap(accountIdSet);
		accountIdSet.addAll(parentChildAccountIdMap.keySet());
		// get all revenue data for all relevant accounts
		List<Budget_and_Revenue__c> budgetAndRevenues = getBudgetAndRevenue(accountIdSet);
		// Determine all the products associated with the revenue data
		Set<Id> productsWithRevenue = new Set<Id>();
		for (Budget_and_Revenue__c currentRecord: budgetAndRevenues) {
			productsWithRevenue.add(currentRecord.Product__c);
		}
		// retrieve any replacement products where
		// the products with revenue (related product) has been replaced with a parent product (in the opportunity products)
		Map<String, Set<String>> productReplacementIdMap = getReplacementProductIdMap(productsWithRevenue, productIdSet);
		// build a table of account revenue
		calculateParentAccountRevenueMap(parentChildAccountIdMap, productReplacementIdMap, budgetAndRevenues);
	
	}

	/**********************************
	Description: calculates totals for account revenue by product by year.
	@param parentChildAccountMap : the child accounts to associate with parents
	@param budetAndRevenue : relevant budget and revenue records to summarise.
	@returnresults are stored in a local key, value map suitable for lazy loading,
		where the key is a composite of account, product and year and the value is a parent account revenue data structure.
	Date Author What Changed
	2023-03-23 Ken McGuire Created
	2023-04-17 - Ken McGuire added product replacement logic
	2024-08-22 - Ken McGuire temporary remove product replacement logic.
	****************************/
	private static void calculateParentAccountRevenueMap(Map<String, String> parentChildAccountIdMap, Map<String, Set<String>> productReplacementIdMap, List<Budget_and_Revenue__c> budgetAndRevenue) {
		
		if (parentAccountRevenueMap != null) {
			return;
		}
			
		parentAccountRevenueMap = new Map<String, ParentAccountRevenue>();
		for (Budget_and_Revenue__c bar: budgetAndRevenue) {
			// revenue for children account are rolled up into the parent account
			boolean isChildAccount = parentChildAccountIdMap.containsKey(bar.Organisation__c);
			Id parentAccountId = isChildAccount ? parentChildAccountIdMap.get(bar.Organisation__c) : bar.Organisation__c;
			// revenue for products that have been replaced are rolled up into a parent product

			String revenueKey = constructRevenueKey(parentAccountId, bar.Product__c, bar.Financial_Year__c);
			if (parentAccountRevenueMap.containsKey(revenueKey)) {
				parentAccountRevenueMap.get(revenueKey).add(bar, isChildAccount);
			} else {
				parentAccountRevenueMap.put(revenueKey, new ParentAccountRevenue(parentAccountId, bar, isChildAccount));
			}

			// roll up child product revenues into their replacement products
			/*if (productReplacementIdMap.containsKey(bar.Product__c)) {
				for (String replacementProductId: productReplacementIdMap.get(bar.Product__c)) {
					revenueKey = constructRevenueKey(parentAccountId, replacementProductId, bar.Financial_Year__c);
					if (parentAccountRevenueMap.containsKey(revenueKey)) {
						parentAccountRevenueMap.get(revenueKey).add(bar, isChildAccount);
					} else {
						parentAccountRevenueMap.put(revenueKey, new ParentAccountRevenue(parentAccountId, bar, replacementProductId, isChildAccount));
					}
				}
			}*/
		}
	}

	/**********************************
	Description: Retreaves budget and revenue records for all products associated with specified accounts.
	@param accountIdSet : the accounts
	@returna list of budget and revenue associated with the accounts.
		Date Author What Changed
		2023-03-23 Ken McGuire Created
	****************************/
	private static List<Budget_and_Revenue__c> getBudgetAndRevenue(Set<String> accountIdSet) {
		return [
			SELECT Organisation__c, Product__c, Financial_Year__c, Jan_Revenue_Amount__c, Feb_Revenue_Amount__c, Mar_Revenue_Amount__c, Apr_Revenue_Amount__c, May_Revenue_Amount__c, Jun_Revenue_Amount__c,
			Jul_Revenue_Amount__c, Aug_Revenue_Amount__c, Sep_Revenue_Amount__c, Oct_Revenue_Amount__c, Nov_Revenue_Amount__c, Dec_Revenue_Amount__c,
			Total_Revenue_Amount__c FROM Budget_and_Revenue__c WHERE Organisation__c IN : accountIdSet AND Financial_Year__c != NULL LIMIT : (LIMITS.getLimitQueryRows() - LIMITS.getQueryRows())
		];
	}

	/*
	*@description: Associates a child product that is to be replaced with a parent product
	*@parameter productIdSet : the child products that may be replaced
	*@returns a Map associating a child product with all the parent products that replace it.
	*/
	private static Map<String, Set<String>> getReplacementProductIdMap(Set<Id> relatedProductsToInclude, Set<id> parentProductsToInclude) {
		Map<String, Set<String>> replacementProductIdMap = new Map<String, Set<String>>();
		if (relatedProductsToInclude == null || parentProductsToInclude==null || relatedProductsToInclude.isEmpty() || parentProductsToInclude.isEmpty()) {
			return replacementProductIdMap;
		}

		list<ProductRelationship__c>  productRelationships = ProductRelationshipsSelector.newInstance().selectByRelatedAndParent(relatedProductsToInclude, parentProductsToInclude);
		for (ProductRelationship__c prr: productRelationships) {
			if (!replacementProductIdMap.containsKey(prr.RelatedProduct__c)) {
				replacementProductIdMap.put(prr.RelatedProduct__c, new Set<String>());
			}
			replacementProductIdMap.get(prr.RelatedProduct__c).add(prr.ParentProduct__c);
		}
		return replacementProductIdMap;
	}

	/**********************************
	Description: Associates child account records with a parent account.
	@param accountIdSet : the parent accounts
	@return a Map associating child accounts with parent accounts.
	Date Author What Changed
	2023-03-23 Ken McGuire Created
	****************************/
	private static Map<String, String> getParentChildAccountIdMap(Set<String> accountIdSet) {

		Map<String, String> parentChildAccountIdMap = new Map<String, String>();
		for (AccountRelationship__c acr: [
				SELECT ParentAccount__c, RelatedAccount__c 
				FROM AccountRelationship__c 
				WHERE ParentAccount__c in : accountIdSet 
				AND Relationship__c = 'OPC' 
				AND EndDate__c = null 
				LIMIT : (LIMITS.getLimitQueryRows() - LIMITS.getQueryRows())
			]) {
			parentChildAccountIdMap.put(acr.RelatedAccount__c, acr.ParentAccount__c);
		}
		return parentChildAccountIdMap;
	}

	/**********************************
	Description: This function creates a unique identifier (UID) for a given Revenue_Schedule__c object based on its related Opportunity Account ID, product, contract start date, and contract end date.
	@param revenueSchedule - The Revenue_Schedule__c object to create a UID for.
	@return A string containing the unique identifier for the Revenue_Schedule__c object.
	Date Author What Changed
	2023-03-23 Ken McGuire Created
	****************************/
	@testVisible
	private static String createRevenueScheduleOpcUid(Revenue_Schedule__c revenueSchedule) {
		return revenueSchedule.Opportunity__r.AccountId + ':' + revenueSchedule.Product__c + ':' + revenueSchedule.Contract_Start_Date__c + ':' + revenueSchedule.Contract_End_Date__c;
	}

	/**********************************
	Description: This function creates a unique identifier (UID) for a given Revenue_Schedule__c object
		based on its related Opportunity Account ID, product, classification, and calendar year.
		This Uid is used to link Revenue Schedules with associated opportunity product classifications.
	@param revenueSchedule - The Revenue_Schedule__c object to create a UID for.
	@return A string containing the unique identifier for the Revenue_Schedule__c object.
	Date Author What Changed
	2023-03-23 Ken McGuire Created
	****************************/
	@testVisible
	private static String createRevenueOPCLinkUid(Revenue_Schedule__c revenueSchedule) {
		return revenueSchedule.Opportunity__r.AccountId + ':' + revenueSchedule.Product__c + ':' + revenueSchedule.Classification_c__c + ':' + revenueSchedule.CalendarYear__c;
	}

	/**********************************
	Description: This function creates a unique identifier (UID) for a given Opp_Product_Classification__c object
		based on its related Account, product, classification, and financial year.
		This Uid is used to link Revenue Schedules with associated opportunity product classifications.
	@param revenueSchedule - The Revenue_Schedule__c object to create a UID for.
	@return A string containing the unique identifier for the Revenue_Schedule__c object.
	Date Author What Changed
	2023-03-23 Ken McGuire Created
	****************************/
	@testVisible
	private static String createRevenueOPCLinkUid(Opp_Product_Classification__c opportunityProductClassification) {
		return opportunityProductClassification.Account__c + ':' 
		+ opportunityProductClassification.Product__c + ':' 
		+ opportunityProductClassification.Classification__c + ':' 
		+ opportunityProductClassification.Financial_Year__c;
	}

	// Unique Identifiers for Map Construction

	/**********************************
	@description: Generates a unique identifier for a budget and revenue record associated with a specified account.
	@param parentAccountId: String - the identifier of the parent account
	ProductId: String - the identifier of the product
	financialYear: String - the financial year for which the record is associated
	@return String - unique identifier for a budget and revenue record associated with a specified account.
	Date Author What Changed
	2022-07-22 Ken McGuire Created
	*********************************/
	public static String constructRevenueKey(String parentAccountId, string ProductId, String financialYear) {
		return parentAccountId + ':' + ProductId + ':' + financialYear;
	}

	// override for above method using Ids instead of Strings
	public static String constructRevenueKey(Id parentAccountId, Id ProductId, Integer financialYear) {
		return constructRevenueKey(String.valueOf(parentAccountId), String.valueOf(ProductId), String.valueOf(financialYear));
	}

	// SOQL CALLS

	// Retrieve opportunity product classification records from a list of ids;
	private static List<Opp_Product_Classification__c> getOppProductClassification(Set<String> opcIdList) {
		return [
			Select Id,
			Product__r.Name,
			Product__r.Id,
			Opportunity__r.OwnerId,
			Opportunity__r.Id,
			Opportunity__c,
			Account__r.Name,
			Account__r.Id,
			Account__c,
			Product__c,
			Classification__c,
			Financial_Year__c,
			Hidden_Under_Review__c,
			Hidden_1st_of_Multi_Year__c,
			Hidden_Renewal_Missing_Growth__c,
			Jan_Growth__c,
			Feb_Growth__c,
			Mar_Growth__c,
			Apr_Growth__c,
			May_Growth__c,
			Jun_Growth__c,
			Jul_Growth__c,
			Aug_Growth__c,
			Sep_Growth__c,
			Oct_Growth__c,
			Nov_Growth__c,
			Dec_Growth__c,

			Jan_Actual_Amount__c,
			Feb_Actual_Amount__c,
			Mar_Actual_Amount__c,
			Apr_Actual_Amount__c,
			May_Actual_Amount__c,
			Jun_Actual_Amount__c,
			Jul_Actual_Amount__c,
			Aug_Actual_Amount__c,
			Sep_Actual_Amount__c,
			Oct_Actual_Amount__c,
			Nov_Actual_Amount__c,
			Dec_Actual_Amount__c,

			Jan_Schedule_Amount__c,
			Feb_Schedule_Amount__c,
			Mar_Schedule_Amount__c,
			Apr_Schedule_Amount__c,
			May_Schedule_Amount__c,
			Jun_Schedule_Amount__c,
			Jul_Schedule_Amount__c,
			Aug_Schedule_Amount__c,
			Sep_Schedule_Amount__c,
			Oct_Schedule_Amount__c,
			Nov_Schedule_Amount__c,
			Dec_Schedule_Amount__c

				From Opp_Product_Classification__c Where Id in : opcIdList
		];
	}

	// Retrieve opportunity product classification records from a list of related records;
	private static List<Opp_Product_Classification__c> getOppProductClassification(Set<String> accountIds, Set<String> productIds, Set<String> classifications, Set<String> financialYears) {
		return [
			Select Id, Account__c, Product__c, Classification__c, Financial_Year__c, Jan_Schedule_Amount__c, Feb_Schedule_Amount__c, Mar_Schedule_Amount__c, Apr_Schedule_Amount__c, May_Schedule_Amount__c,
			Jun_Schedule_Amount__c, Jul_Schedule_Amount__c, Aug_Schedule_Amount__c, Sep_Schedule_Amount__c, Oct_Schedule_Amount__c, Nov_Schedule_Amount__c, Dec_Schedule_Amount__c,

			// Additional fields as per CR 27
			Jan_NRT_Adjustment__c, Feb_NRT_Adjustment__c, Mar_NRT_Adjustment__c, Apr_NRT_Adjustment__c, May_NRT_Adjustment__c, Jun_NRT_Adjustment__c, Jul_NRT_Adjustment__c, Aug_NRT_Adjustment__c,
			Sep_NRT_Adjustment__c, Oct_NRT_Adjustment__c, Nov_NRT_Adjustment__c,
			Dec_NRT_Adjustment__c

			From Opp_Product_Classification__c Where CreatedDate =
			today And Account__c in : accountIds And Product__c in : productIds And Classification__c in : classifications And Financial_Year__c in : financialYears
		];
	}

	/**********************************
	@description: Data structure for representing a year and month combination
	and providing helper methods for comparison
	Date Author What Changed
	2023-03-29 Ken McGuire Created
	*********************************/
	public class YearMonth {
		private Integer year;
		private Integer month;
		public YearMonth(Date dateToUse) {
			this.year = dateToUse.year();
			this.month = dateToUse.month();
		}
		public YearMonth(Integer year, Integer month) {
			this.year = year;
			this.month = month;
		}

		public Integer getYear() {
			return year;
		}

		public Integer getMonth() {
			return month;
		}

		public override String toString() {
			return String.valueOf(year) + String.valueOf(month).leftPad(2, '0');
		}

		public Boolean isBefore(YearMonth other) {
			if (this.year < other.getYear()) {
				return true;
			}
			if (this.year > other.getYear()) {
				return false;
			}
			return this.month < other.getMonth();
		}

		public Boolean isAfter(YearMonth other) {
			if (this.year > other.getYear()) {
				return true;
			} 
			if (this.year < other.getYear()) {
				return false;
			}
			return this.month > other.getMonth();
		}

		public Boolean isBetween(YearMonth startBound, YearMonth endBound) {
			return this.isAfter(startBound) && this.isBefore(endBound);
		}
	}

	/**********************************
	@description: Data strucutre for containing sum total revenues for a product purchased by
	an account and its child (related) account(s) if any, for a specified calendar year
	Date Author What Changed
	2022-07-22 Ken McGuire Created
	*********************************/
	public class ParentAccountRevenue implements Comparable {
		// An array of size 24 stores (1) account revenue total (0)
		// account revenue by month (1-12)
		// total revenue of related accounts (13)
		// related account revenue by month(14-25)
		private Decimal[] Revenue;
		// used to offset the Revenue array to give account or related account info
		private final integer groupValueOffset = 13;
		// the account
		private Id accountId;
		// the product
		private Id productId;
		// the calendar year
		private String year;
		// Determines whether to return the Parent Account Revenue OR
		// the Grouped revenue being the sum of Parent Account Revenue and
		// all child account revenue figures.
		private boolean useGroupedValues;
		// public accessors to retain compatability with references by existing code
		public Id Organisation {
			get { return accountId; }
		}
		public Id Product {
			get { return productId; }
		}
		public String Financial_Year {
			get { return year; }
		}
		public Decimal Total_Revenue_Amount {
			get { return getRevenue(0); }
		}

		/*
		*Constructor
		*@parameter accountId : the account id to associate with the budget and revenue figure
		*@parameter record : the budget and revenue record to associate with the account
		*@parameter productIdOverride : a substitute product Id for the budget and revenue record
		*@returns a string identifier.
		*/
		public ParentAccountRevenue(Id accountId, Budget_and_Revenue__c record, Id productIdOverride, boolean isChildAccount) {
			this.accountId = accountId;
			productId = productIdOverride;
			year = record.Financial_Year__c;
			Revenue = new Decimal[] { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

			add(record, isChildAccount);
			useGroupedValues = false;
		}

		/*
		* Constructor
		* @parameter accountId : the account id to associate with the budget and revenue figure
		* @parameter record : the budget and revenue record to associate with the account
		* @returns a string identifier.
		*/
		public ParentAccountRevenue(Id accountId, Budget_and_Revenue__c record, boolean isChildAccount) {
			this.accountId = accountId;
			productId = record.Product__c;
			year = record.Financial_Year__c;
			Revenue = new Decimal[] { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
			add(record, isChildAccount);
			useGroupedValues = false;
		}

		/*
		* @Description : Used to build up the total revenue figures
		* @parameter accountId : the account id to associate with the budget and revenue figure
		* @parameter record : the budget and revenue record to associate with the account
		*/
		public void add(Budget_and_Revenue__c record, boolean isChildAccount) {
			integer offset = isChildAccount ? groupValueOffset : 0;
			Revenue[0 + offset] += replaceNullWithZero(record.Total_Revenue_Amount__c);
			Revenue[1 + offset] += replaceNullWithZero(record.Jan_Revenue_Amount__c);
			Revenue[2 + offset] += replaceNullWithZero(record.Feb_Revenue_Amount__c);
			Revenue[3 + offset] += replaceNullWithZero(record.Mar_Revenue_Amount__c);
			Revenue[4 + offset] += replaceNullWithZero(record.Apr_Revenue_Amount__c);
			Revenue[5 + offset] += replaceNullWithZero(record.May_Revenue_Amount__c);
			Revenue[6 + offset] += replaceNullWithZero(record.Jun_Revenue_Amount__c);
			Revenue[7 + offset] += replaceNullWithZero(record.Jul_Revenue_Amount__c);
			Revenue[8 + offset] += replaceNullWithZero(record.Aug_Revenue_Amount__c);
			Revenue[9 + offset] += replaceNullWithZero(record.Sep_Revenue_Amount__c);
			Revenue[10 + offset] += replaceNullWithZero(record.Oct_Revenue_Amount__c);
			Revenue[11 + offset] += replaceNullWithZero(record.Nov_Revenue_Amount__c);
			Revenue[12 + offset] += replaceNullWithZero(record.Dec_Revenue_Amount__c);
		}
		/*
		* @Description : sets all revenue value calculations to the grouped revenue
		*/
		public ParentAccountRevenue group() {
			useGroupedValues = true;
			return this;
		}
		/*
		* @Description : sets all revenue value calculations to the parent account revenue only
		*/
		public ParentAccountRevenue ungroup() {
			useGroupedValues = false;
			return this;
		}
		/*
		* @Description : determines if total revenue exceeds a specified value
		* @parameter value : the value to compare
		* @returns : true if the total revenue exceeds the specified value
		*/
		public Boolean totalExceeds(Double value) {
			return getRevenue(0) > value;
		}
		/*
		* @Description : returns the revenue for a specified month
		* @parameter monthIndex : the month of the revenue to return
		* @returns :
		*/
		public Decimal getRevenue(integer monthIndex) {
			return useGroupedValues ? Revenue[monthIndex] + Revenue[monthIndex + groupValueOffset] : Revenue[monthIndex];
		}
		/*
		* @Description : returns the revenue for a specified month allowing for override of current grouping
		* @parameter monthIndex : the month of the revenue to return
		* @returns :
		*/
		public Decimal getRevenue(Integer monthIndex, boolean useGrouped) {
			return useGrouped ? Revenue[monthIndex] + Revenue[monthIndex + groupValueOffset] : Revenue[monthIndex];
		}
		/*
		* @Description : returns the revenue between specified months inclusively
		* @parameter startMonth : the starting month to sum
		* @parameter endMonth : the last month to sum
		* @returns : a sum of all revenue between start and end months inclusive.
		*/
		public Decimal getRevenue(Integer startMonth, Integer endMonth) {
			Decimal totalRevenue = 0;
			for (Integer monthIndex = startMonth; monthIndex <= endMonth; monthIndex++) {
			totalRevenue += getRevenue(monthIndex);
			}
			return totalRevenue;
		}

		// Sort records by Year (desc)
		public Integer compareTo(Object compareTo) {
			ParentAccountRevenue otherRevenue = (ParentAccountRevenue)compareTo;
			if (otherRevenue == null) {
				return 1;
			}
			
			if (year == otherRevenue.year) {
				return 0;
			}
			
			if (year > otherRevenue.year) {
				return -1;
			}
			
			return 1;

		}

		private Decimal replaceNullWithZero(Decimal value) {
			return value == null ? 0 : value;
		}
	}
}