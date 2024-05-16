/**
  * @author       : Rajesh Punjabi
  * @date         : 01/06/2019
  * @description  : Methods used in the MyNetwork SmartForms

--------------------------------------- History --------------------------------------------------
01.06.2019    Rajesh Punjabi(Mav3rik)    Created
26.08.2019    Ronnie Yang(Soda)          Added mail hold/ redirection to the list of categories NA for compensation
18.11.2019    Gunith Devasurendra        REQ1949341: update the name of the field to include liquid, as "Does the article contain wine/alcohol/liquid?"
06/01/2020    Swati Mogadala             REQ1978361: picklist value for product sub-cat changed from "Parcel Post – Secure Accept and Collect" to "Secure Accept and Collect"
07.02.2020    Gunith Devasurendra        REQ2086450: Add PhotoId field
17.02.2020    Gunith Devasurendra        REQ2092604: Remove null when adding Address as Case Comment when Address Line 2 is null
11.06.2020    Swati Mogadala             Added 'Customer Care Specialist' as a Enq-sub-type to be excluded in getTypeAndProductEnqSubTypePickListValues method REQ2100302
08.10.2020    SaiSwetha Pingali          Fix for issues reported with critical update ' Use with sharing for @AuraEnabled Apex Controllers with Implicit Sharing.
22.03.2021    Suman Gunaganti            Updated case comments method to include wine damages instructions
26.03.2021    Madhuri Awasthi            REQ2447384 -Updated case comments method to include wine damages instructions 
09.06.2021    Naveen Rajanna             REQ2525818 -Updated case comments method to include Cust Ref only in case of eparcel damages
16.06.2021    SaiSwetha Pingali			 REQ2866516 -Introduced a new metadata to store product sub category to disable compensation and updated the logic here to utilise the metadata.
18.10.2022    Talib Raza                 REQ2866516 - getAll() only return 255 char, replace it with SOQL 
01.06.2024    Jacob Isaac                REQ3357026 - new question on wine/edamages form
**/

