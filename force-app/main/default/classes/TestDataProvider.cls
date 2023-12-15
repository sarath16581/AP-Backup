/**************************************************
Type:       Utility class to create test data
Purpose:    Defines convenient methods to create test data for the test classes

History:
--------------------------------------------------
17.01.2014  Mohamed.Atheek@bluewolf.com  Created
09.07.2015  Eric.Shen@auspost.com.au     Change  oppy.StageName = 'Identify';
24-08-2015 Fahad.Akhtar@cloudsherpas.com Added methods for custom settings data creation and case creation.
13-10-2015 david.catindoy@cloudsherpas.com Added additional methods for creating test data
01.06.2016  Andrew Judd (salesforce.com) Change createTestAccount to set Record Type to Organisation
012.09.2018 Clin D'Silva                 Added function createEventMessageAttachments
04.01.2019 disha.kariya@auspost.com.au   Added Create Assets Methods
11-12-2019 arjun.singh@auspost.com.au    Added a new method for new version of EDD Integration   
02-09-2020 seth.heang@auspost.com.au    STP-1227 Added Phone attribute on createLead() to pass 'Phone_Or_Mobile_Required' Validation Rule   
*************************************************/

@isTest
public class TestDataProvider
{
    public static Boolean preventTrigger = false;
    public static Integer httpStatus = 200;
    static CaseUtilForTest innerCaseUtilForTest;
    public static CaseUtilForTest CaseUtil {
        get{
            if(innerCaseUtilForTest == null)
                innerCaseUtilForTest = new CaseUtilForTest();

            return innerCaseUtilForTest;
        }
    }

    public class CaseUtilForTest {
        public final string BOB_THE_BUILDER = 'Is cool!';

        public string caseId {
            get{
                string result = null;
                // get the sample caseId and set it....
                return result;
            }
        }

        public Case newCase(string subject){
            Case result = null;
            // create and set values to case...
            return result;
        }
    }

    public static Account createBusinessAccount()
    {
        return createBusinessAccount('BusAcc', null);
    }

    public static Account createBusinessAccount(String name, String recordTypeName)
    {
        Account a = new Account();
        a.Name = name;
        RecordType rt = RecordTypes.getRecordTypeByName(recordTypeName, 'Account');
        if (rt != null)
        {
            a.RecordTypeId = rt.Id;
        }
        return a;
    }

    public static Account createAndSaveBusinessAccount()
    {
        return createAndSaveBusinessAccount('BusAcc', null);
    }

    public static Account createAndSaveBusinessAccount(String name, String recordTypeName)
    {
        Account a = createBusinessAccount(name, recordTypeName);
        insert a;
        return a;
    }

    public static Account createPersonAccount()
    {
        return createPersonAccount('PersAcc', null);
    }

    public static Account createPersonAccount(String name) {
        return createPersonAccount(name, null);
    }

    public static Account createPersonAccount(String name, String recordTypeName)
    {
        Account a = new Account();
        a.FirstName = 'First' + name;
        a.LastName = 'Last' + name;
        a.BillingCity = 'Melbourne';
        a.BillingState = 'VIC';
        a.BillingStreet = '673 bourke street';
        a.BillingPostalCode = '3000';
        a.PersonMailingStreet = 'test address';
        a.PersonMailingPostalCode  = '3000';
        RecordType rt = RecordTypes.getRecordTypeByName(recordTypeName, 'Account');
        if (rt != null)
        {
            a.RecordTypeId = rt.Id;
        }
        return a;
    }

    public static Account createAndSavePersonAccount()
    {
        return createAndSavePersonAccount('PersAcc', null);
    }

    public static Account createAndSavePersonAccount(String name, String recordTypeName)
    {
        Account a = createPersonAccount(name, recordTypeName);
        insert a;
        return a;
    }

    public static Contact createContact()
    {
        Account a = createAndSaveBusinessAccount();
        return createContact('Cont', a.Id, null);
    }

