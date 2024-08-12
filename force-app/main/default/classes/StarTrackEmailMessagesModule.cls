/**
 * @description
 * Module to handle automation specific to StarTrack cases on email messages(email to case).
 * @author Naveen Rajanna
 * @date 2022-02-22
 * @group Domain
 * @domain StarTrackEmailMessagesDomain
 * @changelog
 * 2022-02-22	Naveen Rajanna	created - REQ2723199
 * 2022-10-17	Naveen Rajanna REQ2859152 Removed the filter ParentId as it is included in the parent domain class, changed api version to 55
 * 2024-08-07 - Ranjeewa Silva - Uplifted to new ApplicationModule framework
 */
public inherited sharing class StarTrackEmailMessagesModule extends ApplicationModule {
	private static Map<Id, RecordType> validRecTypes; // type of cases for which code executes
	private static final Set<String> ST_CASE_RECORD_TYPES = new Set<String>{StarTrack_Constants.CASE_VOC_RT_DEV, StarTrack_Constants.CASE_DELIVERY_RT_DEV, StarTrack_Constants.CASE_TWC_RT_DEV, StarTrack_Constants.CASE_CREDIT_RT_DEV, StarTrack_Constants.CASE_PBE_RT_DEV};
	private static StarTrack_Settings__c starTrackSettings;
	private static Map<String, StarTrackDefaultEmailAddresses__c> defaultAddress;

	static {
		try {
			starTrackSettings = StarTrack_Settings__c.getOrgDefaults();
			defaultAddress = StarTrackDefaultEmailAddresses__c.getAll();
			validRecTypes = Utility.getRecordTypesAsSObjectByDevName(String.valueOf(Case.getsObjectType()), ST_CASE_RECORD_TYPES);
		} catch (Exception ex) {
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), StarTrack_Constants.STARTRACK, StarTrackEmailMessagesModule.class.getName(), SSSWConstants.STATIC_BLOCK, BGSConstants.EMAILMESSAGE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	// Setup which triggers this module should respond to
	public StarTrackEmailMessagesModule() {
		getTriggerEvents().enableAfterInsert();
	}

	/**
	* Called when a new EmailMessage is being inserted
	*/
	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		try {
			updateRelatedCases(records, uow); //update related case fields
		} catch (Exception ex) {
			// Error Logged to Exception object for analysis
			UTIL_LoggingService.logHandledException(ex, UserInfo.getOrganizationId(), StarTrack_Constants.STARTRACK, StarTrackEmailMessagesModule.class.getName(), 'onAfterInsert', BGSConstants.EMAILMESSAGE_TRIGGER, LoggingLevel.ERROR);
		}
	}

	/**
 	* Perform updates to related Case object 
	*/
	public void updateRelatedCases(List<SObject> newEmails, ApplicationUnitOfWork uow) {
		Set<Id> emailIdSet = (new Map<Id,SObject>(newEmails)).keySet(); //Set containing emailmessage Id whose parent id is of case
		Set<Id> milestonesToUpdCaseIdSet = new Set<Id>(); //Set containing case Id whose case milestones needs to be updated
		List<SObject> sObjectList = new List<SObject> (); //List of SObject to update

		//Get the selected emailMessage with related case fields, whose parent case recordtype is StarTrack
		for(EmailMessage em : EmailMessagesSelector.newInstance().selectByIdsWithParentStarTrackCase(emailIdSet, new Set<Object>{EmailMessagesSelector.Options.WITH_CASE, CasesSelector.Options.WITH_RECORDTYPE})){
			Case caseToUpd = null;	

			//Incoming Email for selected StarTrack Open Cases with StarTrack_Calc_Email_Address__c populated or has received first email response already
			if (em.Incoming && em.Parent.Status != StarTrack_Constants.CASE_STAT_CLOSED &&
				(em.Parent.First_Email_Response__c || em.Parent.StarTrack_Calc_Email_Address__c != null) &&
				validRecTypes.containsKey(em.Parent.RecordTypeId)) {
				if (StarTrack_Constants.CASE_VOC_RT_DEV.equals(em.Parent.RecordType.DeveloperName)) {
					//Update Case Status to Awaiting Review
					caseToUpd = new Case(Id=em.ParentId, Status=StarTrack_Constants.CASE_STAT_AWAITINGREVIEW);
				} else if ((!em.Parent.Owner_is_Queue__c &&
						(StarTrack_Constants.CASE_DELIVERY_RT_DEV.equals(em.Parent.RecordType.DeveloperName) ||
							StarTrack_Constants.CASE_PBE_RT_DEV.equals(em.Parent.RecordType.DeveloperName))) ||
					(em.Parent.Approval_Status__c != StarTrack_Constants.CASE_APPROVALSTAT_PENDING &&
						(StarTrack_Constants.CASE_CREDIT_RT_DEV.equals(em.Parent.RecordType.DeveloperName) ||
							StarTrack_Constants.CASE_TWC_RT_DEV.equals(em.Parent.RecordType.DeveloperName)))) {
					//Update Case_Update__c field to New Email Received
					caseToUpd = new Case(Id = em.ParentId, Case_Update_Time__c = Datetime.now(),
						Case_Update__c = StarTrack_Constants.KEYWRD_NEWEMAILRECVD);
				}
			}

			//Incoming Email for StarTrack Closed Cases
			else if (em.Incoming && em.Parent.Status == StarTrack_Constants.CASE_STAT_CLOSED && em.Parent.StarTrack_RecordType__c) {
				//Update Case Status to Reopened
				caseToUpd = new Case(Id=em.ParentId, Status=StarTrack_Constants.CASE_STAT_REOPENED);
			}

			//Outbound Email for StarTrack Cases which haven't received first email response
			else if (!em.Parent.First_Email_Response__c &&
				(EmailMessageUtil.STATUS_REPLIED.equals(em.Status) || EmailMessageUtil.STATUS_SENT.equals(em.Status)) && 
					em.Parent.StarTrack_RecordType__c) {
				//Add caseId to set to complete it's 'StarTrack - Customer 1st Response' milestone
				milestonesToUpdCaseIdSet.add(em.ParentId);

				//Set 1st Customer Response flag
				caseToUpd = new Case(Id = em.ParentId, First_Email_Response__c = true);
			}

			//Incoming Email for StarTrack Cases having empty StarTrack_Calc_Email_Address__c
			else if (em.Incoming && em.Parent.StarTrack_Calc_Email_Address__c == null && em.Parent.StarTrack_RecordType__c) {
				caseToUpd = new Case();
				caseToUpd.Id = em.ParentId;
				caseToUpd.Other__c = StarTrackUtil.getCaseOtherFieldValue(em.Subject);
				caseToUpd.StarTrack_Calc_Email_Address__c = StarTrackUtil.getCaseSTCalcEmailAddress(em.ToAddress);
				if (!em.Parent.Business_Solutions_Customer__c && StarTrack_Constants.CASE_ORIGIN_BSC.equals(em.Parent.Origin)) {
					caseToUpd.Business_Solutions_Customer__c = true;
					caseToUpd.Origin = StarTrack_Constants.CASE_ORIGIN_EMAIL;
				}
				
				if(StarTrack_Constants.CASE_CREDIT_RT_DEV.equals(em.Parent.RecordType.DeveloperName) && 
					((String.isNotBlank(em.CcAddress) && em.CcAddress.containsIgnoreCase(starTrackSettings.Credit_Dispute_From_Email__c))
						|| (String.isNotBlank(em.BccAddress) && em.BccAddress.containsIgnoreCase(starTrackSettings.Credit_Dispute_From_Email__c)) 
						|| (String.isNotBlank(em.Subject) && em.Subject.contains(StarTrack_Constants.CREDITCLAIM_INVSUBJECT) && 
							String.isNotBlank(em.ToAddress) && em.ToAddress.containsIgnoreCase(starTrackSettings.Credit_Dispute_From_Email__c)))) {
					caseToUpd.Subject = starTrackSettings.ST_Credit_Claim_Inbound_Email_Prefix__c + em.Parent.Subject;
					caseToUpd.ResolutionCode__c = String.isBlank(em.Parent.ResolutionCode__c) 
						? StarTrack_Constants.CASE_RESOLUTION_DUPLICATE : em.Parent.ResolutionCode__c;
					caseToUpd.Status = StarTrack_Constants.CASE_STAT_CLOSED;
					caseToUpd.Enquiry_Type__c = String.isBlank(em.Parent.Enquiry_Type__c) 
						? StarTrack_Constants.CASE_ENQUIRY_DEF : em.Parent.Enquiry_Type__c;
					caseToUpd.Call_Purpose__c = String.isBlank(em.Parent.Call_Purpose__c) 
						? StarTrack_Constants.CASE_PURPOSE_DEF : em.Parent.Call_Purpose__c;
					caseToUpd.FCR__c = false;
				} else {
					Boolean isDuplicateEmail = false;
					if(starTrackSettings.Check_for_Duplicate_Email__c){
						DateTime customDateTime = em.CreatedDate - (starTrackSettings.Duplicate_Email_Check_Interval_Minutes__c/1440); // Get datetime minus 2 minutes
						Integer dupCount = EmailMessagesSelector.newInstance().getDuplicateEmailMessagesCount(em.Id, em.FromAddress, em.Subject, customDateTime);
						isDuplicateEmail = dupCount > 0 ? true : false;
					}

					if(isDuplicateEmail){
						caseToUpd.Subject = StarTrack_Constants.DUPLICATE_EMAIL + em.Parent.Subject;
						caseToUpd.ResolutionCode__c = StarTrack_Constants.CASE_RESOLUTION_DUPLICATE;
						caseToUpd.Status = StarTrack_Constants.CASE_STAT_CLOSED;
						caseToUpd.Enquiry_Type__c = StarTrack_Constants.CASE_ENQUIRY_DEF;
						caseToUpd.Call_Purpose__c = StarTrack_Constants.CASE_PURPOSE_DEF;                
					} else {
						Map<String, StarTrackDefaultEmailAddresses__c> defaultAddress = StarTrackDefaultEmailAddresses__c.getAll();	
						if(((caseToUpd.StarTrack_Calc_Email_Address__c.contains(starTrackSettings.Business_Solutions_From_Email__c)
								|| caseToUpd.StarTrack_Calc_Email_Address__c.contains(starTrackSettings.Investigators_From_Email__c)) 
								&& StarTrack_Constants.CASE_DELIVERY_RT_DEV.equals(em.Parent.RecordType.DeveloperName)
								&& !em.Parent.Auto_Email_Response_sent__c) 
							|| 
							((StarTrack_Constants.CASE_CREDIT_RT_DEV.equals(em.Parent.RecordType.DeveloperName)
								|| StarTrack_Constants.CASE_VOC_RT_DEV.equals(em.Parent.RecordType.DeveloperName))
								&& !em.Parent.Auto_Email_Response_sent__c)) {
							caseToUpd.Send_Auto_Response_Email__c = true;
						}
						
						if(defaultAddress.containsKey(caseToUpd.StarTrack_Calc_Email_Address__c) && 
							defaultAddress.get(caseToUpd.StarTrack_Calc_Email_Address__c).From_Email_Address__c != null &&
							defaultAddress.get(caseToUpd.StarTrack_Calc_Email_Address__c).From_Email_Address__c != caseToUpd.StarTrack_Calc_Email_Address__c) {
								caseToUpd.StarTrack_Calc_Email_Address__c = defaultAddress.get(caseToUpd.StarTrack_Calc_Email_Address__c).From_Email_Address__c;
						}
					}
				}
			}

			if (caseToUpd != null) {
				sObjectList.add((SObject) caseToUpd);
			}
		}

		//update 'StarTrack - Customer 1st Response' milestone
		if(!milestonesToUpdCaseIdSet.isEmpty()) {
			//Fetch all casemilestones for the selected caseIds and selected milestonetypes filtering only the violated flag true records
			for(CaseMilestone cm : CaseMilestonesSelector.newInstance().selectByCaseAndMilestoneNames(milestonesToUpdCaseIdSet,  new Set<String>{StarTrack_Constants.CASEMILESTONE_CUST_FIRST_RESP}, new Set<Object>{CaseMilestonesSelector.Options.FILTER_VIOLATED})) {
				sObjectList.add((SObject) new CaseMilestone(Id=cm.Id, CompletionDate=System.now()));
			}
		}

		if (!sObjectList.isEmpty()) {
			//register the cases to update with the UOW and the work will be committed in ApplicationDomainTriggerHandler
			uow.registerDirty(sObjectList);
		}
	}
}