/*********************************
* Description: Handles the recursion before calling the class
* Author: Jeoffrey Palmero
* History:
* 06/04/2019        Created
********************************/
public class OpportunityHandler {
    private static Boolean isRunAfterUpdate = FALSE;
    private static Boolean isRunBeforeUpdate = FALSE;
    /*********************************
    * Description: Handles the recursion for afterUpdate
    * Author: Jeoffrey Palmero
    * History:
    * 06/04/2019        Created
    ********************************/
    public static void afterUpdateAction(List<Opportunity> newOptList, Map<Id, Opportunity> oldRecMap){
        if(!isRunAfterUpdate){
            isRunAfterUpdate = TRUE;
            OpportunityUtility.populateClassification(newOptList, oldRecMap);
            /* Shashwat.Nath@Auspost.com has commented this piece of code as classification would be required to be calculated at
               Opportunity Product Level and not at APT_Opportunity_Product_Line_Item__c Level */
             //OpportunityUtility.populateAPTClassification(newOptList, oldRecMap);
            
            /* Shashwa.Nath@Auspost.com Code commenting Ends */
        }
    }
    
    /*********************************
    * Description: Handles the recursion for beforeUpdate
    * Author: Prince Encina
    * History:
    * 07/08/2019        Created
    ********************************/
    public static void beforeUpdateAction(List<Opportunity> newOptList, Map<Id, Opportunity> oldRecMap) {
        OpportunityUtility.checkIfAllowedToCloseWin(RecursionUtility.getUnprocessedRecords('Closed Won Governance', newOptList, Constants.cwgComparisonFields()), oldRecMap);
    }
}