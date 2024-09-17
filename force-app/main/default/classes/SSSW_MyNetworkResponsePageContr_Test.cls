/**
 * @author       : kalpita.talwadekar@auspost.com.au
 * @date         : 20/05/2016
 * @description  : Test class for Testing scenarios on MYNetwork Response capture
 */
/*******************************  History ************************************************
 Date                User                                        Comments
 23.02.18     kalpita.talwadekar@auspost.com.au            updated code for test class for accommodating new enhancements
 04.06.18     kalpita.talwadekar@auspost.com.au            updated code for test class failure fix and coding standards TDO - 203
2019-04-26 - Swati.mogadala@auspost.com.au  - Update 'Message to network' from the case description field as per REQ1760281
2023-07-18 - Nathan Franklin - Update failing test method - a bit of dodgy fix (testNwResp_sendbckCCC) - Move test.starttest()
2024-08-28 mona.raghav@auspost.com.au - mehtod testTrimEscalationEmailContent added to test trimming of the string

 *******************************  History ************************************************/
@isTest
private class SSSW_MyNetworkResponsePageContr_Test{

    // Constants
    private static final String ADMIN_PROFILE = 'System Administrator';
    private static final String SSSW_MYNETWORK_PROFILE = 'MyNetwork Portal';
    private static final Profile prof = [SELECT Id,Name 
                                        FROM 
                                            Profile 
                                        where 
                                            Name =: SSSW_MYNETWORK_PROFILE 
                                        LIMIT 1];


