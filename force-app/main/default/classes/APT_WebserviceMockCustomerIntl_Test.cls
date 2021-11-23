@isTest
private class APT_WebserviceMockCustomerIntl_Test {

	private static testMethod void testMethod1() {
	    Test.startTest();
	   
	    APT_WebserviceMockCustomerInternational obj1 = new APT_WebserviceMockCustomerInternational ();
	    Object obj = 10;
        obj1.doInvoke(obj,obj,new Map<String,Object>{'KeyValueA' => obj}, 'endpoint', 'soapAction','requestName','responseNS','responseName','responseType');
        
        Test.stopTest();
	}

}