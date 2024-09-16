/**
** Change Log : Modified : Change made for roll out of Safe Drop feature on Missing Items form
               17-07-2020 Added test classes for Delivery Issues form @By : hara.sahoo@auspost.com.au
               17-09-2020 Added test classes for Missing Item Form form @By : hara.sahoo@auspost.com.au
               06-110-2020 Added test classes for consignment search api @By : hara.sahoo@auspost.com.au
               2020-11-24 Changes made for roll out of delivery issues network assignment automation @By:hara.sahoo@auspost.com.au
               2021-05-11 DDS-5488 -- Added test methods for search tracking number return 404 @By: phap.mai@auspost.com.au
               2021-05-13 Added test methods for EDD plus n business days
               2021-08-18 alex.volkov@auspost.com.au Updated to improve performance.
                                                     The class should be overhauled to use stubbing and test data factory and lower number of test methods
               2022-01-25 hasantha.liyanage@auspost.com.au DDS-9011 refactor of the method searchTrackingNumber() to handle multiple articles
                                                            Adapting the unit tests to support the coverage.
               2022-06-06 hasantha.liyanage@auspost.com.au DDS-10974 moved the createCaseFromProductsAndServices method to ChasProductsAndServicesControllerTest.
               2022-06-29 hasantha.liyanage@auspost.com.au Modified : DDS-11414 alteration of unit tests for changed method params for getEDDEstimates
               2022-07-04 hasantha.liyanage@auspost.com.au Modified : DDS-11414 getEDDEstimates unit tests moved to it's own class
               2023-11-20 - Nathan Franklin - Adding a tactical reCAPTCHA implementation to assist with reducing botnet attack vectors (INC2251557)

**/
@IsTest(IsParallel=true)
private class ChasApexControllerTest {

    private class TestData {
        Map<String,String> complaintWizardData;
        Map<String,String> missingItemWizardData;
        Map<String,Object> mailRedirectAndHold;
        Map<String,String> dliveryWizardData;
        Map<String,String> productAndSrvWizardData;
        Map<String,String> authUserData;
    }

    private static TestData gTestData;

    /*  static Map <String,String> vTestData.complaintWizardData = null;
      static Map <String,String> vTestData.missingItemWizardData = null;
      static Map <String,Object> vTestData.mailRedirectAndHold = null;
      static Map <String,String> vTestData.dliveryWizardData = null;
      static Map <String,String> vTestData.productAndSrvWizardData = null;
      static Map <String,String> vTestData.authUserData = null; */

    private static TestData wizardDataSetUp() {
        if (gTestData == null) {
            gTestData = new TestData();
            gTestData.complaintWizardData = new Map <String, String>();
            gTestData.missingItemWizardData = new Map <String, String>();
            gTestData.mailRedirectAndHold = new Map <String, Object>();
            gTestData.dliveryWizardData = new Map <String, String>();
            gTestData.productAndSrvWizardData = new Map <String, String>();
            gTestData.authUserData = new Map <String, String>();

            //-- Authenticateduser Data setup
            gTestData.authUserData.put('userContactEmail', 'useremail@gmail.com');
            gTestData.authUserData.put('userContactPhone', '21324235');
            gTestData.authUserData.put('userContactFirstName', 'UserFN');
            gTestData.authUserData.put('userContactLastName', 'UserLN');

            //--Complaint wizardData setup
            gTestData.complaintWizardData.put('selectedRadioName', 'Complaint');
            gTestData.complaintWizardData.put('complaintDetails', 'complaintDetails');
            gTestData.complaintWizardData.put('givenName', 'Test');
            gTestData.complaintWizardData.put('surname', 'A');
            gTestData.complaintWizardData.put('emailId', 'test1@gmail.com');
            gTestData.complaintWizardData.put('phone', '0987654321');

            //missingItem wizardData
            gTestData.missingItemWizardData.put('trackingId', 'HMM000123901000605007');
            gTestData.missingItemWizardData.put('selectedRadio1Name', 'Recipient');
            gTestData.missingItemWizardData.put('senderOrRecipientType', 'Domestic');
            gTestData.missingItemWizardData.put('selectedRadio2Name', 'Parcel');
            gTestData.missingItemWizardData.put('selectedRadio3Name', 'Regular Post');
            gTestData.missingItemWizardData.put('itemSentDate', '2018-01-01');
            gTestData.missingItemWizardData.put('deliveredByDateOrEDD', '2018-01-01');
            gTestData.missingItemWizardData.put('givenName', 'Test');
            gTestData.missingItemWizardData.put('surname', 'B');
            gTestData.missingItemWizardData.put('senderAddressLine1', 'senderAddressLine1');
            gTestData.missingItemWizardData.put('senderAddressLine2', 'senderAddressLine2');
            gTestData.missingItemWizardData.put('senderCity', 'senderCity');
            gTestData.missingItemWizardData.put('senderState', 'senderState');
            gTestData.missingItemWizardData.put('senderPostcode', '23213');
            gTestData.missingItemWizardData.put('senderCountry', 'Australia');
            gTestData.missingItemWizardData.put('recipientAddressLine1', 'recipientAddressLine1');
            gTestData.missingItemWizardData.put('recipientAddressLine2', 'recipientAddressLine2');
            gTestData.missingItemWizardData.put('recipientCity', 'recipientCity');
            gTestData.missingItemWizardData.put('recipientState', 'recipientState');
            gTestData.missingItemWizardData.put('recipientPostcode', 'recipientPostcode');
            gTestData.missingItemWizardData.put('recipientCountry', 'recipientCountry');
            gTestData.missingItemWizardData.put('itemValue', '456');
            gTestData.missingItemWizardData.put('complaintDetails', 'complaintDetails');
            gTestData.missingItemWizardData.put('deliveredByDatePlusBusinessDays', String.valueOf(System.today()));


            //--Mail Redirection and Hold wizardData setup
            List<Object> household = new List<Object>();
            Map<Object, Object> person1Obj = new Map<Object, Object>();
            person1Obj.put('test', 'a');
            Object person1 = (Object) person1Obj;
            household.add(person1);
            Map<Object, Object> person2Obj = new Map<Object, Object>();
            person2Obj.put('test', 'b');
            Object person2 = (Object) person2Obj;
            household.add(person2);

            gTestData.mailRedirectAndHold.put('household', household);
            gTestData.mailRedirectAndHold.put('selectedRadio1Name', 'Mail redirection');
            gTestData.mailRedirectAndHold.put('customerRefNumber', '12345');
            gTestData.mailRedirectAndHold.put('selectedRadio2Name', 'Email address');
            gTestData.mailRedirectAndHold.put('phoneNumber', '09999999999');
            gTestData.mailRedirectAndHold.put('emailAddress', 'a@gmail.com');
            gTestData.mailRedirectAndHold.put('selectedRadio3Name', 'Parcels');

            gTestData.mailRedirectAndHold.put('oldAddressLine1', 'add Lie 1');
            gTestData.mailRedirectAndHold.put('oldAddressLine2', 'add Line2');
            gTestData.mailRedirectAndHold.put('oldCity', 'city');
            gTestData.mailRedirectAndHold.put('oldState', 'state');
            gTestData.mailRedirectAndHold.put('oldPostcode', '1234');

            gTestData.mailRedirectAndHold.put('selectedRadio4Name', 'Within Australia');
            gTestData.mailRedirectAndHold.put('conditionCheckbox', true);

            gTestData.mailRedirectAndHold.put('newAddressLine1', 'recipientAddressLine1');
            gTestData.mailRedirectAndHold.put('newAddressLine2', 'recipientAddressLine2');
            gTestData.mailRedirectAndHold.put('newCity', 'recipientCity');
            gTestData.mailRedirectAndHold.put('newState', 'recipientState');
            gTestData.mailRedirectAndHold.put('newPostcode', 'recipientPostcode');
            gTestData.mailRedirectAndHold.put('newCountry', 'recipientCountry');
            gTestData.mailRedirectAndHold.put('enquiryDetails', 'enquiryDetails');

            //--Delivery issue wizardData setup
            gTestData.dliveryWizardData.put('selectedRadio1Name', 'Delivery not attempted');
            gTestData.dliveryWizardData.put('selectedRadio2Name', 'Parcel');
            gTestData.dliveryWizardData.put('selectedRadio3Name', 'Recipient');
            gTestData.dliveryWizardData.put('trackingId', '125367478855');
            gTestData.dliveryWizardData.put('issueDate', '2018-01-01');
            gTestData.dliveryWizardData.put('deliveryAddressLine1', 'Add Line 1');
            gTestData.dliveryWizardData.put('deliveryAddressLine2', 'AddLine 2');
            gTestData.dliveryWizardData.put('deliveryCity', 'City');
            gTestData.dliveryWizardData.put('deliveryState', 'State');
            gTestData.dliveryWizardData.put('deliveryPostcode', '1234');
            gTestData.dliveryWizardData.put('inCorrectDeliveryAddressLine1', 'Add Line 1');
            gTestData.dliveryWizardData.put('inCorrectDeliveryAddressLine2', 'AddLine 2');
            gTestData.dliveryWizardData.put('inCorrectDeliveryCity', 'City');
            gTestData.dliveryWizardData.put('inCorrectDeliveryState', 'State');
            gTestData.dliveryWizardData.put('inCorrectDeliveryPostcode', '1234');
            gTestData.dliveryWizardData.put('issueDetails', 'complaintDetails');
            gTestData.dliveryWizardData.put('contactPreferrence', 'Email');
            gTestData.dliveryWizardData.put('isEligibleForNetworkAssignmentDeliveryIssue', 'true');

            //--Product Issue wizardData setup
            gTestData.productAndSrvWizardData.put('selectedRadio1Name', 'Mail products');
            gTestData.productAndSrvWizardData.put('mailProductsEnquiryType', '24/7 Parcel Locker');
            gTestData.productAndSrvWizardData.put('transferTrackingNumber', '125367478855');
            gTestData.productAndSrvWizardData.put('idDocumentsAccountsEnquiryType', 'Other');
            gTestData.productAndSrvWizardData.put('orderNumber', '12345');
            gTestData.productAndSrvWizardData.put('orderTrackingNumber', '12345678');
            gTestData.productAndSrvWizardData.put('selectedRadio3Name', 'Bank@Post');
            gTestData.productAndSrvWizardData.put('selectedRadio2Name', 'Yes');

            gTestData.productAndSrvWizardData.put('deliveryAddressLine1', 'Add Line 1');
            gTestData.productAndSrvWizardData.put('deliveryAddressLine2', 'AddLine 2');
            gTestData.productAndSrvWizardData.put('deliveryCity', 'City');
            gTestData.productAndSrvWizardData.put('deliveryState', 'State');
            gTestData.productAndSrvWizardData.put('deliveryPostcode', '1234');

            gTestData.productAndSrvWizardData.put('enquiryDetails', 'complaintDetails');
        }

        return gTestData.clone();
    }

