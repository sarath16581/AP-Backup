public with sharing class brideas_CommunityCtrl {

    public static Boolean showUserNickname = false;

    @AuraEnabled
    public static String getUserDisplayName(Id userId){
        String displayName = '';
        String ntwrkId = Network.getNetworkId();

        if (ntwrkId != null || Test.isRunningTest()) {
            try {
                Network currNtwrk = brideas_CommunityHelper.getNetworkById(ntwrkId);
                brideas_CommunityCtrl.showUserNickname = Boolean.valueOf(currNtwrk.OptionsNicknameDisplayEnabled);

            } catch(Exception ex) {
                System.debug('CommunityCtrl::getUserDisplayName: ' + ex.getMessage());
            }
        }

        try {
            User usr = brideas_CommunityHelper.getUserById(userId);

            if (brideas_CommunityCtrl.showUserNickname && String.isNotBlank(usr.CommunityNickname)) {
                displayName = usr.CommunityNickname;
            } else {
                displayName = usr.FirstName + ' ' + usr.LastName;
            }

        } catch(Exception ex) {
            System.debug('brideas_CommunityCtrl::getUserDisplayName: ' + ex.getMessage());
        }

        return displayName;
    }

    @AuraEnabled
    public static String getSurveyURL(){
        return brideas_Helper.getConfigValue('survey_url');
    }
}