/**
  * @date         : 04/08/2022
  * @description  : Apex class to be used in Transaction Security Policy based on Apex condition.
--------------------------------------- History --------------------------------------------------
04.08.2022    Swati.mogadala@auspost.com.au    Created
**/
public with sharing class TransactionEventCondition implements TxnSecurity.EventCondition{

	public boolean evaluate(SObject event) {
     switch on event{
    		when  LoginEvent loginevent{
        	
                return evaluate(loginEvent);
            }
             
            when else{
                return false;
            }
                
            }
}
      @TestVisible private boolean evaluate(LoginEvent loginEvent){
        Transaction_Security_Policy__c	settings = Transaction_Security_Policy__c.getvalues('LoginEvent');
        string userId = loginEvent.UserId;
        String platform = loginEvent.Platform;
    	// get the Profile name from the current user
   		User user = [select id, name, profile.name from user where id =:userid];
        string Currentprofile = user.profile.name;
          system.debug('currentprofile'+Currentprofile);
          system.debug('Currentplatform'+platform);
          system.debug('setting'+settings);
           if(settings!=null){
               if(Currentprofile.contains(settings.Profiles_to_Monitor__c) && !(platform.Contains(settings.Platform__c)))
        return true;
   			 }
        return false;
   	 	}       
            
     }