    public static Contact createContact(String name, Id accountId, String recordTypeName)
    {
        Contact c = new Contact();
        c.FirstName = 'First' + name;
        c.LastName = 'Last' + name;
        c.MailingCity = 'Melbourne';
        c.MailingState = 'VIC';
        c.MailingStreet = '673 bourke street';
        c.MailingPostalCode = '3000';
        c.Email = 'example@email.com';
        RecordType rt = RecordTypes.getRecordTypeByName(recordTypeName, 'Contact');
        if (rt != null)
        {
            c.RecordTypeId = rt.Id;
        }
        c.AccountId = accountId;
        return c;
    }

    public static Contact createAndSaveContact()
    {
        Account a = createAndSaveBusinessAccount();
        return createAndSaveContact('Cont', a.Id, null);
    }

    public static Contact createAndSaveContact(String name, Id accountId, String recordTypeName)
    {
        Contact c = createContact(name, accountId, recordTypeName);
        insert c;
        return c;
    }

    public static Case createCase()
    {
        return createCase('subject', 'description', null);
    }

    public static Case createCase(String subject, String description, String recordTypeName)
    {
        // Requires population, used in CaseTrigger
        list<Case_Entitlement_Status__c> list_ces = [SELECT Id
                                                     FROM Case_Entitlement_Status__c
                                                     WHERE Internal__c='In Progress,Awaiting Information'
                                                     OR Facility__c='Awaiting Facility Response'
                                                     OR Customer__c='Awaiting Customer Response'];
        if(list_ces != null && list_ces.size() == 0) {
            Case_Entitlement_Status__c ces = new Case_Entitlement_Status__c(name='test',
                                                                        Internal__c='In Progress,Awaiting Information',
                                                                        Facility__c='Awaiting Facility Response',
                                                                        Customer__c='Awaiting Customer Response');
            insert ces;
        }

        /*
        //18/06/2015: Commented this block as it is not used and causing SOQL limit errors in the test code
        Account a = createAndSaveBusinessAccount();

        Entitlement e = new Entitlement(name='Standard Entitlement', accountid=a.Id);
        insert e;
        */

        Case c = new Case();
        c.Subject = subject;
        c.Description = description;
        c.Type='Fax';
        RecordType rt = RecordTypes.getRecordTypeByName(recordTypeName, 'Case');
        if (rt != null)
        {
            c.RecordTypeId = rt.Id;
        }

        return c;
    }

    public static Case createAndSaveCase()
    {
        return createAndSaveCase('subject', 'description', null);
    }

    public static Case createAndSaveCase(String subject, String description, String recordTypeName)
    {
        Case c = createCase(subject, description, recordTypeName);
        insert c;
        return c;
    }

    public static QuickReference__c createQuickReference(String name, String url, Decimal sortOrder, String recordTypeName)
    {
        QuickReference__c qr = new QuickReference__c();
        qr.Name = name;
        qr.FullHyperlink__c = url;
        qr.SortOrder__c = sortOrder;
        RecordType rt = RecordTypes.getRecordTypeByName(recordTypeName, 'QuickReference__c');
        if (rt != null)
        {
            qr.RecordTypeId = rt.Id;
        }
        return qr;
    }

    public static QuickReference__c createAndSaveQuickReference(String name, String url, Decimal sortOrder, String recordTypeName)
    {
        QuickReference__c qr = createQuickReference(name, url, sortOrder, recordTypeName);
        insert qr;
        return qr;
    }

    public static Attachment createAttachment(String name, Id parentId, Blob body)
    {
        Attachment a = new Attachment();
        a.Name = name;
        a.ParentId = parentId;
        a.Body = body;
        return a;
    }

    public static Attachment createAndSaveAttachment(String name, Id parentId, Blob body)
    {
        Attachment a = createAttachment(name, parentId, body);
        insert a;
        return a;
    }

