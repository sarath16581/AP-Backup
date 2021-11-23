/**
Description: The apex class - APT_GuideMeController is the controller of visual force page - APT_GuideMe.
The page is being called from Opportunity to redirect on Guided Selling screen from Opportunity.

Created By - Mausam Padhiyar
Created Date - 17th Aug, 2015
Last Modified By -
Last Modified Date -
*/
public with sharing class APT_GuideMeController {
    public boolean haserrorMessages {get; set;}
    
    /**
    constructor
    **/
    public APT_GuideMeController() {
        haserrorMessages = false;
    }
    
    /**
    page action method to redirect on guided selling page
    **/
    public PageReference doRedirect() {
        try {
            String opptyId = string.escapeSingleQuotes(ApexPages.currentPage().getParameters().get(APT_Constants.URL_OPPORTUNITY_ID));
            String accountId = string.escapeSingleQuotes(ApexPages.currentPage().getParameters().get(APT_Constants.URL_ACCOUNT_ID));
            
            //get default price list Id
            //map<String, APT_R2T_System_Properties__c> r2tSystemProperties = APT_R2T_System_Properties__c.getAll();
            APT_R2T_System_Properties__c r2tSystemProperty = APT_R2T_System_Properties__c.getOrgDefaults();
            String priceListId;
            if(r2tSystemProperty != null && r2tSystemProperty.APT_Default_Price_List_ID__c != null) { 
                priceListId = r2tSystemProperty.APT_Default_Price_List_ID__c;
            } else  {
                haserrorMessages = true;
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.ERROR_MESSAGE_MISSING_DEFAULT_PRICELIST_ID));
            }
            
            String classificationID;
            if(r2tSystemProperty != null && r2tSystemProperty.APT_Classification_ID__c != null) {
                classificationID = r2tSystemProperty.APT_Classification_ID__c;
            } else {
                haserrorMessages = true;
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.ERROR_MESSAGE_MISSING_CLASSIFICATION_ID));
            }
            
            String interviewName;
            if(r2tSystemProperty != null && r2tSystemProperty.APT_Interview_Name__c != null) {
                interviewName = r2tSystemProperty.APT_Interview_Name__c;
            } else {
                haserrorMessages = true;
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, APT_Constants.ERROR_MESSAGE_MISSING_INTERVIEW_NAME));
            }
            
            if(haserrorMessages == true) {
                return null;
            }
            
            //get price list
            Apttus_Config2__PriceList__c priceList = [SELECT Id, Name FROM Apttus_Config2__PriceList__c
                                                    WHERE Id = :priceListId limit 1];
                                                    

            
            //create quote
            Apttus_Proposal__Proposal__c proposal = new Apttus_Proposal__Proposal__c();
            proposal.Apttus_Proposal__Opportunity__c = opptyId;
            proposal.Apttus_Proposal__Account__c = accountId;
            proposal.Apttus_QPConfig__PriceListId__c = priceList.Id;
            insert proposal;
            
            proposal = [SELECT Id, Apttus_Proposal__Proposal_Name__c, Apttus_Proposal__Account__c
                        FROM Apttus_Proposal__Proposal__c WHERE Id = :proposal.Id];
            
            //create configuration
            Apttus_Config2__ProductConfiguration__c configuration = new Apttus_Config2__ProductConfiguration__c();
            configuration.Apttus_QPConfig__Proposald__c = proposal.Id;
            configuration.Apttus_Config2__BusinessObjectId__c = proposal.Id;
            configuration.Apttus_Config2__BusinessObjectType__c = APT_Constants.RECORD_TYPE_PROPOSAL;
            configuration.Apttus_Config2__AccountId__c = accountId;
            configuration.Apttus_Config2__PriceListId__c = priceList.Id;
            configuration.Apttus_Config2__EffectivePriceListId__c = priceList.Id;
            configuration.Apttus_Config2__IsTransient__c = true;
            configuration.name = proposal.Apttus_Proposal__Proposal_Name__c;
            insert configuration;
            
            configuration = [SELECT Id, Name, Apttus_Config2__PriceListId__c, 
                            Apttus_Config2__ExpectedStartDate__c, Apttus_Config2__ExpectedEndDate__c  
                            FROM Apttus_Config2__ProductConfiguration__c 
                            WHERE Id = :configuration.Id];
            
            //create temp object
            Apttus_Config2__TempObject__c tempObject = new Apttus_Config2__TempObject__c();
            tempObject.Apttus_Config2__ConfigurationId__c = configuration.Id;
            
            //XML data 
            String strProposal = proposal.Apttus_Proposal__Proposal_Name__c;
            String strConfiguration = configuration.Name;
              
            if(strConfiguration != null && strConfiguration.contains(APT_Constants.SEPERATOR_AND)) {
                strConfiguration = strConfiguration.replace(APT_Constants.SEPERATOR_AND,APT_Constants.SEPERATOR_AND_AMP);
            }
            
            if(strProposal != null && strProposal.contains(APT_Constants.SEPERATOR_AND)) {
                strProposal = strProposal.replace(APT_Constants.SEPERATOR_AND,APT_Constants.SEPERATOR_AND_AMP);
            }
            
            //string to hold proper XML value
            string strData = APT_Constants.XML_STRING1
                            + proposal.Id + APT_Constants.XML_STRING2
                            + strProposal + APT_Constants.XML_STRING3 
                            + configuration.Apttus_Config2__PriceListId__c+APT_Constants.XML_STRING4
                            + proposal.Apttus_Proposal__Account__c 
                            + APT_Constants.XML_STRING5
                            + strConfiguration + APT_Constants.XML_STRING6 
                            + system.now() + APT_Constants.XML_STRING7
                            + proposal.Id + APT_Constants.XML_STRING8
                            + configuration.Apttus_Config2__ExpectedStartDate__c 
                            + APT_Constants.XML_STRING9
                            + configuration.Apttus_Config2__ExpectedEndDate__c + APT_Constants.XML_STRING10;  
           
            tempObject.Apttus_Config2__Data__c = strData;            
            insert tempObject;
            
            return new PageReference(APT_Constants.URL_GUIDED_SELLING_FLOW_PAGE + opptyId + APT_Constants.URL_ID_EQUALS + configuration.Id + APT_Constants.URL_RET_ID + proposal.Id + APT_Constants.URL_BUSINESS_OBJECT_ID_EQUALS + proposal.Id + APT_Constants.URL_CONFIG_REQUEST_ID_EQUALS + tempObject.Id + APT_Constants.URL_INTERVIEW_NAME + interviewName + APT_Constants.URL_CLASSIFICATIONNAME_ID + classificationID);
             
        } catch(Exception ex) {
            haserrorMessages = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
        return null;
    }
}