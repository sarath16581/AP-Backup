/**
 * Created by hasan on 9/06/2022.
 */
@IsTest(IsParallel=true)
public with sharing class ChasProductsAndServicesControllerTest {
    private class TestData {
        Map<String,String> complaintWizardData;
        Map<String,String> missingItemWizardData;
        Map<String,Object> mailRedirectAndHold;
        Map<String,String> dliveryWizardData;
        Map<String,String> productAndSrvWizardData;
        Map<String,String> authUserData;
    }
    private static TestData gTestData;
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

    @IsTest
    public static void productIssue_DeleteMyPostAccount() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();

            vTestData.productAndSrvWizardData.put('selectedRadio1Name','ID, documents & accounts');
            vTestData.productAndSrvWizardData.put('idDocumentsAccountsEnquiryType','Delete MyPost account');

            Test.startTest();
            ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('productIssue_MailProducts_Letter()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
* Success Case for : Procu Issue
* */
    @IsTest
    public static void productIssue_MailProducts_24By7ParcelLocker() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();

            // vTestData.productAndSrvWizardData.put('selectedRadio1Name','Item not left in a safe location');
            Test.startTest();
            ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('productIssue_MailProducts_24By7ParcelLocker()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }
    /**
* Success Case for : Procu Issue
* */
    @IsTest
    public static void productIssue_MailProducts_ExpressPost() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();

            vTestData.productAndSrvWizardData.put('mailProductsEnquiryType','Express Post');
            //-- more than 255 chars of issue details text
            vTestData.productAndSrvWizardData.put('enquiryDetails','complaintDetails complaintDetails complaintDetailscomplaintDetailscomplaintDetailscomplaintDetails '+
                    'complaintDetails complaintDetails complaintDetails complaintDetailscomplaintDetailscomplaintDetailscomplaintDetails'+
                    'complaintDetails complaintDetails complaintDetailscomplaintDetailscomplaintDetailscomplaintDetails complaintDetails '+
                    'complaintDetails complaintDetailscomplaintDetailscomplaintDetailscomplaintDetails complaintDetails complaintDetails'+
                    'complaintDetailscomplaintDetailscomplaintDetailscomplaintDetails');
            Test.startTest();
            ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('productIssue_MailProducts_ExpressPost()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }


    /**
* Success Case for : Procu Issue
* */
    @IsTest
    public static void productIssue_MailProducts_Letter() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();

            vTestData.productAndSrvWizardData.put('mailProductsEnquiryType','Letter');

            Test.startTest();
            ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('productIssue_MailProducts_Letter()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }
    /**
* Success Case for : Procu Issue
* */
    @IsTest
    public static void productIssue_MailProducts_Parcel() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();

            vTestData.productAndSrvWizardData.put('mailProductsEnquiryType','Parcel');

            Test.startTest();
            ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('productIssue_MailProducts_Parcel()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }
    /**
* Success Case for : Procu Issue
* */
    @IsTest
    public static void productIssue_MailProducts_ParcelCollect() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();

            vTestData.productAndSrvWizardData.put('mailProductsEnquiryType','Parcel Collect');

            Test.startTest();
            ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('productIssue_MailProducts_ParcelCollect()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
* Success Case for : Procu Issue
* */
    @IsTest
    public static void productIssue_MailProducts_POBoxAndPrivateBag() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();

            vTestData.productAndSrvWizardData.put('mailProductsEnquiryType','PO Box and Private Bag');

            Test.startTest();
            ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('productIssue_MailProducts_POBoxAndPrivateBag()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
* Success Case for : Procu Issue
* */
    @IsTest
    public static void productIssue_MailProducts_Tracking() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();

            vTestData.productAndSrvWizardData.put('mailProductsEnquiryType','Tracking');

            Test.startTest();
            ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('productIssue_MailProducts_Tracking()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }


    /**
* Success Case for : Procu Issue
* */
    @IsTest
    public static void productIssue_MailProducts_Transfer() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();

            vTestData.productAndSrvWizardData.put('mailProductsEnquiryType','Transfer');

            Test.startTest();
            ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('productIssue_MailProducts_Transfer()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
* Success Case for : Procu Issue
* */
    @IsTest
    public static void productIssue_PostOffice() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();

            vTestData.productAndSrvWizardData.put('selectedRadio1Name','Post office');

            Test.startTest();
            ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('productIssue_PostOffice()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }


    /**
* Success Case for : Procu Issue
* */
    @IsTest
    public static void productIssue_IdDocuments() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();

            vTestData.productAndSrvWizardData.put('selectedRadio1Name','ID, documents & accounts');

            Test.startTest();
            ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('productIssue_IdDocuments()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }


    /**
* Success Case for : Procu Issue
* */
    @IsTest
    public static void productIssue_IdDocuments_Idheck() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();

            vTestData.productAndSrvWizardData.put('selectedRadio1Name','ID, documents & accounts');
            vTestData.productAndSrvWizardData.put('idDocumentsAccountsEnquiryType','ID check');

            Test.startTest();
            ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('productIssue_IdDocuments_Idheck()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }


    /**
* Success Case for : Procu Issue
* */
    @IsTest
    public static void productIssue_IdDocuments_LandTitle() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();

            vTestData.productAndSrvWizardData.put('selectedRadio1Name','ID, documents & accounts');
            vTestData.productAndSrvWizardData.put('idDocumentsAccountsEnquiryType','Land title');

            Test.startTest();
            ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('productIssue_IdDocuments_LandTitle()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }
    /**
* Success Case for : Procu Issue
* */
    @IsTest
    public static void productIssue_IdDocuments_Letter() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();

            vTestData.productAndSrvWizardData.put('selectedRadio1Name','ID, documents & accounts');
            vTestData.productAndSrvWizardData.put('idDocumentsAccountsEnquiryType','Letter');

            Test.startTest();
            ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('productIssue_IdDocuments_Letter()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
* Success Case for : Procu Issue
* */
    @IsTest
    public static void productIssue_IdDocuments_MyPost() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();

            vTestData.productAndSrvWizardData.put('selectedRadio1Name','ID, documents & accounts');
            vTestData.productAndSrvWizardData.put('idDocumentsAccountsEnquiryType','MyPost');

            Test.startTest();
            ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('productIssue_IdDocuments_MyPost()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }


    /**
* Success Case for : Procu Issue
* */
    @IsTest
    public static void productIssue_IdDocuments_Passport() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();

            vTestData.productAndSrvWizardData.put('selectedRadio1Name','ID, documents & accounts');
            vTestData.productAndSrvWizardData.put('idDocumentsAccountsEnquiryType','Passport');

            Test.startTest();
            ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('productIssue_IdDocuments_Passport()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
* Success Case for : Procu Issue
* */
    @IsTest
    public static void productIssue_IdDocuments_PoliceCheck() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();

            vTestData.productAndSrvWizardData.put('selectedRadio1Name','ID, documents & accounts');
            vTestData.productAndSrvWizardData.put('idDocumentsAccountsEnquiryType','Police check');

            Test.startTest();
            ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('productIssue_IdDocuments_PoliceCheck()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }
    /**
* Success Case for : Procu Issue
* */
    @IsTest
    public static void productIssue_IdDocuments_TFN() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();

            vTestData.productAndSrvWizardData.put('selectedRadio1Name','ID, documents & accounts');
            vTestData.productAndSrvWizardData.put('idDocumentsAccountsEnquiryType','Tax file number (TFN)');

            Test.startTest();
            ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('productIssue_IdDocuments_TFN()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
* Success Case for : Procu Issue
* */
    @IsTest
    public static void productIssue_IdDocuments_Other() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();

            vTestData.productAndSrvWizardData.put('selectedRadio1Name','ID, documents & accounts');
            vTestData.productAndSrvWizardData.put('idDocumentsAccountsEnquiryType','Other');

            Test.startTest();
            ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('productIssue_IdDocuments_Other()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
* Success Case for : Procu Issue
* */
    @IsTest
    public static void productIssue_OnlineShop() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();

            vTestData.productAndSrvWizardData.put('selectedRadio1Name','Online shop');

            Test.startTest();
            ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('productIssue_OnlineShop()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
* Success Case for : Procu Issue
* */
    @IsTest
    public static void productIssue_Money_BankPost() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();

            vTestData.productAndSrvWizardData.put('selectedRadio1Name','Money');
            vTestData.productAndSrvWizardData.put('selectedRadio3Name','Bank@Post');

            Test.startTest();
            ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('productIssue_Money_BankPost()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }

    /**
* Success Case for : Procu Issue
* */
    @IsTest
    public static void productIssue_Money_PostBillPay() {
        Boolean isSuccess = true;

        try{

            TestData vTestData = wizardDataSetUp();

            vTestData.productAndSrvWizardData.put('selectedRadio1Name','Money');
            vTestData.productAndSrvWizardData.put('selectedRadio3Name','Post Billpay');

            Test.startTest();
            ChasProductsAndServicesController.createCaseFromProductsAndServices(vTestData.productAndSrvWizardData, vTestData.authUserData);
            Test.stopTest();

        }catch(Exception e){
            System.debug('productIssue_Money_PostBillPay()::error==>'+e.getMessage());
            isSuccess = false;
        }
        System.assert(isSuccess);
    }
}