    @testSetup
    static void setupTestData() {
        //insert test article with Account's APCN
        Article__c testArticle1 = new Article__c();
        testArticle1.Name = 'testArticle1';
        testArticle1.ArticleID__c = 'testArticle1';
        testArticle1.ArticleLodgementDate__c = Date.today();
        testArticle1.SenderPostcode__c = '3000';
        testArticle1.ReceiverPostcode__c = '3006';
        testArticle1.ArticleType__c = 'Regular Parcel';
        testArticle1.Receiver_APCN__c = 'abcd1234';
        insert testArticle1;

        //insert test network
        Network__c nw = TestDataProvider.createTestNetwork();
        nw.Email__c = 'top@top.com';
        nw.Name = 'test network';
        nw.Post_Code__c = '3000';
        nw.Geolocation__Latitude__s = 31;
        nw.Geolocation__Longitude__s = 121;
        nw.Contact_Facility__c ='MyNetwork';
        insert nw;

        //insert test account record
        Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
        Account acc = TestUtility.createBusinessAccount('Wayne Enterprises',
                accRecTypeMap.get('Organisation').getRecordTypeId());
        Database.insert(acc);

        //insert test contact
        Contact con = TestUtility.createContact('Bruce','Wayne','bruce@wayne.com',acc.id);
        con.Email = 'bruce@wayne.com';
        Database.insert(con);

        //insert test case of Disputed Delivery Scan enquirySubType
        Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
        Case csRec = TestUtility.createCase('Enquiry','In Progress','Investigation',acc.Id,con.Id,
                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
        csRec.ArticleTest__c = testArticle1.Id;
        csRec.Status = 'Awaiting Network Response';
        csRec.Network__c = nw.id;
        csRec.CaseOriginator__c = 'Addressee';
        csRec.EnquirySubType__c = 'Disputed delivery scan';
        csRec.Description = 'Test message to Network1';//REQ1760281
        Database.insert(csRec);

        //insert custom setting data
        List<PON_Update_EmailTemplates__c> pmsList = new List<PON_Update_EmailTemplates__c>();
        PON_Update_EmailTemplates__c pms1 = new PON_Update_EmailTemplates__c(Name='1',CaseCondition__c='ResidentialCannot RecallFront Door',Template_API_Name__c='TestTemplate');
        PON_Update_EmailTemplates__c pms2 = new PON_Update_EmailTemplates__c(Name='2',Enquiry_Sub_Type__c='Disputed delivery scan',Field_Set_Name__c='Disputed_Delivery');
        pmsList.add(pms1);pmsList.add(pms2);
        database.insert(pmsList);

    }

    /**********************************************************************
     *  Scenario:
     *      Checking for the network response screen initialization and on hold response creation
     **********************************************************************/
    private static testMethod void testNwRespInitialize() {

        //insert template
        Folder fld = [Select Id 
                    from 
                        Folder 
                    where 
                        DeveloperName='SSSW_PON_Network_Templates' 
                    limit 1];
        EmailTemplate em = new EmailTemplate(DeveloperName='TestTemplate',SUbject='Test',Body='here we are',Name='TestTemplate',
                FolderId=fld.Id,TemplateType='Text',HTMLValue='text');
        insert em;
        //query case
        Case cse = [Select Id from Case limit 1];//Disputed delivery scan case

        test.startTest();
            //set standard page controller and initialize class constroller
            ApexPages.StandardController stdCon = new ApexPages.StandardController(cse);
            SSSW_MyNetworkResponsePageContr contr = new SSSW_MyNetworkResponsePageContr (stdCon);
            contr.initialize();
            //set class variables
            contr.nResp.Address_Type__c = 'Residential';
            contr.nResp.Delivery_officer_knowledge__c = 'Cannot Recall';
            contr.setDeliveryOptions();
            contr.nresp.More_Delivery_Information__c = 'Front Door';
            contr.nResp.Network_Comments__c = 'Standard Response';
            contr.nResp.Request_Hold_Case__c = true;
            String thread = contr.makeThreadId();
            contr.showEmailTemplate();
        test.stopTest();
        try {
            //qeury to see if network response is created
            Network_Response__c nr = [Select id 
                                     from 
                                        Network_Response__c  
                                     where 
                                        RelatedCase__c= :cse.Id 
                                     order by 
                                        createdDate desc
                                     limit 1];
        } catch(Exception exp) {
            System.assertEquals('List has no rows for assignment to SObject',exp.getMessage(),
                    'SSSW_MyNetworkResponsePageContr_Test_testNwResp_ClosedCaseAcknowledge : Network Response record is not created for the test case.');
        }
    }

    /**********************************************************************
     *  Scenario:
     *      Checking for existing onhold response on the network response screen email template population - positive test
     **********************************************************************/
    private static testMethod void testExistNwResp_onHold() {
        
        Case cse;
        
        cse = [Select Id from Case limit 1]; //Disputed delivery scan case
        
        //insert existing on hold network response
        Network_Response__c nresp = new Network_Response__c();
        nresp.Address_Type__c = 'Residential';
        nResp.Delivery_officer_knowledge__c = 'Cannot Recall';
        nResp.Network_Comments__c = 'Standard Response';
        nResp.RelatedCase__c = cse.Id;
        nResp.RelatedCase__c = cse.Id;
        nresp.Request_Hold_Case__c = true;
        nResp.CaseAction__c = 'On Hold';
        database.insert(nResp);

        test.startTest();
            //set standard page controller and initialize class constroller
            ApexPages.StandardController stdCon = new ApexPages.StandardController(cse);
            SSSW_MyNetworkResponsePageContr contr = new SSSW_MyNetworkResponsePageContr (stdCon);
            contr.initialize();
            contr.setDeliveryOptions();
            contr.nresp.More_Delivery_Information__c = 'Front Door';
            contr.nresp.Request_Hold_Case__c = false;
        
            contr.showEmailTemplate();
        test.stopTest();
        //qeury to see if network response is created
        Network_Response__c nr = [Select id, Request_Hold_Case__c 
                                 from 
                                    Network_Response__c  
                                 where 
                                    RelatedCase__c= :cse.Id 
                                 order by 
                                    createdDate desc
                                 limit 1];
        System.assertNotEquals(null,nr,
                'SSSW_MyNetworkResponsePageContr_Test_testExistNwResp_onHold : Network Response record is created for the test case.');
        System.assertNotEquals(false,nr.Request_Hold_Case__c,
                'SSSW_MyNetworkResponsePageContr_Test_testExistNwResp_onHold : Network Response record is created for the test case with SUI flag unchecked.');
        
    }

    /**********************************************************************
     *  Scenario:
     *      Checking for response on the network response screen email template population - positive test for disputed delivery scan
     **********************************************************************/
    private static testMethod void testNwResp_DisputedDeliveryScan() {
        //insert template
        Folder fld = [Select Id 
                    from 
                        Folder 
                    where 
                        DeveloperName='SSSW_PON_Network_Templates' 
                    limit 1];
        EmailTemplate em = new EmailTemplate(DeveloperName='TestTemplate',SUbject='Test',Body='here we are',Name='TestTemplate',
                FolderId=fld.Id,TemplateType='Text',HTMLValue='text');
        insert em;
        
        test.startTest();
            Case cse = [Select Id from Case limit 1]; //Disputed delivery scan case
            //set standard page controller and initialize class constroller
            ApexPages.StandardController stdCon = new ApexPages.StandardController(cse);
            SSSW_MyNetworkResponsePageContr contr = new SSSW_MyNetworkResponsePageContr (stdCon);
            contr.initialize();
            //set the controller variables
            contr.nResp.Address_Type__c = 'Residential';
            contr.nResp.Delivery_officer_knowledge__c = 'Cannot Recall';
            contr.setDeliveryOptions();
            contr.nresp.More_Delivery_Information__c = 'Front Door';
            contr.nResp.Network_Comments__c = 'Standard Response';
            contr.nResp.Request_Hold_Case__c = false;
            contr.showEmailTemplate();
        test.stopTest();
        try {
            //qeury to see if network response is created
            Network_Response__c nr = [Select id 
                                     from 
                                        Network_Response__c  
                                     where 
                                        RelatedCase__c= :cse.Id 
                                     order by 
                                        createdDate desc
                                     limit 1];
        } catch(Exception exp) {
            System.assertEquals('List has no rows for assignment to SObject',exp.getMessage(),
                    'SSSW_MyNetworkResponsePageContr_Test_testNwResp_ClosedCaseAcknowledge : Network Response record is not created for the test case.');
        }
        
    }

    /**********************************************************************
     *  Scenario:
     *      Checking for response on the network response screen for Non-disputed delivery scans - positive test
     **********************************************************************/
    private static testMethod void testNwResp_NonDisputedDeliveryScan() {
        
        Case cse;
        //query  Disputed delivery scan case
        cse = [Select Id from Case limit 1]; 
        //update to Non DDS
        cse.EnquirySubType__c = 'Missing Item';
        database.update(cse);

        test.startTest();
            //set standard page controller and initialize class constroller
            ApexPages.StandardController stdCon = new ApexPages.StandardController(cse);
            SSSW_MyNetworkResponsePageContr contr = new SSSW_MyNetworkResponsePageContr (stdCon);
            contr.initialize();
            contr.nResp.Address_Type__c = 'Residential';
            contr.nResp.Delivery_officer_knowledge__c = 'Cannot Recall';
            contr.nResp.Network_Comments__c = 'Standard Response';
            contr.setDeliveryOptions();
            contr.nresp.More_Delivery_Information__c = 'Front Door';
            contr.nResp.Request_Hold_Case__c = false;
            contr.showEmailTemplate();
            contr.updateRespoTemp();
            contr.goBack();
        test.stopTest();
        //qeury to see if network response is created
        Network_Response__c nr = [Select id 
                                 from 
                                    Network_Response__c  
                                 where 
                                    RelatedCase__c= :cse.Id 
                                 order by 
                                    createdDate desc
                                 limit 1];
        System.assertNotEquals(null,nr,
                'SSSW_MyNetworkResponsePageContr_Test_testNwResp_NonDisputedDeliveryScan : Network Response record is created for the test case.');
    
    }

    /**********************************************************************
     *  Scenario:
     *      Checking for response on the network response screen for disputed delivery scans - positive test (select options and go back to selection after template review)
     **********************************************************************/
    private static testMethod void testNwResp_DDS_OptionSelect() {
        //insert template
        Folder fld = [Select Id 
                    from 
                        Folder 
                    where 
                        DeveloperName='SSSW_PON_Network_Templates' 
                    limit 1];
        EmailTemplate em = new EmailTemplate(DeveloperName='TestTemplate',SUbject='Test',Body='here we are',Name='ResidentialCannot RecallFront Door',
                FolderId=fld.Id,TemplateType='Text',HTMLValue='text');
        insert em;
        
        test.startTest();
            Case  cse = [Select Id from Case limit 1]; 
            //set standard page controller and initialize class constroller
            ApexPages.StandardController stdCon = new ApexPages.StandardController(cse);
            SSSW_MyNetworkResponsePageContr contr = new SSSW_MyNetworkResponsePageContr (stdCon);
            contr.initialize();
            contr.nResp.Address_Type__c = 'Residential';
            contr.nResp.Delivery_officer_knowledge__c = 'Cannot Recall';
            contr.nResp.Network_Comments__c = 'Standard Response';
            contr.setDeliveryOptions();
            contr.nresp.More_Delivery_Information__c = 'Front Door';
            contr.nResp.Request_Hold_Case__c = false;
            contr.showEmailTemplate();
            contr.updateRespoTemp();
            contr.goBack();
        test.stopTest();
        try {
            //qeury to see if network response is created
            Network_Response__c nr = [Select id 
                                     from 
                                        Network_Response__c  
                                     where 
                                        RelatedCase__c= :cse.Id 
                                     order by 
                                        createdDate desc
                                     limit 1];
        } catch(Exception exp) {
            System.assertEquals('List has no rows for assignment to SObject',exp.getMessage(),
                    'SSSW_MyNetworkResponsePageContr_Test_testNwResp_DDS_OptionSelect : Network Response record is not created for the test case.');
        }
    
    }

    /**********************************************************************
     *  Scenario:
     *      Checking for response on the network response screen for disputed delivery scans - no email template available - negative test
     **********************************************************************/
    private static testMethod void testNwResp_DDS_NoEmailTemp() {
        
        Case cse;
        
        cse = [Select Id from Case limit 1]; //Disputed delivery scan case
        //insert existing network response
        Network_Response__c nresp = new Network_Response__c();
        nresp.Address_Type__c = 'Residential';
        nResp.Delivery_officer_knowledge__c = 'Cannot Recall';
        nResp.Network_Comments__c = 'Standard Response';
        nResp.RelatedCase__c = cse.Id;
        nResp.RelatedCase__c = cse.Id;
        nresp.Request_Hold_Case__c = false;
        database.insert(nResp);
    
        test.startTest();
            //set standard page controller and initialize class constroller
            ApexPages.StandardController stdCon = new ApexPages.StandardController(cse);
            SSSW_MyNetworkResponsePageContr contr = new SSSW_MyNetworkResponsePageContr (stdCon);
            contr.initialize();
            contr.setDeliveryOptions();
            contr.nresp.More_Delivery_Information__c = 'Front Door';
            contr.nresp.Request_Hold_Case__c = false;
            contr.showEmailTemplate();
        test.stopTest();
        
        //qeury to see if network response is created
        Network_Response__c nr = [Select id 
                                 from 
                                    Network_Response__c  
                                 where 
                                    RelatedCase__c= :cse.Id 
                                 order by 
                                    createdDate desc
                                 limit 1];
        System.assertNotEquals(null,nr,
                'SSSW_MyNetworkResponsePageContr_Test_testNwResp_DDS_OptionSelect : Network Response record is created for the test case.');
    
    }

    /**********************************************************************
     *  Scenario:
     *      Checking for response on the network response screen for closed disputed delivery scans for acknowledge scenario- negative and positive test
     **********************************************************************/
    private static testMethod void testNwResp_ClosedCaseAcknowledge() {

        Case cse = [Select Id,Status from Case limit 1];//Disputed delivery scan case
        cse.Status = 'Closed';
        cse.ResolutionCode__c = 'Resolved';
        database.update(cse);

        test.startTest();
            //set standard page controller and initialize class constroller
            ApexPages.StandardController stdCon = new ApexPages.StandardController(cse);
            SSSW_MyNetworkResponsePageContr contr = new SSSW_MyNetworkResponsePageContr (stdCon);
            contr.initialize();
            //set selection options for DDS picklist
            contr.nResp.Address_Type__c = 'Residential';
            contr.nResp.Delivery_officer_knowledge__c = 'Cannot Recall';
            contr.setDeliveryOptions();
            contr.nresp.More_Delivery_Information__c = 'Front Door';
            contr.nResp.Network_Comments__c = 'Standard Response';
            contr.acknowledge();
            contr.nResp.Network_Comments__c = '';
            contr.acknowledge();
        test.stopTest();
        try {
            //qeury to see if network response is created
        Network_Response__c nr = [Select id 
                                 from 
                                    Network_Response__c  
                                 where 
                                    RelatedCase__c= :cse.Id 
                                 order by 
                                    createdDate desc
                                 limit 1];
        } catch(Exception exp) {
            System.assertEquals('List has no rows for assignment to SObject',exp.getMessage(),
                    'SSSW_MyNetworkResponsePageContr_Test_testNwResp_ClosedCaseAcknowledge : Network Response record is not created for the test case.');
        }
    
    }

    /**********************************************************************
     *  Scenario:
     *      Checking for response on the network response screen for closed and updated disputed delivery scans for acknowledge and respond scenario- positive test
     **********************************************************************/
    private static testMethod void testNwResp_closedAckAndSave() {

        Case cse = [Select Id,Status from Case limit 1];//Disputed delivery scan case
        cse.Status = 'Closed';
        cse.ResolutionCode__c = 'Resolved';
        database.update(cse);

        test.startTest();
            //set standard page controller and initialize class constroller
            ApexPages.StandardController stdCon = new ApexPages.StandardController(cse);
            SSSW_MyNetworkResponsePageContr contr = new SSSW_MyNetworkResponsePageContr (stdCon);
            contr.initialize();
            contr.nResp.Address_Type__c = 'Residential';
            contr.nResp.Delivery_officer_knowledge__c = 'Cannot Recall';
            contr.setDeliveryOptions();
            contr.nresp.More_Delivery_Information__c = 'Front Door';
            contr.nResp.Network_Comments__c = 'Standard Response';
            contr.acknowledgeAndSave();
            contr.casePrint();
        test.stopTest();
        //qeury to see if network response is created
        Network_Response__c nr = [Select id 
                                 from 
                                    Network_Response__c  
                                 where 
                                    RelatedCase__c= :cse.Id 
                                 order by 
                                    createdDate desc
                                 limit 1];
        System.assertNotEquals(null,nr,
                'SSSW_MyNetworkResponsePageContr_Test_testNwResp_closedAckAndSave : Network Response record is created for the test case.');
        
    }

    /**********************************************************************
     *  Scenario:
     *      Checking for response on the network response screen for Closed cases On Hold scenario- positive test
     **********************************************************************/
    private static testMethod void testNwResp_Closed_OnHoldCase() {

        //insert template
        Folder fld = [Select Id 
                    from 
                        Folder 
                    where 
                        DeveloperName='SSSW_PON_Network_Templates' 
                    limit 1];
        EmailTemplate em = new EmailTemplate(DeveloperName='TestTemplate',SUbject='Test',Body='here we are',Name='TestTemplate',
                FolderId=fld.Id,TemplateType='Text',HTMLValue='text');
        
        Case cse = [Select Id,Status from Case limit 1];//Disputed delivery scan case
        cse.Status = 'Closed';
        cse.ResolutionCode__c = 'Resolved';
        cse.Type = 'Feedback';
        database.update(cse);

        test.startTest();
            //set standard page controller and initialize class constroller
            ApexPages.StandardController stdCon = new ApexPages.StandardController(cse);
            SSSW_MyNetworkResponsePageContr contr = new SSSW_MyNetworkResponsePageContr (stdCon);
            contr.initialize();
            contr.nResp.Address_Type__c = 'Residential';
            contr.nResp.Delivery_officer_knowledge__c = 'Cannot Recall';
            contr.setDeliveryOptions();
            contr.nresp.More_Delivery_Information__c = 'Front Door';
            contr.nResp.Network_Comments__c = 'Standard Response';
            //contr.nresp.Request_Hold_Case__c = true;
            contr.nresp.CaseAction__c = 'Closed';
            contr.showEmailTemplate();
        test.stopTest();
        try {
            //qeury to see if network response is created
            Network_Response__c nr = [Select id 
                                     from 
                                        Network_Response__c  
                                     where 
                                        RelatedCase__c= :cse.Id 
                                     order by 
                                        createdDate desc
                                     limit 1];
        } catch(Exception exp) {
            System.assertEquals('List has no rows for assignment to SObject',exp.getMessage(),
                    'SSSW_MyNetworkResponsePageContr_Test_testNwResp_Closed_OnHoldCase : Network Response record is not created for the test case.');
        }
    
    }

    /**********************************************************************
     *  Scenario:
     *      Checking for response on the network response screen for closed cases - response capture only
     **********************************************************************/
    private static testMethod void testNwResp_ClosedCase() {

        //insert template
        Folder fld = [Select Id 
                    from 
                        Folder 
                    where 
                        DeveloperName='SSSW_PON_Network_Templates' 
                    limit 1];
        EmailTemplate em = new EmailTemplate(DeveloperName='TestTemplate',SUbject='Test',Body='here we are',Name='TestTemplate',
                FolderId=fld.Id,TemplateType='Text',HTMLValue='text');
        //query DDS case
        Case cse = [Select Id,Status from Case limit 1];//Disputed delivery scan case
        //update to Feedback closed
        cse.Status = 'Closed';
        cse.ResolutionCode__c = 'Resolved';
        cse.Type = 'Feedback';
        database.update(cse);

        test.startTest();
            //set standard page controller and initialize class constroller
            ApexPages.StandardController stdCon = new ApexPages.StandardController(cse);
            SSSW_MyNetworkResponsePageContr contr = new SSSW_MyNetworkResponsePageContr (stdCon);
            contr.initialize();
            contr.nResp.Address_Type__c = 'Residential';
            contr.nResp.Delivery_officer_knowledge__c = 'Cannot Recall';
            contr.setDeliveryOptions();
            contr.nresp.More_Delivery_Information__c = 'Front Door';
            contr.nresp.to_CCC_action__c = false;
            contr.nresp.Request_Hold_Case__c = true;
            
            contr.showEmailTemplate();
        test.stopTest();
        try {
            //qeury to see if network response is created
            Network_Response__c nr = [Select id 
                                     from 
                                        Network_Response__c  
                                     where 
                                        RelatedCase__c= :cse.Id 
                                     order by 
                                        createdDate desc
                                     limit 1];
        } catch(Exception exp) {
            System.assertEquals('List has no rows for assignment to SObject',exp.getMessage(),
                    'SSSW_MyNetworkResponsePageContr_Test_testNwResp_ClosedCase : Network Response record is not created for the test case.');
        }
    
    }


    /**********************************************************************
     *  Scenario:
     *      Checking for response on the network response screen for Case reassgnment and sending back to CCC of closed case - negative test
     **********************************************************************/
    private static testMethod void testNwResp_RessAndCCC_Negative() {

        //insert template
        Folder fld = [Select Id 
                    from 
                        Folder 
                    where 
                        DeveloperName='SSSW_PON_Network_Templates' 
                    limit 1];
        EmailTemplate em = new EmailTemplate(DeveloperName='TestTemplate',SUbject='Test',Body='here we are',Name='TestTemplate',
                FolderId=fld.Id,TemplateType='Text',HTMLValue='text');
        //insert em;

        //insert network for re-assignment
        Network__c nw = TestDataProvider.createTestNetwork();
        nw.Email__c = 'top@top.com';
        nw.Name = 'test network';
        nw.Post_Code__c = '3000';
        nw.Geolocation__Latitude__s = 31;
        nw.Geolocation__Longitude__s = 121;
        nw.Contact_Facility__c ='Email';
        insert nw;

        Case cse = [Select Id,Status from Case limit 1];//Disputed delivery scan case
        cse.Status = 'Closed';
        cse.ResolutionCode__c = 'Resolved';
        cse.Type = 'Feedback';
        database.update(cse);

        test.startTest();
            //set standard page controller and initialize class constroller
            ApexPages.StandardController stdCon = new ApexPages.StandardController(cse);
            SSSW_MyNetworkResponsePageContr contr = new SSSW_MyNetworkResponsePageContr (stdCon);
            contr.initialize();
            contr.nResp.Address_Type__c = 'Residential';
            contr.nResp.Delivery_officer_knowledge__c = 'Cannot Recall';
            contr.setDeliveryOptions();
            contr.nresp.More_Delivery_Information__c = 'Front Door';
            contr.nResp.Network_Comments__c = 'Standard Response';
            contr.nresp.to_CCC_action__c = true;
            contr.nresp.Request_Hold_Case__c = false;
            contr.nresp.to_Reassign_Network__c= nw.Id;
            contr.showEmailTemplate();
        test.stopTest();
        try {
            //qeury to see if network response is created
            Network_Response__c nr = [Select id 
                                     from 
                                        Network_Response__c  
                                     where 
                                        RelatedCase__c= :cse.Id 
                                     order by 
                                        createdDate desc
                                     limit 1];
        } catch(Exception exp) {
            System.assertEquals('List has no rows for assignment to SObject',exp.getMessage(),
                    'SSSW_MyNetworkResponsePageContr_Test_testNwResp_RessAndCCC_Negative : Network Response record is not created for the test case.');
        }
    }

    /**********************************************************************
     *  Scenario:
     *      Checking for response on the network response screen for Case sending back to CCC of closed case - positive test
     **********************************************************************/
    private static testMethod void testNwResp_sendbckCCC() {

        //insert template
        Folder fld = [Select Id 
                    from 
                        Folder 
                    where 
                        DeveloperName='SSSW_PON_Network_Templates' 
                    limit 1];
        EmailTemplate em = new EmailTemplate(DeveloperName='TestTemplate',SUbject='Test',Body='here we are',Name='TestTemplate',
                FolderId=fld.Id,TemplateType='Text',HTMLValue='text');

		test.startTest();
				
			Case cse = [Select Id,Status from Case limit 1];//Disputed delivery scan case
			cse.Status = 'Closed';
			cse.ResolutionCode__c = 'Resolved';
			cse.Type = 'Feedback';
			database.update(cse);

            //set standard page controller and initialize class constroller
            ApexPages.StandardController stdCon = new ApexPages.StandardController(cse);
            SSSW_MyNetworkResponsePageContr contr = new SSSW_MyNetworkResponsePageContr (stdCon);
            contr.initialize();
            contr.nResp.Address_Type__c = 'Residential';
            contr.nResp.Delivery_officer_knowledge__c = 'Cannot Recall';
            contr.setDeliveryOptions();
            contr.nresp.More_Delivery_Information__c = 'Front Door';
            contr.nResp.Network_Comments__c = 'Standard Response';
            contr.nresp.to_CCC_action__c = true;
            contr.showEmailTemplate();
        test.stopTest();

        //qeury to see if network response is created
        Network_Response__c nr = [Select id 
                                 from 
                                    Network_Response__c  
                                 where 
                                    RelatedCase__c= :cse.Id 
                                 order by 
                                    createdDate desc
                                 limit 1];
        System.assertNotEquals(null, nr,
                'SSSW_MyNetworkResponsePageContr_Test_testNwResp_sendbckCCC : Network Response record is created for the test case.');
        String ownerId = [select Id from Group where Name='SSSW Network Queue' and type = 'Queue' limit 1].Id;
        Case cse1 = [Select Id, OwnerId from Case limit 1];
        System.assertNotEquals(ownerId, cse1.OwnerId,
                'SSSW_MyNetworkResponsePageContr_Test_testNwResp_sendbckCCC : Case is sent back to CCC');

    
    }

    /**********************************************************************
     *  Scenario:
     *      Checking for response on the network response screen for Case reassgnment for contact method email - positive test
     **********************************************************************/
    private static testMethod void testNwResp_Reassign_Email() {

        //insert template
        Folder fld = [Select Id 
                    from 
                        Folder 
                    where 
                        DeveloperName='SSSW_PON_Network_Templates' 
                    limit 1];
        EmailTemplate em = new EmailTemplate(DeveloperName='TestTemplate',SUbject='Test',Body='here we are',Name='TestTemplate',
                FolderId=fld.Id,TemplateType='Text',HTMLValue='text');
        //insert em;

        QM__c qm = new QM__c(NetworkEmail__c = 'customerenquiry@auspost.com.au');
        insert qm;

        //insert network
        Network__c nw = TestDataProvider.createTestNetwork();
        nw.Email__c = 'top@top.com';
        nw.Name = 'test network';
        nw.Post_Code__c = '3000';
        nw.Geolocation__Latitude__s = 31;
        nw.Geolocation__Longitude__s = 121;
        nw.Contact_Facility__c ='Email';
        insert nw;

        Case cse = [Select Id,Status from Case limit 1];//Disputed delivery scan case
        cse.Status = 'Closed';
        cse.ResolutionCode__c = 'Resolved';
        cse.Type = 'Feedback';
        database.update(cse);

        test.startTest();
            //set standard page controller and initialize class constroller
            ApexPages.StandardController stdCon = new ApexPages.StandardController(cse);
            SSSW_MyNetworkResponsePageContr contr = new SSSW_MyNetworkResponsePageContr (stdCon);
            contr.initialize();
            contr.nResp.Address_Type__c = 'Residential';
            contr.nResp.Delivery_officer_knowledge__c = 'Cannot Recall';
            contr.setDeliveryOptions();
            contr.nresp.More_Delivery_Information__c = 'Front Door';
            contr.nResp.Network_Comments__c = 'Standard Response';
            contr.nresp.to_CCC_action__c = false;
            contr.nresp.to_Reassign_Network__c= nw.Id;
            contr.showEmailTemplate();
        test.stopTest();
        Case cse1 = [Select id, Network__c from Case limit 1];
        System.assertEquals(nw.Id,cse1.Network__c,
                'SSSW_MyNetworkLandingContr_Test_testNwResp_Reassign_Email : Test case is re-assigned to another network.');
        
    }

    /**********************************************************************
     *  Scenario:
     *      Checking for response on the network response screen for Case reassgnment for Fax contact method - positive test
     **********************************************************************/
    private static testMethod void testNwResp_Reassign_Fax() {

        //insert template
        Folder fld = [Select Id 
                    from 
                        Folder 
                    where 
                        DeveloperName='SSSW_PON_Network_Templates' 
                    limit 1];
        EmailTemplate em = new EmailTemplate(DeveloperName='TestTemplate',SUbject='Test',Body='here we are',Name='TestTemplate',
                FolderId=fld.Id,TemplateType='Text',HTMLValue='text');
        //insert em;

        //insert network
        Network__c nw = TestDataProvider.createTestNetwork();
        nw.Email__c = 'top@top.com';
        nw.Name = 'test network';
        nw.Post_Code__c = '3000';
        nw.Geolocation__Latitude__s = 31;
        nw.Geolocation__Longitude__s = 121;
        nw.Contact_Facility__c ='Fax';
        insert nw;
        
        Case cse = [Select Id,Status from Case limit 1];//Disputed delivery scan case
        cse.Status = 'Closed';
        cse.ResolutionCode__c = 'Resolved';
        cse.Type = 'Feedback';
        database.update(cse);

        test.startTest();
            //set standard page controller and initialize class constroller
            ApexPages.StandardController stdCon = new ApexPages.StandardController(cse);
            SSSW_MyNetworkResponsePageContr contr = new SSSW_MyNetworkResponsePageContr (stdCon);
            contr.initialize();
            contr.nResp.Address_Type__c = 'Residential';
            contr.nResp.Delivery_officer_knowledge__c = 'Cannot Recall';
            contr.setDeliveryOptions();
            contr.nresp.More_Delivery_Information__c = 'Front Door';
            contr.nResp.Network_Comments__c = 'Standard Response';
            contr.nresp.to_CCC_action__c = false;
            contr.nresp.to_Reassign_Network__c= nw.Id;
            contr.showEmailTemplate();
        test.stopTest();
        Case cse1 = [Select id, Network__c from Case limit 1];
        System.assertEquals(nw.Id,cse1.Network__c,
                'SSSW_MyNetworkLandingContr_Test_testNwResp_Reassign_Fax : Test case is re-assigned to another network.');
    
    }


    /**********************************************************************
     *  Scenario:
     *      Checking for response on the network response screen for Case reassgnment for myNetwork contact method - positive test
     **********************************************************************/
    private static testMethod void testNwResp_Reassign_MyNetwork() {

        //insert template
        Folder fld = [Select Id 
                    from 
                        Folder 
                    where 
                        DeveloperName='SSSW_PON_Network_Templates' 
                    limit 1];
        EmailTemplate em = new EmailTemplate(DeveloperName='TestTemplate',SUbject='Test',Body='here we are',Name='TestTemplate',
                FolderId=fld.Id,TemplateType='Text',HTMLValue='text');
        
        //insert network
        Network__c nw = TestDataProvider.createTestNetwork();
        nw.Email__c = 'top@top.com';
        nw.Name = 'test network';
        nw.Post_Code__c = '3000';
        nw.Geolocation__Latitude__s = 31;
        nw.Geolocation__Longitude__s = 121;
        nw.Contact_Facility__c ='MyNetwork';
        insert nw;
        
        Case cse = [Select Id,Status from Case limit 1];//Disputed delivery scan case
        cse.Status = 'Closed';
        cse.ResolutionCode__c = 'Resolved';
        cse.Type = 'Feedback';
        database.update(cse);

        test.startTest();
            //set standard page controller and initialize class constroller
            ApexPages.StandardController stdCon = new ApexPages.StandardController(cse);
            SSSW_MyNetworkResponsePageContr contr = new SSSW_MyNetworkResponsePageContr (stdCon);
            contr.initialize();
            contr.nResp.Address_Type__c = 'Residential';
            contr.nResp.Delivery_officer_knowledge__c = 'Cannot Recall';
            contr.setDeliveryOptions();
            contr.nresp.More_Delivery_Information__c = 'Front Door';
            contr.nResp.Network_Comments__c = 'Standard Response';
            contr.nresp.to_CCC_action__c = false;
            contr.nresp.to_Reassign_Network__c= nw.Id;
            contr.showEmailTemplate();
        test.stopTest();
        Case cse1 = [Select id, Network__c from Case limit 1];
        System.assertEquals(nw.Id,cse1.Network__c,
                'SSSW_MyNetworkLandingContr_Test_testNwResp_Reassign_MyNetwork : Test case is re-assigned to another network.');
        
    }



    /**********************************************************************
     *  Scenario:
     *      Checking for response on the network response screen for closed cases to be acknowledgeAndSave - positive test
     ********************************************************************/
    private static testMethod void testNwResp_AckAndSave() {

        //insert template
        Folder fld = [Select Id 
                    from 
                        Folder 
                    where 
                        DeveloperName='SSSW_PON_Network_Templates' 
                    limit 1];
        EmailTemplate em = new EmailTemplate(DeveloperName='TestTemplate',SUbject='Test',Body='here we are',Name='TestTemplate',
                FolderId=fld.Id,TemplateType='Text',HTMLValue='text');
        
        Case cse = [Select Id,Status, Network__c from Case limit 1];//Disputed delivery scan case
        cse.Status = 'Closed';
        cse.ResolutionCode__c = 'Resolved';
        database.update(cse);

        test.startTest();
            //set standard page controller and initialize class constroller
            ApexPages.StandardController stdCon = new ApexPages.StandardController(cse);
            SSSW_MyNetworkResponsePageContr contr = new SSSW_MyNetworkResponsePageContr (stdCon);
            contr.initialize();
            contr.nResp.Delivery_officer_knowledge__c = 'Cannot Recall';
            contr.setDeliveryOptions();
            contr.nresp.More_Delivery_Information__c = 'Front Door';
            contr.nResp.Network_Comments__c = 'Standard Response';
            contr.nresp.to_CCC_action__c = false;
            contr.nresp.Request_Hold_Case__c = false;
            contr.showEmailTemplate();
            contr.acknowledgeAndSave();
        test.stopTest();
        //qeury to see if network response is created
        Network_Response__c nr = [Select id 
                                 from 
                                    Network_Response__c  
                                 where 
                                    RelatedCase__c= :cse.Id 
                                 order by 
                                    createdDate desc
                                 limit 1];
        System.assertNotEquals(null, nr,
                'SSSW_MyNetworkResponsePageContr_Test_testNwResp_AckAndSave : Network Response record is created for the test case.');
    
    }


    /**********************************************************************
     *  Scenario:
     *      Checking for existing re-assigned response on the network response to nullify all data for new network positive test
     **********************************************************************/
    private static testMethod void testNwResp_ExistingReassign_NullifyData() {

        //insert network
        Network__c nw = TestDataProvider.createTestNetwork();
        nw.Email__c = 'top@top.com';
        nw.Name = 'test network';
        nw.Post_Code__c = '3000';
        nw.Geolocation__Latitude__s = 31;
        nw.Geolocation__Longitude__s = 121;
        nw.Contact_Facility__c ='Email';
        insert nw;

        Case cse;
    
        cse = [Select Id from Case limit 1]; 
        //create existing network response
        Network_Response__c nresp = new Network_Response__c();
        nresp.Address_Type__c = 'Residential';
        nResp.Delivery_officer_knowledge__c = 'Cannot Recall';
        nResp.Network_Comments__c = 'Standard Response';
        nResp.RelatedCase__c = cse.Id;
        nResp.RelatedCase__c = cse.Id;
        nresp.to_Reassign_Network__c = nw.Id;
        database.insert(nResp);

        test.startTest();
            //set standard page controller and initialize class constroller
            ApexPages.StandardController stdCon = new ApexPages.StandardController(cse);
            SSSW_MyNetworkResponsePageContr contr = new SSSW_MyNetworkResponsePageContr (stdCon);
            contr.initialize();
        test.stopTest();
        system.assertEquals('', contr.nresp.Address_Type__c,
                'SSSW_MyNetworkResponsePageContr_Test_testNwResp_ExistingReassign_NullifyData: Network Response values are nullified.' );
        
    }
    
    /**
	  * SCENARIO:
	  *   Scenario will test the trimEscalationEmailContent functionality where the escalation email content is trimmed to the fields length
	  */
	  public static testMethod void testTrimEscalationEmailContent() {
		Test.startTest();
		string trimmedString = SSSW_MyNetworkResponsePageContr.trimContent('email comment', 2);
		Test.stopTest();
		// check the string passed is trimmed
		System.assertEquals(trimmedString, 'em');
	}

}