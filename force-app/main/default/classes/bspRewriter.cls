global without sharing class bspRewriter implements Site.UrlRewriter 
{
    // This class rewrites the portal URL
    //      Instead of      /bsp/bspEnquiryDetail?Id=xxx,
    //      It becomes      /bsp/EnquiryDetail/00091789
    // Note: It is executed by Site running user, not the logon user.
    //  It is set to without Sharing, and let bspEnquiryDetail controller to handle the sharing

    //Variables to represent the user-friendly URLs for case page. Set to public for test class.
    public string CASEDETAIL_PAGE = '/EnquiryDetail/';

    //Variables to represent my custom Visualforce pages that display Case information. Set to public for test class.
    public string CASEDETAIL_VISUALFORCE_PAGE = '/bspEnquiryDetail?id=';


    global PageReference mapRequestUrl(PageReference myFriendlyUrl)
    {
        String url = myFriendlyUrl.getUrl();
        system.debug('xxx url = ' + url);

        if(url.startsWith(CASEDETAIL_PAGE))
        {
            //Extract the CaseNumber from the URL
            //For example: /EnquiryDetail/00110212 returns 00110212
            String caseNo = url.substring(CASEDETAIL_PAGE.length(), url.length());
            system.debug('xxx caseNo = ' + caseNo);            

            string newPageName = '';
            //Select the ID of the Case that matches the CaseNo from the URL
            List<Case> cases = [SELECT Id 
                        FROM Case 
                        WHERE CaseNumber =: caseNo LIMIT 1];
            if(cases.size()==1)
            {
                //Construct a new page reference in the form of my Visualforce page
                newPageName = CASEDETAIL_VISUALFORCE_PAGE + cases[0].id;
            }
            else
            {
                // put an incorrect name and rely on the Site URL Redirect to refresh the URL in address bar
                newPageName = '/bsp/bspEnquiry'; 
            }
            PageReference newPage = new PageReference(newPageName);
            system.debug('xxx newPage = ' + newPage);
            newPage.setRedirect(true);
            return newPage; 
        }

        //If the URL isn't in the form of a Case page, continue with the request
        return null;
    }
    
    global List<PageReference> generateUrlFor(List<PageReference> mySalesforceUrls)
    {
        system.debug('xxx mySalesforceUrls ' + mySalesforceUrls);
        //A list of pages to return after all the links have been evaluated
        List<PageReference> myFriendlyUrls = new List<PageReference>();
        
        //a list of all the ids in the urls
        List<id> caseIds = new List<id>();
        
        // loop through all the urls once, finding all the valid ids
        for(PageReference mySalesforceUrl : mySalesforceUrls)
        {
            //Get the URL of the page
            String url = mySalesforceUrl.getUrl();
 
            //If this looks like case page, transform it
            if(url.startsWith(CASEDETAIL_VISUALFORCE_PAGE))
            {
                //Extract the Id from the query parameter and store in a list for querying later in bulk.
                String Id = url.substring(CASEDETAIL_VISUALFORCE_PAGE.length(), url.length());
                caseIds.add(id);
            }
        }

        // Get all the case number in bulk
        List <Case> cases = [SELECT Id, CaseNumber 
                                FROM Case 
                                WHERE Id IN : caseIds];
    
        map<string,string> caseIdNoMap = new map<string,string>();
        for(Case c : cases)
        {
            caseIdNoMap.put(c.Id, c.CaseNumber);
        }
    
        // it is important to go through all the urls again, so that the order of the urls in the list is maintained. 
        for(PageReference mySalesforceUrl : mySalesforceUrls) 
        {
           //Get the URL of the page
           String url = mySalesforceUrl.getUrl();
    
           if(url.startsWith(CASEDETAIL_VISUALFORCE_PAGE))
           {
                //Extract the Id from the query parameter and store in a list for querying later in bulk.
                String Id = url.substring(CASEDETAIL_VISUALFORCE_PAGE.length(), url.length());
                if(caseIdNoMap.containsKey(Id))
                {
                    myFriendlyUrls.add(new PageReference(CASEDETAIL_PAGE + caseIdNoMap.get(Id)));
                }                   
           }
           else 
           {
                 //If this doesn't start like a case page, don't do any transformations
                 myFriendlyUrls.add(mySalesforceUrl);
           }
        }
       
        //Return the full list of pages
        return myFriendlyUrls;
    }
}