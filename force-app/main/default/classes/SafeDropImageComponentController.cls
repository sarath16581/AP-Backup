public with sharing class SafeDropImageComponentController {

	public static String requestLabel = '';

	/**
	 * Use the API to pull back the filtered out image.
	 * The API blacks out faces and text.
	 */
	@RemoteAction
	public static Object getArticleImage(String guidId) {

		HttpRequest req = SafeDropUtility.getSafeDropHttpRequest(guidId);
		if(req == null)
			return new SafeDropUtility.SafeDropApiResponse(true, 'No Login Information Found.', '');

		try {
			// Create a Continuation for the HTTPRequest
			// This is used for async requests
			Continuation con = new Continuation(60);
			requestLabel = con.addHttpRequest(req);
			con.state = requestLabel;
			con.continuationMethod = 'callback';

			// Return it to the system for processing
			return con;
		} catch (Exception e) {
			// there was an error either receiving a response from the server or processing it on our end.
			String error = 'EXCEPTION\nType: ' + e.getTypeName() + '\nMessage: ' + e.getMessage() + '\nLine Number: ' + String.valueOf(e.getLineNumber()) + '\n\nStack:\n' + e.getStackTraceString();

			SafeDropUtility.SafeDropApiResponse response = new SafeDropUtility.SafeDropApiResponse(true, error, '');
			System.debug(error);

			return response;
		}
	}

	/**
	 * This is the callback for the async callout.
	 * This is returned to the javascript client that invoked the @RemoteAction getArticleImage
	 */
	public static Object callback(Object state) {
		HttpResponse resp = Continuation.getResponse((String)state);

		String responseBody = resp.getBody();
		System.debug('SAFE-DROP API RAW REPONSE: ' + responseBody);

		// parse the json
		SafeDropUtility.SafeDropApiResponse response = SafeDropUtility.parseResponse(responseBody, resp);

		System.debug('SAFE-DROP API PARSED REPONSE: ' + response);

		return response;
	}


}