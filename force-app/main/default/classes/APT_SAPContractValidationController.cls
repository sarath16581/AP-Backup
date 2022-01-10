/* Created by: Adrian Recio
 * Description: Main controller to manage SAP Contract Validation
 * Date: 25/07/2017
 
 * @changelog

 * 2021/09/15 - Sautul Mehta - CI-15 - To bypass the contract number validation for APPC product.
 */

/*
•   Scenario 1:
o   User clicks on the Activate button in the Apttus Contract page layout
o   System presents a new page prompting the User with a question: “Has a new Contract been created in SAP?”

•   Scenario 2:
o   User selects Yes
o   System presents a new page to enter the new SAP Contract numbers (this will be the same process on the Add SAP Contract button in the Apttus Contract)
o   Then continue onto Process 4

•   Scenario 3:
o   User selects No
o   Then continue onto Process 4

•   Scenario 4:
o   System to clone all SAP Contract records from previous amended or renewed Apttus Contract over to new Apttus Contract
o   System to rename all previous SAP Contract records with postfix of .old (doing this will ensure that there is only 1 unique SAP Contract number in Salesforce)

o   24/12/2021 - REQ2703652 : Adding New Contract Type : DoV From ST Revision

*/

public class APT_SAPContractValidationController {
    
    public string replyVal{get; set;}
    public string aptContract{get; set;}
    public boolean showQuestion{get; set;}
    public Apttus__APTS_Agreement__c renewAgreeVar{get; set;}
    public static final string COMPLETED = 'completed';
    public static final string SIGNED = '__signed'; 
    // Constructor
    public APT_SAPContractValidationController(){
        // Force no reply
        showQuestion = false;
        replyVal='No';
        
        // Pull contract parameter
        aptContract = ApexPages.currentPage().getParameters().get('Id');

        try{        
            renewAgreeVar = [SELECT Id, APT_APPC_Count__c, Apttus_QPComply__RelatedProposalId__r.APT_Contract_Number__c, APT_Contract_Type__c,Is_Document_Signed__c,Docusign_Envelope_Status__c,
                             (Select Id from SAPContracts__r)
                             FROM Apttus__APTS_Agreement__c 
                             WHERE Id = :aptContract]; 
        }catch(exception e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Apttus Contract missing.'));
        }
    }
    
