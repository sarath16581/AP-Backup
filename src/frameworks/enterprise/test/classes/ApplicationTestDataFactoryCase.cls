/**
 * @description Yet another Test data factory... specifically for Case
 * @author Nathan Franklin
 * @date 2023-05-29
 * @changelog
 * 2024-06-13 - Parveen Kaushik - Added default value for mapping model on test data. See CSLU-470 (JIRA) for details.
 * 2024-07-23 - Ranjeewa Silva - New methods to return new ContactRequests and ImpactedArticle__c.
 * 2024-08-23 - George Nguyen - added getLiveChatTranscripts(...), getVoiceCalls(...) and updated getContactRequests(...)
*/
@IsTest
public with sharing class ApplicationTestDataFactoryCase {

	public static List<Case> getCases(Integer count, Boolean generateIds) {
		return (List<Case>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(Case.SObjectType, new Map<SObjectField, Object> {
				Case.Subject => 'Case Subject %count%',
				Case.Description => 'Case Description %count%',
				Case.Status => 'New'
		}, count), generateIds);
	}

	public static List<Case> getCases(Integer count, Set<Id> contactIds, Boolean generateIds) {
		return getCases(count, new List<Id>(contactIds), generateIds);
	}

	public static List<Case> getCases(Integer count, List<Id> contactIds, Boolean generateIds) {
		List<Case> output = (List<Case>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(Case.SObjectType, new Map<SObjectField, Object> {
				Case.Subject => 'Case Subject %count%',
				Case.Description => 'Case Description %count%',
				Case.Status => 'New',
				Case.ContactId => contactIds
		}, count), generateIds);

		for(Integer i = 0; i < output.size(); i++) {
			output[i] = (Case)ApplicationTestDataFactory.setUnwritableFields(output[i], new Map<String, Object>{'IsClosed' => false});
		}

		return output;
	}

	public static List<CaseStatus> getCaseStatuses(Integer count, Boolean generateIds) {
		List<CaseStatus> output = (List<CaseStatus>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(CaseStatus.SObjectType, new Map<SObjectField, Object> {
		}, count), generateIds);

		for(Integer i = 0; i < output.size(); i++) {
			output[i] = (CaseStatus)ApplicationTestDataFactory.setUnwritableFields(output[i], new Map<String, Object>{'ApiName' => 'Case Status ' + (i+1), 'MasterLabel' => 'Case Status ' + (i+1), 'IsClosed' => false});
		}

		return output;
	}

	public static List<PendingServiceRouting> getPendingServiceRoutings(Integer count, Id serviceChannelId, Object /*List<Id>*/ queueIds, Object /*List<Id>*/ caseIds, Boolean generateIds) {
		List<PendingServiceRouting> output = (List<PendingServiceRouting>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(PendingServiceRouting.SObjectType, new Map<SObjectField, Object> {
			PendingServiceRouting.CapacityPercentage => 100,
			PendingServiceRouting.IsReadyForRouting => true,
			PendingServiceRouting.PushTimeout => 100,
			PendingServiceRouting.RoutingModel => 'MostAvailable',
			PendingServiceRouting.RoutingPriority => 100,
			PendingServiceRouting.RoutingType => 'QueueBased',
			PendingServiceRouting.SecondaryRoutingPriority => 100,
			PendingServiceRouting.ServiceChannelId => serviceChannelId,
			PendingServiceRouting.WorkItemId => caseIds
		}, count), generateIds);

		for(Integer i = 0; i < output.size(); i++) {
			Id queueId = queueIds instanceOf List<Id> ? ((List<Id>)queueIds)[i] : (Id)queueIds;

			output[i] = (PendingServiceRouting)ApplicationTestDataFactory.setUnwritableFields(output[i], new Map<String, Object>{'QueueId' => queueId, 'GroupId' => queueId});
		}

		return output;
	}

	public static List<MiniCaseFieldMapping__c> getEnquiryTypeMappings(Boolean generateIds) {
		List<MiniCaseFieldMapping__c> mappings = new List<MiniCaseFieldMapping__c>{
				new MiniCaseFieldMapping__c(
						Id = (generateIds ? fflib_IDGenerator.generate(MiniCaseFieldMapping__c.SObjectType) : null),
						ProductCategory__c = 'Domestic Parcels',
						ProductSubcategory__c = 'eParcel- Regular',
						SAPProductCategory__c = 'eParcel',
						SAPProductSubcategory__c = 'eParcel Standard',
						MappingModel__c = SSSWConstants.ENQUIRYMAPPING_CLASSIC_MODEL
				),
				new MiniCaseFieldMapping__c(
						Id = (generateIds ? fflib_IDGenerator.generate(MiniCaseFieldMapping__c.SObjectType) : null),
						ProductCategory__c = 'Domestic Parcels',
						ProductSubcategory__c = 'StarTrack (Next Flight Premium & Express)',
						SAPProductCategory__c = 'StarTrack',
						SAPProductSubcategory__c = 'ST Next Flight',
						MappingModel__c = SSSWConstants.ENQUIRYMAPPING_CLASSIC_MODEL
				),
				new MiniCaseFieldMapping__c(
						Id = (generateIds ? fflib_IDGenerator.generate(MiniCaseFieldMapping__c.SObjectType) : null),
						ProductCategory__c = 'Domestic Parcels',
						ProductSubcategory__c = 'Express',
						SAPProductCategory__c = 'Express Post',
						SAPProductSubcategory__c = 'Express Post Medium',
						MappingModel__c = SSSWConstants.ENQUIRYMAPPING_CLASSIC_MODEL
				)
		};

		for(Integer i = 0; i < mappings.size(); i++) {
			mappings[i] = (MiniCaseFieldMapping__c)ApplicationTestDataFactory.setUnwritableFields(mappings[i], new Map<String, Object>{'SAPKey__c' => mappings[i].SAPProductCategory__c + mappings[i].SAPProductSubcategory__c});
		}

		System.debug(mappings);

		return mappings;
	}

	public static List<EmailMessage> getEmailMessages(Integer count, Boolean generateIds,Boolean isIncoming, String fromAddress, String toAddress, String subject, Id caseId) {
		return getEmailMessages(count, generateIds, isIncoming, fromAddress, toAddress, null, null, subject, caseId);
	}

	public static List<EmailMessage> getEmailMessages(Integer count, Boolean generateIds,Boolean isIncoming, String fromAddress, String toAddress, String ccAddress, String bccAddress, String subject, Id caseId) {
		return (List<EmailMessage>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(EmailMessage.SObjectType, new Map<SObjectField, Object> {
				EmailMessage.Incoming => isIncoming,
				EmailMessage.ParentId => caseId,
				EmailMessage.FromAddress => fromAddress,
				EmailMessage.ToAddress => toAddress,
				EmailMessage.CcAddress => ccAddress,
				EmailMessage.BccAddress => bccAddress,
				EmailMessage.Subject => subject,
				EmailMessage.HTMLBody => 'Sample'
		}, count), generateIds);
	}

	public static List<MilestoneType> getMilestoneTypes(Integer count, Boolean generateIds) {
		return (List<MilestoneType>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(MilestoneType.SObjectType, new Map<SObjectField, Object> {
				MilestoneType.Name => 'Milestone Name %count%',
				MilestoneType.Description => 'Milestone Description %count%'
		}, count), generateIds);
	}

	public static List<CaseMilestone> getCaseMilestones(Integer count, Boolean generateIds,Boolean isViolated, Boolean isCompleted, Id milestoneTypeId, Id caseId) {
		List<CaseMilestone> output = (List<CaseMilestone>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(CaseMilestone.SObjectType, new Map<SObjectField, Object> {}, count), generateIds);

		for(Integer i = 0; i < output.size(); i++) {
			output[i] = (CaseMilestone)ApplicationTestDataFactory.setUnwritableFields(output[i], new Map<String, Object>{'MilestoneTypeId' => milestoneTypeId, 'CaseId' => caseId, 'StartDate' => Date.Today(), 'TargetDate' => Date.Today() + 365, 'IsViolated' => isViolated, 'IsCompleted' => isCompleted, 'CompletionDate' => (isCompleted ? Date.Today() + 10 : null)});
		}
		return output;
	}

	public static List<AgentWork> getAgentWorks(Integer count, Object /*List<Id>*/ userIds, Object /*List<Id>*/ workitemIds, Boolean generateIds) {
		return (List<AgentWork>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(AgentWork.SObjectType, new Map<SObjectField, Object> {
			AgentWork.UserId => userIds,
			AgentWork.WorkItemId => workitemIds
		}, count), generateIds);
	}

	public static List<ContactRequest> getContactRequests(Integer count, Object whatIds, Object whoIds, Boolean generateIds) {
		return (List<ContactRequest>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(ContactRequest.SObjectType, new Map<SObjectField, Object> {
				ContactRequest.WhatId => whatIds,
				ContactRequest.WhoId => whoIds
		}, count), generateIds);
	}

	public static List<VoiceCall> getVoiceCalls(List<Id> relatedRecordIds, Boolean generateIds) {
		List<VoiceCall> output = (List<VoiceCall>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(VoiceCall.SObjectType, new Map<SObjectField, Object> {
		}, relatedRecordIds.size()), generateIds);

		for(Integer i=0;i<relatedRecordIds.size();i++) {
			output[i] = (VoiceCall)ApplicationTestDataFactory.setUnwritableFields(output[i], new Map<String, Object>{'RelatedRecordId' => relatedRecordIds[0]});
		}

		return output;
	}

	public static List<LiveChatTranscript> getLiveChatTranscripts(Integer count, Object caseIds, Boolean generateIds) {
		return (List<LiveChatTranscript>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(LiveChatTranscript.SObjectType, new Map<SObjectField, Object> {
			LiveChatTranscript.CaseId => caseIds
		}, count), generateIds);
	}

	public static List<ImpactedArticle__c> getImpactedArticles(Integer count, Object caseIds, Object articleIds, Boolean generateIds) {
		return (List<ImpactedArticle__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(ImpactedArticle__c.SObjectType, new Map<SObjectField, Object> {
				ImpactedArticle__c.Article__c => articleIds,
				ImpactedArticle__c.Case__c => caseIds
		}, count), generateIds);
	}

	public static Id caseSSSWGeneralEnquiryRecordType {
		get {
			if(caseSSSWGeneralEnquiryRecordType == null) {
				caseSSSWGeneralEnquiryRecordType = [Select Id From RecordType Where SObjectType = 'Case' And DeveloperName = 'SSSWGeneralEnquiry'].Id;
			}
			return caseSSSWGeneralEnquiryRecordType;
		}
		private set;
	}
	
	public static Id caseSSSWDeliveryRecordType {
		get {
			if(caseSSSWDeliveryRecordType == null) {
				caseSSSWDeliveryRecordType = [Select Id From RecordType Where SObjectType = 'Case' And DeveloperName = 'SSSWDelivery'].Id;
			}
			return caseSSSWDeliveryRecordType;
		}
		private set;
	}
	
	public static Id caseStarTrackDeliveryEnquiryRecordType {
		get {
			if(caseStarTrackDeliveryEnquiryRecordType == null) {
				caseStarTrackDeliveryEnquiryRecordType = [Select Id From RecordType Where SObjectType = 'Case' And DeveloperName = 'StarTrack_PUD_Enquiry'].Id;
			  }
			  return caseStarTrackDeliveryEnquiryRecordType;
		 }
		 private set;
	}
	
   public static Id caseStarTrackVoiceOfCustRecordType {
	   get {
		   if(caseStarTrackVoiceOfCustRecordType == null) {
				caseStarTrackVoiceOfCustRecordType = [Select Id From RecordType Where SObjectType = 'Case' And DeveloperName = 'StarTrack_Voice_of_Customer'].Id;
			 }
			 return caseStarTrackVoiceOfCustRecordType;
		}
		private set;
   }

   public static Id caseStarTransitWarrantyClaimRecordType {
		get {
			if(caseStarTransitWarrantyClaimRecordType == null) {
				caseStarTransitWarrantyClaimRecordType = [Select Id From RecordType Where SObjectType = 'Case' And DeveloperName = 'StarTrack_Transit_Warranty_Claim'].Id;
			}
			return caseStarTransitWarrantyClaimRecordType;
		}
		private set;
	}
	
	public static Id casestarTrackGeneralEnquiryRecordType {
		get {
			if(casestarTrackGeneralEnquiryRecordType == null) {
				casestarTrackGeneralEnquiryRecordType = [Select Id From RecordType Where SObjectType = 'Case' And DeveloperName = 'StarTrack_General_Enquiry'].Id;
			}
			return casestarTrackGeneralEnquiryRecordType;
		}
		private set;
	}
	
	public static Id casestarTrackCreditDisputeRecordType {
		get {
			if(casestarTrackCreditDisputeRecordType == null) {
				casestarTrackCreditDisputeRecordType = [Select Id From RecordType Where SObjectType = 'Case' And DeveloperName = 'StarTrack_Credit_Dispute_Claim'].Id;
			}
			return casestarTrackCreditDisputeRecordType;
		}
		private set;
	}

	public static Id caseServiceDeliveryRecordType {
		get {
			if(caseServiceDeliveryRecordType == null) {
				caseServiceDeliveryRecordType = [Select Id From RecordType Where SObjectType = 'Case' And DeveloperName = 'Sales_Ops_Delivery'].Id;
			}
			return caseServiceDeliveryRecordType;
		}
		private set;
	}

	public static Id caseUnifiedInvestigationRecordType {
		get {
			if (caseUnifiedInvestigationRecordType == null) {
				caseUnifiedInvestigationRecordType = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('UnifiedInvestigation').getRecordTypeId();
			}
			return caseUnifiedInvestigationRecordType;
		}
		private set;
	}

}