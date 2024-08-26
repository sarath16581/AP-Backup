/**
  * @author       : Rajesh Punjabi
  * @date         : 01/06/2019
  * @description  : Test class for the MyNetwork service calls

--------------------------------------- History --------------------------------------------------
01.06.2019    Rajesh Punjabi(Mav3rik)    Created
07.02.2020    Gunith Devasurendra        REQ2086450: Add PhotoId field
17.02.2020    Gunith Devasurendra        REQ2092604: Remove null when adding Address as Case Comment when Address Line 2 is null
19.04.2023    Talib Raza				 REQ2906534: API version uplifted to 57.0
24.05.2024    Snigdha Sahu               REQ2911157 :Update to LostArticle method
**/

@IsTest (IsParallel=true)
public class MyNetworkSmartFormsService_Test {
    
    @TestSetup
    static void setup(){
        Case oCase = new Case();
        oCase.PrimaryEmail__c  = 'rajesh.punjabi@mav3rik.com';
        insert oCase;
        
        Article__c artc = new Article__c();
        artc.CID__c  = 'TEST_RKP_ART_NUMBER';
        insert artc;        
    }
    
    @isTest
    public static void getArticleId_Test() {
        
        Article__c artc = [SELECT Id, ArticleID__c FROM Article__c WHERE CID__c  = 'TEST_RKP_ART_NUMBER' LIMIT 1];
        system.debug('artc' + artc.Id);
        MyNetworkSmartFormsService smrt = new MyNetworkSmartFormsService();
        Test.startTest();
        smrt.getArticleId(artc.ArticleID__c);
        Test.stopTest();
    }
    
    @isTest
    public static void testGetProductPickListValues() {
        Test.startTest();
        Map<String, List<String>> mapOfProductPickListValues = MyNetworkSmartFormsService.getProductPickListValues();
        Test.stopTest();
    }
    
    @isTest
    public static void testGetProductPickListValuesByNames() {
        Test.startTest();
        Map<String, List<String>> mapOfProductPickListValuesByNames = MyNetworkSmartFormsService.getProductPickListValuesByNames();
        Test.stopTest();
    }
    
    @isTest
    public static void testGetTypeAndProductEnqSubTypePickListValues() {
        Test.startTest();
        Map<String, List<String>> mapOfProductEnqSubTypePickListValues = MyNetworkSmartFormsService.getTypeAndProductEnqSubTypePickListValues();
        Test.stopTest();
    }
    
    @isTest
    public static void testGetListOfNetworksForLoginUser() {
        Test.startTest();
        List<Facility_User__c> listOfFacilityUser = MyNetworkSmartFormsService.getListOfNetworksForLoginUser();
        Test.stopTest();
    }
    
    @isTest
    public static void testListOfNetworksByRecordTypes() {
        Test.startTest();
        List<Network__c> listOfNetworks = MyNetworkSmartFormsService.getListOfNetworksByRecordTypes();
        Test.stopTest();
    }
    
    @isTest
    public static void testGetSubCatValuesToDisableCompensation() {
        Test.startTest();
        Map<String, List<String>> mapOfSubCatValuesToDisableCompensation = MyNetworkSmartFormsService.getSubCatValuesToDisableCompensation();
        Test.stopTest();
    }
    
    @isTest
    public static void testGetTypeOfDamageValuesToDisableCompensation() {
        Test.startTest();
        List<String> listOfStringsToDisableCompensation = MyNetworkSmartFormsService.getTypeOfDamageValuesToDisableCompensation();
        Test.stopTest();
    }
    
