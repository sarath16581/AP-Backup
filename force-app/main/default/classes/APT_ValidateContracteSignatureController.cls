/**
* @author Sri Harsha
* @date 2021-04-14
* @description APT_ValidateContracteSignatureController helps to validate expired contracts.
* @changelog
*/
public class APT_ValidateContracteSignatureController {
    
    public String pageSource{get;set;}
    public String contID {set;get{return ApexPages.currentPage().getParameters().get(APT_Constants.PARAM_ID);}}
    public String name {set;get{return ApexPages.currentPage().getParameters().get(APT_Constants.PARAM_NAME);}}
    public String text {set;get{return ApexPages.currentPage().getParameters().get(APT_Constants.PARAM_TEXT);}}
    
    public String getCheckAndRedirect() {
        date contractExpirationDate = APT_AgreementObjectsSelector.newInstance(1).selectByConfigId(new Set<Id>{contID}).get(0).Contract_Expiration_Date__c;
        
        if(contractExpirationDate!=null&&contractExpirationDate<system.today()){
            return APT_Constants.ERROR_MESSAGE_CANNOT_SEND_CONTRACT;
        }
        else{
            pageSource=APT_Constants.APT_VfcontractesignaturePage;   
            return APT_Constants.SUCCESS_LABEL_SMALL;
            
        }
    }
  
}