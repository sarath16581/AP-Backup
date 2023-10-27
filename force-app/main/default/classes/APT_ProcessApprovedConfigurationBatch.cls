/**
 * @description       : This class will be called from APT_ConfigurationTriggerHandler - 
 * @author            : Mansi Shah
 * @group             : 
 * @last modified on  : 06-15-2021
 * @last modified by  : Mansi Shah
 * Modifications Log 
 * Ver   Date         Author       Modification
 * 1.0   06-08-2021   Mansi Shah   Initial Version
 * Ken McGuire 2023.04.19 Proposal field migration to opportunity
 * Paul Perry	2023-09-14 Decommissioned StarTrek Pricing Matrix logic MW0005472
**/
public with sharing class APT_ProcessApprovedConfigurationBatch implements Queueable{
	public Set<Id> setOfConfigurationIds;
	public List<Apttus_Config2__ProductConfiguration__c> productConfigurationList = new List<Apttus_Config2__ProductConfiguration__c>();
	public Id quoteId;
	public static String errorMsg='';

	public APT_ProcessApprovedConfigurationBatch(Set<Id> configurationIds) {
		setOfConfigurationIds = configurationIds;
	}

	/**
	* @description
	* @author Mansi Shah | 06-09-2021
	* @param context
	**/
	public void execute(QueueableContext context){

		Id cartId;

		productConfigurationList = [SELECT id, Apttus_Config2__IsPricePending__c, APT_STE_Pricing_Tier__c,Apttus_CQApprov__Approval_Status__c,
				Apttus_Config2__Status__c,Apttus_QPConfig__Proposald__c
		FROM Apttus_Config2__ProductConfiguration__c
		WHERE id =: setOfConfigurationIds AND Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.IsStartrackProposal__c =:APT_Constants.OPTION_YES];


		if(productConfigurationList != null && !productConfigurationList.isEmpty()){

			//taking only first element as there will not be more than one configuration in this usecase.
			cartId = productConfigurationList[0].Id;

			quoteId = productConfigurationList[0].Apttus_QPConfig__Proposald__c;

			if(cartId != null){
				applyConstraintRules(cartId);
				rePriceCart(cartId);
				updateConfiguration(cartId);
				if(errorMsg != null && errorMsg.length() > 0){
					sendEmail(quoteId);
				}
			}
		}
	}

	/**
	* @description: This method will associate the Constraint Rule on the cart
	* @author Mansi Shah | 06-09-2021
	* @param cartId
	**/
	public static void applyConstraintRules(Id cartId){
		try{
			Apttus_CPQApi.CPQWebService.associateConstraintRules(cartId,null);
			Apttus_CPQApi.CPQWebService.applyConstraintRules(cartID, false);
			Apttus_CPQApi.CPQ.ConstraintResultDO constraintResult = Apttus_CPQApi.CPQWebService.getConstraintRuleResult(cartID);

			if(constraintResult.NeedMoreProcessing)
			{
				Apttus_CPQApi.CPQWebService.associateConstraintRules(cartId,null);
				Apttus_CPQApi.CPQWebService.applyConstraintRules(cartID, false);

			}
		}
		Catch(Exception e){
			errorMsg+= ' Exception occured '+e.getMessage();
		}
	}

	/**
	* @description : This method will reprice the provided cart
	* @author Mansi Shah | 06-09-2021
	* @param cartId
	**/
	public static void rePriceCart(Id cartId){
		try{
			Apttus_CpqApi.CPQ.UpdatePriceRequestDO objUpdatePriceRequestDO = new Apttus_CpqApi.CPQ.UpdatePriceRequestDO();
			objUpdatePriceRequestDO.CartId = cartId;
		}
		Catch(Exception e){
			errorMsg+= 'Exception occured '+e.getMessage();
		}
	}

	/**
	* @description : This method will update the Configuration Record for pricing
	* @author Mansi Shah | 06-09-2021
	* @param cartId
	**/
	public static void updateConfiguration(Id cartId){
		try{
			Apttus_Config2__ProductConfiguration__c configToBeUpdated = new Apttus_Config2__ProductConfiguration__c();
			configToBeUpdated.Id = cartId;
			configToBeUpdated.Apttus_CQApprov__Approval_Status__c = APT_Constants.APPROVAL_STAGE_APPROVED;
			configToBeUpdated.Apttus_Config2__Status__c = APT_Constants.Ready_For_Finalization;
			update configToBeUpdated;
		}
		Catch(Exception e){
			errorMsg+= 'Exception occured '+e.getMessage();
		}
	}

	public static void sendEmail(Id quoteId){

		if(quoteId != null){
			Apttus_Proposal__Proposal__c masterQuote = new Apttus_Proposal__Proposal__c();
			masterQuote = [SELECT Id,CreatedBy.Email,CreatedById,Name,CreatedBy.FirstName
			FROM Apttus_Proposal__Proposal__c
			WHERE Id =: quoteId];

			// Notify record owner in case of any failure
			if(masterQuote != null){
				Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
				mail.setSaveAsActivity(false);
				mail.setTreatTargetObjectAsRecipient(false);
				mail.setToAddresses(new String[] {masterQuote.CreatedBy.Email});
				mail.setTargetObjectId(masterQuote.CreatedById);
				String sub = 'Process Failed for '+ masterQuote.Name;

				String htmlBody = 'Hi '+masterQuote.CreatedBy.FirstName +',<br/> <br/>';
				htmlBody += 'Following error(s) occured while performing the After Approval Operation - <br/>' +errorMsg;

				mail.setHtmlBody(htmlBody);
				mail.setSubject(sub);
				Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
			}
		}
	}
}