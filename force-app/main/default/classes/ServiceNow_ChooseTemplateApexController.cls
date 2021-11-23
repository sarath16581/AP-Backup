/*@File Name		: ServiceNow_ChooseTemplateApexController
@Description 		: Apex class to get the list of service now templates
@Author				: Ramtej Juloori
@Created			: 01/07/2018

================================ Modification Log =============================== 
Developer Name 	Date 			Comments

*/ 
public with sharing class ServiceNow_ChooseTemplateApexController {
    /*******************************************************************************************************
* @method name		: getTemplateList		
* @description 		: get llist of all templates available grouped by RecordType
* @returns 			: List<templateWrapper>
*/
	@AuraEnabled
    public static List<templateWrapper> getTemplateList(){
        Map<string,List<Service_Now_Data_Template__c>> templateMap = new Map<string,List<Service_Now_Data_Template__c>>();
        List<templateWrapper> temWrapList = new List<templateWrapper>();
        List<templateinnerWrapper> innerTempList = new List<templateinnerWrapper>();
        for(Service_Now_Data_Template__c snTemp :[SELECT Id, Template_Name__c FROM Service_Now_Data_Template__c WHERE Is_Active__c = true]){
            templateinnerWrapper tempInnerWrap = new templateinnerWrapper();
            tempInnerWrap.templateName = snTemp.Template_Name__c;
            tempInnerWrap.templateId = snTemp.Id;
            innerTempList.add(tempInnerWrap);
        }
        templateWrapper tempWrap = new templateWrapper();
        tempWrap.recordTypeName = 'RecordTypeHolder';
        tempWrap.templateinnerWrapList = innerTempList;
        temWrapList.add(tempWrap);
        return temWrapList;
       
    }
    /*******************************************************************************************************
* @class name		: templateWrapper		
* @description 		: Wrapper class to hold service now templates info Grouped into record type
* @returns 			: NA
*/
    public class templateWrapper{
        @AuraEnabled public string recordTypeName {get; set;}
        @AuraEnabled public List<templateinnerWrapper> templateinnerWrapList {get; set;}
    }
    
       /*******************************************************************************************************
* @class name		: templateinnerWrapper		
* @description 		: Wrapper class to hold service now templates info
* @returns 			: NA
*/
    public class templateinnerWrapper{
        @AuraEnabled public string templateName {get; set;}
        @AuraEnabled public string templateId {get; set;}
    }
}