@isTest
private class APT_CreateCaseController_Test{
    public static testMethod void testingAPT_CreateCaseController() {
        Account tempacct = APT_TestUtils.createOrganisation();
        tempacct.Legacy_Id__c = '60000000';
        insert tempacct;
        Contact con = APT_TestUtils.createContact();
        insert con;
        User u = [SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c from User where Profile.Name =: 'System Administrator' limit 1];
        Apttus__APTS_Agreement__c aptContract = APT_TestUtils.createAgreement(con.Id);
        insert aptContract;
        aptContract.Ownerid=u.id;
        update aptContract;
        Case cse = APT_TestUtils.createCase(con.Id,aptContract.Id);
        System.assertNotEquals(cse,null);
        ApexPages.currentPage().getParameters().put('selectedCategory','High');
        ApexPages.currentPage().getParameters().put('agreementId',aptContract.Id);
        APT_CreateCaseController createCase = new APT_CreateCaseController();
        Test.StartTest();
        createCase.doSave();
        PageReference pgRef = createCase.doCancel();
        system.assert(pgRef != null);
        Test.StopTest();
    }
    public static testMethod void testingAPT_CreateCaseControllerNegative() {
        APT_CreateCaseController createCase = new APT_CreateCaseController();
        Test.StartTest();
        createCase.doSave();
        PageReference pgRef = createCase.doCancel();
        system.assert(pgRef == null);
        Test.StopTest();
    }
}