/* Created by: Adrian Recio
 * Description: Main controller for APT_CreateContractValidation page
 * Date: 17/08/2017
 */
public class APT_CreateContractValidationController {
	public Boolean IsError{get; set;}
    public String apConId;
    public Apttus__APTS_Agreement__c apConVar;
    
    public APT_CreateContractValidationController(){
        IsError = false;
        apConId = ApexPages.currentPage().getParameters().get('Id');
        apConVar = [SELECT Id, APT_Contract_Type__c, (Select Id from DoV_Languages__r) FROM Apttus__APTS_Agreement__c WHERE Id = :apConId]; 
        validateDOVPresent(apConVar); // Call DOV validation
    }
    
    public void validateDOVPresent(Apttus__APTS_Agreement__c apConLocVar){
        // DOV is required before contract creation
        if(apConLocVar.DoV_Languages__r.size()==0 && apConLocVar.APT_Contract_Type__c=='DoV Contract'){
            IsError = true;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'DOV Language is required before contract creation.'));
        }
    }
}