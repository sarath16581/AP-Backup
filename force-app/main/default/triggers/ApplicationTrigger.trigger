trigger ApplicationTrigger on Application__c (after update) 
{
    // AUTHOR:     2014-06-27 Louis Wang (Bluewolf)
    // DESC:       This trigger checks for mandatory fields for Tibco process
    //             It will update Opportunity. to indicate whether mandatory fields are populated.
    //             Opportunity to Application should always be 1 to 1.
    //             Application should not be deleted as it would break all the flow-on Tibco processes.
    
    List<string> oppPassed = new List<string>();
    List<string> oppFailed = new List<string>();
    List<Opportunity> oppToUpdate = new List<Opportunity>();
    
    // get the Map of Application and associated Opportunity
    Map<string, string> appOppMap = new Map<string, string>();
    for(Application__c a : [SELECT Id, Opportunity__c
                                FROM Application__c
                                WHERE Id =: Trigger.New])
    {
        appOppMap.put(a.Id, a.Opportunity__c);
    }                                
    

    if(Trigger.IsUpdate)
    {
        // shouldn't need to check for Insert, as Application can only be created through VF APMSApplication
        for(Application__c a : Trigger.New)
        {
            verifyApp(a);
        }
    }

    for(Opportunity o : [SELECT Id 
                            FROM Opportunity
                            WHERE Id = : oppPassed])
    {
        o.IsSettlementFieldsFilled__c = true;
        oppToUpdate.add(o);
    }
    
    for(Opportunity o : [SELECT Id 
                            FROM Opportunity
                            WHERE Id = : oppFailed])
    {
        o.IsSettlementFieldsFilled__c = false; 
        oppToUpdate.add(o);        
    }    
    update oppToUpdate;

    private void verifyApp(Application__c a)
    {
        // if all 4 fields are populated with a value, then add to corresponding list
        if((a.MCC__c!=null && a.MCC__c!='')
            && (a.SettlementProfile__c!=null && a.SettlementProfile__c!='')
            && (a.RiskCategory__c!=null && a.RiskCategory__c!='')
            && (a.EBTName__c!=null && a.EBTName__c!=''))
        {
            if(appOppMap.containsKey(a.Id))
            {
                oppPassed.add(appOppMap.get(a.Id));
            }
        }
        else
        {
            if(appOppMap.containsKey(a.Id))
            {
                oppFailed.add(appOppMap.get(a.Id));
            }
        }
    }

    

}