    public static Task createTask(Id relateTo, Id whoId, String recordTypeName)
    {
        Task t = new Task();
        RecordType rt = RecordTypes.getRecordTypeByName(recordTypeName, 'Task');
        if (rt != null)
        {
            t.RecordTypeId = rt.Id;
        }
        t.OwnerId = UserInfo.getUserId();
        t.WhatId = relateTo;
        t.WhoId = whoId;
        return t;
    }

    public static Event createEvent(Id relateTo, Id whoId, String recordTypeName) {
        Event e = new Event();
        RecordType rt = RecordTypes.getRecordTypeByName(recordTypeName, 'Event');
        if (rt != null)
        {
            e.RecordTypeId = rt.Id;
        }
        e.OwnerId = UserInfo.getUserId();
        e.WhatId = relateTo;
        e.WhoId = whoId;
        return e;
    }

    public static Task createAndSaveTask(Id relateTo, Id whoId, String recordTypeName)
    {
        Task t = createTask(relateTo, whoId, recordTypeName);
        insert t;
        return t;
    }

    public static AusPostSettings__c createAusPostSettings()
    {
        return createAusPostSettings('ABC', 'AddressValidation');
    }

    public static AusPostSettings__c createAusPostSettings(String token, String name)
    {
        AusPostSettings__c s = new AusPostSettings__c();
        s.Token__c = token;
        s.Name= name;
        return s;
    }

    public static AusPostSettings__c createAndSaveAusPostSettings()
    {
        return createAndSaveAusPostSettings('ABC', 'AddressValidation');
    }

    public static AusPostSettings__c createAndSaveAusPostSettings(String token, String name)
    {
        AusPostSettings__c s = createAusPostSettings(token, name);
        insert s;
        return s;
    }
    //Start : added by Frank 2014/06/20
    public static User createTestUsers() {
        User u = new User();
        u.FirstName ='First';
        u.LastName = 'Tester';
        u.Alias = 'mtst121';
        u.Email = 'mtester121@ItbTestcompany.com';
        u.Username = u.Email;
        u.CommunityNickname = u.Alias;
        u.ProfileId = [select Id
                        from Profile
                        where Name = 'System Administrator' or Name = 'SystemAdministrator'][0].Id;
        u.TimeZoneSidKey = 'America/Chicago';
        u.LocaleSidKey = 'en_US';
        u.EmailEncodingKey = 'UTF-8';
        u.LanguageLocaleKey = 'en_US';
        return u;
    }
    public static MiniCaseFieldMapping__c createTestMiniCaseFieldMapping() {
        MiniCaseFieldMapping__c mcfm = new MiniCaseFieldMapping__c();
        mcfm.Type__c = 'Feedback';
        mcfm.ProductSubcategory__c = 'New';
        mcfm.ProductCategory__c = 'New2';
        return mcfm;
    }

    public static id getRecordIdWithDevName(string devName){
        id result = null;
        for(RecordType t: [select id,developerName,name from RecordType where SObjectType='Case']){
            if(t.DeveloperName == devName){
                result = t.id;
                break;
            }
        }
        return result;
    }