    // Action method called in visualforce that checks response and action conditions
    public pageReference executeSAPContractCheck(){
        boolean unsigned = true;
        if(String.IsNotBlank(aptContract)){
            // Iterating over all the Attachments under particularb contract
            for(attachment atchmnt : [select id,name from attachment where parentid=:aptContract]){
                // Checking if Manual Signed Checkbox is Checked or Docusign Signature is Completed
                if(renewAgreeVar.Is_Document_Signed__c || (atchmnt.name.contains(SIGNED) && COMPLETED.equalsIgnoreCase(renewAgreeVar.Docusign_Envelope_Status__c))){
                    unsigned=false;
                    break;
                }
            }
        }
        if(unsigned && String.IsNotBlank(aptContract)){
            Set<id> contentDocIdSet = new Set<id>();
            List<ContentDocument> ContentDocumentList = new List<ContentDocument>();
            for(contentdocumentlink condoclink: [select id,ContentDocumentId from contentdocumentlink where LinkedEntityId=:aptContract]){
                contentDocIdSet.add(condoclink.ContentDocumentId);    
            }
            // Iterating over all the Attachments under particularb contract
            for(ContentDocument condoc: [select id,title from contentdocument where ID IN :contentDocIdSet]){
                // Checking if Manual Signed Checkbox is Checked or Docusign Signature is Completed
                if(renewAgreeVar.Is_Document_Signed__c || (condoc.title.contains(SIGNED) && COMPLETED.equalsIgnoreCase(renewAgreeVar.Docusign_Envelope_Status__c))){
                    unsigned=false;
                    break;
                }
            }
        }
        
        if(unsigned){
            // Displaying error to Stop User from Activating the Contract
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,Label.Unisgned_Document_Error));
            return null;
        }
        
        // Adding REQ2703652 : Contract_Type__c == 'DoV From ST Revision'
        if(renewAgreeVar.APT_Contract_Type__c == 'Renewal Contract' || 
           renewAgreeVar.APT_Contract_Type__c == 'DoV Contract' || renewAgreeVar.APT_Contract_Type__c == 'DoV From ST Revision'){
            Boolean failClone = false;
            // Clone and redirect to activation page
            if(replyVal=='No'){
                failClone = cloneSapCon(renewAgreeVar);
               
                if(failClone == false){
                    PageReference pgActivateVar = Page.Apttus__AgreementActivate;
                    pgActivateVar.getParameters().put('Id',aptContract);
                    return pgActivateVar;
                }else{
                    return null;
                }
            // Clone and redirect to add sap contract page
            }else if(replyVal == 'Yes'){ 
                failClone = cloneSapCon(renewAgreeVar);
                
                if(failClone == false){
                    PageReference newSAPConPG = Page.APT_ManageSAPContractPage;
                    newSAPConPG.getParameters().put('Id',aptContract);
                    return newSAPConPG;
                }else{
                    return null;
                }
            }
        }else if(renewAgreeVar.APT_Contract_Type__c == 'New Contract' || 
                 renewAgreeVar.APT_Contract_Type__c == 'Migrated Contract'){
                     // CI-15: added confition of APT_Is_APPC_Contract__c to bypass the check for APPC product.	
                     if(renewAgreeVar.SAPContracts__r.size()==0 && renewAgreeVar.APT_APPC_Count__c == 0 ){	
                         ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please add sap contract before activation.'));	
                         return null;	
                     }
                   /*
                   PageReference newSAPConPG = Page.APT_ManageSAPContractPage;
                   newSAPConPG.getParameters().put('Id',aptContract);
                   return newSAPConPG;
                    */
                   PageReference pgActivateVar = Page.Apttus__AgreementActivate;
                   pgActivateVar.getParameters().put('Id',aptContract);
                   return pgActivateVar;
        }
        
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please select your response.'));
        return null;
    }
    
    // Cancel and return to Apttus Contract detail page
    public pageReference returnContract(){
        PageReference pgVar = new Pagereference('/' + aptContract);
        return pgVar;
    }
    
    // Flush SAP Information
    public static void cleanSAP(string agParentId){
        List<APT_SAP_Contracts__c> oldSAPCon = [Select Id from APT_SAP_Contracts__c where APT_Apttus_Contract__c = :agParentId];
        if(oldSAPCon.size()>0){
            delete oldSAPCon;
        }
    }
    
    // Core method to retrieve Old and renewal agreement and call clone function
    public Boolean cloneSapCon(Apttus__APTS_Agreement__c renewConVar){
        Boolean failClone = false;
        
        cleanSAP(aptContract);
        
        Apttus__APTS_Agreement__c origAgreeVar;
        
        // Catch error if more than 1 match exist
        try{
            origAgreeVar = [SELECT Id, Name, Apttus__Version_Number__c
                            FROM Apttus__APTS_Agreement__c 
                            WHERE Apttus__FF_Agreement_Number__c = :renewConVar.Apttus_QPComply__RelatedProposalId__r.APT_Contract_Number__c]; 
        }catch(exception e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Original contract missing.'));
            failClone = true;
        }
        
        system.debug('renewConVar:' + renewConVar);
        system.debug('origAgreeVar:' + origAgreeVar);
        
        // Catch error if null match exist
        if(origAgreeVar==null){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Original contract missing.'));
            failClone = true;
        }else{
            try{
                // Cloning and postfixing action
                APT_AmendRenewUtility.copySAPContratcs(origAgreeVar.Id, renewConVar.Id, origAgreeVar.Apttus__Version_Number__c);
            }catch(exception e){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Contract generation failed. Contact your administrator.'));
                failClone = true;
            }
        }
        
        return failClone;
    }
    
        
    // Method to deactivate sap cons related to agreement
    public static void deactivateOldSapCon(List<Apttus__APTS_Agreement__c> listAgrmnt, Map<Id, Apttus__APTS_Agreement__c> oldAgrMap){
        Set<Id> agIdSet = new Set<Id>();
        for(Apttus__APTS_Agreement__c agVar: listAgrmnt){
            // Pull trigger old agreement
            Apttus__APTS_Agreement__c oldAgrVar = oldAgrMap.get(agVar.Id);
            
            system.debug('Old Category:' + oldAgrVar.Apttus__Status_Category__c);
            system.debug('New Category:' + agVar.Apttus__Status_Category__c);
            
            // Apttus Contract Type is renewal and In Effect
            if(agVar.APT_Contract_Type__c == 'Renewal Contract' && 
               agVar.Apttus__Status_Category__c == 'In Effect' &&
               (oldAgrVar.Apttus__Status_Category__c!=agVar.Apttus__Status_Category__c)){
                agIdSet.add(agVar.Id);
            }
        }
        
        if(agIdSet.size()>0){
            // Pull renewal agreement's parent proposal contract number
            List<Apttus__APTS_Agreement__c> agList = [Select Apttus_QPComply__RelatedProposalId__r.APT_Contract_Number__c 
                                                      from Apttus__APTS_Agreement__c where Id In :agIdSet];
            
            // Store contract number of renewal agreement's parent proposal record
            Set<string> renewOldAgIdSet = new Set<string>();
            for(Apttus__APTS_Agreement__c renewAgreeVar: agList){
                renewOldAgIdSet.add(renewAgreeVar.Apttus_QPComply__RelatedProposalId__r.APT_Contract_Number__c);
            }
            
            
            // Select SAP Con where parent agreement is equal to the FF Agreement Number
            List<APT_SAP_Contracts__c> origAgreeVar = [SELECT Id, SAP_Contract_Status__c FROM APT_SAP_Contracts__c 
                                                       WHERE APT_Apttus_Contract__r.Apttus__FF_Agreement_Number__c IN :renewOldAgIdSet
                                                       AND  (SAP_Contract_Status__c = 'Active' OR SAP_Contract_Status__c = null) AND APT_Apttus_Contract__c IN :agIdSet]; 
            
            // Deactivate SAP contract of matching Old Apttus Contract
            for(APT_SAP_Contracts__c sapConVar: origAgreeVar){
                sapConVar.SAP_Contract_Status__c = 'Inactive';
            }
            
            // Update if size is greater than 0
            if(origAgreeVar.size()>0){
                update origAgreeVar;
            }
        }
    }
}