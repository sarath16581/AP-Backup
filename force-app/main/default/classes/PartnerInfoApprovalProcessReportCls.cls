/**************************************************
Name:       PartnerInfoApprovalProcessReportCls
Purpose:    Displays list of pending approvals for logged in user
            OR All Pending approvals of Partner Info App.
Used By:    
History:
--------------------------------------------------
14.09.2015  Ashutosh (Salesforce.com)    Created
07.06.2016  Andrew Judd (Salesforce.com) Added support for CMA, CPA and PP Licences
**************************************************/

public with sharing class PartnerInfoApprovalProcessReportCls{
    
    public String selectedState {get; set;}
    
    public List<approvalWrapper> licenceWrapperList {get; set;}
    public List<approvalWrapper> pAddendumWrapperList {get; set;}
    public List<approvalWrapper> pICWrapperList {get; set;}
    public String approvalStatusStr {get; set;}
    
    /* List of Australia State */ 
    public List<SelectOption> getStates() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('All','All'));
        options.add(new SelectOption('ACT','ACT'));
        options.add(new SelectOption('NSW','NSW'));
        options.add(new SelectOption('QLD','QLD'));
        options.add(new SelectOption('NT','NT'));
        options.add(new SelectOption('SA','SA'));
        options.add(new SelectOption('TAS','TAS'));
        options.add(new SelectOption('VIC','VIC'));
        options.add(new SelectOption('WA','WA'));
        return options;
    }
    
    /*
        Gives an option to End User to view thier approvals
        OR All approvals of all users
    */
    public List<SelectOption> getApprovalStatus() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('PendingMyApproval','Pending for My Approval'));
        options.add(new SelectOption('AllPendingApprovals','All Pending Approvals'));
        return options;
    }    
    
    /*
        Create Approval Wrapper Structure to display 
        pending approval request for following objects
        1. Licence Approval
        2. Partner Info Change
        3. Partner Addendum
    
    */
    public void setupApprovalStructure(){
        
        set<Id> targetObjectId = new set<Id>();
        List<ProcessInstance> processInstanceList = [Select status, Id, CreatedDate, CreatedById, CreatedBy.Name, TargetObjectId, ProcessDefinition.Name,
                                                        TargetObject.Name,
                                                        (Select Actor.Name, ActorId FROM Workitems) 
                                                     From ProcessInstance 
                                                     Where Status='pending'];
        
        //Related object record ids
        for(ProcessInstance p: processInstanceList){
            if(approvalStatusStr.equals('PendingMyApproval')){
                if(p.Workitems.size()>0 && String.valueOf(p.Workitems[0].ActorId).startsWith('005')){
                    if(UserInfo.getUserId() == p.Workitems[0].ActorId){
                        targetObjectId.add(p.TargetObjectId);
                    }
                }
            }else{
                targetObjectId.add(p.TargetObjectId);
            }
                
        }

        //Approval structure formation
        licenceWrapperList = new List<approvalWrapper>();
        pAddendumWrapperList = new List<approvalWrapper>();
        pICWrapperList = new List<approvalWrapper>();
        
        if(!processInstanceList.isEmpty()){
            
            map<id, Account> licenceList = new map<id, Account>();
            map<id, Partner_Addendum__c> pAddendumList = new map<id, Partner_Addendum__c>();
            map<id, Partner_Info_Change__c> pICList  = new map<id, Partner_Info_Change__c>();  
         
            //Check in licence(account object)
            if(selectedState.Equals('All')){
                
            licenceList = new map<id, Account>([SELECT id, CreatedDate,  Facility__r.ShippingState, Facility__r.Name, Facility__r.WCIS_Code__c, Facility__r.Id
                                                    FROM Account
                                                    WHERE id in: targetObjectId
                                                    And RecordType.DeveloperName in ('Licence','Licence_CMA','Licence_CPA','Licence_PP')
                                                ]);

            //Check in Partner_Addendum__c
            pAddendumList = new map<id, Partner_Addendum__c>([SELECT id, CreatedDate , Facility__r.ShippingState, Licence__r.Facility__r.ShippingState,
                                                                Facility__r.Name, Facility__r.WCIS_Code__c, Facility__r.Id,
                                                                Licence__r.Facility__r.Name, Licence__r.Facility__r.WCIS_Code__c, Licence__r.Facility__r.Id
                                                                FROM Partner_Addendum__c
                                                                WHERE id in: targetObjectId
                                                             ]); 
                                                                                            
            //Check in Partner_Addendum__c
            pICList = new map<id, Partner_Info_Change__c>([SELECT id, CreatedDate ,Facility__r.ShippingState, Licence__r.Facility__r.ShippingState,
                                                                Facility__r.Name, Facility__r.WCIS_Code__c, Facility__r.Id,
                                                                Licence__r.Facility__r.Name, Licence__r.Facility__r.WCIS_Code__c, Licence__r.Facility__r.Id            
                                                            FROM Partner_Info_Change__c
                                                            WHERE id in: targetObjectId
                                                         ]);                                                                                                 
            
            
            }else{
            
            licenceList = new map<id, Account>([SELECT id,CreatedDate , Facility__r.ShippingState,  Facility__r.Name, Facility__r.WCIS_Code__c, Facility__r.Id
                                                                    FROM Account
                                                                    WHERE id in: targetObjectId
                                                                    And RecordType.DeveloperName in ('Licence','Licence_CMA','Licence_CPA','Licence_PP')
                                                                    And Facility__r.ShippingState =:selectedState
                                                                ]);

            //Check in Partner_Addendum__c
            pAddendumList = new map<id, Partner_Addendum__c>([SELECT id, CreatedDate, Facility__c, Facility__r.ShippingState, Licence__r.Facility__r.ShippingState,
                                                                    Facility__r.Name, Facility__r.WCIS_Code__c, Facility__r.Id,
                                                                    Licence__r.Facility__r.Name, Licence__r.Facility__r.WCIS_Code__c, Licence__r.Facility__r.Id            
                                                                FROM Partner_Addendum__c
                                                                WHERE id in: targetObjectId
                                                                AND (Facility__r.ShippingState =:selectedState OR 
                                                                    Licence__r.Facility__r.ShippingState =:selectedState )
                                                             ]); 
                                                                                            
            //Check in Partner_Addendum__c
            pICList = new map<id, Partner_Info_Change__c>([SELECT id,CreatedDate,  Facility__c, Facility__r.ShippingState, Licence__r.Facility__r.ShippingState,
                                                                    Facility__r.Name, Facility__r.WCIS_Code__c, Facility__r.Id,
                                                                    Licence__r.Facility__r.Name, Licence__r.Facility__r.WCIS_Code__c, Licence__r.Facility__r.Id                
                                                                FROM Partner_Info_Change__c
                                                                WHERE id in: targetObjectId
                                                                AND (Facility__r.ShippingState =:selectedState OR 
                                                                     Licence__r.Facility__r.ShippingState =:selectedState )
                                                             ]);               
            
            }
            
            //Iterate over process instane list for wrapper list creation
            for(ProcessInstance p: processInstanceList){
                
                if(((String)(p.TargetObjectId)).startsWith(Account.SObjectType.getDescribe().keyPrefix) && licenceList.containsKey(p.TargetObjectId)){
                    licenceWrapperList.add(new approvalWrapper(p,licenceList.get(p.TargetObjectId).Facility__r.ShippingState,
                                            licenceList.get(p.TargetObjectId).Facility__r.Name, 
                                            licenceList.get(p.TargetObjectId).Facility__r.WCIS_Code__c));
                }
                else if(((String)(p.TargetObjectId)).startsWith(Partner_Addendum__c.SObjectType.getDescribe().keyPrefix) && pAddendumList.containsKey(p.TargetObjectId)){ 
                    if(pAddendumList.get(p.TargetObjectId).Facility__c<>null){
                        pAddendumWrapperList.add(new approvalWrapper(p,pAddendumList.get(p.TargetObjectId).Facility__r.ShippingState,
                                                pAddendumList.get(p.TargetObjectId).Facility__r.Name,
                                                pAddendumList.get(p.TargetObjectId).Facility__r.WCIS_Code__c));
                    }else{
                        pAddendumWrapperList.add(new approvalWrapper(p,pAddendumList.get(p.TargetObjectId).Licence__r.Facility__r.ShippingState,
                                                pAddendumList.get(p.TargetObjectId).Licence__r.Facility__r.Name,
                                                pAddendumList.get(p.TargetObjectId).Licence__r.Facility__r.WCIS_Code__c));                        
                    }
                }
                else if(((String)(p.TargetObjectId)).startsWith(Partner_Info_Change__c.SObjectType.getDescribe().keyPrefix) && pICList.containsKey(p.TargetObjectId)){ 
                    if(pICList.get(p.TargetObjectId).Facility__c<>null){
                        pICWrapperList.add(new approvalWrapper(p,pICList.get(p.TargetObjectId).Facility__r.ShippingState,
                                                               pICList.get(p.TargetObjectId).Facility__r.Name,
                                                               pICList.get(p.TargetObjectId).Facility__r.WCIS_Code__c));
                    }else{
                        pICWrapperList.add(new approvalWrapper(p,pICList.get(p.TargetObjectId).Licence__r.Facility__r.ShippingState,
                                                               pICList.get(p.TargetObjectId).Licence__r.Facility__r.Name,
                                                               pICList.get(p.TargetObjectId).Licence__r.Facility__r.WCIS_Code__c));
                    }                    
                }
            }
            
        }
                                                     
    }
    
    /* Wrapper Class between Processinstance and related approval */
    public class approvalWrapper{
        public ProcessInstance pInstance {get; set;}
        public string state {get; set;}
        public string facility {get; set;}
        public string wcisCode {get; set;}
        
        public approvalWrapper( ProcessInstance processInstance, string state, string facility, string wcisCode ){
            this.pInstance = processInstance;
            this.state = state;
            this.facility = facility;
            this.wcisCode = wcisCode;
        }
    }
}