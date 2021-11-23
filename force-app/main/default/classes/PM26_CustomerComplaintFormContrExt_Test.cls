/**
  * @author       : kalpita.talwadekar@auspost.com.au
  * @date         : 20/05/2016
  * @description  : Test class for generating PM26 form
  */
/*******************************  History ************************************************
    Date                User                                        Comments
    04.06.18     kalpita.talwadekar@auspost.com.au            updated code for test class failure fix and coding standards TDO
    15.03.2019    Swati.mogadala@auspost.com.au               Added custom setting data to append username when user is created INC1300632
    
    
*******************************  History ************************************************/
@isTest
private class PM26_CustomerComplaintFormContrExt_Test {

    // Constants
    private static final String ADMIN_PROFILE = 'System Administrator';
    private static final String SSSW_MYNETWORK_PROFILE = 'MyNetwork Portal';
    private static final Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_MYNETWORK_PROFILE LIMIT 1];
    
    @testSetup 
    static void testDateCreation() {
        
        String recTypeId = [Select Id from RecordType where Name='Consumer' and SobjectType='Account' limit 1].Id;
        
        //insert person account with APCN
        Account accPerson1 = TestUtility.createPersonAccount('Dave',recTypeId);
        accPerson1.FirstName ='John';
        accPerson1.PersonEmail = 'test@abc.com';
        accPerson1.Phone ='2132456';
        accPerson1.APCN__pc = 'abcd11234';
        insert accPerson1;
        Contact con = TestUtility.createContact('John','Don','test@abc.com',null);
        con.MailingStreet = 'test';
        con.MailingStreet2__c = 'test';
        con.MailingCity= 'test';
        con.MailingState = 'test';
        con.MailingCountry = 'test';
        con.MailingPostalCode = 'test';
        con.APCN__c = 'abcd1234';
        insert con;
        
        //insert article with Account's APCN
        Article__c testArticle1 = new Article__c();
        testArticle1.Name = 'testArticle1';
        testArticle1.ArticleID__c = 'testArticle1';
        testArticle1.ArticleLodgementDate__c = Date.today();
        testArticle1.SenderPostcode__c = '3000';
        testArticle1.ReceiverPostcode__c = '3006';
        testArticle1.ArticleType__c = 'Regular Parcel';
        testArticle1.Receiver_APCN__c = 'abcd1234';
        insert testArticle1;
        
        //insert network
        Network__c nw = TestDataProvider.createTestNetwork();
        nw.Email__c = 'top@top.com';
        nw.Name = 'test network';
        nw.Post_Code__c = '3000';
        nw.Geolocation__Latitude__s = 31;
        nw.Geolocation__Longitude__s = 121;
        nw.Portal_Licenses__c = 99;
        insert nw;
        
        //insert network user
        insert new User__c(Org__c = '@MyNetwork.Ptest');  // insert custom setting data for User__c INC1300632
        Facility_User__c nwUser = new Facility_User__c(Network__c=nw.Id, Timezone__c='Western Australia',  Is_MyNetwork_User__c = true, 
                                            Email_Address__c='test@test.com',User_Role__c='MyNetwork User',First_Name__c='testU',Last_Name__c='testLU' );                                   
        insert nwUser;
        
        //insert network user
        Facility_User__c testFacUser = new Facility_User__c(Network__c=nw.Id, Timezone__c='Western Australia',  Is_MyNetwork_User__c = true,  
                                            Email_Address__c='teessst@test111.com',User_Role__c='MyNetwork User',First_Name__c='testU2',Last_Name__c='testLU2');
        insert testFacUser; 
    }
    
    /**********************************************************************
     *  Scenario:
     *      Method to test the PM26 form and page initialization
     **********************************************************************/
    @isTest
    static void PM26_TestCustomComplaint_initializeProdSubCat() {
        Case cse = TestDataProvider.createCase();
        database.insert(cse);
        //insert case comment
        CaseComment newCom = new CaseComment();
        newCom.CommentBody = 'test body' ;
        newCom.IsPublished = TRUE;
        newCom.ParentId = cse.id;
        Database.saveResult sr1 = database.insert(newCom);

        Case cid = [Select Id from Case limit 1];
        test.startTest();
            ApexPages.StandardController stdCont = new ApexPages.StandardController(cId);
            PM26_CustomerComplaintFormContrExt ext = new PM26_CustomerComplaintFormContrExt(stdCont);
        test.stopTest();
    }
    
     /**********************************************************************
     *  Scenario:
     *      Method to test the PM26 form and case creation with necessary validations
     **********************************************************************/
    @isTest
    static void PM26_TestCustomComplaintCaseCreate() {
        
        Account accPerson1 = [Select Id from Account limit 1];
        
        Network__c nw = [Select id from Network__c limit 1];
        
        Article__c testArticle1 = [Select Id from Article__c limit 1];
        
        Case cse = new Case();
        
        System.runAs(new User(Id = UserInfo.getUserId()))  {
            test.startTest();
                
                ApexPages.StandardController stdCont = new ApexPages.StandardController(cse);
                PM26_CustomerComplaintFormContrExt pm26ControllerStdCont = new PM26_CustomerComplaintFormContrExt(stdCont);
                PM26_CustomerComplaintFormContrExt pm26ControllerNoStd = new PM26_CustomerComplaintFormContrExt();
                
                pm26ControllerStdCont.getNetworks();
                pm26ControllerStdCont.getDamageType();
                pm26ControllerStdCont.getProdCat();
                pm26ControllerStdCont.field = 'Domestic Parcels';
                pm26ControllerStdCont.initializeProdSubCat();
                pm26ControllerStdCont.trackId = 'testArticle1';
                pm26ControllerStdCont.getArticleDetails();
                pm26ControllerStdCont.pm26Case.AccountId = accPerson1.Id; 
                pm26ControllerStdCont.pm26Case.Subject = 'Newsdd';
                pm26ControllerStdCont.pm26Case.ReferenceId__c = 'testArticle1';
                pm26ControllerStdCont.pm26Case.type = 'Investigation';
                pm26ControllerStdCont.pm26Case.ArticleTest__c = testArticle1.Id;
                pm26ControllerStdCont.getComplaintTypes();
                pm26ControllerStdCont.complaintType = 'PM26';
                pm26ControllerStdCont.getNoTrackInfo();
                pm26ControllerStdCont.pm26Case.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('SSSW Delivery').getRecordTypeId();
                pm26ControllerStdCont.pm26Case.isNewForRouting__c = true;
                pm26ControllerStdCont.pm26Case.Subscribe__c = true;
                pm26ControllerStdCont.pm26Case.Origin = 'AP Retails(PM26)';
                pm26ControllerStdCont.pm26Case.EnquirySubType__c   = 'Damaged/Missing contents';
                pm26ControllerStdCont.pm26Case.CaseDetails__c = 'test' ;
                pm26ControllerStdCont.pm26Case.Network__c = nw.Id;
                pm26ControllerStdCont.pm26Case.SecondaryEmail__c = 'testsec@abc.com';
                pm26ControllerStdCont.pm26Case.ProductCategory__c = 'Domestic Parcels';
                pm26ControllerStdCont.trackId = 'testArticle1';
                pm26ControllerStdCont.pm26Case.ProductSubCategory__c = 'ECI';
                pm26ControllerStdCont.enableFields();
                pm26ControllerStdCont.createCase();
                pm26ControllerStdCont.pm26Case.TypeofDamage__c = 'Contents - not repairable';
                 pm26ControllerStdCont.adqPck= 'YES';
                 pm26ControllerStdCont.createCase();
                         
            test.stopTest();
        }
    }
    
    
    /**********************************************************************
     *  Scenario:
     *      Method to test the PM26 form with compensation use case 
     **********************************************************************/
    @isTest
    static void PM26_TestCustomComplaint_Compensation() {
        Network__c nw = [Select Id from Network__c limit 1];
        Case cse = TestDataProvider.createCase();
        database.insert(cse);
        //insert case comment
        CaseComment newCom = new CaseComment();
        newCom.CommentBody = 'test body' ;
        newCom.IsPublished = TRUE;
        newCom.ParentId = cse.id;
        Database.saveResult sr1 = database.insert(newCom);

        Case cid = [Select Id from Case limit 1];
        test.startTest();
            ApexPages.StandardController stdCont = new ApexPages.StandardController(cId);
            PM26_CustomerComplaintFormContrExt ext = new PM26_CustomerComplaintFormContrExt(stdCont);
            ext.checkComp();
            ext.complaintType = 'Other';
            ext.getProdCat();
            ext.field = 'Domestic Letters';
            ext.pm26Case.ProductCategory__c = 'Domestic Letters';
            ext.pm26Case.ProductSubCategory__c = 'Cash on Delivery';
            //ext.initializeProdSubCat();
            ext.enableFields();
            ext.noTrackId = true;
            ext.pm26Case.TypeofDamage__c = 'Test';
            ext.adqPck = 'yes';
            ext.pm26Case.Phone__c = '467';
            ext.pm26Case.SecondaryEmail__c = 'test@test.com';
            ext.createCase();
            ext.pm26Case.Phone__c = '0392064326';
            ext.pm26Case.Address2PostCode__c = '4';
            ext.createCase();
            ext.pm26Case.Address2PostCode__c = '3004';
            ext.renderForm();
            ext.compnsation = true;
            ext.compensationValue = 'ab';
            ext.createCase();
            ext.compensationValue = '12';
            ext.createCase();
            ext.pm26Case.Phone__c = null;
            ext.pm26Case.SecondaryContactFirstName__c = 'FName';
            ext.pm26Case.SecondaryContactLastName__c = 'LName';            
            ext.pm26Case.Address2Line1__c = 'Add';            
            ext.pm26Case.Address2State__c = 'Add';                        
            ext.pm26Case.Address2Suburb__c = 'Add'; 
            ext.pm26Case.Address2PostCode__c = '2000'; 
            ext.pm26Case.Address2Country__c = 'Add'; 
            ext.pm26Case.Network__c = nw.Id;
            ext.pm26Case.EnquirySubType__c = 'Missing item';
            ext.pm26Case.Description = 'Missing item';
            ext.createCase();
        test.stopTest();
        
    }
    
    /**********************************************************************
     *  Scenario:
     *      Method to test the PM26 form with compensation use case for MW0002314
     **********************************************************************/
    @isTest
    static void PM26_TestCustomComplaint_ValidationErrors() {
        Case cse = new Case();
        
        System.runAs(new User(Id = UserInfo.getUserId()))  {
            test.startTest();
                Boolean t;
                ApexPages.StandardController stdCont = new ApexPages.StandardController(cse);
                PM26_CustomerComplaintFormContrExt pm26ControllerStdCont = new PM26_CustomerComplaintFormContrExt(stdCont);
                PM26_CustomerComplaintFormContrExt pm26ControllerNoStd = new PM26_CustomerComplaintFormContrExt();
                pm26ControllerStdCont.complaintType = 'PM26';
                t = pm26ControllerStdCont.noArticle;
                t = pm26ControllerStdCont.evidence;
                t = pm26ControllerStdCont.noevidence;
                t = pm26ControllerStdCont.yesInt;
                t = pm26ControllerStdCont.nocompnsation;
                t = pm26ControllerStdCont.yescompnsation;
                pm26ControllerStdCont.field2 = '';
                pm26ControllerStdCont.createCase();
                pm26ControllerStdCont.field2 = 'Packaging only';
                pm26ControllerStdCont.createCase();
                pm26ControllerStdCont.pm26Case.ReferenceId__c = 'testRef';
                pm26ControllerStdCont.createCase();
                pm26ControllerStdCont.pm26Case.SecondaryEmail__c = 'tets@tst.com';
                pm26ControllerStdCont.compensationValue = '100';
                pm26ControllerStdCont.createCase();
                pm26ControllerStdCont.trackId = 'testBlah';
                pm26ControllerStdCont.getArticleDetails();
            
            test.stopTest();
            
        }           
    
    }
}