    public static Case createTestCase() {
        Case case1 = new Case();
        case1.RecordTypeId = getRecordIdWithDevName('Sales_Manager_Review_Exception');
        case1.Type = 'Feedback';
        case1.Subject = 'Newsdd';
        case1.Status = 'New';
        case1.ProductCategory__c = 'Travel & ID';
        case1.EnquirySubType__c = 'Product Support';
        case1.ProductSubCategory__c = 'KeyPass';
        return case1;
    }
    public static Opp_Product_Classification__c createTestOpp_Product_Classification() {
        Opp_Product_Classification__c opc = new Opp_Product_Classification__c();
        return opc;
    }
    public static Account createTestAccount() {
        RecordType organizationRecType = RecordTypes.getRecordTypeByName('Organisation', 'Account');
        Account acc = new Account();
        acc.Name = 'dfde';
        acc.RecordTypeId = organizationRecType.id;
        return acc;
    }
    public static Contact createTestContact() {
        Contact con = new Contact();
        con.LastName = 'dsf';
        con.Function_Group__c = 'Accountant';
        con.MailingCity = 'de';
        con.MailingState = '1';
        con.MailingStreet = '21';
        con.MailingPostalCode = '3200';
        con.Email = 'dsf@df.com';
        con.FirstName = 's';
        return con;
    }
    public static Opportunity createTestOpportunity() {
        Opportunity oppy = new Opportunity();
        oppy.Name = 'dfe';
        oppy.Type = 'New Customer';
        oppy.Offering_Type__c = 'Product';
        oppy.StageName = 'Identify';
        oppy.CloseDate = date.today();
        return oppy;
    }
    public static AusPostSettings__c createTestAusPostSettings1() {
        AusPostSettings__c oa= new AusPostSettings__c();
        for(AusPostSettings__c oa1 : [select Token__c,URL2__c,URL3__c from AusPostSettings__c where Name = 'AddressValidation' limit 1]){
            oa = oa1;
        }
        if(oa.Id == null){
            oa.Token__c = 'f34a0822-4cf1-41cd-90d6-b46b30d7f331';
            oa.URL2__c = 'https://digitalapi-ptest.npe.auspost.com.au/qac/address';
            oa.URL3__c = 'https://digitalapi-ptest.npe.auspost.com.au/qac/details';
            oa.Name = 'AddressValidation';
            insert oa;
        }
        return oa;
    }
    public static AusPostSettings__c createTestAusPostSettings2() {
        AusPostSettings__c oa= new AusPostSettings__c();
        for(AusPostSettings__c oa1 : [select ApplicationName__c,AppKey__c,ServiceName__c,TokenDuration__c,Username__c,Password__c,Token__c,URL__c,URL2__c,URL3__c from AusPostSettings__c where Name = 'AddressValidation' limit 1]){
            oa = oa1;
        }
        if(oa.Id == null){
            oa.Password__c = 'w@X2mb?SbMi%';
            oa.Username__c = 'sssw_sts';
            oa.Token__c = 'f34a0822-4cf1-41cd-90d6-b46b30d7f331';
            oa.URL__c = 'https://digitalapi-ptest.npe.auspost.com.au/auth/token';
            oa.URL2__c = 'https://digitalapi-ptest.npe.auspost.com.au/qac/address';
            oa.URL3__c = 'https://digitalapi-ptest.npe.auspost.com.au/qac/details';
            oa.Name = 'AddressValidation';
            oa.ApplicationName__c = 'postMobile';
            oa.AppKey__c = 'b23a6687-5d9b-456c-9532-dc406662f7b4';
            oa.ServiceName__c = 'QAC';
            oa.TokenDuration__c = '84600';
            insert oa;
        }
        return oa;
    }
    public static AusPostSettings__c createTestAusPostSettings3() {
        AusPostSettings__c oa= new AusPostSettings__c();
        for(AusPostSettings__c oa1 : [select ApplicationName__c,AppKey__c,ServiceName__c,TokenDuration__c,Username__c,Password__c,Token__c,URL__c,URL2__c,URL3__c from AusPostSettings__c where Name = 'EstimatedDeliveryDate' limit 1]){
            oa = oa1;
        }
        if(oa.Id == null){
            oa.Password__c = 'Welcome@123';
            oa.Username__c = 'dt_user';
            oa.URL__c = 'https://digitalapi-ptest.npe.auspost.com.au/delivery-times/v1/domestic/sent-on.json';
            oa.Name = 'EstimatedDeliveryDate';
            insert oa;
        }
        return oa;
    }
    public static FillInboxSettings__c createTestFillInboxSettings() {
        FillInboxSettings__c oa= new FillInboxSettings__c();
        for(FillInboxSettings__c oa1 : [SELECT Name,  CommaSeparatedStatus__c FROM FillInboxSettings__c where Name = '00B30000008IdcD' limit 1]){
            oa = oa1;
        }
        if(oa.Id == null){
            oa.Name = '00B30000008IdcD';
            oa.CommaSeparatedStatus__c = 'On Hold';
            insert oa;
        }
        return oa;
    }
    public static ExpectedResponseQueueManagement__c createTestExpectedResponseQueueManagement() {
        ExpectedResponseQueueManagement__c oa= new ExpectedResponseQueueManagement__c();
        for(ExpectedResponseQueueManagement__c oa1 : [SELECT Name, QueueID__c FROM ExpectedResponseQueueManagement__c where Name = 'Awaiting Customer Response' limit 1]){
            oa = oa1;
        }
        if(oa.Id == null){
            oa.Name = 'Awaiting Customer Response';
            oa.QueueID__c = [SELECT Id FROM Group WHERE Name = 'SSSW Awaiting Customer' LIMIT 1].Id;
            insert oa;
        }
        return oa;
    }
    public static FieldValueImageSettings__c createTestFieldValueImageSettings() {
        FieldValueImageSettings__c oa= new FieldValueImageSettings__c();
        for(FieldValueImageSettings__c oa1 : [SELECT CommaSeparatedFieldNames__c,Name FROM FieldValueImageSettings__c where Name = 'Contact' limit 1]){
            oa = oa1;
        }
        if(oa.Id == null){
            oa.Name = 'Contact';
            oa.CommaSeparatedFieldNames__c = 'Name';
            insert oa;
        }
        return oa;
    }
    public static AllowedFaxAttachmentFiles__c createTestAllowedFaxAttachmentFiles() {
        AllowedFaxAttachmentFiles__c oa= new AllowedFaxAttachmentFiles__c();
        for(AllowedFaxAttachmentFiles__c oa1 : [SELECT  CreatedDate, Name FROM AllowedFaxAttachmentFiles__c where Name = 'pdf' limit 1]){
            oa = oa1;
        }
        if(oa.Id == null){
            oa.Name = 'pdf';
            //oa.CreatedDate = date.today();
            insert oa;
        }
        return oa;
    }
    public static CaseMassUploadFieldMappingSettings__c createTestCaseMassUploadFieldMappingSettings1() {
        CaseMassUploadFieldMappingSettings__c oa= new CaseMassUploadFieldMappingSettings__c();
        for(CaseMassUploadFieldMappingSettings__c oa1 : [SELECT DataType__c, Name,SFDCFieldAPIName__c FROM CaseMassUploadFieldMappingSettings__c where Name = 'Content of Parcel' limit 1]){
            oa = oa1;
        }
        if(oa.Id == null){
            oa.Name = 'Content of Parcel';
            oa.DataType__c = 'Text';
            oa.SFDCFieldAPIName__c = 'Subject';
            insert oa;
        }
        return oa;
    }
    public static CaseMassUploadFieldMappingSettings__c createTestCaseMassUploadFieldMappingSettings2() {
        CaseMassUploadFieldMappingSettings__c oa= new CaseMassUploadFieldMappingSettings__c();
        for(CaseMassUploadFieldMappingSettings__c oa1 : [SELECT DataType__c, Name,SFDCFieldAPIName__c FROM CaseMassUploadFieldMappingSettings__c where Name = 'xxx' limit 1]){
            oa = oa1;
        }
        if(oa.Id == null){
            oa.Name = 'xxx';
            oa.DataType__c = 'Number';
            oa.SFDCFieldAPIName__c = 'ArticleWeight__c';
            insert oa;
        }
        return oa;
    }
    public static Fax__c createTestFax() {
        Fax__c fax = new Fax__c();
        fax.Name = 'ff';
        return fax;
    }
    public static StatusTracking__c createTestStatusTracking() {
        StatusTracking__c st = new StatusTracking__c();
        st.Name = 'dfe';
        return st;
    }
    public static Network__c createTestNetwork() {
        Network__c nw = new Network__c();
        nw.Name = 'NNNDD';
        return nw;
    }
    public static Article__c createTestArticle() {
        Article__c art = new Article__c();
        art.ArticleLodgementDate__c = date.today();
        art.SenderPostcode__c = '123';
        art.ReceiverPostcode__c = '3002';
        art.ArticleType__c = 'Regular Parcel';
        return art;
    }

