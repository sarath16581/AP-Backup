/**
Description: Handler class for apex trigger - APT_ApprovalRequestTrigger.
Created By: Raviteja Epuri
Created Date: 21th Dec, 2015
Last Modified By: Krishna Velani
Last Modified Date: 19th May 2021 STP-5156 Populate OOTB Related Proposal & Related Opportunity fields on AR
Ken McGuire 2023.04.19 Proposal field migration to opportunity
Paul Perry	2023-09-14 Decommissioned StarTrek Pricing Matrix logic MW0005472
*/
public with sharing class APT_ApprovalRequestTriggerHandler {

	/**
		To make Approval Rejection Comments mandatory
		@Params -
		listApprovalRequest: ApprovalRequest List
	 */
	public static String beforeUpdateEvent(list<Apttus_Approval__Approval_Request__c> listApprovalRequest,Map<Id,Apttus_Approval__Approval_Request__c> appReqOldMap) {
		try{
			for(Apttus_Approval__Approval_Request__c app: listApprovalRequest){
				if(!String.isEmpty(app.Apttus_Approval__Approval_Status__c) && !String.isEmpty(appReqOldMap.get(app.Id).Apttus_Approval__Approval_Status__c) && !app.Apttus_Approval__Approval_Status__c.equalsIgnoreCase(appReqOldMap.get(app.Id).Apttus_Approval__Approval_Status__c) &&  !String.isEmpty(app.Apttus_Approval__Approval_Status__c) && !String.isEmpty(APT_Constants.APPROVAL_STATUS_REJECTED) && app.Apttus_Approval__Approval_Status__c.equalsIgnoreCase(APT_Constants.APPROVAL_STATUS_REJECTED) && (app.Apttus_Approval__Approver_Comments__c.startsWith(app.Apttus_Approval__Approval_Status__c+APT_Constants.SEPERATOR_HYPHEN))){
					return APT_Constants.APPROVAL_REJECTION_COMMENTS_MANDOTORY;
				}
			}
			return APT_Constants.SUCCESS_LABEL;
		} catch(Exception ex) {
			return ex.getMessage();
		}
	}
	/**
	  To change status of approval process
	  @Params -
	  listApprovalRequest: ApprovalRequest List
   */
	public static String afterUpdateEvent(list<Apttus_Approval__Approval_Request__c> listApprovalRequest) {
		try{
			Map<Id,String> mapQuoteApprovalStatus = new Map<Id,String>();
			Map<Id,String> mapDangerousGoodsQuoteApprovalStatus = new Map<Id,String>();
			set<Id> quoteIdSet = new Set<Id>();
			for(Apttus_Approval__Approval_Request__c app: listApprovalRequest){
				if(!String.isEmpty(app.Apttus_Approval__StepLabel__c) && !String.isEmpty(APT_Constants.LABEL_APPROVAL_STEP_DANGEROUS_GOODS) && app.Apttus_Approval__StepLabel__c.equalsIgnoreCase(APT_Constants.LABEL_APPROVAL_STEP_DANGEROUS_GOODS)){
					mapDangerousGoodsQuoteApprovalStatus.put(app.Apttus_QPApprov__ProposalId__c,app.Apttus_Approval__Approval_Status__c);
					quoteIdSet.add(app.Apttus_QPApprov__ProposalId__c);
				}
				else if((!String.isEmpty(app.Apttus_Approval__StepLabel__c) && !String.isEmpty(APT_Constants.LABEL_APPROVAL_STEP_OVER_WEIGHT) && app.Apttus_Approval__StepLabel__c.equalsIgnoreCase(APT_Constants.LABEL_APPROVAL_STEP_OVER_WEIGHT)) ||
						(!String.isEmpty(app.Apttus_Approval__StepLabel__c) && !String.isEmpty(APT_Constants.LABEL_APPROVAL_STEP_DOMESTIC_OVERWEIGHT_ITEMS) && app.Apttus_Approval__StepLabel__c.equalsIgnoreCase(APT_Constants.LABEL_APPROVAL_STEP_DOMESTIC_OVERWEIGHT_ITEMS)) ||
						(!String.isEmpty(app.Apttus_Approval__StepLabel__c) && !String.isEmpty(APT_Constants.LABEL_APPROVAL_STEP_INTERNATIONAL_OVERWEIGHT_ITEMS) && app.Apttus_Approval__StepLabel__c.equalsIgnoreCase(APT_Constants.LABEL_APPROVAL_STEP_INTERNATIONAL_OVERWEIGHT_ITEMS)) ||
						(!String.isEmpty(app.Apttus_Approval__StepLabel__c) && !String.isEmpty(APT_Constants.LABEL_APPROVAL_STEP_INTERNATIONAL_ITEMS) && app.Apttus_Approval__StepLabel__c.equalsIgnoreCase(APT_Constants.LABEL_APPROVAL_STEP_INTERNATIONAL_ITEMS) ) ||
						(!String.isEmpty(app.Apttus_Approval__StepLabel__c) && !String.isEmpty(APT_Constants.LABEL_APPROVAL_STEP_UMS_OVERWEIGHT) && app.Apttus_Approval__StepLabel__c.equalsIgnoreCase(APT_Constants.LABEL_APPROVAL_STEP_UMS_OVERWEIGHT) )){
					mapQuoteApprovalStatus.put(app.Apttus_QPApprov__ProposalId__c,app.Apttus_Approval__Approval_Status__c);
					quoteIdSet.add(app.Apttus_QPApprov__ProposalId__c);
				}
			}
			List<Apttus_Proposal__Proposal__c> quoteList = new List<Apttus_Proposal__Proposal__c>();
			quoteList = [SELECT id,Name,APT_Overweight_Approval_Status__c,APT_Domestic_Overweight_Flag__c,APT_International_Overweight_Flag__c, APT_UMS_Overweight_Flag__c from Apttus_Proposal__Proposal__c where id in :quoteIdSet];

			for(Apttus_Proposal__Proposal__c prop : quoteList){
				if(mapQuoteApprovalStatus.containsKey(prop.Id) && (!String.isEmpty(mapQuoteApprovalStatus.get(prop.id)) && !String.isEmpty(APT_Constants.SEPERATOR_NO_SPACE) && !mapQuoteApprovalStatus.get(prop.id).equalsIgnoreCase(APT_Constants.SEPERATOR_NO_SPACE)) || !String.isEmpty(mapQuoteApprovalStatus.get(prop.id)) ){
					if(mapQuoteApprovalStatus.get(prop.id).contains(APT_Constants.APPROVAL_STATUS_REJECTED)&&(prop.APT_Domestic_Overweight_Flag__c|| prop.APT_International_Overweight_Flag__c || prop.APT_UMS_Overweight_Flag__c)){
						prop.APT_Overweight_Approval_Status__c =APT_Constants.APPROVAL_STATUS_REJECTED;
					}else if(mapQuoteApprovalStatus.get(prop.id).contains(APT_Constants.CREDIT_ASSESSMENT_STATUS_APPROVED)&& !String.isEmpty(prop.APT_Overweight_Approval_Status__c) && !String.isEmpty(APT_Constants.APPROVAL_STATUS_REJECTED) && !prop.APT_Overweight_Approval_Status__c.equalsIgnoreCase(APT_Constants.APPROVAL_STATUS_REJECTED))
						prop.APT_Overweight_Approval_Status__c =APT_Constants.CREDIT_ASSESSMENT_STATUS_APPROVED;
				}
				if(mapDangerousGoodsQuoteApprovalStatus.containsKey(prop.Id) &&
						((!String.isEmpty(mapDangerousGoodsQuoteApprovalStatus.get(prop.id)) && !String.isEmpty(APT_Constants.CREDIT_ASSESSMENT_STATUS_APPROVED) && mapDangerousGoodsQuoteApprovalStatus.get(prop.id).equalsIgnoreCase(APT_Constants.CREDIT_ASSESSMENT_STATUS_APPROVED))||
								(!String.isEmpty(mapDangerousGoodsQuoteApprovalStatus.get(prop.id)) && !String.isEmpty(APT_Constants.APPROVAL_STATUS_REJECTED) && mapDangerousGoodsQuoteApprovalStatus.get(prop.id).equalsIgnoreCase(APT_Constants.APPROVAL_STATUS_REJECTED)))){
					prop.APT_Dangerous_Goods_Status__c=mapDangerousGoodsQuoteApprovalStatus.get(prop.id);
				}
			}
			update quoteList;

			return APT_Constants.SUCCESS_LABEL;
		} catch(Exception ex) {
			return ex.getMessage();
		}
	}

	/**
		Method to Parse Approval Comments and Copy to line Item
	**/
	public static String copyApprovalComments(list<Apttus_Approval__Approval_Request__c> listApprovalRequest,set<Id> setLIIds) {
		try{
			map<Id,Apttus_Config2__LineItem__c> mapLI = new map<Id,Apttus_Config2__LineItem__c>([select id,Apttus_Config2__AdjustmentAmount__c,APT_Rate_Card_Key__c,APT_Previous_Discount__c from Apttus_Config2__LineItem__c where ID IN:setLIIds]);
			map<string,APT_ApprovalCommentsFieldMapping__c> mapCS = APT_ApprovalCommentsFieldMapping__c.getall();
			for(Apttus_Approval__Approval_Request__c appReq: listApprovalRequest){

				if(!String.isEmpty(appReq.Apttus_Approval__Approver_Comments__c)){
					for(string line: appReq.Apttus_Approval__Approver_Comments__c.split(APT_Constants.SEPERATOR_NEW_LINE)){
						for(string csVal: mapCS.keyset()){
							if(!line.startsWith(csVal) && line.contains(csVal)){
								line=line.substring((line.indexOf(csVal)));
							}

							if(line.startsWith(csVal)){
								List<string> lstfields=line.split(APT_Constants.SEPERATOR_NO_SPACE_HYPHEN);
								if(lstfields != null && lstfields.size()==2){
									string fieldName = lstfields[0].normalizeSpace();
									if(mapCS.get(fieldName) != null && !String.isEmpty(lstfields[1]) && mapLI.get(appReq.Apttus_Approval__ChildObjectId__c) != null){
										if(!String.isEmpty(mapCS.get(fieldName).APT_Field_Data_Type__c) && !String.isEmpty(APT_Constants.DATA_TYPE_NUMBER) && mapCS.get(fieldName).APT_Field_Data_Type__c.equalsIgnoreCase(APT_Constants.DATA_TYPE_NUMBER)){
											mapLI.get(appReq.Apttus_Approval__ChildObjectId__c).put(mapCS.get(fieldName).APT_Line_Item_Field_Name__c,integer.ValueOf(lstfields[1].replace(APT_Constants.SEPERATOR_PERCENT,APT_Constants.SEPERATOR_NO_SPACE).deleteWhitespace()));
										}else if(!String.isEmpty(mapCS.get(fieldName).APT_Field_Data_Type__c) && !String.isEmpty(APT_Constants.DATA_TYPE_TEXT) && mapCS.get(fieldName).APT_Field_Data_Type__c.equalsIgnoreCase(APT_Constants.DATA_TYPE_TEXT) ){
											mapLI.get(appReq.Apttus_Approval__ChildObjectId__c).put(mapCS.get(fieldName).APT_Line_Item_Field_Name__c,lstfields[1].replace(APT_Constants.SEPERATOR_PERCENT,APT_Constants.SEPERATOR_NO_SPACE).deleteWhitespace());
										}
									}
								}
							}
						}
					}
				}
			}

			if(mapLI.Size()>0){
				Update mapLI.values();
			}
			return APT_Constants.SUCCESS_LABEL;
		} catch(Exception ex) {
			return ex.getMessage();
		}
	}

	//STP-5156 Populate OOTB Related Proposal & Related Opportunity fields on AR
	public static void updateRelated(List<Apttus_Approval__Approval_Request__c> approvalrequestNew)
	{
		List<Apttus_Approval__Approval_Request__c> arToBeUpdated = new List<Apttus_Approval__Approval_Request__c>();
		try
		{
			set<Id> cartId = new set<Id>();
			for(Apttus_Approval__Approval_Request__c ar : approvalrequestNew)
			{
				if(ar.Apttus_CQApprov__CartId__c != null){
					cartId.add(ar.Apttus_CQApprov__CartId__c);
				}
			}
			Map<String, Apttus_Config2__ProductConfiguration__c> cartMap = new Map<String, Apttus_Config2__ProductConfiguration__c>();
			if(!cartId.isEmpty()){
				for(Apttus_Config2__ProductConfiguration__c cartIdRec :
				[Select Id, Apttus_QPConfig__Proposald__c,Apttus_QPConfig__Proposald__r.OwnerId,Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__c,
						Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.IsStartrackProposal__c
				from Apttus_Config2__ProductConfiguration__c where Id In: cartId]){
					cartMap.put(cartIdRec.Id, cartIdRec);
				}
			}
			if(!cartMap.isEmpty()){
				for(Apttus_Approval__Approval_Request__c ar : approvalrequestNew){
					if(cartMap.get(ar.Apttus_CQApprov__CartId__c). Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.IsStartrackProposal__c.equalsIgnoreCase(APT_Constants.OPTION_YES)){
						ar.Apttus_QPApprov__ProposalId__c = cartMap.get(ar.Apttus_CQApprov__CartId__c).Apttus_QPConfig__Proposald__c;
						ar.Apttus_Approval__Related_Opportunity__c=cartMap.get(ar.Apttus_CQApprov__CartId__c).Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__c;
						ar.Apttus_QPApprov__ProposalOwnerId__c = cartMap.get(ar.Apttus_CQApprov__CartId__c).Apttus_QPConfig__Proposald__r.OwnerId;
						//line item name checkpoint
						if(ar.Apttus_Approval__ChildObjectName__c.equalsIgnoreCase(APT_Constants.LINE_ITEM)){
							ar.Apttus_CQApprov__CartLineItemId__c=ar.Apttus_Approval__ChildObjectId__c;
						}
					}
				}
			}
		}
		catch(Exception ex)
		{
			System.debug('exception caused due to>>'+ex.getMessage()+'<<on line number>>'+ex.getLinenumber());
		}

	}
}