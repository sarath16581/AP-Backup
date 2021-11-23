/*------------------------------------------------------------
Author:        Patrick James Franco
Company:       Cloud Sherpas
Description:   Test class for StarTrack Card Left Controller
               testSetup - Creates test data to be used for all test methods
               testUpdateCasePositive - Positive test when trying update the Case
               testUpdateCaseNegative - Negative test when trying to update the Case
               testValidateEnquiryTypeNo - Positive test when validating Enquiry and Billing Account flags set to No
               testValidateEnquiryTypeYes -Positive test when validating Enquiry and Billing Account flags set to Yes
               testValidateEnquiryTypeAirlock - Positive test when validating Enquiry and Article Service Type is set to Airlock
               testValidateEnquiryTypeATL - Positive test when validating Enquiry and ATL is checked
               testValidateEnquiryTypeOverrideYes - Positive test when validating Enquiry and Customer Restriction is Overriden
               testValidateEnquiryTypeOverrideNo - Negative test when validating Enquiry and Customer Restriction is Overriden
               testGetEnquiryTypeValues - Positive test to verify available picklist options
               testOther - Positive test to verify delivery message
History
September 3, 2015 - Patrick James Franco - Created
Oct. 16, 2015 - David Catindoy - Modified
November 26, 2015 - Patrick James Franco - Updated based changes regarding StarTrackQuickAction component
------------------------------------------------------------*/

@isTest
private class StarTrackCardLeft_ControllerX_Test {

    @testSetup static void testSetup() {
        List<sObject> ls = TestDataProvider.createStartrackErrorMessagesData();

        Account testAccount  = TestDataProvider.createAccount('Test Account', 1)[0];
        INSERT testAccount;

        testAccount.Legacy_Id__c = '60000000';
        UPDATE testAccount;

        Billing_Account__c testBillingAcc = TestDataProvider.createBillingAccount('', 1,new List<Account>{testAccount})[0];
        testBillingAcc.Depot_Collection__c = 'No';
        testBillingAcc.Redirection__c = 'No';
        testBillingAcc.Redelivery__c = 'No';
        INSERT testBillingAcc;

        Network__c testNetwork = TestDataProvider.createTestNetwork();
        testNetwork.RecordTypeId = Schema.SObjectType.Network__c.getRecordTypeInfosByName().get('Metro').getRecordTypeId(); 
        testNetwork.Preferred_Method_of_Tasking__c = StarTrack_Constants.NETWORK_PREFMETHOFTASKING_EMAIL;
        testNetwork.ST_Email__c = true;
        testNetwork.Email__c = 'te@st.comz';
        testNetwork.State__c = 'ACT';
        testNetwork.Facility__c = 'Express';
        testNetwork.Business_Hours__c = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1].Id;
        testNetwork.Email__c = 'te@st.zzz';
        INSERT testNetwork;

        Network__c testNetworkDummy = TestDataProvider.createTestNetwork();
        INSERT testNetworkDummy;

        Depot_Area__c testDepotArea = new Depot_Area__c();
        testDepotArea.Name = 'Test Depot Area';
        testDepotArea.Depot__c = testNetwork.Id;
        testDepotArea.Area__c = StarTrack_Constants.DEPOTAREA_AREA_BRANCHMANAGEMENT;
        INSERT testDepotArea;

        Depot_Area_User__c testDepotAreaUser = new Depot_Area_User__c();
        testDepotAreaUser.Name = 'Test Depot Area User';
        testDepotAreaUser.Depot_Role__c = testDepotArea.Id;
        testDepotAreaUser.User__c = UserInfo.getUserId();
        INSERT testDepotAreaUser;

        Article__c testArticle = TestDataProvider.createTestArticle();
        testArticle.Service_Type__c = 'Express';
        testArticle.ReceiverPostcode__c = '1234';
        testArticle.Receiver_Suburb__c = 'TestSuburb';
        testArticle.STServiceType__c = 'Airlock';
        testArticle.Source_System__c = 'TEAM';
        testArticle.Network__c = testNetwork.Id;
        testArticle.Billing_Account__c = testBillingAcc.Id;
        INSERT testArticle;

