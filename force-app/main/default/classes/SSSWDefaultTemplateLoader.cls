	/***************************************************************************************************
	Author:			David CatindoyobjCCSetting
	Company:		Cloud Sherpas
	Description:	Email Quick Action Handler
	Purpose:		This Default Email Template Handler determines the Email Template based on the Record Type name values from the Custom Settings - StarTrack Settings.
					All Case Record Types that require specific Email Template must be specified in the Custom Settings - StarTrack Settings.
	History:
	-----------------------------------------------------------------------------------------
	unknown			David Catindoy
	March 1, 2016	David Catindoy - Modified
	11.06.1018		TDO-223 - kalpita.talwadekar@auspost.com.au   updated code for coding standard follow
	26.04.2022		Naveen Rajanna  REQ2787691 - Avoid copying of template on email template for StarTrack
	06.05.2022		Naveen Rajanna  REQ2829614 - Copy original attachment on email template only for StarTrack VOC
	01.11.2023		Thang Nguyen SB-194 - Set the From/To email address for Credit Claim cases
	***************************************************************************************************/
	global class SSSWDefaultTemplateLoader implements QuickAction.QuickActionDefaultsHandler {

	global SSSWDefaultTemplateLoader (){
		// Empty constructor
	}

	/** 
		 * @name: onInitDefaults()
		* @desciption: method to initialize the email template settings
		* @param: List<QuickAction.QuickActionDefaults> defaults
		* @return: NA
		*
		*/
	public void onInitDefaults(List<QuickAction.QuickActionDefaults> defaults){  
		//call the method for setting defaults on email quick action
		QuickAction.SendEmailQuickActionDefaults sendEmailDefaults = getSendEmailQuickAction(defaults);

		//if these email defaults are found
		if(sendEmailDefaults != null) {  
			//then query the current case details
			Set<SObjectField> caseFieldsToQuery = new Set<SObjectField>{Case.Id, Case.CaseNumber, Case.StarTrack_RecordType__c, Case.StarTrack_Calc_Email_Address__c, Case.ArticleTest__c, Case.StarTrack_From_Address__c,
																		Case.Email_Address__c, Case.Business_Unit__c, Case.Origin
			};

			Case caseRec;			
			List<Case> caseList = CasesSelector.newInstance(caseFieldsToQuery).selectById(new Set<Id>{sendEmailDefaults.getContextId()}, new Set<Object>{CasesSelector.Options.WITH_CONTACT, CasesSelector.Options.WITH_RECORDTYPE}).values(); 											
			if(!caseList.isEmpty()) {
				caseRec = caseList[0];
			}

			//setup the email message based on email message default settings
			EmailMessage emailMessage = (EmailMessage) sendEmailDefaults.getTargetSObject();

			//if it is startrack case
			if(caseRec.StarTrack_RecordType__c){
				emailMessage.FromAddress = caseRec.StarTrack_From_Address__c;
			}
			// set the template id
			sendEmailDefaults.setTemplateId(getTemplateId(caseRec));

			if(caseRec.RecordType.DeveloperName.contains('StarTrack')){
				if(StarTrack_Constants.CASE_VOC_RT_DEV.equals(caseRec.RecordType.DeveloperName)) { //REQ2829614
					sendEmailDefaults.setInsertTemplateBody(true); 
				}
				sendEmailDefaults.setIgnoreTemplateSubject(true);
			}else if (caseRec.RecordType.DeveloperName == BspConstants.CASE_RECORD_TYPE_ENTERPRISE_CREDIT_DISPUTE_DEV_NAME || 
					caseRec.RecordType.DeveloperName == BspConstants.CASE_RECORD_TYPE_ENTERPRISE_CREDIT_DISPUTE_GUEST_DEV_NAME){
				if (!String.isEmpty(caseRec.Business_Unit__c)){
					Credit_Claim_Setting__c ccSettingRecord;
					ccSettingRecord = Credit_Claim_Setting__c.getValues(caseRec.Business_Unit__c);
					emailMessage.FromAddress = ccSettingRecord.Default_From_Email__c;	
				}
				if (caseRec.Origin == 'Web'){
					emailMessage.ToAddress = caseRec.Email_Address__c;	
				}else{
					if (!String.isEmpty(caseRec.Contact.Email)){
						emailMessage.ToAddress = caseRec.Contact.Email;
					}else{
						emailMessage.ToAddress = caseRec.Email_Address__c;
					}
				}
			}

			//call method for attachment details on template for current case
			prepareCaseAttachments(caseRec.Id, caseRec.ArticleTest__c);
		}
	}  

	/** 
		 * @name: getSendEmailQuickAction()
		* @desciption: method for setting defaults on email quick action
		* @param: ApexPages.StandardController controller
		* @return: QuickAction.SendEmailQuickActionDefaults
		*
		*/
	public QuickAction.SendEmailQuickActionDefaults getSendEmailQuickAction(List<QuickAction.QuickActionDefaults> defaults) {   
		//loop through the quick actions defaults
		for(QuickAction.QuickActionDefaults defaultSetting : defaults) {

			//return the specific email quick action for case object
			if(defaultSetting instanceof QuickAction.SendEmailQuickActionDefaults && 
					defaultSetting.getTargetSObject().getSObjectType() == EmailMessage.sObjectType && 
					defaultSetting.getActionName().equals('Case.Email') && 
					defaultSetting.getActionType().equals('Email')){
				return (QuickAction.SendEmailQuickActionDefaults) defaultSetting;
			}
		}
		return null;
	}

	/** 
		 * @name: getTemplateId()
		* @desciption: method to return the right template details based on case type AP or ST or other
		* @param: Case theCase
		* @return: Id
		*
		*/
	global Id getTemplateId(Case theCase){
		//get all ST email details from custom settings
		Map<String, StarTrack_Default_Email_Template__c> defaultEmailTemplate = StarTrack_Default_Email_Template__c.getAll();
		
		//if it is a SSSW case
		if(theCase.RecordType.DeveloperName.contains('SSSW') &&
				defaultEmailTemplate.containsKey('SSSW') &&
				defaultEmailTemplate.get('SSSW').Email_Template_Name__c != null){

			return queryEmailTemplate(defaultEmailTemplate.get('SSSW').Email_Template_Name__c);

		} else if(defaultEmailTemplate.containsKey(theCase.RecordType.Name)){

			if(defaultEmailTemplate.get(theCase.RecordType.Name).Email_Template_Name__c == null){
				return null;
			}
			return queryEmailTemplate(defaultEmailTemplate.get(theCase.RecordType.Name).Email_Template_Name__c);

		} else if(theCase.RecordType.DeveloperName.contains('StarTrack') &&
				defaultEmailTemplate.containsKey('StarTrack') &&
				defaultEmailTemplate.get('StarTrack').Email_Template_Name__c != null){ //if it is a startrack case

			return queryEmailTemplate(defaultEmailTemplate.get('StarTrack').Email_Template_Name__c);
		} else{
			return null;
		}
	}

	/** 
		 * @name: queryEmailTemplate()
		* @desciption: query the template from templateName
		* @param: String templateName
		* @return: NA
		*
		*/
	public Id queryEmailTemplate(String templateName){
		try{
			//based on templateName get the template details
			EmailTemplate theTemplate = [ SELECT Id, Name, DeveloperName FROM EmailTemplate WHERE DeveloperName = :templateName LIMIT 1 ];
			return theTemplate.Id; 
		} catch(Exception ex){
			return null;
		}
	}

	/** 
		 * @name: prepareCaseAttachments()
		* @desciption: method to prepare the attachment details for current case
		* @param: Id caseId, Id conId
		* @return: NA
		*
		*/
	public void prepareCaseAttachments(Id caseId, Id conId){
		Set<String> podIDs = new Set<String>();

		//query all case attachments
		List<Attachment> caseAttachments = [ SELECT Id, Name, Description FROM Attachment WHERE ParentId = :caseId];

		//check if there are any attachments present
		if(!caseAttachments.isEmpty()){ 
			for(Attachment att : caseAttachments){
				podIDs.add(att.Description);
			}
		}
		
		//if a contact exists
		if(String.isNotBlank(conId)){
			//get the POD details for the article based on contact id
			Article__c caseCon = [
					SELECT
						Id, Name,
						(SELECT Id, Name FROM Proof_of_Deliveries__r WHERE Id NOT IN :podIDs)
					FROM
						Article__c
					WHERE
						Id = :conId
			];
										
			Set<Id> podList = new Set<Id>();
			for(Proof_of_Delivery__c pod : caseCon.Proof_of_Deliveries__r){
				podList.add(pod.Id);
			}

			//query all POD attachments
			List<Attachment> podAttachments = [
				SELECT
					Id, Name, Description, Body,
					BodyLength, ContentType, IsPrivate, ParentId
				FROM
					Attachment
				WHERE
					ParentId IN :podList
			];
			caseAttachments.clear();

			//loop through POD attachments and add to existing case attachments if any
			for(Attachment podAttach : podAttachments){
				Attachment newAttach = podAttach.clone(false, true, false, false);
				newAttach.Name = newAttach.Name;
				newAttach.Description = podAttach.ParentId;
				newAttach.ParentId = caseId;
				caseAttachments.add(newAttach);
			}

			// insert the case attachments
			insert caseAttachments;
		}
	}
	}