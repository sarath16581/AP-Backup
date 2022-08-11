/**
  * @date         : 04/08/2022
  * @description  : Apex class to be used in Transaction Security Policy based on Apex condition.
--------------------------------------- History --------------------------------------------------
04.08.2022    Swati.mogadala@auspost.com.au    Created
**/
global class LoginEventCondition implements TxnSecurity.EventCondition {
    //SSSW-Service agent profile Id
    @TestVisible private static final Set < String > PROFILESETID = new Set < String > {
        '00e90000001eeTkAAI'
    };
    // Allowed platform to login for agents
    @TestVisible private static final String PERMITTEDPROFILE = 'Windows';

    public boolean evaluate(SObject event) {
        switch on event {
            when LoginEvent loginEvent {
                return handleLoginEvent(loginEvent);
            }
            when null {
                return false;
            }
            when
            else {
                return false;
            }
        }
    }

    @TestVisible private boolean handleLoginEvent(LoginEvent loginEvent) {

        id userId = loginEvent.UserId;
        String platform = loginEvent.Platform;
        User user = [select id, name, profile.name from user where id =: userId];
        string currentProfile = user.Profile.id;
        if (!(platform.contains(PERMITTEDPROFILE)) && (PROFILESETID.contains(currentProfile))) {
            return true;
        }
        return false;
    }
}