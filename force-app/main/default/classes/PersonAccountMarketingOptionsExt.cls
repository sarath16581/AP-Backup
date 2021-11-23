/**************************************************
Type:       Account Extension Controller 
Purpose:    Used by PersonAccountMarketingOptionsVF Page
History:
--------------------------------------------------
07.08.2015:  snigdha.sahu@auspost.com.au    Created

**************************************************/
public with sharing class PersonAccountMarketingOptionsExt  
{
    
    public Account currentPAccount {get; set;}
        
    public PersonAccountMarketingOptionsExt (ApexPages.StandardController stdcontroller)
    {
        //fetch current contact detail from the page
        currentPAccount = (Account)stdController.getRecord();
        system.debug('Account to be edited is' +   currentPAccount );
        
    }
    public void SaveMarketingOptions()
    {          
          try
          {
                           
            update currentPAccount;
            
          }
          catch (DmlException ex)
          {
            for (Integer i = 0; i < ex.getNumDml(); i++) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(i)));
            system.debug('DML Error: Account to be edited is' +   currentPAccount ); 
            }
          }

      
    }
    
    
}