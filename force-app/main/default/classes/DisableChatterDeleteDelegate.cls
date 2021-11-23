/**
 * Helper for Disable Chatter Deletes App
 * Author: Marcus Ericsson - mericsson@salesforce.com
 */
public class DisableChatterDeleteDelegate
{
    // Constants
    private static final String ErrorText = 'You do not have permission to perform this delete';

  public static boolean allowDelete() {
      Chatter_Delete_Settings__c settings = Chatter_Delete_Settings__c.getInstance();
      if (settings == null) {
          // do default settings
          String profileId = UserInfo.getProfileId();
          Boolean modifyAllData = [select PermissionsModifyAllData from Profile where id = :profileId].PermissionsModifyAllData;
          if (modifyAllData) {
              return true;
          }
          else {
              return false;
          }
      }
      else {
          // use custom defined settings
          return settings.Allow_Feed_Post_and_Comment_deletes__c;
      }
  }

    // RSolomon - Error message can be configured in Custom settings: Chatter Delete Error Message
    public static string ChatterDeleteErrorMsg() {
      Chatter_Error_Message__c ErrMsg = Chatter_Error_Message__c.getInstance();
      if (ErrMsg == null) {
          // use standard error message  
              return ErrorText;
      }
      else {
          // use custom defined error message
          return ErrMsg.Chatter_Error_Message__c;
      }
  }
}