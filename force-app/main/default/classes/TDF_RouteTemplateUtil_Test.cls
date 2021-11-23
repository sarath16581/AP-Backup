/**
 * @author Emmanuel Yap
 * @date 2021-09-10
 * @group Tests
 * @description Test class of RouteTemplateUtil
 * @changelog
 * 2021-09-10 - Emmanuel Yap - Created
*/
@IsTest
public with sharing class TDF_RouteTemplateUtil_Test {

    @testSetup 
    static void setup() {
        // Create common test accounts
        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Afternoon Shift');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dendanong', objOperatingHours.Id);
        insert objServiceTerritory;

        Route_Template__c objRouteTemplate = objTestDataFactory.getDutyTemplate('Test Template', objServiceTerritory.Id);
        insert objRouteTemplate;

        Schema.Location objSiteLocation = new Schema.Location();
        objSiteLocation = objTestDataFactory.getLocation('Dendanong', 'Site');
        insert objSiteLocation;

        Job_Template__c objJobTemplate = objTestDataFactory.getJobTemplate(objRouteTemplate.Id, objSiteLocation.Id);
        insert objJobTemplate;       
    }

    /**
     * Test:
     *  Testing selectBy[Method] methods.
     */
    @IsTest
    public static void testSelectByMethods() {

        Test.startTest();
        Route_Template__c objRouteTemplate = [select id, name from Route_Template__c where name = 'Test Template' LIMIT 1];
        
        Route_Template__c routeTemplate = TDF_RouteTemplateUtil.getRouteTemplateFromID(objRouteTemplate.id);
        System.assertEquals(objRouteTemplate.id, routeTemplate.id ,'Asserted Route Template is existing');
        
        List<Job_Template__c> jobTemplate = TDF_RouteTemplateUtil.getJobTemplateFromDutyTemplateId(objRouteTemplate.id);
        System.assertNotEquals(0, jobTemplate.size(),'Assert Job Templates are populated');

        Test.stopTest();
    }

    @isTest 
    public static void negativeTest(){

        Test.startTest();
        Route_Template__c routeTemplate = TDF_RouteTemplateUtil.getRouteTemplateFromID('no such id');
        System.assertEquals(null, routeTemplate ,'No Route Template found');
        
        List<Job_Template__c> jobTemplate = TDF_RouteTemplateUtil.getJobTemplateFromDutyTemplateId('no such id');
        System.assertEquals(0, jobTemplate.size(),'Empty Job Template List');

        Test.stopTest();        
    } 

}