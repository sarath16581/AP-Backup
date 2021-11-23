/** 
* @author Gaurav
* @date 2017-?-?
* @domain Field Service 
* @description  Test class for clone
*
* @changelog 
* 2020-08-31 - Andrew Judd - Updates for TDF Enhance project
*                               -Changed getTaskTemplate call
*                               -Changed create of Job Template to specify a site, not a vehicle                    
*/
@isTest
public class TDF_DutyTemplateDeepCloneCtrlTest{

	static testmethod void validateDTDeepCloneCtrl(){

        TDF_TestDataFactory objTestDataFactory = new TDF_TestDataFactory();

        OperatingHours objOperatingHours = objTestDataFactory.getOperatingHours('Afternoon Shift');
        insert objOperatingHours;

        ServiceTerritory objServiceTerritory = objTestDataFactory.getServiceTerritory('Dendanong', objOperatingHours.Id);
        insert objServiceTerritory;

        //TDF Enhance 2020-08-31: Comment out and replace with create site
        //Schema.Location objVehicleLocation = new Schema.Location();
        //objVehicleLocation = objTestDataFactory.getLocation('Truck 001', 'Vehicle');
        //insert objVehicleLocation;

        //TDF Enhance 2020-08-31: Create a site loction
        Schema.Location objSiteLocation = new Schema.Location();
        objSiteLocation = objTestDataFactory.getLocation('Acme', 'Site');
        insert objSiteLocation;

        Route_Template__c objRouteTemplate = objTestDataFactory.getDutyTemplate('Test Template', objServiceTerritory.Id);
        insert objRouteTemplate;

        Job_Template__c objJobTemplate = objTestDataFactory.getJobTemplate(objRouteTemplate.Id, objSiteLocation.Id);
        insert objJobTemplate;

        //TDF Enhance 2020-08-31: getTaskTemplate method updated. Create collect from tasks
        Task_Template__c objTaskTemplate = objTestDataFactory.getTaskTemplate(objRouteTemplate.Id, objJobTemplate.Id, null);
        insert objTaskTemplate;

        Profile sysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User objAdminUser = objTestDataFactory.getUser(sysAdmin.Id, 'tdf@australiaPost.com');
        insert objAdminUser;

        ServiceResource objServiceResource = objTestDataFactory.getServiceResource('TDF Test', objAdminUser);
        insert objServiceResource;

        Route_Assignment__c objRouteAssignment = objTestDataFactory.getRouteAssignment(objServiceResource.Id, objRouteTemplate.Id);
        insert objRouteAssignment;      

        PageReference pageRef = Page.TDF_DutyTemplateDeepClone;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', objRouteTemplate.Id);

    	TDF_DutyTemplateDeepCloneControllerX objController = new TDF_DutyTemplateDeepCloneControllerX(new ApexPages.StandardController(objRouteTemplate));                

    	objController.deepCloneDutyTemplate();
	}
}