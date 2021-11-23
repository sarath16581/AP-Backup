global with sharing class AusPostInboundSocialPostHandlerImpl extends Social.InboundSocialPostHandlerImpl implements Social.InboundSocialPostHandler{
 
   global override string  getDefaultAccountId() {
   	
   	string accountName = system.label.socialAccountName;
   	string accountId = null;
   	
   	try {
   		accountId =	[select Id from account where name = :accountName limit 1].Id;
   	}
   	
   	catch(exception e) {}
   	
   	return accountId;
  
   }
}