    @IsTest 
    public static void createCaseComments_eParcel_Test(){
        String eParcelDamages = '{"formId":"eParcel","articleId":"ARTICLE_ID_007_TESTING","facility":"a2Kp0000000QktcEAC",   "senderName":"Winning Group Test Account",   "senderEmail":"jonathan.snelling@auspost.com.au",   "senderCompany":"WINNING GROUP TEST ACCOUNT",   "addresseeName":"PARTIAL ALLOWED",   "addresseeEmail":"sita.yarram@auspost.com.au",   "senderAddress":{"AddressLine1":"GPO Box 1777","AddressLine2":"addressLine2","City":"MELBOURNE","State":"VIC","Postcode":"3001","Countrycode":"AU"   },"senderAddressSearchTerm":"GPO Box 1777,MELBOURNE,VIC 3001,AU",   "addresseeAddress":{"AddressLine1":"ADDREE - 01","AddressLine2":"ADD - 02, ADD - 03","City":"MELBOURNE","State":"VIC","Postcode":"3000","Countrycode":"AU"},"addresseeAddressSearchTerm":"ADDREE - 01,ADD - 02,ADD - 03,MELBOURNE,VIC 3000,AU",   "damageDetails":"Details of product damage",   "damageLocation":"Location of damage within facility",   "howDamageOccured":"other",   "howDamageOccuredOptionalOther":"How the damage occurred - Others option",   "isPartOfConsignment":"yes",   "totalArticlesInConsignment":"2",   "doesContainWine":"yes",   "totalBottlesInCarton":"5",   "totalBottlesDamaged":"5",   "noOfCapsDamaged":"5",   "noOfLabelsDamaged":"5",   "isCartonAdequate":"no",   "cartonInadequecyDetails":"Carton adequate - No",   "isDividerAdequate":"no",   "dividerInadequecyDetails":"Inserts or dividers adequate - No"}';
        Case oCase = [SELECT Id FROM Case WHERE PrimaryEmail__c  = 'rajesh.punjabi@mav3rik.com'];
        MyNetworkSmartFormsWrapper caseWrapper = (MyNetworkSmartFormsWrapper) JSON.deserialize(eParcelDamages, MyNetworkSmartFormsWrapper.class);
        MyNetworkSmartFormsService smartForm = new MyNetworkSmartFormsService();
        Test.startTest();
        smartForm.createCaseComments (caseWrapper, oCase);
        Test.stopTest();
    }
    
