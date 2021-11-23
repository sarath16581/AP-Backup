@isTest
private class ApmsSettingTest 
{
    // 2014-09-16 Louis Wang (Bluewolf)
    //    This class provides test coverage for ApmsSetting visualforce page and ApmsSetting controller
    //    93% coverage

    @isTest
    static void apmsSetting_NoSetting_Test() 
    {
        PageReference landingPage = Page.ApmsSetting;
        Test.setCurrentPage(landingPage); 
        ApmsSetting apms = new ApmsSetting();
        
        apms.Save();
        apms.Refresh();
    }

    @isTest
    static void apmsSetting_HasSetting_Test() 
    {
        ApmsSetting__c customSetting = new ApmsSetting__c();
        customSetting.PlanAPlanNameText__c = 'Launch Price';
        insert customSetting;

        PageReference landingPage = Page.ApmsSetting;
        Test.setCurrentPage(landingPage); 
        ApmsSetting apms = new ApmsSetting();
        apms.setting.PlanAPlanNameText = 'New Plan';
        
        apms.Save();
        apms.Refresh();
    }
}