/*@File Name		: ServiceNowDataProvider2Test
@Description 		: test class for ServiceNowDataProvider2
@Author			: Ramtej Juloori
@Created			: 30/10/2018

================================ Modification Log =============================== 
Developer Name 	Date 			Comments

*/
@isTest
public class ServiceNowDataProvider2Test {
    /*******************************************************************************************************
     * @method name		: ServiceNowDataProvider2TestAllMethods
     * @description 		: method to test all the standard methods from ServiceNowDataProvider2
     * @parameters		: None
     * @returns 			: void
     */
    public testMethod static void ServiceNowDataProvider2TestAllMethods(){
        //initialize the class
        ServiceNowDataProvider2 dataProvider = new ServiceNowDataProvider2();
        //test authentication method which define the auth type used to connect to external source
        dataProvider.getAuthenticationCapabilities();
        //test capability method which defines the dml operation types on external object
        dataProvider.getCapabilities();
    }
}