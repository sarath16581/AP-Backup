/**************************************************
Description: This apex class if handler class for apex trigger - APT_AgreementLineItemTrigger.
History:
2015-12-03 Garvita Rai Created
2016-10-07 Mausam Padhiyar Modified  , defect-1512
2019-05-31 anshul.goyal@auspost.com.au Modified | 31052019 | mark boolean custom fields (Regular_Speed_Service__c,Premium_Express_Speed_Service__c) on the operational schedule record
2019-12-19 Seth Heang Modified | Update operational schedule to capture attribute value for Local Pickup and Delivery Product, and populate agreement attribute value based on Line's Item attribute value into agreement line item's field
2020-01-27 Sheryl Crisostomo Modified | Added additional picklist value called Pickup & Delivery At the same time for Local Pickup and Delivery service type
2021-03-02 - Mathew Jose - Amended International & Local pick & delivery service's automation on DOS checkoxes to be based on relevant product codes & charge types (STP-4590)
2021-06-22 Naveen Rajanna Changed APT_LPD_Frequency__c picklist to APT_LPD_Multiple_Frequency__c  multi-picklist field
2021-10-28 Sautul Mehta - CI-96 Changes for APPC Contract Template Document Generation.
2022-04-26 Pradeep Jaiswal - CI-224 Populated Cubic Status, Cubic Factor and Existing APPC Customer Attributes
2022-05-23 Chaitanya Doshi - Changed condition to exact match Product code as "Premium - STE" has blank Productcode and "contains" is causing issue in PROD.
2022-07-15 Nasir Jawed CI-552 Populating the Agreement Line Item fields when its FSR product for lodgement fields.
2022-09-01 Nasir Jawed CI-288 commenting the code which populate the Agreement Product Attributes values fields as this is done Out of the Box product.
2022-11-04 Harry Wang MW0004978 Adding logic to populating DOS for Startrack products
**************************************************/

