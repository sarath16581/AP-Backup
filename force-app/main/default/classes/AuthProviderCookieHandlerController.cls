/**
 * @description This class is called from AuthProviderCookieHandler vf page. This page is used to do some pre/post processing
 * and manipulation of the querystring parameters if required before sent to Auth0. The current use case of 
 * this is to read a cookie to determine whether or not the prompt=login attribute should be applied to the Auth0
 * redirect or not. There are a small number of scenarios where a transparent relogin should occur 
 * (Merchant Portal persona switching for example). If empty, a direct redirect will occur.
 *
 * @author Nathan Franklin
 * @date 2023-08-25
 * @changelog
*/
public with sharing class AuthProviderCookieHandlerController {

	//CONSTANTS
	@TestVisible
	private static final String COOKIE_NAME = 'auth_prompt_bypass';
	@TestVisible
	private static final String COOKIE_VALUE = '1';
	private static final String PARAM_ACTION = 'action';
	private static final String PARAM_PRE = 'pre';
	private static final String PARAM_POST = 'post';
	private static final String PARAM_COMMUNITY = 'community';
	private static final String PARAM_AUTH_PROVIDER = 'auth_provider';
	private static final String PARAM_NEXT = 'next';
	private static final Set<String> PRE_WHITELISTED_DOMAINS = new Set<String>{
		'.auspost.com.au',
		'.site.com'
	};
	private static final Set<String> POST_WHITELISTED_DOMAINS = new Set<String>{
		'.auspost.com.au'
	};

	public String error { get; set; }

	/**
	 * @description processCookieAndRedirect This function read the action from the url parameters and accordingly sets/resets the cookie.
	 * It manipualtes the queryparams if required and then redirects the Auth0 
	 * @return   return PageReference
	 */
    public PageReference processCookieAndRedirect() {
		PageReference output = null;
		Map<String, String> parameters = ApexPages.currentPage().getParameters();

		if(parameters == null) {
			parameters = new Map<String, String>();
		}

		String action = parameters.get(PARAM_ACTION); // pre or post

		if(PARAM_PRE.equalsIgnoreCase(action)) {
			//set the cookie and redirect to Auth0
			output = setCookieAndRedirect(parameters);
		} else if(PARAM_POST.equalsIgnoreCase(action)) {
			//remove the prompt parameter if cookie exists, delete the cookie and then redirect to Auth0
			output = resetCookieAndRedirect(parameters);
		} else {
			error = 'Failed to parse request - invalid action';
		}

		return output;
	}

	/**
	 * @description This function checks whether the domain in the preWhitelisted domains and sets the cookie. We then
	 * redirect to Auth0 for authentication
	 * @param  parameters Apex Page params
	 * @param  output Pagereference
	 * @return  return PageReference
	 */
	private Pagereference setCookieAndRedirect(Map<String, String> parameters) {
		Pagereference output = null;
		// we need to set the cookie and then forward the user onto to their site & login provider
		String community = parameters.get(PARAM_COMMUNITY);
		String authProvider = parameters.get(PARAM_AUTH_PROVIDER);

		if(!String.isEmpty(community) && !String.isEmpty(authProvider)) {
			try {
				Url communityUrl = new Url(community);
				String domain = communityUrl.getAuthority();
				Boolean found = false;
				//check the domain from community url ends with the pre whitelisted domains 
				for(String whitelistedDomain : PRE_WHITELISTED_DOMAINS) {
					if(domain.endsWith(whitelistedDomain)) {
						found = true;
						break;
					}
				}

				//set the cookie
				if(found) {
					System.Cookie cookie = new System.Cookie(COOKIE_NAME, COOKIE_VALUE, '/', 1, true, 'Lax');

					output = new PageReference(community + '/services/auth/sso/' + EncodingUtil.urlEncode(authProvider, 'UTF-8'));
					output.setCookies(new List<System.Cookie>{cookie});
					output.setRedirect(true);
					output.setRedirectCode(302); //have to explicitly set the code to 302 otherwise as per salesforce setRedirect sets as 200 
				} else {
					error = 'Failed to parse request - invalid pre parameters';
				}
			} catch (Exception ex) {
				// not a valid URL
				System.debug(ex);
				error = 'Failed to parse request';
			}
		}
		return output;
	}

	/**
	 * @description This function checks whether the domain in the postWhitelisted domains and sets the cookie. We then
	 * redirect to Auth0 for authentication
	 * @param  parameters Apex Page params
	 * @param  output Pagereference
	 * @return  return PageReference
	 */
	private Pagereference resetCookieAndRedirect(Map<String, String> parameters) {
		Pagereference output = null;
		try {
			// we need to read the cookie to determine whether or not to add/strip the prompt=login from the authoriseurl
			// then forward the user onto to their site & login provider
			String nextUrlParam = parameters.get(PARAM_NEXT);
			Url nextUrl = new Url(nextUrlParam);
			String domain = nextUrl.getAuthority();
			Boolean found = false;
			for(String whitelistedDomain : POST_WHITELISTED_DOMAINS) {
				if(domain.endsWith(whitelistedDomain)) {
					found = true;
					break;
				}
			}

			if(found) {
				// since the next url is whitelisted we can proceed with a redirect
				output = new System.PageReference(nextUrlParam);
				output.setRedirect(true);
				output.setRedirectCode(302); //have to explicitly set the code to 302 otherwise as per salesforce setRedirect sets as 200 
				
				System.Cookie cookie = ApexPages.currentPage().getCookies().get(COOKIE_NAME);
				if(cookie != null && COOKIE_VALUE.equalsIgnoreCase(cookie.getValue())) {
					// remove the prompt parameter if it exists
					// this is the hero of this page!
					output.getParameters().remove('prompt');

					// delete the cookie
					System.Cookie deletedCookie = new System.Cookie(COOKIE_NAME, COOKIE_VALUE, '/', 0, true, 'Lax');
					output.setCookies(new List<System.Cookie>{deletedCookie});
				}
				
			} else {
				error = 'Failed to parse request - invalid post parameters';
			}
		} catch (Exception ex) {
			// not a valid URL
			System.debug(ex);
			error = 'Failed to parse request';
		}
		return output;
	}
}