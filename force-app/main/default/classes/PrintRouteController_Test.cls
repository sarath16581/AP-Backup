/**
 * Created by kamilszyc on 1/7/2022.
 */

@IsTest
private class PrintRouteController_Test {
    @IsTest
    static void testGetBookingsForMultipleRoutes() {

        //Create test Depot
        Network__c networkDepot = PUDTestUtility.createNetwork ('Kew Van Services', 'Business_Hub_3');
        List<PUD_Route__c> routeList = new List<PUD_Route__c>();
        //Create routes
        PUD_Route__c route1 = PUDTestUtility.createRoute ('DT61', networkDepot.Id);
        routeList.add(route1);
        PUD_Route__c route2 = PUDTestUtility.createRoute ('DT62', networkDepot.Id);
        routeList.add(route2);

        ApplicationTestDataFactory.generateRecordIds(routeList);//I don't think I need this

        // =====================================
        // Stubbing
        // =====================================
        //
        PUDRoutesSelector routesSelector = (PUDRoutesSelector)MockUtility.mockSelector(PUDRoutesSelector.class);
        // set up responses
        MockUtility.Mocks.startStubbing();

        MockUtility.Mocks.when(routesSelector.selectByIdWithActiveBookings((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject()))
                .thenReturn(routeList
                );
        MockUtility.Mocks.stopStubbing();


        Test.startTest();

        PageReference pageRef = Page.PUD_JobPrintFromRoutesList;
        Test.setCurrentPage(pageRef);

        PUD_PrintRouteController testRoutesPrint = new PUD_PrintRouteController(new ApexPages.StandardSetController(routeList));
        Test.stopTest();
        System.assertNotEquals(null, testRoutesPrint.routes, 'The selector has not returned a list of routes');
        System.assert(!testRoutesPrint.routes.isEmpty(), 'Expected routes were not returned by the controller');
    }
    @IsTest
    static void testGetBookingsForSingleRoute() {
        //Create test Depot
        Network__c networkDepot = PUDTestUtility.createNetwork ('Kew Van Services', 'Business_Hub_3');
        //Create a route
        PUD_Route__c route1 = PUDTestUtility.createRoute ('DT61', networkDepot.Id);

        // =====================================
        // Stubbing
        // =====================================
        //
        PUDRoutesSelector routesSelector = (PUDRoutesSelector)MockUtility.mockSelector(PUDRoutesSelector.class);
        // set up responses
        MockUtility.Mocks.startStubbing();

        MockUtility.Mocks.when(routesSelector.selectByIdWithActiveBookings((Set<Id>) fflib_Match.anyObject(), (Set<Id>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject()))
                .thenReturn(new List<PUD_Route__c>{route1}
                );
        MockUtility.Mocks.stopStubbing();


        Test.startTest();

        PageReference pageRef = Page.PUD_JobPrintFromRoutesList;
        Test.setCurrentPage(pageRef);

        PUD_PrintRouteController testRoutesPrint = new PUD_PrintRouteController(new ApexPages.StandardController(route1));
        Test.stopTest();
        System.assertNotEquals(null, testRoutesPrint.route, 'The selector has not returned a route');
    }
}