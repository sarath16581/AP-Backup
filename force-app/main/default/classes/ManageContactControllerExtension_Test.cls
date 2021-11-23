@isTest
public class ManageContactControllerExtension_Test {
	public static testMethod void testSave() {
        Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
        Account currentAccount = TestUtility.createBusinessAccount('Stark and Co', 
                         accRecTypeMap.get('Organisation').getRecordTypeId());
        currentAccount.Email__c='stark@stark.com.tst';
        insert currentAccount; 
        
        Contact currentContact = TestUtility.createContact('Arya', 'Stark', 'arya.stark@stark.com.tst', currentAccount.Id);
        insert currentContact;
        ApexPages.StandardController sc = new ApexPages.standardController(currentContact);
        ManageContactControllerExtension mcc = new ManageContactControllerExtension(sc);
        mcc.saveNew=false;
        PageReference pr = mcc.saveContact();
        Contact conNew = [select Email from Contact where Name='Arya Stark'];
        System.assertEquals('arya.stark@stark.com.tst', conNew.Email);
    }
    
    public static testMethod void testSaveNew() {
        Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
        Account currentAccount = TestUtility.createBusinessAccount('Stark and Co', 
                         accRecTypeMap.get('Organisation').getRecordTypeId());
        currentAccount.Email__c='stark@stark.com.tst';
        insert currentAccount; 
        
        Contact currentContact = TestUtility.createContact('Arya', 'Stark', 'arya.stark@stark.com.tst', currentAccount.Id);
        insert currentContact;
        ApexPages.StandardController sc = new ApexPages.standardController(currentContact);
        ManageContactControllerExtension mcc = new ManageContactControllerExtension(sc);
        mcc.saveNew=true;
        mcc.newUrl='/apex/ManageContact';
        PageReference pr = mcc.saveContact();
        System.assertEquals('/apex/ManageContact',pr.getUrL());
        Contact conNew = [select Email from Contact where Name='Arya Stark'];
        System.assertEquals('arya.stark@stark.com.tst', conNew.Email);
    }
    
    public static testMethod void testCopyAddr() {
        Map<String,Schema.RecordTypeInfo> accRecTypeMap = Schema.Sobjecttype.Account.getRecordTypeInfosByName();
        Account currentAccount = TestUtility.createBusinessAccount('Stark and Co', 
                         accRecTypeMap.get('Organisation').getRecordTypeId());
        currentAccount.Email__c='stark@stark.com.tst';
        insert currentAccount; 
        
        Contact currentContact = TestUtility.createContact('Arya', 'Stark', 'arya.stark@stark.com.tst', currentAccount.Id);
        
        ApexPages.StandardController sc = new ApexPages.standardController(currentContact);
        
        ManageContactControllerExtension mcc = new ManageContactControllerExtension(sc);
        mcc.mailingAddress.line1='111 Bourke Street';
        mcc.mailingAddress.city='Melbourne';
        mcc.mailingAddress.state='Victoria';
        mcc.mailingAddress.postcode='3000';
        mcc.saveNew=false;
        mcc.copyFromMailing=true;
        mcc.copyAddress();
        System.assertEquals('111 Bourke Street', mcc.otherAddress.line1);
        System.assertEquals('Melbourne', mcc.otherAddress.city);
        System.assertEquals('Victoria', mcc.otherAddress.state);
        System.assertEquals('3000', mcc.otherAddress.postcode);
        mcc.otherAddress.line1='100 Miller Street';
        mcc.otherAddress.city='North Sydney';
        mcc.otherAddress.state='NSW';
        mcc.otherAddress.postcode='2020';
        mcc.saveNew=false;
        mcc.copyFromMailing=false;
        mcc.copyAddress();
        System.assertEquals('100 Miller Street', mcc.otherAddress.line1);
        System.assertEquals('North Sydney', mcc.otherAddress.city);
        System.assertEquals('NSW', mcc.otherAddress.state);
        System.assertEquals('2020', mcc.otherAddress.postcode);
    }
    
    public static testMethod void testCancel() {
        Contact currentContact = new Contact();
        ApexPages.StandardController sc = new ApexPages.standardController(currentContact);
        ManageContactControllerExtension mcc = new ManageContactControllerExtension(sc);
        PageReference pr = mcc.cancelOp();
        System.assertEquals('/003/o',pr.getUrL());
    }
}