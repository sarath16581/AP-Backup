/**************************************************
Type:       Contact Extension Controller 
Purpose:    Used by ContactMarketingOptionsVF Page
History:
--------------------------------------------------
29.07.2015:  snigdha.sahu@auspost.com.au    Created

**************************************************/
public with sharing class ContactMarketingOptionsExt 
{
    public Contact currentContact {get; set;}
        
    public ContactMarketingOptionsExt(ApexPages.StandardController stdcontroller)
    {
        //fetch current contact detail from the page
        currentContact = (Contact)stdController.getRecord();  
        
    }
    public void SaveMarketingOptions()
    {          
          try
          {
                           
            update currentContact;
            
          }
          catch (DmlException ex)
          {
            for (Integer i = 0; i < ex.getNumDml(); i++) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getDmlMessage(i))); 
            }
          }

      
    }
    
}