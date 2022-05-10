/**
* @author Sri Harsha
* @date 2021-04-13
* @description APT_Validatecontractcontroller helps to validate expired contracts.
* @changelog
*/
public class APT_ValidateContractController {
    public String pageSource{get;set;}
    public String contID {set;get{return ApexPages.currentPage().getParameters().get(APT_Constants.PARAM_ID);}}
    public String Count {set;get{return ApexPages.currentPage().getParameters().get(APT_Constants.PARAM_COUNT);}}
    
    public String getCheckAndRedirect() {
        date contractExpirationDate = APT_AgreementObjectsSelector.newInstance(1).selectByConfigId(new Set<Id>{contID}).get(0).Contract_Expiration_Date__c;
        
        if(contractExpirationDate!=null&&contractExpirationDate<system.today())
        {
            
            return APT_Constants.ERROR_MESSAGE_CANNOT_CREATE_CONTRACT;
        }
        else{
            pageSource=APT_Constants.APT_VfcontractPage; 
            return APT_Constants.SUCCESS_LABEL_SMALL;
            
        }
    }
    
}