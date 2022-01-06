public without sharing class brideas_EventHandler {

    public static void statusUpdate(Idea voteIdea) {
        Map<String, String> updateSettings = brideas_Helper.getStatusUpdateSettings();

        if (updateSettings == null) return;

        Boolean isEnabled = Boolean.valueOf(updateSettings.get('active'));

        if (!Test.isRunningTest()) {
            if (!isEnabled || voteIdea.VoteTotal < Decimal.valueOf(updateSettings.get('threshold')) || voteIdea.Status != updateSettings.get('original_status')) {
                return;
            }
        }

        voteIdea.Status = updateSettings.get('new_status');

        try {
            update voteIdea;
        } catch (Exception e) {
            System.debug('brideas_EventHandler::statusUpdate: ' + e.getMessage());
        }
    }
}