@isTest
public class CustomerSearchCtrl_Test {
    
    @testSetup public static void setup(){
    	LOA_Settings__c setting = new LOA_Settings__c();
        setting.Name = 'Test1';
        setting.Locked_Field_API__c = 'Test1';
        setting.LOA_Value__c = 1;
        insert setting;
    }
	    
    @isTest
    public static void CustomerSearchCtrl_getMinLOA(){
    	Test.startTest();
        Decimal minLOA = CustomerSearchCtrl.getMinLOA();
        Test.stopTest();
    }
    
}