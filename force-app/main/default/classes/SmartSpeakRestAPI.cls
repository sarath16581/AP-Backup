/*-----------------------------------------------------------------------------------------------------------------
Author:        Nathan Main
Company:       Salesforce.com
Description:   Wrapper REST API Class for SmartSpeak API
Inputs:

Test Class:    SmartSpeakRestAPI_Test
History
<Date>         <Authors Name>     	<Brief Description of Change>
2016-04-21	   Nathan Main 		    New class to wrap the REST API calls to SmartSpeak
-----------------------------------------------------------------------------------------------------------------*/
public with sharing class SmartSpeakRestAPI {


	public MpbHsp_Smart_Speak_Setting__c smartSpeakApiSettings {get;set;}
	public smartSpeakBodyReq bodyRequest {get;set;}
	public String contentType {get;set;}
	public String apiKey {get;set;}
	public Integer timeout {get;set;}
	public String serviceRequestURL {get;set;}
	public String serviceStateURL {get;set;}
	public Integer debugMode {get;set;}

	public SmartSpeakRestAPI()
	{
		contentType = '';
		apiKey = '';
		timeout = 0;
		serviceRequestURL = '';
		serviceStateURL = '';
		debugMode = 0;

		getCustomSettings();
	}

	/*------------------------------------------------------------
	Author:        Nathan Main
	Company:       Salesforce.com
	Description:   Perform a Rest API callout using POST nd return a httpResponse
	Inputs:

	History
	<Date>      <Authors Name>     <Brief Description of Change>
	21/04/16    Nathan Main			Created.
	------------------------------------------------------------*/
	//this was a static method.....not sure why it needs to be static
	//public static httpResponse callout(String httpMethod, String endpoint, String body){
	public  httpResponse callout(String httpMethod, String endpoint, String body){
		//Instantiate an httpRequest and set the required attributes
		httpRequest req = new httpRequest();
		req.setMethod(httpMethod);
		req.setEndpoint(endpoint);
        if (string.isNotBlank(body))
        	req.setBody(body);

        //req.setHeader('Content-Type','application/json');
        req.setHeader('Content-Type',contentType);
        req.setHeader('x-api-key',apiKey);

		//You can adjust the timeout duration (in milliseconds) to deal with slow servers or large payloads
		req.setTimeout(timeout);

		//Use the HTTP Class to send the httpRequest and receive an httpResposne
		/*If you are not using an HttpCalloutMock: 
		if (!test.isRunningTest){
		*/
		httpResponse res = new http().send(req);
		/*If you are not using an HttpCalloutMock: 
		}
		*/
		if (debugMode > 0)
		{
			system.debug('httpResponse from service call: '+res.toString());
			system.debug('Response Body: '+res.getBody());
		}
		return res;
	}

	/*------------------------------------------------------------
		Author:        Nathan Main
		Company:       Salesforce.com
		Description:   Get custom settings associated with the Smart Speak API
		Inputs:

		History
		<Date>      <Authors Name>     <Brief Description of Change>
		21/04/16    Nathan Main			Created.
		------------------------------------------------------------*/
	public void getCustomSettings()
	{
		try
		{

			Map<String, MpbHsp_Smart_Speak_Setting__c> smartSpeakApiSettings = MpbHsp_Smart_Speak_Setting__c.getAll();
			if (!smartSpeakApiSettings.isEmpty())
			{
				MpbHsp_Smart_Speak_Setting__c customSettings = MpbHsp_Smart_Speak_Setting__c.getInstance('Settings');
				if (customSettings != null)
				{
					apiKey = customSettings.x_api_key__c;
					contentType = customSettings.Content_Type__c;
					timeout = Integer.valueOf(customSettings.time_out__c);
					serviceRequestURL = customSettings.ServiceRequest__c;
					serviceStateURL = customSettings.ServiceState__c;
					debugMode = Integer.valueOf(customSettings.debugMode__c);
				}
			}


			if (debugMode > 0)
			{
				system.debug('contentType: ' + contentType + ' apiKey:' + apiKey + ' timeout:' + timeout + ' serviceRequestURL:' + serviceRequestURL +
						'serviceStateURL:' + serviceStateURL + ' debugMode:' + debugMode);
			}
		}
		catch (Exception e)
		{
			system.debug('Exception in SmartSpeakRestAPI.getCustomSettings, Exception: ' +e.getMessage());
		}
	}


    public class smartSpeakBodyReq
	{
		public String phoneNumber {get;set;}
		public String callbackData1 {get;set;}
		public String ReqBody {get;set;}

		public smartSpeakBodyReq(){
			phoneNumber = '';
			callbackData1 = '';
			ReqBody = '';
		}



		/*------------------------------------------------------------
		Author:        Nathan Main
		Company:       Salesforce.com
		Description:   Method to set the required message body and format
					   Due to the type of Header users ('Content-Type','application/x-www-form-urlencoded)
					   a JSON formatted body cannot be used.
		Inputs:

		History
		<Date>      <Authors Name>     <Brief Description of Change>
		21/04/16    Nathan Main			Created.
		------------------------------------------------------------*/
		public void createBody(String phNumber, String contactId)
		{
			ReqBody  = 'phoneNumber=' +phNumber+ '&callbackData1=' + contactId;
		}

	}


	

}