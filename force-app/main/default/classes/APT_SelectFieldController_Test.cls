/**
Description - This class is test class for APT_SelectFieldController.
Created By - Drashtee Shah
Created Date - 3rd Mar, 2016
Last Modified By -
Last Modified Date - 
 */
@isTest
private class APT_SelectFieldController_Test {
    /**
        Creating Test Data
    **/
    private static TestMethod void testMethod1() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {             
            //Create Account
            Account acc = APT_TestUtils.createOrganisation();
            acc.Type = 'Charge Account + Sub Account';
            acc.ACN__c = '123456789';
            acc.BillingCountry = 'Russia';
            acc.ShippingCountry = 'Russia';
            insert acc;
            
            ////create international product
            Product2 bundle1 = APT_TestUtils.createInternationalProduct('International Bundle','APOST001','Postal Services');
            insert bundle1;
            
            PageReference pageRef = Page.APT_SelectField;
            Test.setCurrentPage(pageRef);
           
            Apexpages.currentPage().getParameters().put('Id', bundle1.Id);
            Apexpages.currentPage().getParameters().put('objType', 'Product2');
            
            
            List<SelectOption> options = new List<SelectOption>(); 
            options.add(new SelectOption(APT_WebServiceUtility.ORGANIZATION_NAME, APT_WebServiceUtility.ORGANIZATION_NAME));
            options.add(new SelectOption(APT_WebServiceUtility.ACN,APT_WebServiceUtility.ACN)); 
            options.add(new SelectOption(APT_WebServiceUtility.ABN,APT_WebServiceUtility.ABN)); 
            
            Test.StartTest();
           // ApexPages.StandardController sc = new ApexPages.StandardController(acc);
            APT_SelectFieldController sfc = new APT_SelectFieldController();
            sfc.next();
            sfc.getFieldsForSelectedObject();
            sfc.cancel();
            sfc.sortSelectOptions(options);
            
            Test.StopTest();
             system.assert(pageRef!=null);
        }
    }
    /**
        Creating Test Data
    **/
    private static TestMethod void testMethod2() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {   
            APT_SelectFieldController sfc = new APT_SelectFieldController();
            sfc.next();
            sfc.getFieldsForSelectedObject();
        }
    }
    
}