public with sharing class MyNetworkSmartFormsService {
	
	public enum AddressType {Addressee, Sender, Customer}
	
	// Move this method to Utility Class;
	public static Set<Id> getRecordTypeIdsByName(String objName, Set<String> setRecordTypeNames){
		
		Set<Id> recTypeIds;
		// verify if object api name & search string for recordtype is provided
		if(String.isNotBlank(objName) && setRecordTypeNames.size()>0){
			// check session cache
			recTypeIds = (Set<Id>)CacheManager.get('UTILITY_RECORD_TYPE_IDS', objName + String.valueOf(setRecordTypeNames).left(30));
			if(recTypeIds != null) {
				return recTypeIds;
			}
			
			// Iterate over the record types of sObject using schema methods
			recTypeIds = new Set<Id>();
			for(Schema.RecordTypeInfo result : Schema.getGlobalDescribe().get(objName).getDescribe().getRecordTypeInfos()){
				
				if(setRecordTypeNames.contains(result.getName())){
					recTypeIds.add(result.getRecordTypeId());   // add to return set
				}
			}
			
			CacheManager.put('UTILITY_RECORD_TYPE_IDS', objName + String.valueOf(setRecordTypeNames).left(30), recTypeIds);
		}
		return recTypeIds;
	}
	
	@auraEnabled(cacheable=true)
	public static Map<String, List<String>> getProductPickListValues(){
		Schema.DescribeFieldResult fieldResult = Case.ProductCategory__c.getDescribe();
		Schema.sObjectField productCategoryField = fieldResult.getSObjectField();
		
		fieldResult = Case.ProductSubCategory__c.getDescribe();
		Schema.sObjectField productSubCategoryField = fieldResult.getSObjectField();
		
		return AP_FieldDescribeUtil.getDependentPicklistValues (productSubCategoryField, productCategoryField);
	}
	
	@auraEnabled(cacheable=true)
	public static Map<String, List<String>> getProductPickListValuesByNames(){
		
		// Move this to custom metadata.
		Set<String> setIncludeProducts = new Set<String>{'Domestic Letters', 'Domestic Parcels', 'International Letters', 'International Parcels','Money & Insurance','Post Office & Business Hub Services','Travel & ID','Web & Apps'};
			
			Schema.DescribeFieldResult fieldResult = Case.ProductCategory__c.getDescribe();
		Schema.sObjectField productCategoryField = fieldResult.getSObjectField();
		
		fieldResult = Case.ProductSubCategory__c.getDescribe();
		Schema.sObjectField productSubCategoryField = fieldResult.getSObjectField();
		
		Map<String, List<String>> mapProdSubProd = AP_FieldDescribeUtil.getDependentPicklistValues (productSubCategoryField, productCategoryField);
		Map<String, List<String>> finalMapProdSubProd = new Map<String, List<String>>();
		
		for(String prod : setIncludeProducts){
			if(mapProdSubProd.containsKey(prod)){
				finalMapProdSubProd.put(prod,mapProdSubProd.get(prod));
			}
		}
		
		System.debug('mapProdSubProd key values'+finalMapProdSubProd.keyset());
		return finalMapProdSubProd;
	}
	
	// This method returns TypeAndProduct and its dependent Enquiry Sub Type pick list values
	@auraEnabled(cacheable=true)
	public static Map<String, List<String>> getTypeAndProductEnqSubTypePickListValues(){
		Schema.DescribeFieldResult typeFieldResult = Case.Type_and_Product__c.getDescribe();
		Schema.sObjectField typeAndProductField = typeFieldResult.getSObjectField();
		
		Schema.DescribeFieldResult  enqFieldResult = Case.EnquirySubType__c.getDescribe();
		Schema.sObjectField enquirySubTypeField = enqFieldResult.getSObjectField();
		// Discuss and move to metedata.
		Set<String> setIncludeType = new Set<String>{'Investigation', 'Feedback'};
		//'Customer Care Specialist' added in the set to be excluded REQ2100302 
		Set<String> setExcludeEnquirySubType = new Set<String>{'Facility reported damages','Damaged/Missing contents','Missing Item','Redirection Failure','Delivery complaint','Delivery request','Staff Complaint','Staff Compliment','Customer Care Specialist'};
				
				List<Schema.PicklistEntry> ple = typeFieldResult.getPicklistValues();
		List<String> typeAndProductKey = new List<String>();
		Map<String,List<String>> mapOfStr = AP_FieldDescribeUtil.getDependentPicklistValues (enquirySubTypeField, typeAndProductField);
		Map<String,List<String>> finalMap = new Map<String,List<String>>();
		
		/* Exclude EnquirySubType values which is used in all other forms*/
		List<String> listExcludeEnquirySubType = new List<String>();
		listExcludeEnquirySubType.addAll(setExcludeEnquirySubType);
		for(String key : mapOfStr.keyset()){
			Set<String> setOfStr = new Set<String>();
			setOfStr.addAll(mapOfStr.get(key));
			setOfStr.removeAll(listExcludeEnquirySubType);
			List<String> finalEnqSubType = new List<String>();
			finalEnqSubType.addAll(setOfStr);
			finalmap.put(key,finalEnqSubType);
		}
		
		System.debug('End....'+finalMap);
		return finalMap;
	}
	
	@auraEnabled(cacheable=true)
	public static List<Facility_User__c> getListOfNetworksForLoginUser(){
		System.debug('Called from lwc...');
		List<Facility_User__c> lstUserFacilities = [SELECT Network__r.Name,Network__c, Network__r.Post_Code__c 
													FROM Facility_User__c 
													WHERE User__c =:userinfo.getUserId()]; 
		System.debug('List of facility user...'+lstUserFacilities);
		return lstUserFacilities;
	}
	
	@auraEnabled(cacheable=true)
	public static List<Network__c > getListOfNetworksByRecordTypes(){
		System.debug('Called from lwc...');
		/*** Record Types for Network to filter the List of Networks ***/
		Set<String> sNetworkRecordTypeNames = new Set<String> {'Business Hub','Delivery','Retail'};
			
			List<Network__c > lstNetwork = [SELECT Id, Name 
											FROM Network__c 
											WHERE RecordTypeId IN:getRecordTypeIdsByName(String.valueOf(Network__c.getsObjectType()), sNetworkRecordTypeNames)]; 
		System.debug('List of facilities...'+lstNetwork);
		return lstNetwork;
	}
	
	@auraEnabled(cacheable=true)
	public static Map<String, List<String>> getSubCatValuesToDisableCompensation(){
		Map<String,List<String>> mapOfValuesToDisableCompensation = new Map<String,List<String>>();
		
		for (MyNetworkProdSubCategory__mdt mcs : [SELECT Label, Product_Sub_Category__c FROM MyNetworkProdSubCategory__mdt])
		{
			mapOfValuesToDisableCompensation.put(mcs.Label,new List<String>(mcs.Product_Sub_Category__c.split(','))); 
		}
		 // Discuss and move to metadata.
		/* REQ2866516 - Moved this to custom metadata MyNetworkProdSubCategory__mdt
		mapOfValuesToDisableCompensation.put('Domestic Parcels',new List<String> {'Cash on Delivery', 'eParcel- Express', 'eParcel- Regular','StarTrack (Next Flight Premium & Express)','StarTrack Courier','Secure Accept and Collect', 'Mail hold', 'Mail redirection'});
		mapOfValuesToDisableCompensation.put('Domestic Letters',new List<String> {'Cash on Delivery', 'Unaddressed Mail', 'Mail hold', 'Mail redirection'});
		mapOfValuesToDisableCompensation.put('International Letters',new List<String> {'Airmail under 2kg', 'Economy Air under 500g', 'International Courier', 'International Express', 'Pack and Track International', 'Registered Post International', 'ECI', 'ECI Platinum', 'Express Post International', 'Mail redirection'});
		mapOfValuesToDisableCompensation.put('Post Office & Business Hub Services',new List<String> {'General merchandise', 'Mail Pick up', 'Philatelic (stamps)',  'PO Boxes & Bags', 'Mobile products',  'Stationery and packaging', 'Passport & ID Photos', 'Post office locator', 'Mail hold', 'Mail redirection'});
		mapOfValuesToDisableCompensation.put('International Parcels',new List<String> {'Airmail over 2kg','Airmail under 2kg','ECI','ECI Platinum','Economy Air under 2kg','Economy Sea over 2kg','Express Post International','Global Logistics','International Courier','International Express','International Standard','Pack and Track International','Registered Post International','Sea Mail','StarTrack International'});
 		*/
		return mapOfValuesToDisableCompensation;
	}
	
	@auraEnabled(cacheable=true)
	public static List<String> getTypeOfDamageValuesToDisableCompensation(){
		// Discuss and move to metedata.
		List<String> listOfTypeOfDamages = new List<String> {'Contents Missing - evidence of tampering','Contents Missing - no evidence of tampering'};

			return listOfTypeOfDamages;
	}
	
	//.. eParcel
	public String geteParcelDamageDetails(MyNetworkSmartFormsWrapper oSmartFormWrapper){
		String ParcelDamageDetails = '';
		System.debug('  Damage Details - Case Comments - Start');
		ParcelDamageDetails += SSSWConstants.NEW_LINE;
		ParcelDamageDetails += SSSWConstants.NEW_LINE + 'Details of product damage - ' + oSmartFormWrapper.damageDetails;
		ParcelDamageDetails += SSSWConstants.NEW_LINE + 'Location of damage within facility - ' + oSmartFormWrapper.damageLocation;
		ParcelDamageDetails += SSSWConstants.NEW_LINE + 'How the damage occurred (if known) - ' + oSmartFormWrapper.howDamageOccured;
		
		// Condition has to be added for other values if required.
		if(oSmartFormWrapper.howDamageOccured == 'Other'){
			ParcelDamageDetails += SSSWConstants.NEW_LINE + 'Others: Please specify - ' + oSmartFormWrapper.howDamageOccuredOptionalOther;
		}
		
		ParcelDamageDetails += SSSWConstants.NEW_LINE + 'Is this part of a consignment? - ' + oSmartFormWrapper.isPartOfConsignment;
		ParcelDamageDetails += SSSWConstants.NEW_LINE + 'Total articles in consignment - ' + oSmartFormWrapper.totalArticlesInConsignment;
		ParcelDamageDetails += SSSWConstants.NEW_LINE + 'Does the article contain wine/alcohol/liquid?' + SSSWConstants.HYPHEN_SPACED + oSmartFormWrapper.doesContainWine;

		if(oSmartFormWrapper.doesContainWine == 'yes'){
			ParcelDamageDetails += SSSWConstants.NEW_LINE + 'Total bottles originally sent - ' + oSmartFormWrapper.totalBottlesInCarton;
			ParcelDamageDetails += SSSWConstants.NEW_LINE + 'Total bottles damaged/broken - ' + oSmartFormWrapper.totalBottlesDamaged;
			ParcelDamageDetails += SSSWConstants.NEW_LINE + 'Number of caps damaged - ' + oSmartFormWrapper.noOfCapsDamaged;
			ParcelDamageDetails += SSSWConstants.NEW_LINE + 'Number of labels damaged - ' + oSmartFormWrapper.noOfLabelsDamaged;
			ParcelDamageDetails += SSSWConstants.NEW_LINE + 'Carton adequate? (Must be 3mm minimum) - ' + oSmartFormWrapper.isCartonAdequate;
			if(oSmartFormWrapper.isCartonAdequate=='no'){
				ParcelDamageDetails += SSSWConstants.NEW_LINE + 'Provide details - ' + oSmartFormWrapper.cartonInadequecyDetails;
			}
			ParcelDamageDetails += SSSWConstants.NEW_LINE + 'Inserts or dividers adequate? (Must be 3mm minimum) - ' + oSmartFormWrapper.isDividerAdequate;
			if(oSmartFormWrapper.isDividerAdequate=='no'){
				ParcelDamageDetails += SSSWConstants.NEW_LINE + 'Provide details - ' + oSmartFormWrapper.dividerInadequecyDetails;
			}
			if(oSmartFormWrapper.actionTaken != null){
				ParcelDamageDetails += SSSWConstants.NEW_LINE + 'Damage instructions - ' + oSmartFormWrapper.damageInstructions;
				ParcelDamageDetails += SSSWConstants.NEW_LINE + 'Action Taken - ' + oSmartFormWrapper.actionTaken;
				ParcelDamageDetails += SSSWConstants.NEW_LINE + 'Additional Information - ' + oSmartFormWrapper.additionalInformation;
			}

		 } if(oSmartFormWrapper.doesContainWine == 'no'){
			ParcelDamageDetails += SSSWConstants.NEW_LINE + 'Total number of items in the parcel  - ' + oSmartFormWrapper.totalItemInParcel;
			ParcelDamageDetails += SSSWConstants.NEW_LINE + 'Have all the items in the parcel sustained damage?' + SSSWConstants.HYPHEN_SPACED + oSmartFormWrapper.sustainedDamage;
			if(oSmartFormWrapper.sustainedDamage == 'no'){
				ParcelDamageDetails += SSSWConstants.NEW_LINE + 'Please list the items that have not sustained damage -' + oSmartFormWrapper.sustainedDamageDetails;
			}
			ParcelDamageDetails += SSSWConstants.NEW_LINE + 'Was the article sufficiently packaged? ' + SSSWConstants.HYPHEN_SPACED + oSmartFormWrapper.sufficientPackage;
			if(oSmartFormWrapper.sufficientPackage == 'no'){
				ParcelDamageDetails += SSSWConstants.NEW_LINE + 'Provide details - ' + oSmartFormWrapper.sufficientPackageDetails;
			}
		}
		ParcelDamageDetails += SSSWConstants.NEW_LINE;
		
		System.debug(' Case Comments - ' + ParcelDamageDetails);
		return ParcelDamageDetails;
	}
	
	// Damaged article
	public String getDamageArticleDetails(MyNetworkSmartFormsWrapper oSmartFormWrapper){
		String sDamageArticle = '';
		
		System.debug('  Damage Article - Case Comments - Start');
		sDamageArticle += SSSWConstants.NEW_LINE;
		sDamageArticle += SSSWConstants.NEW_LINE + 'Damaged article or missing contents? - ' + oSmartFormWrapper.damagedOrMissing;
		sDamageArticle += SSSWConstants.NEW_LINE + 'Additional comments/damage report - ' + oSmartFormWrapper.comments;
		
		sDamageArticle += SSSWConstants.NEW_LINE + 'Type of damage - ' + oSmartFormWrapper.typeOfDamage;
		sDamageArticle += SSSWConstants.NEW_LINE + 'Description of contents - ' + oSmartFormWrapper.contents;
		sDamageArticle += SSSWConstants.NEW_LINE + 'Value of contents - ' + oSmartFormWrapper.valueOfContents;
		sDamageArticle += SSSWConstants.NEW_LINE + 'In your opinion, was the article adequately packaged? - ' + oSmartFormWrapper.adequatelyPackaged;
		sDamageArticle += SSSWConstants.NEW_LINE + 'Is the article on hand? - ' + oSmartFormWrapper.isarticleonhand;
		if(!String.isBlank(oSmartFormWrapper.compensationBeingPaid)){
			sDamageArticle += SSSWConstants.NEW_LINE + 'Are you paying compensation to the customer? - ' + oSmartFormWrapper.compensationBeingPaid;
		}
		if(oSmartFormWrapper.compensationBeingPaid == 'yes'){
			sDamageArticle += SSSWConstants.NEW_LINE + 'Amount compensated for contents ($) - ' + oSmartFormWrapper.compensationAmount;
			sDamageArticle += SSSWConstants.NEW_LINE + 'Amount refunded for postage ($) - ' + oSmartFormWrapper.postagevalue;
		}
		
		sDamageArticle += SSSWConstants.NEW_LINE;
		
		return sDamageArticle;
	}
	
	// Lost article
	public String getLostArticleDetails(MyNetworkSmartFormsWrapper oSmartFormWrapper){
		String sLostArticle = '';
		
		System.debug('  Lost Article - Case Comments - Start');
		sLostArticle += SSSWConstants.NEW_LINE;
		sLostArticle += SSSWConstants.NEW_LINE + 'Additional comments - ' + oSmartFormWrapper.comments;
		
		sLostArticle += SSSWConstants.NEW_LINE + 'Description of contents - ' + oSmartFormWrapper.contents;
		sLostArticle += SSSWConstants.NEW_LINE + 'Value of contents - ' + oSmartFormWrapper.valueOfContents;
		if(!String.isBlank(oSmartFormWrapper.compensationBeingPaid)){
			sLostArticle += SSSWConstants.NEW_LINE + 'Are you paying compensation to the customer? - ' + oSmartFormWrapper.compensationBeingPaid;
		}   
		if(oSmartFormWrapper.compensationBeingPaid == 'yes'){
			sLostArticle += SSSWConstants.NEW_LINE + 'Amount compensated for contents ($) - ' + oSmartFormWrapper.compensationAmount;
			sLostArticle += SSSWConstants.NEW_LINE + 'Amount refunded for postage ($) - ' + oSmartFormWrapper.postagevalue;
		}
		
		sLostArticle += SSSWConstants.NEW_LINE;
		
		return sLostArticle;
	}
	
	// Mail redirection/hold
	public String getMailRedirectHoldDetails(MyNetworkSmartFormsWrapper oSmartFormWrapper){
		String sMailRedirectHoldDetails = '';

		System.debug('  Mail Redirection/hold - Case Comments - Start');
		sMailRedirectHoldDetails += SSSWConstants.NEW_LINE;

		sMailRedirectHoldDetails += 'Privacy check completed in store? ' + oSmartFormWrapper.hasPhotoId;

		sMailRedirectHoldDetails += SSSWConstants.NEW_LINE;

		if(oSmartFormWrapper.productSubCategory == 'Mail redirection'){
			sMailRedirectHoldDetails += SSSWConstants.NEW_LINE + 'Notes to assist with enquiry - ' + oSmartFormWrapper.redirectComments;
		}
		else if (oSmartFormWrapper.productSubCategory == 'Mail hold'){
			sMailRedirectHoldDetails += SSSWConstants.NEW_LINE + 'Notes to assist with enquiry - ' + oSmartFormWrapper.mailholdComments;
		}
		sMailRedirectHoldDetails += SSSWConstants.NEW_LINE;
		
		return sMailRedirectHoldDetails;
	}
	
	// Delivery concerns
	public String getDeliveryConcernDetails(MyNetworkSmartFormsWrapper oSmartFormWrapper){
		String sDeliveryConcernsDetails = '';
		
		System.debug('Delivery Concerns - Case Comments - Start');
		sDeliveryConcernsDetails += SSSWConstants.NEW_LINE;
		sDeliveryConcernsDetails += SSSWConstants.NEW_LINE + 'What is the enquiry about - ' + oSmartFormWrapper.comments;
		sDeliveryConcernsDetails += SSSWConstants.NEW_LINE;
		
		return sDeliveryConcernsDetails;
	}
	
	// Staff related feedback
	public String getStaffFeedbackDetails(MyNetworkSmartFormsWrapper oSmartFormWrapper){
		String sStaffRelated = '';
		
		System.debug('Staff related Feedback - Case Comments - Start');
		sStaffRelated += SSSWConstants.NEW_LINE;
		/*
		sStaffRelated += SSSWConstants.NEW_LINE + 'Customer Address - ' + oSmartFormWrapper.customerAddress.addressLine1;
		if(!String.isBlank(oSmartFormWrapper.customerAddress.addressLine2)){
			sStaffRelated += SSSWConstants.NEW_LINE + oSmartFormWrapper.customerAddress.addressLine2;
		}
		sStaffRelated += SSSWConstants.NEW_LINE + oSmartFormWrapper.customerAddress.city;
		sStaffRelated += SSSWConstants.WHITE_SPACE + oSmartFormWrapper.customerAddress.state;
		sStaffRelated += SSSWConstants.WHITE_SPACE + oSmartFormWrapper.customerAddress.postcode;
		sStaffRelated += SSSWConstants.WHITE_SPACE + oSmartFormWrapper.customerAddress.countrycode;
		sStaffRelated += SSSWConstants.NEW_LINE;
		sStaffRelated += SSSWConstants.NEW_LINE + '--------------------------------------------';
		sStaffRelated += SSSWConstants.NEW_LINE;
		*/
		sStaffRelated += SSSWConstants.NEW_LINE + 'What is the enquiry about - ' + oSmartFormWrapper.comments;
		sStaffRelated += SSSWConstants.NEW_LINE;
		
		return sStaffRelated;
	}
	
	// Something else
	public String getSomethingElseDetails(MyNetworkSmartFormsWrapper oSmartFormWrapper){
		String sSomethingElse = '';
		
		System.debug('Something Else - Case Comments - Start');
		sSomethingElse += SSSWConstants.NEW_LINE;
		sSomethingElse += SSSWConstants.NEW_LINE + 'What is the enquiry about - ' + oSmartFormWrapper.comments;
		sSomethingElse += SSSWConstants.NEW_LINE;

		if(!String.isBlank(oSmartFormWrapper.compensationBeingPaid)){
			sSomethingElse += SSSWConstants.NEW_LINE + 'Are you paying compensation to the customer? - ' + oSmartFormWrapper.compensationBeingPaid;
		}
		if(oSmartFormWrapper.compensationBeingPaid == 'yes'){
			sSomethingElse += SSSWConstants.NEW_LINE + 'Amount compensated for contents ($) - ' + oSmartFormWrapper.compensationAmount;
			sSomethingElse += SSSWConstants.NEW_LINE + 'Amount refunded for postage ($) - ' + oSmartFormWrapper.postagevalue;
		}
		return sSomethingElse;
	}
	
	//..
	public String getAddresseeDetailsAsComments(MyNetworkSmartFormsWrapper oSmartFormWrapper){
		String AddresseeDetails = '';
		System.debug('Addressee Details - Case Comments - Start');

		AddresseeDetails += SSSWConstants.NEW_LINE;
		AddresseeDetails += SSSWConstants.NEW_LINE + 'Addressee Name - ' + oSmartFormWrapper.addresseeName;
		AddresseeDetails += SSSWConstants.NEW_LINE + 'Addressee Email - ' + oSmartFormWrapper.addresseeEmail;
		AddresseeDetails += SSSWConstants.NEW_LINE + 'Addressee Address - ' + oSmartFormWrapper.addresseeAddress.addressLine1;
		if(!String.isBlank(oSmartFormWrapper.addresseeAddress.addressLine2)){
			AddresseeDetails += SSSWConstants.NEW_LINE + oSmartFormWrapper.addresseeAddress.addressLine2;
		}
		AddresseeDetails += SSSWConstants.NEW_LINE + oSmartFormWrapper.addresseeAddress.city;
		AddresseeDetails += SSSWConstants.WHITE_SPACE + oSmartFormWrapper.addresseeAddress.state;
		AddresseeDetails += SSSWConstants.WHITE_SPACE + oSmartFormWrapper.addresseeAddress.postcode;
	   // AddresseeDetails += SSSWConstants.WHITE_SPACE + oSmartFormWrapper.addresseeAddress.countrycode;
		AddresseeDetails += SSSWConstants.NEW_LINE;

		System.debug('Addressee Details - ' + AddresseeDetails);
		return AddresseeDetails;
	}
	
	//..
	public String getSenderDetailsAsComments(MyNetworkSmartFormsWrapper oSmartFormWrapper){
		String sSenderDetails = '';
		System.debug('Sender Details - Case Comments - Start');

		sSenderDetails += SSSWConstants.NEW_LINE + 'Sender Name - ' + oSmartFormWrapper.senderName;
		sSenderDetails += SSSWConstants.NEW_LINE + 'Sender Company - ' + oSmartFormWrapper.senderCompany;
		sSenderDetails += SSSWConstants.NEW_LINE + 'Sender Email - ' + oSmartFormWrapper.senderEmail;
		sSenderDetails += SSSWConstants.NEW_LINE + 'Sender Address - ' + oSmartFormWrapper.senderAddress.addressLine1;
		if(!String.isBlank(oSmartFormWrapper.senderAddress.addressLine2)){
			sSenderDetails += SSSWConstants.NEW_LINE + oSmartFormWrapper.senderAddress.addressLine2;
		}
		sSenderDetails += SSSWConstants.NEW_LINE + oSmartFormWrapper.senderAddress.city;
		sSenderDetails += SSSWConstants.WHITE_SPACE + oSmartFormWrapper.senderAddress.state;
		sSenderDetails += SSSWConstants.WHITE_SPACE + oSmartFormWrapper.senderAddress.postcode;
	   // sSenderDetails += SSSWConstants.WHITE_SPACE + oSmartFormWrapper.senderAddress.countrycode;
		sSenderDetails += SSSWConstants.NEW_LINE;
		
		System.debug('Sender Details - ' + sSenderDetails);
		return sSenderDetails;
	}
	
	public String getAddressAsString(MyNetworkSmartFormsWrapper oSmartFormWrapper, MyNetworkSmartFormsService.AddressType eAddressType){
		String sAddress = '';
		if(eAddressType == AddressType.Addressee){
			sAddress = oSmartFormWrapper.addresseeAddress.addressLine1 + SSSWConstants.WHITE_SPACE;
			if(!String.isBlank(oSmartFormWrapper.addresseeAddress.addressLine2)){
				sAddress += oSmartFormWrapper.addresseeAddress.addressLine2 + SSSWConstants.WHITE_SPACE;
			}
			sAddress += oSmartFormWrapper.addresseeAddress.city + SSSWConstants.WHITE_SPACE + oSmartFormWrapper.addresseeAddress.state + SSSWConstants.WHITE_SPACE + oSmartFormWrapper.addresseeAddress.postcode;
		}
		else if(eAddressType == AddressType.Sender){
			sAddress = oSmartFormWrapper.senderAddress.addressLine1 + SSSWConstants.WHITE_SPACE;
			if(!String.isBlank(oSmartFormWrapper.senderAddress.addressLine2)){
				sAddress += oSmartFormWrapper.senderAddress.addressLine2 + SSSWConstants.WHITE_SPACE;
			}
			sAddress += oSmartFormWrapper.senderAddress.city + SSSWConstants.WHITE_SPACE + oSmartFormWrapper.senderAddress.state + SSSWConstants.WHITE_SPACE + oSmartFormWrapper.senderAddress.postcode;
		}
		else if(eAddressType == AddressType.Customer){
			sAddress = oSmartFormWrapper.customerAddress.addressLine1 + SSSWConstants.WHITE_SPACE;
			if(!String.isBlank(oSmartFormWrapper.customerAddress.addressLine2)){
				sAddress += oSmartFormWrapper.customerAddress.addressLine2 + SSSWConstants.WHITE_SPACE;
			}
			sAddress += oSmartFormWrapper.customerAddress.city + SSSWConstants.WHITE_SPACE + oSmartFormWrapper.customerAddress.state + SSSWConstants.WHITE_SPACE + oSmartFormWrapper.customerAddress.postcode;
		}
		
		return sAddress;
	}
	
	public void createCaseComments(MyNetworkSmartFormsWrapper oSmartFormWrapper, Case oCase){
		MyNetworkCaseSharing  CaseService = new MyNetworkCaseSharing();
		CaseComment oCaseComment = new CaseComment();
		String sBodyComments = '';
		
		if(oSmartFormWrapper.formId == 'eParcel'){
			//REQ2525818
			if(!String.isBlank(oSmartFormWrapper.custRefID)){
				sBodyComments += 'Sender Reference - ' + oSmartFormWrapper.custRefID ;
			}
			sBodyComments += getSenderDetailsAsComments(oSmartFormWrapper);
			sBodyComments += getAddresseeDetailsAsComments(oSmartFormWrapper);
			sBodyComments += geteParcelDamageDetails(oSmartFormWrapper);            
		}
		else if(oSmartFormWrapper.formId == 'damagedArticle'){
			sBodyComments = getDamageArticleDetails(oSmartFormWrapper);
			sBodyComments += getCustomerAsString(oSmartFormWrapper);
		}
		else if(oSmartFormWrapper.formId == 'lostArticle'){
			sBodyComments = getLostArticleDetails(oSmartFormWrapper);
			sBodyComments += getCustomerAsString(oSmartFormWrapper);
		}
		else if(oSmartFormWrapper.formId == 'mailRedirectHold'){
			sBodyComments = getmailRedirectHoldDetails(oSmartFormWrapper);
			sBodyComments += getCustomerAsString(oSmartFormWrapper);
		} 
		else if(oSmartFormWrapper.formId == 'deliveryConcern'){
			sBodyComments = getDeliveryConcernDetails(oSmartFormWrapper);
			sBodyComments += getCustomerAsString(oSmartFormWrapper);
		} 
		else if(oSmartFormWrapper.formId == 'staffFeedback'){
			sBodyComments = getStaffFeedbackDetails(oSmartFormWrapper);
			sBodyComments += getCustomerAsString(oSmartFormWrapper);
		} 
		else if(oSmartFormWrapper.formId == 'somethingElse'){
			sBodyComments = getSomethingElseDetails(oSmartFormWrapper);
			sBodyComments += getCustomerAsString(oSmartFormWrapper);
		}         
		
		// Facility name from the Facility User dropdown on the form
		if(!String.isBlank(oSmartFormWrapper.facilityName)){
			sBodyComments += SSSWConstants.NEW_LINE;
			sBodyComments += 'Facility: '+ oSmartFormWrapper.facilityName;
			sBodyComments += SSSWConstants.NEW_LINE;
		}
		System.debug('Case Comments before insert - '+sBodyComments);
		oCaseComment.CommentBody = sBodyComments;
		oCaseComment.ParentId = oCase.Id;
		//insert oCaseComment;
		CaseService.createCaseComments(oCaseComment);
	}  
	
	//..
	public String getCustomerAsString(MyNetworkSmartFormsWrapper oSmartFormWrapper){
		String sCustomerDetails = '';
		
		System.debug('Sender Details - Case Comments - Start');

		sCustomerDetails += SSSWConstants.NEW_LINE;
		sCustomerDetails += SSSWConstants.NEW_LINE + 'First Name - ' + oSmartFormWrapper.FirstName;
		sCustomerDetails += SSSWConstants.NEW_LINE + 'Last Name - ' + oSmartFormWrapper.LastName;
		if(!String.isBlank(oSmartFormWrapper.MobilePhone)){
			sCustomerDetails += SSSWConstants.NEW_LINE + 'Contact Number - ' + oSmartFormWrapper.MobilePhone;
		}
		if(!String.isBlank(oSmartFormWrapper.Email)){
			sCustomerDetails += SSSWConstants.NEW_LINE + 'Email - ' + oSmartFormWrapper.Email;
		}
		sCustomerDetails += SSSWConstants.NEW_LINE + 'Customer Address: - ' + oSmartFormWrapper.customerAddress.addressLine1 + SSSWConstants.WHITE_SPACE;
		if(!String.isBlank(oSmartFormWrapper.customerAddress.addressLine2)){
			sCustomerDetails += oSmartFormWrapper.customerAddress.addressLine2 + SSSWConstants.WHITE_SPACE;
		}
		sCustomerDetails += oSmartFormWrapper.customerAddress.city + SSSWConstants.WHITE_SPACE + oSmartFormWrapper.customerAddress.state + SSSWConstants.WHITE_SPACE+ oSmartFormWrapper.customerAddress.postcode;
		sCustomerDetails += SSSWConstants.NEW_LINE;

		System.debug('Customer Comments');
		return sCustomerDetails;
	}
	
	//..
	 /* Moved this method to inner class MyNetworkCaseSharing
	public void createCompensation(MyNetworkSmartFormsWrapper oSmartFormWrapper, Case oCase){
		System.debug('Adding Compensation Record');
		Compensation__c oComp = new Compensation__c();
		oComp.recordtypeId = Schema.SObjectType.Compensation__c.getRecordTypeInfosByDeveloperName().get(SSSWConstants.COMPENSATION_RT).getRecordTypeId();
		oComp.Case__c = oCase.Id;
		oComp.Contact__c = oCase.ContactId;
		if(!String.isBlank(oSmartFormWrapper.postagevalue)){
			oComp.Service_Value__c = Decimal.valueOf(oSmartFormWrapper.postagevalue);
		}
		if(!String.isBlank(oSmartFormWrapper.compensationAmount)){
			oComp.Compensation_Amount__c = Decimal.valueOf(oSmartFormWrapper.compensationAmount); 
		}
		oComp.Status__c = 'Retail Compensation Paid';
		oComp.Legal_Entity_Name__c = oCase.AccountId;
		insert oComp;
	} */
	
	//.. 
	public Id getArticleId(String articleNumber){
		System.debug('Get articleId'+ articleNumber);
		return [SELECT Id FROM Article__c WHERE ArticleID__c =:articleNumber LIMIT 1].Id;
	}
	
	/**
* @Description: Convert string to Single Quotes for SQL
*/
	public String toSOQL(Object value) {
		return '\'' + String.valueOf(value) + '\'';
	}
	
	/**
* @Description: Convert string to Single Quotes for SQL
*/
	public String toSOQLwithoutQuotes(Object value) {
		return String.valueOf(value);
	}

	/**Inner class created to open up sharing access when creating cases 
	 * CaseComments and CreateCompensation requires access to case.
	 * Added by spingali - Fix for issues reported with critical update ' Use with sharing for @AuraEnabled Apex Controllers with Implicit Sharing '
	*/
	public without sharing class MyNetworkCaseSharing {
	
		//Query case detail to associate casecomments and compensation.
		 public case getCasedetail(String value) {
			 Case newCase = Database.query(value); 
			 return newCase;
		 }
	 
		 public void createCaseComments(CaseComment oCase){
			 insert oCase;
		 }  
	 
		 public void createCompensation(MyNetworkSmartFormsWrapper oSmartFormWrapper, Case oCase){
			 System.debug('Adding Compensation Record');
			 Compensation__c oComp = new Compensation__c();
			 oComp.recordtypeId = Schema.SObjectType.Compensation__c.getRecordTypeInfosByDeveloperName().get(SSSWConstants.COMPENSATION_RT).getRecordTypeId();
			 oComp.Case__c = oCase.Id;
			 oComp.Contact__c = oCase.ContactId;
			 if(!String.isBlank(oSmartFormWrapper.postagevalue)){
				 oComp.Service_Value__c = Decimal.valueOf(oSmartFormWrapper.postagevalue);
			 }
			 if(!String.isBlank(oSmartFormWrapper.compensationAmount)){
				 oComp.Compensation_Amount__c = Decimal.valueOf(oSmartFormWrapper.compensationAmount); 
			 }
			 oComp.Status__c = 'Retail Compensation Paid';
			 oComp.Legal_Entity_Name__c = oCase.AccountId;
			 insert oComp;
		 }
			 /**
	*Description: Creates network response record for case record
	 */
		public void createNetworkResponseforWineDamageArticle( String caseId, string actionTaken, string additionalInformation, String facilityId){

			Network_Response__c networkResponse = new Network_Response__c();
			networkResponse.RelatedCase__c = caseId;
			networkResponse.Network_Response__c = actionTaken;
			networkResponse.Network_Comments__c = additionalInformation;
			networkResponse.isClosedByNetwork__c = true;
			networkResponse.CaseAction__c = 'Closed';
			networkResponse.SuppressCaseAutomation__c = true;
			networkResponse.Acting_Network__c = facilityId;

			insert networkResponse;
		}
	 
	 }
		 /**
* @Description: get wine damage instructions for organisation
*/
	@auraEnabled(cacheable=true)
	public static Billing_Account__c getDamageInstructions(String billingAccountId){
		if(!String.isBlank(billingAccountId)){
			Billing_Account__c bc  = [SELECT Id, Organisation__r.Wine_Damage_Instruction__c,Organisation__r.eParcelDamagesDelegate__c
									FROM Billing_Account__c
									WHERE id = :billingAccountId];
									
			return bc;

		}
		return null;
	}

}