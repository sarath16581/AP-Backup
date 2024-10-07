/**
 * @description A wrapper class used as Apex-defined data type when passed to a Flow for input variables. 
 * 				Each instance encapsulates all details needed for the Flow to call a static email alert action. 
 * 				Static email actions in a flow are pre-configued/existing workflow email alerts that specifies the email content and recipients.
 * 				Apex Emailing or Send Email action in flows are incredibly prohibitive with daily limits. These are not in scope at this time. 
 * 
 * @author Parveen Kaushik
 * @date 2024-05-20
 * @changelog
 */
public inherited sharing class ApplicationFlowEmailType {

	/**
	 * Record ID to use for the email alert. Salesforce uses this record when generating merge field values for email templates and to resolve recipients
	 * */ 
	@AuraEnabled 
	public Id srcRecordId {get; set;}
   
	/**
	 * API name of the email alert. This value will be used in decision logic to call mapped email action by Flow.
	 * */ 
	@AuraEnabled 
	public String emailAlertName{get; set;}

	/**
	 * Type of the sObject in string format. Used by flow to branch out and launch related sub flows.
	 * */ 
	@AuraEnabled
	public String objectType {get; set;}
	
    /**
	 * Instantiates ApplicationFlowEmailType with all required parameters.
	 * @param srcRecordId Record ID to use for the static email alert
	 * @param srcObjectType Type of the sObject
	 * @param emailAlertName API name of the pre-configured email alert
	 * */     
	public ApplicationFlowEmailType(Id srcRecordId, sObjectType srcObjectType, String emailAlertName) {
        this.srcRecordId = srcRecordId;
		this.objectType = String.valueof(srcObjectType);
		this.emailAlertName = emailAlertName;
	}

    /**
	 * Akin to hashCode, this method returns a key to uniquely identify the email notification wrapper
	 * @return Simple concatenation of record id and email alert api name joined by a hyphen
	 * */    	
	public String generateRegistryKey() {
		return String.join(new List<String>{String.valueOf(this.srcRecordId), this.emailAlertName},  '-');
	}


    public class FlowEmailException extends Exception {}
}