/**
* @author       : arjun.singh@auspost.com.au
* @date         : 23/03/2020
* @description  : Test class for MyNetworkCaseListController
*/
/*******************************  History ************************************************
 * 19-06-2020 Hara Sahoo Added test method for myNetworkupdatePrintedCaseFlag
 * 12-08-2020 Disha Kariya Updated http mock for AME API
 * ***************************************************************************************/
@isTest
 private  class MyNetworkCaseListControllerTest {
    // Constants
    private static final String ADMIN_PROFILE = 'System Administrator';
    private static final String SSSW_MYNETWORK_PROFILE = 'MyNetwork Portal';
    private static final Profile prof = [SELECT Id,Name FROM profile where Name =: SSSW_MYNETWORK_PROFILE LIMIT 1];
    private static final Profile adminProfile = [SELECT Id,Name FROM profile where Name =: ADMIN_PROFILE LIMIT 1];
    private static final CaseTeamRole cTeamRorl = [Select Id from CaseTeamRole LIMIT 1] ;
    private static final UserRole portalUserRole = [Select id from UserRole where developerName='SSSW_Facility_Manager_VIC'];
    private static final UserRole adminUserRole = [Select id from UserRole where developerName='CEO_EGM'];
    private static User myNetworkUser;
    @testSetup
    static void testDateCreation() {
        //Get Event Message Type based on category
        Map<String, List<EventMessageTypeMapping__mdt>> eventMessageType = EventMessageUtil.getEventMessageTypesByCategory();
        //insert standard entitlement
        Account at = new Account(Name=SSSWConstants.ENTITLEMENT_ACC);
        insert at;
        Entitlement ent = new Entitlement(AccountId = at.Id, Name='Standard Entitlement');
        insert ent;

        String oId = [Select Id,Name from Group where Name='SSSW Network Queue' and type = 'Queue' limit 1].Id;

        //insert article with Account's APCN
        list<Article__c> articleList = new list<Article__c>();
        Article__c testArticle1 = new Article__c();
        testArticle1.Name = 'testArticle1';
        testArticle1.ArticleID__c = 'testArticle1';
        testArticle1.ArticleLodgementDate__c = Date.today();
        testArticle1.ReceiverAddressLine1__c = '300 bourke street';
        testArticle1.SenderPostcode__c = '3000';
        testArticle1.ReceiverPostcode__c = '3006';
        testArticle1.ReceiverCity__c = 'Melbourne';
        testArticle1.ArticleType__c = 'Regular Parcel';
        testArticle1.Receiver_APCN__c = 'abcd1234';
        articleList.add(testArticle1);

        Article__c testArticle2 = new Article__c();
        testArticle2.Name = 'testArticle2';
        testArticle2.ArticleID__c = 'testArticle2';
        testArticle2.ArticleLodgementDate__c = Date.today();
        testArticle2.ReceiverAddressLine1__c = '300 bourke street';
        testArticle2.SenderPostcode__c = '3000';
        testArticle2.ReceiverPostcode__c = '3006';
        testArticle2.ReceiverCity__c = 'Melbourne';
        testArticle2.ArticleType__c = 'Regular Parcel';
        testArticle2.Receiver_APCN__c = 'abcd123';
        articleList.add(testArticle2);

        insert articleList;

        //insert network
        Network__c nw = TestDataProvider.createTestNetwork();
        nw.Email__c = 'top@top.com';
        nw.Name = 'test network';
        nw.Post_Code__c = '3000';
        nw.Geolocation__Latitude__s = -32.927406;
        nw.Geolocation__Longitude__s = 151.62805;
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
        System.runAs(new user(ID = UserInfo.getUserID())){
            myNetworkUser = TestUtility.createUser('lTest', prof.Id, portalUserRole.Id);
            insert myNetworkUser;
        }
        user uRecr = [Select id, profile.name from user where id=:myNetworkUser.Id];
        System.debug('uRecr>>>'+uRecr);
        //insert Case
        list<case> cList = new list<case>();
        Map<String,Schema.RecordTypeInfo> caseRecTypeMap = Schema.Sobjecttype.Case.getRecordTypeInfosByName();
        Case csRec = TestUtility.createCase('Enquiry','In Progress','Investigation',acc.Id,con.Id,
                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
        csRec.ArticleTest__c = testArticle2.Id;
        csRec.ReferenceId__c ='testArticle2';
        csRec.Status = 'Awaiting Network Response';
        csRec.Address2__c = '100 Bourke Street Melbourne 3000';
        csRec.Network__c = nw.id;
        csRec.Type = 'Investigation';
        csRec.CaseOriginator__c = 'Addressee';
        csRec.Checkbox__c = true;
        csRec.PONUser__c = myNetworkUser.Id;
        csRec.OwnerId = [Select Id,Name from Group where Name='SSSW Network Queue' and type = 'Queue' limit 1].Id;
        cList.add(csRec);
        Case csRecord = TestUtility.createCase('Enquiry','In Progress','Investigation',acc.Id,con.Id,
                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
        csRecord.ArticleTest__c = testArticle1.Id;
        csRecord.ReferenceId__c ='testArticle1';
        csRecord.Status = 'Awaiting Network Response';
        csRecord.Network__c = nw.id;
       // csRecord.PONUser__c = userinfo.getuserid();
        csRecord.Type = 'Investigation';
        csRecord.CaseOriginator__c = 'Addressee';
        csRecord.Checkbox__c = true;  
        csRecord.Priority = 'High';       
        csRecord.Root_cause__c = 'Awaiting Network Response';
        csRecord.OwnerId = [Select Id,Name from Group where Name='SSSW Network Queue' and type = 'Queue' limit 1].Id;
        cList.add(csRecord);

        Case csRecord1 = TestUtility.createCase('Enquiry','In Progress','Investigation',acc.Id,con.Id,
                caseRecTypeMap.get('SSSW Delivery').getRecordTypeId());
        csRecord1.ArticleTest__c = testArticle1.Id;
        csRecord1.ReferenceId__c ='testArticle1';
        csRecord1.Status = 'Awaiting Network Response';
        csRecord1.Network__c = nw.id;
        //csRecord1.PONUser__c = userinfo.getuserid();
        csRecord1.Type = 'Feedback';
        csRecord1.CaseOriginator__c = 'Addressee';
        csRecord1.Checkbox__c = false;       
        csRecord1.Root_cause__c = 'Awaiting Network Response';
        csRecord1.OwnerId = userinfo.getuserid();
        cList.add(csRecord1);
        Database.insert(cList);
        System.debug('cList>>>>>>>>'+cList);

        List<CaseTeamMember> ctmList = new List<CaseTeamMember>();
        CaseTeamMember ctm = new CaseTeamMember(ParentId = csRec.id,MemberId = userinfo.getuserid(),TeamRoleId = cTeamRorl.Id);
        CaseTeamMember ctm1 = new CaseTeamMember(ParentId = csRecord.id,MemberId = userinfo.getuserid(),TeamRoleId = cTeamRorl.Id);
        CaseTeamMember ctm2 = new CaseTeamMember(ParentId = csRecord1.id,MemberId = userinfo.getuserid(),TeamRoleId = cTeamRorl.Id);
        ctmList.add(ctm);
        ctmList.add(ctm1);
        ctmList.add(ctm2);
        database.insert(ctmList);

        List<EventMessage__c> eventMessages = new List<EventMessage__c>();
        EventMessage__c eventMessage = new EventMessage__c();
        eventMessage.Article__c = testArticle2.Id;
        eventMessage.EventType__c = eventMessageType.get('Delivered')[0].Label;
        eventMessage.EventGeoLocation__Longitude__s = 151.62805;
        eventMessage.EventGeoLocation__Latitude__s = -32.927406;
        eventMessages.add(eventMessage);
        //Attempted delivery event message
        EventMessage__c eventMessage1 = new EventMessage__c();
        eventMessage1.Article__c = testArticle2.Id;
        eventMessage1.EventType__c = eventMessageType.get('AttemptedDelivery')[0].Label;
        eventMessage1.EventGeoLocation__Longitude__s = 151.62805;
        eventMessage1.EventGeoLocation__Latitude__s = -32.927406;
        eventMessages.add(eventMessage1);

        insert eventMessages;

        list<Network_Response__c> nrList = new list<Network_Response__c>();
        Network_Response__c nr = new Network_Response__c();
        nr.Related_Case__c = csRec.Id;
        nrList.add(nr);
        Network_Response__c nres = new Network_Response__c();
        nres.Related_Case__c = csRecord.Id;
        nrList.add(nres);
        Network_Response__c nresRec = new Network_Response__c();
        nresRec.Related_Case__c = csRecord1.Id;
        nrList.add(nresRec);
        insert nrList;

        AusPostSettings__c setting = new AusPostSettings__c();
        setting.Name = 'AMEAddressValidation';
        setting.Token__c = 'O63igHoZbTNBIPQFRAxbjbPaMQHyoHNR';
        setting.URL2__c = 'https://digitalapi-stest.npe.auspost.com.au/ame/api/v1/address?text=';
        setting.URL3__c = 'https://digitalapi-stest.npe.auspost.com.au/ame/api/v1/dpid/' + '85865442' +'?singleLine=true&semiStructured=true&structured=true&upu=true&geo=true&delivery=true';
        insert setting;
    }
    @isTest
     static void myNetworkupdatePrintedCaseFlag()
     {
         List<Case> caseList = [SELECT Id From Case];
         List<String> caseIds = new List<String>();
         for(Case cs : caseList)
         {
             caseIds.add(cs.Id);
         }
         Test.StartTest();
         MyNetworkCaseListController.updatePrintedCaseFlag(caseIds);
         Test.StopTest();
         List<Case> casesUpdated = [SELECT Id, Checkbox__c FROM Case WHERE Id = :caseIds];
         System.assertEquals(true, casesUpdated[0].Checkbox__c, 'Printed Case flag not set to true');
     }
    @isTest
    static void myNetworkCasesMethodTest() {
        String selectedListView = 'All_Cases';
        list<MyNetworkCaseListController.myNetworkCasesWrapper> wrapperList = new list<MyNetworkCaseListController.myNetworkCasesWrapper>();
        Test.StartTest();
        wrapperList =  MyNetworkCaseListController.myNetworkCases(selectedListView);
        Test.StopTest();
        system.assert(!wrapperList.isEmpty());
    }
    @isTest
    static void myNetworkFiltersCasesMethodTest() {
        String filteredString = '{"isPrinted":"Yes","priorityVal":"High","enquirySubTypeVal":"Carding issue","addressePostcodeVal":"4000,3000","selectedProductCategoryVal":"International Parcels","selectedNetworkRecrdIdVal":"a2K0w0000008cWzEAI","selectedlistview":"All_Cases","searchButtonClicked":true,"caseNumberVal":""}';
        list<MyNetworkCaseListController.myNetworkCasesWrapper> wrapperList = new list<MyNetworkCaseListController.myNetworkCasesWrapper>();
        Test.StartTest();
        wrapperList =  MyNetworkCaseListController.getFilteredCases(filteredString);
        Test.StopTest();
        system.assert(wrapperList.isEmpty());
    }
    @isTest
    static void myNetworkFiltersAllCases() {
        String filteredString = '{"isPrinted":"","priorityVal":"--Select--","enquirySubTypeVal":"--Select--","addressePostcodeVal":"","selectedProductCategoryVal":"--Select--","selectedNetworkRecrdIdVal":"","selectedlistview":"All_Cases","searchButtonClicked":true,"caseNumberVal":""}';
        list<MyNetworkCaseListController.myNetworkCasesWrapper> wrapperList = new list<MyNetworkCaseListController.myNetworkCasesWrapper>();

        Test.StartTest();

        wrapperList =  MyNetworkCaseListController.getFilteredCases(filteredString);
        Test.StopTest();
        system.assert(!wrapperList.isEmpty());
    }
    @isTest
    static void myNetworkFiltersCasesMyCases() {
        String filteredString = '{"isPrinted":"","priorityVal":"--Select--","enquirySubTypeVal":"--Select--","addressePostcodeVal":"","selectedProductCategoryVal":"--Select--","selectedNetworkRecrdIdVal":"","selectedlistview":"My_Cases","searchButtonClicked":true,"caseNumberVal":""}';
        list<MyNetworkCaseListController.myNetworkCasesWrapper> wrapperList = new list<MyNetworkCaseListController.myNetworkCasesWrapper>();
        case cRecrd = [Select Id, PONUser__c from case where PONUser__c != null And PONUser__r.profileId=:prof.Id limit 1] ;
        User uRecrd = [Select id,name from user where Id=: cRecrd.PONUser__c];
       
        CaseTeamMember ctmem = new CaseTeamMember(ParentId = cRecrd.id,MemberId = uRecrd.Id,TeamRoleId = cTeamRorl.Id);
        insert ctmem;
        System.runAs(uRecrd){
            Test.StartTest();
            wrapperList =  MyNetworkCaseListController.getFilteredCases(filteredString);
            Test.StopTest();
            system.assert(!wrapperList.isEmpty());
        }
    }
    @isTest
    static void myNetworkAssignToselfMethodTest() {
        case cRecrd = [Select Id, PONUser__c from case where PONUser__c = null limit 1 ] ;
        User uRecrd = [Select id,name from user where lastName = 'lTest' and profileId=:prof.Id and isActive= true limit 1];
       
        CaseTeamMember ctmem = new CaseTeamMember(ParentId = cRecrd.id,MemberId = uRecrd.Id,TeamRoleId = cTeamRorl.Id);
        insert ctmem;           
        System.debug('cRecrd>>>'+cRecrd);
        String cId = '["'+ cRecrd.Id+ '"]' ;
        System.runAs(uRecrd){
            Test.StartTest();
                MyNetworkCaseListController.assignToSelf(cId);
            Test.StopTest();  
        }
        case  cRecord = [Select id , PONUser__c from Case where id =: cRecrd.Id];
        System.assertEquals(cRecord.PONUser__c, uRecrd.Id); 
    }
    @isTest
    static void myNetworkAssignToUserMethodTest() {
        case cRecrd = [Select Id, PONUser__c from case where PONUser__c = null limit 1 ] ;
        User uRecrd = [Select Id,name from user where lastName = 'lTest' and profileId=:prof.Id and isActive= true limit 1];
       
        CaseTeamMember ctmem = new CaseTeamMember(ParentId = cRecrd.id,MemberId = uRecrd.Id,TeamRoleId = cTeamRorl.Id);
        insert ctmem;
        String cId = '["'+ cRecrd.Id+ '"]' ;
        String uId =  uRecrd.Id  ;
        System.runAs(uRecrd){
            Test.StartTest();
                MyNetworkCaseListController.assignToUser(cId, uId);
            Test.StopTest();  
        }
        case  cRecord = [Select id , PONUser__c from Case where id =: cRecrd.Id];
        System.assertEquals(cRecord.PONUser__c, uRecrd.Id); 
    }
    @isTest
    static void getSafeDropInformationTest() {
        case cRecrd = [Select Id,ArticleTest__c from case where ArticleTest__r.Name = 'testArticle2' limit 1 ] ;
        
        User uRecrd = [Select Id,name from user where lastName = 'lTest' and profileId=:prof.Id and isActive= true limit 1];
       
        CaseTeamMember ctmem = new CaseTeamMember(ParentId = cRecrd.id,MemberId = uRecrd.Id,TeamRoleId = cTeamRorl.Id);
        insert ctmem;
//        Test.setMock(HttpCalloutMock.class, new AddressFromGeolocationResGenerator());
        System.debug('cRecrd>>>'+cRecrd);
        String cId =  cRecrd.Id;
        MyNetworkCaseListController.SafeLocationDetails sDetails;
        System.runAs(uRecrd){
            Test.StartTest();
            Test.setMock(HttpCalloutMock.class, new AMEAddressValidationController1_Test.WebServiceMockResponseGeo());
            sDetails = MyNetworkCaseListController.getSafeDropInformation(cId);
            Test.StopTest();  
        }
        System.assertEquals(sDetails.isValid, true, 'Valid Delivery address not found');
        System.assertEquals(sDetails.addresseeAddress.latitudeValue, String.valueOf(-37.82022851), 'Addressee latitude found from mock');
    }
    
    @isTest
    static void getMyNetworkPortalUserTst() {
        case cRecrd = [Select Id,ArticleTest__c from case where ArticleTest__r.Name = 'testArticle2' limit 1 ] ;
        User uRecrd = [Select Id,name from user where lastName = 'lTest' and profileId=:prof.Id and isActive= true limit 1];
        CaseTeamMember ctmem = new CaseTeamMember(ParentId = cRecrd.id,MemberId = uRecrd.Id,TeamRoleId = cTeamRorl.Id);
        insert ctmem;
        String searchTerm = 'lTest';
        String fieldList = 'firstName,lastName,Name';
        String sobjectName = 'User';
        String fieldsToSearch = 'firstName,lastName,Name';
        String cId =  cRecrd.Id;
        List<SObject> uRecord;
        System.runAs(uRecrd){
            Test.StartTest();
            uRecord =  MyNetworkCaseListController.getMyNetworkPortalUser(searchTerm, fieldList,  sobjectName, fieldsToSearch);
            Test.StopTest();  
        }
        System.assert(!uRecord.isEmpty()); 
    }
    @isTest
    static void getAddressFromGeoLocationForEventMeTst() {
        case cRecrd = [Select Id,ArticleTest__c from case where ArticleTest__r.Name = 'testArticle2' limit 1 ] ;
        User uRecrd = [Select Id,name from user where lastName = 'lTest' and profileId=:prof.Id and isActive= true limit 1];
        CaseTeamMember ctmem = new CaseTeamMember(ParentId = cRecrd.id,MemberId = uRecrd.Id,TeamRoleId = cTeamRorl.Id);
        insert ctmem;
        EventMessage__c evMsg = [Select id From EventMessage__c where Article__r.Name = 'testArticle2' limit 1];
//        Test.setMock(HttpCalloutMock.class, new AddressFromGeolocationResGenerator());
        System.debug('cRecrd>>>'+cRecrd);
        MyNetworkCaseListController.GeoLocationWithAddress  geoAddr;
        String cId =  cRecrd.Id;
        System.runAs(uRecrd){
            Test.StartTest();
            Test.setMock(HttpCalloutMock.class, new AMEAddressValidationController1_Test.WebServiceMockResponseGeo());
            geoAddr =  MyNetworkCaseListController.getAddressFromGeoLocationForEventMessage(evMsg.Id);
            Test.StopTest();  
        }
        System.assertEquals(geoAddr.geoLatitdue, '-32.927406', 'Latitude for the request.');
        System.assertEquals(geoAddr.addressValue, 'Test Address', 'Address found in AME');
    }
    
    @isTest
    static void myNetworkgetRelatedEventMsgMethodTest() {
        Case caseRecordVar = [Select id, ArticleTest__c from Case limit 1];
        Test.StartTest();
        MyNetworkCaseListController.getSelectedCases(string.valueOf(caseRecordVar.Id));        
        MyNetworkCaseListController.EventMessagesWithSortingDetails lEventMsg = MyNetworkCaseListController.getRelatedEventMessages(string.valueOf(caseRecordVar.Id));
        Test.StopTest();
        System.assert(!lEventMsg.eventMessageWithGeoCodeList.isEmpty());
    }
    @isTest
    static void myNetworkEnqrySubTypeTest() {
        Case caseRecordVar = [Select id, ArticleTest__c from Case limit 1];
        Test.StartTest();
        list<myNetworkPickListFieldValues__mdt> subtypeString = MyNetworkCaseListController.getpickListValues();        
        MyNetworkCaseListController.getFiltersData();
        MyNetworkCaseListController.clearCache();
        Test.StopTest();
        System.assert(!subtypeString.isEmpty());
    }

    @isTest
    static void getCaseFirstMessageTest() {
        Case caseRecordVar = [Select id, ArticleTest__c,type  from Case where ownerId=: userinfo.getuserid()  limit 1];
        
        Test.StartTest();
        list<MyNetworkCaseListController.caseMessage> cMessage = MyNetworkCaseListController.getCaseMessages(string.valueOf(caseRecordVar.Id));
        Test.StopTest();
        System.assertEquals(cMessage[0].messageString ,'This case has received further information and is now under review by the Customer Contact Centre.');
    }
}