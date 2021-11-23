/************************************
 * History
 * May-2015:  scherukuwada@salesforce.com   Added Sharing
 * **********************************/

public  class ApmsSetting 
{
    // 2014-09-15 Louis Wang (Bluewolf)
    // This controller is used for VF page ApmsSetting
    // The VF Page allows non-admin user to access Custom Setting
    // (only relevant fields from ApmsSetting__c are displayed)
    
    public SettingProxy setting {get; set;}
    public boolean settingExistsFlag {get;set;}
    
    public ApmsSetting() 
    {
        // there is only one record in Custom Setting APMS Setting, so fetch it
        list<ApmsSetting__c> settingList = [SELECT AusPostSupportEmail__c, AusPostSupportPhone__c, LinkedPlanName__c, 
                                                Name, OmnitureURL__c, PlanACommissionText__c, PlanAMonthlyFeeText__c, 
                                                PlanAPlanNameText__c, PlanATransactionFeeText__c, SecurePayWebsite__c, 
                                                SopEmailTemplateEmail__c, SopEmailTemplateWebsite__c, SopIntegrationGuideLink__c, 
                                                SopLivePaymentsLink__c, SopTestPaymentsLink__c, SopPhone__c 
                                                FROM APMSSetting__c
                                                LIMIT 1];
        if(settingList.size()==0)
        {
            settingExistsFlag = false;
            // need to throw error, as the custom setting is not setup yet
            string sectionError = 'The initial APMS Setting is not defined. Please see your System Administrator for assistance.';
            AddVfMessage(sectionError);
        }
        else
        {
            // pass the custom setting to wrapper class
            setting = new SettingProxy(settingList[0]);
            settingExistsFlag = true;
        }
    }

    private void AddVfMessage(string InfoDetail)
    {
        apexpages.Message msg = new Apexpages.Message(ApexPages.Severity.Info,InfoDetail);
        apexpages.addMessage(msg);            
    }    

    public PageReference save() 
    {
        if (setting != null)
        {
            try
            {
                update setting.getCustomSetting();
            }
            catch(Exception ex)
            {
                ApexPages.addMessages(ex);
                return null;            
            }
        }
        // refresh the current page
        return refresh();
    }

    public PageReference refresh()
    {
        // refresh the current page
        String URL = ApexPages.CurrentPage().GetURL();
        if(URL.contains('?'))
        {
            URL = URL.substring(0,URL.indexOf('?'));
        }
        PageReference currentPage = new PageReference(URL);
        currentPage.setRedirect(true);
        return currentPage;    
    }

    public class SettingProxy 
    {
        // must define for each field, otherwise there will be save error for standard user
        private Id id {get;set;}
        public string LinkedPlanName {get;set;}
        public string PlanACommissionText {get;set;}
        public string PlanAMonthlyFeeText {get;set;}
        public string PlanAPlanNameText {get;set;}
        public string PlanATransactionFeeText {get;set;}
        public string SecurePayWebsite {get;set;}
        public string AusPostSupportEmail {get;set;}
        public string SopEmailTemplateEmail {get;set;}
        public string SopEmailTemplateWebsite {get;set;}
        public string SopIntegrationGuideLink {get;set;}
        public string SopLivePaymentsLink {get;set;}
        public string AusPostSupportPhone {get;set;}
        public string SopTestPaymentsLink {get;set;}
        public string SopPhone {get;set;}

        public SettingProxy(ApmsSetting__c sop)
        {
            this.Id = sop.Id;
            this.LinkedPlanName = sop.LinkedPlanName__c;
            this.PlanACommissionText = sop.PlanACommissionText__c;
            this.PlanAMonthlyFeeText = sop.PlanAMonthlyFeeText__c;
            this.PlanAPlanNameText = sop.PlanAPlanNameText__c;
            this.PlanATransactionFeeText = sop.PlanATransactionFeeText__c;
            this.SecurePayWebsite = sop.SecurePayWebsite__c;
            this.AusPostSupportEmail = sop.AusPostSupportEmail__c;
            this.SopEmailTemplateEmail = sop.SopEmailTemplateEmail__c;
            this.SopEmailTemplateWebsite = sop.SopEmailTemplateWebsite__c;
            this.SopIntegrationGuideLink = sop.SopIntegrationGuideLink__c;
            this.SopLivePaymentsLink = sop.SopLivePaymentsLink__c;
            this.AusPostSupportPhone = sop.AusPostSupportPhone__c;
            this.SopTestPaymentsLink = sop.SopTestPaymentsLink__c;
            this.SopPhone = sop.SopPhone__c;
        }        

        public SettingProxy() {}
        
        public ApmsSetting__c getCustomSetting()
        {
            ApmsSetting__c toSave = new ApmsSetting__c();
            toSave.Id = this.Id;
            toSave.LinkedPlanName__c = this.LinkedPlanName;
            toSave.PlanACommissionText__c = this.PlanACommissionText;
            toSave.PlanAMonthlyFeeText__c = this.PlanAMonthlyFeeText;
            toSave.PlanAPlanNameText__c = this.PlanAPlanNameText;
            toSave.PlanATransactionFeeText__c = this.PlanATransactionFeeText;
            toSave.SecurePayWebsite__c = this.SecurePayWebsite;
            toSave.AusPostSupportEmail__c = this.AusPostSupportEmail;
            toSave.SopEmailTemplateEmail__c = this.SopEmailTemplateEmail;
            toSave.SopEmailTemplateWebsite__c = this.SopEmailTemplateWebsite;
            toSave.SopIntegrationGuideLink__c = this.SopIntegrationGuideLink;
            toSave.SopLivePaymentsLink__c = this.SopLivePaymentsLink;
            toSave.AusPostSupportPhone__c = this.AusPostSupportPhone;
            toSave.SopTestPaymentsLink__c = this.SopTestPaymentsLink;
            toSave.SopPhone__c = this.SopPhone;

            return toSave;
        }

    }
}