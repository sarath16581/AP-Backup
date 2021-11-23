/************************************
 * History
 * May-2015:  scherukuwada@salesforce.com	Added Sharing
 * **********************************/
public with sharing class CaseLatestFaxExt 
{
    public Id myCaseId {get; set;}
    public Id latestFax {get; set;}
    public Id myFaxId {get; set;}
   

    public CaseLatestFaxExt(ApexPages.StandardController stdController) 
    {
        myCaseId = (Id)stdController.getId();
        List<Fax__c> tempList = [SELECT id from Fax__c where Case__c = :myCaseId ORDER BY CreatedDate Desc LIMIT 1];
        if (tempList.size() > 0)
        {
            myFaxId = tempList[0].id;
        }
        else
        {
        
        }
    }
    
    public PageReference reLoad()
    {
        try
        {
            Set<String> fileNamesAllowed = AllowedFaxAttachmentFiles__c.getAll().keyset();
            system.debug(fileNamesAllowed);
            String criteria = '';
            for(String s: fileNamesAllowed) {
                if(String.isBlank(criteria)) {
                    criteria = '(Name like \'%'+s+'\'';
                } else {
                    criteria = criteria + 'or Name like \'%'+s+'\'';
                }               
            }
            Attachment att;
            if(String.isBlank(criteria)) {
                att = [Select Id from Attachment where ParentId = :myFaxId order by LastModifiedDate limit 1];
            } else {
                att = Database.Query('Select Id from Attachment where ParentId = :myFaxId and '+criteria+') order by LastModifiedDate limit 1');
            }
            latestFax = att.Id;
        } catch(Exception e) 
        {
            ApexPages.Message noAttachments = new ApexPages.Message(ApexPages.Severity.INFO,'There are no Faxes found for this Case, or no attachments against the Fax record.');
            ApexPages.addMessage(noAttachments);
            return null;
        }
        PageReference pageRef = new PageReference('/servlet/servlet.FileDownload?file='+latestFax);
        return pageRef;
    }

}