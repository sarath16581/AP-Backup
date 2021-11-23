/**
 * @author Emmanuel Yap
 * @date 2021-09-10
 * @description Test class for Print Duty Template Controller
 * @changelog
 * 2021-09-10 - Emmanuel Yap - Created
*/

@isTest
public class TDF_DutyTemplatePrintControllerYTest {

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
        objJobTemplate.Activity_Type__c = 'Rest Break';
        insert objJobTemplate;  
        
        Job_Template__c objJobTemplate1 = objTestDataFactory.getJobTemplate(objRouteTemplate.Id, objSiteLocation.Id);
        objJobTemplate1.Activity_Type__c = 'Collection';
        insert objJobTemplate1; 
    }

    @isTest 
    static void validateDutyTemplatePrintControllerXMethodOne(){

    	Test.StartTest(); 

        Route_Template__c objRouteTemplate = [select id, name from Route_Template__c where name = 'Test Template' LIMIT 1];

			PageReference pageRef = Page.TDF_DutyTemplatePrint_New; 
			pageRef.getParameters().put('Id', String.valueOf(objRouteTemplate.Id));
			Test.setCurrentPage(pageRef);
        
        	TDF_DutyTemplatePrintControllerY testDTPrint = new TDF_DutyTemplatePrintControllerY(new ApexPages.StandardController(objRouteTemplate));
            System.assertEquals(objRouteTemplate.Id, testDTPrint.routeTemplate.id ,'Asserted Route Template is existing');
            System.assertNotEquals(0, testDTPrint.jobTemplateList.size(),'Assert Job Templates are populated');

		Test.StopTest();              
    } 

    @isTest 
    static void negativeTest(){

    	Test.StartTest(); 

        	PageReference pageRef = Page.TDF_DutyTemplatePrint_New; 
			pageRef.getParameters().put('Id', null);
			Test.setCurrentPage(pageRef);
            try{
                TDF_DutyTemplatePrintControllerY testDTPrint = new TDF_DutyTemplatePrintControllerY(new ApexPages.StandardController(null));
                System.assertEquals(null, testDTPrint.routeTemplate ,'Asserted Route Template is null');
            } catch(NullPointerException ex){
                System.assertEquals(null,null,'System.NullPointerException: Argument cannot be null');
            }
        
		Test.StopTest();              
    } 

}