/**
 * @author       : kalpita.talwadekar@auspost.com.au
 * @date         : 20/05/2016
 * @description  : Test class for myNetwork portal landing page
 */
/*******************************  History ************************************************
 Date                User                                        Comments
 23.02.18     kalpita.talwadekar@auspost.com.au            updated code for test class for accommodating new enhancements
 04.06.18    kalpita.talwadekar@auspost.com.au            updated code for test class failure fix and coding standards TDO-201
 2018-11-27    nathan.franklin@auspost.com.au            Adding new test method to test visualforce array chunking
 2019-11-26 gunith.devasurendra@auspost.com.au REQ1982330/REQ1962663 - Order by Priority and highlight High priority ones
 2022-03-16 saiswetha.pingali@auspost.com.au Added custom settings to disable triggers on case object to fix soql error.
 *******************************  History ************************************************/
@isTest
private class SSSW_MyNetworkLandingContr_Test{

    // Constants
    private static final String ADMIN_PROFILE = 'System Administrator';
    private static final String SSSW_MYNETWORK_PROFILE = 'MyNetwork Portal';
    private static final Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_MYNETWORK_PROFILE LIMIT 1];

    @testSetup
    static void testDateCreation() {

        //insert standard entitlement
        Account at = new Account(Name=SSSWConstants.ENTITLEMENT_ACC);
        insert at;
        Entitlement ent = new Entitlement(AccountId = at.Id, Name='Standard Entitlement');
        insert ent;

        String oId = [Select Id,Name from Group where Name='SSSW Network Queue' and type = 'Queue' limit 1].Id;

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
        nw.Contact_Facility__c ='MyNetwork';
        insert nw;

        //insert Account
        Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
        Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                accRecTypeMap.get('Organisation').getRecordTypeId());
        Database.insert(acc);

        //insert contact
        Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
        con.Email = 'bruce@wayne.com';
        Database.insert(con);

        //insert Case
        Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
        Case csRec = TestUtility.createCase('Enquiry','In Progress','Investigation',acc.Id,con.Id,
                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
        csRec.ArticleTest__c = testArticle1.Id;
        csRec.Status = 'Awaiting Network Response';
        csRec.Network__c = nw.id;
        csRec.Type = 'Investigation';
        csRec.CaseOriginator__c = 'Addressee';
        csRec.Checkbox__c = true;
        csRec.OwnerId = [Select Id,Name from Group where Name='SSSW Network Queue' and type = 'Queue' limit 1].Id;
        Database.insert(csRec);

    }

    /**********************************************************************
     *  Scenario:
     *      Method to initialize the landing screen of myNetwork with investigation case and select specific case
     **********************************************************************/
    @isTest
    static void MyNetworkLanding_initializeInvestigation() {

        Case cse = [Select Id,Status,OwnerId, Owner.Name, type from Case limit 1];//Disputed delivery scan case
        system.debug(cse.OwnerId + cse.Owner.Name + cse.Type  +cse.Id );
        system.runAs(new User(Id = UserInfo.getUserId())) {
            test.startTest();
                CaseTeamMember ctm = new CaseTeamMember(ParentId = cse.id,MemberId = userinfo.getuserid(),TeamRoleId = '0B790000000TNg8');
                database.insert(ctm);
                ApexPages.StandardController stdCon = new ApexPages.StandardController(cse);
                SSSW_MyNetworkLandingContr ctr = new SSSW_MyNetworkLandingContr ();
                ctr.initialize();
                ctr.respondtoCase();
            test.stopTest();
            System.assertEquals(cse.Id,ctr.caseList[0].values()[0].Id,
                    'SSSW_MyNetworkLandingContr_Test_MyNetworkLanding_initializeInvestigation : Test case is picked to display in landing page.');
        }
    }

    /**********************************************************************
     *  Scenario:
     *      Method to initialize the landing screen of myNetwork with feedback case and select specific case
     **********************************************************************/
    @isTest
    static void MyNetworkLanding_initializeFeedback() {

        Case cse = [Select Id,Status,OwnerId, Owner.Name, type from Case limit 1];//Disputed delivery scan case
        cse.Type = 'Feedback';
        cse.ResolutionCode__c = 'Closed';
        cse.status = 'Closed';
        database.update(cse);
        system.debug(cse.OwnerId + cse.Owner.Name + cse.Type  +cse.Id );
        system.runAs(new User(Id = UserInfo.getUserId())) {
            test.startTest();
                CaseTeamMember ctm = new CaseTeamMember(ParentId = cse.id,MemberId = userinfo.getuserid(),TeamRoleId = '0B790000000TNg8');
                database.insert(ctm);

                ApexPages.StandardController stdCon = new ApexPages.StandardController(cse);
                SSSW_MyNetworkLandingContr ctr = new SSSW_MyNetworkLandingContr ();
                ctr.initialize();
                ctr.respondtoCase();
            test.stopTest();
            System.assertEquals(cse.Id,ctr.caseList[0].values()[0].Id,
                    'SSSW_MyNetworkLandingContr_Test_MyNetworkLanding_initializeFeedback : Test case is picked to display in landing page.');
        }
    }

    /**********************************************************************
     *  Scenario:
     *      Method to initialize the landing screen of myNetwork with updated type of case and select specific case
     **********************************************************************/
    @isTest
    static void MyNetworkLanding_updatedUseCase() {


        Case cse = [Select Id,Status,OwnerId, Owner.Name, type from Case limit 1];//Disputed delivery scan case
        cse.Root_Cause__c = 'Awaiting Network Response';
        cse.OwnerId = UserInfo.getUserId();
        Database.update(cse);
        system.debug(cse.OwnerId + cse.Owner.Name + cse.Type  +cse.Id );
        system.runAs(new User(Id = UserInfo.getUserId())) {

            CaseTeamMember ctm = new CaseTeamMember(ParentId = cse.id,MemberId = userinfo.getuserid(),TeamRoleId = '0B790000000TNg8');
            database.insert(ctm);
            test.startTest();
                ApexPages.StandardController stdCon = new ApexPages.StandardController(cse );
                SSSW_MyNetworkLandingContr ctr2 = new SSSW_MyNetworkLandingContr (stdCon);
                SSSW_MyNetworkLandingContr ctr = new SSSW_MyNetworkLandingContr ();
                ctr.initialize();
                ctr.cseId = cse.Id;
                ctr.respondtoCase();
            test.stopTest();
            System.assertEquals(cse.Id,ctr.caseList[0].values()[0].Id,
                    'SSSW_MyNetworkLandingContr_Test_MyNetworkLanding_updatedUseCase : Test case is picked to display in landing page.');
        }
    }

    /**********************************************************************
     *  Scenario:
     *      Method to initialize the landing screen of myNetwork with still under investigation case
     **********************************************************************/
    @isTest
    static void MyNetworkLanding_SUIFeeback() {

        Case cse = [Select Id,Status,OwnerId, Owner.Name, type from Case limit 1];//Disputed delivery scan case
        cse.Type = 'Feedback';
        cse.CaseOriginator__c = 'Addressee';
        cse.status = 'Closed';
        cse.ResolutionCode__c = 'Closed';
        cse.Root_Cause__c = 'Awaiting Network Response';
        cse.OwnerId = [Select Id,Name from Group where Name='SSSW Network Queue' and type = 'Queue' limit 1].Id;
        Database.update(cse);
        system.debug(cse.OwnerId + cse.Owner.Name + cse.Type  +cse.Id );
        system.runAs(new User(Id = UserInfo.getUserId())) {

            CaseTeamMember ctm = new CaseTeamMember(ParentId = cse.id,MemberId = userinfo.getuserid(),TeamRoleId = '0B790000000TNg8');
            database.insert(ctm);
            Network_Response__c nR = new Network_Response__c(Request_Hold_Case__c = true, RelatedCase__c=cse.Id);
            database.insert(nR);
            test.startTest();
                ApexPages.StandardController stdCon = new ApexPages.StandardController(cse);
                SSSW_MyNetworkLandingContr ctr = new SSSW_MyNetworkLandingContr ();
                ctr.initialize();
                ctr.respondtoCase();
            test.stopTest();
            System.assertEquals(cse.Id,ctr.caseList[0].values()[0].Id,
                    'SSSW_MyNetworkLandingContr_Test_MyNetworkLanding_SUIFeeback : Test case is picked to display in landing page.');
        }
    }

    /**********************************************************************
     *  Scenario:
     *      Method to initialize the landing screen of myNetwork with existing network response which is sent to CCC
     **********************************************************************/
    @isTest
    static void MyNetworkLanding_SUIInvestigation() {

        Case cse = [Select Id,Status,OwnerId, Owner.Name, type from Case limit 1];//Disputed delivery scan case
        system.debug(cse.OwnerId + cse.Owner.Name + cse.Type  +cse.Id );
        system.runAs(new User(Id = UserInfo.getUserId())) {

            CaseTeamMember ctm = new CaseTeamMember(ParentId = cse.id,MemberId = userinfo.getuserid(),TeamRoleId = '0B790000000TNg8');
            database.insert(ctm);
            Network_Response__c nR = new Network_Response__c(Request_Hold_Case__c = true, RelatedCase__c=cse.Id);
            database.insert(nR);
            test.startTest();
                ApexPages.StandardController stdCon = new ApexPages.StandardController(cse);
                SSSW_MyNetworkLandingContr ctr = new SSSW_MyNetworkLandingContr ();
                ctr.initialize();
                ctr.respondtoCase();
            test.stopTest();
            System.assertEquals(cse.Id,ctr.caseList[0].values()[0].Id,
                    'SSSW_MyNetworkLandingContr_Test_MyNetworkLanding_SUIInvestigation : Test case is picked to display in landing page.');
        }
    }


    /**********************************************************************
     *  Scenario:
     *      Method to initialize the landing screen of myNetwork with existing network response which is sent back to CCC
     **********************************************************************/
    @isTest
    static void MyNetworkLanding_CCC2() {

        Case cse = [Select Id,Status,OwnerId, Owner.Name, type from Case limit 1];//Disputed delivery scan case
        system.debug(cse.OwnerId + cse.Owner.Name + cse.Type  +cse.Id );
        system.runAs(new User(Id = UserInfo.getUserId())) {

            CaseTeamMember ctm = new CaseTeamMember(ParentId = cse.id,MemberId = userinfo.getuserid(),TeamRoleId = '0B790000000TNg8');
            database.insert(ctm);

            Network_Response__c nR = new Network_Response__c(to_CCC_action__c = true, RelatedCase__c=cse.Id);
            database.insert(nR);

            test.startTest();
                ApexPages.StandardController stdCon = new ApexPages.StandardController(cse);
                SSSW_MyNetworkLandingContr ctr = new SSSW_MyNetworkLandingContr ();
                ctr.initialize();
                ctr.respondtoCase();
            test.stopTest();
            System.assertEquals(cse.Id,ctr.caseList[0].values()[0].Id,
                    'SSSW_MyNetworkLandingContr_Test_MyNetworkLanding_CCC2 : Test case is picked to display in landing page.');
        }
    }

    /**********************************************************************
     *  Scenario:
     *      Method to initialize the landing screen of myNetwork with Feedback type closed case with updated use - case
     **********************************************************************/
    @isTest
    static void MyNetworkLanding_FeedbackUpdated() {

        Case cse = [Select Id,Status,OwnerId, Owner.Name, type from Case limit 1];//Disputed delivery scan case
        cse.Status = 'Closed';
        cse.ResolutionCode__c = 'Closed';
        cse.Type = 'Feedback';
        cse.CaseOriginator__c = 'Addressee';
        cse.ResolutionCode__c = 'with network';
        cse.Root_Cause__c = 'Awaiting Network Response';
        cse.OwnerId = UserInfo.getUserId();
        Database.update(cse);
        system.debug(cse.OwnerId + cse.Owner.Name + cse.Type  +cse.Id );
        system.runAs(new User(Id = UserInfo.getUserId())) {

            CaseTeamMember ctm = new CaseTeamMember(ParentId = cse.id,MemberId = userinfo.getuserid(),TeamRoleId = '0B790000000TNg8');
            database.insert(ctm);

            test.startTest();
                ApexPages.StandardController stdCon = new ApexPages.StandardController(cse );
                SSSW_MyNetworkLandingContr ctr2 = new SSSW_MyNetworkLandingContr (stdCon);
                SSSW_MyNetworkLandingContr ctr = new SSSW_MyNetworkLandingContr ();
                ctr.initialize();
                ctr.cseId = cse.Id;
                ctr.respondtoCase();
            test.stopTest();
            System.assertEquals(cse.Id,ctr.caseList[0].values()[0].Id,
                    'SSSW_MyNetworkLandingContr_Test_MyNetworkLanding_FeedbackUpdated : Test case is picked to display in landing page.');
        }
    }

    /**********************************************************************
     *  Scenario:
     *      Method to initialize the landing screen of myNetwork with printed cases
     **********************************************************************/
    @isTest
    static void MyNetworkLanding_CasePrint() {

        Case cse = [Select Id, Checkbox__c from Case where Type='Investigation' limit 1];

        test.startTest();
            PageReference PageRef = Page.PON_Case_Detail_View;
            Test.setCurrentPage(PageRef);
            ApexPages.currentPage().getParameters().put('ID', cse.Id);
            ApexPages.StandardController stdCon = new ApexPages.StandardController(cse );
            PON_CaseDetailViewCtrl ctr = new PON_CaseDetailViewCtrl (stdCon);
            ctr.updatePrintFlag();
            SSSW_MyNetworkLandingContr ctr2 = new SSSW_MyNetworkLandingContr ();
        test.stopTest();
        Case cse2 = [Select Id, Checkbox__c from Case where Type='Investigation' limit 1];
        System.assertEquals(true,cse2.Checkbox__c,
                'SSSW_MyNetworkLandingContr_Test_MyNetworkLanding_CasePrint : Test case has the print flag - Checkbox ticked.');

    }

    /**********************************************************************
    *  Scenario:
    *      Testing the way Apex Controller splits cases up into List<> chunks for visualforce (to overcome limitation of 1000 in collection)
    **********************************************************************/
    @isTest
    static void MyNetworkLanding_testCaseArrayChunk() {

        SystemSwitch__c settings = SystemSwitch__c.getInstance();
        settings.DisableTriggers__c = true;
        settings.ObjectTriggersToBeDisabled__c = 'Case';
        upsert settings;

        Account acc = [Select Id From Account LIMIT 1];
        Contact con = [Select Id From Contact LIMIT 1];
        Network__c nw = [Select Id From Network__c LIMIT 1];
        Article__c testArticle1 = [Select Id From Article__c LIMIT 1];

        //insert additional Case for test
        Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
        Case csRec = TestUtility.createCase('Enquiry','In Progress','Investigation',acc.Id,con.Id,
                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
        csRec.ArticleTest__c = testArticle1.Id;
        csRec.Status = 'Awaiting Network Response';
        csRec.Network__c = nw.id;
        csRec.Type = 'Investigation';
        csRec.CaseOriginator__c = 'Addressee';
        csRec.Checkbox__c = true;
        csRec.OwnerId = [Select Id,Name from Group where Name='SSSW Network Queue' and type = 'Queue' limit 1].Id;
        Database.insert(csRec);

        List<Case> cases = [Select Id,Status,OwnerId, Owner.Name, type from Case limit 2];//Disputed delivery scan case

        system.runAs(new User(Id = UserInfo.getUserId())) {
            test.startTest();

            List<CaseTeamMember> ctm = new List<CaseTeamMember>{
                    new CaseTeamMember(ParentId = cases[0].id,MemberId = userinfo.getuserid(),TeamRoleId = '0B790000000TNg8'),
                    new CaseTeamMember(ParentId = cases[1].id,MemberId = userinfo.getuserid(),TeamRoleId = '0B790000000TNg8')
            };
            database.insert(ctm);

            // set chunk size
            SSSW_MyNetworkLandingContr.ARRAY_CHUNK_SIZE = 1;

            SSSW_MyNetworkLandingContr ctr = new SSSW_MyNetworkLandingContr ();
            ctr.initialize();
            ctr.respondtoCase();
            test.stopTest();
            System.assertEquals(2,ctr.caseList.size(),
                    'SSSW_MyNetworkLandingContr_Test_MyNetworkLanding_initializeInvestigation : Case list size is not 2.');
        }
    }

    @IsTest
    static void caseWrapperSorting(){
        Datetime now = Datetime.now();

        SSSW_MyNetworkLandingContr.CaseWrapper[] caseWrappers = new SSSW_MyNetworkLandingContr.CaseWrapper[0];

        SSSW_MyNetworkLandingContr.CaseWrapper caseMed = new SSSW_MyNetworkLandingContr.CaseWrapper(new Case(Priority='Medium', LastModifiedDate= now));
        caseWrappers.add(caseMed);

        SSSW_MyNetworkLandingContr.CaseWrapper caseHigh = new SSSW_MyNetworkLandingContr.CaseWrapper(new Case(Priority='High', LastModifiedDate= now));
        caseWrappers.add(caseHigh);

        SSSW_MyNetworkLandingContr.CaseWrapper caseLow = new SSSW_MyNetworkLandingContr.CaseWrapper(new Case(Priority='Low', LastModifiedDate= now));
        caseWrappers.add(caseLow);

        caseWrappers.sort();

        System.assertEquals(caseWrappers.get(0), caseHigh);
        System.assertEquals(caseWrappers.get(1), caseMed);
        System.assertEquals(caseWrappers.get(2), caseLow);
    }
}