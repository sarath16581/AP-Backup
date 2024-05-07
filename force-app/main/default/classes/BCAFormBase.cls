/**
* @description		: business credit account form base class
* @author			: avula.jansirani@auspost.com.au
* @group			: 
* @last modified on	: 06-07-2021
* @last modified by	: ankur.gandhi@auspost.com.au
* -------------------------------------------------------------------------
* Modifications Log  
* Ver   	Date			Author								Modification
* 1.0   18-12-2020  avula.jansirani@auspost.com.au   			Initial Version
* 1.01 	2024-04-28	venkataraghavendra.ravipati@auspost.com.au	Replaced BSP_Announcement__kav with Knowledge__kav
**/
public without sharing class BCAFormBase {

	/**
	* Check whether the logged in user is EXISTING or NEW Customer
	*/
	@AuraEnabled(cacheable=true)
	public static UserDetails checkUserAccessToBCACreation(String loggedInUserId) {

		// Boolean isUsrHasBillingAcc = false;
		UserDetails userDetail = new UserDetails();

		// Check if site is under maintenance from Custom Setting
		userDetail.underMaintenance = getIsUnderMaintenance();

		userDetail.allowBCACreation = true;  // Default allow to create
		Id userId =  !String.isEmpty(loggedInUserId.trim()) ? loggedInUserId :UserInfo.getUserId(); //0055D000003meG8QAI
		
		String accId = getUserAccountId(userId);
		if(!String.isEmpty(accId)){
			userDetail.userOrgId = accId;
			
			Set<Object> accOptions = new Set<Object>();
			accOptions.add(AccountsSelector.Options.WITH_TYPE_CUST_ACTIVE_BILLING_ACCOUNTS);
			accOptions.add(AccountsSelector.Options.WITH_RECENT_CREATED_CREDIT_ASSESMENT);
			
			List<Account> accountsList = AccountsSelector.newInstance().selectById(new Set<Id>{accId},accOptions).values();
			//System.debug('CUST BILLING ACCOUNTS='+accountsList[0].Billing_Accounts__r);
			//System.debug('Recent Created Credit Assessments='+accountsList[0].Credit_Assessments__r);

			//--if have Billing Account
			if(!accountsList[0].Billing_Accounts__r.isEmpty()){
				userDetail.allowBCACreation = false;
				userDetail.header = BCAFormConstants.MESSAGE_HEADER_TO_USER_HAVING_EXISTING_BILLING_ACCOUNT;
				userDetail.message = BCAFormConstants.MESSAGE_BODY_TO_USER_HAVING_EXISTING_BILLING_ACCOUNT;
				return userDetail;
			}else{
				userDetail = existingCreditAssessmentCheck(accountsList, userDetail);
			}
		}
		
		return userDetail;
	}

	@TestVisible
	private static Boolean getIsUnderMaintenance()
	{
		Set<SObjectField> fields = new Set<SObjectField>{BCA_Settings__c.Name, BCA_Settings__c.Boolean_Value__c};
		CustomsSettingsSelector settingsSelector = CustomsSettingsSelector.newInstance(BCA_Settings__c.SObjectType, fields);
		Set<String> settingNames = new Set<String> {BCAFormConstants.UNDER_MAINTENANCE};
		Map<String, SObject> bcaSettings = (Map<String, SObject>) settingsSelector.selectByNames(settingNames);

		BCA_Settings__c underMaintenance = (BCA_Settings__c) bcaSettings.get(BCAFormConstants.UNDER_MAINTENANCE);
		if(null != underMaintenance)
		{
			return underMaintenance.Boolean_Value__c;
		}

		// by default, assume the form is up
		return false;
		//String clientId = ((BCA_Settings__c) bcaSettings.get(BCAFormConstants.DIGITAL_ID_CLIENT_ID)).Boolean_Value__c;
	}


	//Find out existing credit assessment exists or not.
	private static UserDetails existingCreditAssessmentCheck(List<Account> accountsList, UserDetails userDetail){
		
		//--if have Credit assements then take first one 
		if(!accountsList[0].Credit_Assessments__r.isEmpty()){
			string caStatus = accountsList[0].Credit_Assessments__r[0].APT_Credit_Assessment_Status__c;
			string intStatus = accountsList[0].Credit_Assessments__r[0].Integration_Status__c;
			if(!String.isEmpty(caStatus)){
				if(caStatus.equalsIgnoreCase(BCAFormConstants.CREDIT_ASSESSMENT_STATUS_REJECTED) || 
					caStatus.equalsIgnoreCase(BCAFormConstants.CREDIT_ASSESSMENT_STATUS_APPROVED) || 
					caStatus.equalsIgnoreCase(BCAFormConstants.CREDIT_ASSESSMENT_STATUS_AUTO_APPROVED)){
					userDetail.allowBCACreation = true;
				} else if(caStatus.equalsIgnoreCase(APT_Constants.CREDIT_ASSESSMENT_STATUS_REFERRED) ||
					caStatus.equalsIgnoreCase(BCAFormConstants.CREDIT_ASSESSMENT_STATUS_WORK_IN_PROGRESS)){
					userDetail.allowBCACreation = false;
					userDetail.header = BCAFormConstants.MESSAGE_HEADER_TO_USER_HAVING_EXISTING_CREDIT_ASSESMENT;
					userDetail.message = BCAFormConstants.MESSAGE_BODY_TO_USER_HAVING_EXISTING_CREDIT_ASSESMENT;
				}

				if(userDetail.allowBCACreation && !String.isEmpty(intStatus) 
					&& (intStatus.equalsIgnoreCase(BCAFormConstants.ERROR) || 
						intStatus.equalsIgnoreCase(BCAFormConstants.INTEGRATION_STATUS_REQUESTED))){
					userDetail.allowBCACreation = false;
					userDetail.header = BCAFormConstants.MESSAGE_HEADER_TO_USER_HAVING_EXISTING_CREDIT_ASSESMENT;
					userDetail.message = BCAFormConstants.MESSAGE_BODY_TO_USER_HAVING_EXISTING_CREDIT_ASSESMENT;
				}
			}else{
				//System.debug('Recent created CA status is empty, so allowing the user to create BCA');  //[TO DO: check this csenario with @Ankur]
				 userDetail.allowBCACreation = true;
			}
			
		}else{
			userDetail.allowBCACreation = true;
		}

		return userDetail;
	}

	//-- Get user's org Id, if user is not having any org then returns null
	public static String getUserAccountId(String userId){
		String usrAccId;
		//--Get the user's contact
		User usr = UsersSelector.newInstance().selectById(new Set<Id>{userId}, new Set<Object>{UsersSelector.Options.WITH_CONTACT}).values()[0];
		//System.debug('usr='+usr);
		if(!String.isEmpty(usr.Contact.Id)){
			//--Get Contact's Organisation
			Contact usersContact = ContactsSelector.newInstance().selectById(new Set<Id>{usr.Contact.Id},
																			 new Set<Object>{ContactsSelector.Options.WITH_ACCOUNT}).values()[0];
			//System.debug('usersContact='+usersContact);

			if(!String.isEmpty(usersContact.AccountId)){
				usrAccId = usersContact.AccountId;
			}
		}
		return usrAccId;
	}

	/**
	* to store detail whether is allowed to BCA creation form (or) show message
	*/
	public class UserDetails{
		@AuraEnabled
		public  Boolean allowBCACreation{set;get;}
		@AuraEnabled
		public  string header{set;get;}
		@AuraEnabled
		public  string message{set;get;}
		@AuraEnabled
		public  string userOrgId{set;get;}

		@AuraEnabled
		public Boolean underMaintenance{set; get;}
	}


	/**
	* Method to retrieve the Welcome text
	*/
	@AuraEnabled(cacheable=true)
	public static Knowledge__kav getWelcomeMessage() {
		Knowledge__kav bcaWelcome = getKnowledgeArticle('Online', 'en_US', 'Welcome');
		return bcaWelcome;
	}

	/**
	* Method to retrieve the Direct debit T&C Text
	*/
	@AuraEnabled(cacheable=true)
	public static Knowledge__kav getDirectTC() {
		Knowledge__kav ka = getKnowledgeArticle('Online', 'en_US', 'Direct Debit T&C');
		return ka;
	}

	/**
	* Method to retrieve the the summary T&C Text
	*/
	@AuraEnabled(cacheable=true)
	public static Knowledge__kav getSummaryTC() {
		Knowledge__kav ka = getKnowledgeArticle('Online', 'en_US', 'Summary T&C');
		return ka;
	}
	

	private static Knowledge__kav getKnowledgeArticle(String publishStatus, String language, String type)
	{
		Set<SObjectField> fields = new Set<SObjectField>{
				Knowledge__kav.Id
				, Knowledge__kav.Message__c
		};
		Map<String, Object> searchParams = new Map<String, Object>();
		searchParams.put('statuses', new Set<String>{publishStatus});
		searchParams.put('languages', new Set<String>{language});
		searchParams.put('types', new Set<String>{type});
		searchParams.put('recordTypeNames', new Set<String>{'Business_Credit_Account'});

		KnowledgeArticleVersionsSelector kavSelector = KnowledgeArticleVersionsSelector.newInstance(fields);
		List<Knowledge__kav> kavs = (List<Knowledge__kav>) kavSelector.search(searchParams, true);
		if(kavs.size() == 1)
		{
			return kavs[0];
		}
		return null;
	}

	/**
	* Get the given object field data as List based on given criteria
	* @criteria :  WHERE ANZSIC_Division__c='B Mining'
	* **/
	@AuraEnabled(Cacheable=true)
	public static List<bspEnquiryUplift.SelectOptionCustom> getObjectRecordFieldValues(
		String sObjectApiName, String fieldApiName,String criteria, Boolean isDistinct){
			List<bspEnquiryUplift.SelectOptionCustom> options = new list<bspEnquiryUplift.SelectOptionCustom>();
			//System.debug('getObjectRecordFieldValues -- START');
			fieldApiName = String.escapeSingleQuotes(fieldApiName);
			sObjectApiName = String.escapeSingleQuotes(sObjectApiName);
			criteria = String.escapeSingleQuotes(criteria);

			if(sObjectApiName !=null && fieldApiName != null){
				//System.debug('criteria='+criteria);
				String queryString = 'Select ';//'Select Id ,';
				if(criteria !=null){
					queryString = queryString+  fieldApiName+' From '+ sObjectApiName + ' ' +criteria;
				}else{
					queryString = queryString+  fieldApiName +' From '+ sObjectApiName;
				}
				if(isDistinct){
					queryString = queryString + ' Group By '+fieldApiName; //+ ' Group By Id ,'+fieldApiName;
				}
				queryString = queryString + ' ORDER BY '+ fieldApiName +' ASC';
				//System.debug('queryString='+queryString);
				List<sObject> recordList = Database.query(String.escapeSingleQuotes(queryString));
				if(recordList != null && recordList.size() > 0){

					for(sObject record : recordList){
						options.add(new bspEnquiryUplift.SelectOptionCustom((String)record.get(fieldApiName), (String)record.get(fieldApiName)));
					}

				}
			}
			return options;
		}

	@AuraEnabled(Cacheable=true)
	public static List<bspEnquiryUplift.SelectOptionCustom> getIndustryDivisionValues(){
		List<bspEnquiryUplift.SelectOptionCustom> options = new list<bspEnquiryUplift.SelectOptionCustom>();
		Set<String> tempSet = new Set<String>();
		List<ANZSIC_Code__c> recordList = [Select ANZSIC_Division__c, ANZSIC_Division_Trim__c From ANZSIC_Code__c Where ANZSIC_Division__c != '' ORDER BY ANZSIC_Division_Trim__c]; //TO DO: do we put Limit 50000
		//-- Need to get the unique values of 'ANZSIC_Division_Trim', as this field is formula field so cannot apply 'Group By' clause. So getting unquique values by iterating them with below way
		if(recordList != null && recordList.size() > 0){
			for(ANZSIC_Code__c record : recordList){
				if(tempSet.contains(record.ANZSIC_Division_Trim__c)){
					continue;
				}
				else{
					tempSet.add(record.ANZSIC_Division_Trim__c);
					options.add(new bspEnquiryUplift.SelectOptionCustom((String)record.ANZSIC_Division__c, (String)record.ANZSIC_Division_Trim__c));
				}

			}
		}

		return options;
	}

	@AuraEnabled(Cacheable=true)
	public static Map<String, Decimal> noOfTimesCreditLimit() {
		Map<String, Decimal> creditLimitsMap = new  Map<String, Decimal>();
	  
		BCA_Settings__c bcaSettingCreditLimit = getBcaSettingByName(BCAFormConstants.CREDIT_LIMIT_TIMES);
		BCA_Settings__c bcaSettingCreditRoundNearest = getBcaSettingByName(BCAFormConstants.CREDIT_AMOUNT_ROUND_NEAREST);
		
		if(null != bcaSettingCreditLimit){
			creditLimitsMap.put('noOfTimes', bcaSettingCreditLimit.Number_Value__c);
		}
		if(null != bcaSettingCreditRoundNearest){
			creditLimitsMap.put('roundNearest', bcaSettingCreditRoundNearest.Number_Value__c);
		}
	   
		return creditLimitsMap;
	}

	@AuraEnabled(Cacheable=true)
	public static Decimal getMinimumCreditLimit() {
		BCA_Settings__c bcaSetting = getBcaSettingByName(BCAFormConstants.MINIMUM_CREDIT_AMOUNT);
		if(null != bcaSetting){
			return bcaSetting.Number_Value__c;
		}
		return 0;
	}

	@AuraEnabled(Cacheable=true)
	public static String getSummryTCDownloadURL() {
		BCA_Settings__c bcaSetting = getBcaSettingByName(BCAFormConstants.SUMMARY_TC_DOWNLOAD_URL);
		if(null != bcaSetting){
			return bcaSetting.Text_Value__c;
		}
		return '';
	}

	@AuraEnabled(Cacheable=true)
	public static String getSummryPrivacyNoticeURL() {
		BCA_Settings__c bcaSetting = getBcaSettingByName(BCAFormConstants.SUMMARY_PRIVACY_NOTICE_URL);
		if(null != bcaSetting){
			return bcaSetting.Text_Value__c;
		}
		return '';
	}
	
	@AuraEnabled(Cacheable=true)
	public static String getDirectDebitTCDownloadURL() {
		BCA_Settings__c bcaSetting = getBcaSettingByName(BCAFormConstants.DIRECT_DEBIT_TC_DOWNLOAD_URL);
		if(null != bcaSetting){
			return bcaSetting.Text_Value__c;
		}
		return '';
	}

	private static BCA_Settings__c getBcaSettingByName(String settingName)
	{
		Set<SObjectField> fields = new Set<SObjectField>{
				BCA_Settings__c.Id
				, BCA_Settings__c.Name
				, BCA_Settings__c.Text_Value__c
				, BCA_Settings__c.Number_Value__c
				, BCA_Settings__c.Boolean_Value__c
		};
		CustomsSettingsSelector settingsSelector = CustomsSettingsSelector.newInstance(BCA_Settings__c.SObjectType, fields);
		List<BCA_Settings__c> bcaSettings = (List<BCA_Settings__c>) settingsSelector.selectByNames(new Set<String> {settingName}).values();
		if(bcaSettings.size() == 1)
		{
			return bcaSettings[0];
		}
		return null;
	}


	/**
	* @author: 	Jansi Rani
	* @description:	Method to perform duplicate check on matching ABN/ACN of existing Organisation records
						The duplicate check is called prior to executing the ABN/ACN lookup at Equifax
	* @param:	List<Account>
	* @return:	Boolean - true if duplicate is found, otherwise false
	*/
	public static Boolean containDuplicateABNACN(List<Account> accList, Id acctId) {
		// Replacing DataCloud with DataProxy class.
		List<DatacloudProxy.FindDuplicatesResult> results = ApplicationDatabase.getInstance().findDuplicates(accList);
		Account newAcc = new Account();
		/*
		Datacloud.FindDuplicatesResult[] results = Datacloud.FindDuplicates.findDuplicates(accList);
		System.debug('Duplicate account search results='+results);
		Account newAcc = new Account();
		*/
		/**
		* Sample code from Salesforce, to return the duplicate records found by the matching rule on Organisation ABN/ACN
		* Link: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_class_Datacloud_FindDuplicatesResult.htm#apex_class_Datacloud_FindDuplicatesResult
		*  */ 
		for (DatacloudProxy.FindDuplicatesResult findDupeResult : results) {
			for (DatacloudProxy.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {
				for (DatacloudProxy.MatchResult matchResult : dupeResult.getMatchResults()) {
					for (DatacloudProxy.MatchRecord matchRecord : matchResult.getMatchRecords()) {
						// save the duplicate record found by the matching rule and cast to Account type
						newAcc = (Account) matchRecord.getRecord();
						//System.debug('newAcc='+newAcc);
						// It must be a distinct and existing organisation record, unrelated to the current user 
						if(newAcc.id != acctId){
							return true;
						}
					}
				}
			}
		}
		
		return false;
	}

	public class BSB_Result{
		@AuraEnabled public String name {get; set;}

		public BSB_Result(BSB__c bsbRecord)
		{
			this.name = bsbRecord.Name;
		}
	}

	@AuraEnabled
	public static BSB_Result validateBSB(String bsb)
	{
		Set<SObjectField> fields = new Set<SObjectField>{BSB__c.Name};
		CustomsSettingsSelector settingsSelector = CustomsSettingsSelector.newInstance(BSB__c.SObjectType, fields);
		Set<String> settingNames = new Set<String> {bsb};
		Map<String, SObject> bsbResult = (Map<String, SObject>) settingsSelector.selectByNames(settingNames);
		if(bsbResult.values().size() > 0)
		{
			return new BSB_Result((BSB__c) bsbResult.values()[0]);
		}
		return null;
	}
}