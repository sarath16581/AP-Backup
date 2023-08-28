/**
 * @description Test class for covering AuthProviderCookieHandlerController
 * @author Mahesh Parvathaneni
 * @date 2023-08-25
 * @changelog
*/

@IsTest
private class AuthProviderCookieHndlrController_Test {

	/**
	 * Test:
	 * Making sure that cookie is set when action is pre and community domain is in preWhiteListedDomains 
	 * and redirect to Auth0
	 */
	@IsTest
	private static void testPreActionProcessCookieAndRedirect() {
		// =====================================
		// Data Preparation
		// =====================================
		String communityUrl = 'https://auspost--devnathan.sandbox.my.site.com/merchantportal/AuthProviderCookieHandler';
		Pagereference pageRef = new PageReference(communityUrl);
		pageRef.getParameters().put('action','pre');
		pageRef.getParameters().put('auth_provider','Auth0MPProvider');
		pageRef.getParameters().put('community','https://auspost--devnathan.sandbox.my.site.com/bsp');

		// =====================================
		// Stubbing
		// =====================================
		Test.setCurrentPage(pageRef);

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		AuthProviderCookieHandlerController controller = new AuthProviderCookieHandlerController();
		Pagereference output = controller.processCookieAndRedirect();
		Test.stopTest();

		// =====================================
		// Verification
		// =====================================
		System.Cookie cookie = output.getCookies().get(AuthProviderCookieHandlerController.COOKIE_NAME);
		String url = output.getUrl();
		System.assertEquals(1, cookie.getMaxAge(), 'Expected cookie to be set');
		System.assertEquals(AuthProviderCookieHandlerController.COOKIE_VALUE, cookie.getValue(), 'Incorrect cookie value returned');
		System.assertEquals(true, url.contains('Auth0MPProvider'), 'Expected redirection to Auth Provider url');
		System.assertEquals(null, controller.error, 'Expected no error to be returned');
	}

	/**
	 * Test:
	 * Making sure that cookie is read when action is post and prompt login is removed from the authorise url if cookie exists
	 * and redirect to Auth0
	 */
	@IsTest
	private static void testPostActionProcessCookieAndRedirect() {
		// =====================================
		// Data Preparation
		// =====================================
		String nextUrl = 'https://auspost--devnathan.sandbox.my.site.com/merchantportal/AuthProviderCookieHandler';
		Pagereference pageRef = new PageReference(nextUrl);
		pageRef.getParameters().put('action','post');
		pageRef.getParameters().put('next','https://welcome.ptest.auspost.com.au/authorize&response_type=code&code_challenge_method=S256&prompt=login');
		System.Cookie cookie = new System.Cookie(AuthProviderCookieHandlerController.COOKIE_NAME, AuthProviderCookieHandlerController.COOKIE_VALUE, '/', 1, true, 'Lax');
		pageRef.setCookies(new List<System.Cookie>{cookie});

		// =====================================
		// Stubbing
		// =====================================
		Test.setCurrentPage(pageRef);

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		AuthProviderCookieHandlerController controller = new AuthProviderCookieHandlerController();
		Pagereference output = controller.processCookieAndRedirect();
		Test.stopTest();

		// =====================================
		// Verification
		// =====================================
		System.Cookie cookieDeleted = output.getCookies().get(AuthProviderCookieHandlerController.COOKIE_NAME);
		Map<String, String> params = output.getParameters();
		System.assertEquals(0, cookieDeleted.getMaxAge(), 'Expected cookie to be deleted');
		System.assertEquals(true, !params.containsKey('prompt'), 'Expected prompt param to be removed from the Auth Url');
		System.assertEquals(null, controller.error, 'Expected no error to be returned');
	}

	/**
	 * Test:
	 * Making sure that cookie is not set when action is pre and community domain is invalid
	 * No Pagereference redirection is set
	 */
	@IsTest
	private static void testPreActionError() {
		// =====================================
		// Data Preparation
		// =====================================
		String communityUrl = 'https://auspost--devnathan.sandbox.my.site.com/merchantportal/AuthProviderCookieHandler';
		Pagereference pageRef = new PageReference(communityUrl);
		pageRef.getParameters().put('action','pre');
		pageRef.getParameters().put('auth_provider','Auth0MPProvider');
		pageRef.getParameters().put('community','invalidurl');

		// =====================================
		// Stubbing
		// =====================================
		Test.setCurrentPage(pageRef);

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		AuthProviderCookieHandlerController controller = new AuthProviderCookieHandlerController();
		Pagereference output = controller.processCookieAndRedirect();
		Test.stopTest();

		// =====================================
		// Verification
		// =====================================
		System.assertNotEquals(null, controller.error, 'Expected error to be returned');
		System.assertEquals(null, output, 'Expected no page reference to be set');
	}

	/**
	 * Test:
	 * Making sure that no Pagereference redirection is set when nextUrl param is invalid
	 */
	@IsTest
	private static void testPostActionError() {
		// =====================================
		// Data Preparation
		// =====================================
		String nextUrl = 'https://auspost--devnathan.sandbox.my.site.com/merchantportal/AuthProviderCookieHandler';
		Pagereference pageRef = new PageReference(nextUrl);
		pageRef.getParameters().put('action','post');
		pageRef.getParameters().put('next','invalidurl');

		// =====================================
		// Stubbing
		// =====================================
		Test.setCurrentPage(pageRef);

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		AuthProviderCookieHandlerController controller = new AuthProviderCookieHandlerController();
		Pagereference output = controller.processCookieAndRedirect();
		Test.stopTest();

		// =====================================
		// Verification
		// =====================================
		System.assertNotEquals(null, controller.error, 'Expected error to be returned');
		System.assertEquals(null, output, 'Expected no page reference to be set');
	}
}