/**************************************************
Type:      
Purpose:    
History:
--------------------------------------------------

10 Sept 2015 (christopher.henschke@auspost.com.au) - updated for new end point used by Marketing team
14/09/2016  Kalpita.talwadekar@auspost.com.au      - updated to add new method for sending bulk emails.
06/02/2017   eric.shen@auspost.com.au              - create checkEmailDomainMapping method to swap email domains and apply it to 'fromaddress' value
13/02/2017   eric.shen@auspost.com.au              - ET custom setting update to accommodate new customer keys.
18/04/2017  eric.shen@auspost.com.au               - merged Dion's code
25/10/2023 	naveen.rajanna@auspost.com.au			- REQ3342357 change hardcoded MC endpoint to refer to TSE endpoint in custom settings 
*/

public with sharing class ExactTargetEmail {
	public Boolean isTest = false;

	class ExactTargetFrom {
		public ExactTargetFrom(string address, string name){
			this.Address = address;
			this.name = name;   
		}       
		public string Address {get;set;}
		public string Name {get;set;}
	}
	
	class ExactTargetTo {
		public ExactTargetTo(string address, string SubscriberKey, ExactTargetContactAttributes ContactAttributes){
			this.Address = address;
			this.SubscriberKey = SubscriberKey;
			this.ContactAttributes = ContactAttributes;
		}
		public string Address {get;set;}
		public string SubscriberKey {get;set;}
		public ExactTargetContactAttributes ContactAttributes {get;set;}
	}
	
	class ExactTargetContactAttributes {
		public ExactTargetContactAttributes(ExactTargetSubscriberAttributes SubscriberAttributes){
			this.SubscriberAttributes = SubscriberAttributes;
		}
		public ExactTargetSubscriberAttributes SubscriberAttributes {get;set;}
	}
	
	class ExactTargetSubscriberAttributes{
		public ExactTargetSubscriberAttributes(string emailSubject, string name, string emailBody){
			this.emailSubject = emailSubject;
			this.name = name;
			this.emailBody = emailBody;
		}
		public string EmailSubject {get;set;}
		public string Name {get;set;}
		public string EmailBody {get;set;}
	}
	
	public class ExactTargetSentResult {
		public ExactTargetSentResult(){
			isSuccessful = false;
			requestBody = '';
			message = '';
			IsBatchEmail = false;
		}
		public boolean isSuccessful {get;set;}
		public string requestBody {get;set;}
		public string message {get;set;}
		public boolean IsBatchEmail {get;set;}
	}
	
	public ExactTargetSentResult sendBacklog(string jsonString, boolean isBatch){
	   ExactTargetSentResult result = new ExactTargetSentResult();
	   
	   if(validToken.length()>0){
		try {
			HttpRequest req = new HttpRequest();
			if(isBatch){
				req.setEndpoint(exactTargetLogIn.message_endpoint__c.replace('send?', 'sendBatch?')+validToken);
			} else {
				req.setEndpoint(exactTargetLogIn.message_endpoint__c+validToken);
			}
			req.setMethod('POST');
			req.setHeader('Content-Type', 'application/json');
			req.setBody(jsonString);
			HTTPResponse res = new Http().send(req);
			JSONParser parser =JSON.createParser(res.getBody());
			parser.nextToken();
			parser.nextValue();
			result.requestBody = jsonString;
			result.message = parser.getText();
			result.isSuccessful = true;
			 
			} catch(Exception ex) {
				result.message = 'Error: ' + ex.getMessage();
				System.debug(ex.getMessage());
			}
		} else {
			result.message = 'Error: Invalid token';
		}
		
		return result;
	}
	
	public ExactTargetSentResult sendSingleMail(string fromAddress, string fromName, string toAddress, string toName, string emailBody,string subject, string subscriberID){
	   ExactTargetSentResult result = new ExactTargetSentResult();

	   //6-Feb-2-17 Eric Shen change email domain
	   String newFromAddress =checkEmailDomainMapping(fromAddress);
	   
	   if(test.isRunningtest() || validToken.length()>0){
			try {
				HttpRequest req = new HttpRequest();
				
				// 10 Sept 2015 (christopher.henschke@auspost.com.au) - updated for new end point used by Marketing team
				if(subscriberID == 'noreply@auspost.com.au') {
					if (fromaddress == SSSWConstants.NETWORK_EMAIL){ //customerenquiry@auspost.com.au - SSSWSalesForceEmailCustomerEnquiry
						req.setEndpoint('https://' + mcTSEHostname + '/messaging/v1/messageDefinitionSends/key:' + exactTargetLogIn.NetworkSearchSendKey__c + '/send?access_token=' +validToken);
					}
					else if (fromaddress == SSSWConstants.ORGWIDEEMAIL){ //customerservice@auspost.com.au - SSSWSalesForceEmailAustraliaPost
						req.setEndpoint('https://' + mcTSEHostname + '/messaging/v1/messageDefinitionSends/key:' + exactTargetLogIn.ShareInfoSendKey__c + '/send?access_token=' +validToken);
					} else {
						req.setEndpoint(exactTargetLogIn.message_endpoint__c+validToken);
					}
				}
				 //13-Feb-17 Eric Shen repoint customer key for domain change
				else if (fromaddress == SSSWConstants.NETWORK_EMAIL){ //customerenquiry@auspost.com.au - SSSWSalesForceEmailCustomerEnquiry
				   req.setEndpoint('https://' + mcTSEHostname + '/messaging/v1/messageDefinitionSends/key:' + exactTargetLogIn.NetworkSearchSendKey__c + '/send?access_token=' +validToken);
				}
				else if (fromaddress == SSSWConstants.ORGWIDEEMAIL){ //customerservice@auspost.com.au - SSSWSalesForceEmailAustraliaPost
				   req.setEndpoint('https://' + mcTSEHostname + '/messaging/v1/messageDefinitionSends/key:' + exactTargetLogIn.ShareInfoSendKey__c + '/send?access_token=' +validToken);
				}
				else {
					req.setEndpoint(exactTargetLogInMarketing.message_endpoint__c+validToken);
				}

				req.setMethod('POST');
				req.setHeader('Content-Type', 'application/json');
				system.debug('email body:'+emailBody);
				emailBody = emailBody.replace('"','\'');
				system.debug('email body:'+emailBody);
				JSONGenerator generator = JSON.createGenerator(true); 
				generator.writeStartObject(); 

				//6-Feb-2-17 Eric Shen change email domain
				//generator.writeObjectField('From', new ExactTargetFrom(fromAddress, fromName)); 
				generator.writeObjectField('From', new ExactTargetFrom(newFromAddress, fromName));
				generator.writeObjectField('To', new ExactTargetTo(toAddress, subscriberID, new ExactTargetContactAttributes(new ExactTargetSubscriberAttributes(subject, toName, emailBody))));  
				generator.writeEndObject(); 
				string jsonString = generator.getAsString();
				system.debug('==========>>> Sending to ExactTarget: ' + jsonString);

				req.setBody(jsonString);
				HTTPResponse res = new Http().send(req);
			
				JSONParser parser =JSON.createParser(res.getBody());
				parser.nextToken();
				parser.nextValue();
				System.debug('>>>>>>>>>>>>>:'+parser.getText());
				result.requestBody = jsonString;
				result.message = parser.getText();
				result.isSuccessful = true;
				
			} catch(Exception ex) {
				result.message = 'Error: ' + ex.getMessage();
				System.debug(ex.getMessage());
			}
		} else {
			result.message = 'Error: Invalid token';
		}
		
		return result;
	}
	
	//added by lingjun.jiang@bluewolf.com at 2014.6.25
	//send multiple email by exacttarget email 
	public ExactTargetSentResult sendMailToMultipleAddresses(string fromAddress, string fromName, string[] toAddresses, string[] toNames, string emailBody,string subject, string subscriberID){
	   ExactTargetSentResult result = new ExactTargetSentResult();
	   result.IsBatchEmail = true;
	   
		//6-Feb-2-17 Eric Shen change email domain
	   String newFromAddress =checkEmailDomainMapping(fromAddress);

	   if(isTest || validToken.length()>0){
			try {
				HttpRequest req = new HttpRequest();
				
				// 10 Sept 2015 (christopher.henschke@auspost.com.au) - updated for new end point used by Marketing team
				if(subscriberID == 'noreply@auspost.com.au') {
					req.setEndpoint(exactTargetLogIn.message_endpoint__c.replace('send?', 'sendBatch?')+validToken);
				}
				else {
					req.setEndpoint(exactTargetLogInMarketing.message_endpoint__c.replace('send?', 'sendBatch?')+validToken);         
				}

				req.setMethod('POST');
				req.setHeader('Content-Type', 'application/json');
				system.debug('email body:'+emailBody);
				emailBody = emailBody.replace('"','\'');
				system.debug('email body:'+emailBody);

				system.debug('req:'+req.getEndpoint());
				String body = '[';
				for (Integer i = 0; i < toAddresses.size(); i++) {
					if (body != '[') body += ', '; 
					 //6-Feb-2-17 Eric Shen change email domain
				   // body += '{"From": {"Address": "'+fromAddress+'","Name": "'+fromName+'"},"To": {"Address": "'+toAddresses[i]+'","SubscriberKey": "'+subscriberID+'","ContactAttributes": {"SubscriberAttributes": {"EmailSubject":"'+subject+'","Name":"'+toNames[i]+'","EmailBody":"'+emailBody+'"}}}}';
					  body += '{"From": {"Address": "'+newFromAddress+'","Name": "'+fromName+'"},"To": {"Address": "'+toAddresses[i]+'","SubscriberKey": "'+subscriberID+'","ContactAttributes": {"SubscriberAttributes": {"EmailSubject":"'+subject+'","Name":"'+toNames[i]+'","EmailBody":"'+emailBody+'"}}}}';
				}
				body += ']';
				system.debug('to address is' + toAddresses);
				req.setBody(body);
				HTTPResponse res = new Http().send(req);
				
				JSONParser parser =JSON.createParser(res.getBody());
				parser.nextToken();
				parser.nextValue();
				System.debug('>>>>>>>>>>>>>:'+parser.getText());
				result.requestBody = body;
				result.message = parser.getText();
				result.isSuccessful = true;

			} catch(Exception ex) {
				result.message = 'Error: ' + ex.getMessage();
				System.debug(ex.getMessage());
			}
		} else {
			result.message = 'Error: Invalid token';
		}
		
		return result;
	}

	//added by Kalpita Talwadekar - bulk email send - 14/09/2016
	//send multiple email by exacttarget email
	public ExactTargetSentResult sendMailToMultipleAddressesBulk(String batchToken,string fromAddress, string fromName, string[] toAddresses, string[] toNames,
			string[] emailBody2,string[] subject, String[] subscriberID){
	   ExactTargetSentResult result = new ExactTargetSentResult();
	   result.IsBatchEmail = true;


		//6-Feb-2-17 Eric Shen change email domain
	   String newFromAddress =checkEmailDomainMapping(fromAddress);
	   if(test.isRunningtest() || batchToken.length()>0){
		   // try {
				HttpRequest req = new HttpRequest();

				req.setEndpoint('https://' + mcTSEHostname + '/messaging/v1/messageDefinitionSends/key:' + exactTargetLogIn.BulkCaseTriggeredSendKey__c + '/sendBatch');

				req.setMethod('POST');
				req.setHeader('Content-Type', 'application/json');
				req.setHeader('Authorization', 'Bearer ' + validToken);
				 system.debug('req:'+req.getEndpoint());
				//system.debug('email body:'+emailBody2);
				String[] emailBody = new String[]{};
				//added by kalpita - to loop through list of body and make replacement
				for(String eBdy : emailBody2) {
					//eBdy.replaceFirst('"','');
					//String s1 = eBdy.replace('"','\'');
					//emailBody.add(eBdy.removeEnd('"').replaceFirst('"','').replace('"','\'').replace('&gt;','>').replace('&lt;','<'));
					emailBody.add(eBdy.removeEnd('"').replaceFirst('"',''));
				}
				//system.debug('email body:'+emailBody);
				String body = '[';
				//if(!toAddresses.isEMpty() && toAddresses.size() > 1) body = '[';
				for (Integer i = 0; i < toAddresses.size(); i++) {
					if (body != '[') body += ', ';

					//6-Feb-2-17 Eric Shen change email domain
				   // body += '{"From":{"Address":"'+fromAddress+'","Name":"'+fromName+'"},"To":{"Address":"'+toAddresses[i]+'","SubscriberKey":"'+subscriberID+'","ContactAttributes":{"SubscriberAttributes":{"Name":"'+toNames[i]+'","HTML__Body":"'+emailBody[i]+'","EmailSubject":"'+subject[i]+'"}}},"OPTIONS":{"RequestType":"ASYNC"}}';
					body += '{"From":{"Address":"'+newFromAddress+'","Name":"'+fromName+'"},"To":{"Address":"'+toAddresses[i]+'","SubscriberKey":"'+subscriberID[i]+'","ContactAttributes":{"SubscriberAttributes":{"Name":"'+toNames[i]+'","HTML__Body":"'+emailBody[i]+'","EmailSubject":"'+subject[i]+'"}}},"OPTIONS":{"RequestType":"ASYNC"}}';

				}
				body += ']';
				system.debug('json body before sending: ' + body);
				system.debug('to address is' + toAddresses);
				req.setBody(body);
				HTTPResponse res = new Http().send(req);

				JSONParser parser =JSON.createParser(res.getBody());
				system.debug('JSON Response: '+ JSON.serializePretty(res.getBody()));
				parser.nextToken();
				parser.nextValue();
				System.debug('>>>>>>>>>>>>>:'+parser.getText());
				result.requestBody = body;
				result.message = parser.getText();
				result.isSuccessful = true;

		  //  } catch(Exception ex) {
		  //      result.message = 'Error: ' + ex.getMessage();
		  //      System.debug(ex.getMessage());
		  //  }
		} else {
			result.message = 'Error: Invalid token';
		}
		return result;
	}
	// -- end of added by Kalpita --

	Exact_Target_LogIn__c  exactTargetLogIn {
		get {
			if(exactTargetLogIn == null) {
				exactTargetLogIn = [select clientid__c, clientsecret__c, message_endpoint__c, requestToken_endpoint__c, BulkCaseTriggeredSendKey__c,NetworkSearchSendKey__c,ShareInfoSendKey__c  from Exact_Target_LogIn__c limit 1][0]; // 13-Feb-17 Eric Shen Add two more sendkey fields
			}
			return exactTargetLogIn;
		} private set;
	}

	// 10 Sept 2015 (christopher.henschke@auspost.com.au) - updated for new end point used by Marketing team
	Exact_Target_LogIn__c  exactTargetLogInMarketing {
		get {
			if(exactTargetLogInMarketing == null) {
				exactTargetLogInMarketing = Exact_Target_LogIn__c.getValues('marketinglogin');
			}
			return exactTargetLogInMarketing;
		} private set;
	}

	public string validToken {
		get {
			if(validToken == null && exactTargetLogIn != null) {
				HttpRequest req = new HttpRequest();
				req.setEndpoint(exactTargetLogIn.requestToken_endpoint__c);
				req.setMethod('POST');
				req.setHeader('Content-Type', 'application/json');
				req.setBody('{"clientId": "'+exactTargetLogIn.clientid__c+'","clientSecret": "'+exactTargetLogIn.clientsecret__c+'"}');
		
				Http http = new Http();
				HTTPResponse res = http.send(req);
				try {
					JSONParser parser =JSON.createParser(res.getBody());
					parser.nextToken();
					parser.nextValue();
					System.debug('>>>>>>>>>>>>>>:'+parser.getText());
					if (parser.getText()<>null){
						validToken= parser.getText();    
					}
				} catch(Exception ex) {
					System.debug(ex.getMessage());
				}
			}
			return validToken;
		}
		private set;
	}

	public string mcTSEHostname {
		get {
			if(mcTSEHostname == null && exactTargetLogIn != null) {
				mcTSEHostname = new System.Url(exactTargetLogIn.Message_EndPoint__c).getHost();
			}
			return mcTSEHostname;
		}
		private set;
	}

// 6-Feb-2017 Eric Shen create a new method to check email domain
	private string checkEmailDomainMapping (string faddress) {

		String newFaddress =faddress;
		List<EmailDomainMapping__mdt> lstDomains = [SELECT MasterLabel, New_EmailDomain__c FROM EmailDomainMapping__mdt where MasterLabel= :faddress limit 1];

	   if (!lstDomains.isEmpty() ){

		   newFaddress = lstDomains[0].New_EmailDomain__c;
	   }

		return newFaddress;
	}	
	
}