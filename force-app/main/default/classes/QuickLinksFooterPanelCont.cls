/**************************************************
Type:       Visualforce controller
Purpose:    Provides the controller logic to create the quick links based on the link definitions in the QuickReference__c records.
			Selects all the records of record type 'QuickLinks' and uses the latest attachments on the records
			as the link images.
Used By:    QuickLinksFooterPanel.page         
History:
--------------------------------------------------
18.12.2013  Mohamed.Atheek@bluewolf.com  Created   
05.04.2019	ramtej.juloori@auspost.com.au	Added methods to identify 
			live agent user and get colors to style chat tab
17.05.2021	Modified Constructor to cater for StarTrack Quicklinks

06.07.2021 prerna.rahangdale@auspost.com.au Added remoteAction getChatDetails to get the LiveChatranscript details from
			Agent Accepted Work Item.
**************************************************/

global with sharing class QuickLinksFooterPanelCont
{
	final static String APPLICATION_NAME = 'applicationName';
    final static String APPLICATION_KEY = 'appKey';
    final static String SERVICE_NAME = 'serviceName';
    final static String TOKEN_DURATION = 'tokenDuration';
    final static String TOKEN_REQUEST = 'tokenRequest';
    
	//Maximum number of links to show on a large screen (using twitter bootstrap)
	private static final Integer NUMBER_OF_COLUMNS = 6;
	
	public string token {get;set;}
	public string addressSearchURL {get;set;}
	public string addressDetailsURL {get;set;}
	

	//n x 6 multi-dimensional array
	public List<List<QuickLinkWrapper>> quickLinkWrappers 
	{
		get;		
		private set;
	}
	
	//Get the available colors for live agent chat tab from metadata 
    public String colorCodes {
        get{
            List<String> colorCodeList = new List<String>();
            for(Live_Agent_Tab_Color__mdt tabColorRec :[SELECT Id, Color_Code__c FROM Live_Agent_Tab_Color__mdt]){
                colorCodeList.add(tabColorRec.Color_Code__c);
            }
            return JSON.serialize(colorCodeList);
        }
    }
	
	//verify if the current logged in user is live agent user
	public boolean isLiveAgentUser{
		get{
			return [SELECT Id, UserPermissionsLiveAgentUser FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].UserPermissionsLiveAgentUser;
		}
	}
	//Method to get the ChatDetails from AgentWork - Work Item Id from LiveChatTranscript.
	@RemoteAction
	global static LiveChatTranscript getChatDetails(Id workItemId){
		return [SELECT Id, ChatKey, Tracking_Number__c FROM LiveChatTranscript  WHERE Id = :workItemId LIMIT 1];
	}

	/**
	 * Sets quicklinkWrappers for AP or StarTrack based on page context
	 */
	public QuickLinksFooterPanelCont() 
	{
		quickLinkWrappers = new List<List<QuickLinkWrapper>>();
		List<QuickReference__c> quicklinks = null;

		// We run a different query if we are in StarTrack Service & Support
		String strUrl = ApexPages.currentPage().getUrl();

		if(strUrl.contains('QuickLinksFooterPanelST')) {
			quickLinks = [SELECT Id, Name, FullHyperlink__c
			FROM QuickReference__c
			WHERE Hide_ST__c = false AND RecordType.DeveloperName = 'QuickLinks'
			ORDER BY SortOrder_ST__c];
		} else {
			quickLinks = [SELECT Id, Name, FullHyperlink__c
			FROM QuickReference__c
			WHERE Hide__c = false AND RecordType.DeveloperName = 'QuickLinks'
			ORDER BY SortOrder__c];
		}
		if (quickLinks.size() > 0) 
		{									  
			Map<Id, Attachment> attachmentMap = new Map<Id, Attachment>();									  
			for (Attachment a : [SELECT Id, ParentId 
								 FROM Attachment 
								 WHERE ParentId IN :quickLinks 
								 ORDER BY LastModifiedDate ASC]) 
			{
				attachmentMap.put(a.ParentId, a);
			}
			
			for (Integer i = 0; i < quickLinks.size(); i += NUMBER_OF_COLUMNS) 
			{
				List<QuickLinkWrapper> wlist = new List<QuickLinkWrapper>();
				for (Integer j = 0; j < NUMBER_OF_COLUMNS; j++) 
				{
					if (i + j >= quickLinks.size())
					{
						break;
					}
					wlist.add(new QuickLinkWrapper(quickLinks[i + j], attachmentMap.get(quickLinks[i + j].Id)));
				}
				quickLinkWrappers.add(wlist);
			}
		}
		
		token = '';
		addressSearchURL = '';
		addressDetailsURL = '';
		
		AusPostSettings__c setting = AusPostSettings__c.getValues('AddressValidation');
		if(setting != null){
			token = setting.Token__c;
			addressSearchURL = setting.URL2__c;
			addressDetailsURL = setting.URL3__c;
		} 
	}
	
	
    @RemoteAction   
    global static string getToken(boolean refreshToken) {
        string result = '';
        AusPostSettings__c addressValidationSetting = AusPostSettings__c.getValues('AddressValidation');
        result = addressValidationSetting.Token__c;
        if(result.trim() == '')
        	refreshToken = true;
	        
	    if(refreshToken) {
	        HttpRequest req = new HttpRequest();
	        String username = addressValidationSetting.Username__c;
	        String password= addressValidationSetting.Password__c;
	        Http http = new Http();
	        req.setEndpoint(addressValidationSetting.URL__c);
	        req.setMethod('POST');
	        Blob headerValue = Blob.valueOf(username +':' +password);
	        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
	        System.debug('Encoder Value' + EncodingUtil.base64Encode(headerValue));
	        req.setHeader('Authorization', authorizationHeader);
	        req.setHeader('Content-Type','application/json');
	        JSONGenerator gen = JSON.createGenerator(true);
	        gen.writeStartObject();
	        gen.writeFieldName(TOKEN_REQUEST);
	        gen.writeStartObject();
	        gen.writeStringField(APPLICATION_NAME, addressValidationSetting.ApplicationName__c);
	        gen.writeStringField(APPLICATION_KEY, addressValidationSetting.AppKey__c);
	        gen.writeStringField(SERVICE_NAME, addressValidationSetting.ServiceName__c);
	        gen.writeStringField(TOKEN_DURATION, addressValidationSetting.TokenDuration__c);
	        gen.writeEndObject();
	        gen.writeEndObject();
	        req.setBody(gen.getAsString());
	        // modified by shengpeng.xiao@bluewolf.com at 2014.7.9
	        // adjust to test class as callout not allowed in test class
	        HttpResponse res;
	        if(!Test.isRunningTest()) {
	        	res = http.send(req);
	        }else {
	        	res = new Httpresponse();
	        	res.setBody('{"userToken1":"userToken"}');
	        }
	        JSONParser parser = JSON.createParser(res.getBody());
	        while(parser.nextToken()!=null) 
	        {
	            if(parser.getCurrentName() == 'userToken' && parser.getText() != 'userToken') 
	            {
	                result = parser.getText();
	                if(result != '') {
	                	addressValidationSetting.Token__c = result;
	                	update addressValidationSetting;
	                	system.debug('Got new token from AusPost: ' + result);
	                	break;
	                }
	            }
	        }
	    }
        return result;
    }
	
	public class QuickLinkWrapper 
	{
		public QuickReference__c  ql
		{
			get; 
			set;
		}
		
		public Attachment a
		{
			get; 
			set;
		}
		
		public QuickLinkWrapper(QuickReference__c  ql, Attachment a) {
			this.ql = ql;
			this.a = a;
		}
	}
}