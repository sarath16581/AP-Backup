/*
* created by: George Nguyen
* description: This controller is being used by the OmniBugRedirect VF page. 
* It is required to return the current org's domain name for validation of the target page as part of the redirect.
*/
public inherited sharing class OmniBugRedirectController {
    
    public String orgDomainUrl { get { return URL.getOrgDomainUrl().toExternalForm(); } }
}