    @IsTest 
    public static void createCaseComments_staffFeedback_Test(){
        String staffFeedback = '{ "formId":"staffFeedback",  "enquirySubType":"Staff Complaint",   "facilityOutlet":"yes",   "networkName":"Brisbane - Metro",   "networkId":"a2Kp0000000QlYcEAK" ,  "facility":"a2Kp0000000QktXEAS",   "contactId":"003p000000a42xmAAA",   "FirstName":"Sammy",   "LastName":"K",   "Name":"Sammy K",   "MobilePhone":"0435814728",   "Email":"sameed.khan@gmail.com",   "IsPersonAccount":false,   "AccountId":"001p000000kmU2sAAE",   "Account":{      "Name":"Australia Post",      "Id":"001p000000kmU2sAAE"   },   "title":"Sammy K | Australia Post",   "subtitle":"Sammy K  ·  0435814728  ·  sameed.khan@gmail.com",   "customerAddress":{      "overflow":false,      "truncated":false,      "verified":true,      "addressLine1":"121 Queens Pde",      "addressLine2":"",      "city":"Clifton Hill",      "state":"VIC",      "postcode":"3068",      "dpid":"84275529",      "countrycode":"AU"   },   "productCategory":"Domestic Parcels",   "productSubCategory":"Courier Post",   "comments":"What is the enquiry about? - details"}';
        Case oCase = [SELECT Id FROM Case WHERE PrimaryEmail__c  = 'rajesh.punjabi@mav3rik.com'];
        MyNetworkSmartFormsWrapper caseWrapper = (MyNetworkSmartFormsWrapper) JSON.deserialize(staffFeedback, MyNetworkSmartFormsWrapper.class);
        MyNetworkSmartFormsService smartForm = new MyNetworkSmartFormsService();
        Test.startTest();
        smartForm.createCaseComments (caseWrapper, oCase);
        Test.stopTest();
    }
    
    
    @IsTest 
    public static void createCase_damagedArticle(){
        String damagedArticle = '{"formId":"damagedArticle",   "articleId":"ARTICLE_ID_007_TESTING",   "facility":"a2Kp0000000QktcEAC",   "senderName":"Winning Group Test Account",   "senderEmail":"jonathan.snelling@auspost.com.au",   "senderCompany":"WINNING GROUP TEST ACCOUNT",   "addresseeName":"PARTIAL ALLOWED",   "addresseeEmail":"sita.yarram@auspost.com.au",   "senderAddress":{      "addressLine1":"GPO Box 1777",      "addressLine2":"addressLine2",      "city":"MELBOURNE",      "state":"VIC",      "postcode":"3001",      "countrycode":"AU"   },   "senderAddressSearchTerm":"GPO Box 1777,MELBOURNE,VIC 3001,AU",   "addresseeAddress":{      "addressLine1":"ADDREE - 01",      "addressLine2":"ADD - 02, ADD - 03",      "city":"MELBOURNE",      "state":"VIC",      "postcode":"3000",      "countrycode":"AU"   },   "addresseeAddressSearchTerm":"ADDREE - 01,ADD - 02,ADD - 03,MELBOURNE,VIC 3000,AU",   "caseOriginator":"Sender",   "damagedOrMissing":"Damaged",   "contactId":"003p000000a42xmAAA",   "FirstName":"Sammy",   "LastName":"K",   "Name":"Sammy K",   "MobilePhone":"0435814728",   "Email":"sameed.khan@gmail.com",   "IsPersonAccount":false,   "AccountId":"001p000000kmU2sAAE",   "Account":{      "Name":"Australia Post",      "Id":"001p000000kmU2sAAE"   },   "title":"Sammy K | Australia Post",   "subtitle":"Sammy K  ·  0435814728  ·  sameed.khan@gmail.com",   "customerAddress":{      "overflow":false,      "truncated":false,      "verified":true,      "addressLine1":"111 Bourke Rd",      "addressLine2":"Melbourne",      "city":"Clayton South",      "state":"VIC",      "postcode":"3169",      "dpid":"82911061",      "countrycode":"AU"   },   "customerAddressSearchTerm":"111 Bourke Road, CLAYTON SOUTH  VIC  3169",   "productCategory":"Domestic Letters",   "productSubCategory":"Business Letters",   "comments":"Additional comments/damage report - details",   "typeOfDamage":"Damaged after delivery",   "contents":"Description of contents - details",   "valueOfContents":"50",   "adequatelyPackaged":"no",   "compensationBeingPaid":"yes",   "compensationAmount":"30",   "postagevalue":"10"}';
        Case oCase = [SELECT Id FROM Case WHERE PrimaryEmail__c  = 'rajesh.punjabi@mav3rik.com'];
        MyNetworkSmartFormsWrapper caseWrapper = (MyNetworkSmartFormsWrapper) JSON.deserialize(damagedArticle, MyNetworkSmartFormsWrapper.class);
        MyNetworkSmartFormsService smartForm = new MyNetworkSmartFormsService();
        Test.startTest();
        smartForm.createCaseComments (caseWrapper, oCase);
        Test.stopTest();
        CaseComment comment = [SELECT Id, CommentBody FROM CaseComment WHERE ParentId = :oCase.Id ORDER BY LastModifiedDate DESC LIMIT 1];
        System.assertEquals('Damaged article or missing contents? - Damaged\nAdditional comments/damage report - Additional comments/damage report - details\nType of damage - Damaged after delivery\nDescription of contents - Description of contents - details\nValue of contents - 50\nIn your opinion, was the article adequately packaged? - no\nIs the article on hand? - null\nAre you paying compensation to the customer? - yes\nAmount compensated for contents ($) - 30\nAmount refunded for postage ($) - 10\n\n\nFirst Name - Sammy\nLast Name - K\nContact Number - 0435814728\nEmail - sameed.khan@gmail.com\nCustomer Address: - 111 Bourke Rd Melbourne Clayton South VIC 3169', comment.CommentBody);
    }
    
