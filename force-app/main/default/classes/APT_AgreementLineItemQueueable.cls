/**
 Description:
Created By: Himanshu jain
Created Date: 25th Jun, 2016
**/
public with sharing class APT_AgreementLineItemQueueable implements Queueable {

	public String configurationID;
	public ID agreementID;
	public final static string ORDER_BY_LINENUMBER = ' Order By Apttus_QPConfig__LineNumber__c, Apttus_QPConfig__ItemSequence__c';
	/**
	 Constructor
	**/
	public APT_AgreementLineItemQueueable(String configurationId ,ID agreementID){
		this.agreementID = agreementID;
		this.configurationId = configurationId;
	}
	/**
	 Execute Method
	**/
	public void execute(QueueableContext context) {
	try {
		if(String.IsBlank(agreementID)){
			return;
		}
		Apttus__APTS_Agreement__c agreement = [select id,RecordType.DeveloperName,
												(select id from Apttus__AgreementLineItems__r) ,APT_Contract_Type__c, Included_Product_Lines__c
												from Apttus__APTS_Agreement__c
												where id =: agreementID];

		if(agreement == null || String.IsBlank(configurationID)
				|| String.IsBlank(agreement.Included_Product_Lines__c)
				|| (agreement.Apttus__AgreementLineItems__r != null
						&& agreement.Apttus__AgreementLineItems__r.size() > 0)){
			return;
		}
		String availableProductTypes = APT_Constants.EMPTY_STRING;

		if(String.IsNOtBlank(agreement.RecordType.DeveloperName)
			&& (APT_Constants.RECORD_TYPE_DOV_CONTRACT.equalsIgnoreCase(agreement.APT_Contract_Type__c)
				|| APT_Constants.RECORD_TYPE_RENEWAL_CONTRACT.equalsIgnoreCase(agreement.APT_Contract_Type__c))){
				system.Debug('agreement.RecordType.Name-------->' + agreement.RecordType.DeveloperName);

				List<APT_AgreementIncludedProductsLineMapping__mdt> agreementLineItemsMappings = [select id, Product_Type__c from APT_AgreementIncludedProductsLineMapping__mdt where MasterLabel=: agreement.RecordType.DeveloperName];
				system.Debug('agreementLineItemsMappings-------->' + agreementLineItemsMappings);

				if(agreementLineItemsMappings != null && agreementLineItemsMappings.size() > 0 ){
					for(APT_AgreementIncludedProductsLineMapping__mdt mapings  : agreementLineItemsMappings){
						availableProductTypes = availableProductTypes + mapings.Product_Type__c;
					}
			}
		} else {
			system.Debug('agreement.Included_Product_Lines__c-------->' + agreement.Included_Product_Lines__c);
			availableProductTypes = agreement.Included_Product_Lines__c;
			system.Debug('availableProductTypes-------->' + availableProductTypes);
		}

		system.Debug('availableProductTypes-------->' + availableProductTypes);

		Set<String> sourceFieldNames = new Set<String>(APT_AmendRenewUtility.getFieldNames(Apttus__AgreementLineItem__c.getSObjectType()));

		//create agreement line items
		list<Apttus__AgreementLineItem__c> listAgreementLineItems = new list<Apttus__AgreementLineItem__c>();
		set<String> setIgnoreFields = new set<String>{APT_Constants.SUMMARY_GROUP_ID_OBJECT, APT_Constants.ATTRIBUTE_VALUE_ID_OBJECT};

		Set<String> pliFieldNameSet = APT_AmendRenewUtility.getAllFieldsAPIName(APT_Constants.PROPOSAL_LINEITEM_OBJECT);

		String pliQuery = APT_Constants.SOQL_SELECT
							+ APT_AmendRenewUtility.getAllAgrFields(APT_Constants.PROPOSAL_LINEITEM_OBJECT)
							+ APT_Constants.product_non_contracted
							+ APT_Constants.product_product_type
							+ APT_Constants.STRING_FROM_PLI
							+ ORDER_BY_LINENUMBER;
		System.Debug('PliList-->' + database.query(pliQuery));
		Apttus__AgreementLineItem__c clonedAgreementLineItem;
		/*
		//1084
		map<decimal, Boolean> mapNewPricing = new map<decimal, Boolean>();
		//1084
		*/

		for(Apttus_Proposal__Proposal_Line_Item__c pli : database.query(pliQuery)) {
			system.Debug('pli-------->' + pli);

			clonedAgreementLineItem = new Apttus__AgreementLineItem__c();
			if(String.Isblank(pli.Apttus_Proposal__Product__r.APT_Product_type__c)
					|| !availableProductTypes.contains(pli.Apttus_Proposal__Product__r.APT_Product_type__c)
					|| pli.Apttus_Proposal__Product__r.Non_contracted__c){
				system.Debug('continue-------->' + pli.Apttus_Proposal__Product__r.Non_contracted__c);
				continue;
			}

			for (String fieldName : pliFieldNameSet) {
				Object value = pli.get(fieldName);
				if(value != null) {
					// get the target field name
					String tgFieldName =  (fieldName.startsWith(APT_Constants.NAMESPACE_APTTUS_ONLY) ? APT_AmendRenewUtility.toNoNamespaceName(fieldName) : fieldName);
					if(sourceFieldNames.contains(APT_Constants.NAMESPACE_APTTUS_CMCONFIG + tgFieldName) == true && setIgnoreFields.contains(APT_Constants.NAMESPACE_APTTUS_CMCONFIG + tgFieldName) == false ) {
						clonedAgreementLineItem.put(APT_Constants.NAMESPACE_APTTUS_CMCONFIG + tgFieldName, value);
					} else if(sourceFieldNames.contains(APT_Constants.NAMESPACE_APTTUS + tgFieldName) == true) {
						clonedAgreementLineItem.put(APT_Constants.NAMESPACE_APTTUS + tgFieldName, value);
					} else if(sourceFieldNames.contains(tgFieldName) == true) {
						clonedAgreementLineItem.put(tgFieldName, value);
					} else {}

				}
			}
			//set agreement id
			clonedAgreementLineItem.Apttus__AgreementId__c = agreementID;
			clonedAgreementLineItem.Apttus__ProductId__c = pli.Apttus_Proposal__Product__c;
			clonedAgreementLineItem.Apttus__Quantity__c = pli.Apttus_QPConfig__Quantity2__c;

			listAgreementLineItems.add(clonedAgreementLineItem);
			system.Debug('clonedAgreementLineItem-->' + clonedAgreementLineItem);
		system.Debug('pli-->' + pli);
		}

		system.Debug('listAgreementLineItems-->' + listAgreementLineItems);

		if(listAgreementLineItems.size() > 0) {
			insert listAgreementLineItems;

			If(!test.isrunningtest()) ID jobID = System.enqueueJob(new APT_AgreementLineItemChildQueueable(new Set<ID>{agreementID}));

			List<Apttus__AgreementLineItem__c> aliListForDOSUpdate = new List<Apttus__AgreementLineItem__c>();
			aliListForDOSUpdate = [select id, Apttus__AgreementId__r.Operational_Schedule__c,
									Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Estimated_Revenue__c,
									Apttus__ProductId__r.Name,Apttus__ProductId__r.ProductCode, Apttus__AgreementId__r.Included_Product_Lines__c,
									Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Minimum_Quantity__c,
									Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.Transit_cover__c,
									Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Volume_Thresholds__c,
									Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_PostBillPay_Channel__c,
									Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Payment_Method__c,
									Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Minimum_Fees__c,
									Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Annual_Volume_Review__c
									from Apttus__AgreementLineItem__c
									where Apttus__AgreementId__c =: agreementID
									and Apttus_CMConfig__OptionId__c = null
									and Apttus_CMConfig__IsPrimaryLine__c = true];

			APT_Operational_Schedule__c dos = new APT_Operational_Schedule__c();


			if(aliListForDOSUpdate!= null && aliListForDOSUpdate.size() > 0 ){
				//This is done hardcoded as this Queueable Method will run for single Agreement and for single
				// agreement we have only one Product attribute Values.

				for(Apttus__AgreementLineItem__c ali: aliListForDOSUpdate){
					dos.ID = ali.Apttus__AgreementId__r.Operational_Schedule__c;

					if(APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE.equalsIgnoreCase(ali.Apttus__ProductId__r.ProductCode) || APT_Constants.PRODUCT_CODE_INTERNATIONAL_PCMS.equalsIgnoreCase(ali.Apttus__ProductId__r.ProductCode) || APT_Constants.PRODUCT_CODE_INTERNATIONAL_PCMS_airmail.equalsIgnoreCase(ali.Apttus__ProductId__r.ProductCode)){
						dos.APT_IP_Minimum_Revenue_per_annum__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Estimated_Revenue__c;

					} else if(APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD.equalsIgnoreCase(ali.Apttus__ProductId__r.ProductCode)
							|| APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS.equalsIgnoreCase(ali.Apttus__ProductId__r.ProductCode)) {
						dos.APT_Parcels_Minimum_Quantity_per_annum__c = String.ValueOf(ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Minimum_Quantity__c);
						if(null != ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.Transit_cover__c && String.IsNotBlank(ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.Transit_cover__c)){
							dos.APT_Parcel_Services_Transit_Cover__c = true;
						}

					} else if(APT_Constants.PRODUCT_CODE_UNADDRESSED_MAIL_SERVICES.equalsIgnoreCase(ali.Apttus__ProductId__r.ProductCode)){
						/*
						Decimal umsMinQuantity = 0;
						String volumeThresold = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Volume_Thresholds__c;
						if(String.IsBlank(volumeThresold)){
							umsMinQuantity = 0;
						} else if(VOLUME_THERESHOLD_250K.equalsIgnoreCase(volumeThresold)){
							umsMinQuantity = 250000;
						} else if(VOLUME_THERESHOLD_500K.equalsIgnoreCase(volumeThresold)){
							umsMinQuantity = 500000;
						} else if(VOLUME_THERESHOLD_1M.equalsIgnoreCase(volumeThresold)){
							umsMinQuantity = 1000000;
						} else if(VOLUME_THERESHOLD_2M.equalsIgnoreCase(volumeThresold)){
							umsMinQuantity = 2500000;
						} else {
							umsMinQuantity = 0;
						}
						*/
						Decimal umsMinQuantity = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Minimum_Quantity__c;

						dos.APT_UMS_Minimum_Quantity__c = umsMinQuantity;
					}
					//Changes to update operational schedule record for post billpay product on cart update during renewal/dov
					else if (APT_Constants.PRODUCT_CODE_POSTBILLPAY.equalsIgnoreCase(ali.Apttus__ProductId__r.ProductCode)){
						dos.APT_PostBillPay_Channel__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_PostBillPay_Channel__c;
						dos.APT_Payment_Method__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Payment_Method__c;
						dos.APT_Minimum_Fees__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Minimum_Fees__c;
						dos.APT_Annual_Volume_Review__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Annual_Volume_Review__c;
					}
					else {

					}

				}

				if(null != dos.ID && String.IsNotBlank(dos.ID)){
					update dos;
				}
			}
		}

		} catch (System.Exception ex) {
			system.debug(Logginglevel.ERROR, 'Exception msg : ' + ex.getMessage());
			throw ex;
		}
	}

	public static final String VOLUME_THERESHOLD_0 = '0 - 250K';
	public static final String VOLUME_THERESHOLD_250K = '250K - 499K';
	public static final String VOLUME_THERESHOLD_500K = '500K - 999K';
	public static final String VOLUME_THERESHOLD_1M = '1M - 2.5M';
	public static final String VOLUME_THERESHOLD_2M = 'Above 2.5M';


}