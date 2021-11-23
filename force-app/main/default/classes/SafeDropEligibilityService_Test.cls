/***
 * @author Disha Kariya
 * @date 2020-10-01
 * @group Tests
 * @description Test Scenarios for Safe Drop Eligibility Service
 * @changelog
 */
@IsTest
public with sharing class SafeDropEligibilityService_Test {

	@TestSetup
	private static void setup() {
		AusPostSettings__c oa = new AusPostSettings__c();
		oa.Password__c = 'w@X2mb?SbMi%';
		oa.Username__c = 'sssw_sts';
		oa.URL3__c = 'https://digitalapi-ptest.npe.auspost.com.au/auth/token';
		oa.URL2__c = 'https://digitalapi-ptest.npe.auspost.com.au/qac/pobLease/';
		oa.Name = 'SAPEMCustomerArticles';
		insert oa;
	}

	@IsTest
	public static void testGetSafeDropEligibilityStatusResponses() {
		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		Test.setMock(HttpCalloutMock.class, new MyPostHttpMock());

		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		SafeDropEligibilityService service = SafeDropEligibilityService.getInstance();
		SafeDropEligibilityService.EligibilityResponse resultEligible = service.getSafeDropStatus('HJJKJ5465ELIGIBLE');
		SafeDropEligibilityService.EligibilityResponse resultRequested = service.getSafeDropStatus('HJJKJ5465REQUESTED');
		SafeDropEligibilityService.EligibilityResponse resultSuccess = service.getSafeDropStatus('HJJKJ5465SUCCESS');
		SafeDropEligibilityService.EligibilityResponse resultFailed = service.getSafeDropStatus('HJJKJ5465FAILED');
		SafeDropEligibilityService.EligibilityResponse resultIneligible = service.getSafeDropStatus('HJJKJ5465INELIGIBLE');
		SafeDropEligibilityService.EligibilityResponse resultUnsuccess = service.getSafeDropStatus('HJJKJ5465UNSUCCESS');

		//Verifications
		System.assertEquals(true, resultEligible.status.showStatus, 'Show status should be true');
		System.assertEquals(true, resultEligible.status.isSafeDropSettable, 'Safe drop settable is true for eligible articles.');
		System.assertEquals('Eligible', resultEligible.status.statusValue, 'Safe drop status is Eligible');
		System.assertEquals(true, resultRequested.status.showStatus, 'Show status should be true');
		System.assertEquals(true, resultRequested.status.isSafeDropUnsettable, 'Safe drop unsettable is true for eligible articles.');
		System.assertEquals('Requested', resultRequested.status.statusValue, 'Safe drop status is Eligible');
		System.assertEquals(false, resultSuccess.status.showStatus, 'Show status should be false');
		System.assertNotEquals('', resultSuccess.status.eligibilityLabel, 'Eligibility Label is blank');
		System.assertEquals(false, resultFailed.status.showStatus, 'Show status should be false');
		System.assertNotEquals('', resultFailed.status.eligibilityLabel, 'Eligibility Label is blank');
		System.assertEquals(true, resultIneligible.status.showStatus, 'Show status should be true');
		System.assertNotEquals('', resultIneligible.status.eligibilityLabel, 'Eligibility Label is blank');
		System.assertNotEquals('', resultUnsuccess.error, 'Error for unsuccessful is blank');
		Test.stopTest();
	}

	@IsTest
	public static void testSetSafeDropSuccessResponse() {
		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		Test.setMock(HttpCalloutMock.class, new MyPostHttpMock());

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		SafeDropEligibilityService service = SafeDropEligibilityService.getInstance();
		String result = service.submitSafeDrop('HJJKJ5465SET', 'ADDSUCCESS');

		Test.stopTest();
		System.assertEquals('Submitted successfully.', result, 'Safe drop not submitted successfully.');
	}
	
	@IsTest
	public static void testSetSafeDropUnsuccessResponse() {
		// =====================================
		// Data Preparation
		// =====================================
		// None!
		
		// =====================================
		// Stubbing
		// =====================================
		Test.setMock(HttpCalloutMock.class, new MyPostHttpMock());
		
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		
		SafeDropEligibilityService service = SafeDropEligibilityService.getInstance();
		String result = service.submitSafeDrop('HJJKJ5465NOTSET', 'ADDUNSUCCESS');
		
		Test.stopTest();
		System.assertNotEquals('Submitted successfully.', result, 'Safe drop should not be submitted successfully.');
	}

	public class MyPostHttpMock implements HttpCalloutMock {
		public HttpResponse respond(HTTPRequest req) {
			HttpResponse res = new HttpResponse();
			System.debug('req.getEndpoint()--->'+req.getEndpoint());
			if (req.getEndpoint().containsIgnoreCase('HJJKJ5465ELIGIBLE')) {
				res.setStatusCode(200);
				res.setBody('{\n' +
							'	"d":{\n' +
							'		"SafeDropStatus" :{\n' +
							'			"StatusValue": "Eligible"\n' +
							'		},\n' +
							'		"SafeDropInfo" :{\n' +
							'			"IneligibilityReason": ""\n' +
							'		}\n' +
							'   }\n' +
							'}');
				return res;
			}
			if (req.getEndpoint().containsIgnoreCase('HJJKJ5465REQUESTED')) {
				res.setStatusCode(200);
				res.setBody('{\n' +
						'	"d":{\n' +
						'		"SafeDropStatus" :{\n' +
						'			"StatusValue": "Requested"\n' +
						'		},\n' +
						'		"SafeDropInfo" :{\n' +
						'			"IneligibilityReason": ""\n' +
						'		}\n' +
						'   }\n' +
						'}');
				return res;
			}
			if (req.getEndpoint().containsIgnoreCase('HJJKJ5465SUCCESS')) {
				res.setStatusCode(200);
				res.setBody('{\n' +
						'	"d":{\n' +
						'		"SafeDropStatus" :{\n' +
						'			"StatusValue": "Success"\n' +
						'		},\n' +
						'		"SafeDropInfo" :{\n' +
						'			"IneligibilityReason": ""\n' +
						'		}\n' +
						'   }\n' +
						'}');
				return res;
			}
			if (req.getEndpoint().containsIgnoreCase('HJJKJ5465FAILED')) {
				res.setStatusCode(200);
				res.setBody('{\n' +
						'	"d":{\n' +
						'		"SafeDropStatus" :{\n' +
						'			"StatusValue": "Failed"\n' +
						'		},\n' +
						'		"SafeDropInfo" :{\n' +
						'			"IneligibilityReason": ""\n' +
						'		}\n' +
						'   }\n' +
						'}');
				return res;
			}
			if (req.getEndpoint().containsIgnoreCase('HJJKJ5465INELIGIBLE')) {
				res.setStatusCode(200);
				res.setBody('{\n' +
						'	"d":{\n' +
						'		"SafeDropStatus" :{\n' +
						'			"StatusValue": "Ineligible"\n' +
						'		},\n' +
						'		"SafeDropInfo" :{\n' +
						'			"IneligibilityReason": "3"\n' +
						'		}\n' +
						'   }\n' +
						'}');
				return res;
			}
			if (req.getEndpoint().containsIgnoreCase('HJJKJ5465UNSUCCESS')) {
				res.setStatusCode(400);
				res.setBody('{\n' +
						'	"error":{\n' +
						'		"message" :{\n' +
						'			"value": "Article does not exist"\n' +
						'		},\n' +
						'		"SafeDropInfo" :{\n' +
						'			"IneligibilityReason": "3"\n' +
						'		}\n' +
						'   }\n' +
						'}');
				return res;
			}
			if(req.getMethod().containsIgnoreCase('Head')){
				res.setHeader('Content-Type', 'application/json');
				res.setHeader('x-csrf-token', 'token');
				res.setStatusCode(200);
				res.setHeader('Set-Cookie', 'SAP_SESSIONID_TC0_031=testing');
				res.setBody('{"foo":"bar"}');
				return res;
			}
			if(req.getEndpoint().containsIgnoreCase('ADDSUCCESS') ||
					req.getEndpoint().containsIgnoreCase('HJJKJ5465SET') ||
					req.getEndpoint().containsIgnoreCase('HJJKJ5465UNSET')){
				res.setHeader('Content-Type', 'application/json');
				res.setStatusCode(200);
				res.setHeader('Set-Cookie', 'SAP_SESSIONID_TC0_031=testing');
				res.setBody('{"d": {"ArticleID": "HMM000154201000605008","StatusValue": "Eligible"}}');
				return res;
			}
			if(req.getEndpoint().containsIgnoreCase('ADDUNSUCCESS')){
				res.setHeader('Content-Type', 'application/json');
				res.setStatusCode(500);
				res.setHeader('Set-Cookie', 'SAP_SESSIONID_TC0_031=testing');
				res.setBody('{\n' +
						'	"error":{\n' +
						'		"message" :{\n' +
						'			"value": "Article does not exist"\n' +
						'		},\n' +
						'		"SafeDropInfo" :{\n' +
						'			"IneligibilityReason": "3"\n' +
						'		}\n' +
						'   }\n' +
						'}');
				return res;
			}
			return null;
		}
	}

}