    @IsTest 
    public static void createCase_lostArticle (){
        String lostArticle  = '{"formId":"lostArticle", "articleId":"JDQ021778901000910903",   "facility":"a2Kp0000000QktXEAS",   "senderName":"Winning Group Test Account",   "senderEmail":"jonathan.snelling@auspost.com.au",   "senderCompany":"WINNING GROUP TEST ACCOUNT",   "addresseeName":"PARTIAL ALLOWED",   "addresseeEmail":"sita.yarram@auspost.com.au",   "senderAddress":{      "addressLine1":"GPO Box 1777",      "addressLine2":"addressLine2",      "city":"MELBOURNE",      "state":"VIC",      "postcode":"3001",      "countrycode":"AU"   },   "senderAddressSearchTerm":"GPO Box 1777,MELBOURNE,VIC 3001,AU",   "addresseeAddress":{      "addressLine1":"ADDREE - 01",      "addressLine2":"ADD - 02, ADD - 03",      "city":"MELBOURNE",      "state":"VIC",      "postcode":"3000",      "countrycode":"AU"   },   "addresseeAddressSearchTerm":"ADDREE - 01,ADD - 02,ADD - 03,MELBOURNE,VIC 3000,AU",   "contactId":"003p000000a42xmAAA",   "FirstName":"Sammy",   "LastName":"K",   "Name":"Sammy K",   "MobilePhone":"0435814728",   "Email":"sameed.khan@gmail.com",   "IsPersonAccount":false,   "AccountId":"001p000000kmU2sAAE",   "Account":{      "Name":"Australia Post",      "Id":"001p000000kmU2sAAE"   },   "title":"Sammy K | Australia Post",   "subtitle":"Sammy K  ·  0435814728  ·  sameed.khan@gmail.com",   "caseOriginator":"Sender",   "customerAddress":{      "overflow":false,      "truncated":false,      "verified":true,      "addressLine1":"111 Bourke Rd",      "addressLine2":"",      "city":"Clayton South",      "state":"VIC",      "postcode":"3169",      "dpid":"82911061",      "countrycode":"AU"   },   "customerAddressSearchTerm":"111 Bourke Road, CLAYTON SOUTH  VIC  3169",   "productCategory":"Domestic Letters",   "productSubCategory":"Business Letters",   "comments":"Additional comments - details",   "contents":"Description of contents - details",   "valueOfContents":"25",   "compensationBeingPaid":"yes",   "compensationAmount":"30",   "postagevalue":"10", "scannedDelivered":"Yes"}';
        Case oCase = [SELECT Id FROM Case WHERE PrimaryEmail__c  = 'rajesh.punjabi@mav3rik.com'];
        MyNetworkSmartFormsWrapper caseWrapper = (MyNetworkSmartFormsWrapper) JSON.deserialize(lostArticle, MyNetworkSmartFormsWrapper.class);
        MyNetworkSmartFormsService smartForm = new MyNetworkSmartFormsService();
        Test.startTest();
        smartForm.createCaseComments (caseWrapper, oCase);
        Test.stopTest();
        CaseComment comment = [SELECT Id, CommentBody FROM CaseComment WHERE ParentId = :oCase.Id ORDER BY LastModifiedDate DESC LIMIT 1];
        System.assertEquals('Additional comments - Additional comments - details\nHas the article been scanned as Delivered? - Yes\nDescription of contents - Description of contents - details\nValue of contents - 25\nAre you paying compensation to the customer? - yes\nAmount compensated for contents ($) - 30\nAmount refunded for postage ($) - 10\n\n\nFirst Name - Sammy\nLast Name - K\nContact Number - 0435814728\nEmail - sameed.khan@gmail.com\nCustomer Address: - 111 Bourke Rd Clayton South VIC 3169', comment.CommentBody);
    }
    
    @IsTest 
    public static void createCase_mailRedirect(){
        String mailRedirectHold   = '{"formId":"mailRedirectHold", "facility":"a2Kp0000000QktcEAC",   "productSubCategory":"Mail redirection",   "productCategory":"Domestic Letters",   "custRefNo":"yes",   "custRefID":"zsdfsdf",   "caseLocality":"Domestic",   "contactId":"003p000000a42xmAAA",   "FirstName":"Sammy",   "LastName":"K",   "Name":"Sammy K",   "MobilePhone":"0435814728",   "Email":"sameed.khan@gmail.com",   "IsPersonAccount":false,   "AccountId":"001p000000kmU2sAAE",   "Account":{      "Name":"Australia Post",      "Id":"001p000000kmU2sAAE"   },   "title":"Sammy K | Australia Post",   "subtitle":"Sammy K  ·  0435814728  ·  sameed.khan@gmail.com",   "customerAddress":{      "overflow":false,      "truncated":false,      "verified":true,      "addressLine1":"111 Bourke Rd",      "addressLine2":"addressLine2",      "city":"Clayton South",      "state":"VIC",      "postcode":"3169",      "dpid":"82911061",      "countrycode":"AU"   },   "customerAddressSearchTerm":"111 Bourke Road, CLAYTON SOUTH  VIC  3169",   "senderAddress":{      "overflow":false,      "truncated":false,      "verified":true,      "addressLine1":"10-12 Queen St",      "addressLine2":"",      "city":"Arncliffe",      "state":"NSW",      "postcode":"2205",      "dpid":"53690394",      "countrycode":"AU"   },   "senderAddressSearchTerm":"10-12 Queen Street, ARNCLIFFE  NSW  2205",   "addresseeAddress":{      "overflow":false,      "truncated":false,      "verified":true,      "addressLine1":"121 Kingston Av",      "addressLine2":"",      "city":"Melrose Park",      "state":"SA",      "postcode":"5039",      "dpid":"73970724",      "countrycode":"AU"   },   "addresseeAddressSearchTerm":"121 Kingston Avenue, MELROSE PARK  SA  5039",   "redirectComments":"Notes to assist with enquiry" , "hasPhotoId":"yes" }';
        Case oCase = [SELECT Id FROM Case WHERE PrimaryEmail__c  = 'rajesh.punjabi@mav3rik.com'];
        MyNetworkSmartFormsWrapper caseWrapper = (MyNetworkSmartFormsWrapper) JSON.deserialize(mailRedirectHold, MyNetworkSmartFormsWrapper.class);
        MyNetworkSmartFormsService smartForm = new MyNetworkSmartFormsService();
        Test.startTest();
        smartForm.createCaseComments (caseWrapper, oCase);
        Test.stopTest();
        CaseComment comment = [SELECT Id, CommentBody FROM CaseComment WHERE ParentId = :oCase.Id ORDER BY LastModifiedDate DESC LIMIT 1];
        System.assertEquals('Privacy check completed in store? yes\n\nNotes to assist with enquiry - Notes to assist with enquiry\n\n\nFirst Name - Sammy\nLast Name - K\nContact Number - 0435814728\nEmail - sameed.khan@gmail.com\nCustomer Address: - 111 Bourke Rd addressLine2 Clayton South VIC 3169', comment.CommentBody);
    }
    
