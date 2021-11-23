/*@File Name        : ServiceNow_CreatePageApexController2Test
@Description        : Apex class to test ServiceNow_CreatePageApexController2
@Author             : Ramtej Juloori
@Created            : 15/08/2018

================================ Modification Log =============================== 
Developer Name                      Date            Comments
hasantha.liyanage@auspost.com.au    15/05/2019      File upload capability added
*/ 
@isTest
public with sharing class ServiceNow_CreatePageApexController2Test {
    
    /*
     * @method name		: setupData
     * @description 		: method to setup the data required for test methods in this class
     * @parameters		: None
     * @returns 			: void
     */
    @testsetup
    public static void setupData(){
        //Create template and insert template values
        Service_Now_Data_Template__c temp = new Service_Now_Data_Template__c(Template_Name__c = 'TestTemp');
        List<Service_Now_Data_Template__c> tempList = new List<Service_Now_Data_Template__c>{temp};
        insert tempList;
        //Create template values for the inserted templates
        Service_Now_Template_Value__c tempValue = new Service_Now_Template_Value__c(Service_Now_Data_Template__c = temp.Id, Field_Name__c = 'description__c', Field_Value__c = 'Parcel Send Login/Despatch (\'C\' number issue) assistance for following user:- Contact Name:- Contact Email:-Contact Phone:-Additional Comment', Object_Name__c = 'Service_Now_Case__x');
        Service_Now_Template_Value__c tempValue1 = new Service_Now_Template_Value__c(Service_Now_Data_Template__c = temp.Id, Field_Name__c = 'short_description__c', Field_Value__c = 'Parcel Send Customer logged into MyPost Business', Object_Name__c = 'Service_Now_Case__x');
        Service_Now_Template_Value__c tempValue2 = new Service_Now_Template_Value__c(Service_Now_Data_Template__c = temp.Id, Field_Name__c = 'Case_Type__c', Field_Value__c = 'Restoration', Object_Name__c = 'Service_Now_Case__x');
        Service_Now_Template_Value__c tempValue3 = new Service_Now_Template_Value__c(Service_Now_Data_Template__c = temp.Id, Field_Name__c = 'Channel__c', Field_Value__c = 'Salesforce', Object_Name__c = 'Service_Now_Case__x');
        List<Service_Now_Template_Value__c> tempValueList = new List<Service_Now_Template_Value__c>{tempValue, tempValue1, tempValue2, tempValue3};
        insert tempValueList;

        AusPostSettings__c auspostSettings = new AusPostSettings__c();
        auspostSettings.Name = 'ServiceNowCredentials';
        auspostSettings.URL__c = 'TestURL';
        auspostSettings.Username__c = 'TestUserName';
        auspostSettings.Password__c = 'TestPassword';
        insert auspostSettings;
        
        
    }
    /*
     * @method name		: saveSNCaseWithoutTemplate
     * @description 		: method to test create Service now case method without template
     * @parameters		: None
     * @returns 			: void
     */
    public testMethod static void saveSNCaseWithoutTemplate(){
        //setting mock response for servicenowCasePageLayout
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('ServiceNowCasePageLayoutMock');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
		// Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        List<LayoutAPIRoot.DetailLayoutSection> serviceNowCaseLayout = ServiceNow_CreatePageApexController2.getFieldWrapList('Service_Now_Case__x', '', '', '');
        string caseId = ServiceNow_CreatePageApexController2.save(JSON.serialize(serviceNowCaseLayout), 'Service_Now_Case__x', '', '', '');
        system.assertEquals(true, string.isNotBlank(caseId));
        Test.stopTest();
    }
    
     /*
     * @method name		: saveSNCaseWithTemplate
     * @description 		: method to test create Service now case method with template
     * @parameters		: None
     * @returns 			: void
     */
    public testMethod static void saveSNCaseWithTemplate(){
        //setting mock response for servicenowCasePageLayout
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('ServiceNowCasePageLayoutMock');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
		// Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);
        string templateId = [SELECT Id FROM Service_Now_Data_Template__c LIMIT 1].Id;
        Test.startTest();
        List<LayoutAPIRoot.DetailLayoutSection> serviceNowCaseLayout = ServiceNow_CreatePageApexController2.getFieldWrapList('service_now_case__x', '', '', templateId);
        string caseId = ServiceNow_CreatePageApexController2.save(JSON.serialize(serviceNowCaseLayout), 'service_now_case__x', '', '', '');
        system.assertEquals(true, string.isNotBlank(caseId));
        Test.stopTest();
    }
    
    /*
     * @method name		: saveSNCaseWithRecordId
     * @description 		: method to test create Service now case method with recordId
     * @parameters		: None
     * @returns 			: void
     */
    public testMethod static void saveSNCaseWithRecordId(){
        //setting mock response for servicenowCasePageLayout
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('ServiceNowCasePageLayoutMock');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
		// Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);
        string templateId = [SELECT Id FROM Service_Now_Data_Template__c LIMIT 1].Id;
        Test.startTest();
        List<LayoutAPIRoot.DetailLayoutSection> serviceNowCaseLayout = ServiceNow_CreatePageApexController2.getFieldWrapList('service_now_case__x', '', 'testId', templateId);
        string caseId = ServiceNow_CreatePageApexController2.save(JSON.serialize(serviceNowCaseLayout), 'service_now_case__x', templateId, '', 'testId');
        system.assertEquals(true, string.isNotBlank(caseId));
        system.assertEquals('test class insert ', caseId);
        Test.stopTest();
    }
    
    /*
     * @method name		: saveSNCaseComment
     * @description 		: method to test create Service now case comment
     * @parameters		: None
     * @returns 			: void
     */
    public testMethod static void saveSNCaseComment(){
        //setting mock response for servicenowCasePageLayout
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('ServiceNowCaseCommentPageLayoutMock');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
		// Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);
        string templateId = [SELECT Id FROM Service_Now_Data_Template__c LIMIT 1].Id;
        Test.startTest();
        List<LayoutAPIRoot.DetailLayoutSection> serviceNowCaseLayout = ServiceNow_CreatePageApexController2.getFieldWrapList('Service_Now_Case_Comment__x', '', '', '');
        string caseCommentId = ServiceNow_CreatePageApexController2.save(JSON.serialize(serviceNowCaseLayout), 'Service_Now_Case_Comment__x', '', '', '');
        system.assertEquals(true, string.isNotBlank(caseCommentId));
        string caseCommentId2 = ServiceNow_CreatePageApexController2.save(JSON.serialize(serviceNowCaseLayout), 'Service_Now_Case_Comment__x', templateId, '', '');
        system.assertEquals(true, string.isNotBlank(caseCommentId2));
        system.assertEquals('test class insert ', caseCommentId);
        Test.stopTest();
    }
    
    /*
     * @method name		: testAllMethods
     * @description 		: method to test helper methods in ServiceNow_CreateApexController2
     * @parameters		: None
     * @returns 			: void
     */
    public testMethod static void testAllMethods(){
        Service_Now_Data_Template__c templateRecord = [SELECT Id FROM Service_Now_Data_Template__c LIMIT 1];
        Test.startTest();
        ServiceNowUtility.getNameByIdUtility(templateRecord.Id);
        ServiceNowUtility.getNameByIdUtility(null);
        ServiceNowUtility.getNameByIdUtility('null');
        string objectPrefix = ServiceNow_CreatePageApexController2.getObjectPrefix('Service_Now_Data_Template__c');
        system.assertEquals(true, string.isNotBlank(objectPrefix));
        string objectName = ServiceNow_CreatePageApexController2.getObjectNameById(templateRecord.Id);
        system.assertEquals('Service_Now_Data_Template__c', objectName);
        boolean validateRecordTrue = ServiceNow_CreatePageApexController2.validSelectedRecord(templateRecord.Id, 'Service_Now_Data_Template__c');
        system.assertEquals(true, validateRecordTrue);
        boolean validateRecordFalse = ServiceNow_CreatePageApexController2.validSelectedRecord(templateRecord.Id, 'ErrorObjectName');
        system.assertEquals(true, validateRecordFalse);
        boolean validateRecordFalse2 = ServiceNow_CreatePageApexController2.validSelectedRecord('ErrorRecordId', 'ErrorObjectName');
        system.assertEquals(false, validateRecordFalse2);
        string instanceURL = ServiceNow_CreatePageApexController2.getServiceNowInstanceURL();
        system.assertEquals('TestURL',instanceURL);
        Test.stopTest();
    }

    /*
     * @method name		: savemethodWithException
     * @description 		: method to test save case/case comment with exception
     * @parameters		: None
     * @returns 			: void
     */
    public testMethod static void savemethodWithException(){
        //setting mock response for servicenowCasePageLayout
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('ServiceNowCaseCommentPageLayoutMock');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
		// Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        try{
        	List<LayoutAPIRoot.DetailLayoutSection> serviceNowCaseLayout = ServiceNow_CreatePageApexController2.getFieldWrapList('Service_Now_Case_Comment__x', '', '', '');
            string caseCommentId = ServiceNow_CreatePageApexController2.save(JSON.serialize(serviceNowCaseLayout), 'ErrorObjectForException', '', '', '');
        }
        catch(AuraHandledexception ex){
            system.debug('cause '+ex.getMessage());
        }
        Test.stopTest();
    }
    
    /*
     * @method name		: testLayoutAPIRoot
     * @description 		: method to test LayoutAPIRoot class
     * @parameters		: None
     * @returns 			: void
     */
    public testMethod static void testLayoutAPIRoot(){
        LayoutAPIRoot APIRoot = new LayoutAPIRoot();
        APIRoot.detailLayoutSections = new List<LayoutAPIRoot.DetailLayoutSection>();
        APIRoot.editLayoutSections = new List<LayoutAPIRoot.DetailLayoutSection>();
        
        LayoutAPIRoot.DetailLayoutSection detailSection = new LayoutAPIRoot.DetailLayoutSection();
        detailSection.heading = '';
		detailSection.useHeading = false;
		detailSection.useCollapsibleSection = false;        
        
        LayoutAPIRoot.Details details = new LayoutAPIRoot.Details();
		details.label = '';
		details.updateable = false;
		details.dateTimevalue = system.now();
		details.dateValue = system.today();
		details.booleanValue = false;
		details.decimalValue = 0;

		LayoutAPIRoot.LayoutComponent layoutComponent = new LayoutAPIRoot.LayoutComponent();
		layoutComponent.displayLines = 0;
        layoutComponent.required = false;
        layoutComponent.tabOrder = 1;
        layoutComponent.type = '';
        layoutComponent.value = '';
        
        LayoutAPIRoot.LayoutItem layoutItem = new LayoutAPIRoot.LayoutItem();
        layoutItem.label = '';
        layoutItem.required = false;
    }
    
}