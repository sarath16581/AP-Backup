/*********************************
* Description: Handles the recursion before calling the class
* Author: Jeoffrey Palmero
* History:
* 06/04/2019        Created
1/10/2024 Ken McGuire removed legacy opc recalculation calls. Classificaiton is now calculated by the product revenue service.
********************************/
public class OpportunityHandler {
    @testvisible 
    private static Boolean isRunAfterUpdate = FALSE;
    @testvisible
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
        isRunBeforeUpdate = TRUE;
        OpportunityUtility.checkIfAllowedToCloseWin(RecursionUtility.getUnprocessedRecords('Closed Won Governance', newOptList, Constants.cwgComparisonFields()), oldRecMap);
    }
}