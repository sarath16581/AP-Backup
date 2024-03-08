/**
 * @author Mathew Jose
 * @date 2021-03-21
 * @group Controller
 * @tag Controller
 * @domain Core
 * @description This apex class containing the server side actions/methods for oppProductDataTable(lwc).
 * @changelog
 * 2021-03-21 - Mathew Jose - Created
 * 2023-04-12 - Harry Wang - Updated getOpptyProducts using selector
 * 14/8/2023 fix for additional fields queried by selector class
*/
public with sharing class APT_OpptyProductListController {
	/**
	* This method is used to retrieve OpportunityLineItems under a given opportunity
	* @param oppId ID of the opportunity
	* @param recalculate if recalculate is required
	* @return list of OpportunityLineItems
	*/
	@AuraEnabled(Cacheable=true)
	public static List<OpportunityLineItem> getOpptyProducts(Id oppId, Boolean recalculate){
		Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
				OpportunityLineItem.SObjectType => new Set<SObjectField>{
						OpportunityLineItem.Id, OpportunityLineItem.Name, OpportunityLineItem.Classification__c, OpportunityLineItem.Change_Classification__c,
						OpportunityLineItem.Quantity, OpportunityLineItem.Contract_Start_Date__c, OpportunityLineItem.Contract_End_Date__c,
						OpportunityLineItem.UnitPrice, OpportunityLineItem.TotalPrice, OpportunityLineItem.Annualised_Value__c,
						OpportunityLineItem.Contract_Product__c, OpportunityLineItem.Contract_Number__c,OpportunityLineItem.OPCOverride__c, OpportunityLineItem.IncrementalRevenue__c, OpportunityLineItem.RetainedRevenue__c,OpportunityLineItem.TweleveMonthRevenue__c},
				Product2.SObjectType => new Set<SObjectField>{Product2.Name},
				Opportunity.SObjectType => new Set<SObjectField>{Opportunity.Name,Opportunity.AccountId,Opportunity.Id}
		};
		List<OpportunityLineItem> items = OpportunityLineItemSelector.newInstance(0, fieldOverrides).selectByOpportunity(new Set<Id>{oppId}, new Set<Object>{OpportunityLineItemSelector.Options.WITH_OPPORTUNITY, OpportunityLineItemSelector.Options.WITH_PRODUCT});
		if (recalculate) {
			return OpportunityLineItemService.getPreClassifiedLineItems(items);
		}
		return items;
	}

	/**
	 * Method to update a list of Opportunitylineitems leveraging save result.
	 * @param oppProds list of OpportunityLineItems
	 * @return JSON string returned with the status of the update as well as details of errors if any.
	 */
	@AuraEnabled
	public static string updateOppProducts(List<OpportunityLineItem> oppProds ){
		Database.SaveResult[] srList = Database.update(oppProds, false);
		// Iterate through each returned result
		Errors err = new Errors();
		List<RowError> rows = new List<RowError>();
		TableError table = new TableError();
		Set<String>tableErrorMessages = new Set<String>();
		Integer errorCount = 0;
		for(Integer i=0;i<srList.size();i++){
			if (!srList[i].isSuccess()) {
				// Operation failed, so get all errors
				for(Database.Error er : srList[i].getErrors()) {
					errorCount++;
					RowError row = new RowError();
					List<String> messageList = new List<String>();
					messageList.add(er.getMessage());
					row.rowId = oppProds[i].Id;
					//row.title = er.getStatusCode() + ': ' + er.getMessage();
					row.title = 'Error!!' ;
					row.fieldNames = er.getFields();
					row.errorMessages = messageList;
					rows.add(row);
					tableErrorMessages.addAll(messageList);
				}
			}
		}
		if(errorCount > 0){
			err.status = 'Errors';
			table.title = 'We found '+errorCount+' errors';
			table.errorMessages = new List<String>(tableErrorMessages);
			err.rows = rows;
			err.table = table;
		}else{
			err.status = 'Success';
		}
		return JSON.serialize(err);

	}
	//Wrapper class used to determine the error type accepted by lightning datatable.
	public class Errors{
		public String status;
		public RowError[] rows;
		public TableError table;
	}

	public class RowError{
		public String rowId;
		public String title;
		public String[] fieldNames;
		public String[] errorMessages;
	}
	public class TableError{
		public String title;
		public String[] errorMessages;
	}
}