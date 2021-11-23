/*-----------------------------------------------------------------------------------------------------------------
Author:        Kenny Liew
Company:       Salesforce.com
Description:   Controller for bspLiveAgent Visualforce Components
Inputs:        

Test Class:    bspLiveAgent_Test
History
<Date>      <Authors Name>     	<Brief Description of Change>
2016-04-07	Kenny Liew			This existing controller is being modified to support functionality required for
								MyPost Business Help & Support Portal's requirements.  New custom setting added
								to support the additional live agent chat button, separate from existing BSP's.
-----------------------------------------------------------------------------------------------------------------*/
public class bspLiveAgent
{
    public string buttonId {get;set;}
    public string deploymentId {get;set;}
    public string orgId {get;set;}
    public string scriptSrc {get;set;}
    public string init {get;set;}
    public Boolean isMpbHspFlag {get;set;}
    public Boolean isSTFlag {get;set;}
        
    public bspLiveAgent()
    {
        // fetch Ids from custom setting
        // note: Live Agent only takes 15 characters, and hence must use string as data type here.
        //        Otherwise, it will be automatically coverted to 18 characters and LiveAgent will stop to work.

        // 21/04/16 - Modified for MyPostBusiness
        PageReference page = ApexPages.currentPage();
        isSTFlag = false;
        string pageURL = '';
        if (page != null)
        	pageURL = page.getUrl();

        // 21/04/16 - Modified for MyPostBusiness
        // 
        if (pageURL != null)
        {
           if (pageURL.containsIgnoreCase('MpbHspEnquiry'))
           {
               mpbHspLiveChatBtnSettings__c config = mpbHspLiveChatBtnSettings__c.getInstance();
               buttonId = config.LiveAgentButtonId__c;
               deploymentId = config.LiveAgentDeploymentId__c;
               orgId = config.LiveAgentOrgId__c;
               scriptSrc = config.LiveAgentScriptSrc__c;
               init = config.LiveAgentInit__c;
            }
            else
            {
                CCUSettings__c config = CCUSettings__c.getInstance();
                buttonId = config.LiveAgentButtonId__c;
                deploymentId = config.LiveAgentDeploymentId__c;
                orgId = config.LiveAgentOrgId__c;
                scriptSrc = config.LiveAgentScriptSrc__c;
                init = config.LiveAgentInit__c;
                isSTFlag = hasSTBillingAccounts();
            }
        }
        
        /*// from the test class the page reference will be null
        if (page == null)    
        {
            CCUSettings__c config = CCUSettings__c.getInstance();
            buttonId = config.LiveAgentButtonId__c;
            deploymentId = config.LiveAgentDeploymentId__c;
            orgId = config.LiveAgentOrgId__c;
            scriptSrc = config.LiveAgentScriptSrc__c;
            init = config.LiveAgentInit__c;
        }*/
    }

    @AuraEnabled(cacheable=true)
    public static CCUSettings__c getLiveAgetSettings(){
        return CCUSettings__c.getInstance();
    }
    
    @AuraEnabled(cacheable=true)
    public static boolean hasAPBillingAccounts(){
        return bspBaseUplift.hasAPBillingAccounts;
    }

    @AuraEnabled(cacheable=true)
    public static boolean hasSTBillingAccounts(){
        return bspBaseUplift.hasSTBillingAccounts;
    }
}