/* Created by BlueWolf as part of SSSW Project

2015-05-28 - CMcIntyre - Updated "with sharing" as part of security audit.

*/

public with sharing class LatestFaxExt 
{

    public Id latestFax {get; set;}
    public Id myFaxId {get; set;}

    public LatestFaxExt(ApexPages.StandardController stdController) 
    {
        myFaxId = (Id)stdController.getId(); 
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
            ApexPages.Message noAttachments = new ApexPages.Message(ApexPages.Severity.INFO,'There are no attachments against the Fax record');
            ApexPages.addMessage(noAttachments);
            return null;
        }
        PageReference pageRef = new PageReference('/servlet/servlet.FileDownload?file='+latestFax);
        return pageRef;
    }

}