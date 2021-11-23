/**************************************************
Description: This is the controller for components: 
APT_StarTrackApprovalHeaderComponent & APT_StarTrackApprovalFooterComponent 
used in Startrack Approval VF templates
@CreatedBy: Krishna Velani
@CreatedDate: 29th April 2021
@ModifiedBy:
@ModifiedDate:
**************************************************/

public class APT_StarTrackApprovalHeaderFooterImage {
     /**
     * returns header image url
     */
    public String getHeaderURL() {
        Apttus_Config2__ConfigSystemProperties__c configSystemProperties = Apttus_Config2__ConfigSystemProperties__c.getValues(APT_Constants.CUSTOM_SETTING_RECORD_NAME_SYSTEM_PROPERTIES);
        Document headerDoc = [SELECT Id FROM Document  WHERE DeveloperName = 'APT_StarTrack_Approval_Header_Logo'];
        if(configSystemProperties != null && headerDoc != null) {
            String headerURL = configSystemProperties.Apttus_Config2__InstanceUrl__c + APT_Constants.SEPERATOR_BACKWARD_SLASH + APT_Constants.SERVLET + APT_Constants.SEPERATOR_BACKWARD_SLASH + APT_Constants.SERVLET + APT_Constants.SEPERATOR_DOT + APT_Constants.IMAGE_SERVER + APT_Constants.PARMA_ID + headerDoc.Id + APT_Constants.PARMA_O_ID + UserInfo.getOrganizationId();
            System.debug('HeaderURl'+headerURL);
            return headerURL;
        }
        return null;
    }
    
     /**
     * returns footer image url
     */
    public String getFooterURL() {
        Apttus_Config2__ConfigSystemProperties__c configSystemProperties = Apttus_Config2__ConfigSystemProperties__c.getValues(APT_Constants.CUSTOM_SETTING_RECORD_NAME_SYSTEM_PROPERTIES);
        Document footerDoc = [SELECT Id FROM Document  WHERE DeveloperName = 'APT_StarTrack_Approval_Footer_Logo'];
        if(configSystemProperties != null && footerDoc != null) {
            String footerURL = configSystemProperties.Apttus_Config2__InstanceUrl__c + APT_Constants.SEPERATOR_BACKWARD_SLASH + APT_Constants.SERVLET + APT_Constants.SEPERATOR_BACKWARD_SLASH + APT_Constants.SERVLET + APT_Constants.SEPERATOR_DOT + APT_Constants.IMAGE_SERVER + APT_Constants.PARMA_ID + footerDoc.Id + APT_Constants.PARMA_O_ID + UserInfo.getOrganizationId();
            System.debug('FooterURL'+footerURL);
            return footerURL;
        }
        return null;
    }
    

}