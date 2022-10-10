/* @author Seth Heang
 * @date 2022-05-30
 * @tag ApexController
 * @domain Core, Apttus
 * @description A controller for LWC interface for linking functionality of billing account, charge/sub accound request to Apttus Contract
 * @changelog
 * 2022-05-30 - Seth Heang - created
 * 01/08/2022 - prerna.rahangdale@auspost.com.au - insertAgreementLodgementPoints - Added the validation error if the lodegement zone selected in the Sub Account Request form is not from
 *                                                 the lodegement zones of proposals.
 */
public with sharing class APT_LinkingBillAccToContractController {

	/**
	 * @decription This method is used by wired method at LWC to retrieve Agreement lodgment points data based on contract Id on page load.
	 * @param String contractId
	 * @return List<APT_Agreement_Lodgement_Point__c>
	 * @exception AuraHandledException
	 */
	@AuraEnabled(cacheable=true)
	public static List<APT_Agreement_Lodgement_Point__c> retrieveAgreementLodgementPoints (String contractId) {
		List<APT_Agreement_Lodgement_Point__c> alpList = new List<APT_Agreement_Lodgement_Point__c>();
		try {
			alpList = APT_AgreementLodgementPointsSelector.newInstance().selectByApttusContractId(
				new Set<Id>{
					(Id) contractId
				},
				new Set<Object>{
					APT_AgreementLodgementPointsSelector.Options.WITH_BILLING_ACCOUNT,
					APT_AgreementLodgementPointsSelector.Options.WITH_CHARGE_ACCOUNT_REQ,
					APT_AgreementLodgementPointsSelector.Options.WITH_SUB_ACCOUNT_REQ
				}).values();
		} catch (Exception e) {
			throw new AuraHandledException('Error occurred while retrieving agreement lodgement point records: ' + e.getMessage());
		}
		return alpList;
	}

	/**
	 * @decription This method is used by wired method at LWC to retrieve Agreement line item data based on contract Id on page load.
	 * @param String contractId
	 * @return List<Apttus__AgreementLineItem__c>
	 * @exception AuraHandledException
	 */
	@AuraEnabled(cacheable=true)
	public static List<Apttus__AgreementLineItem__c> retrieveProductsFromCLI(String contractId) {
		List<Apttus__AgreementLineItem__c> cliList = new List<Apttus__AgreementLineItem__c>();
		try {
			cliList = APT_AgreementLineItemsSelector.newInstance().selectByContractIdsAndLineType(
				new Set<id>{
					(Id) contractId
				},
				new Set<String>{
					'Product/Service'
				},
				new Set<Object>{
					APT_AgreementLineItemsSelector.Options.WITH_CONTRACT,
					APT_AgreementLineItemsSelector.Options.WITH_PROPOSAL
				}
			);

		} catch (Exception e) {
			throw new AuraHandledException('Error occurred while retrieving agreement line item records: ' + e.getMessage());
		}
		return cliList;
	}

	/**
	 * @decription This method is called imperatively from LWC to retrieve charge account request data based on proposal Id,
	 *              when applying for charge/sub account rate
	 * @param String propId
	 * @return List<APT_Charge_Account__c>
	 * @exception AuraHandledException
	 */
	@AuraEnabled(cacheable=true)
	public static List<APT_Charge_Account__c> retrieveChargeAccountRequests(String propId) {
		List<APT_Charge_Account__c> chargeAccList = new List<APT_Charge_Account__c>();
		try {
		    chargeAccList = ChargeAccountRequestSelector.newInstance().selectByProposalId(
				new Set<Id>{
					(Id) propId
				},
				new Set<Object>{
					ChargeAccountRequestSelector.Options.WITH_ORGANISATION
				});
		} catch (Exception e) {
			throw new AuraHandledException('Error occurred while retrieving charge account request records: ' + e.getMessage());
		}
		return chargeAccList;
	}

	/**
	 * @decription This method is called imperatively from LWC to retrieve charge account request data based on proposal Id,
	 *              when applying for charge/sub account rate
	 * @param String propId
	 * @return List<APT_Sub_Account__c>
	 * @exception AuraHandledException
	 */
	@AuraEnabled(cacheable = true)
	public static List<APT_Sub_Account__c> retrieveSubAccountRequests(String propId) {
		List <APT_Sub_Account__c> subAccList = new List <APT_Sub_Account__c>();
		try {
			subAccList = SubAccountRequestsSelector.newInstance().selectByProposalId(
				new Set <Id> {
					(Id) propId
				},
				new Set <Object> {
					SubAccountRequestsSelector.Options.WITH_ORGANISATION
				});
		} catch (Exception e) {
			throw new AuraHandledException('Error occurred while retrieving sub account request records: ' + e.getMessage());
		}
		return subAccList;
	}

	/**
	 * @decription This method is called imperatively from LWC to retrieve billing account data based on contract's organisation Id,
	 *              when applying for specific billing account rate
	 * @param String contractOrgId
	 * @return List<Billing_Account__c>
	 * @exception AuraHandledException
	 */
	@AuraEnabled(cacheable=true)
	public static List<Billing_Account__c> retrieveBillingAcc(String contractOrgId) {
		List<Billing_Account__c> billingAccList = new List<Billing_Account__c>();
		try {
			billingAccList = BillingAccountsSelector.newInstance().selectByOrgId(
				new Set<Id>{
					(Id) contractOrgId
				},
				new Set<object>{
					BillingAccountsSelector.Options.FILTER_ACTIVE,
					BillingAccountsSelector.Options.FILTER_CUST_TYPE,
					BillingAccountsSelector.Options.WITH_PAYER_ACCOUNT_ID
				}
			).values();
		} catch (Exception e) {
			throw new AuraHandledException('Error occurred while retrieving billing account records: ' + e.getMessage());
		}
		return billingAccList;
	}

	/**
	 * @decription This method is called imperatively from LWC to link billing account, charge/sub account to Apttus Contract,
	 *              by inserting a new agreement lodgement point record with appropriate field mapping
	 * @param List<LinkingAccountWrapper> wrapperObjList
	 * @param String contractId
	 * @param String orgId
	 * @param String prodName
	 * @return String 'SUCCESS'
	 * @throw AuraHandledException
	 */
	@AuraEnabled
	public static string insertAgreementLodgementPoints(List<LinkingAccountWrapper> wrapperObjList, String contractId, String orgId, String prodName,String proposalId, String lodgementPointWCCs) {
		List<APT_Agreement_Lodgement_Point__c> alpListForInsert = new List<APT_Agreement_Lodgement_Point__c>();

		try {
			// Prerna Lodgement points to Charge Account .
			List<CreateSubAccountsController.SObjectResult> responseDetail = null;

			if (lodgementPointWCCs != null) {
				// deserialise the JSON and convert to the custom Sboject
				responseDetail = (List<CreateSubAccountsController.SObjectResult>) System.JSON.deserialize(lodgementPointWCCs, List<CreateSubAccountsController.SObjectResult>.class);
			// validate whether the lodgement zone selected is matching the Agreement line items lodgement Zones.
			if(!CreateSubAccountsController.validateSearchLodgementZone(proposalId,responseDetail[0].postCode)){
				return 'FAILED';
			}
			}
			// iterate over wrapper object and map to respective lookup fields based on supplied SObject type(eg. Billing Acc, Charge Acc Req, Sub Acc Req)
			for (LinkingAccountWrapper wrapperRec : wrapperObjList) {
				APT_Agreement_Lodgement_Point__c newALP = new APT_Agreement_Lodgement_Point__c();
				// map billing account lookup for linking billing account
				if (wrapperRec.id != null && wrapperRec.objType.equals('APT_Billing_Account__c')) {
					newALP.APT_Billing_Account__c = wrapperRec.id;
				}
				// map billing account lookup for linking charge account request
				else if (wrapperRec.id != null && wrapperRec.objType.equals('APT_Charge_Account__c')) {
					newALP.APT_Charge_Account__c = wrapperRec.id;
					// As of now only one lodgement Point can be added for a Charge Account
					newALP.APT_Lodgement_Point_Lookup__c = responseDetail[0].recId;
				}
				// map billing account lookup for linking sub account request
				else if (wrapperRec.id != null && wrapperRec.objType.equals('APT_Sub_Account__c')) {
					newALP.APT_Sub_Account__c = wrapperRec.id;
				}
				// map lodgement point lookup for linking at the organisation level, only for new customer scenario
				else if (wrapperRec.id != null && wrapperRec.objType.equals('APT_Organisation__c') && lodgementPointWCCs != null) {
					newALP.APT_Lodgement_Point_Lookup__c = responseDetail[0].recId;
				}
				// map product name if supplied for produce specific linking
				if (prodName != null || prodName != '') {
					newALP.APT_Product__c = prodName;
				}
				// organisation and apttus contract are mandatory due to master-detail relationships
				newALP.APT_Organisation__c = orgId;
				newALP.APT_Agreement__c = contractId;
				alpListForInsert.add(newALP);
			}
			// insert agreement LP for each respective lookup field per entry
			ApplicationDatabase.getInstance().dmlInsert(alpListForInsert);
			return APT_Constants.SUCCESS_LABEL;
		} catch (Exception e) {
			throw new AuraHandledException('Error occurred while inserting Agreement Lodgement Point records: ' + e.getMessage());
		}
    }

	/**
	 * @description Wrapper class object to pass over a wrapper object of Id and object api value from LWC into apex controller
	 *              Two Attributes:
	 *              -id: id of billing account, charge account request, sub account request, organisation
	 *              -objType: API name of the respective lookup fields on Agreement lodgement point for mapping billing account, 
	 *                          charge account request, sub account request, organisation
	 */
	public class LinkingAccountWrapper {
		@AuraEnabled
		public String id { get; set; }
		@AuraEnabled
		public String objType { get; set; }
		@AuraEnabled
		public String proposalId {get;set;}
	}
}