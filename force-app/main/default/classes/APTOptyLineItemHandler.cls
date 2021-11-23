/*------------------------------------------------------------
Author:   :      Jeoffrey Palmero
Date Created:    08/06/2019
Description:     Handles logic related to the Apttus Opportunity Line Item

History
<Date>           <Authors Name>     <Brief Description of Change>
08/06/2019        JPalmero           Created
------------------------------------------------------------*/
public class APTOptyLineItemHandler {
    public static void beforeInsertActions(List<APT_Opportunity_Product_Line_Item__c> newAPTOptyLineItems){
        APTOptyLineItemService.productControlWhenClosedWon(newAPTOptyLineItems, null);
        //APTOptyLineItemService.populateClassification(newAPTOptyLineItems);
        APTOptyLineItemService.overrideClassification(newAPTOptyLineItems, NULL);
    }
    
    public static void beforeUpdateActions(List<APT_Opportunity_Product_Line_Item__c> newAPTOptyLineItems, Map<Id, APT_Opportunity_Product_Line_Item__c> oldRecMap){
        // APTOptyLineItemService.lockFieldsWhenClosedWon(RecursionUtility.getUnprocessedRecords('Lock Fields When Closed Won', newAPTOptyLineItems, Constants.aptOptyLIComparisonFields()), oldRecMap);
        APTOptyLineItemService.productControlWhenClosedWon(RecursionUtility.getUnprocessedRecords('Product Control When Closed Won', newAPTOptyLineItems, Constants.aptOptyLIComparisonFields()), oldRecMap);
        APTOptyLineItemService.overrideClassification(RecursionUtility.getUnprocessedRecords('Change APT Classification', newAPTOptyLineItems, Constants.aptOptyLIComparisonFields()), oldRecMap);
        
    }
    
    public static void beforeDeleteActions(List<APT_Opportunity_Product_Line_Item__c> APTOptyLineItems) {
        APTOptyLineItemService.productControlWhenClosedWon(APTOptyLineItems, null);
    }
}