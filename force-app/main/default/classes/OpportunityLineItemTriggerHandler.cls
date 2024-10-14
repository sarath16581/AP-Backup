/**************************************************
Type: Trigger Handler for OpportunityLineItem Object
Purpose: Handle Triggers for the OpportunityLineItem Object for a cleaner code coverage
--------------------------------------------------
August 2, 2018 - Created by conrad.c.v.borbon
18-01-2019 John.Mapanao@auspost.com.au Added logic for Complexity Drivers logic. Method name: processBndGActionAfterDelete() and processBndGActionAfterInsert()
28/05/2020 Lija Jawahar SOQL Error fix update
14/03/2023 Nasir Jawed Added function populateRevenueDate() to inset the Revenue start/End Date when an OLI in inserted at beforeInsertActions
02/05/2023 Ken McGuire modified opc recalculation calls to newly refactored methods.
1/10/2024 Ken McGuire removed legacy opc recalculation calls. Classificaiton is now calculated by the product revenue service.
**************************************************/
public without sharing class OpportunityLineItemTriggerHandler  extends ApplicationTriggerHandler
{
	private static final String STR_LOWER_CASE_NO = 'no';
	private static final Decimal THREE_MILLION = 3000000.00;
	private static final String APP_COMPLEXITY_DRIVERS = 'Complexity Drivers';
	private static final String METHOD_PROCESS_BNGACTIONAFTERDELETE = 'processBndGActionAfterDelete';
	private static final String METHOD_PROCESS_BNGACTIONAFTERINSERT = 'processBndGActionAfterInsert';
	private static final String TRIGGER_OLI = 'OpportunityLineItem';
	private static final String TRIGGER_OPP = 'opportunityTrigger_16112011';
	private static Boolean isRunBeforeInsert = FALSE;

	// fields to stop recursion when scoring opportunites
	// these will prvent an opportunity line item from being processed more than once in the same transaction.
	private static Set<Id> processedOppLineItemsForScoringDelete = new Set<Id> ();
	private static Set<Id> processedOppLineItemsForScoringInsert = new Set<Id> ();

	@TestVisible
	private static Set<Id> processedOpportunitiesForScoringUpdate = new Set<Id> ();
    // Application Framework Implementation
    public override void registerModules() {
        registerModule(GroupedLineItemSalesModule.class);
    }
    
	/**
	 * This defines a list of objects that may be 'touched' during module execution. 
	 * It also defines the order in which the work will be committed
	 */
	public static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{
			OpportunityLineItem.SObjectType,
			GroupedAccountProductRevenue__c.SObjectType,
			GroupedRevenueSchedule__c.SObjectType
		};
	}
    
    public override SObjectType getSObjectType() {
		return OpportunityLineItem.SObjectType;
	}

	public override ApplicationUnitOfWork newUnitOfWork() {
		return ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
	}
    
    // Legacy
	public static void OpptyLineItemAfterDelete(List<OpportunityLineItem> oliList)
	{
		// Created by conrad.c.v.borbon - August 1, 2018 - START
		List<Opportunity> updateOpptyList = new List<Opportunity> ();

		Set<Id> oppIds = new Set<Id> ();
		for (OpportunityLineItem oli: oliList)
		{
			oppIds.add(oli.OpportunityId);
		}

		//28/05/2020 Lija Jawahar Removal of SOQL inside for loop
		Map<Id, Opportunity> relatedOpptyMap = new Map<Id, Opportunity> ([
			SELECT Id, Product_Complexity_Rating__c, hidden_Complex_Product_Counter__c,
			(SELECT Id FROM OpportunityLineItems WHERE PricebookEntry.Product2.Is_Exception_Product__c = TRUE)
			FROM Opportunity
			WHERE Id IN: oppIds
		]);

		for (OpportunityLineItem oli: oliList)
		{
			// selects the Opportunity to be updated with the new product complexity rating to be performed below
			Opportunity updateOppty = relatedOpptyMap.get(oli.OpportunityId);

			// counts the number of complex products in the Opportunity
			// pass the counter to the Integer (complexProductCount)
			Integer complexProductCount = updateOppty.OpportunityLineItems.size();

			// checks the counter value (complexProductCount)
			// -- if the counter is 0 - it means there are no complex products so update the Product Complexity Rating and the hidden Complex Product Counter to 0
			// -- if the counter is not 0 - it means that there is a complex product so just update the hidden Complex Product Counter to the value of the counter
			if (complexProductCount == 0)
			{
				updateOppty.Product_Complexity_Rating__c = 0;
				updateOppty.hidden_Complex_Product_Counter__c = 0;
				/*Shashwat.Nath has added an additional check on 08/09/2020 to make sure no duplicate id's are getting added */
				If(!updateOpptyList.contains(updateOppty))
				{
					updateOpptyList.add(updateOppty);
				}
			}
			else
			{
				updateOppty.hidden_Complex_Product_Counter__c = complexProductCount;
				/*Shashwat.Nath has added an additional check on 08/09/2020 to make sure no duplicate id's are getting added */
				If(!updateOpptyList.contains(updateOppty))
				{
					updateOpptyList.add(updateOppty);
				}
			}
		}

		if (updateOpptyList.size() > 0)
		{
			update updateOpptyList;
		}

		// Created by conrad.c.v.borbon - August 1, 2018 - END
	}

	/*
	 *GIVEN Opportunity have five (5) Opportunity Line Items
	 *WHEN User delete any of the Opportunity Line Items
	 *THEN recalculate the value of "B&G Forum Attendance" field of the parent Opportunity
	 */
	public static void processBndGActionAfterDelete(Map<Id, OpportunityLineItem> oldMap)
	{
		Set<Id> oppIds = new Set<Id> ();

		// Get related opportunity ids
		for (OpportunityLineItem oli: oldMap.values())
		{
			// only process the opportunity if the opp line item hasn't already passed through here
			// this is stop stop recursion from happening.
			if (!processedOppLineItemsForScoringDelete.contains(oli.Id))
			{
				oppIds.add(oli.OpportunityID);
				processedOppLineItemsForScoringDelete.add(oli.Id);
			}
		}

		if (!oppIds.isEmpty())
		{
			// Using collected opportunity ids, query remaining opportunity line items
			Map<Id, Set < String>> oppLineItemMap = new Map<Id, Set < String>> ();
			for (OpportunityLineItem oppLineItem:[SELECT Id, OpportunityId, Product2.Product_Level_2__c
					FROM OpportunityLineItem
					WHERE OpportunityId IN: oppIds AND Id NOT IN: oldMap.keySet()
				])
			{
				if (String.isNotBlank(oppLineItem.Product2.Product_Level_2__c))
				{
					if (!oppLineItemMap.containsKey(oppLineItem.OpportunityId))
					{
						oppLineItemMap.put(oppLineItem.OpportunityId, new Set<String> ());
					}

					oppLineItemMap.get(oppLineItem.OpportunityId).add(oppLineItem.Product2.Product_Level_2__c);
				}
			}

			// Query related opportunity fields
			Map<Id, Opportunity> relatedOpportunitesMap = getDetailedOpportunities(oppIds);

			for (Opportunity opp: relatedOpportunitesMap.values())
			{
			 	// Return true if there's multiple Level 2 value from the child Opportunity Line Items per opportunity
				Boolean hasMultipleLevel2 = (oppLineItemMap.get(opp.Id) != null && oppLineItemMap.get(opp.Id).size() > 1);

				// Return true if Opportunity Annualised Value field from Opportunity is greater than or equal to 3 million
				Boolean isMoreOrEqual3mOppAnnualisedValue = (opp.Opportunity_Annualised_Value__c >= THREE_MILLION);

				// Return true if Opportunity Annualised Value field from Opportunity is less than to 3 million
				Boolean isLess3mOppAnnualisedValue = (opp.Opportunity_Annualised_Value__c < THREE_MILLION);

				// Return true if any of the questions' answer is No
				Boolean hasNoAnswerToAnyQuestions = false;
				if (STR_LOWER_CASE_NO.equalsIgnoreCase(opp.Standard_Rate_Cards__c) ||
					STR_LOWER_CASE_NO.equalsIgnoreCase(opp.Standard_Australia_Post_Contract__c) ||
					STR_LOWER_CASE_NO.equalsIgnoreCase(opp.Standard_Product_Features__c) ||
					STR_LOWER_CASE_NO.equalsIgnoreCase(opp.Standard_Operational_Requirements__c) ||
					STR_LOWER_CASE_NO.equalsIgnoreCase(opp.Implementation_or_Onboarding_Complexity__c))
				{
					hasNoAnswerToAnyQuestions = true;
				}

				setActionNeeded(opp, isMoreOrEqual3mOppAnnualisedValue, isLess3mOppAnnualisedValue, hasMultipleLevel2, hasNoAnswerToAnyQuestions);
			}

			if (!relatedOpportunitesMap.isEmpty())
			{
				updateDML(relatedOpportunitesMap.values(), METHOD_PROCESS_BNGACTIONAFTERDELETE, TRIGGER_OLI);
			}
		}
	}

	/*
	 *GIVEN Opportunity have five (5) Opportunity Line Items
	 *WHEN User add new Opportunity Line Item (Product)
	 *THEN recalculate the value of "B&G Forum Attendance" field of the parent Opportunity
	 */
	public static void processBndGActionAfterInsert(Map<Id, OpportunityLineItem> newMap)
	{
		Set<Id> oppIds = new Set<Id> ();
		Map<Id, Set < String>> oppLineItemMap = new Map<Id, Set < String>> ();
		for (OpportunityLineItem oli: newMap.values())
		{
			// only process the opportunity if the opp line item hasn't already passed through here
			// this is stop stop recursion from happening.
			if (!processedOppLineItemsForScoringInsert.contains(oli.Id))
			{
				oppIds.add(oli.OpportunityID);

				processedOppLineItemsForScoringInsert.add(oli.Id);
			}
		}

		if (!oppIds.isEmpty())
		{
			// Query opportunity line items related to the opportunity
			for (OpportunityLineItem oppLineItem:[SELECT Id, OpportunityId, Product2.Product_Level_2__c FROM OpportunityLineItem WHERE OpportunityId IN: oppIds])
			{
				if (String.isNotBlank(oppLineItem.Product2.Product_Level_2__c))
				{
					if (!oppLineItemMap.containsKey(oppLineItem.OpportunityId))
					{
						oppLineItemMap.put(oppLineItem.OpportunityId, new Set<String> ());
					}

					oppLineItemMap.get(oppLineItem.OpportunityId).add(oppLineItem.Product2.Product_Level_2__c);
				}
			}

			// Query related opportunity fields
			Map<Id, Opportunity> relatedOpportunitesMap = getDetailedOpportunities(oppIds);

			for (Opportunity opp: relatedOpportunitesMap.values())
			{
				Boolean hasMultipleLevel2 = (oppLineItemMap.get(opp.Id) != null && oppLineItemMap.get(opp.Id).size() > 1);

				Boolean isMoreOrEqual3mOppAnnualisedValue = (opp.Opportunity_Annualised_Value__c >= THREE_MILLION);
				Boolean isLess3mOppAnnualisedValue = (opp.Opportunity_Annualised_Value__c < THREE_MILLION);

				Boolean hasNoAnswerToAnyQuestions = false;

				if (STR_LOWER_CASE_NO.equalsIgnoreCase(opp.Standard_Rate_Cards__c) ||
					STR_LOWER_CASE_NO.equalsIgnoreCase(opp.Standard_Australia_Post_Contract__c) ||
					STR_LOWER_CASE_NO.equalsIgnoreCase(opp.Standard_Product_Features__c) ||
					STR_LOWER_CASE_NO.equalsIgnoreCase(opp.Standard_Operational_Requirements__c) ||
					STR_LOWER_CASE_NO.equalsIgnoreCase(opp.Implementation_or_Onboarding_Complexity__c))
				{
					hasNoAnswerToAnyQuestions = true;
				}

				setActionNeeded(opp, isMoreOrEqual3mOppAnnualisedValue, isLess3mOppAnnualisedValue, hasMultipleLevel2, hasNoAnswerToAnyQuestions);
			}

			if (!relatedOpportunitesMap.isEmpty())
			{
				updateDML(relatedOpportunitesMap.values(), METHOD_PROCESS_BNGACTIONAFTERINSERT, TRIGGER_OLI);
			}
		}
	}

	/*
	 *This method will be invoked from before update trigger event of Opportunity
	 *GIVEN Opportunity
	 *WHEN any of the complexity drivers questions has been changed
	 *THEN recalculate the value of "B&G Forum Attendance" field
	 */
	public static void processBndGActionBeforeUpdate(Map<Id, Opportunity> newMap)
	{
		// since we only want the opportunity to be processed once, we add a recurssion stopper here
		// this ensures each opportunity will only be processed the first time it enters here
		// TODO: This should also include a check to confirm if any of the necessary fields have changed value and if they have then reprocess
		Map<Id, Opportunity> processableOpps = new Map<Id, Opportunity> ();
		for (Opportunity opp: newMap.values())
		{
			if (!processedOpportunitiesForScoringUpdate.contains(opp.Id))
			{
				processedOpportunitiesForScoringUpdate.add(opp.Id);
				processableOpps.put(opp.Id, opp);
			}
		}

		if (!processableOpps.isEmpty())
		{
			Map<Id, Set < String>> oppLineItemMap = new Map<Id, Set < String>> ();
			for (OpportunityLineItem oli:[SELECT Id, OpportunityId, Product2.Product_Level_2__c FROM OpportunityLineItem WHERE OpportunityId IN: processableOpps.keySet()])
			{
				if (String.isNotBlank(oli.Product2.Product_Level_2__c))
				{
					if (!oppLineItemMap.containsKey(oli.OpportunityId))
					{
						oppLineItemMap.put(oli.OpportunityId, new Set<String> ());
					}

					oppLineItemMap.get(oli.OpportunityId).add(oli.Product2.Product_Level_2__c);
				}
			}

			for (Opportunity opp: processableOpps.values())
			{
			 	// Return true if there's multiple Level 2 value from the child Opportunity Line Items per opportunity
				Boolean hasMultipleLevel2 = (oppLineItemMap.get(opp.Id) != null && oppLineItemMap.get(opp.Id).size() > 1);

				// Return true if Opportunity Annualised Value field from Opportunity is greater than or equal to 3 million
				Boolean isMoreOrEqual3mOppAnnualisedValue = (opp.Opportunity_Annualised_Value__c >= THREE_MILLION);

				// Return true if Opportunity Annualised Value field from Opportunity is less than to 3 million
				Boolean isLess3mOppAnnualisedValue = (opp.Opportunity_Annualised_Value__c < THREE_MILLION);

				// Check if any of the complexity questions has 'No' answer
				Boolean hasNoAnswerToAnyQuestions = false;
				if (STR_LOWER_CASE_NO.equalsIgnoreCase(opp.Standard_Rate_Cards__c) ||
					STR_LOWER_CASE_NO.equalsIgnoreCase(opp.Standard_Australia_Post_Contract__c) ||
					STR_LOWER_CASE_NO.equalsIgnoreCase(opp.Standard_Product_Features__c) ||
					STR_LOWER_CASE_NO.equalsIgnoreCase(opp.Standard_Operational_Requirements__c) ||
					STR_LOWER_CASE_NO.equalsIgnoreCase(opp.Implementation_or_Onboarding_Complexity__c))
				{
					hasNoAnswerToAnyQuestions = true;
				}

				setActionNeeded(opp, isMoreOrEqual3mOppAnnualisedValue, isLess3mOppAnnualisedValue, hasMultipleLevel2, hasNoAnswerToAnyQuestions);
			}
		}
	}

	/*
	 *Query opportunity fields
	 */
	public static Map<Id, Opportunity> getDetailedOpportunities(Set<Id> oppIds)
	{
		return new Map<Id, Opportunity> ([SELECT Id, Opportunity_Annualised_Value__c, Standard_Rate_Cards__c, Standard_Australia_Post_Contract__c,
			Standard_Product_Features__c, Standard_Operational_Requirements__c, Implementation_or_Onboarding_Complexity__c
			FROM Opportunity
			WHERE Id IN: oppIds
		]);
	}

	/*
	 *Eligibility Criteria - business rules
	 *Commit to Action
	 *>= $3m Opportunity Annualised Value AND multiple ‘Level 2’ product items AND (Answer of “No” to any question in the Complexity Drivers section)
	 *Deal Desk
	 *< $3m Opportunity Annualised Value AND multiple ‘Level 2’ product items AND (Answer of “No” to any question in the Complexity Drivers section)
	 *
	 *Values to be displayed in this field:
	 *1. If the deal meets Commit to Action criteria, display - “Please contact B&GCommitToAction mailbox”
	 *2. If the deal meets Deal Desk criteria, display - “Please contact B&GDealDesk mailbox”
	 *3. If neither criteria is met, display - “Not required, see your manager to opt-in”
	 */
	public static void setActionNeeded(Opportunity opp, Boolean isMoreOrEqual3mOppAnnualisedValue, Boolean isLess3mOppAnnualisedValue, Boolean hasMultipleLevel2, Boolean hasNoAnswerToAnyQuestions)
	{
		if (isMoreOrEqual3mOppAnnualisedValue && hasMultipleLevel2 && hasNoAnswerToAnyQuestions)
		{
			// Opportunity Annualised Value >= $3m AND multiple 'Level 2' product items AND (Answer of 'No' to any questions in the Complexity Drivers section)
			// Display 'Please contact B&GCommitToAction mailbox'
			//opp.Name = Label.B_GCommitToAction;	//'Please contact B&GCommitToAction mailbox'
			opp.Hidden_B_G_Forum_Attendance__c = 'CommitToAction';
		}
		else if (isLess3mOppAnnualisedValue && hasMultipleLevel2 && hasNoAnswerToAnyQuestions)
		{
			// Opportunity Annualised Value<$3m AND multiple 'Level 2' product items AND (Answer of 'No' to any questions in the Complexity Drivers section)
			// Display 'Please contact B&GDealDesk mailbox'
			//opp.Name = Label.B_GDealDesk;	//'Please contact B&GDealDesk mailbox'
			opp.Hidden_B_G_Forum_Attendance__c = 'DealDesk';
		}
		else
		{
			//opp.Name = Label.B_GNotRequired;	//'Not required, see your manager to opt-in'
			opp.Hidden_B_G_Forum_Attendance__c = 'NotRequired';
		}
	}

	/*
	 *Method specific for dml and error handling
	 */
	public static void updateDML(List<Opportunity> toUpdateOpportunitiesList, String methodName, String triggerName)
	{
		try
		{
			update toUpdateOpportunitiesList;
		}

		catch (Exception ex)
		{
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), APP_COMPLEXITY_DRIVERS,
				OpportunityLineItemTriggerHandler.class.getName(), methodName, triggerName, LoggingLevel.ERROR);
		}
	}

	public static void beforeInsertActions(List<OpportunityLineItem> newOppLineItemList)
	{
	/*Shashwat.Nath has updated the code on 18/09/2020 to make sure only filtered list is passed to populateclassification Method 
	- This has been picked up by understanding Null Pointer Exceptions being Recorded in Exception Logs
	- With the Changes in the Product Sync, the Opportunity Products would be created without Revenue Start Dates and Classification
	would only be poulated when user manually edits the Opportunity Product record and enters the Revenue Dates.
	- Filtering the Trigger.New list to make sure only those records are passed which have Start date Populated as start date drives 
	the Classification calculation
	*/
		// populate revenue dates for for Conga related line items.
		OpportunityLineItemService.populateRevenueDate(newOppLineItemList);
		
        /********* obsolete
		// filter the line items for those which should be given OPC classifications
		List<OpportunityLineItem> populateClassificationFilteredList = new List<OpportunityLineItem>();
		
		for (OpportunityLineItem opli: newOppLineItemList)
		{
			if (opli.Contract_Start_Date__c != Null)
			{
				populateClassificationFilteredList.add(opli);
			}
		}
		// assign the classification to the filtered list of line items.

        OpportunityLineItemService.populateClassification(populateClassificationFilteredList);
		*/
    }
    
	// This method is now obsolete
	public static void beforeUpdateActions(List<OpportunityLineItem> newOppLineItemList, Map<Id, OpportunityLineItem> oldRecMap)
	{
		//OpportunityLineItemService.recalculateClassification(RecursionUtility.getUnprocessedRecords('Recalculate Classification', newOppLineItemList, Constants.optyLIComparisonFields()), oldRecMap);
	}

	public static void beforeDeleteActions(List<OpportunityLineItem> newOppLineItemList, Map<Id, OpportunityLineItem> oldRecMap)
	{
		OpportunityLineItemService.beforeDeleteValidation(newOppLineItemList);
	}
}