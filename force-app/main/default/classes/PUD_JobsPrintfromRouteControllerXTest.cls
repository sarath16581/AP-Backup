@isTest
public class PUD_JobsPrintfromRouteControllerXTest {
    
    
    static testmethod void validateBookingPrintControllerXMethodOne(){
        
        //Create test Depot
        Network__c networkDepot = PUDTestUtility.createNetwork ('Kew Van Services', 'Business_Hub_3');
        insert networkDepot;
        
        //Create a Route
        PUD_Route__c route = PUDTestUtility.createRoute ('DT61', networkDepot.Id);
        insert route;
        
        Test.StartTest(); 
        
        PageReference pageRef = Page.PUD_BookingPrint; 
        pageRef.getParameters().put('Id', String.valueOf(route.Id));
        Test.setCurrentPage(pageRef);
        
        PUD_JobsPrintfromRouteControllerX testDTPrint = new PUD_JobsPrintfromRouteControllerX(new ApexPages.StandardController(route));
        
        Test.StopTest();              
    } 
    
}