/*
* created by: George Nguyen
* description: Test class for OmniBugRedirectController
*/
@IsTest
public class OmniBugRedirectController_Test {
    
    @IsTest
    static void ensureThatOrgDomainUrlReturnsTheCorrectUrl() {
        OmniBugRedirectController controller = new OmniBugRedirectController();
        String expected = URL.getOrgDomainUrl().toExternalForm();
        String actual = controller.orgDomainUrl;
        System.assertEquals(expected, actual, 'urls needs to match');
    }
}
