public class MpbHspCallMeBackRestController {
 	public String requestEndpoint {get;set;}
	public String requestMethod {get;set;}
	public String requestBody {get;set;}
	public String responseStatus {get;set;}
	public Integer responseStatusCode {get;set;}
	public String responseBody {get;set;}
    public String phoneNumber {get;set;}
    public Integer calloutResponse  {get;set;}
    public SmartSpeakRestAPI smartSpeakRestAPI {get;set;}
    public SmartSpeakRestAPI.smartSpeakBodyReq smartSpeakBodyRequest {get;set;}

    @testVisible
    private User loginUser {get;set;}
    @testVisible
    private string loginContactId {get;set;}
    @testVisible
    private string loginAccountId {get;set;}
    
    
	public MpbHspCallMeBackRestController ()
    {
        
        try
        {
            
            requestEndpoint = '';
            requestMethod = '';
            requestBody = '';
            responseStatus = '';
            responseStatusCode = -1;
            responseBody = '';
            phoneNumber = '';
            calloutResponse  = -1;


            smartSpeakRestAPI = new SmartSpeakRestAPI();
            smartSpeakBodyRequest = new SmartSpeakRestAPI.smartSpeakBodyReq();
            smartSpeakBodyRequest.phoneNumber = '';
            smartSpeakBodyRequest.callbackData1 = '';

            retrieveUserAndContact();

        }
        catch (Exception e)
        {
            system.debug('Exception in MpbHspCallMeBackRestController.MpbHspCallMeBackRestController() - Ex: '+e.getMessage());
        }
    }
    
    
    public void callout()
    {
        try
        {
             //system.debug('MpbHspCallMeBackRestController.callout()');
            
            calloutResponse = calloutServiceState();
            if (calloutResponse == 0)
                calloutResponse = calloutMakeRequest();        
            }
        catch(Exception e)
        {
            system.debug('Exception in MpbHspCallMeBackRestController.callout() - Ex: '+e.getMessage());
        }
        
    }
    
	public Integer calloutServiceState(){
        
        try
        {

            httpResponse res = smartSpeakRestAPI.callout('POST', smartSpeakRestAPI.serviceStateURL, requestBody);
            responseStatus = res.getStatus();
            responseStatusCode = res.getStatusCode();
            responseBody = res.getBody();

            if (smartSpeakRestAPI.debugMode > 0)
            {
                system.debug('responseStatus:' + responseStatus);
                system.debug('responseStatusCode:' + responseStatusCode);
                system.debug('responseBody:' + responseBody);
            }

            if (responseBody.contains('true'))
                return 0;
            else 
                return 1;  // status to indicate that service is unavailable due to out of hours. 
        }
        catch(Exception e)
        {
            system.debug('Exception in MpbHspCallMeBackRestController.calloutServiceState:'+e.getMessage());
            return -1;
        }
	}
    
    public Integer calloutMakeRequest(){
        
        try
        {
            system.debug('MpbHspCallMeBackRestController.calloutMakeRequest()');

            smartSpeakBodyRequest.phoneNumber = phoneNumber;
            smartSpeakBodyRequest.callbackData1 = loginContactId;
            smartSpeakBodyRequest.createBody(phoneNumber,loginContactId);

            requestBody = smartSpeakBodyRequest.ReqBody;

            // supplied phone number should be 10 digits without the international code and an Australian number
            //requestBody = 'phoneNumber=' +phoneNumber+ '&callbackData1=' + loginContactId;

            if (smartSpeakRestAPI.debugMode > 0)
                system.debug('requestBody:'+requestBody);
        
            httpResponse res = smartSpeakRestAPI.callout('POST', smartSpeakRestAPI.serviceRequestURL, requestBody);
            responseStatus = res.getStatus();
            responseStatusCode = res.getStatusCode();
            responseBody = res.getBody();

            if (smartSpeakRestAPI.debugMode > 0)
            {
                system.debug('responseStatus:'+responseStatus);
                system.debug('responseStatusCode:'+responseStatusCode);
                system.debug('responseBody:'+responseBody);
            }

            
            if (responseBody.contains('success'))
                return 0;
            else 
                return 2;  // There has been a failure of some sort.  Invalid number or service has failed.
            
        }
        catch(Exception e)
        {
            system.debug('Exception in MpbHspCallMeBackRestController.calloutMakeRequest:'+e.getMessage());
            return -1;
        }
            
	}
    
    public void retrieveUserAndContact()
    {
        
        try
        {
            // get Contact based on login User's ContactId (only applicable for Community User)
            string userId = UserInfo.getUserId();
            
            list<User> userList = [SELECT Firstname, Lastname, Street, City, State, PostalCode, CompanyName, ContactId, 
                                    Contact.AccountId, Contact.Account.ServiceSLA__c, Contact.BillingAccount__c, Contact.CCUAuthorisedAllOrgCases__c, 
                                    DPID__c, Country
                                    FROM User
                                    WHERE Id = : userId
                                    LIMIT 1];        
    
            if(userList.size() > 0)
            {
                loginUser = userList[0];
                loginContactId = loginUser.ContactId;
                loginAccountId = loginUser.Contact.AccountId;            
            }     
        }
        catch(Exception e)
        {
            system.debug('Exception in MpbHspCallMeBackRestController.retrieveUserAndContact() - Ex: '+e.getMessage());
        }
    }

}