public class APT_URLimagesHeaderFooter{
   /**
     * return header image url
     */
    public String getHeaderURL() {
        Apttus_Config2__ConfigSystemProperties__c configSystemProperties = Apttus_Config2__ConfigSystemProperties__c.getValues(APT_Constants.CUSTOM_SETTING_RECORD_NAME_SYSTEM_PROPERTIES);
        Document headerDoc = [SELECT Id FROM Document  WHERE Name = :APT_Constants.R2T_CONTRACT_LETTER_HEAD];
        if(configSystemProperties != null && headerDoc != null) {
            String headerURL = configSystemProperties.Apttus_Config2__InstanceUrl__c + APT_Constants.SEPERATOR_BACKWARD_SLASH + APT_Constants.SERVLET + APT_Constants.SEPERATOR_BACKWARD_SLASH + APT_Constants.SERVLET + APT_Constants.SEPERATOR_DOT + APT_Constants.IMAGE_SERVER + APT_Constants.PARMA_ID + headerDoc.Id + APT_Constants.PARMA_O_ID + UserInfo.getOrganizationId();
            return headerURL;
        }
        return null;
    }
    
     /**
     * return footer image url
     */
    public String getFooterURL() {
        Apttus_Config2__ConfigSystemProperties__c configSystemProperties = Apttus_Config2__ConfigSystemProperties__c.getValues(APT_Constants.CUSTOM_SETTING_RECORD_NAME_SYSTEM_PROPERTIES);
        Document footerDoc = [SELECT Id FROM Document  WHERE Name = :APT_Constants.R2T_QUOTE_LETTER_HEAD_FOOTER];
        if(configSystemProperties != null && footerDoc != null) {
            String footerURL = configSystemProperties.Apttus_Config2__InstanceUrl__c + APT_Constants.SEPERATOR_BACKWARD_SLASH + APT_Constants.SERVLET + APT_Constants.SEPERATOR_BACKWARD_SLASH + APT_Constants.SERVLET + APT_Constants.SEPERATOR_DOT + APT_Constants.IMAGE_SERVER + APT_Constants.PARMA_ID + footerDoc.Id + APT_Constants.PARMA_O_ID + UserInfo.getOrganizationId();
            return footerURL;
        }
        return null;
    }
    }