        Id delEnquiryRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Delivery Enquiry').getRecordTypeId();
        Case testCase = TestDataProvider.createTestCase();
        testCase.RecordTypeId = delEnquiryRecTypeId;
        testCase.Call_Purpose__c = 'Card Left';
        testCase.Enquiry_Type__c = 'Check Address';
        testCase.ArticleTest__c = testArticle.Id;
        testCase.Related_Billing_Account__c = testBillingAcc.Id;
        testCase.AccountId = testAccount.Id;
        testCase.Network__c = testNetwork.Id;
        testCase.BusinessHoursId = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1].Id;
        INSERT testCase;
    }

    @isTest static void testUpdateCasePositive1() {

        Case queryCase = [SELECT Id, Network__c, ArticleTest__c FROM Case LIMIT 1];
        if(queryCase.Network__c == null){
            queryCase.Network__c = [SELECT Id, Network__c FROM Article__c WHERE Id =: queryCase.ArticleTest__c].Network__c;
            update queryCase;
        }

        Test.setCurrentPage(Page.StarTrackCardLeftPA);
        ApexPages.currentPage().getParameters().put('id', queryCase.Id);

        StarTrackCardLeft_ControllerX ext = new StarTrackCardLeft_ControllerX();
        Integer dayOfTheWeek = Math.mod(Date.newInstance(1900, 1, 7).daysBetween(System.today()), 7);
        Date validDate = System.today();
        if(dayOfTheWeek < 5){
            validDate += 1;
        } else{
            validDate += 3;
        }
        
        Test.startTest();
            ext.changeEnquiryType();
            ext.caseRecord.Business_Name__c = 'StarTrack';
            ext.caseRecord.Phone__c = '0976347364';
            ext.caseRecord.Delivery_Collection_Date__c = validDate;
            ext.deliveryAddress.line1 = 'line1';
            ext.deliveryAddress.line2 = 'line2';
            ext.deliveryAddress.city = 'city';
            ext.deliveryAddress.state = 'state';
            ext.deliveryAddress.postcode = 'postcode';
            ext.updateCase();
        Test.stopTest();

        Case resultCase = [SELECT Delivery_Address_Line_1__c, Delivery_Address_Line_2__c, Delivery_Address_Suburb__c, Delivery_Address_State__c, Delivery_Address_Post_Code__c, Delivery_Address_DPID__c, Delivery_Address_Validation__c, Calculate_Run_Dock_and_Depot_Area__c, Additional_Information__c FROM Case WHERE Id = :queryCase.Id];
        System.assertEquals(resultCase.Delivery_Address_Line_1__c, 'line1');
        System.assertEquals(resultCase.Delivery_Address_Line_2__c, 'line2');
        System.assertEquals(resultCase.Delivery_Address_Suburb__c, 'city');
        System.assertEquals(resultCase.Delivery_Address_State__c, 'state');
        System.assertEquals(resultCase.Delivery_Address_Post_Code__c, 'postcode');
    }

    @isTest static void testUpdateCasePositive2() {

        Case queryCase = [SELECT Id FROM Case LIMIT 1];

        Test.setCurrentPage(Page.StarTrackCardLeftPA);
        ApexPages.currentPage().getParameters().put('id', queryCase.Id);

        StarTrackCardLeft_ControllerX ext = new StarTrackCardLeft_ControllerX();
        Integer dayOfTheWeek = Math.mod(Date.newInstance(1900, 1, 7).daysBetween(System.today()), 7);
        Date validDate = System.today();
        if(dayOfTheWeek < 5){
            validDate += 1;
        } else{
            validDate += 3;
        }

        Test.startTest();
            ext.caseRecord.Enquiry_Type__c = 'Depot Collection';
            ext.caseRecord.Business_Name__c = 'StarTrack';
            ext.caseRecord.Phone__c = '0976347364';
            ext.caseRecord.Delivery_Collection_Date__c = validDate;
            ext.updateCase();

        Test.stopTest();

        Case resultCase = [SELECT Business_Name__c, Phone__c, Delivery_Collection_Date__c, Enquiry_Type__c, Additional_Information__c FROM Case WHERE Id = :queryCase.Id];
        System.assertEquals(resultCase.Enquiry_Type__c, 'Depot Collection');
        System.assertEquals(resultCase.Business_Name__c, 'StarTrack');
        System.assertEquals(resultCase.Phone__c, '0976347364');
        System.assertEquals(resultCase.Delivery_Collection_Date__c, validDate);

    }

    @isTest static void testUpdateCaseCatch1() {

        Case queryCase = [SELECT Id, Network__c, ArticleTest__c FROM Case LIMIT 1];
        if(queryCase.Network__c == null){
            queryCase.Network__c = [SELECT Id, Network__c FROM Article__c WHERE Id =: queryCase.ArticleTest__c].Network__c;
            update queryCase;
        }

        Test.setCurrentPage(Page.StarTrackCardLeftPA);
        ApexPages.currentPage().getParameters().put('id', queryCase.Id);

        StarTrackCardLeft_ControllerX ext = new StarTrackCardLeft_ControllerX();
        Integer dayOfTheWeek = Math.mod(Date.newInstance(1900, 1, 7).daysBetween(System.today()), 7);
        Date validDate = System.today();
        if(dayOfTheWeek < 5){
            validDate += 1;
        } else{
            validDate += 3;
        }

        Test.startTest();
            ext.changeEnquiryType();
            ext.caseRecord.Business_Name__c = 'StarTrack';
            ext.caseRecord.Phone__c = '0976347364';
            ext.caseRecord.Delivery_Collection_Date__c = validDate;
            ext.caseRecord.ATL_Instructions__c = 'Other';
            ext.deliveryAddress.line1 = 'line1';
            ext.deliveryAddress.line2 = 'line2';
            ext.deliveryAddress.city = 'city';
            ext.deliveryAddress.state = 'state';
            ext.deliveryAddress.postcode = 'postcode';
            try{
                ext.updateCase();
            } catch(DMLException e){
                System.assert(String.isEmpty(e.getMessage()));
            }
        Test.stopTest();
    }

    @isTest static void testUpdateCaseCatch2() {

        Case queryCase = [SELECT Id FROM Case LIMIT 1];

        Test.setCurrentPage(Page.StarTrackCardLeftPA);
        ApexPages.currentPage().getParameters().put('id', queryCase.Id);

        StarTrackCardLeft_ControllerX ext = new StarTrackCardLeft_ControllerX();
        Integer dayOfTheWeek = Math.mod(Date.newInstance(1900, 1, 7).daysBetween(System.today()), 7);
        Date validDate = System.today();
        if(dayOfTheWeek < 5){
            validDate += 1;
        } else{
            validDate += 3;
        }

        Test.startTest();
            ext.caseRecord.ATL_Instructions__c = 'Other';
            ext.caseRecord.Enquiry_Type__c = 'Depot Collection';
            ext.caseRecord.Business_Name__c = 'StarTrack';
            ext.caseRecord.Phone__c = '0976347364';
            ext.caseRecord.Delivery_Collection_Date__c = validDate;
            try{
                ext.updateCase();
            } catch(DMLException e){
                System.assert(String.isEmpty(e.getMessage()));
            }

        Test.stopTest();

    }

    @isTest static void testUpdateCaseNegative() {

        Case queryCase = [SELECT Id FROM Case LIMIT 1];

        Test.setCurrentPage(Page.StarTrackCardLeftPA);
        ApexPages.currentPage().getParameters().put('id', queryCase.Id);

        StarTrackCardLeft_ControllerX ext = new StarTrackCardLeft_ControllerX();

        Test.startTest();
            ext.updateCase();

            Case resultCase = [SELECT Delivery_Address_Line_1__c, Delivery_Address_Line_2__c, Delivery_Address_Suburb__c, Delivery_Address_State__c, Delivery_Address_Post_Code__c, Delivery_Address_DPID__c, Delivery_Address_Validation__c FROM Case WHERE Id =:queryCase.Id];
            System.assert(String.isBlank(resultCase.Delivery_Address_Line_1__c));
            System.assert(String.isBlank(resultCase.Delivery_Address_Line_2__c));
            System.assert(String.isBlank(resultCase.Delivery_Address_Suburb__c));
            System.assert(String.isBlank(resultCase.Delivery_Address_State__c));
            System.assert(String.isBlank(resultCase.Delivery_Address_Post_Code__c));
            System.assert(String.isBlank(resultCase.Delivery_Address_DPID__c));
            System.assertEquals(resultCase.Delivery_Address_Validation__c, false);

            ext.caseRecord.Enquiry_Type__c = 'Depot Collection';
            ext.updateCase();

            ext.hasDeliveryDateMessage = true;
            ext.caseRecord.Override_Customer_Restriction__c = true;
            ext.updateCase();
        Test.stopTest();
    }

    @isTest static void testCaseUpdateMissingDetails() {

        Case queryCase = [SELECT Id, Network__c, ArticleTest__c FROM Case LIMIT 1];
        if(queryCase.Network__c == null){
            queryCase.Network__c = [SELECT Id, Network__c FROM Article__c WHERE Id =: queryCase.ArticleTest__c].Network__c;
            update queryCase;
        }

        Test.setCurrentPage(Page.StarTrackCardLeftPA);
        ApexPages.currentPage().getParameters().put('id', queryCase.Id);

        StarTrackCardLeft_ControllerX ext = new StarTrackCardLeft_ControllerX();
        Integer dayOfTheWeek = Math.mod(Date.newInstance(1900, 1, 7).daysBetween(System.today()), 7);
        Date validDate = System.today();
        if(dayOfTheWeek < 5){
            validDate += 1;
        } else{
            validDate += 3;
        }

        Test.startTest();
            ext.changeEnquiryType();
            ext.caseRecord.Business_Name__c = 'StarTrack';
            ext.caseRecord.Phone__c = '0976347364';
            ext.caseRecord.Delivery_Collection_Date__c = validDate;
            ext.deliveryAddress.line1 = '';
            ext.deliveryAddress.line2 = 'line2';
            ext.deliveryAddress.city = '';
            ext.deliveryAddress.state = 'state';
            ext.deliveryAddress.postcode = 'postcode';
            ext.updateCase();

        Test.stopTest();

        Case resultCase = [SELECT Delivery_Address_Line_1__c, Delivery_Address_Line_2__c, Delivery_Address_Suburb__c, Delivery_Address_State__c, Delivery_Address_Post_Code__c, Delivery_Address_DPID__c, Delivery_Address_Validation__c, Calculate_Run_Dock_and_Depot_Area__c FROM Case WHERE Id = :queryCase.Id];
        System.assert(!ApexPages.getMessages().isEmpty());
    }

    @isTest static void testValidateEnquiryTypeNo() {

        Case queryCase = [SELECT Id FROM Case LIMIT 1];

        Test.setCurrentPage(Page.StarTrackCardLeftPA);
        ApexPages.currentPage().getParameters().put('id', queryCase.Id);

        StarTrackCardLeft_ControllerX ext = new StarTrackCardLeft_ControllerX();

        Test.startTest();
            // Depot Collection
            ext.caseRecord.Enquiry_Type__c = 'Depot Collection';
            ext.validateEnquiryType();

            // Redirection
            ext.caseRecord.Enquiry_Type__c = 'Redirection';
            ext.validateEnquiryType();

            // Redelivery
            ext.caseRecord.Enquiry_Type__c = 'Redelivery';
            ext.validateEnquiryType();
            System.assertEquals(false, ApexPages.getMessages().isEmpty());
        Test.stopTest();
    }

    @isTest static void testValidateEnquiryTypeYes() {
        Billing_Account__c queryBillingAcc = [SELECT Depot_Collection__c, Redirection__c, Redelivery__c FROM Billing_Account__c LIMIT 1];
        queryBillingAcc.Depot_Collection__c = 'Sender Authorisation Required';
        queryBillingAcc.Redirection__c = 'Sender Authorisation Required';
        queryBillingAcc.Redelivery__c = 'Sender Authorisation Required';
        UPDATE queryBillingAcc;

        Case queryCase = [SELECT Id FROM Case LIMIT 1];

        Test.setCurrentPage(Page.StarTrackCardLeftPA);
        ApexPages.currentPage().getParameters().put('id', queryCase.Id);

        StarTrackCardLeft_ControllerX ext = new StarTrackCardLeft_ControllerX();

        Test.startTest();
            // Depot Collection
            ext.caseRecord.Enquiry_Type__c = 'Depot Collection';
            ext.validateEnquiryType();

            // Redirection
            ext.caseRecord.Enquiry_Type__c = 'Redirection';
            ext.validateEnquiryType();

            // Redelivery
            ext.caseRecord.Enquiry_Type__c = 'Redelivery';
            ext.validateEnquiryType();
            System.assertEquals(false, ApexPages.getMessages().isEmpty());
        Test.stopTest();
    }

    @isTest static void testValidateEnquiryTypeAirlock() {
        Billing_Account__c queryBillingAcc = [SELECT Depot_Collection__c, Redirection__c, Redelivery__c FROM Billing_Account__c LIMIT 1];
        queryBillingAcc.Depot_Collection__c = '';
        queryBillingAcc.Redirection__c = '';
        queryBillingAcc.Redelivery__c = '';
        UPDATE queryBillingAcc;

        Case queryCase = [SELECT Id FROM Case LIMIT 1];

        Test.setCurrentPage(Page.StarTrackCardLeftPA);
        ApexPages.currentPage().getParameters().put('id', queryCase.Id);

        StarTrackCardLeft_ControllerX ext = new StarTrackCardLeft_ControllerX();

        Test.startTest();
            // Depot Collection
            ext.caseRecord.Enquiry_Type__c = 'Depot Collection';
            ext.validateEnquiryType();

            // Check Address
            ext.caseRecord.Enquiry_Type__c = 'Check Address';
            ext.validateEnquiryType();
            //System.assert(ApexPages.getMessages().isEmpty()); PB dependent
            
            // Redirection
            ext.caseRecord.Enquiry_Type__c = 'Redirection';
            ext.validateEnquiryType();
            System.assert(!ApexPages.getMessages().isEmpty());

            // Redelivery
            ext.caseRecord.Enquiry_Type__c = 'Redelivery';
            ext.caseRecord.ATL__c = true;
            ext.validateEnquiryType();
            System.assert(!ApexPages.getMessages().isEmpty());

        Test.stopTest();
    }

    @isTest static void testValidateEnquiryTypeATL() {
        Billing_Account__c queryBillingAcc = [SELECT Depot_Collection__c, Redirection__c, Redelivery__c FROM Billing_Account__c LIMIT 1];
        queryBillingAcc.Depot_Collection__c = 'Yes';
        queryBillingAcc.Redirection__c = 'Yes';
        queryBillingAcc.Redelivery__c = 'Yes';
        queryBillingAcc.Authority_to_leave__c = 'Yes';
        UPDATE queryBillingAcc;

        //DELETE [SELECT Id FROM Article__c];

        Case queryCase = [SELECT Id FROM Case WHERE Related_Billing_Account__c = :queryBillingAcc.Id];

        Test.setCurrentPage(Page.StarTrackCardLeftPA);
        ApexPages.currentPage().getParameters().put('id', queryCase.Id);

        StarTrackCardLeft_ControllerX ext = new StarTrackCardLeft_ControllerX();
        
        System.debug(ext.billingAccount);
        Test.startTest();
            // Redirection
            ext.caseRecord.Enquiry_Type__c = 'Redirection';
            ext.caseRecord.ATL__c = true;
            ext.validateEnquiryType();

            // Redelivery
            ext.caseRecord.Enquiry_Type__c = 'Redelivery';
            ext.validateEnquiryType();

            // Check Address
            ext.caseRecord.Enquiry_Type__c = 'Check Address';
            ext.validateEnquiryType();
            System.assert(!ApexPages.getMessages().isEmpty());
        Test.stopTest();
    }

    @isTest static void testValidateEnquiryTypeOverrideYes() {
        Billing_Account__c queryBillingAcc = [SELECT Depot_Collection__c, Redirection__c, Redelivery__c FROM Billing_Account__c LIMIT 1];
        queryBillingAcc.Authority_to_leave__c = 'Sender Authorisation Required';
        UPDATE queryBillingAcc;

        Case queryCase = [SELECT Id FROM Case LIMIT 1];

        Test.setCurrentPage(Page.StarTrackCardLeftPA);
        ApexPages.currentPage().getParameters().put('id', queryCase.Id);

        StarTrackCardLeft_ControllerX ext = new StarTrackCardLeft_ControllerX();

        Test.startTest();
            ext.caseRecord.Override_Customer_Restriction__c = true;
            ext.caseRecord.ATL__c = true;
            ext.caseRecord.Enquiry_Type__c = 'Depot Collection';
            ext.validateEnquiryType();

            ext.caseRecord.Enquiry_Type__c = 'Redelivery';
            ext.validateEnquiryType();

            ext.caseRecord.Enquiry_Type__c = '';
            ext.validateEnquiryType();
            System.assertEquals(false, ApexPages.getMessages().isEmpty());
        Test.stopTest();
    }

    @isTest static void testValidateEnquiryTypeOverrideNo() {
        Billing_Account__c queryBillingAcc = [SELECT Depot_Collection__c, Redirection__c, Redelivery__c FROM Billing_Account__c LIMIT 1];
        queryBillingAcc.Authority_to_leave__c = 'No';
        UPDATE queryBillingAcc;

        Case queryCase = [SELECT Id FROM Case LIMIT 1];

        Test.setCurrentPage(Page.StarTrackCardLeftPA);
        ApexPages.currentPage().getParameters().put('id', queryCase.Id);

        StarTrackCardLeft_ControllerX ext = new StarTrackCardLeft_ControllerX();

        Test.startTest();
            ext.caseRecord.Override_Customer_Restriction__c = true;
            ext.caseRecord.ATL__c = true;
            ext.caseRecord.Enquiry_Type__c = 'Depot Collection';
            ext.validateEnquiryType();

            ext.caseRecord.Enquiry_Type__c = 'Redelivery';
            ext.validateEnquiryType();

            ext.caseRecord.Enquiry_Type__c = '';
            ext.validateEnquiryType();
            System.assertEquals(false, ApexPages.getMessages().isEmpty());
        Test.stopTest();
    }

    @isTest static void testGetEnquiryTypeValues() {

        Case queryCase = [SELECT Id FROM Case LIMIT 1];

        Test.setCurrentPage(Page.StarTrackCardLeftPA);
        ApexPages.currentPage().getParameters().put('id', queryCase.Id);

        StarTrackCardLeft_ControllerX ext = new StarTrackCardLeft_ControllerX();

        Test.startTest();
            System.assertEquals(5, ext.getEnquiryTypeValues().size());
        Test.stopTest();
    }

    @isTest static void testOther() {

        Case queryCase = [SELECT Id, Network__c, ArticleTest__c FROM Case LIMIT 1];
        if(queryCase.Network__c == null){
            queryCase.Network__c = [SELECT Id, Network__c FROM Article__c WHERE Id =: queryCase.ArticleTest__c].Network__c;
            update queryCase;
        }
        

        Test.setCurrentPage(Page.StarTrackCardLeftPA);
        ApexPages.currentPage().getParameters().put('id', queryCase.Id);

        StarTrackCardLeft_ControllerX ext = new StarTrackCardLeft_ControllerX();
        Integer dayOfTheWeek = Math.mod(Date.newInstance(1900, 1, 7).daysBetween(System.today()), 7);
        Date validDate = System.today();
        if(dayOfTheWeek < 5){
            validDate += 1;
        } else{
            validDate += 3;
        }

        Test.startTest();
            ext.addPageMessage('delivery');
            System.assert(!ApexPages.getMessages().isEmpty());
            ext.caseRecord.Delivery_Collection_Date__c = validDate;
            ext.validateDeliveryDate();
            Integer diff = validDate.daysBetween(System.today());
            ext.caseRecord.Delivery_Collection_Date__c = validDate - diff;
            ext.validateDeliveryDate();
            ext.caseRecord.Enquiry_Type__c = 'Redirection';
            ext.caseRecord.Delivery_Collection_Date__c = validDate;
            ext.validateDeliveryDate();
            ext.caseRecord.Enquiry_Type__c = 'Redelivery';
            ext.validateDeliveryDate();
            System.assert(!ApexPages.getMessages().isEmpty());
        Test.stopTest();
    }

    @isTest static void testWithNullNetworkAndArticleValue() {

        Case queryCase = [SELECT Id, Network__c, ArticleTest__c FROM Case LIMIT 1];
        queryCase.Network__c = null;
        queryCase.ArticleTest__c = null;
        UPDATE queryCase;

        Test.setCurrentPage(Page.StarTrackCardLeftPA);
        ApexPages.currentPage().getParameters().put('id', queryCase.Id);

        Test.startTest();
            StarTrackCardLeft_ControllerX ext = new StarTrackCardLeft_ControllerX();
            System.assert(!ApexPages.getMessages().isEmpty());
        Test.stopTest();
    }
    
    @isTest static void testRemainingScenarios() {

        Case queryCase = [SELECT Id, Network__c, Enquiry_Type__c, ArticleTest__c FROM Case LIMIT 1];
        queryCase.Enquiry_Type__c = 'Depot Collection';
        if(queryCase.Network__c == null){
            queryCase.Network__c = [SELECT Id, Network__c FROM Article__c WHERE Id =: queryCase.ArticleTest__c].Network__c;
        }
        UPDATE queryCase;

        Test.setCurrentPage(Page.StarTrackCardLeftPA);
        ApexPages.currentPage().getParameters().put('id', queryCase.Id);
        Integer dayOfTheWeek = Math.mod(Date.newInstance(1900, 1, 7).daysBetween(System.today()), 7);
        Date validDate = System.today();
        if(dayOfTheWeek < 5){
            validDate += 1;
        } else{
            validDate += 3;
        }

        Test.startTest();
            StarTrackCardLeft_ControllerX ext = new StarTrackCardLeft_ControllerX();
            ext.caseRecord.Enquiry_Type__c = 'Depot Collection';
            ext.caseRecord.Delivery_Collection_Date__c = validDate;
            ext.validateDeliveryDate();
            ext.addPageMessage('enquiry No');
            ext.addPageMessage('enquiry Yes');
            ext.addPageMessage('service');
            ext.addPageMessage('ATL service');
            ext.addPageMessage('ATL Yes');
            ext.addPageMessage('ATL No');
        Test.stopTest();
        
        System.assert(!ApexPages.getMessages().isEmpty());
    }
    
     @isTest static void testCaseNotif() {

        Case queryCase = [SELECT Id FROM Case LIMIT 1];

        Test.setCurrentPage(Page.StarTrackCardLeftPA);
        ApexPages.currentPage().getParameters().put('id', queryCase.Id);

        StarTrackCardLeft_ControllerX ext = new StarTrackCardLeft_ControllerX();

        Test.startTest();
          Test.setMock(WebServiceMock.class, new StartrackWebSvcCalloutMock());
            StarTrackCardLeft_ControllerX.notifyCaseChange(queryCase.Id);
        Test.stopTest();
    }
    
    @isTest static void testCreateChild() {

        Case queryCase = [SELECT Id, Network__c, ArticleTest__c FROM Case LIMIT 1];
        Network__c networkRec = new Network__c(Name = 'System Depot', Preferred_Method_of_Tasking__c = StarTrack_Constants.NETWORK_PREFMETHOFTASKING_EMAIL, ST_Email__c = true, Email__c = 'te@st.comz', State__c = 'ACT', Facility__c = 'Express');
        networkRec.Business_Hours__c = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1].Id;
        networkRec.RecordTypeId = Schema.SObjectType.Network__c.getRecordTypeInfosByName().get('Metro').getRecordTypeId(); 
        INSERT networkRec;
        
        Article__c conRec = [SELECT Id, Network__c FROM Article__c WHERE Id = :queryCase.ArticleTest__c];
        conRec.Network__c = networkRec.Id;
        update conRec;
        
        Depot_Area__c depotArea = new Depot_Area__c(Name = 'Operations', Area__c = 'Operations', Depot__c = networkRec.Id, Used_for_Tasking__c = true);
        insert depotArea;
        
        Depot_Area_User__c depotAreaUser = new Depot_Area_User__c(Name = 'David Catindoy', User__c = UserInfo.getUserId(), Depot_Role__c = depotArea.Id);
        insert depotAreaUser;
        
        networkRec.Preferred_Method_of_Tasking__c = StarTrack_Constants.NETWORK_PREFMETHOFTASKING_SYSTEM;
        networkRec.System__c = true;
        update networkRec;
        
        queryCase.Network__c = networkRec.Id;
        queryCase.Enquiry_Type__c = 'Depot Collection';
        update queryCase;

        Test.setCurrentPage(Page.StarTrackCardLeftPA);
        ApexPages.currentPage().getParameters().put('id', queryCase.Id);
        Integer dayOfTheWeek = Math.mod(Date.newInstance(1900, 1, 7).daysBetween(System.today()), 7);
        Date validDate = System.today();
        if(dayOfTheWeek < 5){
            validDate += 1;
        } else{
            validDate += 3;
        }

        Test.startTest();
            StarTrackCardLeft_ControllerX ext = new StarTrackCardLeft_ControllerX();
            ext.changeEnquiryType();
            ext.caseRecord.Business_Name__c = 'StarTrack';
            ext.caseRecord.Phone__c = '0976347364';
            ext.caseRecord.Delivery_Collection_Date__c = validDate;
            ext.deliveryAddress.line1 = 'line1';
            ext.deliveryAddress.line2 = 'line2';
            ext.deliveryAddress.city = 'city';
            ext.deliveryAddress.state = 'state';
            ext.deliveryAddress.postcode = 'postcode';
            ext.updateCase();
            ext.caseRecord.Enquiry_Type__c = 'Redirection';
            ext.createChildRecord();
        Test.stopTest();

        System.assert(![SELECT Id FROM Task WHERE CaseObject__c =: queryCase.Id LIMIT 1].isEmpty());
        
    }
}