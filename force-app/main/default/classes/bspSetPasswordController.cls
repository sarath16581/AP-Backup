/*
History:
	2023-08-28	Naveen Rajanna	REQ3286437 - Changed api version and removed hard coded URL to use apex methods to generate URL
*/
global class bspSetPasswordController {

	
	public PageReference save() {
		if(u!=null && password1 == password2) {
			try{
			system.setPassword(u.Id,password1);
			passwordSet = true;
			} catch(Exception ex) {
				ApexPages.addMessages(ex);
				hasException = true;
				//return null;
			}
			//Andrew Judd 24.10.18 AP1 Refresh - replaced hardcoded url reference
			string url = URL.getSalesforceBaseUrl().toExternalForm() + '/bsp/bsplogin';
			newPage = new PageReference(url);
			//return newPage;
		}
		
		return null;
	}


	public String password1 {get; set;}
	public string password2 {get; set;}
	public string email {get; set;}
	public Boolean passwordSet {get; set;}
	public Boolean hasException {get; set;}
	public User u {get; set;}
	public PageReference newPage {get; set;}
	
	public bspSetPasswordController() {
		Id userId = ApexPages.currentPage().getParameters().get('myId');
		string emailId = ApexPages.currentPage().getParameters().get('myEmail');
		//Community users are recognized as contacts - hence the OR check for contactId
		u = [select id,email from User where (id =:userId or contactId =:userId) and email =:emailId limit 1];
		email = u.email;
		hasException = false;
		passwordSet = false;
	}
	
	public PageReference securePage()
	{
		// this function redirects to https protocol
		string sfdcBaseURL = URL.getSalesforceBaseUrl().toExternalForm();
		integer firstSemiColonPos = sfdcBaseURL.indexOf(':');
		string protocolString = sfdcBaseURL.substring(0,firstSemiColonPos);
		string sitePathPrefix = Site.getPathPrefix();

		if(protocolString!='https')
		{       
			string secureURL = 'https' + sfdcBaseURL.substring(firstSemiColonPos) + sitePathPrefix;
			PageReference securePage = new PageReference(secureURL);
			securePage.setRedirect(true);
			return securePage;  
		}
		else
		{   
			return null;
		}          
	} 
}