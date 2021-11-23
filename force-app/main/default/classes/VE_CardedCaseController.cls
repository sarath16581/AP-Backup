/**
  * @author       : nandan.narasappa@auspost.com.au
  * @date         : 31/10/2016
  * @description  : Controller for visualforce component "VE_CardedCase"
  */
/*******************************  History ************************************************
    Date                User                                        Comments
    10/01/2017      nandan.narasappa@auspost.com.au          updated getter for eventMessage to look for additional 
                                                             event codes from custom setting
        
*******************************  History ************************************************/
public with sharing class VE_CardedCaseController{
    
    // variables
    public Case cardedCase {get;set;}
    
    // variable to store "Attempt to Delivery" event message
    public EventMessage__c eventMessage {
        get{
            if(cardedCase != null && eventMessage == null){
                Set<String> eventTypes = new Set<String>();
                
                // custom setting stores event codes for Carded cases
                for(CardedCaseEventCode__c code : CardedCaseEventCode__c.getAll().values()){
                    eventTypes.add(code.EventType__c);
                }
                
                //fetch event messages with cardedCase event codes
                for(EventMessage__c event : [SELECT Id,DeviceID__c,DeviceUser__c,RoundNo__c,ActualDateTime__c,WorkCentreText__c,DriverContract__c  
                                                FROM EventMessage__c WHERE Article__r.ArticleID__c =: cardedCase.ReferenceId__c
                                                AND EventType__c IN: eventTypes LIMIT 1]){
                    eventMessage = event;
                }
            }
            return eventMessage;
        }
        set;
    }
    
    // variable to store event message fields to be displayed based on product category
    public List<Schema.FieldSetMember> eventMessageFields {
        get{
            if(cardedCase != null && eventMessageFields == null){
                eventMessageFields = (Label.BLUE_POST.equalsIgnoreCase(cardedCase.Network__r.Parent_SBU__c)) ?
                                        Schema.SObjectType.EventMessage__c.fieldSets.Carded_Case_Parcel.getFields() :
                                        (Label.RED_POST.equalsIgnoreCase(cardedCase.Network__r.Parent_SBU__c)) ? 
                                            Schema.SObjectType.EventMessage__c.fieldSets.Carded_Case_LMN.getFields() : 
                                            eventMessageFields ;
            }
            return eventMessageFields;
        }
        set;
    }
    
}