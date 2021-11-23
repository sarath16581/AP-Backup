/**
 *Test class for schema classes.
 @author Fuqi Tan
 @created 2014-06-20
 *- Test coverage 90%
 * changelog:
 * 2021-09-09	seth.heang@auspost.com.au		Uplift SF API version to 52
*/

@isTest
private class AuspostTrackEventService_Test{
    @IsTest
    static void testGeneral(){
        AuspostTrackEventService service = new AuspostTrackEventService();
        AuspostTrackEventService.EventManagement_v1Endpoint1 endpoint = 
            new AuspostTrackEventService.EventManagement_v1Endpoint1();
    }
}