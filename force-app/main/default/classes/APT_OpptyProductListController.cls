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
    
    public static String getColumnDefinitions() {
        // Create a list to hold the column definitions
        List<ColumnDef> columnDefs = new List<ColumnDef>();
        
        // Helper method to add columns to the list
        columnDefs.add(createColumn('Product Name', 'ProductName', false, true, 160, null, null));
        columnDefs.add(createColumn('Revenue Start Date', 'Contract_Start_Date__c', true, false, 160, 'date-local', 'utility:stop'));
        columnDefs.add(createColumn('Revenue End Date', 'Contract_End_Date__c', true, false, 160, 'date-local', 'utility:stop'));
        columnDefs.add(createColumn('Quantity', 'Quantity', true, false, 160, 'Integer', 'utility:stop'));
        columnDefs.add(createColumnWithAlignment('Unit Sales Price (Ex GST)', 'UnitPrice', true, false, 160, 'currency', 'utility:stop', 'left'));
        columnDefs.add(createColumnWithAlignment('Total Price', 'TotalPrice', false, false, 160, 'currency', null, 'left'));
        columnDefs.add(createColumnWithAlignment('ACV', 'Annualised_Value__c', false, false, 160, 'currency', null, 'left'));
        columnDefs.add(createColumnWithAlignment('Last 12 months Revenue', 'TweleveMonthRevenue__c', false, false, 160, 'currency', null, 'left'));
        columnDefs.add(createColumnWithAlignment('Retained ACV', 'RetainedRevenue__c', false, false, 160, 'currency', null, 'left'));
        columnDefs.add(createColumnWithAlignment('Incremental ACV', 'IncrementalRevenue__c', false, false, 160, 'currency', null, 'left'));
        columnDefs.add(createColumnWithAlignment('Classification', 'Classification__c', false, false, 160, 'text', null, 'left'));
        columnDefs.add(createColumn('Quote Number', 'Contract_Number__c', true, false, 160, 'text', null));
        columnDefs.add(createColumnWithAlignment('Contract Product?', 'ContractProduct', true, false, 160, 'boolean', 'utility:stop', 'center'));
        
        // Serialize the list to JSON
        return JSON.serialize(columnDefs);
    }

    // Helper method to create a column definition without alignment
    private static ColumnDef createColumn(String label, String fieldName, Boolean editable, Boolean wrapText, Integer initialWidth, String type, String iconName) {
        ColumnDef columnDef = new ColumnDef();
        columnDef.label = label;
        columnDef.fieldName = fieldName;
        columnDef.editable = editable;
        columnDef.wrapText = wrapText;
        columnDef.initialWidth = initialWidth;
        columnDef.type = type;
        columnDef.iconName = iconName;
        return columnDef;
    }
    
    // Helper method to create a column definition with alignment
    private static ColumnDef createColumnWithAlignment(String label, String fieldName, Boolean editable, Boolean wrapText, Integer initialWidth, String type, String iconName, String alignment) {
        ColumnDef columnDef = createColumn(label, fieldName, editable, wrapText, initialWidth, type, iconName);
        columnDef.cellAttributes = new CellAttributes();
        columnDef.cellAttributes.alignment = alignment;
        return columnDef;
    }
        
	//Wrapper class used to determine the error type accepted by lightning datatable.
	Public class Errors{
		Public String status;
		Public RowError[] rows;
		Public TableError table;
	}

	Public class RowError{
		Public String rowId;
		Public String title;
		Public String[] fieldNames;
		Public String[] errorMessages;
	}
	Public class TableError{
		Public String title;
		Public String[] errorMessages;
	}
    
    public class CellAttributes
    {
        public string alignment { get; set; }
    }

    public class ColumnDef
    {
        public string label { get; set; }
        public string fieldName { get; set; }
        public boolean editable { get; set; }
        public boolean wrapText { get; set; }
        public integer initialWidth { get; set; }
        public string type { get; set; }
        public string iconName { get; set; }
        public CellAttributes cellAttributes { get; set; }
    }
}