    public static List<sobject> createStartrackErrorMessagesData(){
        // Load the test consignment search records are created from the static resource
        List<StarTrack_Error_Messages__c> ls = Test.loadData(StarTrack_Error_Messages__c.sObjectType, 'StarTrackErrorMessagesCustomSettingData');
        return ls;
    }


    public static List<sobject> createConsignmentCustomSettings(){
        // Load the test consignment search records are created from the static resource
        List<Consignment_Search_Settings__c> ls = Test.loadData(Consignment_Search_Settings__c.sObjectType, 'StarTrackConsignmentSearchTestData');
        return ls;
    }

    public static list<case> createCases(string subject, Integer count, list<Article__c> lst_article){
        List<case> lst_cases = new List<case>();
        for(integer i = 0; i < count; i++){
            case c =  new case();
            c.subject = subject + ' ' + i;
            //c.ArticleTest__c = lst_article[(math.random() * lst_article.size()).intValue()].id;
            c.ArticleTest__c = lst_article[i].id;
            c.Call_Purpose__c = 'Other';
            lst_cases.add(c);
        }
        return lst_cases;
    }

    public static list<Article__c> createArticle(string subject, Integer count, list<Billing_Account__c> lst_BillingAccount){
        List<Article__c> lst_article = new List<Article__c>();
        for(integer i = 0; i < count; i++){
            Article__c a =  new Article__c();
            a.name = String.ValueOf(100 + i);
            a.Barcode__c = a.name + i;
            Date lastWeek = Date.today() - 7;
            a.Last_Scan_Event__c = Datetime.newInstance(lastWeek.year(), lastWeek.month(), lastWeek.day());
            a.Receiver_Suburb__c = 'TestSuburb';
            lst_article.add(a);
        }
        return lst_article;
    }

