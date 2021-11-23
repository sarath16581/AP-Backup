@isTest
public class ManageAccountControllerExtension_Test {
    
    public static testMethod void testSave() {
        Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
        Account currentAccount = TestUtility.createBusinessAccount('Testing Enterprises 100', 
                         accRecTypeMap.get('Organisation').getRecordTypeId());
        currentAccount.Email__c='testing100@testing.com.tst';
        insert currentAccount;                 
        ApexPages.StandardController sc = new ApexPages.standardController(currentAccount);
        ManageAccountControllerExtension mac = new ManageAccountControllerExtension(sc);
        mac.saveNew=false;
        PageReference pr = mac.saveAccount();
        Account[] accNew = [select Email__c from Account where Name='Testing Enterprises 100'];
        System.assertEquals('testing100@testing.com.tst', accNew[0].Email__c);
    }
    
    public static testMethod void testSaveNew() {
        Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
        Account currentAccount = TestUtility.createBusinessAccount('Testing Enterprises 100', 
                         accRecTypeMap.get('Organisation').getRecordTypeId());
        currentAccount.Email__c='testing100@testing.com.tst';
        insert currentAccount;                 
        ApexPages.StandardController sc = new ApexPages.standardController(currentAccount);
        ManageAccountControllerExtension mac = new ManageAccountControllerExtension(sc);
        mac.saveNew=true;
        mac.newUrl='/apex/ManageAccount';
        PageReference pr = mac.saveAccount();
        System.assertEquals('/apex/ManageAccount',pr.getUrL());
        Account[] accNew = [select Email__c from Account where Name='Testing Enterprises 100'];
        System.assertEquals('testing100@testing.com.tst', accNew[0].Email__c);
    }
    
    public static testMethod void testCopyAddr() {
        Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
        Account currentAccount = TestUtility.createBusinessAccount('Testing Enterprises 100', 
                         accRecTypeMap.get('Organisation').getRecordTypeId());
        ApexPages.StandardController sc = new ApexPages.standardController(currentAccount);
        ManageAccountControllerExtension mac = new ManageAccountControllerExtension(sc);
        mac.billingAddress.line1='111 Bourke Street';
        mac.billingAddress.city='Melbourne';
        mac.billingAddress.state='Victoria';
        mac.billingAddress.postcode='3000';
        mac.saveNew=false;
        mac.copyFromBilling=true;
        mac.copyAddress();
        System.assertEquals('111 Bourke Street', mac.shippingAddress.line1);
        System.assertEquals('Melbourne', mac.shippingAddress.city);
        System.assertEquals('Victoria', mac.shippingAddress.state);
        System.assertEquals('3000', mac.shippingAddress.postcode);
        mac.shippingAddress.line1='100 Miller Street';
        mac.shippingAddress.city='North Sydney';
        mac.shippingAddress.state='NSW';
        mac.shippingAddress.postcode='2020';
        mac.saveNew=false;
        mac.copyFromBilling=false;
        mac.copyAddress();
        System.assertEquals('100 Miller Street', mac.billingAddress.line1);
        System.assertEquals('North Sydney', mac.billingAddress.city);
        System.assertEquals('NSW', mac.billingAddress.state);
        System.assertEquals('2020', mac.billingAddress.postcode);
    }
    
    public static testMethod void testCancel() {
        Account currentAccount = new Account();
        ApexPages.StandardController sc = new ApexPages.standardController(currentAccount);
        ManageAccountControllerExtension mac = new ManageAccountControllerExtension(sc);
        PageReference pr = mac.cancelOp();
        System.assertEquals('/001/o',pr.getUrL());
    }
}