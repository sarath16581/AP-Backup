@isTest
public class ctrlMyPostDeliveries_Test {
    
    Static testMethod void testDelPrefs()
    {
        test.startTest();
        //select APCN__c, HeightLessThan15M__c, HeightMoreThan05M__c, SafeDropInstruction__c, ParcelLockerRegistered__c from MyPostPreferences__x where APCN__c
        Account acc = new Account(FirstName = 'James', LastName = 'Bond' , PersonEmail = 'J.Bond@austposttest.com.au', APCN__pc='123456789');
		Insert acc;
        MyPostPreferences__x dp = new MyPostPreferences__x(APCN__c = '123456789' , HeightLessThan15M__c = 'Y', HeightMoreThan05M__c = 'Y', SafeDropInstruction__c = '');
        ctrlMyPostDeliveries.prefs.add(dp);
        ApexPages.StandardController stdCont = new ApexPages.standardController(acc);
        ctrlMyPostDeliveries ext = new ctrlMyPostDeliveries(stdCont);
        test.stopTest();
        
       
    }
        Static testMethod void testDelPrefs2()
    {
        test.startTest();
        Account acc = new Account(FirstName = 'James', LastName = 'Bond' , PersonEmail = 'J.Bond@austposttest.com.au', APCN__pc='123456789');
		Insert acc;
        MyPostPreferences__x dp2 = new MyPostPreferences__x(APCN__c = '123456789' , HeightLessThan15M__c = 'Y', HeightMoreThan05M__c = 'N', SafeDropInstruction__c = '');
        ctrlMyPostDeliveries.prefs.add(dp2);
        ApexPages.StandardController stdCont = new ApexPages.standardController(acc);
        ctrlMyPostDeliveries ext = new ctrlMyPostDeliveries(stdCont);
        test.stopTest();
    }
	Static testMethod void testDelPrefs3()
    {
        test.startTest();
        Account acc = new Account(FirstName = 'James', LastName = 'Bond' , PersonEmail = 'J.Bond@austposttest.com.au', APCN__pc='123456789');
		Insert acc;
        MyPostPreferences__x dp2 = new MyPostPreferences__x(APCN__c = '123456789' , HeightLessThan15M__c = 'N', HeightMoreThan05M__c = 'N', SafeDropInstruction__c = '');
        ctrlMyPostDeliveries.prefs.add(dp2);
        ApexPages.StandardController stdCont = new ApexPages.standardController(acc);
        ctrlMyPostDeliveries ext = new ctrlMyPostDeliveries(stdCont);
        test.stopTest();
    }
    	Static testMethod void testDelPrefs4()
    {
        test.startTest();
        Account acc = new Account(FirstName = 'James', LastName = 'Bond' , PersonEmail = 'J.Bond@austposttest.com.au', APCN__pc='123456789');
		Insert acc;
        MyPostPreferences__x dp2 = new MyPostPreferences__x(APCN__c = '123456789' , HeightLessThan15M__c = 'N', HeightMoreThan05M__c = 'Y', SafeDropInstruction__c = '');
        ctrlMyPostDeliveries.prefs.add(dp2);
        ApexPages.StandardController stdCont = new ApexPages.standardController(acc);
        ctrlMyPostDeliveries ext = new ctrlMyPostDeliveries(stdCont);
        test.stopTest();
    }
}