    public static list<Billing_Account__c> createBillingAccount(string subject, Integer count, list<Account> lst_Organisation){
        List<Billing_Account__c> lst_billingaccount = new List<Billing_Account__c>();
        for(integer i = 0; i < count; i++){
            Billing_Account__c ba =  new Billing_Account__c();
            ba.name = String.ValueOf(100 + i);
            System.debug('**  List Organisation__c ' + lst_Organisation.size());
            System.debug('** Index Number ' +(math.random() * lst_Organisation.size()).intValue());
            ba.Organisation__c = lst_Organisation[(math.random() * lst_Organisation.size()).intValue()].id;
            lst_billingaccount.add(ba);
        }
        return lst_billingaccount;
    }

    public static list<Account> createAccount(string name, Integer count){

        RecordType rt = RecordTypes.getRecordTypeByName('Organisation', 'Account');
        List<Account> lst_account = new List<Account>();

        for(integer i = 0; i < count; i++){
            Account a = new Account();
            a.Name = name + '' +  i;
            a.RecordTypeId = rt.Id;
            a.Legacy_Id__c = String.ValueOf(60000000 + i);
            lst_account.add(a);
        }
        return lst_account;
    }

    public static list<Network__c> createNetwork (string name, integer count){
        List<Network__c> lst_network = new List<Network__c>();

        for(integer i = 0; i < count; i++){
            Network__c a = new Network__c();
            a.Name = name + '' +  i;
            lst_network.add(a);
        }
        return lst_network;
    }

    public static Postcode__c createTestPostCode(){
        Postcode__c postCode = new Postcode__c();
        postCode.Name = '1220';
        postCode.Suburb__c = 'Cambridge';
        postCode.State__c = 'VIC';
        return postCode;
    }

