/**
* @author
* @date
* @group Articles
* @tags Cases, SSSW, Articles, Safe Drop, SAP-EM, Tibco
* @domain Articles
* @description
* @changelog
* 12.05.2017  nathan.franklin@auspost.com.au  Added support to show safe drop image if it is available in the event messages
* 2017-10-02  nathan.franklin@auspost.com.au  Add clear values to left and right columns
* 6.4.2018   disha.kariya@auspost.com.au Added Set Safe Drop for NCCC agents
* 06.07.2018	dilshan.egodawela@auspost.com.au Updated to return an empty status when the ineligibility code returned from SAP EM is not in Ineligibility_Reason__mdt table
* 28.02.2019   disha.kariya@auspost.com.au   Updated to pass requester name to SAP EM
* 2020-03-16   nathan.franklin@auspost.com.au   Exposed getSAPEMValues, saveToSAPEM, unsetSafeDrop to Aura and added some security best practices to getSAPEMValues
* 13.06.2024	Parveen Kaushik Added a filter in SOQL for mapping model. See CSLU-470 (JIRA) for details.
*/
global class TIBCOArticleComponentCont {
	public string productCategory { get; set; }
	public string productSubcategory { get; set; }
	public string caseType { get; set; }
	public List<FieldValueDisplay> leftDetailsList { get; set; }
	public List<FieldValueDisplay> rightDetailsList { get; set; }
	public string lodgementDateString { get; set; }
	public Contact receiver { get; set; }
	public Contact sender { get; set; }

	// Support to show safe drop image if it is available in the event messages
	public String safeDropGUID { get; set; }

	/*public static Map<String, String> articleFieldList
	{
		get
		{
			if (articleFieldList == null)
			{
				articleFieldList = new Map<String, String>();
				for (Schema.FieldSetMember fm : SObjectType.Article__c.FieldSets.SAP_EM_Panel_Article_View.getFields())
				{
					articleFieldList.put(fm.getFieldPath(), fm.getLabel());
				}
			}
			return articleFieldList;
		}
	}*/

	TIBCOArticleWrapper boundArticle;

	public TIBCOArticleWrapper getBoundArticle() {
		System.debug('In GET call boundArticle--->' + boundArticle);
		return boundArticle;
	}

	public void setBoundArticle(TIBCOArticleWrapper value) {

		// clear the values and the columns incase we are resetting the component with new data.
		leftDetailsList.clear();
		rightDetailsList.clear();

		system.debug('############## setting bound artile #############');
		boundArticle = value;

		setFieldValueDisplays();
		ID receiverContactID = Util.contactIDForNameAndEmail(boundArticle.proxyArticle.ReceiverName__c, boundArticle.proxyArticle.ReceiverEmail__c);
		if (receiverContactID != null) {
			system.debug('############## receiverContactID: ' + receiverContactID);
			receiver = [select Name from Contact where id = :receiverContactID limit 1];
		}

		ID senderContactID = Util.contactIDForNameAndEmail(boundArticle.proxyArticle.SenderName__c, boundArticle.proxyArticle.SenderEmail__c);
		if (senderContactID != null) {
			system.debug('############## senderContactID: ' + senderContactID);
			sender = [select Name from Contact where id = :senderContactID limit 1];
		}

		// 2017-05-12 NATHAN FRANKLIN add Safe Drop field to show Safe Drop image
		// this will pull from event messages to grab the GUID that can be passed into component to show the safe drop image
		System.Debug('############## Event Messages:');
		System.Debug(boundArticle.eventMessages);
		if (boundArticle.eventMessages != null) {
			for (TIBCOEventMessageWrapper message : boundArticle.eventMessages) {
				if (!String.isEmpty(message.proxyEM.Safe_Drop_GUID__c)) {
					safeDropGUID = message.proxyEM.Safe_Drop_GUID__c;
					break;
				}
			}
		}
	}

	void setFieldValueDisplays() {
		if (boundArticle != null && leftDetailsList.size() == 0 && rightDetailsList.size() == 0) {
			List<FieldValueDisplay> l = new List<FieldValueDisplay>();
			lodgementDateString = '';

			if (boundArticle.proxyArticle.ArticleLodgementDate__c != null) {
				Datetime lodgementDate = Datetime.newInstance(boundArticle.proxyArticle.ArticleLodgementDate__c, Time.newInstance(1, 0, 0, 0));
				lodgementDateString = lodgementDate.format('yyyy-MM-dd');// lodgementDate.format('yyyy-MM-dd HH:mm:ss');
			}

			for (Schema.FieldSetMember fm : SObjectType.Article__c.FieldSets.SAP_EM_Panel_Article_View.getFields()) {
				Object o = boundArticle.proxyArticle.get(fm.getFieldPath());
				if (canDisplayField(fm.getFieldPath(), o)) {
					if (o instanceof Date) {
						l.add(new FieldValueDisplay(fm.getFieldPath(), fm.getLabel(), ((Date) o).format()));
					} else if (o instanceof DateTime) {
						l.add(new FieldValueDisplay(fm.getFieldPath(), fm.getLabel(), ((DateTime) o).format()));
					} else {
						l.add(new FieldValueDisplay(fm.getFieldPath(), fm.getLabel(), o));
					}
				}
			}

			/*for (String f : articleFieldList.keySet())
			{
				Object o = boundArticle.proxyArticle.get(f);
				if (o != null)
				{
					if (o instanceof Date)
					{
						l.add(new FieldValueDisplay(f, articleFieldList.get(f), ((Date)o).format()));
					}
					else if (o instanceof DateTime)
					{
						l.add(new FieldValueDisplay(f, articleFieldList.get(f), ((DateTime)o).format()));
					}
					else
					{
						l.add(new FieldValueDisplay(f, articleFieldList.get(f), o));
					}
				}
			}*/

			integer index = 0;
			for (FieldValueDisplay d : l) {
				if (Math.mod(index, 2) == 0) {
					leftDetailsList.add(d);
				} else {
					rightDetailsList.add(d);
				}


				index++;
			}

			string key = string.isEmpty(boundArticle.proxyArticle.ProductCategory__c) ? '' : boundArticle.proxyArticle.ProductCategory__c.trim();
			key += string.isEmpty(boundArticle.proxyArticle.SubProduct__c) ? '' : boundArticle.proxyArticle.SubProduct__c.trim();
			if (key != '') {
				List<MiniCaseFieldMapping__c> mappings = [select ProductCategory__c, ProductSubcategory__c, Type__c from MiniCaseFieldMapping__c where SAPKey__c = :key AND MappingModel__c =: SSSWConstants.ENQUIRYMAPPING_CLASSIC_MODEL];
				if (mappings.size() > 0) {
					productCategory = mappings[0].ProductCategory__c;
					productSubcategory = mappings[0].ProductSubcategory__c;
					caseType = mappings[0].Type__c;
				}
			}
		}
		System.debug('In setFieldValueDisplays call leftDetailsList--->' + leftDetailsList);
	}

	private Boolean canDisplayField(String fieldName, Object value) {
		if (fieldName == 'SignatureRequiredFlag__c') {
			return value == true;
		} else {
			return value != null;
		}
	}
	//Method to get SAP EM Safe Drop options Disha
	@RemoteAction
	@AuraEnabled
	global static String getSAPEMValues(String articleId, String trackingId) {
		String actualTrackingId = (!String.isEmpty(trackingId)) ? trackingId : articleId;
		String endPointGet;
		String status;
		AusPostSettings__c setting = AusPostSettings__c.getValues('SAPEMCustomerArticles');
		if (setting != null) {
			endPointGet = setting.URL2__c;
		}
		endpointGet = endpointGet + '(\'' + EncodingUtil.urlEncode(actualTrackingId, 'UTF-8') + '\')/SafeDropStatus?$format=json';
		HttpRequest reqGet = TIBCOArticleComponentCont.generateRequest(setting, endPointGet, 'GET');
		Http httpGet = new Http();
		HTTPResponse resGet = httpGet.send(reqGet);
		System.debug('resGet.getbody()--->' + resGet.getbody());
		System.debug('resGet.getStstusCode()--->' + resGet.getstatusCode());
		if (resGet.getstatusCode() == 200) {
			Map<String, Object> resBody = (Map<String, Object>) JSON.deserializeUntyped(resGet.getbody());
			system.debug('resBody--->' + resBody);
			Map<String, Object> statusValues = (Map<String, Object>) resBody.get('d');
			system.debug('dim--->' + statusValues);
			status = (String) statusValues.get('StatusValue');
			if (status.equalsIgnoreCase('Ineligible') || status.equalsIgnoreCase('Expired')) {
				String endPointGetIneligible;
				if (setting != null) {
					endPointGetIneligible = setting.URL2__c;
				}
				endPointGetIneligible = endPointGetIneligible + '(\'' + EncodingUtil.urlEncode(actualTrackingId, 'UTF-8') + '\')/SafeDropInfo?$format=json';
				HttpRequest reqGetIneligible = TIBCOArticleComponentCont.generateRequest(setting, endPointGetIneligible, 'GET');
				Http httpGetIneligible = new Http();
				HTTPResponse resGetIneligible = httpGetIneligible.send(reqGetIneligible);
				if (resGetIneligible.getstatusCode() == 200) {
					Map<String, Object> resBodyIneligible = (Map<String, Object>) JSON.deserializeUntyped(resGetIneligible.getbody());
					system.debug('resGetIneligible--->' + resGetIneligible);
					Map<String, Object> dimIneligible = (Map<String, Object>) resBodyIneligible.get('d');
					system.debug('dimIneligible--->' + dimIneligible);
					String reason = (String) dimIneligible.get('IneligibilityReason');
					if (reason != '') {
						//modified by dilshan.egodawela@auspost.com to return an empty status when the ineligibility code returned
						//from SAP EM is not in Ineligibility_Reason__mdt table
						List<Ineligibility_Reason__mdt> reasonsList = new List<Ineligibility_Reason__mdt>();
						reasonsList = [SELECT id,Reason__c,MasterLabel FROM Ineligibility_Reason__mdt where MasterLabel = :reason];
						System.debug('reasonsList : ' + reasonsList);
						if (!reasonsList.isEmpty()) {
							status = status + ': ' + reasonsList[0].Reason__c;
						} else {
							status = '';
						}
					} else {
						status = status + ': Could not find reason for Ineligibility.';
					}
				}
			}
			return status;
		} else {
			status = 'Error: Something went wrong. Please contact System Admin.';
			return status;
		}
		return null;
	}

	//Method to get SAP EM CSRF Token for POST Disha
	public static List<String> getCSRFToken() {
		AusPostSettings__c setting = AusPostSettings__c.getValues('SAPEMCustomerArticles');
		List<String> retValues = new List<String>(); // [0] Cookie & [1] Token
		String endPoint;
		if (setting != null) {
			endPoint = setting.URL3__c;
		}
		HttpRequest reqToken = TIBCOArticleComponentCont.generateRequest(setting, endPoint, 'HEAD');
		reqToken.setHeader('x-csrf-token', 'fetch');
		String token;
		Http http = new Http();
		HTTPResponse resToken = http.send(reqToken);
		//Check for SUCCESS Status
		if (resToken.getStatusCode() == 200) {
			String cookiesAll = resToken.getHeader('Set-Cookie');
			List<String> cookies = cookiesAll.split(';');
			for (String s : cookies) {
				//Find Session Id
				if (s.subStringBefore('=').startsWithIgnoreCase('SAP_SESSIONID')) {
					retValues.add(s);
					System.debug('retValues--->' + retValues);
				}
			}
			system.debug('retValues--->' + retValues);
			System.debug('cookies--->' + cookies);
			System.debug('resToken.getHeader(x-csrf-token)--->' + resToken.getHeader('x-csrf-token'));
			token = resToken.getHeader('x-csrf-token');
			if (token != '') {
				retValues.add(token);
			}
			return retValues;
		}
		return null;
	}

	// Method to save Set Safe Drop to SAP EM Disha
	@RemoteAction
	@AuraEnabled
	global static String saveToSAPEM(String articleId, String trackingId) {
		System.debug('<--Inside saveToSAPEM-->');
		String retMessage;
		AusPostSettings__c setting = AusPostSettings__c.getValues('SAPEMCustomerArticles');
		System.debug('articleId--->' + articleId);
		System.debug('trackingId--->' + trackingId);
		String actualTrackingId = (!String.isEmpty(trackingId)) ? trackingId : articleId;
		System.debug('actualTrackingId--->' + actualTrackingId);
		try {
			List<String> token = TIBCOArticleComponentCont.getCSRFToken();
			if (token.size() > 0) {
				String endPointAddPost;
				if (setting != null) {
					endPointAddPost = setting.URL3__c;
				}
				String senderName = 'Salesforce';
				System.debug('senderName--->' + senderName);
				String requesterName = (String) UserInfo.getUserId();
				String location = 'at a safe place on premises';
				endPointAddPost = endPointAddPost + 'SubmitSafeDrop?TrackingID=\'' + actualTrackingId + '\'&SenderID=\'SF\'&SenderName=\'' + SENDERNAME + '\'&Requester=\'' + requesterName + '\'&Location=\'' + location + '\'&Terms=\'ACCEPT\'&Action=\'ADD\'&$format=json';
				HttpRequest reqAddPost = TIBCOArticleComponentCont.generateRequest(setting, endPointAddPost, 'POST');
				reqAddPost.setHeader('x-csrf-token', token[1]);
				reqAddPost.setHeader('Cookie', token[0]);
				reqAddPost.setHeader('Accept', 'application/json');
				reqAddPost.setHeader('Content-Type', 'application/json');
				Http http1 = new Http();
				System.debug('reqAddPost--->' + reqAddPost);
				HttpResponse resAddPost = http1.send(reqAddPost);
				System.debug('resAddPost.getStatusCode()--->' + resAddPost.getStatusCode());
				System.debug('resAddPost.getbody()--->' + resAddPost.getbody());
				if (resAddPost.getStatusCode() != 200) {
					retMessage = 'Something went wrong. Please contact System Admin.';
				} else {
					retMessage = 'Safe Drop request submitted successfully.';
				}
			} else {
				retMessage = 'Something went wrong. Please contact System Admin.';
			}
			return retMessage;
		} catch (Exception exp) {
			retMessage = 'Something went wrong. Please contact System Admin.';
			return retMessage;
		}
	}

	// Method to Unset Safe Drop to SAP EM Disha
	@RemoteAction
	@AuraEnabled
	global static String unsetSafeDrop(String articleId, String trackingId) {
		AusPostSettings__c setting = AusPostSettings__c.getValues('SAPEMCustomerArticles');
		String retMessage;
		System.debug('articleId--->' + articleId);
		System.debug('trackingId--->' + trackingId);
		String actualTrackingId = (!String.isEmpty(trackingId)) ? trackingId : articleId;
		System.debug('actualTrackingId--->' + actualTrackingId);
		try {
			List<String> token = TIBCOArticleComponentCont.getCSRFToken();
			if (token.size() > 0) {
				String endPointDeletePost;
				if (setting != null) {
					endPointDeletePost = setting.URL3__c;
				}
				String SENDERNAME = 'Salesforce';
				String requesterName = (String) UserInfo.getUserId();
				System.debug('senderName--->' + senderName);
				String location = 'at a safe place on premises';
				endPointDeletePost = endPointDeletePost + 'SubmitSafeDrop?TrackingID=\'' + actualTrackingId + '\'&SenderID=\'SF\'&SenderName=\'' + SENDERNAME + '\'&Requester=\'' + requesterName + '\'&Location=\'' + location + '\'&Terms=\'ACCEPT\'&Action=\'DELETE\'&$format=json';
				HttpRequest reqDeletePost = TIBCOArticleComponentCont.generateRequest(setting, endPointDeletePost, 'POST');
				reqDeletePost.setHeader('x-csrf-token', token[1]);
				reqDeletePost.setHeader('Cookie', token[0]);
				reqDeletePost.setHeader('Accept', 'application/json');
				reqDeletePost.setHeader('Content-Type', 'application/json');
				System.debug('reqDeletePost--->' + reqDeletePost);
				Http http1 = new Http();
				HttpResponse resDeletePost = http1.send(reqDeletePost);
				System.debug('resDeletePost.getStatusCode()--->' + resDeletePost.getStatusCode());
				System.debug('resDeletePost.getbody()--->' + resDeletePost.getbody());
				if (resDeletePost.getStatusCode() != 200) {
					retMessage = 'Something went wrong. Please contact System Admin.';
				} else {
					retMessage = 'Remove Safe Drop request submitted successfully.';
				}
			} else {
				retMessage = 'Something went wrong. Please contact System Admin.';
			}
			return retMessage;
		} catch (Exception exp) {
			retMessage = 'Something went wrong. Please contact System Admin.';
			return retMessage;
		}
	}

	// Create HTTP Request based on Parameters passed
	Public Static HttpRequest generateRequest(AusPostSettings__c setting, String endpoint, String method) {
		if (setting != null && endpoint.length() > 0 && method.length() > 0) {
			HttpRequest req = new HttpRequest();
			req.setMethod(method);
			req.setEndpoint(endPoint.replaceAll(' ', '+'));
			Blob headerValue1 = Blob.valueOf(setting.Username__c + ':' + setting.Password__c);
			String authorizationHeader1 = 'Basic ' + EncodingUtil.base64Encode(headerValue1);
			req.setHeader('Authorization', authorizationHeader1);
			return req;
		}
		return null;
	}

	public TIBCOArticleComponentCont(ApexPages.StandardController stdController) {
	}

	public TIBCOArticleComponentCont() {
		leftDetailsList = new List<FieldValueDisplay>();
		rightDetailsList = new List<FieldValueDisplay>();
		System.debug('In Constructor TIBCOArticleComponentsCont');
	}
}