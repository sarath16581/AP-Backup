/**
Description: Test class for apex class - APT_AttachFileController.
Created By: Drashtee Shah
Created Date: 19th Feb, 2016
Last Modified By:
Last Modified Date:
*/
@isTest
private class APT_AttachFileController_Test {
    /**
            Creating test data
     */
    private static testMethod void APT_AttachFileController1() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {      
            //Create Account
            Account acc = APT_TestUtils.createOrganisation();
            insert acc;
            
            Folder folder = [SELECT Id FROM Folder where Type = 'Document' LIMIT 1];
            
            Document doc = new Document(FolderId = folder.ID ,Name='mySampleFile', Body = Blob.ValueOf('Hello World'));
            doc.ContentType = 'jpeg';
                 
            Test.StartTest();
            ApexPages.currentPage().getParameters().put('id',acc.ID);
            ApexPages.currentPage().getParameters().put('selectedValue','Name'); 
            ApexPages.currentPage().getParameters().put('obj','Account');
            ApexPages.currentPage().getParameters().put('comboLabel','temp');
            ApexPages.currentPage().getHeaders().put('Host','temp');
            
            APT_AttachFileController afc = new APT_AttachFileController();
            //String temp1 = afc.getExtractName();
            afc.mydoc = doc;
            afc.uploadFile();
            afc.goHome();
            afc.getImage();
            afc.choice = 'temp1';
            afc.folderID = folder.ID;

            Test.StopTest();
            system.assert(afc.folderID != null);
        }
    }
    /**
            Creating test data
     */
    private static testMethod void APT_AttachFileController2() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {     
            Folder folder = [SELECT Id FROM Folder where name = 'images' LIMIT 1];
            Document doc = new Document(FolderId = folder.ID ,Name='mySampleFile', Body = Blob.ValueOf('Hello World'));
            doc.ContentType = 'pdf';
    
            ApexPages.currentPage().getParameters().put('selectedValue','Name'); 
            ApexPages.currentPage().getParameters().put('obj','Account');
            ApexPages.currentPage().getParameters().put('comboLabel','temp');
            ApexPages.currentPage().getHeaders().put('Host','temp');
            Test.StartTest();
            APT_AttachFileController afc = new APT_AttachFileController();
            //String temp1 = afc.getExtractName();
            afc.mydoc = doc;
            afc.uploadFile();
            afc.insertIntoReachTextBox();
            afc.goHome();
            afc.getImage();
            afc.choice = 'temp1';
            afc.folderID = folder.ID;
            
            Test.StopTest();
            system.assert(afc.folderID != null);
        }
    }
    /**
            Creating test data
     */    
    private static testMethod void APT_AttachFileController3() {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User testuser = new User(Alias = APT_Constants.ALIAS_TEST_USER, Email=APT_Constants.EMAIL_TEST_USER,
        EmailEncodingKey=APT_Constants.EMAILENCODINGKEY_TEST_USER, LastName=APT_Constants.LASTNAME_TEST_USER, LanguageLocaleKey=APT_Constants.LANGUAGELOCALEKEY_TEST_USER,
        LocaleSidKey=APT_Constants.LOCALESIDKEY_TEST_USER, ProfileId = p.Id,
        TimeZoneSidKey=APT_Constants.TIMEZONESIDKEY_TEST_USER,
        UserName=APT_Constants.EMAIL_TEST_USER);
        System.runAs(testuser) {    
            Document doc = new Document(FolderId = null ,Name='mySampleFile', Body = Blob.ValueOf('Hello World'));
            
            ApexPages.currentPage().getParameters().put('selectedValue','Name'); 
            ApexPages.currentPage().getParameters().put('obj','Account');
            ApexPages.currentPage().getParameters().put('comboLabel','temp');
            ApexPages.currentPage().getHeaders().put('Host','temp');
            Test.StartTest();
            APT_AttachFileController afc = new APT_AttachFileController();
            afc.mydoc = doc;
            afc.uploadFile();
            afc.folderID = null;
            
            Test.StopTest();
            system.assert(afc.folderID == null);
        }
    }
}