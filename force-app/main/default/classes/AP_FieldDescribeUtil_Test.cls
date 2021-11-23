@IsTest (IsParallel=true)
public class AP_FieldDescribeUtil_Test {
    @IsTest
    public static void getDependentOptionsImpl_Test(){
        Map<String, List<String>> depFieldsMap = new Map<String, List<String>>();
        
        Schema.DescribeFieldResult fieldResult = Case.ProductCategory__c.getDescribe();
        Schema.sObjectField productCategoryField = fieldResult.getSObjectField();
        
        fieldResult = Case.ProductSubCategory__c.getDescribe();
        Schema.sObjectField productSubCategoryField = fieldResult.getSObjectField();
        
        Test.startTest();
        depFieldsMap = AP_FieldDescribeUtil.getDependentPicklistValues	(productSubCategoryField, productCategoryField);
        Test.stopTest();
		System.assert(depFieldsMap.size()>0, 'Dependent Picklist Values found');
    }
    
    @IsTest
    public static void PicklistEntryWrapper_Test(){
        AP_FieldDescribeUtil.PicklistEntryWrapper pwrap = new AP_FieldDescribeUtil.PicklistEntryWrapper();
        Test.startTest();
        
        pwrap.active='true';
        pwrap.defaultValue = 'defaultvalue';
        pwrap.label ='label';
        pwrap.value ='value';
        pwrap.validFor='validfor';
        Test.stopTest();
        
        System.assert(pwrap.active.length() > 0, 'Value found for Active variable.');
    }
}