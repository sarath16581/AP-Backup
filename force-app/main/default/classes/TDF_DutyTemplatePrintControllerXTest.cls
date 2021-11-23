@isTest
public class TDF_DutyTemplatePrintControllerXTest {
    static testmethod void validateDutyTemplatePrintControllerXMethodOne(){

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

		Test.StartTest(); 

			PageReference pageRef = Page.TDF_DutyTemplatePrint; 
			pageRef.getParameters().put('Id', String.valueOf(objRouteTemplate.Id));
			Test.setCurrentPage(pageRef);
        
        	TDF_DutyTemplatePrintControllerX testDTPrint = new TDF_DutyTemplatePrintControllerX(new ApexPages.StandardController(objRouteTemplate));

		Test.StopTest();              
    } 
}