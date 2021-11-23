public class CaseMassUploadCont 
{
    
    public Blob csvBlob {get; set;}
    
    public Case proxyCase {get; set;}   
    
    public CaseMassUploadCont()
    {
        proxyCase = new Case();
        proxyCase.Type = CaseMassUploadManager.DEFAULT_CASE_TYPE;
        proxyCase.OwnerId = CaseMassUploadManager.DefaultOwner != null ? CaseMassUploadManager.DefaultOwner.Id : null;
        proxyCase.Origin = CaseMassUploadManager.CASE_ORIGIN_MASS_UPLOAD;
        
        if (isPosrtalUser() || Test.isRunningTest()) // as there is no posrtaluser find, add this option to run the code in test class...
        {
            List<User> uList = [SELECT AccountId, ContactId FROM User WHERE Id = :UserInfo.getUserId()];
            if (uList.size() > 0)
            {
                proxyCase.AccountId = uList[0].AccountId;
                proxyCase.ContactId = uList[0].ContactId;
            }
        }
    }
    
    public void swap(String a, String b) {
        String temp = a;
        a=b;
        b=temp;
    }
    
    public PageReference upload() 
    {       
        try 
        {
            System.debug('---csvBlob:' + csvBlob.toString());   
            
            List<Case> cases = CaseMassUploadManager.createCases(proxyCase, csvBlob.toString());
            if (cases.size() > 0)
            {
                insert cases;
              
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
    
    private Boolean isPosrtalUser()
    {
        String ut = UserInfo.getUserType();
        return ut == 'Partner' ||
                ut == 'High Volume Portal' ||
                ut == 'Customer Portal User' ||
                ut == 'Customer Portal Manager';
    }
}