    public static PostcodeMapping__c createTestPostCodeMapping(){
        PostcodeMapping__c postCodeMap = new PostcodeMapping__c();
        postCodeMap.Run_Dock__c = '143';
        return postCodeMap;
    }

    public static List<EventMessage__c> createEventMessages(Integer count, Article__c parentCon, String eventType){
        List<EventMessage__c> listOfEvents = new List<EventMessage__c>();
        for(Integer i=0; i<count; i++){
            listOfEvents.add(new EventMessage__c(ActualDateTime__c = System.now(), StatusText__c = 'Valid', Facility__c = parentCon.Network__c, EventType__c = eventType, Article__c = parentCon.Id));
        }

        return listOfEvents;
    }

    public static List<Event_Message_Attachment__c> createEventMessageAttachments(Integer count, string EventMessageId){
        List<Event_Message_Attachment__c> listOfEventAtts = new List<Event_Message_Attachment__c>();
        for(Integer i=0; i<count; i++){
            listOfEventAtts.add(new Event_Message_Attachment__c(EventMessage__c = EventMessageId,Msg_Description__c='ImageGuid' + i + '.jpg',Msg_Name__c='ImageGuid' + i  ));
        }

        return listOfEventAtts;
    }


    public static List<Disputed_Item__c> createDisputedItem(Integer count, string CaseId){
        List<Disputed_Item__c> listOfDispItem = new List<Disputed_Item__c>();
        date dt = date.today();
        for(Integer i=0; i<count; i++){
            listOfDispItem.add(new Disputed_Item__c(Service_Date__c = dt , Case__c = CaseId ));
        }

        return listOfDispItem;
    }

    //1-Jun-Eric Shen add create lead
    //02-09-2020 STP-1227 Add Phone attribute to pass 'Phone_Or_Mobile_Required' Validation Rule
    public static Lead createLead( String recordTypeName)
    {

        Lead testLead1 = new Lead(
                Company = 'oracle',
                LastName='Ellison',
                FirstName='Larry',
                Email='le@oracle.com',
                Street='Street',
                City='City',
                State='State',
                Country='Country',
                PostalCode='1234',
                Parcels_per_week__c='1-9',
                Status='Not Verified',
                Lead_Seeker__c=True,
                LeadSource='Snap It',
                Lead_Creator_Phone__c ='1234567',
            	Phone='0410203040'
        );

        RecordType rt = RecordTypes.getRecordTypeByName(recordTypeName, 'Lead');
        if (rt != null)
        {
            testLead1.RecordTypeId = rt.Id;
        }

        // insert testLead1;
        return testLead1;
    }

    //End

    //4 Jan Disha Added below methods
    public static Asset createAssets(String name, Id accountId, String recordTypeName)
    {
        Asset a = new Asset();
        a.Name = name;
        //a.contactId = contactId;
        a.accountId = accountId;
        a.installDate = System.today();
        RecordType rt = RecordTypes.getRecordTypeByName(recordTypeName, 'Asset');
        if (rt != null)
        {
            //a.recordTypeId = rt.id;
        }
        return a;
    }

    public static Asset createAndSaveAssets(String name, Id accountId, String recordTypeName)
    {
        Asset a = createAssets(name, accountId, recordTypeName);
        insert a;
        return a;
    }
    public static AusPostSettings__c createTestAusPostSettingsV2() {
        AusPostSettings__c oa= new AusPostSettings__c();
        for(AusPostSettings__c oa1 : [select ApplicationName__c,AppKey__c,ServiceName__c,TokenDuration__c,Username__c,Password__c,Token__c,URL__c,URL2__c,URL3__c from AusPostSettings__c where Name = 'EstimatedDeliveryDateV2' limit 1]){
            oa = oa1;
        }
        if(oa.Id == null){
            oa.AppKey__c = 'AnyValue';
            oa.URL__c = 'https://digitalapi.auspost.com.au/postage/v4/catalogue/service.json';
            oa.Name = 'EstimatedDeliveryDateV2';
            insert oa;
        }
        return oa;
    }
}