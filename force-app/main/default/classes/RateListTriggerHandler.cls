/******************************************************************************************
    
    Author:         Lyndon Lavapie
    Date Created:   03/10/2016
    Description:    Handler for RateListTrigger
    
    Change Log:
    Date:          Author:                  Description:
    03/10/2016     Lyndon Lavapie           Created
    
*******************************************************************************************/
public class RateListTriggerHandler {
    private static final String ERROR_MSG = 'Record Cannot be deleted!';
    private static final Set<String> rlStatus = new Set<String>{'Superseded','Active'};
    
    /*********************************************************************************************************************************
      Author:     Lyndon Lavapie
      Description:  Adds an error when the user delete a Rate List Record with prohibited Status
                    
      Input:        List<Rate_List__c>
      Output:        Void
    *********************************************************************************************************************************/
    public static void preventDelete(List<Rate_List__c> oldRL){
        
        for(Rate_List__c rl:oldRL){
            if(rlStatus.contains(rl.Status__c)){
                rl.addError(ERROR_MSG);
            }
        }
    }
}