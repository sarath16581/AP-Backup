public class ssswRecentNetworkEmailMessage
{
    /**************************************************
    Type:         Controller for visualforce component ssswRecentNetworkEmailMessage
    History:
    NOTE:         N/A
    --------------------------------------------------
    2014-09-24    Louis Wang (Bluewolf)        Created.
    **************************************************/

    public Id caseId 
    {    
        get;
        set
        {
            // component will only load the AssignTo into class variable after the constructor is executed
            // so need to execute the code here
            caseId = value;   
            if(caseId != null)
            {
            	List<Fax__c> tempfax = new List<Fax__c>([select Id from Fax__c where case__c = :caseId]); 
            	if (!tempfax.isEmpty()) {       
        			SSSWFaxUtility.generateAttachment(tempfax);
            	}
            	
                fetchRecentEmail();     
                Case tempCase = [select Id, network__r.Contact_Facility__c, EnquirySubType__c, EscalationEmail__c from Case where id = :caseID][0];
                contactType = tempCase.network__r.Contact_Facility__c;
                newEmail = tempCase.EscalationEmail__c;
            }      
        }
    }
    
    private Case tempCase {get;set;}
    public String newEmail {get;set;}
    public String contactType {get;set;}
        
    public EmailMessage em {get;set;}

    public ssswRecentNetworkEmailMessage() {}
        
    private void fetchRecentEmail()
    {
        system.debug('xxx caseId = ' + caseId);    
        // fetch From Address from Custom Setting
        QM__c configSetting = QM__c.getInstance();
        string fromAddress = configSetting.NetworkEmail__c;
        
        if(fromAddress != null)
        {
            // fetch the most recent email message sent by AusPost network (as per defined in custom setting)
            list<EmailMessage> emList = [SELECT Id, FromAddress, ToAddress, CreatedDate,
                                            TextBody, Subject, HtmlBody 
                                            FROM EmailMessage
                                            WHERE FromAddress = : fromAddress
                                            AND ParentId = : caseId
                                            ORDER BY CreatedDate DESC
                                            LIMIT 1];

            if(emList.size() > 0)
            {
                em = emList[0];
            }
        }
    }
    
}