    /**
* Success Case of create Case with 'Compalint and feedback'
* */
    @IsTest
    public static void complaintAndFeedBack_complaint() {
        Boolean isSuccess = true;

        try{
            TestData vTestData = wizardDataSetUp();

            Test.startTest();
            ChasApexController.createCaseFromComplaintWizard(vTestData.complaintWizardData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('complaintAndFeedBack_complaint()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }


    /**
* Success Case of create Case with 'Compalint and feedback'
* */
    @IsTest
    public static void complaintAndFeedBack_privacyConcern() {
        Boolean isSuccess = true;

        try{
            TestData vTestData = wizardDataSetUp();

            vTestData.complaintWizardData.put('selectedRadioName','Privacy concern');
            vTestData.complaintWizardData.put('complaintDetails','complaintDetails complaintDetails complaintDetails'+
                    'complaintDetails complaintDetails complaintDetails complaintDetails'+
                    'complaintDetails complaintDetails complaintDetails complaintDetails'+
                    'complaintDetails complaintDetails complaintDetails complaintDetails'+
                    'complaintDetails complaintDetails complaintDetails complaintDetails'+
                    'complaintDetails complaintDetails complaintDetails complaintDetails'+
                    'complaintDetails complaintDetails complaintDetails complaintDetails'+
                    'complaintDetails complaintDetails complaintDetails complaintDetails'+
                    'complaintDetails complaintDetails complaintDetails complaintDetails'+
                    'complaintDetails complaintDetails complaintDetails complaintDetails'+
                    'complaintDetails complaintDetails complaintDetails complaintDetails'+
                    'complaintDetails complaintDetails complaintDetails complaintDetails');

            Test.startTest();
            ChasApexController.createCaseFromComplaintWizard(vTestData.complaintWizardData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('complaintAndFeedBack_privacyConcern()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
* Success Case for : Missing Item
* */
    @IsTest
    public static void missingItem_EligibleForNetwork() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();
            vTestData.missingItemWizardData.put('isEligibleForMyNetworkAssignment','true');
            vTestData.missingItemWizardData.put('reasonForEnquiry','Other');
            vTestData.missingItemWizardData.put('hasCustomerSeenSafeDrop','true');
            Test.startTest();
            ChasApexController.createCaseFromMissingWizard(vTestData.missingItemWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('missingItem_EligibleForNetwork()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
* Success Case for : Missing Item
* */
    @IsTest
    public static void missingItem_EnquiryDateWithinEDDPlusBusinessdays() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();
            vTestData.missingItemWizardData.put('latestDeliveredScanWcid','9876666');
            vTestData.missingItemWizardData.put('selectedRadio4Name','No');
            vTestData.missingItemWizardData.put('isEnquiryDateWithinEDDPlusBusinessdays','true');
            //vTestData.missingItemWizardData.put('deliveredByDatePlusBusinessDays',deliveredByDatePlusBusinessDays);
            Test.startTest();
            ChasApexController.createCaseFromMissingWizard(vTestData.missingItemWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('missingItem_EligibleForNetwork()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
    * Success Case for : Missing Item
    * */
    @IsTest
    public static void missingItem_EnquiryDateWithinEDD() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();
            vTestData.missingItemWizardData.put('latestDeliveredScanWcid','9876666');
            vTestData.missingItemWizardData.put('selectedRadio4Name','No');
            vTestData.missingItemWizardData.put('isEnquiryDateWithinEDD','true');
            //vTestData.missingItemWizardData.put('deliveredByDatePlusBusinessDays',System.Today());
            Test.startTest();
            ChasApexController.createCaseFromMissingWizard(vTestData.missingItemWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('missingItem_EligibleForNetwork()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
* Success Case for : Missing Item
* */
    @IsTest
    public static void missingItem_Domestic_Recipient_Parcel_RegularPost() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();
            vTestData.missingItemWizardData.put('isEligibleForMyNetworkAssignment','false');
            vTestData.missingItemWizardData.put('hasCustomerSeenSafeDrop','false');
            Test.startTest();
            ChasApexController.createCaseFromMissingWizard(vTestData.missingItemWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('missingItem_Domestic_Recipient_Parcel_RegularPost()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }
    /**
* Success Case for : Missing Item
* */
    @IsTest
    public static void missingItem_Domestic_Recipient_Parcel_ExpressPost() {
        Boolean isSuccess = true;

        try{
            TestData vTestData = wizardDataSetUp();

            vTestData.missingItemWizardData.put('selectedRadio3Name','Express Post');
            vTestData.missingItemWizardData.put('itemValue',null);
            vTestData.missingItemWizardData.put('complaintDetails','complaintDetails complaintDetails complaintDetails complaintDetails'+
                    'complaintDetails complaintDetails complaintDetails complaintDetails complaintDetails'+
                    'complaintDetails complaintDetails complaintDetails complaintDetails complaintDetails'+
                    'complaintDetails complaintDetails complaintDetails complaintDetails complaintDetails'+
                    'complaintDetails complaintDetails complaintDetails complaintDetails complaintDetails'+
                    'complaintDetails complaintDetails complaintDetails complaintDetails complaintDetails'+
                    'complaintDetails complaintDetails complaintDetails complaintDetails complaintDetails'+
                    'complaintDetails complaintDetails complaintDetails complaintDetails complaintDetails'+
                    'complaintDetails complaintDetails complaintDetails complaintDetails complaintDetails'+
                    'complaintDetails complaintDetails complaintDetails complaintDetails complaintDetails'+
                    'complaintDetails complaintDetails complaintDetails complaintDetails complaintDetails'+
                    'complaintDetails complaintDetails complaintDetails complaintDetails complaintDetails');

            Test.startTest();
            ChasApexController.createCaseFromMissingWizard(vTestData.missingItemWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('missingItem_Domestic_Recipient_Parcel_ExpressPost()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
* Success Case for : Missing Item
* */
    @IsTest
    public static void missingItem_Domestic_Sender_Letter_RegularPost() {
        Boolean isSuccess = true;

        try{
            TestData vTestData = wizardDataSetUp();

            vTestData.missingItemWizardData.put('selectedRadio1Name','Sender');
            vTestData.missingItemWizardData.put('senderOrRecipientType','Domestic');
            vTestData.missingItemWizardData.put('selectedRadio2Name','Letter');    //'Letter'
            vTestData.missingItemWizardData.put('selectedRadio3Name','Regular Post');

            Test.startTest();
            ChasApexController.createCaseFromMissingWizard(vTestData.missingItemWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('missingItem_Domestic_Sender_Letter_RegularPost()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
* Success Case for : Missing Item
* */
    @IsTest
    public static void missingItem_Domestic_Sender_Letter_ExpressPost() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();

            vTestData.missingItemWizardData.put('selectedRadio1Name','Sender');
            vTestData.missingItemWizardData.put('senderOrRecipientType','Domestic');
            vTestData.missingItemWizardData.put('selectedRadio2Name','Letter');
            vTestData.missingItemWizardData.put('selectedRadio3Name','Express Post');
            vTestData.missingItemWizardData.put('itemValue',null);
            vTestData.missingItemWizardData.put('isEligibleForMyNetworkAssignment','true');
            vTestData.missingItemWizardData.put('reasonForEnquiry','Other');
            vTestData.missingItemWizardData.put('hasCustomerSeenSafeDrop','true');

            Test.startTest();
            ChasApexController.createCaseFromMissingWizard(vTestData.missingItemWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('missingItem_Domestic_Sender_Letter_ExpressPost()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
* Success Case for : Missing Item
* */
    @IsTest
    public static void missingItem_Domestic_Sender_Letter_RegisteredPost() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();

            vTestData.missingItemWizardData.put('selectedRadio1Name','Sender');
            vTestData.missingItemWizardData.put('senderOrRecipientType','Domestic');
            vTestData.missingItemWizardData.put('selectedRadio2Name','Letter');
            vTestData.missingItemWizardData.put('selectedRadio3Name','Registered Post');
            vTestData.missingItemWizardData.put('itemValue',null);

            Test.startTest();
            ChasApexController.createCaseFromMissingWizard(vTestData.missingItemWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('missingItem_Domestic_Sender_Letter_RegisteredPost()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }
    /**
* Success Case for : Missing Item
* */
    @IsTest
    public static void missingItem_International_Recipient_Parcel_Courier() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();

            vTestData.missingItemWizardData.put('selectedRadio1Name','Recipient');
            vTestData.missingItemWizardData.put('senderOrRecipientType','International');
            vTestData.missingItemWizardData.put('selectedRadio2Name','Parcel');
            vTestData.missingItemWizardData.put('selectedRadio3Name','Courier');

            Test.startTest();
            ChasApexController.createCaseFromMissingWizard(vTestData.missingItemWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('missingItem_International_Recipient_Parcel_Courier()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
* Success Case for : Missing Item
* */
    @IsTest
    public static void missingItem_International_Recipient_Parcel_ExpressPost() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();

            vTestData.missingItemWizardData.put('selectedRadio1Name','Recipient');
            vTestData.missingItemWizardData.put('senderOrRecipientType','International');
            vTestData.missingItemWizardData.put('selectedRadio2Name','Parcel');
            vTestData.missingItemWizardData.put('selectedRadio3Name','Express');  //Express Post
            vTestData.missingItemWizardData.put('itemValue',null);

            Test.startTest();
            ChasApexController.createCaseFromMissingWizard(vTestData.missingItemWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('missingItem_International_Recipient_Parcel_ExpressPost()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }


    /**
* Success Case for : Missing Item
* */
    @IsTest
    public static void missingItem_International_Recipient_Parcel_Standard() {
        Boolean isSuccess = true;

        try{
            TestData vTestData = wizardDataSetUp();

            vTestData.missingItemWizardData.put('selectedRadio1Name','Recipient');
            vTestData.missingItemWizardData.put('senderOrRecipientType','International');
            vTestData.missingItemWizardData.put('selectedRadio2Name','Parcel');
            vTestData.missingItemWizardData.put('selectedRadio3Name','Standard');

            Test.startTest();
            ChasApexController.createCaseFromMissingWizard(vTestData.missingItemWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('missingItem_International_Recipient_Parcel_Standard()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }
    /**
* Success Case for : Missing Item
* */
    @IsTest
    public static void missingItem_International_Recipient_Parcel_EconomyAir() {
        Boolean isSuccess = true;

        try{
            TestData vTestData = wizardDataSetUp();

            vTestData.missingItemWizardData.put('selectedRadio1Name','Recipient');
            vTestData.missingItemWizardData.put('senderOrRecipientType','International');
            vTestData.missingItemWizardData.put('selectedRadio2Name','Parcel');
            vTestData.missingItemWizardData.put('selectedRadio3Name','Economy Air');

            Test.startTest();
            ChasApexController.createCaseFromMissingWizard(vTestData.missingItemWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('missingItem_International_Recipient_Parcel_EconomyAir()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
* Success Case for : Missing Item
* */
    @IsTest
    public static void missingItem_International_Recipient_Parcel_EconomySea() {
        Boolean isSuccess = true;

        try{
            TestData vTestData = wizardDataSetUp();

            vTestData.missingItemWizardData.put('selectedRadio1Name','Recipient');
            vTestData.missingItemWizardData.put('senderOrRecipientType','International');
            vTestData.missingItemWizardData.put('selectedRadio2Name','Parcel');
            vTestData.missingItemWizardData.put('selectedRadio3Name','Economy Sea');

            Test.startTest();
            ChasApexController.createCaseFromMissingWizard(vTestData.missingItemWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('missingItem_International_Recipient_Parcel_EconomySea()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
* Success Case for : Missing Item
* */
    @IsTest
    public static void missingItem_International_Recipient_Letter_Courier() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();

            vTestData.missingItemWizardData.put('selectedRadio1Name','Recipient');
            vTestData.missingItemWizardData.put('senderOrRecipientType','International');
            vTestData.missingItemWizardData.put('selectedRadio2Name','Letter');
            vTestData.missingItemWizardData.put('selectedRadio3Name','Courier');

            Test.startTest();
            ChasApexController.createCaseFromMissingWizard(vTestData.missingItemWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('missingItem_International_Recipient_Letter_Courier()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
* Success Case for : Missing Item
* */
    @IsTest
    public static void missingItem_International_Recipient_Letter_ExpressPost() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();

            vTestData.missingItemWizardData.put('selectedRadio1Name','Recipient');
            vTestData.missingItemWizardData.put('senderOrRecipientType','International');
            vTestData.missingItemWizardData.put('selectedRadio2Name','Letter');
            vTestData.missingItemWizardData.put('selectedRadio3Name','Express');
            vTestData.missingItemWizardData.put('itemValue',null);

            Test.startTest();
            ChasApexController.createCaseFromMissingWizard(vTestData.missingItemWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('missingItem_International_Recipient_Letter_ExpressPost()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }


    /**
* Success Case for : Missing Item
* */
    @IsTest
    public static void missingItem_International_Recipient_Letter_Standard() {
        Boolean isSuccess = true;

        try{
            TestData vTestData = wizardDataSetUp();

            vTestData.missingItemWizardData.put('selectedRadio1Name','Recipient');
            vTestData.missingItemWizardData.put('senderOrRecipientType','International');
            vTestData.missingItemWizardData.put('selectedRadio2Name','Letter');
            vTestData.missingItemWizardData.put('selectedRadio3Name','Standard');

            Test.startTest();
            ChasApexController.createCaseFromMissingWizard(vTestData.missingItemWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('missingItem_International_Recipient_Letter_Standard()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }
    /**
* Success Case for : Missing Item
* */
    @IsTest
    public static void missingItem_International_Recipient_Letter_EconomyAir() {
        Boolean isSuccess = true;

        try{
            TestData vTestData = wizardDataSetUp();

            vTestData.missingItemWizardData.put('selectedRadio1Name','Recipient');
            vTestData.missingItemWizardData.put('senderOrRecipientType','International');
            vTestData.missingItemWizardData.put('selectedRadio2Name','Letter');
            vTestData.missingItemWizardData.put('selectedRadio3Name','Economy Air');

            Test.startTest();
            ChasApexController.createCaseFromMissingWizard(vTestData.missingItemWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('missingItem_International_Recipient_Letter_EconomyAir()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
* Success Case for : Missing Item
* */
    @IsTest
    public static void missingItem_International_Recipient_Letter_EconomySea() {
        Boolean isSuccess = true;

        try{
            TestData vTestData = wizardDataSetUp();

            vTestData.missingItemWizardData.put('selectedRadio1Name','Recipient');
            vTestData.missingItemWizardData.put('senderOrRecipientType','International');
            vTestData.missingItemWizardData.put('selectedRadio2Name','Letter');
            vTestData.missingItemWizardData.put('selectedRadio3Name','Economy Sea');

            Test.startTest();
            ChasApexController.createCaseFromMissingWizard(vTestData.missingItemWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('missingItem_International_Recipient_Letter_EconomySea()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }


    /**
     * Consignment has multiple articles and user is eligible for multi article selection
     */
    @IsTest
    public static void missingItem_create_case_multiple_article_selected() {
        Boolean isSuccess = true;

        try{
            TestData vTestData = wizardDataSetUp();

            List<Object> articles = new List<Object>();
            Map<Object, Object> article1Obj1 = new Map<Object, Object>();
            article1Obj1.put('articleId', 'JDQ028052801000910904');
            article1Obj1.put('dpid', '76953814');
            article1Obj1.put('articleType', 'Parcel Post');
            article1Obj1.put('eddStatus', 'DELIVERED');
            article1Obj1.put('enqSubtype', 'Disputed delivery scan');
            article1Obj1.put('isEligibleForMyNetworkAssignment', true);
            article1Obj1.put('wcid', '351310');
            article1Obj1.put('trackStatusValue', 'Delivered');
            Object article1 = (Object) article1Obj1;
            articles.add(article1);

            Map<Object, Object> article1Obj2 = new Map<Object, Object>();
            article1Obj2.put('articleId|', 'JDQ028052802000910901');
            article1Obj2.put('dpid', '76953815');
            article1Obj2.put('articleType', 'Parcel Post');
            article1Obj2.put('eddStatus', 'DELIVERED');
            article1Obj2.put('enqSubtype', 'Disputed delivery scan');
            article1Obj2.put('isEligibleForMyNetworkAssignment', true);
            article1Obj2.put('wcid', '351310');
            article1Obj2.put('trackStatusValue', 'Delivered');
            article1Obj2.put('isSelected', true);
            Object article2 = (Object) article1Obj2;
            articles.add(article2);

            Map<Object, Object> article1Obj3 = new Map<Object, Object>();
            article1Obj3.put('articleId|', 'JDQ028052803000910908');
            article1Obj3.put('dpid', '76953814');
            article1Obj3.put('articleType', 'Parcel Post');
            article1Obj3.put('eddStatus', 'PENDING');
            article1Obj3.put('enqSubtype', 'Disputed delivery scan');
            article1Obj3.put('isEligibleForMyNetworkAssignment', true);
            article1Obj3.put('wcid', '351310');
            article1Obj3.put('trackStatusValue', 'Pending');
            article1Obj3.put('isSelected', true);
            Object article3 = (Object) article1Obj3;
            articles.add(article3);
            vTestData.missingItemWizardData.put('isEligibleForMultipleArticleSelection', 'true');
            vTestData.missingItemWizardData.put('articles', JSON.serializePretty(articles));
            Test.startTest();
            ChasApexController.createCaseFromMissingWizard(vTestData.missingItemWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('missingItem_International_Recipient_Letter_EconomySea()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
     * user is not eligible for multiple article selection
     */
    @IsTest
    public static void missingItem_create_case_not_eligible_multi_article_select() {
        Boolean isSuccess = true;

        try{
            TestData vTestData = wizardDataSetUp();

            List<Object> articles = new List<Object>();
            Map<Object, Object> article1Obj1 = new Map<Object, Object>();
            article1Obj1.put('articleId', 'JDQ028052801000910904');
            article1Obj1.put('dpid', '76953814');
            article1Obj1.put('articleType', 'Parcel Post');
            article1Obj1.put('eddStatus', 'DELIVERED');
            article1Obj1.put('enqSubtype', 'Disputed delivery scan');
            article1Obj1.put('isEligibleForMyNetworkAssignment', true);
            article1Obj1.put('wcid', '351310');
            article1Obj1.put('trackStatusValue', 'Delivered');
            Object article1 = (Object) article1Obj1;
            articles.add(article1);

            vTestData.missingItemWizardData.put('isEligibleForMultipleArticleSelection', 'false');
            vTestData.missingItemWizardData.put('articles', JSON.serializePretty(articles));
            Test.startTest();
            ChasApexController.createCaseFromMissingWizard(vTestData.missingItemWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('missingItem_International_Recipient_Letter_EconomySea()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
* Success Case for : Mail Redirection & Hold 
* */
    @IsTest
    public static void mailRedirectAndHold_mailRedirection_Parcel() {
        Boolean isSuccess = true;

        try{
            TestData vTestData = wizardDataSetUp();

            Test.startTest();
            ChasApexController.createCaseFromMailRedirectAndHold(vTestData.mailRedirectAndHold, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('vTestData.mailRedirectAndHold_mailRedirection_Parcel()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
* Success Case for :  Mail Redirection & Hold  
* */
    @IsTest
    public static void mailRedirectAndHold_mailRedirection_Letters_WithinAustralia() {
        Boolean isSuccess = true;

        try{
            TestData vTestData = wizardDataSetUp();

            vTestData.mailRedirectAndHold.put('enquiryDetails','enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails'+
                    'enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails'+
                    'enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails'+
                    'enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails'+
                    'enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails'+
                    'enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails'
            );
            vTestData.mailRedirectAndHold.put('selectedRadio3Name','Letters');
            vTestData.mailRedirectAndHold.put('conditionCheckbox',false);
            vTestData.mailRedirectAndHold.put('selectedRadio2Name','Phone number');
            vTestData.mailRedirectAndHold.put('phoneNumber','09999999999');
            vTestData.mailRedirectAndHold.put('selectedRadio4Name','Within Australia');

            Test.startTest();
            ChasApexController.createCaseFromMailRedirectAndHold(vTestData.mailRedirectAndHold, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('vTestData.mailRedirectAndHold_mailRedirection_Letters_WithinAustralia()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
     * DDS-4885: Add "Both" option to MRS form
     * Success case for Mail Redirect - Both - Within Australia
     */
    @IsTest
    public static void mailRedirectAndHold_mailRedirection_Both_WithinAustralia() {
        Boolean isSuccess = true;

        try{
            TestData vTestData = wizardDataSetUp();

            vTestData.mailRedirectAndHold.put('enquiryDetails','enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails'+
                    'enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails'+
                    'enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails'+
                    'enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails'+
                    'enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails'+
                    'enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails enquiryDetails'
            );
            vTestData.mailRedirectAndHold.put('selectedRadio3Name','Both');
            vTestData.mailRedirectAndHold.put('conditionCheckbox',false);
            vTestData.mailRedirectAndHold.put('selectedRadio2Name','Phone number');
            vTestData.mailRedirectAndHold.put('phoneNumber','09999999999');
            vTestData.mailRedirectAndHold.put('selectedRadio4Name','Within Australia');

            Test.startTest();
            ChasApexController.createCaseFromMailRedirectAndHold(vTestData.mailRedirectAndHold, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('vTestData.mailRedirectAndHold_mailRedirection_Letters_WithinAustralia()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
* Success Case for :  Mail Redirection & Hold 
* */
    @IsTest
    public static void mailRedirectAndHold_mailRedirection_Letters_Overseas() {
        Boolean isSuccess = true;

        try{
            TestData vTestData = wizardDataSetUp();

            vTestData.mailRedirectAndHold.put('selectedRadio3Name','Letters');
            vTestData.mailRedirectAndHold.put('selectedRadio4Name','Overseas');

            Test.startTest();
            ChasApexController.createCaseFromMailRedirectAndHold(vTestData.mailRedirectAndHold, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('vTestData.mailRedirectAndHold_mailRedirection_Letters_Overseas()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
     * DDS-4885: Add "Both" option on MRS form
     * Success case for Mail Redirection - Both - Overseas
     */
    @IsTest
    public static void mailRedirectAndHold_mailRedirection_Both_Overseas() {
        Boolean isSuccess = true;

        try{
            TestData vTestData = wizardDataSetUp();

            vTestData.mailRedirectAndHold.put('selectedRadio3Name','Both');
            vTestData.mailRedirectAndHold.put('selectedRadio4Name','Overseas');

            Test.startTest();
            ChasApexController.createCaseFromMailRedirectAndHold(vTestData.mailRedirectAndHold, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('vTestData.mailRedirectAndHold_mailRedirection_Letters_Overseas()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
* Success Case for :  Mail Redirection & Hold 
* */
    @IsTest
    public static void mailRedirectAndHold_mailHold_Parcel() {
        Boolean isSuccess = true;

        try{
            TestData vTestData = wizardDataSetUp();

            vTestData.mailRedirectAndHold.put('selectedRadio1Name','Mail hold');
            vTestData.mailRedirectAndHold.put('selectedRadio3Name','Parcels');

            Test.startTest();
            ChasApexController.createCaseFromMailRedirectAndHold(vTestData.mailRedirectAndHold, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('vTestData.mailRedirectAndHold_mailHold_Parcel()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
* Success Case for : International Sender Letter 
* */
    @IsTest
    public static void mailRedirectAndHold_mailHold_Letters() {
        Boolean isSuccess = true;

        try{
            TestData vTestData = wizardDataSetUp();

            vTestData.mailRedirectAndHold.put('selectedRadio1Name','Mail hold');
            vTestData.mailRedirectAndHold.put('selectedRadio3Name','Letters');
            Test.startTest();
            ChasApexController.createCaseFromMailRedirectAndHold(vTestData.mailRedirectAndHold, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('vTestData.mailRedirectAndHold_mailHold_Letters()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
     * DDS-4885: Add "Both" option to MRS form
     * Success case for Mail Hold - Both
     */
    @IsTest
    public static void mailRedirectAndHold_mailHold_Both() {
        Boolean isSuccess = true;

        try{
            TestData vTestData = wizardDataSetUp();

            vTestData.mailRedirectAndHold.put('selectedRadio1Name','Mail hold');
            vTestData.mailRedirectAndHold.put('selectedRadio3Name','Both');
            Test.startTest();
            ChasApexController.createCaseFromMailRedirectAndHold(vTestData.mailRedirectAndHold, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('vTestData.mailRedirectAndHold_mailHold_Letters()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
* Error Case for : International Sender Letter 
* */
    @IsTest
    public static void mailRedirectAndHold_errorCase() {
        Boolean isSuccess = true;

        try{
            TestData vTestData = wizardDataSetUp();
            vTestData.mailRedirectAndHold.put('conditionCheckbox','false');   // -- actualy needs to pass a bollen value but passing as string to cover exception code
            Test.startTest();
            ChasApexController.createCaseFromMailRedirectAndHold(vTestData.mailRedirectAndHold, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('vTestData.mailRedirectAndHold_errorCase()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }
    /**
* Success Case for : DeliveryIssue 
deliveryIssue_Incorrect_delivery_address_needs_fixing_Letter
* */
    @IsTest
    public static void deliveryIssue_Incorrect_Address_Letter() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();


            vTestData.dliveryWizardData.put('IssueName','Incorrect delivery address needs fixing');
            vTestData.dliveryWizardData.put('issueDescription','complaintDetails');
            vTestData.dliveryWizardData.put('issueDetails',null);
            vTestData.dliveryWizardData.put('selectedRadio2Name','Letter');
            vTestData.dliveryWizardData.put('selectedRadio3Name','Sender');

            Test.startTest();
            ChasApexController.createCaseFromDeliveryIssue(vTestData.dliveryWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('Error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }



    /**
* Success Case for : DeliveryIssue 
deliveryIssue_Incorrect_delivery_address_needs_fixing_Parcel
* */
    @IsTest
    public static void deliveryIssue_Incorrect_Address_Parcel() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();


            vTestData.dliveryWizardData.put('IssueName','Incorrect delivery address needs fixing');
            /* Test for more than 255 characters*/
            vTestData.dliveryWizardData.put('issueDescription','complaintDetails complaintDetails complaintDetailscomplaintDetailscomplaintDetailscomplaintDetails '+
                    'complaintDetails complaintDetails complaintDetails complaintDetailscomplaintDetailscomplaintDetailscomplaintDetails'+
                    'complaintDetails complaintDetails complaintDetailscomplaintDetailscomplaintDetailscomplaintDetails complaintDetails '+
                    'complaintDetails complaintDetailscomplaintDetailscomplaintDetailscomplaintDetails complaintDetails complaintDetails'+
                    'complaintDetailscomplaintDetailscomplaintDetailscomplaintDetails');
            vTestData.dliveryWizardData.put('issueDetails',null);
            vTestData.dliveryWizardData.put('selectedRadio2Name','Parcel');

            Test.startTest();
            ChasApexController.createCaseFromDeliveryIssue(vTestData.dliveryWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('Error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }



    /**
* Success Case for : DeliveryIssue 
deliveryIssue_Left_Card_Letter
* */
    @IsTest
    public static void deliveryIssue_Left_Card_Letter() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();


            vTestData.dliveryWizardData.put('IssueName','Postie didn\'t knock');
            /* Test for more than 255 characters*/
            vTestData.dliveryWizardData.put('issueDetails','complaintDetails complaintDetails complaintDetailscomplaintDetailscomplaintDetailscomplaintDetails '+
                    'complaintDetails complaintDetails complaintDetails complaintDetailscomplaintDetailscomplaintDetailscomplaintDetails'+
                    'complaintDetails complaintDetails complaintDetailscomplaintDetailscomplaintDetailscomplaintDetails complaintDetails '+
                    'complaintDetails complaintDetailscomplaintDetailscomplaintDetailscomplaintDetails complaintDetails complaintDetails'+
                    'complaintDetailscomplaintDetailscomplaintDetailscomplaintDetails');
            vTestData.dliveryWizardData.put('selectedRadio2Name','Letter');

            Test.startTest();
            ChasApexController.createCaseFromDeliveryIssue(vTestData.dliveryWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('Error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }



    /**
* Success Case for : DeliveryIssue 
deliveryIssue_Left_Card_Parcel
* */
    @IsTest
    public static void deliveryIssue_Left_Card_Parcel() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();


            vTestData.dliveryWizardData.put('IssueName','Postie didn\'t knock');
            vTestData.dliveryWizardData.put('selectedRadio2Name','Parcel');

            Test.startTest();
            ChasApexController.createCaseFromDeliveryIssue(vTestData.dliveryWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('Error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }


    /**
* Success Case for : DeliveryIssue 
deliveryIssue_Inconvenient_Postoffice_Letter
* */
    @IsTest
    public static void deliveryIssue_Inconvenient_Postoffice_Letter() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();


            vTestData.dliveryWizardData.put('IssueName','Item was taken to an inconvenient Post Office');
            vTestData.dliveryWizardData.put('selectedRadio2Name','Letter');

            Test.startTest();
            ChasApexController.createCaseFromDeliveryIssue(vTestData.dliveryWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('Error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }



    /**
* Success Case for : DeliveryIssue 
deliveryIssue_Left_Card_Parcel
* */
    @IsTest
    public static void deliveryIssue_Inconvenient_Postoffice_Parcel() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();


            vTestData.dliveryWizardData.put('IssueName','Item was taken to an inconvenient Post Office');
            vTestData.dliveryWizardData.put('selectedRadio2Name','Parcel');

            Test.startTest();
            ChasApexController.createCaseFromDeliveryIssue(vTestData.dliveryWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('Error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
* Success Case for : DeliveryIssue 
deliveryIssue_Item_Damaged_Letter
* */
    @IsTest
    public static void deliveryIssue_Item_Damaged_Letter() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();


            vTestData.dliveryWizardData.put('IssueName','Item was damaged');
            vTestData.dliveryWizardData.put('selectedRadio2Name','Letter');

            Test.startTest();
            ChasApexController.createCaseFromDeliveryIssue(vTestData.dliveryWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('Error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }



    /**
* Success Case for : DeliveryIssue 
deliveryIssue_Item_Damaged_Parcel
* */
    @IsTest
    public static void deliveryIssue_Item_Damaged_Parcel() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();


            vTestData.dliveryWizardData.put('IssueName','Item was damaged');
            vTestData.dliveryWizardData.put('selectedRadio2Name','Parcel');

            Test.startTest();
            ChasApexController.createCaseFromDeliveryIssue(vTestData.dliveryWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('Error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
* Success Case for : DeliveryIssue 
deliveryIssue_Unsafe_Place_Parcel
* */
    @IsTest
    public static void deliveryIssue_Unsafe_Place_Parcel() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();


            vTestData.dliveryWizardData.put('IssueName','Item was left in an unsafe place');
            vTestData.dliveryWizardData.put('selectedRadio2Name','Parcel');

            Test.startTest();
            ChasApexController.createCaseFromDeliveryIssue(vTestData.dliveryWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('Error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }



    /**
* Success Case for : DeliveryIssue 
deliveryIssue_Unsafe_Place_Letter
* */
    @IsTest
    public static void deliveryIssue_Unsafe_Place_Letter() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();


            vTestData.dliveryWizardData.put('IssueName','Item was left in an unsafe place');
            vTestData.dliveryWizardData.put('selectedRadio2Name','Letter');

            Test.startTest();
            ChasApexController.createCaseFromDeliveryIssue(vTestData.dliveryWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('Error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
* Success Case for : DeliveryIssue 
deliveryIssue_Somethingelse
* */
    @IsTest
    public static void deliveryIssue_Somethingelse() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();


            vTestData.dliveryWizardData.put('IssueName','Something else');
            //vTestData.dliveryWizardData.put('selectedRadio2Name','Letter');

            Test.startTest();
            ChasApexController.createCaseFromDeliveryIssue(vTestData.dliveryWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('Error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    public static  ChasApexController.ConsignmentDetails testsearchTrackingNumberSetup(StaticResourceCalloutMock mock, String consType) {

        List< Consumer_Help_and_Support__c> customSettingList = new List< Consumer_Help_and_Support__c>();
        //-- setting some key and service URL as it wont hit a call for service from test cases
        Consumer_Help_and_Support__c setting = new Consumer_Help_and_Support__c();
        setting.reCAPTCHASecretKey__c = '1234';
        setting.reCAPTCHAVerifyURL__c = 'https://www.google.com/recaptcha/api/siteverify';
        setting.API_Key_v2__c = 'ecc702f2-278a-4b84-aa1e-3e7dea3c6246';
        setting.Connection_Time_Out__c = 60000;
        setting.End_Point_1Track_Service_URL_v2__c ='https://digitalapi-ptest.npe.auspost.com.au/consignment-internal/v2/articles';
        setting.EDD_Service_API_Key__c = 'kjkjkjjklk';
        setting.EDD_Service_Connection_Time_Out__c = 50000;
        setting.End_Point_URL_EDD_Service__c ='https://digitalapi-stest.npe.auspost.com.au/shipment-edd/v1/shipments/';
        setting.EDDQueryParams__c='?postcode';
        setting.AP_Channel_Name__c ='HelpSupport';
        setting.SetupOwnerId=UserInfo.getOrganizationId();
        customSettingList.add(setting);
        //-- Inserting Custom setting
        insert customSettingList;

        ChasApexController.TrackingNumberDetails a = new ChasApexController.TrackingNumberDetails();
        a.articleType=null;
        a.deliveredByDateOrEDD=null;
        a.eddStatus = null;
        a.itemType = null;
        a.recipientCountry = null;
        a.senderCountry = null;
        a.trackingNumSerachStatusCode= null;
        a.trackingNumSerachStatusMsg = null;
        a.duplicateCase = null;
        a.latestEventLocation = 'LAVERTON VIC, 3028';
        a.latestEventLocationMessage = 'Delivered - Left in a safe place';
        a.enqSubtype = null;
        a.enqType = null;
        a.trackStatusValue = null;
        a.safedropDelivered = '2020-06-28 16:02:10';
        a.isReturnToSender = true;
        //Safedrop ineligible
        a.deliveryChoicesSafeDropIneligibilityCode = false;

        List<ChasApexController.TrackingNumberDetails> trackingNumberDetails = new List<ChasApexController.TrackingNumberDetails>();
        trackingNumberDetails.add(a);
        ChasApexController.ConsignmentDetails cons = new ChasApexController.ConsignmentDetails();
        cons.trackingNumberDetails = trackingNumberDetails;

        mock.setStaticResource(consType);
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');

        return cons;

    }

    /**
     * Test will ensure that captcha is bypassed if there is a logged in user (not a guest user)
     */
    @IsTest
    private static void testsearchTrackingNumberWithCaptchaBypassedForLoggedInUser() {

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        testsearchTrackingNumberSetup(mock,'CHAS_AwaitingCollection');

        HttpCalloutRecaptchaHappyPathMock recaptchaMock = new HttpCalloutRecaptchaHappyPathMock();

        MultiRequestMock mockManager = new MultiRequestMock(new Map<String, HttpCalloutMock>{
            'https://digitalapi-ptest.npe.auspost.com.au/consignment-internal/v2/articles?q=36382832732382&expand=events' => mock,
            'https://www.google.com/recaptcha/api/siteverify' => recaptchaMock
        });

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mockManager);

        ChasApexController.searchTrackingNumberWithCaptcha('36382832732382', 'mytokenfromclickingintheclient');

        System.assertEquals(false, recaptchaMock.mockCalled, 'Mock was invoked when it should not have been');

        Test.stopTest();
    }

    /**
     * Test will ensure to the captcha endpoint is called for an unauthenticated user before calling the tracking api
     */
    @IsTest
    private static void testsearchTrackingNumberWithCaptchaForUnauthenticatedUser() {

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        testsearchTrackingNumberSetup(mock,'CHAS_AwaitingCollection');

        HttpCalloutRecaptchaHappyPathMock recaptchaMock = new HttpCalloutRecaptchaHappyPathMock();

        MultiRequestMock mockManager = new MultiRequestMock(new Map<String, HttpCalloutMock>{
            'https://digitalapi-ptest.npe.auspost.com.au/consignment-internal/v2/articles?q=36382832732382&expand=events' => mock,
            'https://www.google.com/recaptcha/api/siteverify' => recaptchaMock
        });

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mockManager);

        User guestUser = getGuestUser();
        System.runAs(guestUser){
                ChasApexController.searchTrackingNumberWithCaptcha('36382832732382', 'mytokenfromclickingintheclient');
        }

        System.assert(recaptchaMock.mockCalled, 'Mock was not invoked');

        // setup in testsearchTrackingNumberSetup method call above
        System.assertEquals('1234', recaptchaMock.postBody.get('secret'), 'Secret was not passed correctly ' + recaptchaMock.postBody);
        System.assertEquals('mytokenfromclickingintheclient', recaptchaMock.postBody.get('response'), 'Response was not passed correctly ' + recaptchaMock.postBody);

        Test.stopTest();
    }

    /**
     * Test will ensure to the captcha endpoint is called for an unauthenticated user before calling the tracking api
     * This will ensure when a token is not valid it will fail and return an AuraHandledException
     */
    @IsTest
    private static void testsearchTrackingNumberWithCaptchaForUnauthenticatedUserAndVerificationFails() {

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        testsearchTrackingNumberSetup(mock,'CHAS_AwaitingCollection');

        HttpCalloutRecaptchaInvalidMock recaptchaMock = new HttpCalloutRecaptchaInvalidMock();

        MultiRequestMock mockManager = new MultiRequestMock(new Map<String, HttpCalloutMock>{
            'https://digitalapi-ptest.npe.auspost.com.au/consignment-internal/v2/articles?q=36382832732382&expand=events' => mock,
            'https://www.google.com/recaptcha/api/siteverify' => recaptchaMock
        });

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mockManager);

        User guestUser = getGuestUser();
        System.runAs(guestUser){
            try {
                ChasApexController.searchTrackingNumberWithCaptcha('36382832732382', 'mytokenfromclickingintheclient');

                System.assert(false);
            } catch(AuraHandledException exp) {
                System.assert(true);
            } catch(Exception exp) {
                System.assert(false);
            }
        }

        System.assert(recaptchaMock.mockCalled, 'Mock was not invoked');

        // setup in testsearchTrackingNumberSetup method call above
        System.assertEquals('1234', recaptchaMock.postBody.get('secret'), 'Secret was not passed correctly ' + recaptchaMock.postBody);
        System.assertEquals('mytokenfromclickingintheclient', recaptchaMock.postBody.get('response'), 'Response was not passed correctly ' + recaptchaMock.postBody);

        Test.stopTest();
    }

    // DDS-5488: test method for Consignment API return 404
    @IsTest
    private static void testsearchTrackingNumber_404()
    {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        testsearchTrackingNumberSetup(mock, 'CHAS_404Error');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        ChasApexController.searchTrackingNumber('36382832732382');
        Test.stopTest();
    }

    // IsAwaitingCollection
    @IsTest
    public static void testsearchTrackingNumber_IsAwaitingCollection() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        testsearchTrackingNumberSetup(mock,'CHAS_AwaitingCollection');

        Test.startTest();
        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);

        ChasApexController.searchTrackingNumber('2JD280270301000935004');

        Test.stopTest();
    }
    // CHAS_OnboardForDelivery
    @IsTest
    public static void testsearchTrackingNumber_OnBoardForDelivery() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        testsearchTrackingNumberSetup(mock,'CHAS_OnboardForDelivery');

        Test.startTest();
        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);

        ChasApexController.searchTrackingNumber('2JD280270301000935004');

        Test.stopTest();
    }
    // CHAS_OnboardForDeliveryOnTime
    @IsTest
    public static void testsearchTrackingNumber_CHAS_OnboardForDeliveryOnTime() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        testsearchTrackingNumberSetup(mock,'CHAS_OnboardForDeliveryOnTime');

        Test.startTest();
        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);

        ChasApexController.searchTrackingNumber('2JD280270301000935004');

        Test.stopTest();
    }
    // CHAS_LateDelivery
    @IsTest
    public static void testsearchTrackingNumber_CHAS_Late() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        testsearchTrackingNumberSetup(mock,'CHAS_Late');

        Test.startTest();
        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);

        ChasApexController.searchTrackingNumber('2JD280270301000935004');

        Test.stopTest();
    }
    // IsDelivered
    @IsTest
    public static void testsearchTrackingNumber_IsDelivered() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        testsearchTrackingNumberSetup(mock,'CHAS_Delivered');

        Test.startTest();
        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);

        ChasApexController.searchTrackingNumber('33LPL000102501000600304');

        Test.stopTest();
    }
    // IsDelivered-Left in a safe place
    @IsTest
    public static void testsearchTrackingNumber_IsDeliveredSafePlace() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        testsearchTrackingNumberSetup(mock,'CHAS_DeliveredLeftInASafePlace');

        Test.startTest();
        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);

        ChasApexController.searchTrackingNumber('2JD280270501000935008');

        Test.stopTest();
    }
    // CHAS_NoEDDReturned
    @IsTest
    public static void testsearchTrackingNumber_NoEDDReturned() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        testsearchTrackingNumberSetup(mock,'CHAS_NoEDDReturned');

        Test.startTest();
        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);

        ChasApexController.searchTrackingNumber('JDQ020406901000605006');

        Test.stopTest();
    }
    // CHAS_NoEDDReturned_DuplicateCase
    @IsTest
    public static void testsearchTrackingNumber_NoEDDReturnedDuplicateCase() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        testsearchTrackingNumberSetup(mock,'CHAS_NoEDDReturned_DuplicateCase');

        Test.startTest();
        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);

        ChasApexController.searchTrackingNumber('33LPL000061903000605008');

        Test.stopTest();
    }

    // CHAS_DeliveredLeftInASafePlaceMailRedirected
    @IsTest
    public static void testsearchTrackingNumber_CHAS_DeliveredLeftInASafePlaceMailRedirected() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        testsearchTrackingNumberSetup(mock,'CHAS_DeliveredLeftInASafePlaceMailRedirected');

        Test.startTest();
        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);

        ChasApexController.searchTrackingNumber('2JD280381201000935002');

        Test.stopTest();
    }
    // CHAS_NotScannedYet
    @IsTest
    public static void testsearchTrackingNumber_CHAS_NotScannedYet() {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        testsearchTrackingNumberSetup(mock,'CHAS_NotScannedYet');

        Test.startTest();
        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);

        ChasApexController.searchTrackingNumber('33LPL000061903000605008');

        Test.stopTest();
    }

    /**
* Success Case for : get UserInfo
* */
    @IsTest
    public static void testGetUserInfo() {
        Boolean isSuccess = true;

        try{

            Test.startTest();
            ChasApexController.getLoggedInUserInfo();     //-- Create community User with contact
            Test.stopTest();

        }catch(Exception e){
            System.debug('testGetUserInfo()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
* Success Case for : encrypt
* 28/08/2018 - decrypt and encrypt methods changed so that wizData is stored in Platform Cache - make sure the 'local.HelpAndSupport' platform cache partition exists.
* */

    @IsTest
    public static void testEncrypt() {
        Boolean isSuccess = true;

        try{
            Test.startTest();

            List< Consumer_Help_and_Support__c> customSettingList = new List< Consumer_Help_and_Support__c>();
            Consumer_Help_and_Support__c setting = new Consumer_Help_and_Support__c();
            setting.Encoded_Crypto_Key__c = EncodingUtil.base64Encode(Crypto.generateAesKey(256));
            setting.SetupOwnerId=UserInfo.getOrganizationId();
            customSettingList.add(setting);
            //-- Inserting Custom setting
            insert customSettingList;

            Consumer_Help_and_Support__c consumerHelpNSupport = Consumer_Help_and_Support__c.getOrgDefaults();
            System.debug('consumerHelpNSupport custom setting='+consumerHelpNSupport);

            System.debug('inserted custom setting');
            System.debug('Custom setting inserted successfully');

            ChasApexController.EncryptDetails encryptedDetails = ChasApexController.encryptData('Test Data to be Encrypted');
            // 28/08/2018 - adjusted to return GUID only
            if(encryptedDetails.cacheKey != null){
                //if(encryptedDetails.encodedData != null){
                isSuccess =true;
            }else{
                isSuccess = false;
            }
            Test.stopTest();

        }catch(Exception e){
            System.debug('testEncrypt()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
* Success Case for : decrypt
*
* 28/08/2018 - decrypt and encrypt methods changed so that wizData is stored in Platform Cache - make sure the 'local.HelpAndSupport' platform cache partition exists.
* */
    @IsTest
    public static void testdecrypt() {
        Boolean isSuccess = true;

        try{
            Test.startTest();

            List< Consumer_Help_and_Support__c> customSettingList = new List< Consumer_Help_and_Support__c>();
            Consumer_Help_and_Support__c setting = new Consumer_Help_and_Support__c();
            setting.Encoded_Crypto_Key__c = EncodingUtil.base64Encode(Crypto.generateAesKey(256));
            setting.SetupOwnerId=UserInfo.getOrganizationId();
            customSettingList.add(setting);
            //-- Inserting Custom setting
            insert customSettingList;

            ChasApexController.EncryptDetails encryptedDetails = ChasApexController.encryptData('Test Data to be Encrypted');
            // 28/08/2018 - decrypt and encrypt methods changed so that wizData is stored in Platform Cache - make sure the 'local.HelpAndSupport' platform cache partition exists.
            if(encryptedDetails.cacheKey != null){
                String decryptedData = ChasApexController.decryptData('No longer used', encryptedDetails.cacheKey);
                if(decryptedData !=null){
                    isSuccess =true;
                }

            }else{
                isSuccess = false;


                //if(encryptedDetails.encodedData != null){
                //    String decryptedData = ChasApexController.decryptData(encryptedDetails.encodedData, guid);
                //    if(decryptedData !=null){
                //        isSuccess =true;
                //    }
                //
                //}else{
                //    isSuccess = false;
            }
            Test.stopTest();

        }catch(Exception e){
            System.debug('testdecrypt()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /** test methods for chasUtil class**/
    @IsTest
    public static void getBusinessHours() {
        System.assert(ChasUtil.getBusinessHours() != null);
    }
    @IsTest
    public static void calculateNextBusinessDay() {
        System.assert(BusinessHoursService.newInstance().calculateNextBusinessDay(Date.today(),5) != null);
    }
    @IsTest
    public static void isTheDateWithinEDDPlusBusinessdays() {
        System.assert(ChasUtil.isTheDateWithinEDDPlusBusinessdays(Date.today()) != null);
    }
    @IsTest
    public static void isTheDatePastEDDPlusBusinessdays() {
        System.assert(ChasUtil.isTheDatePastEDDPlusBusinessdays(Date.valueOf('2017-08-09')), true);
    }

    /**
* Success Case for : get UserInfo
* */
    /* public static testMethod void testGetUserInfoWithContact() {
Boolean isSuccess = true; 

try{

Test.startTest();
User userWithContact = null;

Contact Con = new Contact( FirstName = 'ss', LastName = 'dd',email ='a@gmail.com');
try{
insert Con;
System.debug('Con==>'+Con);

}catch(Exception ex){
System.debug('ex==>'+ex);
}

try{
Profile prof =[Select Id from Profile where name='System Administrator' LIMIT 1];
userWithContact = new User( email='testuser@xyz.com', contactid = Con.id, profileid = prof.Id, UserName='testuser@xyz.com', alias='tuser', CommunityNickName='tuser',
TimeZoneSidKey='America/New_York', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',
LanguageLocaleKey='en_US', FirstName = 'User', LastName = 'Test' );

insert userWithContact;
System.debug('userWithContact==>'+userWithContact);
}catch(Exception ex2){
System.debug('ex2==>'+ex2);
}
//User userWithContact = [Select Id from User where contactId !=null Limit 1];
//System.debug('userWithContact='+userWithContact);
System.runAs(userWithContact){
ChasApexController.getLoggedInUserInfo();     //-- Create community User with contact   
}

Test.stopTest();

}catch(Exception e){
System.debug('testGetUserInfo()::error==>'+e.getMessage());
isSuccess = false;
}
System.assert(isSuccess); 
}*/



    /**
* Success Case for : Util
* */
    @IsTest
    public static void testUtilMethods() {
        Boolean isSuccess = true;

        try{

            Test.startTest();

            try{
                ChasApexController.UserDetails userDetailWrapperObj = new  ChasApexController.UserDetails();
                userDetailWrapperObj.userContactPhone = '12332434545';
                userDetailWrapperObj.userContactEmail ='abc@gmail.com';
                userDetailWrapperObj.userContactFirstName ='FirstName';
                userDetailWrapperObj.userContactLastName ='LastName';

            }catch(Exception ex){

            }
            try{
                ChasUtil.isTheDateIsPast(Date.today());
            }catch(Exception ex){

            }
            try{
                ChasUtil.convertToSFDateStrFormat('2017/08/09');
            }catch(Exception ex){

            }
            try{
                ChasUtil.isTheDateIsPast(Date.today().addDays(-5));
            }catch(Exception ex){

            }

            try{
                ChasUtil.convertToSFDateStrFormat('11-12'); // -- wrong date format for exception
            }catch(Exception ex){

            }
            try{
                ChasUtil.convertToSFDateStrFormat('2017.08.09');
            }catch(Exception ex){

            }
            try{
                ChasUtil.convertToSFDateStrFormat('2017-08-09');
            }catch(Exception ex){

            }

            try{
                ChasUtil.convertToSFDateStrFormat('08-08-2018');
            }catch(Exception ex){

            }
            try{
                ChasUtil.convertToSFDateStrFormat('08-08'); //-- wrong date format for exception
            }catch(Exception ex){

            }

            try{
                ChasUtil.convertToDateStrWithHyphenSeparator('20170809');
            }catch(Exception ex){

            }
            try{
                ChasUtil.convertToDateStrWithHyphenSeparator('2017');
            }catch(Exception ex){

            }
            try{
                ChasUtil.displayFormatted('30 August 2019');
            }catch(Exception ex){

            }
            try{
                ChasUtil.getMonth(1);
            }catch(Exception ex){

            }
            try{
                ChasUtil.getMonth(2);
            }catch(Exception ex){

            }
            try{
                ChasUtil.getMonth(3);
            }catch(Exception ex){

            }
            try{
                ChasUtil.getMonth(4);
            }catch(Exception ex){

            }
            try{
                ChasUtil.getMonth(5);
            }catch(Exception ex){

            }
            try{
                ChasUtil.getMonth(6);
            }catch(Exception ex){

            }
            try{
                ChasUtil.getMonth(7);
            }catch(Exception ex){

            }
            try{
                ChasUtil.getMonth(8);
            }catch(Exception ex){

            }
            try{
                ChasUtil.getMonth(9);
            }catch(Exception ex){

            }  try{
                ChasUtil.getMonth(10);
            }catch(Exception ex){

            }  try{
                ChasUtil.getMonth(11);
            }catch(Exception ex){

            }  try{
                ChasUtil.getMonth(12);
            }catch(Exception ex){

            }

            Test.stopTest();

        }catch(Exception e){
            System.debug('testUtilMethods()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    @IsTest
    private static void getNextStepMetadata()
    {
        List<CHAS_ThankYouPageNextSteps__mdt> metadatas = ChasApexController.getNextStepMetadata('nextStepsSafeDropDelivered');
        System.assert(metadatas.size() > 0);
    }

    private static User getGuestUser() {
        Profile guestProfile = [SELECT Id FROM Profile WHERE Name = 'Consumer Help and Support Profile' AND UserLicense.Name = 'Guest User License' LIMIT 1];

        User guestUser = [Select Id From User Where ProfileId = :guestProfile.Id LIMIT 1];

        // //Create our test guest user
        // User guestUser = new User(
        //     Alias = 'random',
        //     Email='random' + DateTime.now().getTime() + '@apsf.com',
        //     EmailEncodingKey = 'UTF-8',
        //     LastName = 'random',
        //     LocaleSidKey = 'en_US',
        //     LanguageLocaleKey = 'en_US',
        //     ProfileId = guestProfile.Id,
        //     TimeZoneSidKey ='America/Los_Angeles',
        //     UserName ='randomuser' + DateTime.now().getTime() + '@apsf.com'
        // );

        return guestUser;
    }

    public class HttpCalloutRecaptchaHappyPathMock implements HttpCalloutMock {
        public Boolean mockCalled = false;
        public Map<String, String> postBody = new Map<String, String>();

        public HTTPResponse respond(HTTPRequest req) {
            System.PageReference pageReference = new System.PageReference('/?' + req.getBody());
            Map<String,String> parameters = pageReference.getParameters();
            postBody.put('secret', parameters.get('secret'));
            postBody.put('response', parameters.get('response'));

            mockCalled = true;

            HttpResponse res = new HttpResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('{"success":true}');
            return res;
        }
    }

    public class HttpCalloutRecaptchaInvalidMock implements HttpCalloutMock {
        public Boolean mockCalled = false;
        public Map<String, String> postBody = new Map<String, String>();

        public HTTPResponse respond(HTTPRequest req) {
            System.PageReference pageReference = new System.PageReference('/?' + req.getBody());
            Map<String,String> parameters = pageReference.getParameters();
            postBody.put('secret', parameters.get('secret'));
            postBody.put('response', parameters.get('response'));

            mockCalled = true;

            HttpResponse res = new HttpResponse();
            res.setStatus('OK');
            res.setStatusCode(200);
            res.setBody('{"success":false}');
            return res;
        }
    }

    public class MultiRequestMock implements HttpCalloutMock {
        Map<String, HttpCalloutMock> requests;

        public MultiRequestMock(Map<String, HttpCalloutMock> requests) {
            this.requests = requests;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpCalloutMock mock = requests.get(req.getEndpoint());
            if (mock != null) {
                return mock.respond(req);
            } else {
                return null;
            }
        }

        public void addRequestMock(String url, HttpCalloutMock mock) {
            requests.put(url, mock);
        }
    }


    /**
* Error Case of create Case with 'Compalint and feedback'
* */
    /*  public static testMethod void complaintAndFeedBack_errorCase() {
Boolean isSuccess = true; 

try{
TestData vTestData = wizardDataSetUp();

vTestData.complaintWizardData.put('First_Name__c','test test test test test test test test test test test test test test test'+
'test test test test test test test test test test test test test test test'+
'test test test test test test test test test test test test test test test'+
'test test test test test test test test test test test test test test test'+
'test test test test test test test test test test test test test test test'+
'test test test test test test test test test test test test test test test'+
'test test test test test test test test test test test test test test test'+
'test test test test test test test test test test test test test test test'+
'test test test test test test test test test test test test test test test'+
'test test test test test test test test test test test test test test test');  // assigning more chars to firstname to make Case insertion fail

Test.startTest();
ChasApexController.createCaseFromComplaintWizard(vTestData.complaintWizardData);

Test.stopTest();
}catch(Exception e){
System.debug('complaintAndFeedBack_errorCase()::error==>'+e.getMessage());
isSuccess = false;
}
System.assert(isSuccess); 
}*/

    /**
* Success Case for : Domestic Sender with Letter
* */
    /* public static testMethod void testMIDomesticSenderLetterCase() {
Boolean isSuccess = true; 

try{

Map <String,String> wizardData = new Map <String,String>();
Map <String,String> vTestData.authUserData = new Map <String,String>();

wizardData.put('trackingId','HMM000123901000605007');
wizardData.put('selectedRadio1Name','Sender');
wizardData.put('senderOrRecipientType','Domestic');   //'International');
wizardData.put('selectedRadio2Name','Letter');    //'Letter'
wizardData.put('selectedRadio3Name','Regular Post');    //'Registered Post', 'Express Post', 'Courier, 'Standard', 'Economy Air', 'Economy Sea');
wizardData.put('itemSentDate','2018-01-01');
wizardData.put('givenName','Test');
wizardData.put('surname','B');
wizardData.put('senderAddressLine1','senderAddressLine1');
wizardData.put('senderAddressLine2','senderAddressLine2');
wizardData.put('senderCity','senderCity');
wizardData.put('senderState','senderState' );
wizardData.put('senderPostcode','23213' );
wizardData.put('senderCountry','Australia' );
wizardData.put('recipientAddressLine1','recipientAddressLine1' );
wizardData.put('recipientAddressLine2','recipientAddressLine2' );
wizardData.put('recipientCity','recipientCity' );
wizardData.put('recipientState','recipientState' );
wizardData.put('recipientPostcode','recipientPostcode' );
wizardData.put('recipientCountry','recipientCountry' );
wizardData.put('itemValue','456' );

wizardData.put('complaintDetails','complaintDetails');

vTestData.authUserData.put('userContactEmail','useremail@gmail.com' );
vTestData.authUserData.put('userContactPhone','21324235' );
vTestData.authUserData.put('userContactFirstName','UserFN' ); 
vTestData.authUserData.put('userContactLastName','UserLN' ); 

Test.startTest();
ChasApexController.createCaseFromMissingWizard(wizardData, vTestData.authUserData);

wizardData.put('selectedRadio3Name','Express Post');
wizardData.put('itemValue',null);
ChasApexController.createCaseFromMissingWizard(wizardData, vTestData.authUserData);

wizardData.put('selectedRadio3Name','Registered Post');
ChasApexController.createCaseFromMissingWizard(wizardData, vTestData.authUserData);
Test.stopTest();

}catch(Exception e){
System.debug('testMIDomesticSenderLetterCase()::error==>'+e.getMessage());
isSuccess = false;
}
System.assert(isSuccess); 
}*/

    /**
* Success Case for : International Recipient Parcel 
* */
    /*public static testMethod void testMIInternationalRecipientParcelCase() {
Boolean isSuccess = true; 

try{

Map <String,String> wizardData = new Map <String,String>();
Map <String,String> vTestData.authUserData = new Map <String,String>();

wizardData.put('trackingId','HMM000123901000605007');
wizardData.put('selectedRadio1Name','Recipient');
wizardData.put('senderOrRecipientType','International');   
wizardData.put('selectedRadio2Name','Parcel');    
wizardData.put('selectedRadio3Name','Courier');    
wizardData.put('itemSentDate','2018-01-01');
wizardData.put('givenName','Test');
wizardData.put('surname','B');
wizardData.put('senderAddressLine1','senderAddressLine1');
wizardData.put('senderAddressLine2','senderAddressLine2');
wizardData.put('senderCity','senderCity');
wizardData.put('senderState','senderState' );
wizardData.put('senderPostcode','23213' );
wizardData.put('senderCountry','Australia' );
wizardData.put('recipientAddressLine1','recipientAddressLine1' );
wizardData.put('recipientAddressLine2','recipientAddressLine2' );
wizardData.put('recipientCity','recipientCity' );
wizardData.put('recipientState','recipientState' );
wizardData.put('recipientPostcode','recipientPostcode' );
wizardData.put('recipientCountry','recipientCountry' );
wizardData.put('itemValue','456' );

wizardData.put('complaintDetails','complaintDetails');

vTestData.authUserData.put('userContactEmail','useremail@gmail.com' );
vTestData.authUserData.put('userContactPhone','21324235' );
vTestData.authUserData.put('userContactFirstName','UserFN' ); 
vTestData.authUserData.put('userContactLastName','UserLN' ); 

Test.startTest();
ChasApexController.createCaseFromMissingWizard(wizardData, vTestData.authUserData);

wizardData.put('selectedRadio3Name','Express Post');
wizardData.put('itemValue',null);
ChasApexController.createCaseFromMissingWizard(wizardData, vTestData.authUserData);

wizardData.put('selectedRadio3Name','Standard');
ChasApexController.createCaseFromMissingWizard(wizardData, vTestData.authUserData);

wizardData.put('selectedRadio3Name','Economy Air');
ChasApexController.createCaseFromMissingWizard(wizardData, vTestData.authUserData);

wizardData.put('selectedRadio3Name','Economy Sea');
ChasApexController.createCaseFromMissingWizard(wizardData, vTestData.authUserData);

Test.stopTest();

}catch(Exception e){
System.debug('testMIInternationalRecipientParcelCase()::error==>'+e.getMessage());
isSuccess = false;
}
System.assert(isSuccess); 
}*/


    /**
* Success Case for : International Sender Letter 
* */
    /* public static testMethod void testMIInternationalSenderLetterCase() {
Boolean isSuccess = true; 

try{

Map <String,String> wizardData = new Map <String,String>();
Map <String,String> vTestData.authUserData = new Map <String,String>();

wizardData.put('trackingId','HMM000123901000605007');
wizardData.put('selectedRadio1Name','Sender');
wizardData.put('senderOrRecipientType','International');   
wizardData.put('selectedRadio2Name','Letter');    
wizardData.put('selectedRadio3Name','Courier');    
wizardData.put('itemSentDate','2018-01-01');
wizardData.put('givenName','Test');
wizardData.put('surname','B');
wizardData.put('senderAddressLine1','senderAddressLine1');
wizardData.put('senderAddressLine2','senderAddressLine2');
wizardData.put('senderCity','senderCity');
wizardData.put('senderState','senderState' );
wizardData.put('senderPostcode','23213' );
wizardData.put('senderCountry','Australia' );
wizardData.put('recipientAddressLine1','recipientAddressLine1' );
wizardData.put('recipientAddressLine2','recipientAddressLine2' );
wizardData.put('recipientCity','recipientCity' );
wizardData.put('recipientState','recipientState' );
wizardData.put('recipientPostcode','recipientPostcode' );
wizardData.put('recipientCountry','recipientCountry' );
wizardData.put('itemValue','456' );

wizardData.put('complaintDetails','complaintDetails');

vTestData.authUserData.put('userContactEmail','useremail@gmail.com' );
vTestData.authUserData.put('userContactPhone','21324235' );
vTestData.authUserData.put('userContactFirstName','UserFN' ); 
vTestData.authUserData.put('userContactLastName','UserLN' ); 

Test.startTest();
ChasApexController.createCaseFromMissingWizard(wizardData, vTestData.authUserData);

wizardData.put('selectedRadio3Name','Express Post');
wizardData.put('itemValue',null);
ChasApexController.createCaseFromMissingWizard(wizardData, vTestData.authUserData);

wizardData.put('selectedRadio3Name','Standard');
ChasApexController.createCaseFromMissingWizard(wizardData, vTestData.authUserData);

wizardData.put('selectedRadio3Name','Economy Air');
ChasApexController.createCaseFromMissingWizard(wizardData, vTestData.authUserData);

wizardData.put('selectedRadio3Name','Economy Sea');
ChasApexController.createCaseFromMissingWizard(wizardData, vTestData.authUserData);

Test.stopTest();

}catch(Exception e){
System.debug('testMIInternationalSenderLetterCase()::error==>'+e.getMessage());
isSuccess = false;
}
System.assert(isSuccess); 
} */
}