    @IsTest 
    public static void createCase_mailHold(){
        String mailRedirectHold   = '{"formId":"mailRedirectHold", "facility":"a2Kp0000000QktXEAS",   "productSubCategory":"Mail hold",   "productCategory":"Domestic Parcels",   "custRefNo":"yes",   "custRefID":"asdasda",   "caseLocality":"International",   "contactId":"003p000000a42xmAAA",   "FirstName":"Sammy",   "LastName":"K",   "Name":"Sammy K",   "MobilePhone":"0435814728",   "Email":"sameed.khan@gmail.com",   "IsPersonAccount":false,   "AccountId":"001p000000kmU2sAAE",   "Account":{      "Name":"Australia Post",      "Id":"001p000000kmU2sAAE"   },   "title":"Sammy K | Australia Post",   "subtitle":"Sammy K  ·  0435814728  ·  sameed.khan@gmail.com",   "customerAddress":{      "overflow":false,      "truncated":false,      "verified":true,      "addressLine1":"111 Bourke St",      "addressLine2":"addressLine2",      "city":"Dubbo",      "state":"NSW",      "postcode":"2830",      "dpid":"69817414",      "countrycode":"AU"   },   "customerAddressSearchTerm":"111 Bourke Street, DUBBO  NSW  2830",   "addresseeAddress":{      "overflow":false,      "truncated":false,      "verified":true,      "addressLine1":"121 Kingston Dr",      "addressLine2":"",      "city":"Australind",      "state":"WA",      "postcode":"6233",      "dpid":"53637141",      "countrycode":"AU"   },   "addresseeAddressSearchTerm":"121 Kingston Drive, AUSTRALIND  WA  6233",   "mailholdComments":"Notes to assist with enquiry - details"}';
        Case oCase = [SELECT Id FROM Case WHERE PrimaryEmail__c  = 'rajesh.punjabi@mav3rik.com'];
        MyNetworkSmartFormsWrapper caseWrapper = (MyNetworkSmartFormsWrapper) JSON.deserialize(mailRedirectHold, MyNetworkSmartFormsWrapper.class);
        MyNetworkSmartFormsService smartForm = new MyNetworkSmartFormsService();
        Test.startTest();
        smartForm.createCaseComments (caseWrapper, oCase);
        Test.stopTest();
    }
    
