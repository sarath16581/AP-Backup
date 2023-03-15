/**
  * @author       : dion.gunn@auspost.com.au
  * @date         : 12/01/2017
  * @description  : A rewrite of the SSSWRoutingController class to support the new SSSWSorting page.
--------------------------------------- History --------------------------------------------------

* 5-Jul-2018    disha.kariya@auspost.com.au Updated Controller to accommodate NPS and Auto Escalation
* 28-Sep-2020   naseer.abbasi@auspost.com.au    Updated to include new flag i.e isStrategic    
* 17-Nov-2020 - Ranjeewa Silva - Updated to include new field on SSSW Rule - 'SocialPostTags__c'
* 07-03-2023	george.nguyen8@auspost.com.au	Added CustomerQueueType__c to the validation rule that checks for existing matching rule with the same attributes. 
**/
global with sharing class SSSWRoutingController {
	public static String MULTI_SELECT_DELIM = ';';
	public ApexPages.StandardController controller { get; set; }
	public Case proxyCase {get;set;}
	public Boolean showExisting{get;set;}
	public List<SSSWRouting__c> existingRoutings { get; set; }
	public SSSWRouting__c selRouting { get; set; }
	public String caseRecordTypeId { get; set; }
	public string[] origin { get; set; }
	public string[] productCategory { get; set; }
	public string[] productSubCategory { get; set; }
	public string[] enquiryType { get; set; }
	public string[] enquirySubType { get; set; }
	public string[] customerQueueType { get; set; }
	public string[] status { get; set; }
	public string owner { get; set; }
	public id queueID { get; set; }
	public id templateID { get; set; }
	public String RecordType { get; set; }
	public List<SelectOption> originOptions { get; set; }
	public List<SelectOption> productCategoryOptions { get; set; }
	public List<SelectOption> productSubCategoryOptions { get; set; }
	public List<SelectOption> enquiryTypeOptions { get; set; }
	public List<SelectOption> enquirySubTypeOptions { get; set; }
	public List<SelectOption> customerQueueTypeOptions { get; set; }
	public List<SelectOption> statusOptions { get; set; }
	public string sequenceNo { get; set; }
	public string newRoute { get; set; }


	public SSSWRoutingController(ApexPages.StandardController controller) {
		this.controller = controller;
		newRoute = System.currentPageReference().getParameters().get('newRoute');
		productCategoryOptions = getPicklistValues('Case', 'ProductCategory__c');
		productSubCategoryOptions = getPicklistValues('Case', 'ProductSubCategory__c');
		originOptions = getPicklistValues('Case', 'Origin');
		customerQueueTypeOptions = getPicklistValues('Case', 'CustomerQueueType__c');
		enquiryTypeOptions = getPicklistValues('Case', 'Type');
		enquirySubTypeOptions = getPicklistValues('Case', 'EnquirySubType__c');
		statusOptions = getPicklistValues('Case', 'Status');
		caseRecordTypeId = [select Id from RecordType where SObjectType = 'Case' and DeveloperName = 'SSSWGeneralEnquiry' limit 1].Id;


		if (controller.getRecord().id != null) {
			selRouting = [
					SELECT  IsActive__c, Origin__c, ProductCategory__c, ProductSubCategory__c, CaseType__c, EnquirySubType__c, Network__c, DefaultCaseDetails__c,
							AutoEscalate__c, ExcludeFromNPS__c, CustomerQueueType__c, Queue_ID__c, CaseRecordTypeId__c, High_Level_Complaint_Flag__c,
							Customer_Recovery_Flag__c, Match_Rules_On__c, Sequence__c, Status__c, IsNew__c, RecordType.Name, NPS_criteria__c, Description__c,
							LastModifiedDate, LastModifiedBy.FirstName, LastModifiedBy.LastName, IsStrategic__c, SocialPostTags__c, HasExtraCover__c,
							PreferredAgentExpiry__c
					from SSSWRouting__c
					where id = :controller.getRecord().id
					limit 1
			];
			/*
			productCategory = selRouting.ProductCategory__c;
			productSubCategory = selRouting.ProductSubCategory__c;
			enquiryType = selRouting.CaseType__c;
			enquirySubType = selRouting.EnquirySubType__c;
			customerQueueType = selRouting.CustomerQueueType__c;
			origin = selRouting.Origin__c;
			queueID = selRouting.Queue_ID__c;
			status = selRouting.Status__c; */
			productCategory = splitMultiSelectValue(selRouting.ProductCategory__c);
			productSubCategory = splitMultiSelectValue(selRouting.ProductSubCategory__c);
			enquiryType = splitMultiSelectValue(selRouting.CaseType__c);
			enquirySubType = splitMultiSelectValue(selRouting.EnquirySubType__c);
			customerQueueType = splitMultiSelectValue(selRouting.CustomerQueueType__c);
			origin = splitMultiSelectValue(selRouting.Origin__c);
			queueID = selRouting.Queue_ID__c;
			status = splitMultiSelectValue(selRouting.Status__c);
			RecordType = selRouting.RecordType.Name != null ? selRouting.RecordType.Name : System.currentPageReference().getParameters().get('recType');
			sequenceNo = selRouting.Sequence__c != null ? String.valueOf(selRouting.Sequence__c) : System.currentPageReference().getParameters().get('newSeqFrom');
		} else {
			selRouting = new SSSWRouting__c();
			RecordType = System.currentPageReference().getParameters().get('recType');
			if(RecordType=='' || RecordType==null){
				Id recId = System.currentPageReference().getParameters().get('RecordType');
				RecordType = Schema.SObjectType.SSSWRouting__c.getRecordTypeInfosById().get(recId).getname();
			}
			Integer count = database.countQuery('select Count() from SSSWRouting__c where recordtype.name = \'' +RecordType+ '\' AND isActive__c=true');
			sequenceNo = String.valueOf(count + 1);
			System.debug('sequenceNo--->'+sequenceNo);
		}
	}

	public List<SelectOption> getQueueIDs() {
		List<SelectOption> options = new List<SelectOption>();

		for (AggregateResult ar: [
				SELECT Group.Id, Group.Name
				FROM Group
				where Group.Type = 'Queue' and Group.Name like 'SSSW%'
				group by Group.Name, Group.Id
				order by Group.Name
		]) {
			options.add(new SelectOption(String.ValueOf(ar.get('Id')), String.ValueOf(ar.get('Name'))));
		}

		return options;
	}
	
	private static List<Schema.PicklistEntry> sortPickListEntriesByLabel(List<Schema.PicklistEntry> picklistEntries)
	{
		Map<String, Schema.PicklistEntry> pleMapByLabel = new Map<String, Schema.PicklistEntry>();
		for(Schema.PicklistEntry ple: picklistEntries)
		{
			pleMapByLabel.put(ple.getLabel(), ple);
		}

		List<String> pleLabels = new List<String>(pleMapByLabel.keySet());
		pleLabels.sort();

		List<Schema.PicklistEntry> pleSorted = new List<Schema.PicklistEntry>();
		for(String pleLabel:pleLabels)
		{
			pleSorted.add(pleMapByLabel.get(pleLabel));
		}
		return pleSorted;
	}

	//Returns a map of picklist values
	public static List<SelectOption> getPicklistValues(String ObjectApi_name, String Field_name) {

		List<SelectOption> listPickvals = new List<SelectOption>();
		Schema.SObjectType targetType = Schema.getGlobalDescribe().get(ObjectApi_name);//From the Object Api name retrieving the SObject
		Sobject Object_name = targetType.newSObject();
		Schema.sObjectType sobject_type = Object_name.getSObjectType(); //grab the sobject that was passed
		Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe(); //describe the sobject
		Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap(); //get a map of fields for the passed sobject
		List<Schema.PicklistEntry> pick_list_values = field_map.get(Field_name).getDescribe().getPickListValues(); //grab the list of picklist values for the passed field on the sobject       
		//listPickvals.add(new SelectOption('', '--None--'));//Add in a default value of empty string for first entry
		// sort alphabetically
		pick_list_values = sortPickListEntriesByLabel(pick_list_values);
		System.debug('pick_list_values--->'+pick_list_values);
		for (Schema.PicklistEntry a : pick_list_values) { //for all values in the picklist list
			System.debug('a.getValue()--->'+a.getValue());
			System.debug('a.getLabel()--->'+a.getLabel());
			listPickvals.add(new SelectOption(a.getValue(), a.getLabel()));//add the value  to our final list
		}
		System.debug('listPickvals--->'+listPickvals);
		return listPickvals;
	}
	public void reloadPicklists(){
		// do nothing
	}
	// public PageReference newRoute() {
	//     if (sequenceNo != null) {
	//         sequenceNo = String.valueOf((Integer.valueOf(sequenceNo) + 1));
	//     }
	//     PageReference pr = new PageReference('/apex/SSSWRouting?newSeqFrom=' + sequenceNo + '&newRoute=true');
	//     pr.setRedirect(true);
	//     return pr;
	// }

	public void checkExisting() {
		//Check for existing records
		Integer seq = sequenceNo != null ? Integer.valueOf(sequenceNo) : 0;
		
		String sProductCategory = joinMultiSelectValue(productCategory);
		String sProductSubCategory = joinMultiSelectValue(productSubCategory);
		String sEnquiryType = joinMultiSelectValue(enquiryType);
		String sEnquirySubType = joinMultiSelectValue(enquirySubType);
		String sCustomerQueueType = joinMultiSelectValue(customerQueueType);
		String sOrigin = joinMultiSelectValue(origin);
		String sStatus = joinMultiSelectValue(status);
			  	 
		List<SSSWRouting__c> soqlRoutings = new List<SSSWRouting__c>([
				Select Id, Sequence__c, Origin__c, CustomerQueueType__c, CaseType__c, EnquirySubType__c, ProductCategory__c,
						ProductSubCategory__c, SocialPostTags__c, HasExtraCover__c
				from SSSWRouting__c
				where
				//ProductCategory__c = :productCategory AND
				//ProductSubCategory__c = :productSubCategory AND
				//CaseType__c = :enquiryType AND
				//EnquirySubType__c = :enquirySubType AND
				//CustomerQueueType__c = :customerQueueType AND
				//Origin__c = :origin AND
				Status__c =: sStatus and
				High_Level_Complaint_Flag__c = :selRouting.High_Level_Complaint_Flag__c and
				Customer_Recovery_Flag__c = :selRouting.Customer_Recovery_Flag__c and
				Match_Rules_On__c = :selRouting.Match_Rules_On__c and
				IsNew__c = :selRouting.IsNew__c and
				IsStrategic__c = :selRouting.IsStrategic__c and
				HasExtraCover__c = :selRouting.HasExtraCover__c and
				Sequence__c != :seq and 
				RecordType.name = :recordType
		]);

		existingRoutings = new List<SSSWRouting__c>();
		for(Integer i = 0; i < soqlRoutings.size(); i++)
		{
			SSSWRouting__c route = soqlRoutings[i];
			if((route.ProductCategory__c==null? '' : route.ProductCategory__c) == sProductCategory
					&& (route.ProductSubCategory__c==null? '' : route.ProductSubCategory__c) == sProductSubCategory
					&& (route.CaseType__c==null? '' : route.CaseType__c) == sEnquiryType
					&& (route.EnquirySubType__c==null? '' : route.EnquirySubType__c) == sEnquirySubType
					&& (route.Origin__c==null? '' : route.Origin__c) == sOrigin
					&& (route.CustomerQueueType__c==null? '' : route.CustomerQueueType__c) == sCustomerQueueType
					&& isSamePostTags(route.SocialPostTags__c, selRouting.SocialPostTags__c))
			{
				existingRoutings.add(route);
			}
		}
		System.debug('existingRoutings--->'+existingRoutings);
	}
	
	private List<String> splitMultiSelectValue(String sSelected)
	{
		if(null == sSelected)
		{
			return new List<String>();
		}
		return sSelected.split(MULTI_SELECT_DELIM);
	}

	private String joinMultiSelectValue(List<String> listSelected)
	{
		String s = '';
		if(listSelected != null){
			for(String selectedValue:listSelected)
			{
				if(s.length() > 0)
					s += MULTI_SELECT_DELIM;
				s += selectedValue;
			}
		}
		return s;
	}

	public void save() {
		try {
			checkExisting();
			if (existingRoutings.size() > 0) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'ERROR: Duplicate Settings - Please refer to the list below'));
			} else {
				/*
				selRouting.ProductCategory__c = productCategory;
				selRouting.ProductSubCategory__c = productSubCategory;
				selRouting.CaseType__c = enquiryType;
				selRouting.EnquirySubType__c = enquirySubType;
				selRouting.CustomerQueueType__c = customerQueueType;
				selRouting.Origin__c = origin;
				selRouting.Status__c = status; */
				selRouting.ProductCategory__c = joinMultiSelectValue(productCategory);
				selRouting.ProductSubCategory__c = joinMultiSelectValue(productSubCategory);
				selRouting.CaseType__c = joinMultiSelectValue(enquiryType);
				selRouting.EnquirySubType__c = joinMultiSelectValue(enquirySubType);
				selRouting.CustomerQueueType__c = joinMultiSelectValue(customerQueueType);
				selRouting.Origin__c = joinMultiSelectValue(origin);
				selRouting.Status__c = joinMultiSelectValue(status);
				selRouting.Queue_ID__c = queueID;
				System.debug('Sequence Number--->'+sequenceNo);
				selRouting.Sequence__c = sequenceNo != null ? Integer.valueOf(sequenceNo) : 0;
				//selRouting.NPS_criteria__c = 
				//selRouting.NPS_criteria__c = 
				selRouting.recordtypeId = Schema.SObjectType.SSSWRouting__c.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
				if (controller.getRecord().id != null) {
					update selRouting;
				} else {
					insert selRouting;
				}
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Saved successfully!'));
			}
		} catch (Exception ex) {
			ApexPages.addMessages(ex);
		}
	}

	public void changeRecordType() {
		System.debug('selRouting.recordtypeId--->'+selRouting.recordtypeId);
		String recTypeName = Schema.SObjectType.SSSWRouting__c.getRecordTypeInfosById().get(selRouting.recordtypeId).getName();
		System.debug('recTypeName--->'+recTypeName);
		if(recTypeName != null && recTypeName != ''){
			recordType = recTypeName;
		}
	}

	@TestVisible private Boolean isSamePostTags(String newPostTagsString, String postTagsString) {
		Set<String> newPostTags = splitSocialPostTags(newPostTagsString);
		Set<String> postTags = splitSocialPostTags(postTagsString);
		return newPostTags.equals(postTags);
	}

	private Set<String> splitSocialPostTags(String postTags) {
		if (postTags == null || postTags.trim().length() == 0) {
			return new Set<String>();
		}
		Set<String> uniquePostTags = new Set<String>();
		for (String postTag: postTags.split(MULTI_SELECT_DELIM)) {
			uniquePostTags.add(postTag.toLowerCase().trim());
		}
		return uniquePostTags;
	}
	
	/*
	public static void getOverlaps()
	{
		List<AggregateResult> duplicates = [
				SELECT Count(Id),
						IsNew__c, Origin__c, ProductCategory__c, ProductSubCategory__c,
						Customer_Type__c, CaseType__c, EnquirySubType__c,
						High_Level_Complaint_Flag__c, Customer_Recovery_Flag__c
				FROM SSSWRouting__c
				GROUP BY IsNew__c, Origin__c, ProductCategory__c, ProductSubCategory__c,
						Customer_Type__c, CaseType__c, EnquirySubType__c,
						High_Level_Complaint_Flag__c, Customer_Recovery_Flag__c
				HAVING COUNT(Id) > 1
		];

		List<List<SSSWRouting__c>> dupeLists = new List<List<SSSWRouting__c>> ();
		for(AggregateResult dupe:duplicates)
		{
			//String rType = (String) dupe.get('RecordType');
			Boolean isNew = (Boolean) dupe.get('IsNew__c');
			Boolean isHLC = (Boolean) dupe.get('High_Level_Complaint_Flag__c');
			Boolean isCR = (Boolean) dupe.get('Customer_Recovery_Flag__c');
			String origin = (String) dupe.get('Origin__c');
			String productCat = (String) dupe.get('ProductCategory__c');
			String productSubCat = (String) dupe.get('ProductSubCategory__c');
			String customerType = (String) dupe.get('Customer_Type__c');
			String caseType = (String) dupe.get('CaseType__c');
			String enquirySubType = (String) dupe.get('EnquirySubType__c');

			List<SSSWRouting__c> dupeRecords = [
					SELECT Id, RecordType.DeveloperName, Queue_Name__c,
							IsNew__c, Origin__c, ProductCategory__c, ProductSubCategory__c,
							Customer_Type__c, CaseType__c, EnquirySubType__c,
							High_Level_Complaint_Flag__c, Customer_Recovery_Flag__c
					FROM SSSWRouting__c
					WHERE IsNew__c = :isNew
					AND Origin__c = :origin
					AND ProductCategory__c = :productCat
					AND ProductSubCategory__c = :productSubCat
					AND Customer_Type__c = :customerType
					AND CaseType__c = :caseType
					AND EnquirySubType__c = :enquirySubType
					AND High_Level_Complaint_Flag__c = :isHLC
					AND Customer_Recovery_Flag__c = :isCR
			];

			System.debug('!@#$ duplicates');
			System.debug(dupeRecords);
		}

	}
	
	 */
}