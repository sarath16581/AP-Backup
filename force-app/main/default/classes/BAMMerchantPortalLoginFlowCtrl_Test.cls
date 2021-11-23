@isTest
public class BAMMerchantPortalLoginFlowCtrl_Test {
    @isTest
    static void test_checkTandC(){
        BAMMerchantPortalLoginFlowController bamMPLoginFlowCtrl = new BAMMerchantPortalLoginFlowController();
        System.assertEquals('/', bamMPLoginFlowCtrl.checkTandC().getUrl());
    }

    @isTest
    static void test_submit(){
        BAMMerchantPortalLoginFlowController bamMPLoginFlowCtrl = new BAMMerchantPortalLoginFlowController();
        bamMPLoginFlowCtrl.agreeTsAndCs = false;   
        System.assertEquals(null, bamMPLoginFlowCtrl.submit());
        bamMPLoginFlowCtrl.agreeTsAndCs = true;   
        System.assertEquals('/', bamMPLoginFlowCtrl.submit().getUrl());
    }  

    @isTest
    static void test_acceptConditions(){
        User u = TestDataProvider.createTestUsers();
        insert u;
        System.runAs(u) {
            BAMMerchantPortalLoginFlowController bamMPLoginFlowCtrl = new BAMMerchantPortalLoginFlowController();
            PageReference finishedFlowPageRef = bamMPLoginFlowCtrl.acceptConditions();
        }
        User queriedUser = [SELECT Id, Merchant_Portal_T_C_Last_Accepted__c FROM User WHERE ID =: u.Id];
        System.assertNotEquals(null, queriedUser.Merchant_Portal_T_C_Last_Accepted__c);
    }  
}