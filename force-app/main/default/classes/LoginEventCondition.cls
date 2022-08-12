/**
  * @date         : 04/08/2022
  * @description  : Apex class to be used in Transaction Security Policy based on Apex condition.
--------------------------------------- History --------------------------------------------------
04.08.2022    Swati.mogadala@auspost.com.au    Created
**/
global class LoginEventCondition implements TxnSecurity.EventCondition {
    @TestVisible 
    private static final Set <String> PERMITTEDPROFILE = new Set <String>{'SSSW - Service Agent'}; // Profiles to check
    @TestVisible
    private static final String PERMITTEDPLATFORM = 'Windows'; // Allowed platform for permitted profiles

    public boolean evaluate(SObject event) {
        switch on event {
            when LoginEvent loginEvent {
                return handleLoginEvent(loginEvent);
            }
            when null {
                return false;
            }
            when else {
                return false;
            }
        }
    }

    @TestVisible 
    private boolean handleLoginEvent(LoginEvent loginEvent) {
        id userId = loginEvent.UserId;
        String platform = loginEvent.Platform;
        User user = [select id, name, profile.name from user where id =: userId];
        string currentProfile = user.Profile.name;
        if (!(platform.contains(PERMITTEDPLATFORM)) && (PERMITTEDPROFILE.contains(currentProfile))) {
            return true;
        }
        return false;
    }
}