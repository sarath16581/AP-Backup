public with sharing class AMLCTFViewActionStatementExt {
/*------------------------------------------------------------
Author:        Deepu Chacko
Company:       Salesforce
Description:   Displays Action Statement with editable list of actions
Inputs:        View action of Action Statement is overriden with VF - AMLCTFViewActionStatementExt
               which calls this extension controller
Test Class:    AMLCTFViewActionStatementExt_Test
History
<Date>          <Authors Name>      <Brief Description of Change>
15.Sep.2016     Deepu Chacko        Initial Version
------------------------------------------------------------*/
    
    public list<ActionWrapper> actions      {get; set;}     // All the actions for the given statement
    
    private AMLCTF_Audit_Action_Statement__c statement;     // Holds the reference for the primary action statement record

    // Constructor
    public AMLCTFViewActionStatementExt(ApexPages.StandardController con){
        statement = (AMLCTF_Audit_Action_Statement__c)con.getRecord();
        fetchActions();
    }
    
    // Inner class representing a record in the front-end editable table
    public class ActionWrapper {
        public boolean markedForDelete                                  {get; set;}     // Checkbox on the UI to mark actions to delete
        public boolean isUpdated                                        {get; set;}     // Hidden field to determine if an action was updated
        public AMLCTF_Audit_Action__c record                            {get; set;}     // Each action of the statement
        public list<Audit_Action_Standard_Response__c> stdResponses     {get; set;}     // Std Responses applicable
        
        public ActionWrapper(AMLCTF_Audit_Action__c p_record, list<Audit_Action_Standard_Response__c> p_responses){
            this.markedForDelete    = false;
            this.isUpdated          = false;
            this.record             = p_record;
            this.stdResponses       = p_responses;
        }
    }
    
    // Fetch the list of actions for a given statement
    // Called from the front end on load of the page
    public void fetchActions(){
        if(statement.id == null) return;        // Safety net, if the page is launched without a statement record.
        
        actions = new list<ActionWrapper>();    // Initialize the global variable
        
        // All the standard responses will be grouped by its key which is the Audit Task # and stored in the map
        map<string, list<Audit_Action_Standard_Response__c>> mapResponses = new map<string, list<Audit_Action_Standard_Response__c>>();
        
        for(Audit_Action_Standard_Response__c rec : [SELECT Id, Name,
                                                                Audit_Task_Num__c,
                                                                AMLCTF_Corrective_Action__c,
                                                                AMLCTF_Comments_or_Findings__c,
                                                                Standardised_Response__c
                                                            FROM Audit_Action_Standard_Response__c 
                                                            ORDER BY Audit_Task_Num__c ASC, Standardised_Response__c DESC, Name ASC
                                                           ]){

            list<Audit_Action_Standard_Response__c> values = new list<Audit_Action_Standard_Response__c>();
                                                               
            // If the map already has this key then get the list so you can add this record to it.
            if(mapResponses.get(rec.Audit_Task_Num__c) != null){
                values = mapResponses.get(rec.Audit_Task_Num__c);
            }

            // Add the current response to the list and put it back into the map
            values.add(rec);
            mapResponses.put(rec.Audit_Task_Num__c, values);
        }
        
        // Add each action to the wrapper list.
        for(AMLCTF_Audit_Action__c action : [SELECT Id, Name,
                                                 AMLCTF_Comments_or_Findings__c,
                                                 AMLCTF_Corrective_Action__c,
                                                 AMLCTF_Audit_Task_Num__c,
                                                 AMLCTF_Task_Name__c
                                             FROM AMLCTF_Audit_Action__c
                                             WHERE AMLCTF_Audit_Action_Statement__c = :statement.id 
                                             ORDER BY AMLCTF_Item_Number__c]){
            // Initialize the action wrapper with the action record and the corresponding standard responses.
            actions.add(
                new ActionWrapper(
                    action, 
                    mapResponses.get(action.AMLCTF_Audit_Task_Num__c)
                )
            );
        }
    }
    
    public void saveActions(){
        // Separate records to delete from the main list
        list<AMLCTF_Audit_Action__c> updActions = new list<AMLCTF_Audit_Action__c>();   // actions that were updated
        list<AMLCTF_Audit_Action__c> delActions = new list<AMLCTF_Audit_Action__c>();   // actions marked for deletion
        list<ActionWrapper> newActions          = new list<ActionWrapper>();                        // all actions minus deleted ones
        
        for(ActionWrapper action : actions){
            if(action.markedForDelete){
                delActions.add(action.record);
            }
            else{
                // Update only the actions that were edited
                if(action.isUpdated) 
                    updActions.add(action.record);
                // Since we are not retrieving from the database, use the existing collection of action records
                // but ignore the deleted records which is why we are adding to the 'newActions' list in the else part
                newActions.add(action);
            }
        }
        
        if(updActions.size() == 0 && delActions.size() == 0){
        } else {
            // DML Operations
            Savepoint sp = Database.setSavepoint(); // If either of the DML operations fail then it should rollback completely
            try{
    
                if(updActions.size()>0) update updActions;
                if(delActions.size()>0) {
                    delete delActions;
                    // Since records were deleted, use the new list of actions that does not include the deleted ones
                    actions = newActions;
                }
                // Reset the update flag
                for(ActionWrapper action : actions)
                    action.isUpdated = false;
            } catch (Exception ex){
                ApexPages.addMessages(ex);
                Database.rollback(sp);  // If delete fails then the update needs to be rolled back as well.
            }
        }
    }
}