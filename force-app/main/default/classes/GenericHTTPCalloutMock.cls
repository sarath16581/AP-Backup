/**
 * @author alexvolkov
 * @date 26/5/21
 * @group Tests
 * @description Generic mock class to switch between mock HTTP responses based on endpoint
 */

/**
--------------------------------------- History --------------------------------------------------
26.05.2021	alex.volkov@auspost.com.au	Initial creation
**/

@IsTest
public with sharing class GenericHTTPCalloutMock implements HttpCalloutMock
{
	protected Integer code;
	protected String status;
	protected Boolean success;
	protected String body;
	protected Map<String, String> responseHeaders;

	public GenericHttpCalloutMock(Integer code, String status, Boolean success, String body) {
		this.code = code;
		this.status = status;
		this.success = success;
		this.body = body;
	}

	public HttpResponse respond(HttpRequest req) {
		HttpResponse res = new HttpResponse();
		if (req.getEndpoint().startsWithIgnoreCase('callout:AuthZ'))
		{
			if (this.success)
			{
				res.setBody('{"access_token" : "test_token", "token_type":"Bearer", "expires_in":"900"}');
				res.setStatusCode(200);
				res.setStatus('OK');
			}
			else
			{
				res.setBody('');
				res.setStatusCode(500);
				res.setStatus('Error');
			}

		}
		else if (req.getEndpoint().startsWithIgnoreCase('callout:NotificationPreferences') && req.getMethod() == 'GET')
		{
			if (this.success)
			{
				res.setBody('[\n' +
						'  {\n' +
						'	"email":"test@test.com",\n' +
						'	"optedOut": true\n' +
						'  },\n' +
						'  {\n' +
						'	"mobile":"0433222111",\n' +
						'	"optedOut": false\n' +
						'  }\n' +
						']');
				res.setStatusCode(200);
				res.setStatus('OK');
			}
			else
			{
				res.setBody('');
				res.setStatus('Unauthorized');
				res.setStatusCode(401);
			}
		}
		else if (req.getEndpoint().startsWithIgnoreCase('callout:NotificationPreferences') && req.getMethod() == 'POST')
		{
			if (this.success)
			{
 				res.setBody('[\n' +
						'  {\n' +
						'	"email":"test@test.com",\n' +
						'	"optedOut": true\n' +
						'  },\n' +
						'  {\n' +
						'	"mobile":"0433222111",\n' +
						'	"optedOut": false\n' +
						'  }\n' +
						']');
				res.setStatusCode(200);
				res.setStatus('OK');
			}
			else
			{
				res.setBody('');
				res.setStatus('Unauthorized');
				res.setStatusCode(401);
			}
		}
		else if (req.getEndpoint().startsWithIgnoreCase('callout:NotificationPreferences') && req.getMethod() == 'PUT')
		{
			if (this.success)
			{
				res.setBody('[\n' +
						'  {\n' +
						'	"email":"test@test.com",\n' +
						'	"optedOut": true\n' +
						'  },\n' +
						'  {\n' +
						'	"mobile":"0433222111",\n' +
						'	"optedOut": false\n' +
						'  }\n' +
						']');
				res.setStatusCode(204);
				res.setStatus('OK');
			}
			else
			{
				res.setBody('');
				res.setStatus('Unauthorized');
				res.setStatusCode(401);
			}
		}
		else
		{
			res.setBody(this.body);
			res.setStatusCode(this.code);
			res.setStatus(this.status);
		}
		return res;
	}
}