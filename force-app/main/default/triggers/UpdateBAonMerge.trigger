/*------------------------------------------------------------  
Description:   
   update 

History
<Date>      <Authors Name>     <Brief Description of Change>
24-06-2014  Eric Shen              Delete revenue by organisation record when an account is deleted such as customer merge
------------------------------------------------------------*/

trigger UpdateBAonMerge on Account (before delete) {
    if(Trigger.isdelete)
    {    
        List<Account> updateAccount =  [SELECT Id, (Select Id from Billing_Accounts__r ) FROM Account WHERE Id in :Trigger.old];
        
        List<Billing_Account__c> ba = new List<Billing_Account__c>();
        
        for(Account a: updateAccount)
        {
            for(Billing_Account__c b : a.Billing_Accounts__r)
            {
                b.Date_Parent_Changed__c = Datetime.now();
                ba.add(b);
            }
        }
        update ba;
        
    //to check revenue by organisation object and delete if any records.    
        
     List<Account> deleteAccount =  [SELECT Id, (Select Id from Revenue_by_Organisation__r ) FROM Account WHERE Id in :Trigger.old];
        
        List <Revenue_by_organisation__c> rbo = new List <Revenue_by_organisation__c>();
        
         for(Account a: deleteAccount )
        {
            for(Revenue_by_organisation__c ro : a.Revenue_by_Organisation__r)
            {
              
                rbo.add(ro);
            }
        }
        
       if (rbo.size()<>0)
       { 
        delete rbo;
        }
    }
    
    
    
    
}