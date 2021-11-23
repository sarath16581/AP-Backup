/**************************************************************************************
Description:    Test class to cover cpNavBarController functionality
History:
---------------------------------------------------------------------------------------
12-11-2018  Rahul Kapoor  Created
***************************************************************************************/
@IsTest
public class cpNavBarControllerTest {

    /*********************************************************************************
    *  Scenario:
    *      Test to get menu items.
    **********************************************************************************/
    static testMethod void testGetMenuItems() {
        Test.startTest();

        //Call the getMenuItems method in Controller to cover code coverage.
        List<NavigationMenuItem> menuItem = cpNavBarController.getMenuItems();

        Test.stopTest();

    }
}