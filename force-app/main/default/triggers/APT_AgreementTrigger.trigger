/**

Created By: Mausam Padhiyar
Created Date:25th Nov, 2015
Last Modified By: Mausam Padhiyar
Last Modified Date: 25th Jan, 2017 | 1825  | set Pricing Category as Offline Rates

Last Modified By - Lija Jawahar
Last Modified Date - 28th May 2020 | SOQL Limit exceeding Fix

2020-10-22 - Mathew Jose - setting product lines on Agreement
2021-08-31 - Naveen Rajanna - REQ2542972 - Comment code to set 'Fixed Term' when UMS or print Post
2022-05-02 - SaiSwetha Pingali - REQ2703521 - Added logic to capture role of the user at the time of creation.
2023-02-14 - Ranjeewa Silva - Added support for before delete, after delete and after undelete trigger events
2023-04-05 - Yatika Bansal - Updated code to populate agreement dates
2023-05-10 - Yatika Bansal - Added code to populate service dates on agreement line items.

*/

trigger APT_AgreementTrigger on Apttus__APTS_Agreement__c (after insert,before insert,before update,after update, before delete, after delete, after undelete) {
String result;
List<Opportunity> listOpportunity = new List<Opportunity>();
Opportunity oppty;

// Application Domain
if(!TriggerHelper.isTriggerDisabled(String.valueOf(Apttus__APTS_Agreement__c.SObjectType))) {
	APTAgreementDomainTriggerHandler.newInstance().dispatch();
}
//before
if (Trigger.isBefore) {
	//insert
	if (Trigger.isInsert) {
		
		//Not feasible with Process Builder – not possible to access User fields via Owner lookup in Process Builder
		Set<Id> setOwnerId = new Set<Id>();
		Set<Id> setProposalId = new Set<Id>();
		Map<Id, Apttus_Proposal__Proposal__c> mapProposal = new Map<Id, Apttus_Proposal__Proposal__c>();
		//spingali - REQ2703521 - Added logic to capture role of the user at the time of creation.
		String roleId = Userinfo.getUserRoleId();
		List<UserRole> RoleList ;
		if(roleId !=null)
		{
			RoleList = [SELECT id, name FROM userRole WHERE Id =: roleId];
		}
		for (Apttus__APTS_Agreement__c agreement : Trigger.new) {
			//spingali - REQ2703521 - Added logic to capture role of the user at the time of creation.
			agreement.APT_Creator_Role__c = RoleList?.get(0).Name;
			setOwnerId.add(agreement.OwnerId);
			if (null != agreement.Apttus__Related_Opportunity__c) {
				oppty = new Opportunity(Id = agreement.Apttus__Related_Opportunity__c);
				oppty.Next_Step__c = APT_Constants.OPPORTUNITY_NEXTSTEP_NEGOTIATE_TO_ACHIEVE_ALIGNMENT;
				listOpportunity.add(oppty);
			}

			//1825
			if (String.isNotBlank(agreement.Apttus_QPComply__RelatedProposalId__c)) {
				setProposalId.add(agreement.Apttus_QPComply__RelatedProposalId__c);
			}
			//1825
		}

		if (setProposalId.size()>0 ) {
			mapProposal = new Map<Id, Apttus_Proposal__Proposal__c>([
					SELECT Id, APT_Use_Offline_Rates__c,
						(SELECT id, Apttus_Proposal__Product__c,
							APT_Bundle_Product_Name__c,
							Apttus_Proposal__Product__r.name,
							Apttus_Proposal__Product__r.APT_Product_Lines__c,
							Apttus_QPConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_PostBillPay_Channel__c,
							Apttus_Proposal__Product__r.Apttus_Config2__ConfigurationType__c
						FROM Apttus_Proposal__R00N70000001yUfBEAU__r)
					FROM Apttus_Proposal__Proposal__c
					WHERE Id IN :setProposalId
			]);
		}


		if (listOpportunity.size() > 0) {
			update listOpportunity;
		}

		List<User> listOwner = new List<User>([
				SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c
				FROM User
				WHERE Id IN :setOwnerId
		]
		);

		result = APT_AgreementTriggerHandler.afterChangeofOwner(listOwner, Trigger.new);
		result = APT_AgreementTriggerHandler.updateAgreementwithAttribute(Trigger.new);
		APT_AgreementTriggerHandler.agreementDatesLogicOnCreate(Trigger.new);
		result = APT_AgreementTriggerHandler.setProductLines(Trigger.new, mapProposal);

		if (result != APT_Constants.SUCCESS_LABEL) {
			for (Apttus__APTS_Agreement__c agreement : Trigger.new) {
				agreement.addError(result);
			}
		}

		//for updating DOV agreement field and pricePlan
		Set<String> newSetFFNumber = new Set<String>();
		Map<Id, String> mapofIdToString = new Map<Id, String>();

		for (Apttus__APTS_Agreement__c DOVagreement : Trigger.new) {
			Decimal AgreementnumberDecimal = Decimal.valueOf(DOVagreement.Apttus__FF_Agreement_Number__c);
			Id IdOfDOVAgreement = DOVagreement.Id;
			Integer agreementNumberParent = AgreementnumberDecimal.intValue();
			String agreementNumberString = (('000000') + agreementNumberParent).right(8) + '.0';
			//String agreementNumberString = String.format('%08d',agreementNumberParent)+'.0';
			mapofIdToString.put(IdOfDOVAgreement, agreementNumberString);
			newSetFFNumber.add(agreementNumberString);

			//1825
			if (String.isNotBlank(DOVagreement.Apttus_QPComply__RelatedProposalId__c)) {

				if (mapProposal.get(DOVagreement.Apttus_QPComply__RelatedProposalId__c) != null && mapProposal.get(DOVagreement.Apttus_QPComply__RelatedProposalId__c).APT_Use_Offline_Rates__c) {
					DOVagreement.APT_Pricing_Category__c = 'Offline Rates';
				}
			}
			//1825
		}

		List<Apttus__APTS_Agreement__c> parentAgrList = [
				SELECT Id,Name,Apttus__FF_Agreement_Number__c,Apttus__Status_Category__c,Apttus__Status__c,APT_Price_Plan__c,Record_Type_Name__c
				FROM Apttus__APTS_Agreement__c
				WHERE Apttus__FF_Agreement_Number__c IN:newSetFFNumber
		];

		Map<String, Apttus__APTS_Agreement__c> mapFFToAgrObj = new Map<String, Apttus__APTS_Agreement__c>();

		for (Apttus__APTS_Agreement__c agrSO : parentAgrList) {
			mapFFToAgrObj.put(agrSO.Apttus__FF_Agreement_Number__c, agrSO);
		}

		/* TODO : DELETE not used any where
		Map<ID, Apttus__APTS_Agreement__c> parentAgreementObjMap = new Map<ID, Apttus__APTS_Agreement__c>([
				SELECT Id, Name,Apttus__Status_Category__c,Apttus__Status__c,APT_Price_Plan__c,Record_Type_Name__c
				FROM Apttus__APTS_Agreement__c
				WHERE Apttus__FF_Agreement_Number__c IN  :mapofIdToString.values()]);

			*/

		for (Apttus__APTS_Agreement__c DOVagreement : Trigger.new) {
			if (DOVagreement.Apttus__Status_Category__c == 'Request' && DOVagreement.Apttus__Status__c == 'In Amendment') {
				DOVagreement.APT_Price_Plan__c = mapFFToAgrObj.get(DOVagreement.Apttus__Agreement_Number__c + '.0').APT_Price_Plan__c ;
				DOVagreement.APT_Contract_Type__c = 'DoV Contract';
			}
		}
	}

	//update
	else if (Trigger.isUpdate) {
		Map<Id, Apttus__APTS_Agreement__c> oldAgreementMap = Trigger.oldMap;
		Set<Id> setOwnerId = new Set<Id>();
		Set<Id> setNewAgreementIds = new Set<Id>();
		Set<Id> setInEffectAgreementIds = new Set<Id>();
		Set<Id> rateCardsCreatedAgreementIds = new Set<Id>();


		for (Apttus__APTS_Agreement__c agreement : Trigger.new) {
			setNewAgreementIds.add(agreement.Id);
			if (oldAgreementMap.get(agreement.Id).OwnerId != agreement.OwnerId) {
				setOwnerId.add(agreement.OwnerId);
			}

			if (
					String.isNotBlank(agreement.Apttus__Status_Category__c) &&
							String.isNotBlank(Trigger.oldMap.get(agreement.Id).Apttus__Status_Category__c) &&
							agreement.Apttus__Status_Category__c.equalsIgnoreCase(APT_Constants.STATUS_CATEGORY_IN_EFFECT) &&
							!Trigger.oldMap.get(agreement.Id).Apttus__Status_Category__c.equalsIgnoreCase(APT_Constants.STATUS_CATEGORY_IN_EFFECT)
					) {
				setInEffectAgreementIds.add(agreement.Id);
			}

			//APT Customised Contract > process builder to trigger
			if (
					agreement.APT_of_requested_T_C_changes__c != null &&
							agreement.APT_of_requested_T_C_changes__c > 0 &&
							((String.isNotBlank(agreement.Apttus__Agreement_Category__c) && agreement.Apttus__Agreement_Category__c.equalsIgnoreCase(APT_Constants.NETWORK_TYPE_STANDARD)) ||
									(String.isNotBlank(agreement.Term__c) && agreement.Term__c.equalsIgnoreCase(APT_Constants.TERM_OPEN_ENDED))
							)
					) {
				agreement.Apttus__Agreement_Category__c = APT_Constants.AGREEMENT_CATEGORY_CUSTOMISED;
				agreement.Term__c = APT_Constants.TERM_FIXED_TERM;
			}
			//APT Customised Contract > process builder to trigger

			//APT Print Post Makes Contract FT > workflow rule to trigger
			//REQ2542972
			// if (String.isNotBlank(agreement.Term__c) && String.isNotBlank(agreement.Included_Product_Lines__c) && !agreement.Term__c.equalsIgnoreCase(APT_Constants.TERM_FIXED_TERM) &&
			//(agreement.Included_Product_Lines__c.contains(APT_Constants.PRODUCT_CODE_PRINT_POST) || agreement.Included_Product_Lines__c.contains(APT_Constants.PRODUCT_CODE_UMS))) {
			//agreement.Term__c = APT_Constants.TERM_FIXED_TERM;
			// }
			//APT Print Post Makes Contract FT > workflow rule to trigger

			// START**********Defect to update APT_PBP_Gross_Settled__c to true if Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_PostBillPay_Gross_Settlement_fee__c is true for any of the
			//line items product attribute value
			if ((agreement.Record_Type_Name__c == 'Letter of Intent' || agreement.Record_Type_Name__c == 'Post Billpay Contract') && agreement.APT_Ratecards_Created__c) {
				rateCardsCreatedAgreementIds.add(agreement.Id);
			}
			if (null != agreement.Apttus__Related_Opportunity__c) {
				oppty = new Opportunity(Id = agreement.Apttus__Related_Opportunity__c);
				if (!oldAgreementMap.get(agreement.Id).Apttus__Status_Category__c.equalsIgnoreCase(APT_Constants.AGREEMENT_STATUS_CATEGORY_IN_AUTHORING) &&
						agreement.Apttus__Status_Category__c.equalsIgnoreCase(APT_Constants.AGREEMENT_STATUS_CATEGORY_IN_AUTHORING)) {
					oppty.Next_Step__c = APT_Constants.OPPORTUNITY_NEXTSTEP_PRESENT_FINAL_CONTRACT_TO_CUSTOMER;
					listOpportunity.add(oppty);
				}
				if (!oldAgreementMap.get(agreement.Id).Apttus__Status_Category__c.equalsIgnoreCase(APT_Constants.AGREEMENT_STATUS_CATEGORY_IN_SIGNATURES) &&
						agreement.Apttus__Status_Category__c.equalsIgnoreCase(APT_Constants.AGREEMENT_STATUS_CATEGORY_IN_SIGNATURES)) {
					oppty.Next_Step__c = APT_Constants.OPPORTUNITY_NEXTSTEP_PRESENT_FINAL_CONTRACT_TO_CUSTOMER;
					listOpportunity.add(oppty);
				}
			}
		}
		if (listOpportunity.size() > 0) {
			update listOpportunity;
		}
		// Defect to update APT_PBP_Gross_Settled__c to true if Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_PostBillPay_Gross_Settlement_fee__c is true for any of the
		//line items product attribute value
		Map<String, Boolean> agreementIDtoGrossSetteled = new Map<String, Boolean>();
		if (rateCardsCreatedAgreementIds != null) {
			for (Apttus__AgreementLineItem__c aLineItem : [
					SELECT Id, Apttus__AgreementId__c,Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_PostBillPay_Gross_Settlement_fee__c
					FROM Apttus__AgreementLineItem__c
					WHERE Apttus__AgreementId__c IN :rateCardsCreatedAgreementIds
			]
			) {
				if (aLineItem.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_PostBillPay_Gross_Settlement_fee__c.equalsIgnoreCase(APT_Constants.OPTION_YES)) {
					agreementIDtoGrossSetteled.put(aLineItem.Apttus__AgreementId__c, true);
				}
			}
		}

		for (String agreementID : agreementIDtoGrossSetteled.keySet()) {
			Trigger.newMap.get(agreementID).APT_PBP_Gross_Settled__c = true;
		}
		//END********Defect to update APT_PBP_Gross_Settled__c Logic Ends

		//APT Included Products Long Form > process builder to trigger
		//Search Field Update > workflow rule to trigger
		//query for field - recordType.Name and Apttus__Account__r.Name
		for (Apttus__APTS_Agreement__c agreement : [
				SELECT Id, Name, RecordType.Name, Included_Product_Lines__c,
						Apttus__Subtype__c, Apttus__Account__r.Name,
						Apttus_QPComply__RelatedProposalId__r.APT_TotalOPLineItemPrice__c
				FROM Apttus__APTS_Agreement__c
				WHERE Id IN :setNewAgreementIds
		]) {

			Apttus__APTS_Agreement__c newAgreement = Trigger.newMap.get(agreement.Id);

			// Added by Adrian Recio
			// Description: Calculate total amount on update
			newAgreement.Apttus__Total_Contract_Value__c = agreement.Apttus_QPComply__RelatedProposalId__r.APT_TotalOPLineItemPrice__c;

			if (newAgreement != null &&
					String.isNotBlank(newAgreement.Included_Product_Lines__c) &&
					String.isNotBlank(agreement.RecordType.Name) &&
					agreement.RecordType.Name.contains(APT_Constants.RECORD_TYPE_NAME_MSA) &&
					(newAgreement.Included_Product_Lines__c.contains(APT_Constants.PRODUCT_CODE_UMS) ||
							newAgreement.Included_Product_Lines__c.contains(APT_Constants.PRODUCT_CODE_PRINT_POST) ||
							newAgreement.Included_Product_Lines__c.contains(APT_Constants.PRODUCT_CODE_COURIER)
					)
					) {
				newAgreement.Apttus__Subtype__c = APT_Constants.SUBTYPE_LONG_FORM;
			}

			if (String.isNotBlank(agreement.Apttus__Account__r.Name) || String.isNotBlank(newAgreement.Apttus__FF_Agreement_Number__c)) {
				newAgreement.Apttus__Account_Search_Field__c = agreement.Apttus__Account__r.Name + newAgreement.Apttus__FF_Agreement_Number__c;
			}
		}
		//Search Field Update > workflow rule to trigger
		//APT Included Products Long Form > process builder to trigger

		//defect 861
		Map<Id, List<Apttus__AgreementLineItem__c>> mapInEffectAgreementLineItem = new Map<Id, List<Apttus__AgreementLineItem__c>>();
		List<Apttus__AgreementLineItem__c> listALI = new List<Apttus__AgreementLineItem__c>();
		if (setInEffectAgreementIds != null) {
			for (Apttus__AgreementLineItem__c ali : [
					SELECT Id, Name, Apttus__AgreementId__c,
							APT_Cubic_Factor__c, Apttus_CMConfig__LineType__c, Apttus_CMConfig__IsPrimaryLine__c
					FROM Apttus__AgreementLineItem__c
					WHERE Apttus__AgreementId__c IN :setInEffectAgreementIds
					AND Apttus_CMConfig__LineType__c = :APT_Constants.LINE_TYPE_PRODUCT_SERVICE
					AND Apttus_CMConfig__IsPrimaryLine__c = TRUE
			]) {

				if (String.isNotBlank(ali.APT_Cubic_Factor__c)) {
					listALI = new List<Apttus__AgreementLineItem__c>();
					listALI = mapInEffectAgreementLineItem.get(ali.Apttus__AgreementId__c);
					if (listALI != null && listALI.size() > 0) {
						listALI.add(ali);
					} else {
						listALI = new List<Apttus__AgreementLineItem__c>();
						listALI.add(ali);
					}

					mapInEffectAgreementLineItem.put(ali.Apttus__AgreementId__c, listALI);
				}
			}
		}

		for (Id agreementId : setInEffectAgreementIds) {
			if (mapInEffectAgreementLineItem.get(agreementId) != null && mapInEffectAgreementLineItem.get(agreementId).size() > 0) {
				Apttus__APTS_Agreement__c newAgreement = Trigger.newMap.get(agreementId);
				if (newAgreement != null) {
					newAgreement.APT_Cubic_Factor_Contract__c = true;
				}
			}
		}

		//beforeAgreementFullySigned
		APT_AgreementTriggerHandler.beforeAgreementFullySigned(Trigger.oldMap, Trigger.new);
		//beforeAgreementFullySigned

		//populateAgreementDatesOnUpdate
		APT_AgreementTriggerHandler.populateAgreementDatesOnUpdate(Trigger.oldMap, Trigger.newMap);


		if(setOwnerId!= null) {
			List<User> listOwner = new List<User>([
					SELECT Id,ManagerId,Seller_Manager__c,Sales_General_Manager__c
					FROM User
					WHERE Id IN:setOwnerId
			]);
			if (listOwner.size() > 0) {
				result = APT_AgreementTriggerHandler.afterChangeofOwner(listOwner, Trigger.new);
			} else {
				result = APT_Constants.SUCCESS_LABEL;
			}
		}

	}

	if (!Trigger.isDelete && result != APT_Constants.SUCCESS_LABEL) {
		for (Apttus__APTS_Agreement__c agreement : Trigger.new) {
			agreement.addError(result);
		}
	}
}

//after
if (Trigger.isAfter) {
	//insert
	if (Trigger.isInsert) {
		APT_AgreementTriggerHandler.updateProposalStage(Trigger.new);
		APT_AgreementTriggerHandler.addPostBillPayLineItemsToChild(Trigger.new);

		result = APT_AgreementTriggerHandler.createOperationalSchedule(Trigger.new);

		if (result != APT_Constants.SUCCESS_LABEL) {
			for (Apttus__APTS_Agreement__c agreement : Trigger.new) {
				agreement.addError(result);
			}
		}
	}

	//update
	else if (Trigger.isUpdate) {

		//sendEmailToDriver
		APT_AgreementTriggerHandler.populateServiceDatesOnUpdate(Trigger.oldMap, Trigger.newMap);
		APT_AgreementTriggerHandler.deleteExtralineItems(Trigger.oldMap, Trigger.newMap);

		// Added by Adrian Recio
		// Date: 4/08/2017
		// Description: Deactivate old sap contracts if there is a renewal Apttus Contract
		APT_SAPContractValidationController.deactivateOldSapCon(Trigger.new, Trigger.oldMap);

		Set<Id> setAgIds = new Set<Id>();
		Set<Id> setChildAgIdsActivated = new Set<Id>();

		for (Apttus__APTS_Agreement__c agreement : [
				SELECT Id, Billing_Account_No__c,RecordType.DeveloperName, Apttus__Related_Opportunity__c,
						Apttus__Account__c, Apttus__Status__c, APT_Product__c, APT_Rollup_Product_Names__c,
						Apttus_QPComply__RelatedProposalId__r.APT_Method_of_Payment__c,Apttus__Version_Number__c,
						APT_New_Rate_Card_Download__c, Apttus__Contract_End_Date__c, Apttus__FF_Agreement_Number__c, Apttus__Account__r.AccountNumber, Apttus__Account__r.Name, (
						SELECT Id, Apttus__ProductId__c, Apttus__ProductId__r.ProductCode, Apttus_CMConfig__OptionId__r.ProductCode
						FROM Apttus__AgreementLineItems__r
				)
				FROM Apttus__APTS_Agreement__c
				WHERE Id IN :Trigger.new
		]) {


			if (Trigger.oldMap.get(agreement.Id).Apttus__Status__c != agreement.Apttus__Status__c &&
					agreement.Apttus__Status__c == APT_Constants.AGREEMENT_STATUS_FULLY_SIGNED &&
					APT_Agreement_auto_activate_recordtypes__c.getValues(agreement.RecordType.DeveloperName) != NULL) {

				//lstAgremment.add(agreement);
				setAgIds.add(agreement.Id);
			}

			if (Trigger.oldMap.get(agreement.Id).Apttus__Status__c != agreement.Apttus__Status__c &&
					APT_Constants.LABEL_ACTIVATED.equalsIgnoreCase(agreement.Apttus__Status__c) &&
					agreement.Apttus__Version_Number__c != 0) {

				setChildAgIdsActivated.add(agreement.Id);
			}
		}

		if (setAgIds.size() > 0) {

			result = APT_AgreementTriggerHandler.afterAgreementFullySigned(setAgIds);

			if (result != APT_Constants.SUCCESS_LABEL) {
				for (Apttus__APTS_Agreement__c agreement : Trigger.new) {
					agreement.addError(result);
				}
			}
		}

		if (setChildAgIdsActivated.size() > 0) {
			APT_AgreementTriggerHandler.afterAgreementActivatedForChildAgreements(setChildAgIdsActivated);
		}

		/* Shashwat.Nath@Auspost.com.au has added the below lines of code on 22/09/2020 for STP Release 2 requirement
		of superseding the Original Opportunity when the new DOV contract reaches the stage of "In Signature" and "Fully Signed" */

		Set<Id> opportunitiesInScope = new Set<Id>();
		// Iterating on trigger.new and adding only those opportunity Ids to the set which would parent opportunities be required to be superseded
		for(Apttus__APTS_Agreement__c apttusContract : trigger.new){
			if('In Signatures'.equalsIgnoreCase(apttusContract.Apttus__Status_Category__c) &&
				trigger.oldmap.get(apttusContract.id).Apttus__Status__c != apttusContract.Apttus__Status__c &&
				'Fully Signed'.equalsIgnoreCase(apttusContract.Apttus__Status__c) && apttusContract.Apttus__Related_Opportunity__c!=null){
					opportunitiesInScope.add(apttusContract.Apttus__Related_Opportunity__c);
				}
		}
		if(!opportunitiesInScope.isEmpty()){
			// Calling the supersede Original Opportunity Method
			APT_AgreementTriggerHandler.supersedeOriginalOpportunity(opportunitiesInScope);
		}

		/* Shashwat.Nath@auspost.com.au code ends */
	}
}
}