    @IsTest 
    public static void createCase_deliveryConcern(){
        String deliveryConcern   = '{"formId":"deliveryConcern", "articleId":"JDQ021778901000910903",   "facility":"a2Kp0000000QktcEAC",   "enquirySubType":"Delivery Complaint",   "enquiryLinkedArticle":"yes",   "senderName":"Winning Group Test Account",   "senderEmail":"jonathan.snelling@auspost.com.au",   "senderCompany":"WINNING GROUP TEST ACCOUNT",   "addresseeName":"PARTIAL ALLOWED",   "addresseeEmail":"sita.yarram@auspost.com.au",   "senderAddress":{      "addressLine1":"GPO Box 1777",      "addressLine2":"addressLine2",      "city":"MELBOURNE",      "state":"VIC",      "postcode":"3001",      "countrycode":"AU"   },   "senderAddressSearchTerm":"GPO Box 1777,MELBOURNE,VIC 3001,AU",   "addresseeAddress":{      "addressLine1":"ADDREE - 01",      "addressLine2":"ADD - 02, ADD - 03",      "city":"MELBOURNE",      "state":"VIC",      "postcode":"3000",      "countrycode":"AU"   },   "addresseeAddressSearchTerm":"ADDREE - 01,ADD - 02,ADD - 03,MELBOURNE,VIC 3000,AU",   "contactId":"003p000000a42xmAAA",   "FirstName":"Sammy",   "LastName":"K",   "Name":"Sammy K",   "MobilePhone":"0435814728",   "Email":"sameed.khan@gmail.com",   "IsPersonAccount":false,   "AccountId":"001p000000kmU2sAAE",   "Account":{      "Name":"Australia Post",      "Id":"001p000000kmU2sAAE"   },   "title":"Sammy K | Australia Post",   "subtitle":"Sammy K  ·  0435814728  ·  sameed.khan@gmail.com",   "customerAddress":{      "overflow":false,      "truncated":false,      "verified":true,      "addressLine1":"111 Bourke Rd",      "addressLine2":"",      "city":"Umina Beach",      "state":"NSW",      "postcode":"2257",      "dpid":"62822594",      "countrycode":"AU"   },   "customerAddressSearchTerm":"111 Bourke Road, UMINA BEACH  NSW  2257",   "caseOriginator":"Sender",   "productCategory":"Domestic Parcels",   "productSubCategory":"Courier Post",   "comments":"Additional comments - details",   "facilityOutlet":"yes",   "networkName":"Brisbane - Metro",   "networkId":"a2Kp0000000QlYcEAK"}';
        Case oCase = [SELECT Id FROM Case WHERE PrimaryEmail__c  = 'rajesh.punjabi@mav3rik.com'];
        MyNetworkSmartFormsWrapper caseWrapper = (MyNetworkSmartFormsWrapper) JSON.deserialize(deliveryConcern, MyNetworkSmartFormsWrapper.class);
        MyNetworkSmartFormsService smartForm = new MyNetworkSmartFormsService();
        Test.startTest();
        smartForm.createCaseComments (caseWrapper, oCase);
        Test.stopTest();
    }
    
    @IsTest 
    public static void createCase_somethingElse(){
        String somethingElse   = '{"formId":"somethingElse",  "caseType":"Feedback",   "facility":"a2Kp0000000QktXEAS",   "contactId":"",   "FirstName":"Sammy",   "LastName":"K",   "Name":"Sammy K",   "MobilePhone":"0435814728",   "Email":"sameed.khan@gmail.com",   "IsPersonAccount":false,   "AccountId":"001p000000kmU2sAAE",   "Account":{      "Name":"Australia Post",      "Id":"001p000000kmU2sAAE"   },   "title":"Sammy K | Australia Post",   "subtitle":"Sammy K  ·  0435814728  ·  sameed.khan@gmail.com",   "customerAddress":{      "overflow":false,      "truncated":false,      "verified":true,      "addressLine1":"111 Bourke Rd",      "addressLine2":"addressLine2",      "city":"Clayton South",      "state":"VIC",      "postcode":"3169",      "dpid":"82911061",      "countrycode":"AU"   },   "customerAddressSearchTerm":"111 Bourke Road, CLAYTON SOUTH  VIC  3169",   "productCategory":"Travel & ID",   "productSubCategory":"KeyPass",   "enquirySubType":"stuff1",   "comments":"What is the enquiry about?"}';
        Case oCase = [SELECT Id FROM Case WHERE PrimaryEmail__c  = 'rajesh.punjabi@mav3rik.com'];
        MyNetworkSmartFormsWrapper caseWrapper = (MyNetworkSmartFormsWrapper) JSON.deserialize(somethingElse, MyNetworkSmartFormsWrapper.class);
        MyNetworkSmartFormsService smartForm = new MyNetworkSmartFormsService();
        Test.startTest();
        smartForm.createCaseComments (caseWrapper, oCase);
        Test.stopTest();
    }
}