public class CaseMassUploadDeciphaCont 
{
    
    public Blob csvBlob {get; set;}
    
    public Case proxyCase {get; set;}   
    
    public CaseMassUploadDeciphaCont()
    {
        proxyCase = new Case();
        proxyCase.Type = CaseMassUploadManager.DEFAULT_CASE_TYPE;
        proxyCase.OwnerId = CaseMassUploadManager.DefaultOwner != null ? CaseMassUploadManager.DefaultOwner.Id : null;      
        proxyCase.Origin = CaseMassUploadManager.CASE_ORIGIN_DECIPHA;
    }
    
    public PageReference upload() 
    {       
        try 
        {
            System.debug('---csvBlob:' + csvBlob.toString());   
            
            List<Case> cases = CaseMassUploadManager.createCases(proxyCase, csvBlob.toString());
            if (cases.size() > 0)
            {
                List<CaseComment> caseComments = new List<CaseComment>();
                for(Case c:cases) 
                {
                    if((c.CaseOriginator__c!= NULL && c.CaseOriginator__c.toLowerCase() == 'addressee') || 
                       (c.Other_Party__c != NULL && c.Other_Party__c.toLowerCase() == 'sender')) 
                    {
                        String temp = '';
                        
                        temp = c.Address1__c;
                        c.Address1__c = c.Address2__c;
                        c.Address2__c = temp;
                        
                        temp = c.Address1line2__c;
                        c.Address1line2__c = c.Address2line2__c;
                        c.Address2line2__c = temp;
                        
                        temp = c.Address1Country__c;
                        c.Address1Country__c = c.Address2Country__c;
                        c.Address2Country__c = temp;
                        
                        temp = c.Address1DPID__c;
                        c.Address1DPID__c = c.Address2DPID__c;
                        c.Address2DPID__c = temp;
                        
                        temp = c.Address1Postcode__c;
                        c.Address1Postcode__c = c.Address2Postcode__c;
                        c.Address2Postcode__c = temp;
                        
                        temp = c.Address1State__c;
                        c.Address1State__c = c.Address2State__c;
                        c.Address2State__c = temp;
                        
                        temp = c.Address1Suburb__c;
                        c.Address1Suburb__c = c.Address2Suburb__c;
                        c.Address2Suburb__c = temp;
                        
                        temp = c.PrimaryContactFirstName__c;
                        c.PrimaryContactFirstName__c = c.SecondaryContactFirstName__c;
                        c.SecondaryContactFirstName__c = temp;
                        
                        temp = c.PrimaryContactLastName__c;
                        c.PrimaryContactLastName__c = c.SecondaryContactLastName__c;
                        c.SecondaryContactLastName__c = temp;
                    }
                    
                    c.Primary_Name__c =  (c.PrimaryContactFirstName__c!=null?c.PrimaryContactFirstName__c+' ':'') + (c.PrimaryContactLastName__c!=null?c.PrimaryContactLastName__c:'');
                    c.Secondary_Contact__c = (c.SecondaryContactFirstName__c!=null?c.SecondaryContactFirstName__c+' ':'') + (c.SecondaryContactLastName__c!=null?c.SecondaryContactLastName__c:'');
                    
                    CaseComment com = new CaseComment(Ispublished=false, CommentBody = c.Description);
                    c.Description = '';
                    caseComments.add(com);
                }
                system.debug('--Cases**'+cases);
                insert cases;
                for(Integer i=0;i<caseComments.size();i++) 
                {
                    caseComments[i].ParentId=cases[i].Id;                        
                }
                for(Integer i=0;i<caseComments.size();i++) 
                {
                    if(caseComments[i].CommentBody == null || caseComments[i].CommentBody == '') 
                    {
                        CaseComment removed = caseComments.remove(i);
                    }
                }
                insert caseComments;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, cases.size() + ' Cases Created'));
            }  
        }
        catch (Exception e)
        {
            ApexPages.addMessages(e);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, CaseMassUploadManager.TOO_MANY_ROWS_MESSAGE));
        }
        return null;
    }
    
    public PageReference downloadTemplate()
    {
        return new PageReference('/resource/CSVUploadTemplates/DeciphaUploadTemplate.csv');
    }
}