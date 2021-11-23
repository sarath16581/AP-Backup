/*@File Name		: ServiceNow_ChooseTemplateApexCtrltTest
@Description 		: Apex class to get the list of service now templates
@Author				: Ramtej Juloori
@Created			: 01/07/2018

================================ Modification Log =============================== 
Developer Name 	Date 			Comments

*/ 
@isTest
public class ServiceNow_ChooseTemplateApexCtrltTest {

	/*******************************************************************************************************
     * @method name		: setupData
     * @description 		: method to setup the data required for test methods in this class
     * @parameters		: None
     * @returns 			: void
     */    
    @testsetup
    public static void setupData(){
        //Create template and insert template values
        Service_Now_Data_Template__c temp = new Service_Now_Data_Template__c(Template_Name__c = 'TestTemp', Is_Active__c = true);
        List<Service_Now_Data_Template__c> tempList = new List<Service_Now_Data_Template__c>{temp};
        insert tempList;
        
        Service_Now_Template_Value__c tempValue = new Service_Now_Template_Value__c(Service_Now_Data_Template__c = temp.Id, Field_Name__c = 'description__c', Field_Value__c = 'Parcel Send Login/Despatch (\'C\' number issue) assistance for following user:- Contact Name:- Contact Email:-Contact Phone:-Additional Comment', Object_Name__c = 'Service_Now_Case__x');
        Service_Now_Template_Value__c tempValue1 = new Service_Now_Template_Value__c(Service_Now_Data_Template__c = temp.Id, Field_Name__c = 'short_description__c', Field_Value__c = 'Parcel Send Customer logged into MyPost Business', Object_Name__c = 'Service_Now_Case__x');
        Service_Now_Template_Value__c tempValue2 = new Service_Now_Template_Value__c(Service_Now_Data_Template__c = temp.Id, Field_Name__c = 'Case_Type__c', Field_Value__c = 'Restoration', Object_Name__c = 'Service_Now_Case__x');
        Service_Now_Template_Value__c tempValue3 = new Service_Now_Template_Value__c(Service_Now_Data_Template__c = temp.Id, Field_Name__c = 'Channel__c', Field_Value__c = 'Salesforce', Object_Name__c = 'Service_Now_Case__x');
        List<Service_Now_Template_Value__c> tempValueList = new List<Service_Now_Template_Value__c>{tempValue, tempValue1, tempValue2, tempValue3};
        insert tempValueList;
    }
    
    /*******************************************************************************************************
     * @method name		: setupData
     * @description 		: method to test getTemplateList from ServiceNow_ChooseTemplateApexController
     * @parameters		: None
     * @returns 			: void
     */ 
    public testMethod static void testGetWrapList(){
        Test.startTest();
        List<ServiceNow_ChooseTemplateApexController.templateWrapper> tempWrap = ServiceNow_ChooseTemplateApexController.getTemplateList();
        system.assertEquals(true, tempWrap != null);
        Test.stopTest();
    }
}