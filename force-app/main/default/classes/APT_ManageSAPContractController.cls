/*
    Created By: Kushal Bhalodiya
    Date: 11 July 2016
    Description: Visual force page controller to handle new SAP Contracts insert.
*/
public class APT_ManageSAPContractController {
    public String textAreaUserInput {get;set;} 
    private Map<String,APT_SAP_Contracts__c> existingSAPContractMap;
    private Map<String,APT_SAP_Contracts__c> newSAPContractMap;
    private String newSAPContractsWithErrors;
    private String newSAPContractsSuccess;
    private String contractID;
    private Boolean errorFlag = false;
    public static final String VF_TITLE_MANAGE_SAP_CONTRACT = 'Manage SAP Contracts';
    public String title {set;get{return VF_TITLE_MANAGE_SAP_CONTRACT;}}
    public static final String VF_PROCESSING = '"Please wait.."';
    public String processingText {set;get{return VF_PROCESSING;}}
    public static final String VF_SAVE = 'Save';
    public String saveText {set;get{return VF_SAVE;}}
    public static final String VF_PAGE_CANCEL = 'Back to Contract';
    public String pageCancel {set;get{return VF_PAGE_CANCEL;}}
    
    /*
    Constructor
    */
    public APT_ManageSAPContractController()
    {
        contractID = ApexPages.currentPage().getParameters().get(APT_Constants.PARAM_ID);
        if(String.isBlank(contractID))
        {
            errorFlag =true;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,APT_Constants.ERROR_MESSAGE_MALFORMED_URL)); 
        }
    }
    /*
    Insert SAP Contract and check for duplicate values already present in system
    */
    public pageReference saveSAPContracts()
    {
        if(!errorFlag)
        {
            // Updated by Adrian Recio
            // Only numberic characters is accepted aside from the new line delimiter
            // 14/8/2017
            string flushNewLine = string.valueOf(textAreaUserInput).remove(APT_Constants.SEPARATOR_NEXT_LINE);
            Boolean allNumeric = flushNewLine.containsOnly('1234567890');

            if(allNumeric == false){
                errorFlag = true;
                newSAPContractsWithErrors = 'Only numeric characters are accepted.';
            }
            
            if(allNumeric==true){
                List<String> splitSAPContractsList = textAreaUserInput.split(APT_Constants.SEPARATOR_NEXT_LINE);
                
                existingSAPContractMap = new Map<String,APT_SAP_Contracts__c>();
                for(APT_SAP_Contracts__c SAPContracts : [select ID,APT_SAP_Contract_Number__c from APT_SAP_Contracts__c where APT_SAP_Contract_Number__c IN :splitSAPContractsList]) //where APT_Apttus_Contract__c =:contractID])
                {
                    if(!existingSAPContractMap.containsKey(SAPContracts.APT_SAP_Contract_Number__c))
                    {
                        existingSAPContractMap.put(SAPContracts.APT_SAP_Contract_Number__c.trim().toLowerCase(),SAPContracts);
                    }
                }
                
                Set<String> setOfUserInputValues = new Set<String>();
                newSAPContractMap = new Map<String,APT_SAP_Contracts__c>();
                newSAPContractsWithErrors = APT_Constants.DEFINE_STRING;
                newSAPContractsSuccess = APT_Constants.DEFINE_STRING;
                Integer count =0;
                for(String sapContract : splitSAPContractsList)
                {
                    count ++;
                    if(!String.isBlank(sapContract) && 7 == sapContract.trim().length() && !newSAPContractMap.containsKey(sapContract) &&
                       !existingSAPContractMap.containsKey(sapContract.trim().toLowerCase()))
                    {
                            newSAPContractMap.put(sapContract, new APT_SAP_Contracts__c(APT_SAP_Contract_Number__c = sapContract,APT_Apttus_Contract__c = contractID));
                            newSAPContractsSuccess = newSAPContractsSuccess + sapContract + APT_Constants.STRING_HTML_BR;
                    }
                    else if(String.isBlank(sapContract))
                    {
                        errorFlag =true;
                        newSAPContractsWithErrors = newSAPContractsWithErrors + APT_Constants.ERROR_EMPTY_VALUE_AT_LINE+ count + APT_Constants.STRING_HTML_BR;
                    }
                    else if(7 != sapContract.trim().length())
                    {
                        errorFlag =true;
                        newSAPContractsWithErrors = newSAPContractsWithErrors + APT_Constants.ERROR_NUMBER_OF_CHAR_RESTRICTION+ count + APT_Constants.STRING_SPACE_DOUBLE_QUOTES + sapContract+ APT_Constants.STRING_DOUBLE_QUOTES + APT_Constants.STRING_HTML_BR;
                    }
                    else if(newSAPContractMap.containsKey(sapContract))
                    {
                        errorFlag =true;
                        newSAPContractsWithErrors = newSAPContractsWithErrors + APT_Constants.ERROR_DUPLICATE_VALUE_AT_LINE + count + APT_Constants.STRING_SPACE_DOUBLE_QUOTES + sapContract + APT_Constants.STRING_DOUBLE_QUOTES + APT_Constants.STRING_HTML_BR;
                    }
                    else if(existingSAPContractMap.containsKey(sapContract.trim().toLowerCase()))
                    {
                        errorFlag =true;
                        newSAPContractsWithErrors = newSAPContractsWithErrors + APT_Constants.ERROR_VALUE_ALREADY_EXIST + count + APT_Constants.STRING_SPACE_DOUBLE_QUOTES + sapContract + APT_Constants.STRING_DOUBLE_QUOTES + APT_Constants.STRING_HTML_BR;
                    }
                }
                if(newSAPContractMap.size() > 0)
                {
                    insert newSAPContractMap.values();
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,APT_Constants.DEFINE_STRING + newSAPContractsSuccess));   
                }
            }
            
            if(errorFlag)
            {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,APT_Constants.DEFINE_STRING + newSAPContractsWithErrors));   
                errorFlag = false;
            }else{
                return backToContract();
            }
            
            /*else{ // Removed. Change of requirements. Redirect not necessary.
             
                // Updated by Adrian Recio
                // Pagereference redirect to activation page added to make sure auto activation will happen after adding sap contracts
                // 2/08/2017
                PageReference pgActivateVar = Page.Apttus__AgreementActivate;
                pgActivateVar.getParameters().put('Id',contractID);
                return pgActivateVar;

            }*/
        }
        
        return null;
    }
    /*
    Redirect back to the contract
    */
    public PageReference backToContract()
    {
        return new PageReference(URL.getSalesforceBaseUrl().toExternalForm() + APT_Constants.SEPERATOR_BACKWARD_SLASH + contractID); 
    }
}