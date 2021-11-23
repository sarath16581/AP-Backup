/**
 * @description
 * Manages the functions for safe drop eligibility for a tracking article
 *
 * @author Nathan Franklin
 * @date 2020-09-27
 * @group Tracking
 * @changelog
 */
public inherited sharing class SafeDropEligibilityService {

	/**
	 * Creates a new instance of the service. This allows use to use dependency injection for mocking
	 */
	public static SafeDropEligibilityService getInstance() {
		return (SafeDropEligibilityService) Application.Utilities.getInstance(SafeDropEligibilityService.class);
	}

	/**
	 * Retrieve the current Safe Drop Status and Information for a particular tracking article
	 * This is a single article either standalone or a part of a consignment
	 */
	public EligibilityResponse getSafeDropStatus(String articleId) {
		EligibilityResponse output = new EligibilityResponse();

		AusPostSettings__c setting = AusPostSettings__c.getValues('SAPEMCustomerArticles');

		String endPoint = setting.URL2__c;
		endPoint += '(\'' + EncodingUtil.urlEncode(articleId, 'UTF-8') + '\')/?$expand=SafeDropInfo,SafeDropStatus&$format=json';
		HttpRequest request = getHttpRequest(endPoint, setting, 'GET');

		Http http = new Http();
		HttpResponse response = http.send(request);
		String body = response.getBody();
		System.debug(body);

		if(response.getStatusCode() == 200) {
			Map<String, Object> resBody = (Map<String, Object>)JSON.deserializeUntyped(body);
			Map<String, Object> safeDropStatus = (Map<String, Object>)getProperty(resBody, 'd.SafeDropStatus', new Map<String, Object>());
			Map<String, Object> safeDropInfo = (Map<String, Object>)getProperty(resBody, 'd.SafeDropInfo', new Map<String, Object>());

			// EXAMPLES
			//"SafeDropInfo" : {
			//      "ArticleID" : "42N2046603011425",
			//      "Location" : "On the front porch",
			//      "LocationCode" : "P",
			//      "Action" : "ADD",
			//      "IneligibilityReason" : ""
			//    },
			// "SafeDropStatus" : {
			//      "ArticleID" : "42N2046603011425",
			//      "StatusType" : "SafeDropStatus",
			//      "StatusDesc" : "Customer ATL Request Status",
			//      "StatusValue" : "Eligible",
			//      "UpdatedDate" : "\/Date(1466177130000)\/"
			//    }

			Status status = new Status();
			status.articleId = articleId;
			status.statusValue = ifNull(safeDropStatus.get('StatusValue'), '');

			// TODO Refactor into something more dynamic
			if('Eligible'.equalsIgnoreCase(status.statusValue) || 'Cancelled'.equalsIgnoreCase(status.statusValue)) {
				status.showStatus = true;
				status.isSafeDropSettable = true;
				status.eligibilityLabel = Label.SafeDropEligibleCancelledLabel;
			} else if('Requested'.equalsIgnoreCase(status.statusValue)) {
				status.showStatus = true;
				status.isSafeDropUnsettable = true;
				status.eligibilityLabel = Label.SafeDropRequestedLabel;
			} else if('Failed'.equalsIgnoreCase(status.statusValue) || 'Expired'.equalsIgnoreCase(status.statusValue)) {
				status.showStatus = false;
				status.eligibilityLabel = 'Unsafe or unable to Safe Drop';
			} else if('Success'.equalsIgnoreCase(status.statusValue)) {
				status.showStatus = false;
				status.eligibilityLabel = 'Article was safe dropped';
			} else if('Ineligible'.equalsIgnoreCase(status.statusValue)) {
				status.showStatus = true;
				status.eligibilityLabel = 'Ineligible';

				String ineligibilityReason = String.valueOf(safeDropInfo.get('IneligibilityReason'));
				if(!String.isEmpty(ifNull(ineligibilityReason, ''))) {
					// grab the label to display when safe drop is not allowed for the article
					List<Ineligibility_Reason__mdt> reasonsList = [SELECT Id, Reason__c, MasterLabel, HideStatus__c FROM Ineligibility_Reason__mdt WHERE MasterLabel = :ineligibilityReason];
					if(reasonsList.size() > 0) {
						status.showStatus = !reasonsList[0].HideStatus__c;
						status.eligibilityLabel = reasonsList[0].Reason__c;
					}
				}
			} else {
				status.showStatus = false;
				status.eligibilityLabel = status.statusValue;
			}

			output.success = true;
			output.status = status;
		} else {
			output.success = false;
			try {
				Map<String, Object> resBody = (Map<String, Object>) JSON.deserializeUntyped(body);
				output.error = String.valueOf(getProperty(resBody, 'error.message.value', 'An unknown error occurred'));
			} catch(Exception ex) {
				output.error = response.getStatusCode() + ': ' + response.getStatus();
			}
		}
		return output;
	}

	/**
	 * Set the safe drop preference. This should always be a consignment when available
	 */
	public String submitSafeDrop(String articleId, String action) {
		AusPostSettings__c setting = AusPostSettings__c.getValues('SAPEMCustomerArticles');
		try {
			List<String> token = getCSRFToken();
			if (token.size() == 2) {
				String senderName = 'Salesforce';
				String requesterName = (String)UserInfo.getUserId();
				String location = 'at a safe place on premises';

				String endPointAddPost = setting.URL3__c.removeEnd('/') + '/SubmitSafeDrop?TrackingID=\'' + EncodingUtil.urlEncode(articleId, 'UTF-8') + '\'&SenderID=\'SF\'&SenderName=\'' + EncodingUtil.urlEncode(senderName, 'UTF-8') + '\'&Requester=\'' + EncodingUtil.urlEncode(requesterName, 'UTF-8') + '\'&Location=\'' + EncodingUtil.urlEncode(location, 'UTF-8') + '\'&Terms=\'ACCEPT\'&Action=\'' + EncodingUtil.urlEncode(action, 'UTF-8') + '\'&$format=json';

				HttpRequest request = getHttpRequest(endPointAddPost, setting, 'POST');
				request.setHeader('x-csrf-token', token[1]);
				request.setHeader('Cookie', token[0]);
				request.setHeader('Accept', 'application/json');
				request.setHeader('Content-Type', 'application/json');

				Http http = new Http();
				HttpResponse response = http.send(request);
				String body = response.getBody();
				System.debug(body);

				if (response.getStatusCode() == 200) {
					return 'Submitted successfully.';
				} else {
					try {
						Map<String, Object> resBody = (Map<String, Object>) JSON.deserializeUntyped(body);
						return String.valueOf(getProperty(resBody, 'error.message.value', 'An unknown error occurred'));
					} catch(Exception ex) {
						return response.getStatusCode() + ': ' + response.getStatus();
					}
				}
			} else {
				return 'Something went wrong. Please contact System Admin.';
			}
		} catch (Exception exp) {
			return 'Something went wrong. Please contact System Admin. ' + exp.getMessage();
		}
	}

	/**
	 * Grab the CSRF token to enable POST to Safe Drop API
	 */
	private static List<String> getCSRFToken() {
		AusPostSettings__c setting = AusPostSettings__c.getValues('SAPEMCustomerArticles');
		List<String> output = new List<String>(); // [0] Cookie & [1] Token

		HttpRequest reqToken = getHttpRequest(setting.URL3__c, setting, 'HEAD');
		reqToken.setHeader('x-csrf-token', 'fetch');

		Http http = new Http();
		HttpResponse response = http.send(reqToken);

		if (response.getStatusCode() == 200) {
			String cookiesAll = response.getHeader('Set-Cookie');
			String token = response.getHeader('x-csrf-token');
			List<String> cookies = cookiesAll.split(';');
			for (String s : cookies) {
				//Find Session Id
				if (s.subStringBefore('=').startsWithIgnoreCase('SAP_SESSIONID')) {
					output.add(s);
					break;
				}
			}
			if (token != '') {
				output.add(token);
			}
		}
		return output;
	}

	private static Object getProperty(Map<String, Object> obj, String propertyPath, Object nullValue) {
		Map<String, Object> currentObj = obj;
		List<String> stringParts = propertyPath.split('\\.');
		for(Integer i=0;i<stringParts.size();i++) {
			System.debug('currentObj: ' + currentObj);
			if(currentObj == null) {
				return nullValue;
			}

			String part = stringParts[i];
			if(i == (stringParts.size() - 1)) {
				return (currentObj.get(part) == null ? nullValue : currentObj.get(part));
			} else {
				currentObj = (Map<String, Object>)currentObj.get(part);
			}
		}

		return nullValue;
	}

	private static String ifNull(Object obj, String valueIfNull) {
		return (obj == null ? valueIfNull : String.valueOf(obj));
	}

	// Create HTTP Request based on Parameters passed
	private static HttpRequest getHttpRequest(String endPoint, AusPostSettings__c setting, String method) {
		HttpRequest req = new HttpRequest();
		req.setMethod(method);
		req.setEndpoint(endPoint.replaceAll(' ', '+'));
		Blob headerValue1 = Blob.valueOf(setting.Username__c + ':' + setting.Password__c);
		String authorizationHeader1 = 'Basic ' + EncodingUtil.base64Encode(headerValue1);
		req.setHeader('Authorization', authorizationHeader1);
		return req;
	}

	public class Status {
		@AuraEnabled public String statusValue;
		//		@AuraEnabled public String updatedDate;
		//		@AuraEnabled public String location;
		//		@AuraEnabled public String locationCode;
		//		@AuraEnabled public String action;
		//		@AuraEnabled public String ineligibilityReason;
		//		@AuraEnabled public String ineligibilityReasonLabel;

		@AuraEnabled public String articleId;
		@AuraEnabled public String eligibilityLabel;
		@AuraEnabled public Boolean isSafeDropSettable = false;
		@AuraEnabled public Boolean isSafeDropUnsettable = false;
		@AuraEnabled public Boolean showStatus;
	}

	public class EligibilityResponse {
		@AuraEnabled public Boolean success;
		@AuraEnabled public String error;
		@AuraEnabled public Status status;
	}

}