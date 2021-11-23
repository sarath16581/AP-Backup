/**************************************************
Type:         Controller for visualforce components
                bspHeader, bspYourDetails
History:
--------------------------------------------------
2014-05-27    Louis Wang (Bluewolf)        Created.
2017-02-16    David Catindoy (Accenture)   Added fields on the user query.
2017-04-20    Andrew Judd (salesforce)     Fix for Defect W-001650 INC0921311 - Added check to not trigger BAScope check if context is My Post Business page
2018-05-17	  Subbu C (salesforce) 			Added field to check for Cognition Authorization Rules
2019-04-28 nathan.franklin@auspost.com.au Uplift for better BAM support
2021-09-15  prerna.rahangdale@auspost.com.au added the getters for the smartspeak chat attributes.
**************************************************/
public with sharing class bspComponent extends bspBase {

    /*********
     * Can be removed on next deployment... added due to deployment errors
     * https://success.salesforce.com/issues_view?id=a1p300000008YkUAAU
     */
    public Boolean hideSSCR5 {get;set;}
    public String BAScope {get;set;}
    /*
     * END
     **********/

     public static final mpbHspLiveChatBtnSettings__c  mpbLiveChatSettings {
        get {
            return mpbHspLiveChatBtnSettings__c.getInstance();
        }
    }

    /**
     * SmartSpeak Chat Bot attributes required to populate the Chat button on MPB Portal
     */
    public  String orgId{
        get {
            return mpbLiveChatSettings.LiveAgentOrgId__c;
        }
    }

    /**
     * SmartSpeak Chat Bot attributes required to populate the Chat button on MPB Portal
     */
    public  String chatInit{
        get {
            return mpbLiveChatSettings.LiveAgentInit__c;
        }
    }

    /**
     * SmartSpeak Chat Bot attributes required to populate the Chat button on MPB Portal
     */
    public  String chatScriptSrc{
        get {
            return mpbLiveChatSettings.LiveAgentScriptSrc__c;
        }
    }

    public  String buttonId{
        get {
            return mpbLiveChatSettings.LiveAgentButtonId__c;
        }
    }

    public  String deploymentId{
        get {
            return mpbLiveChatSettings.LiveAgentDeploymentId__c;
        }
    }

    public  String endpoint {
        get {
            return mpbLiveChatSettings.Live_Agent_SS_Endpoint__c;
        }
    }

    public  String serviceSLA {
        get {
            if(loginAccount != null){
                return loginAccount.ServiceSLA__c;
            } else {
                return '';
            }
        }
    }
    /**
     * Smart Speak Chat Bot Attributes End
     */

    public String businessName {
        get {
            return loginAccount.Name;
        }
    }
    public String businessNumber {
        get {
            if(!isMpbHspFlag) {
                return primaryBillingAccount.LEGACY_ID__c;
            } else {
                return '';
            }
        }
    }
    public Boolean isCognitionUser {
        get {
            if(isCognitionUser == null) {
                List<Authorization_Rule__c> cognitionRules = [SELECT ID FROM Authorization_Rule__c WHERE AccessRole__c = :Label.Cognition_User AND Contact__c = :loginContactId LIMIT 1];
                if (cognitionRules.isEmpty()) {
                    isCognitionUser = false;
                } else {
                    isCognitionUser = true;
                }
            }

            return isCognitionUser;
        }
        private set;
    }

}