/**
 ** Description: Controller for StarTrackNoDataConsignmentPA Page
 ** Author: Jen Karen Tan
 ** Date Created: SEP.07.2016
 ** Modified by: David Catindoy - Sept. 12, 2016 Finalized the controller
 **/
public with sharing class StarTrackNoDataConsignmentPAController {


    public Case existingCase {get; set;}
    public Boolean validation {get; set;}
    public String selectedDeliveryType {get; set;}
    public Boolean noDataConsignment {get; set;}
    public Id caseId {get; set;}
    
    

    public StarTrackNoDataConsignmentPAController(ApexPages.StandardController con){
        caseId = con.getId();
        initialize(); //Call method to initialize container/variables.
    }

    //Initialize delivery type picklist selection.
    public List<SelectOption> getDeliveryTypeValues() {
        List<SelectOption> option = new List<SelectOption>();
        option.add(new SelectOption('', StarTrack_Constants.GLOBAL_NONE));
        for(StarTrackPicklistSettings__c sps : [SELECT Name, PicklistFieldName__c, PicklistValue__c FROM StarTrackPicklistSettings__c WHERE PicklistFieldName__c =: StarTrack_Constants.DELIVERY_TYPE]) {
            option.add(new SelectOption(sps.PicklistValue__c, sps.PicklistValue__c));
        }
        return option;
    }
    public void initialize(){
        
        //Query case record.
        existingCase = [SELECT Id, Origin, Status, Network__r.Parent_Network__c, Network__r.Email__c, ArticleTest__c, Network__c, Priority, Enquiry_Type__c, Network__r.Preferred_Method_of_Tasking__c, ArticleTest__r.ReceiverName__c, 
                        ArticleTest__r.ActualWeight__c, ArticleTest__r.Number_of_Items__c, ArticleTest__r.Unit_Type__c, Network__r.RecordType.DeveloperName, ArticleTest__r.ReceiverPostcode__c, ArticleTest__r.Receiver_Suburb__c, RecordType.Name,
                        Primary_Name__c, Address1__c, Address3Suburb__c, Address3Postcode__c, StarTrack_Receiver_Name__c, Address4__c, Address4Suburb__c, Address4Postcode__c, Service_Type__c, Number_of_Items__c, Unit_Type__c, ArticleTest__r.Name,
                        No_Data_Capture_DateTime__c, No_Data_Change__c, Number_of_No_Data_Consignment_Updates__c, ArticleTest__r.Service_Type__c, OwnerId, LDC_System_Check__c
                        FROM Case WHERE ID =: caseId];
                        
        //Validation variable to check of validaition is sucessful before save.
        validation = false;
        noDataConsignment = String.isNotBlank(existingCase.ArticleTest__c) && String.isBlank(existingCase.ArticleTest__r.ReceiverPostcode__c) && String.isBlank(existingCase.ArticleTest__r.Receiver_Suburb__c) ? true : false;
        selectedDeliveryType = noDataConsignment ? '' : (String.isNotBlank(existingCase.ArticleTest__c) ? existingCase.ArticleTest__r.Service_Type__c : '');
    }


    public void updateRecord() {
        if(String.isNotBlank(existingCase.ArticleTest__c)){
            if(String.isBlank(selectedDeliveryType) && noDataConsignment){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, StarTrack_Constants.ERRORMSG_DELIVERYTYPE));
            } else if(!noDataConsignment){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, StarTrack_Constants.ERRORMSG_CONSIGNNODATA));
            } else if(String.valueOf(existingCase.OwnerId).startsWith(StarTrack_Constants.QUEUE_PREFIX)){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, StarTrack_Constants.ERRORMSG_OWNERISQUEUE));
            } else if(StarTrack_Constants.CASE_ENQUIRY_LDC.equals(existingCase.Enquiry_Type__c) && existingCase.LDC_System_Check__c){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, StarTrack_Constants.ERRORMSG_LDCCASE));
            } else{
                existingCase.No_Data_Change__c = true;
                existingCase.Number_of_No_Data_Consignment_Updates__c += 1;
                existingCase.ArticleTest__r.Service_Type__c = selectedDeliveryType;
                StarTrackUtil.calculateCaseDepot(new List<Case>{existingCase});
                try{
                    Database.update(existingCase);
                    validation = true;
                }catch(DMLException err){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, err.getMessage()));
                }
            }
        } else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'This action cannot be performed until a consignment is associated to the case.'));
        }
    }

}