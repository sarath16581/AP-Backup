@isTest
public class TDF_ProductTriggerOnDeleteTest{

    public static testmethod void validateProductDeleteTrigger(){

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory(); 

        TDF_Products__c objTDFProduct = new TDF_Products__c();
        objTDFProduct.Name = 'Test 101 Product';
        insert objTDFProduct;

        Product2 objProduct = objTestDataFactory.getProduct('Test 101 Product');
        insert objProduct;

        try{
        	delete objProduct;
        }catch(DmlException e){
        	Boolean expectedExceptionThrown =  e.getMessage().contains('This Product can not be deleted') ? true : false;
			System.AssertEquals(expectedExceptionThrown, true);
        }
    }
}