public with sharing class APT_AgreementLineItemTriggerHandler{

	/**
	 * before insert trigger event
	 */
	public static String beforeInsertEvent(List<Apttus__AgreementLineItem__c> aliList) {
		try {
			//1084
			for(Apttus__AgreementLineItem__c ali : aliList) {
				if(ali.APT_Mark_All_Agreement_Line_Items_as_Old__c) {
					ali.APT_New__c = false;
				}       
			}
			//1084
			return APT_Constants.SUCCESS_LABEL;
		} catch(system.exception ex) {
			return ex.getMessage();
		}
	}    
	/**
	 * after insert agreement line item
	 */
	public static String afterInsertOrDeleteEvent(List<Apttus__AgreementLineItem__c> aliList, Boolean isInsert, Boolean isDelete) {
		try {
			
			//process builder to trigger
			set<Id> setAgreementLineItemId = new set<Id>();
			List<Apttus__AgreementLineItem__c> listAliToUpdate = new List<Apttus__AgreementLineItem__c>();

			//CI-552 When the product is FSR update price structure to Z1
			Map<String,APT_FSR_Product__c> allCodes = APT_FSR_Product__c.getAll();              
			list<String> fsrProducts= new list<String>();
			for(APT_FSR_Product__c fsr: allCodes.values()){
				fsrProducts.add(fsr.name);    
			}
			//CI-552

			for(Apttus__AgreementLineItem__c ali : aliList) {
				setAgreementLineItemId.add(ali.Id);
			}

			//set<Id> setUniqueOSId = new set<Id>();
			map<Id, APT_Operational_Schedule__c> mapOS = new map<Id, APT_Operational_Schedule__c>();
			//list<APT_Operational_Schedule__c> listOS = new list<APT_Operational_Schedule__c>();
			APT_Operational_Schedule__c os;
			Apttus_CMConfig__AgreementProductAttributeValue__c newApav;
			Boolean steCleared = false;
			
			// map used for 'Local Pickup and Delivery Services' Product that associate Agreement Line Item and Agreement Product Attribute Value
			map<Apttus__AgreementLineItem__c, Apttus_CMConfig__AgreementProductAttributeValue__c> mapAgreementLineItemToPav = new map<Apttus__AgreementLineItem__c, Apttus_CMConfig__AgreementProductAttributeValue__c>();
				for(Apttus__AgreementLineItem__c ali : [SELECT Id, Apttus__ProductId__c, Apttus__ProductId__r.Name, Apttus__ProductId__r.ProductCode,
													Apttus_CMConfig__ChargeType__c, Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c,
													Apttus_CMConfig__OptionId__c, Apttus_CMConfig__OptionId__r.Name, Apttus_CMConfig__OptionId__r.ProductCode,
													Apttus_CMConfig__OptionId__r.Apttus_Config2__ConfigurationType__c,Apttus_CMConfig__OptionId__r.Lodgement_zone__c,
													Apttus_CMConfig__OptionId__r.APT_Lodgement_Zone_Code__c,
													Apttus__AgreementId__r.recordType.Name, Apttus__AgreementId__r.Operational_Schedule__c,
													Apttus__AgreementId__r.Operational_Schedule__r.Fixed_Price_Premium__c,
													Apttus__AgreementId__r.Operational_Schedule__r.Premium_Priority_Air_Services__c,
													Apttus__AgreementId__r.Apttus_QPComply__RelatedProposalId__c,
													Apttus__AgreementId__r.Apttus_QPComply__RelatedProposalId__r.APT_Minimum_Monthly_Spend__c,
													Apttus__AgreementId__r.Apttus_QPComply__RelatedProposalId__r.APT_Dangerous_Goods_Flag__c,
													APT_Identical_Line__c, List_Price_Text__c,
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Subsequent_Parcel_Discount__c,
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Min_Transit_Cover_Amount_Per_Article__c,
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Min_Spend_Per_Annum__c,
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Price_Structure__c,
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Cubic_Status__c,
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Cubic_Factor__c,  
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Existing_APPC_Customer__c, 
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Estimated_Revenue__c,
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Distance_Facility_Provided_In_Km__c,
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Multiple_Frequency__c,
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Collection_Address_From_1__c,
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Collection_Address_From_2__c,
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Service_Type__c,
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_From_Time_24_hour_clock_1__c,
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_To_Time_24_hour_clock_1__c,
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_From_Time_24_hour_clock_2__c,
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_To_Time_24_hour_clock_2__c,
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Collection_Address_To_1__c,
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Collection_Address_To_2__c,
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Customer_Tier__c,
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.Transit_cover__c,
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Transit_Cover_Type__c,
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.SAP_Weight_Rounding__c,
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.SAP_Cubic_Conversion_Factor__c,
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.SAP_Rating_Group__c,
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.SAP_Rating_Model__c,
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.SAP_Rating_Plan_DWT_Conversion_Factor__c,
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Selected_Lodgement_Zone__c,
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Additional_Lodgement_Zone_1__c,
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Additional_Lodgement_Zone_2__c,
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.Applied_PSR__c,
													//Adding Post Billpay attribute values
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Annual_Volume_Review__c,
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Volume_Threshold_PBP__c,
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Minimum_Fees__c,
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_PostBillPay_Channel__c,
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_PostBillPay_Gross_Settlement_fee__c,
													Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Payment_Method__c,
													APT_Option_Group__c,
													APT_Lodgement_Zone_Code__c,
													APT_Lodgement_Zone__c,
													Apttus_CMConfig__OptionId__r.APT_Apttus_Product_Classification__c
													FROM Apttus__AgreementLineItem__c
													WHERE Id IN :setAgreementLineItemId]) {
				
				//CI-552 When the product is FSR update price structure to Z001
				if(fsrProducts.contains(ali.Apttus_CMConfig__OptionId__r.APT_Apttus_Product_Classification__c)){
					Apttus__AgreementLineItem__c ref = new Apttus__AgreementLineItem__c();
					ref.Id = ali.Id;
					ref.APT_Lodgement_Zone_Code__c = ali.Apttus_CMConfig__OptionId__r.APT_Lodgement_Zone_Code__c;  //'AN';
					ref.APT_Lodgement_Zone__c = ali.Apttus_CMConfig__OptionId__r.Lodgement_zone__c ;   //'Anywhere';
					listAliToUpdate.add(ref);                   
				}

				
				if(mapOS.get(ali.Apttus__AgreementId__r.Operational_Schedule__c) != null) {
					os = mapOS.get(ali.Apttus__AgreementId__r.Operational_Schedule__c);
				} else {
					os = new APT_Operational_Schedule__c();
				}

				// initialise agreement product attribute value if empty, else skip
				if(mapAgreementLineItemToPav.get(ali) != null){
					newApav = mapAgreementLineItemToPav.get(ali);
				}else{
					newApav = new Apttus_CMConfig__AgreementProductAttributeValue__c();
				}
				
				//UMS
				if(String.isBlank(ali.Apttus_CMConfig__OptionId__c) && String.isNotBlank(ali.Apttus__ProductId__c) && null != ali.Apttus__ProductId__r.ProductCode && String.isNotBlank(ali.Apttus__ProductId__r.ProductCode) && ali.Apttus__ProductId__r.ProductCode.contains(APT_Constants.PRODUCT_CODE_UNADDRESSED_MAIL_SERVICES)
					&& String.isNotBlank(ali.Apttus__AgreementId__r.recordType.Name) && ali.Apttus__AgreementId__r.recordType.Name.contains(APT_Constants.MSA)
					&& null != ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c && String.isNotBlank(ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c) && ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c.equalsIgnoreCase(APT_Constants.CONFIG_TYPE_STAND_ALONE)
					&& null != ali.Apttus__AgreementId__r.Operational_Schedule__c && String.isNotBlank(ali.Apttus__AgreementId__r.Operational_Schedule__c) && !ali.APT_Identical_Line__c) {
					
					os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
					if(isInsert) {
						os.APT_Unaddressed_Mail__c = true;
					} 
					
					if(isDelete) {
						os.APT_Unaddressed_Mail__c = false;
					}
					
					mapOS.put(os.Id, os);
				}
				
				//Print post
				if(String.isBlank(ali.Apttus_CMConfig__OptionId__c) && String.isNotBlank(ali.Apttus__ProductId__c) && null != ali.Apttus__ProductId__r.ProductCode && String.isNotBlank(ali.Apttus__ProductId__r.ProductCode) && ali.Apttus__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_PRINT_POST)
					&& String.isNotBlank(ali.Apttus__AgreementId__r.recordType.Name) && ali.Apttus__AgreementId__r.recordType.Name.contains(APT_Constants.MSA)
					&& null != ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c && String.isNotBlank(ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c) && ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c.equalsIgnoreCase(APT_Constants.CONFIG_TYPE_STAND_ALONE)
					&& null != ali.Apttus__AgreementId__r.Operational_Schedule__c && String.isNotBlank(ali.Apttus__AgreementId__r.Operational_Schedule__c) && !ali.APT_Identical_Line__c) {
					
					os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
					if(isInsert) {
						os.APT_Print_Post__c = true;
					} 
					
					if(isDelete) {
						os.APT_Print_Post__c = false;
					}
					
					mapOS.put(os.Id, os);
				}
				
				//Post Bill Pay product value attribute assignmemt to agreement line items
				if(String.isNotBlank(ali.Apttus__ProductId__c) && null != ali.Apttus__ProductId__r.ProductCode && String.isNotBlank(ali.Apttus__ProductId__r.ProductCode) && 
					ali.Apttus__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_POSTBILLPAY) && null != ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c && String.isNotBlank(ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c)) {
					newApav.Apttus_CMConfig__LineItemId__c = ali.id;
					newApav.APT_Annual_Volume_Review__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Annual_Volume_Review__c;
					newApav.APT_Volume_Threshold_PBP__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Volume_Threshold_PBP__c;
					newApav.APT_Minimum_Fees__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Minimum_Fees__c;
					newApav.APT_PostBillPay_Channel__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_PostBillPay_Channel__c;
					newApav.APT_PostBillPay_Gross_Settlement_fee__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_PostBillPay_Gross_Settlement_fee__c;
					newApav.APT_Payment_Method__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Payment_Method__c;
					mapAgreementLineItemToPav.put(ali, newApav);
				}
				
				//Local Pickup 
				if((String.isBlank(ali.Apttus_CMConfig__OptionId__c) 
					&& String.isNotBlank(ali.Apttus__ProductId__c) 
					&& null != ali.Apttus__ProductId__r.ProductCode 
					&& String.isNotBlank(ali.Apttus__ProductId__r.ProductCode) 
					&& (ali.Apttus__ProductId__r.ProductCode.contains(APT_Constants.PRODUCT_CODE_LOCAL_PICKUP_DELIVERY))
					&& String.isNotBlank(ali.Apttus__AgreementId__r.recordType.Name) 
					&& ali.Apttus__AgreementId__r.recordType.Name.contains(APT_Constants.MSA)
					&& null != ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c 
					&& String.isNotBlank(ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c) 
					&& ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c.equalsIgnoreCase(APT_Constants.CONFIG_TYPE_STAND_ALONE)
					&& null != ali.Apttus__AgreementId__r.Operational_Schedule__c 
					&& String.isNotBlank(ali.Apttus__AgreementId__r.Operational_Schedule__c)
					) || ( 
						// Chaitanya 23-05-2022: Changed condition to exact match Product code as "Premium - STE" has blank Productcode and "contains" is causing issue in PROD.
						ali.Apttus__ProductId__r.ProductCode == APT_Constants.PRODUCT_CODE_APPC 
					))                   
					{                       
					os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
					if(isInsert) {
						os.APT_Parcel__c = true; //US-126
						// Populate relevant attribute values from DerivedFrom field and save into an agreement product attribute value
						newApav.APT_LPD_Service_Type__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Service_Type__c;
						newApav.APT_LPD_Multiple_Frequency__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Multiple_Frequency__c;
						newApav.APT_LPD_Distance_Facility_Provided_In_Km__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Distance_Facility_Provided_In_Km__c;
						newApav.APT_LPD_Collection_Address_From_1__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Collection_Address_From_1__c;
						newApav.APT_LPD_Collection_Address_From_2__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Collection_Address_From_2__c;
						newApav.APT_LPD_From_Time_24_hour_clock_1__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_From_Time_24_hour_clock_1__c;
						newApav.APT_LPD_To_Time_24_hour_clock_1__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_To_Time_24_hour_clock_1__c;
						newApav.APT_LPD_From_Time_24_hour_clock_2__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_From_Time_24_hour_clock_2__c;
						newApav.APT_LPD_To_Time_24_hour_clock_2__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_To_Time_24_hour_clock_2__c;
						newApav.APT_LPD_Collection_Address_To_1__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Collection_Address_To_1__c;
						newApav.APT_LPD_Collection_Address_To_2__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Collection_Address_To_2__c;
						// Attach agreement line item to agreement product attribute value
						newApav.Apttus_CMConfig__LineItemId__c = ali.id;

						newApav.APT_Subsequent_Parcel_Discount__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Subsequent_Parcel_Discount__c;
						newApav.APT_Min_Transit_Cover_Amount_Per_Article__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Min_Transit_Cover_Amount_Per_Article__c;
						newApav.APT_Min_Spend_Per_Annum__c =  ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Min_Spend_Per_Annum__c;
						newApav.APTS_Price_Structure__c =  ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Price_Structure__c;
						newApav.APT_Cubic_Factor__c =  ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Cubic_Factor__c;
						newApav.APT_Cubic_Status__c =  ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Cubic_Status__c;
						newApav.APT_Existing_APPC_Customer__c =  ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Existing_APPC_Customer__c;
						
						
						//Populate Agreement product attribute values field from Derived field 
						newApav.APT_Transit_Cover_Type__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Transit_Cover_Type__c;
						newApav.Transit_cover__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.Transit_cover__c;
						newApav.APT_Customer_Tier__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Customer_Tier__c;
						newApav.SAP_Cubic_Conversion_Factor__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.SAP_Cubic_Conversion_Factor__c;
						newApav.SAP_Rating_Group__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.SAP_Rating_Group__c;
						newApav.SAP_Rating_Model__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.SAP_Rating_Model__c;
						newApav.SAP_Rating_Plan_DWT_Conversion_Factor__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.SAP_Rating_Plan_DWT_Conversion_Factor__c;
						newApav.SAP_Weight_Rounding__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.SAP_Weight_Rounding__c; 
												
						newApav.APT_Selected_Lodgement_Zone__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Selected_Lodgement_Zone__c;
						newApav.APT_Additional_Lodgement_Zone_1__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Additional_Lodgement_Zone_1__c;
						newApav.APT_Additional_Lodgement_Zone_2__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Additional_Lodgement_Zone_2__c;
						newApav.Applied_PSR__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.Applied_PSR__c;

						// Populate attribute values from DerivedFrom field into a new operational schedule
						os.APT_LPD_Service_Type__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Service_Type__c;
						os.APT_LPD_Multiple_Frequency__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Multiple_Frequency__c;
						//mathew.jose@auspost.com.au added the following line to update the checkbox on DOS for the Local Pickup & Delivery.
						os.APT_Courier__c = true;
						// 'Service Type and Frequency' field is used to distinguish combination of:
						// - Frequency: 'Scheduled' or 'Ad hoc'
						// - Service Type: 'Delivery' or 'Pickup' or 'Pickup & Delivery At the same time'
						// And is solely used to tick appropriate service type's checkboxes in the 'R2T Long Form Operational Schedule' template
						if(String.isNotBlank(os.APT_LPD_Multiple_Frequency__c)){
							if((os.APT_LPD_Service_Type__c).equalsIgnoreCase('Delivery Service')
								|| (os.APT_LPD_Service_Type__c).equalsIgnoreCase('Pickup Service')
								|| (os.APT_LPD_Service_Type__c).equalsIgnoreCase('Pickup & Delivery At the same time')){
									// Check Service types so that appropriate frequency such as 'Ad hoc' or 'Scheduled' can be assigned correctly
									List<String> multiFrequency = os.APT_LPD_Multiple_Frequency__c.split(';');
									if(multiFrequency.contains('Ad hoc')){
										os.APT_LPD_Service_Type_and_Frequency__c += os.APT_LPD_Service_Type__c + ' Ad hoc; ';
									}else{
										os.APT_LPD_Service_Type_and_Frequency__c += os.APT_LPD_Service_Type__c + ' Scheduled; ';
									}
								}else{
								// Adhoc is not available for other service types
									os.APT_LPD_Service_Type_and_Frequency__c += os.APT_LPD_Service_Type__c + '; ';
								}
						}
						
						// Populate the other relevent attribute values
						os.APT_LPD_Distance_Facility_Provided_In_Km__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Distance_Facility_Provided_In_Km__c;
						os.APT_LPD_Collection_Address_From_1__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Collection_Address_From_1__c;
						os.APT_LPD_Collection_Address_From_2__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Collection_Address_From_2__c;
						os.APT_LPD_From_Time_24_hour_clock_1__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_From_Time_24_hour_clock_1__c;
						os.APT_LPD_To_Time_24_hour_clock_1__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_To_Time_24_hour_clock_1__c;
						os.APT_LPD_From_Time_24_hour_clock_2__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_From_Time_24_hour_clock_2__c;
						os.APT_LPD_To_Time_24_hour_clock_2__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_To_Time_24_hour_clock_2__c;
						os.APT_LPD_Collection_Address_To_1__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Collection_Address_To_1__c;
						os.APT_LPD_Collection_Address_To_2__c = ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_LPD_Collection_Address_To_2__c;
					} 
									
					if(isDelete) {
						os.APT_Courier__c = false;
					}
					// Associate agreement line item with relevant  agreement product attribute value using a map
					mapAgreementLineItemToPav.put(ali, newApav);
					mapOS.put(os.Id, os);
				}
				//eparcel
				if(String.isBlank(ali.Apttus_CMConfig__OptionId__c) && String.isNotBlank(ali.Apttus__ProductId__c) && null != ali.Apttus__ProductId__r.ProductCode && String.isNotBlank(ali.Apttus__ProductId__r.ProductCode) && ali.Apttus__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD)
					&& String.isNotBlank(ali.Apttus__AgreementId__r.recordType.Name) && ali.Apttus__AgreementId__r.recordType.Name.contains(APT_Constants.MSA)
					&& null != ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c && String.isNotBlank(ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c) && ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c.equalsIgnoreCase(APT_Constants.LABEL_LINE_TYPE_BUNDLE)
					&& null != ali.Apttus__AgreementId__r.Operational_Schedule__c && String.isNotBlank(ali.Apttus__AgreementId__r.Operational_Schedule__c) && !ali.APT_Identical_Line__c
					) {
					
					os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
					if(isInsert) {                        
						os.APT_Parcel_Services_eParcel__c = true;
						os.APT_Parcel__c = true;
					} 
					
					if(isDelete) {
						os.APT_Parcel_Services_eParcel__c = false;
						os.APT_Parcel__c = false;
					}
					
					mapOS.put(os.Id, os);
				}
				
				//eparcel and dangerous goods flag = true
				if(String.isBlank(ali.Apttus_CMConfig__OptionId__c) && String.isNotBlank(ali.Apttus__ProductId__c) && null != ali.Apttus__ProductId__r.ProductCode && String.isNotBlank(ali.Apttus__ProductId__r.ProductCode) && ali.Apttus__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_STANDARD)
					&& String.isNotBlank(ali.Apttus__AgreementId__r.recordType.Name) && ali.Apttus__AgreementId__r.recordType.Name.contains(APT_Constants.MSA)
					&& null != ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c && String.isNotBlank(ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c) && ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c.equalsIgnoreCase(APT_Constants.LABEL_LINE_TYPE_BUNDLE)
					&& null != ali.Apttus__AgreementId__r.Operational_Schedule__c && String.isNotBlank(ali.Apttus__AgreementId__r.Operational_Schedule__c) && !ali.APT_Identical_Line__c
					&& null != ali.Apttus__AgreementId__r.Apttus_QPComply__RelatedProposalId__c && String.isNotBlank(ali.Apttus__AgreementId__r.Apttus_QPComply__RelatedProposalId__c)
					&& ali.Apttus__AgreementId__r.Apttus_QPComply__RelatedProposalId__r.APT_Dangerous_Goods_Flag__c
					&& null != ali.Apttus_CMConfig__ChargeType__c && String.isNotBlank(ali.Apttus_CMConfig__ChargeType__c) && ali.Apttus_CMConfig__ChargeType__c.equalsIgnoreCase(APT_Constants.CHARGE_TYPE_STANDARD_PRICE)) {
					
					os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
					if(isInsert) {
						os.APT_Parcel_Services_Special_Parcel__c = true;
					} 
					
					if(isDelete) {
						os.APT_Parcel_Services_Special_Parcel__c = false;
					}
					
					mapOS.put(os.Id, os);
				}
				
				//eparcel call for return
				if(String.isNotBlank(ali.Apttus_CMConfig__OptionId__c) && null != ali.Apttus_CMConfig__OptionId__r.ProductCode && String.isNotBlank(ali.Apttus_CMConfig__OptionId__r.ProductCode) && ali.Apttus_CMConfig__OptionId__r.ProductCode.contains(APT_Constants.PRODUCT_CODE_EPARCEL_CALL_FOR_RETURN) 
					&& null != ali.Apttus_CMConfig__OptionId__r.Apttus_Config2__ConfigurationType__c && String.isNotBlank(ali.Apttus_CMConfig__OptionId__r.Apttus_Config2__ConfigurationType__c) && ali.Apttus_CMConfig__OptionId__r.Apttus_Config2__ConfigurationType__c.equalsIgnoreCase(APT_Constants.LABEL_LINE_TYPE_OPTION)
					&& String.isNotBlank(ali.Apttus__AgreementId__r.recordType.Name) && ali.Apttus__AgreementId__r.recordType.Name.contains(APT_Constants.MSA)
					&& null != ali.Apttus__AgreementId__r.Operational_Schedule__c && String.isNotBlank(ali.Apttus__AgreementId__r.Operational_Schedule__c) && !ali.APT_Identical_Line__c) {
					
					os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
					if(isInsert) {
						os.APT_Parcel_Srvics_eParcel_Call_for_Retrn__c = true;
					} 
					
					if(isDelete) {
						os.APT_Parcel_Srvics_eParcel_Call_for_Retrn__c = false;
					}
					
					mapOS.put(os.Id, os);
				}
				
				//eParcel Post Return
				if(String.isNotBlank(ali.Apttus_CMConfig__OptionId__c) && null != ali.Apttus_CMConfig__OptionId__r.ProductCode && String.isNotBlank(ali.Apttus_CMConfig__OptionId__r.ProductCode) && ali.Apttus_CMConfig__OptionId__r.ProductCode.contains(APT_Constants.PRODUCT_CODE_EPARCEL_POST_RETURN) 
					&& null != ali.Apttus_CMConfig__OptionId__r.Apttus_Config2__ConfigurationType__c && String.isNotBlank(ali.Apttus_CMConfig__OptionId__r.Apttus_Config2__ConfigurationType__c) && ali.Apttus_CMConfig__OptionId__r.Apttus_Config2__ConfigurationType__c.equalsIgnoreCase(APT_Constants.CONFIG_TYPE_STAND_ALONE)
					&& String.isNotBlank(ali.Apttus__AgreementId__r.recordType.Name) && ali.Apttus__AgreementId__r.recordType.Name.contains(APT_Constants.MSA)
					&& null != ali.Apttus__AgreementId__r.Operational_Schedule__c && String.isNotBlank(ali.Apttus__AgreementId__r.Operational_Schedule__c) && !ali.APT_Identical_Line__c) {
					
					os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
					if(isInsert) {
						os.APT_Parcel_Servcs_eParcel_Retrns_Service__c = true;
					} 
					
					if(isDelete) {
						os.APT_Parcel_Servcs_eParcel_Retrns_Service__c = false;
					}
					
					mapOS.put(os.Id, os);
				}
				
				/**
				//defect 1512
				//Identity on Delivery Service
				if(String.isNotBlank(ali.Apttus_CMConfig__OptionId__c) && String.isNotBlank(ali.Apttus_CMConfig__OptionId__r.ProductCode) && ali.Apttus_CMConfig__OptionId__r.ProductCode.contains(APT_Constants.PRODUCT_CODE_IDENTITY_ON_DELIVERY_SERVICE) 
					&& String.isNotBlank(ali.Apttus_CMConfig__OptionId__r.Apttus_Config2__ConfigurationType__c) && ali.Apttus_CMConfig__OptionId__r.Apttus_Config2__ConfigurationType__c.equalsIgnoreCase(APT_Constants.LABEL_LINE_TYPE_OPTION)
					&& String.isNotBlank(ali.Apttus__AgreementId__r.recordType.Name) && ali.Apttus__AgreementId__r.recordType.Name.contains(APT_Constants.MSA)
					&& String.isNotBlank(ali.Apttus__AgreementId__r.Operational_Schedule__c) && !ali.APT_Identical_Line__c) {
					
					os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
					if(isInsert) {
						os.APT_Parcl_Servcs_eParcl_Identity_on_Deli__c = true;
					} 
					
					if(isDelete) {
						os.APT_Parcl_Servcs_eParcl_Identity_on_Deli__c = false;
					}
					
					mapOS.put(os.Id, os);
				}
				**/
				
				//eparcel express
				if(String.isBlank(ali.Apttus_CMConfig__OptionId__c) && String.isNotBlank(ali.Apttus__ProductId__c) && null != ali.Apttus__ProductId__r.ProductCode && String.isNotBlank(ali.Apttus__ProductId__r.ProductCode) && ali.Apttus__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_ePARCEL_EXPRESS)
					&& String.isNotBlank(ali.Apttus__AgreementId__r.recordType.Name) && ali.Apttus__AgreementId__r.recordType.Name.contains(APT_Constants.MSA)
					&& null != ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c && String.isNotBlank(ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c) && ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c.equalsIgnoreCase(APT_Constants.LABEL_LINE_TYPE_BUNDLE)
					&& null != ali.Apttus__AgreementId__r.Operational_Schedule__c && String.isNotBlank(ali.Apttus__AgreementId__r.Operational_Schedule__c) && !ali.APT_Identical_Line__c
					&& null != ali.Apttus_CMConfig__ChargeType__c && null != ali.Apttus_CMConfig__ChargeType__c && String.isNotBlank(ali.Apttus_CMConfig__ChargeType__c) && ali.Apttus_CMConfig__ChargeType__c.equalsIgnoreCase(APT_Constants.CHARGE_TYPE_STANDARD_PRICE)) {
					
					os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
					if(isInsert) {
						os.APT_Parcel_Services_Express_Post_Parcel__c = true;
						os.APT_Parcel_Services_Express_eParcel__c = true;
						os.APT_Parcel__c = true;
					} 
					
					if(isDelete) {
						os.APT_Parcel_Services_Express_Post_Parcel__c = false;
						os.APT_Parcel_Services_Express_eParcel__c = false;
						os.APT_Parcel__c = false;
					}
					
					mapOS.put(os.Id, os);
				}
				
				//international postal
				//mathew.jose@auspost.com.au updated the if condition to include all the different international product codes & charge types.                
				if(String.isBlank(ali.Apttus_CMConfig__OptionId__c) && String.isNotBlank(ali.Apttus__ProductId__c) 
					&& null != ali.Apttus__ProductId__r.ProductCode && String.isNotBlank(ali.Apttus__ProductId__r.ProductCode)                      
					&& (ali.Apttus__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_BUNDLE) || 
						ali.Apttus__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_PCMS_airmail) ||
						ali.Apttus__ProductId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_PCMS)) 
					&& String.isNotBlank(ali.Apttus__AgreementId__r.recordType.Name) && ali.Apttus__AgreementId__r.recordType.Name.contains(APT_Constants.MSA)
					&& null != ali.Apttus_CMConfig__ChargeType__c && String.isNotBlank(ali.Apttus_CMConfig__ChargeType__c)   
					&& (ali.Apttus_CMConfig__ChargeType__c.equalsIgnoreCase(APT_Constants.BUNDLE_NAME_INTERNATIONAL) ||
						ali.Apttus_CMConfig__ChargeType__c.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_PCMS_airmail_new) ||
						ali.Apttus_CMConfig__ChargeType__c.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_PCMSNew))
					&& null != ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c && String.isNotBlank(ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c) && ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c.equalsIgnoreCase(APT_Constants.LABEL_LINE_TYPE_BUNDLE)
					&& null != ali.Apttus__AgreementId__r.Operational_Schedule__c && String.isNotBlank(ali.Apttus__AgreementId__r.Operational_Schedule__c) && !ali.APT_Identical_Line__c) {
					
					os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
					if(isInsert) {
						os.APT_International_Postal__c = true;
					} 
					
					if(isDelete) {
						os.APT_International_Postal__c = false;
					}
					/*
					system.debug('*** estimated revenue ***'+ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Estimated_Revenue__c);
					if(ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Estimated_Revenue__c != null) {
						os.APT_IP_Minimum_Revenue_per_annum__c =  ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APT_Estimated_Revenue__c;
					}
					*/
					
					mapOS.put(os.Id, os);
				}
				
				
				//registered post
				if(String.isNotBlank(ali.Apttus_CMConfig__OptionId__c) && null != ali.Apttus_CMConfig__OptionId__r.ProductCode && String.isNotBlank(ali.Apttus_CMConfig__OptionId__r.ProductCode) && ali.Apttus_CMConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.AIRRPI_INTERNATIONAL_PRODUCT) 
					&& String.isNotBlank(ali.Apttus__AgreementId__r.recordType.Name) && ali.Apttus__AgreementId__r.recordType.Name.contains(APT_Constants.MSA)
					&& null != ali.Apttus__AgreementId__r.Operational_Schedule__c && String.isNotBlank(ali.Apttus__AgreementId__r.Operational_Schedule__c) && !ali.APT_Identical_Line__c) {
					
					os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
					if(isInsert) {
						os.APT_IP_Services_Registered_Post__c = true;
					} 
					
					if(isDelete) {
						os.APT_IP_Services_Registered_Post__c = false;
					}
					
					mapOS.put(os.Id, os);
				}
				
				//express courier international
				if(String.isNotBlank(ali.Apttus_CMConfig__OptionId__c) && null != ali.Apttus_CMConfig__OptionId__r.ProductCode && String.isNotBlank(ali.Apttus_CMConfig__OptionId__r.ProductCode) && ali.Apttus_CMConfig__OptionId__r.ProductCode.contains(APT_Constants.ECIPCL_INTERNATIONAL_PRODUCT) 
					&& String.isNotBlank(ali.Apttus__AgreementId__r.recordType.Name) && ali.Apttus__AgreementId__r.recordType.Name.contains(APT_Constants.MSA)
					&& null != ali.Apttus__AgreementId__r.Operational_Schedule__c && String.isNotBlank(ali.Apttus__AgreementId__r.Operational_Schedule__c) && !ali.APT_Identical_Line__c) {
					
					os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
					if(isInsert) { 
						os.APT_IP_Servcs_Exprss_Courier_Internatnal__c = true;
					} 
					
					if(isDelete) {
						os.APT_IP_Servcs_Exprss_Courier_Internatnal__c = false;
					}
					
					mapOS.put(os.Id, os);
				}
				
				//air mail
				if(String.isNotBlank(ali.Apttus_CMConfig__OptionId__c) && null != ali.Apttus_CMConfig__OptionId__r.ProductCode && String.isNotBlank(ali.Apttus_CMConfig__OptionId__r.ProductCode) && ali.Apttus_CMConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.AIRPCL_INTERNATIONAL_PRODUCT) 
					&& String.isNotBlank(ali.Apttus__AgreementId__r.recordType.Name) && ali.Apttus__AgreementId__r.recordType.Name.contains(APT_Constants.MSA)
					&& null != ali.Apttus__AgreementId__r.Operational_Schedule__c && String.isNotBlank(ali.Apttus__AgreementId__r.Operational_Schedule__c) && !ali.APT_Identical_Line__c) {
					
					os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
					if(isInsert) {  
						os.APT_IP_Services_Airmail__c = true;
					} 
					
					if(isDelete) {
						os.APT_IP_Services_Airmail__c = false;
					}
					
					mapOS.put(os.Id, os);
				}
				
					//US-379               
					//International Returns 
				if(String.isNotBlank(ali.Apttus_CMConfig__OptionId__c) && null != ali.Apttus_CMConfig__OptionId__r.ProductCode && String.isNotBlank(ali.Apttus_CMConfig__OptionId__r.ProductCode) && ali.Apttus_CMConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.PRODUCT_CODE_INTERNATIONAL_RETURNS) 
					&& String.isNotBlank(ali.Apttus__AgreementId__r.recordType.Name) && ali.Apttus__AgreementId__r.recordType.Name.contains(APT_Constants.MSA)
					&& null != ali.Apttus__AgreementId__r.Operational_Schedule__c && String.isNotBlank(ali.Apttus__AgreementId__r.Operational_Schedule__c) && !ali.APT_Identical_Line__c) {
					
					os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
					if(isInsert) {  
						os.APT_International_Returns__c = true;
					} 
					
					if(isDelete) {
						os.APT_International_Returns__c = false;
					}
					
					mapOS.put(os.Id, os);
				}
				
				//pack and track
				if(String.isNotBlank(ali.Apttus_CMConfig__OptionId__c) && null != ali.Apttus_CMConfig__OptionId__r.ProductCode && String.isNotBlank(ali.Apttus_CMConfig__OptionId__r.ProductCode) && ali.Apttus_CMConfig__OptionId__r.ProductCode.equalsIgnoreCase(APT_Constants.AIRPTI_INTERNATIONAL_PRODUCT) 
					&& String.isNotBlank(ali.Apttus__AgreementId__r.recordType.Name) && ali.Apttus__AgreementId__r.recordType.Name.contains(APT_Constants.MSA)
					&& null != ali.Apttus__AgreementId__r.Operational_Schedule__c && String.isNotBlank(ali.Apttus__AgreementId__r.Operational_Schedule__c) && !ali.APT_Identical_Line__c) {
					
					os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
					if(isInsert) {  
						os.APT_IP_Services_Pack_and_Track__c = true;
					} 
					
					if(isDelete) {
						os.APT_IP_Services_Pack_and_Track__c = false;
					}
					
					mapOS.put(os.Id, os);
				}
				
				//min collection value
				if(String.isNotBlank(ali.Apttus_CMConfig__OptionId__c) && null != ali.Apttus_CMConfig__OptionId__r.ProductCode && String.isNotBlank(ali.Apttus_CMConfig__OptionId__r.ProductCode) && ali.Apttus_CMConfig__OptionId__r.ProductCode.contains(APT_Constants.PRODUCT_CODE_MIN_COLLECTION_VALUE) 
					&& String.isNotBlank(ali.Apttus__AgreementId__r.recordType.Name) && ali.Apttus__AgreementId__r.recordType.Name.contains(APT_Constants.MSA)
					&& null != ali.Apttus_CMConfig__OptionId__r.Apttus_Config2__ConfigurationType__c && String.isNotBlank(ali.Apttus_CMConfig__OptionId__r.Apttus_Config2__ConfigurationType__c) && ali.Apttus_CMConfig__OptionId__r.Apttus_Config2__ConfigurationType__c.equalsIgnoreCase(APT_Constants.LABEL_LINE_TYPE_OPTION)
					&& null != ali.Apttus__AgreementId__r.Operational_Schedule__c && String.isNotBlank(ali.Apttus__AgreementId__r.Operational_Schedule__c) && !ali.APT_Identical_Line__c) {
					
					os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
					if(isInsert) {  
						os.APT_Parcel_Minimum_Collection_Value__c = ali.List_Price_Text__c;
					} 
					
					if(isDelete) {
						os.APT_Parcel_Minimum_Collection_Value__c = null;
					}
					
					mapOS.put(os.Id, os);
				}

				//31052019- fetch priority product codes from the custom metadata 'Priority_Product_Name__mdt'
				Set <String> priorityProdCodes = new  Set <String>();
				for (Priority_Product_Name__mdt ppName : priorityProdNames) {
					priorityProdCodes.add(ppName.QualifiedApiName);
				}

				//31052019- check the prerequisite for the operational schedule and then set the boolean flags for the priority products
				if(String.isBlank(ali.Apttus_CMConfig__OptionId__c) && String.isNotBlank(ali.Apttus__ProductId__c) && null != ali.Apttus__ProductId__r.ProductCode && String.isNotBlank(ali.Apttus__ProductId__r.ProductCode) && priorityProdCodes.contains(ali.Apttus__ProductId__r.ProductCode)
						&& String.isNotBlank(ali.Apttus__AgreementId__r.recordType.Name) && ali.Apttus__AgreementId__r.recordType.Name.contains(APT_Constants.MSA)
						&& null != ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c && String.isNotBlank(ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c) && ali.Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c.equalsIgnoreCase(APT_Constants.CONFIG_TYPE_STAND_ALONE)
						&& null != ali.Apttus__AgreementId__r.Operational_Schedule__c && String.isNotBlank(ali.Apttus__AgreementId__r.Operational_Schedule__c) && !ali.APT_Identical_Line__c
					) {

					os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
					if(isInsert) {
						if(ali.Apttus__ProductId__r.ProductCode==APT_Constants.PRODUCT_CODE_PriorityProd_RegularSpeedService){
							os.Regular_Speed_Service__c = true;
						}
						else if(ali.Apttus__ProductId__r.ProductCode==APT_Constants.PRODUCT_CODE_PriorityProd_PremExpSpeedService){
							os.Premium_Express_Speed_Service__c = true;
						}
					}

					if(isDelete) {
							os.Regular_Speed_Service__c = false;
							os.Premium_Express_Speed_Service__c = false; 
					}

					mapOS.put(os.Id, os);
				}

					// Populating Startrack fields on DOS
					if(String.isNotBlank(ali.Apttus_CMConfig__OptionId__c) && null != ali.Apttus_CMConfig__OptionId__r.ProductCode && String.isNotBlank(ali.Apttus_CMConfig__OptionId__r.ProductCode)
							&& String.isNotBlank(ali.Apttus__AgreementId__r.recordType.Name) && ali.Apttus__AgreementId__r.recordType.Name.contains(APT_Constants.MSA)
							&& null != ali.Apttus__AgreementId__r.Operational_Schedule__c && String.isNotBlank(ali.Apttus__AgreementId__r.Operational_Schedule__c) && !ali.APT_Identical_Line__c) {
						// Clear existing product tick on OS
						if (isInsert && !steCleared) {
							os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
							os.Fixed_Price_Premium__c = false;
							os.Premium_Priority_Air_Services__c = false;
							os.APT_Express_Road__c = false;
							os.APT_Special_Services_Tailgate__c = false;
							os.APT_Next_Flight__c = false;
							os.APT_Security_Services__c = false;
							mapOS.put(os.Id, os);
							steCleared = true;
						}
						// Minimum Monthly Spend
						if (String.isNotBlank(ali.Apttus__AgreementId__r.Apttus_QPComply__RelatedProposalId__c) && os.APT_Minimum_Monthly_Revenue__c != ali.Apttus__AgreementId__r.Apttus_QPComply__RelatedProposalId__r.APT_Minimum_Monthly_Spend__c) {
							os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
							os.APT_Minimum_Monthly_Revenue__c = ali.Apttus__AgreementId__r.Apttus_QPComply__RelatedProposalId__r.APT_Minimum_Monthly_Spend__c;
							mapOS.put(os.Id, os);
						}
						// Road Express
						if (ali.Apttus_CMConfig__OptionId__r.ProductCode.contains('ExpressRoad')) {
							os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
							if(isInsert) {
								os.APT_Express_Road__c = true;
							}
							if(isDelete) {
								os.APT_Express_Road__c = false;
							}
							mapOS.put(os.Id, os);
						}
						// FPP Premium
						if (ali.Apttus_CMConfig__OptionId__r.ProductCode.contains('PremiumFPP')) {
							os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
							if(isInsert) {
								os.Fixed_Price_Premium__c = true;
							}
							if(isDelete) {
								os.Fixed_Price_Premium__c = false;
							}
							mapOS.put(os.Id, os);
						}
						// PRM Premium
						if (ali.Apttus_CMConfig__OptionId__r.ProductCode.contains('PremiumPRM')) {
							os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
							if(isInsert) {
								os.Premium_Priority_Air_Services__c = true;
							}
							if(isDelete) {
								os.Premium_Priority_Air_Services__c = false;
							}
							mapOS.put(os.Id, os);
						}
						// Special Services/Tailgate
						if (ali.Apttus_CMConfig__OptionId__r.ProductCode.contains('SpecialServices')) {
							os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
							if(isInsert) {
								os.APT_Special_Services_Tailgate__c = true;
							}
							if(isDelete) {
								os.APT_Special_Services_Tailgate__c = false;
							}
							mapOS.put(os.Id, os);
						}
						// Security Express
						if (ali.Apttus_CMConfig__OptionId__r.ProductCode.contains('SecurityExpress')) {
							os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
							if(isInsert) {
								os.APT_Security_Services__c = true;
							}
							if(isDelete) {
								os.APT_Security_Services__c = false;
							}
							mapOS.put(os.Id, os);
						}
						// Next Flight
						if (ali.Apttus_CMConfig__OptionId__r.ProductCode.contains('NextFlight')) {
							os.Id = ali.Apttus__AgreementId__r.Operational_Schedule__c;
							if(isInsert) {
								os.APT_Next_Flight__c = true;
							}
							if(isDelete) {
								os.APT_Next_Flight__c = false;
							}
							mapOS.put(os.Id, os);
						}
					}
			}
			
			if(mapOS != null && mapOS.values().size() > 0) {
				//update mapOS.values();
				ApplicationDatabase.getInstance().dmlUpdate(mapOS.values());
			}
			//process builder to trigger

			// Create New Agreement Product Attribute Value on Agreement Line Item object from Line Item's Attribute Value fields
			if(!mapAgreementLineItemToPav.isEmpty()){
				insert mapAgreementLineItemToPav.values();
				List<Apttus__AgreementLineItem__c> listAli = new List<Apttus__AgreementLineItem__c>();
				// Update Agreement line item to attach associated agreement product attribute object from the map
				for(Apttus__AgreementLineItem__c newALI : mapAgreementLineItemToPav.keySet()){
					newALI.Apttus_CMConfig__AttributeValueId__c = mapAgreementLineItemToPav.get(newALI).id;
					listAli.add(newALI);
				}
				ApplicationDatabase.getInstance().dmlUpdate(listAli);
			}

			if(listAliToUpdate.size() > 0 ) {  
				ApplicationDatabase.getInstance().dmlUpdate(listAliToUpdate);
			}

			
			
			return APT_Constants.SUCCESS_LABEL;
		} catch(system.exception ex) {
			return ex.getMessage();
		}
	}
}