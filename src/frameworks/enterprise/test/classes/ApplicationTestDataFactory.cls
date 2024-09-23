/**
 * @description Yet another Test data factory... hopefully the last one before a tidyup... eek!
 *
 * IMPORTANT - New methods for generating test data are to be added in a domain specific (e.g. SSSW, StarTrack) application
 *		   test data factory. Please refer PUDTestDataFactory for an example.
 *		   Test data helpers currently in this class will be incrementally moved to domain specific test data factories.
 *
 * @author Nathan Franklin
 * @date 2020-04-24
 * @group Tests
 * @tags mocking, apex mocks, tests, data factory, test data
 * @changelog
 * 2023-03-21 - Nathan Franklin - small refactor / adding record type for consumer
 * 2023-04-04 - Mahesh Parvathaneni - Added method getFeedComments
 * 2023-03-27 - Pratyush Chalasani - Added method to retrieve Lead BG Standard record type
 * 2023-05-25 - Nathan Franklin - Deprecated a bunch of case related methods (Use ApplicationTestDataFactoryCase moving forward)
 * 2023-05-11 - Mahesh Parvathaneni - Added methods getPostcodes/getPostcodeMappings/getNetworkBypasses
 * 2023-05-31 - Mahesh Parvathaneni - Added method getEmailToCaseMappings
 * 2023-06-30 - Pratyush Chalasani - Added getAdjustments
 * 2023-07-16 - SteveL- Added getEvents
 * 2023-07-20 - Mahesh Parvathaneni - Added method getBamApplications
 * 2023-08-09 - Mahesh Parvathaneni - Added method getNetworkMembers
 * 2023-09-22 - Ken McGuire - added methods for product revenue objects
 * 2024-04-17 - Deepak Kemidi - added method for creating vendor emails
 * 2024-07-19 - Nathan Franklin - resetting data factory due to some overwrites
*/
@IsTest
public with sharing class ApplicationTestDataFactory {

	public static List<Account> getAccounts(Integer count, Boolean generateIds) {
		return (List<Account>)maybeGenerateIds(populateSObjects(Account.SObjectType, new Map<SObjectField, Object> {
				Account.RecordTypeId => accountRecordType,
				Account.Name => 'Test Name %count%',
				Account.NumberOfEmployees => '%count%',
				Account.AnnualRevenue => 1000000,
				Account.Industry => 'Manufacturing'
		}, count), generateIds);
	}

	public static List<Billing_Account__c> getBillingAccounts(Integer count, Id accountId, String sourceSystem, Boolean generateIds) {
		return (List<Billing_Account__c>)maybeGenerateIds(populateSObjects(Billing_Account__c.SObjectType, new Map<SObjectField, Object> {
				Billing_Account__c.Organisation__c => accountId,
				Billing_Account__c.Name => 'Test Billing Account %count%',
				Billing_Account__c.Source_System__c => sourceSystem,
				Billing_Account__c.LEGACY_ID__c => (sourceSystem == 'TEAM' ? 'T' : (sourceSystem == 'PeopleSoft' ? 'P' : '')) + '%count%'
		}, count), generateIds);
	}

	public static List<APR__c> getAPRs(Integer count, Id billingAccountId, String type, Boolean generateIds) {
		return (List<APR__c>)maybeGenerateIds(populateSObjects(APR__c.SObjectType, new Map<SObjectField, Object> {
				APR__c.Billing_Account_Name__c => billingAccountId,
				APR__c.Type__c => type
		}, count), generateIds);
	}

	public static List<AssignmentRule> getAssignmentRules(Integer count, String objType, Boolean generateIds) {
		List<AssignmentRule> output = (List<AssignmentRule>)maybeGenerateIds(populateSObjects(Schema.SObjectType.AssignmentRule.SObjectType, new Map<SObjectField, Object> {
		}, count), generateIds);

		for(Integer i=0;i<output.size();i++) {
			output[i] = (AssignmentRule)setUnwritableFields(output[i], new Map<String, Object>{'SobjectType' => objType, 'Active' => true});
		}

		return output;
	}

	public static List<CaseInvestigation__c> getCaseInvestigations(Integer count, Set<Id> caseIds, Article__c article, Id networkId, Boolean generateIds) {
		return (List<CaseInvestigation__c>)maybeGenerateIds(populateSObjects(CaseInvestigation__c.SObjectType, new Map<SObjectField, Object> {
				CaseInvestigation__c.Case__c => caseIds,
				CaseInvestigation__c.Article__c => article == null ? null : article.Id,
				CaseInvestigation__c.ReferenceID__c => article == null ? null : article.Name,
				CaseInvestigation__c.Network__c => networkId
				}, count), generateIds);
	}

 	public static List<CaseInvestigation__c> getCaseInvestigations(Integer count, Id caseId, Article__c article, Id networkId, Boolean generateIds) {
		return (List<CaseInvestigation__c>)maybeGenerateIds(populateSObjects(CaseInvestigation__c.SObjectType, new Map<SObjectField, Object> {
				CaseInvestigation__c.Case__c => caseId,
				CaseInvestigation__c.Article__c => article == null ? null : article.Id,
				CaseInvestigation__c.ReferenceID__c => article == null ? null : article.Name,
				CaseInvestigation__c.Network__c => networkId
				}, count), generateIds);
	}

	public static List<Facility_User__c> getNetworkUsers(Integer count, Id networkId, Id userId, Boolean generateIds) {
		return (List<Facility_User__c>)maybeGenerateIds(populateSObjects(Facility_User__c.SObjectType, new Map<SObjectField, Object> {
				Facility_User__c.Network__c => networkId,
				Facility_User__c.User__c => userId
				}, count), generateIds);
	}

	public static List<NetworkMember> getNetworkMembers(Integer count, Id networkId, Id memberId, Boolean generateIds) {
		List<NetworkMember> output = (List<NetworkMember>)maybeGenerateIds(populateSObjects(NetworkMember.SObjectType, new Map<SObjectField, Object> {
				}, count), generateIds);

		for(Integer i = 0; i < output.size(); i++) {
			output[i] = (NetworkMember)setUnwritableFields(output[i], new Map<String, Object>{'NetworkId' => networkId, 'MemberId' => memberId});
		}

		return output;
	}

	public static List<FeedItem> getChatterFeeds(Integer count, Id parentId, Boolean generateIds) {
		return (List<FeedItem>)maybeGenerateIds(populateSObjects(FeedItem.SObjectType, new Map<SObjectField, Object> {
			FeedItem.ParentId => parentId
				}, count), generateIds);
	}

	public static List<FeedComment> getFeedComments(Integer count, Id parentId, Id feedItemId, Boolean generateIds) {
		List<FeedComment> output = (List<FeedComment>)maybeGenerateIds(populateSObjects(FeedComment.SObjectType, new Map<SObjectField, Object> {
			FeedComment.FeedItemId => feedItemId
			}, count), generateIds);

		for(Integer i = 0; i < output.size(); i++) {
			output[i] = (FeedComment)setUnwritableFields(output[i], new Map<String, Object>{'ParentId' => parentId});
		}

		return output;
	}

	public static List<Account> getPersonAccounts(Integer count, Boolean generateIds) {
		return (List<Account>)maybeGenerateIds(populateSObjects(Account.SObjectType, new Map<SObjectField, Object> {
				Account.RecordTypeId => personAccountRecordType,
				Account.FirstName => 'First Name %count%',
				Account.LastName => 'Last Name %count%',
				Account.PersonEmail => 'ZZtest%count%@test%count%.test%count%.com'
		}, count), generateIds);
	}
	
	public static List<Account> getFacilityAccounts(Integer count, Id networkId, Boolean generateIds) {
		return (List<Account>)maybeGenerateIds(populateSObjects(Account.SObjectType, new Map<SObjectField, Object> {
			Account.RecordTypeId => accountFacilityRecordType,
				Account.Name => 'Test Facility %count%',
				Account.Licence_Type__c => 'LPO',
				Account.Is_a_facility__c => true,
				Account.Network_Facility__c => networkId
				}, count), generateIds);
	}
	
	public static List<Account> getLPOAccounts(Integer count, Id parentId, Id facilityId, Boolean generateIds) {
		return (List<Account>)maybeGenerateIds(populateSObjects(Account.SObjectType, new Map<SObjectField, Object> {
			Account.RecordTypeId => accountLicenceRecordType,
				Account.Name => 'Test Licence %count%',
				Account.ParentId => parentId,
				Account.Licence_Type__c => 'LPO',
				Account.Facility__c => facilityId
				}, count), generateIds);
	}
	
	public static List<Network__c> getLPONetwork(Integer count, Boolean generateIds) {
		return (List<Network__c>)maybeGenerateIds(populateSObjects(Network__c.SObjectType, new Map<SObjectField, Object> {
			Network__c.Name => 'TestNetwork %count%',
				Network__c.Org_ID__c => '1234',
				Network__c.Org_Unit_Type__c => 'LPO',
				Network__c.Org_ID__c => '123456'
				}, count), generateIds);
	}

	public static List<Network__c> getNetworks(Integer count, Boolean generateIds) {
		return (List<Network__c>)maybeGenerateIds(populateSObjects(Network__c.SObjectType, new Map<SObjectField, Object> {
				Network__c.Name => 'TestNetwork %count%',
				Network__c.Network_manager__c => UserInfo.getUserId(),
				Network__c.State__c => 'VIC'
		}, count), generateIds);
	}

	public static List<Network_Response__c> getNetworkResponses(Integer count, Id networkId, Id relatedCasesId, Boolean generateIds) {
		return (List<Network_Response__c>)maybeGenerateIds(populateSObjects(Network_Response__c.SObjectType, new Map<SObjectField, Object> {
				Network_Response__c.Acting_Network__c => networkId,
				Network_Response__c.RelatedCase__c => relatedCasesId
		}, count), generateIds);
	}

	public static List<EventMessage__c> getEventMessages(Integer count, Id articleId, Boolean generateIds) {
		return (List<EventMessage__c>)maybeGenerateIds(populateSObjects(EventMessage__c.SObjectType, new Map<SObjectField, Object> {
				EventMessage__c.Article__c => articleId
		}, count), generateIds);
	}

	public static List<Attachment> getAttachments(Integer count, Id parentId, Boolean generateIds) {
		return (List<Attachment>)maybeGenerateIds(populateSObjects(Attachment.SObjectType, new Map<SObjectField, Object> {
				Attachment.ParentId => parentId,
				Attachment.Description => 'Attachment description',
				Attachment.Body => Blob.valueOf('body_%count%'),
				Attachment.Name => 'Attachment_%count%'
		}, count), generateIds);
	}
	
	public static List<ContentVersion> getContentVersions(Integer count, Id contentDocumentId, Boolean generateIds) {
		List<ContentVersion> output = (List<ContentVersion>)maybeGenerateIds(populateSObjects(ContentVersion.SObjectType, new Map<SObjectField, Object> {
			ContentVersion.RecordTypeId => contentVersionReportRecordType,
			ContentVersion.ContentLocation => 'S',
			ContentVersion.PathOnClient => 'conVer_%count%',
			ContentVersion.Title => 'conVer_%count%',
			ContentVersion.ContentDocumentId => contentDocumentId,
			ContentVersion.Document_Date__c => Date.valueOf('2020-10-05'),
			ContentVersion.Document_Interval__c => 'Weekly',
			ContentVersion.Document_Type__c => 'DIFOT'
		}, count), generateIds);

		for(Integer i = 0; i < output.size(); i++) {
			output[i] = (ContentVersion)setUnwritableFields(output[i], new Map<String, Object>{'VersionNumber' => 1});
			output[i].VersionData = Blob.valueOf('body_%count%');
		}

		return output;
	}

	public static List<ContentDocumentLink> getContentDocumentLinks(Integer count, Id linkedEntityId, Id contentDocumentId, Boolean generateIds) {
		return (List<ContentDocumentLink>)maybeGenerateIds(populateSObjects(ContentDocumentLink.SObjectType, new Map<SObjectField, Object> {
				ContentDocumentLink.LinkedEntityId => linkedEntityId,
				ContentDocumentLink.ContentDocumentId => contentDocumentId,
				ContentDocumentLink.Visibility => 'InternalUsers',
				ContentDocumentLink.ShareType => 'S'
		}, count), generateIds);
	}

	public static List<Membership__c> getMembership(Integer count, String stat, String licType,Id licenseId, Id memberId, Boolean generateIds) {
		return (List<Membership__c>)maybeGenerateIds(populateSObjects(Membership__c.SObjectType, new Map<SObjectField, Object> {
				Membership__c.Status__c => stat,
//			  Membership__c.ABN__c => '12345678910',
				Membership__c.Licensee_Type__c => licType,
				Membership__c.WCC__c => '123456',
				Membership__c.Contact__c => memberId,
				Membership__c.Account__c => licenseId,
				Membership__c.Date_Signed__c => System.TODAY(),
				Membership__c.APLAC_Welcome_Email_Sent__c => true,
				Membership__c.RecordTypeId => membershipAplacRecordType
		}, count), generateIds);
	}

	public static List<Contact> getContacts(Integer count, Id accountId, Boolean generateIds) {
		return (List<Contact>)maybeGenerateIds(populateSObjects(Contact.SObjectType, new Map<SObjectField, Object> {
				Contact.FirstName => 'First Name %count%',
				Contact.LastName => 'Last Name %count%',
				Contact.Email => 'ZZtest%count%@test%count%.test%count%.com',
				Contact.DoNotCall => true,
				Contact.AccountId => accountId
		}, count), generateIds);
	}

	public static List<Contact> getContacts(Integer count, Set<Id> accountIds, Boolean generateIds) {
		return (List<Contact>)maybeGenerateIds(populateSObjects(Contact.SObjectType, new Map<SObjectField, Object> {
				Contact.FirstName => 'First Name %count%',
				Contact.LastName => 'Last Name %count%',
				Contact.Email => 'ZZtest%count%@test%count%.test%count%.com',
				Contact.DoNotCall => true,
				Contact.AccountId => accountIds
		}, count), generateIds);
	}

	public static List<ContactPointAddress> getContactPointAddresses(Integer count, Id accountId, Boolean generateIds) {
		return (List<ContactPointAddress>)maybeGenerateIds(populateSObjects(ContactPointAddress.SObjectType, new Map<SObjectField, Object> {
			ContactPointAddress.Street => '%count%',
			ContactPointAddress.ParentId => accountId
		}, count), generateIds);
	}

	public static List<ContactPointPhone> getContactPointPhones(Integer count, Id accountId, Boolean generateIds) {
		return (List<ContactPointPhone>)maybeGenerateIds(populateSObjects(ContactPointPhone.SObjectType, new Map<SObjectField, Object> {
			ContactPointPhone.TelephoneNumber => '%count%',
			ContactPointPhone.ParentId => accountId
		}, count), generateIds);
	}

	public static List<ContactPointEmail> getContactPointEmails(Integer count, Id accountId, Boolean generateIds) {
		return (List<ContactPointEmail>)maybeGenerateIds(populateSObjects(ContactPointEmail.SObjectType, new Map<SObjectField, Object> {
			ContactPointEmail.EmailAddress => 'ZZtest%count%@test%count%.test%count%.com',
			ContactPointEmail.ParentId => accountId
		}, count), generateIds);
	}

	public static List<Lead> getLeads(Integer count, Boolean generateIds) {
		return (List<Lead>)maybeGenerateIds(populateSObjects(Lead.SObjectType, new Map<SObjectField, Object> {
				Lead.FirstName => 'First Name %count%',
				Lead.LastName => 'Last Name %count%',
				Lead.Email => 'ZZtest%count%@test%count%.test%count%.com',
				Lead.MobilePhone => '0444123456',
				Lead.LeadSource => 'Client'
		}, count), generateIds);
	}

	/**
	 * @deprecated ApplicationTestDataFactoryCases
	 */
	public static List<Case> getCases(Integer count, Boolean generateIds) {
		return (List<Case>)maybeGenerateIds(populateSObjects(Case.SObjectType, new Map<SObjectField, Object> {
				Case.Subject => 'Case Subject %count%',
				Case.Description => 'Case Description %count%',
				Case.Status => 'New'
		}, count), generateIds);
	}

	public static List<Case> getCases(Integer count, String referenceId , Boolean generateIds) {
		return (List<Case>)maybeGenerateIds(populateSObjects(Case.SObjectType, new Map<SObjectField, Object> {
				Case.ReferenceID__c => referenceId,
				Case.Subject => 'Case Subject %count%',
				Case.Description => 'Case Description %count%',
				Case.Status => 'New'
		}, count), generateIds);
	}

	// Added by Madhusudan
	public static List<Task> getTasks(Integer count, Id whatId, Boolean generateIds) {
		return (List<Task>)maybeGenerateIds(populateSObjects(Task.SObjectType, new Map<SObjectField, Object> {
				Task.WhatId => whatId,
				Task.Priority => 'New'
		}, count), generateIds);
	 }

	public static List<Event> getEvents(Integer count, Id whatId, Boolean generateIds) {
		return (List<Event>)maybeGenerateIds(populateSObjects(Event.SObjectType, new Map<SObjectField, Object> {
				Event.WhatId => whatId
		}, count), generateIds);
	}

	/**
	 * @deprecated ApplicationTestDataFactoryCases
	 */
	public static List<Case> getCases(Integer count, Set<Id> contactIds, Boolean generateIds) {
		return getCases(count, new List<Id>(contactIds), generateIds);
	}

	/**
	 * @deprecated ApplicationTestDataFactoryCases
	 */
	public static List<Case> getCases(Integer count, List<Id> contactIds, Boolean generateIds) {
		List<Case> output = (List<Case>)maybeGenerateIds(populateSObjects(Case.SObjectType, new Map<SObjectField, Object> {
				Case.Subject => 'Case Subject %count%',
				Case.Description => 'Case Description %count%',
				Case.Status => 'New',
				Case.ContactId => contactIds
		}, count), generateIds);

		for(Integer i = 0; i < output.size(); i++) {
			output[i] = (Case)setUnwritableFields(output[i], new Map<String, Object>{'IsClosed' => false});
		}

		return output;
	}

	/**
	 * @deprecated ApplicationTestDataFactoryCases
	 */
	public static List<CaseStatus> getCaseStatuses(Integer count, Boolean generateIds) {
		List<CaseStatus> output = (List<CaseStatus>)maybeGenerateIds(populateSObjects(CaseStatus.SObjectType, new Map<SObjectField, Object> {
		}, count), generateIds);

		for(Integer i = 0; i < output.size(); i++) {
			output[i] = (CaseStatus)setUnwritableFields(output[i], new Map<String, Object>{'ApiName' => 'Case Status ' + (i+1), 'MasterLabel' => 'Case Status ' + (i+1), 'IsClosed' => false});
		}

		return output;
	}

	public static List<Article__c> getArticles(Integer count, Boolean generateIds) {
		return getArticles(count, null, generateIds);
	}

	public static List<Article__c> getArticles(Integer count, Id consignmentId, Boolean generateIds) {
		List<Article__c> articles = getArticleConsignmentRecords(count, false, generateIds);
		for(Article__c article : articles) {
			article.Consignment__c = consignmentId;
		}
		return articles;
	}

	public static List<Article__c> getConsignments(Integer count, Boolean generateIds) {
		return getArticleConsignmentRecords(count, true, generateIds);
	}

	private static List<Article__c> getArticleConsignmentRecords(Integer count, Boolean isConsignment, Boolean generateIds) {
		return (List<Article__c>)maybeGenerateIds(populateSObjects(Article__c.SObjectType, new Map<SObjectField, Object> {
				Article__c.RecordTypeId => (isConsignment ? articleConsignmentRecordType.Id : articleArticleRecordType.Id),
				Article__c.ArticleID__c => (isConsignment ? 'CON' : 'ART') + '123%count%',
				Article__c.Name => (isConsignment ? 'CON' : 'ART') + '123%count%',
				Article__c.ExpectedDeliveryDate__c => Date.today(),
				Article__c.ArticleLodgementDate__c => Date.today(),
				Article__c.SenderPostcode__c => '3000',
				Article__c.ReceiverPostcode__c => '3002',
				Article__c.ArticleType__c => 'Regular Parcel',
				Article__c.ReceiverName__c => 'ReceiverFirstName%count% ReceiverLastName%count%',
				Article__c.ReceiverEmail__c => 'receiver-test%count%@test%count%.test%count%.com',
				Article__c.Receiver_APCN__c => '123',
				Article__c.Sender_APCN__c => '123456789',
				Article__c.SenderName__c => 'SenderFirstName%count% SenderLastName%count%',
				Article__c.SenderEmail__c => 'sender-test%count%@test%count%.test%count%.com',
				Article__c.ArticleLodgementDate__c => Date.today(),
				Article__c.ProductCategory__c => 'eParcel',
				Article__c.ArticleTransitAmountValue__c => 1,
				Article__c.SubProduct__c => 'eParcel Standard',
				Article__c.ActualWeight__c => 2,
				Article__c.DeliveryInstructions__c => '99bb'
		}, count), generateIds);
	}

	public static List<UserRole> getUserRoles(Integer count, Boolean generateIds) {
		return (List<UserRole>)maybeGenerateIds(populateSObjects(UserRole.SObjectType, new Map<SObjectField, Object> {
				UserRole.DeveloperName => 'UserRole_%count%'
		}, count), generateIds);
	}

	/**
	 * @deprecated ApplicationTestDataFactoryCases
	 */
	public static List<MiniCaseFieldMapping__c> getEnquiryTypeMappings(Boolean generateIds) {
		List<MiniCaseFieldMapping__c> mappings = new List<MiniCaseFieldMapping__c>{
				new MiniCaseFieldMapping__c(
						Id = (generateIds ? fflib_IDGenerator.generate(MiniCaseFieldMapping__c.SObjectType) : null),
						ProductCategory__c = 'Domestic Parcels',
						ProductSubcategory__c = 'eParcel- Regular',
						SAPProductCategory__c = 'eParcel',
						SAPProductSubcategory__c = 'eParcel Standard'
				),
				new MiniCaseFieldMapping__c(
						Id = (generateIds ? fflib_IDGenerator.generate(MiniCaseFieldMapping__c.SObjectType) : null),
						ProductCategory__c = 'Domestic Parcels',
						ProductSubcategory__c = 'StarTrack (Next Flight Premium & Express)',
						SAPProductCategory__c = 'StarTrack',
						SAPProductSubcategory__c = 'ST Next Flight'
				),
				new MiniCaseFieldMapping__c(
						Id = (generateIds ? fflib_IDGenerator.generate(MiniCaseFieldMapping__c.SObjectType) : null),
						ProductCategory__c = 'Domestic Parcels',
						ProductSubcategory__c = 'Express',
						SAPProductCategory__c = 'Express Post',
						SAPProductSubcategory__c = 'Express Post Medium'
				)
		};

		for(Integer i = 0; i < mappings.size(); i++) {
			mappings[i] = (MiniCaseFieldMapping__c)setUnwritableFields(mappings[i], new Map<String, Object>{'SAPKey__c' => mappings[i].SAPProductCategory__c + mappings[i].SAPProductSubcategory__c});
		}

		System.debug(mappings);

		return mappings;
	}


	public static List<Group> getGroups(Integer count, Boolean generateIds) {
		return getGroups(count, 'Queue', generateIds);
	}

	public static List<Group> getGroups(Integer count, String groupType, Boolean generateIds) {
		return (List<Group>)maybeGenerateIds(populateSObjects(Group.SObjectType, new Map<SObjectField, Object> {
				Group.DeveloperName => 'Group_%count%',
				Group.Name => 'Group %count%',
				Group.Email => 'ZZtest%count%@test%count%.test%count%.com',
				Group.Type => groupType
		}, count), generateIds);
	}

	public static List<GroupMember> getGroupMembers(Integer count, List<Id> groupIds, List<Id> userOrGroupIds, Boolean generateIds) {
		return (List<GroupMember>)maybeGenerateIds(populateSObjects(GroupMember.SObjectType, new Map<SObjectField, Object> {
				GroupMember.userOrGroupId => userOrGroupIds,
				GroupMember.GroupId => groupIds
		}, count), generateIds);
	}

	public static List<QueueRoutingConfig> getQueueRoutingConfigs(Integer count, Boolean generateIds) {
		return (List<QueueRoutingConfig>)maybeGenerateIds(populateSObjects(QueueRoutingConfig.SObjectType, new Map<SObjectField, Object> {
		}, count), generateIds);
	}

	public static List<User> getCommunityUsers(Integer count, List<Id> contactIds, Boolean generateIds) {
		return getCommunityUsers(count, contactIds, defaultCommunityUserProfileId, generateIds);
	}

	public static List<User> getCommunityUsers(Integer count, List<Id> contactIds, Id profileId, Boolean generateIds) {
		List<User> users = getUsers(count, profileId, generateIds);
		for(Integer i = 0; i < count; i++) {
			users[i].ContactId = contactIds[i];
		}
		return users;
	}

	public static List<User> getUsers(Integer count, Boolean generateIds) {
		return getUsers(count, defaultUserProfileId, generateIds);
	}

	public static List<User> getUsers(Integer count, Id profileId, Boolean generateIds) {
		List<User> output = (List<User>)maybeGenerateIds(populateSObjects(User.SObjectType, new Map<SObjectField, Object> {
				User.FirstName => 'First Name %count%',
				User.LastName => 'Last Name %count%',
				User.Username => 'ZZtest%count%@test%count%.test%count%.com',
				User.Email => 'ZZtest%count%@test%count%.test%count%.com',
				User.Alias => 'R12Z%count%',
				User.EmailEncodingKey => 'UTF-8',
				User.TimezoneSidKey => 'Australia/Sydney',
				User.LanguageLocaleKey => 'en_AU',
				User.LocaleSidKey => 'en_AU',
				User.ProfileId => profileId
		}, count), generateIds);

		for(Integer i=0;i<output.size();i++) {
			output[i] = (User)setUnwritableFields(output[i], new Map<String, Object>{'Name' => output[i].FirstName + ' ' + output[i].LastName});
		}

		return output;
	}

	public static List<Asset> getPSRAssignedAssets(Integer count, Id accId, Id prodId, Boolean toBeProcessed, Date freezeStartDate, Date freezeEndDate, String status, Boolean generateIds){
		return (List<Asset>)maybeGenerateIds(populateSObjects(Asset.SObjectType, new Map<SObjectField, Object> {
				Asset.Name => 'PSR',
				Asset.AccountId => accId,
				Asset.Product2Id => prodId,
				Asset.RecordTypeId => assetPSRRecordType,
				Asset.Tier_Type__c => 'Assigned',
				Asset.To_Be_Processed__c => toBeProcessed,
				Asset.Freeze_Period_Start_Date__c =>freezeStartDate,
				Asset.Freeze_Period_End_Date__c => freezeEndDate,
				Asset.Status => status
		}, count), generateIds);
	}

	public static List<Asset> getPSRTransactionalAssets(Integer count, Id accId, Id prodId, Boolean toBeProcessed, String status, Boolean generateIds){
		return (List<Asset>)maybeGenerateIds(populateSObjects(Asset.SObjectType, new Map<SObjectField, Object> {
				Asset.Name => 'PSR',
				Asset.AccountId => accId,
				Asset.Product2Id => prodId,
				Asset.RecordTypeId => assetPSRRecordType,
				Asset.Tier_Type__c => 'Transactional',
				Asset.To_Be_Processed__c => toBeProcessed,
				Asset.Status => status
		}, count), generateIds);
	}

	public static List<Product2> getPSRProducts(Integer count, Boolean generateIds) {
		return (List<Product2>)maybeGenerateIds(populateSObjects(Product2.SObjectType, new Map<SObjectField, Object> {
				Product2.Name => 'Band%count%',
				Product2.Family => 'Parcel Sending Rewards',
				Product2.Product_Hierarchy_Value__c => '%count%'
		}, count), generateIds);
	}

	public static List<Active_Band_History__c> getActiveBandHistories(Integer count, Id accountId, Id bandValue, String bandType, Boolean generateIds) {
		return (List<Active_Band_History__c>)maybeGenerateIds(populateSObjects(Active_Band_History__c.SObjectType, new Map<SObjectField, Object> {
				Active_Band_History__c.Offer_type__c => 'PSR',
				Active_Band_History__c.Band_Type__c => bandType,
				Active_Band_History__c.Band_Value__c => bandValue,
				Active_Band_History__c.Organisation__c => accountId,
				Active_Band_History__c.Change_Date__c => System.today()
		}, count), generateIds);
	}
	public static List<Opportunity> getOpportunities(integer count, Id accountId, Boolean generateIds){
		return (List<Opportunity>)maybeGenerateIds(populateSObjects(Opportunity.SObjectType, new Map<SObjectField, Object> {
			Opportunity.RecordTypeId => simpleOpportunityRecordType,
			Opportunity.Name => 'test opportunity %count%',
			Opportunity.Type => 'New Customer',
			Opportunity.Offering_Type__c => 'Product',
			Opportunity.StageName => 'Identify',
			Opportunity.CloseDate => date.Today().addDays(365),
			Opportunity.AccountId =>accountId
		}, count), generateIds);
	}
	public static List<Opportunity> getOpportunities(integer count, set<Id> accountIds, Boolean generateIds){
		return (List<Opportunity>)maybeGenerateIds(populateSObjects(Opportunity.SObjectType, new Map<SObjectField, Object> {
			Opportunity.RecordTypeId => simpleOpportunityRecordType,
			Opportunity.Name => 'test opportunity %count%',
			Opportunity.Type => 'New Customer',
			Opportunity.Offering_Type__c => 'Product',
			Opportunity.StageName => 'Identify',
			Opportunity.CloseDate => date.Today().addDays(365),
			Opportunity.AccountId =>accountIds
		}, count), generateIds);
	}
	public static List<OpportunitySplit> getOpportunitySplits(integer count, Id opportunityId, Id userId,Id splitypeIdVar, String overlayType, Boolean generateIds){
		System.debug('overlayType>>>>>>>'+overlayType);
		return (List<OpportunitySplit>)maybeGenerateIds(populateSObjects(OpportunitySplit.SObjectType, new Map<SObjectField, Object> {
			OpportunitySplit.SplitTypeId => splitypeIdVar,
			OpportunitySplit.Overlay_Type__c => overlayType,
			OpportunitySplit.OpportunityId => opportunityId,
			OpportunitySplit.SplitOwnerId => userId
		}, count), generateIds);
	}
	public static List<OpportunityTeamMember> getOpportunityTeamMembers(integer count, Id opportunityId, Id userId, String teamMemberRole, String opportunityAccessLevelVar, Boolean generateIds){
		return (List<OpportunityTeamMember>)maybeGenerateIds(populateSObjects(OpportunityTeamMember.SObjectType, new Map<SObjectField, Object> {
			OpportunityTeamMember.opportunityId => opportunityId,
			OpportunityTeamMember.userId => userId,
			OpportunityTeamMember.teamMemberRole => teamMemberRole,
			OpportunityTeamMember.OpportunityAccessLevel => opportunityAccessLevelVar
		}, count), generateIds);
	}
	public static List<OpportunityShare> getOpportunityShares(integer count, Id opportunityId, Id userOrGroupId, String opportunityAccessLevelVar, Boolean generateIds){
		return (List<OpportunityShare>)maybeGenerateIds(populateSObjects(OpportunityShare.SObjectType, new Map<SObjectField, Object> {
			OpportunityShare.opportunityId => opportunityId,
			OpportunityShare.userOrGroupId => userOrGroupId,
			OpportunityShare.OpportunityAccessLevel => opportunityAccessLevelVar
		}, count), generateIds);
	}

	public static List<Opp_Product_Classification__c> getOpportunityProductClassification(Integer count, Id accountId, Id oppId, boolean currentYear, String fYear, Boolean generateIds) {
		List<Opp_Product_Classification__c> opcList;
			opcList = (List<Opp_Product_Classification__c>)populateSObjects(Opp_Product_Classification__c.SObjectType, new Map<SObjectField, Object> {
			Opp_Product_Classification__c.Account__c => accountId,
			Opp_Product_Classification__c.Opportunity__c => oppId,
			Opp_Product_Classification__c.Financial_Year__c => fYear,
			Opp_Product_Classification__c.Jan_Schedule_Amount__c => 1000,
			Opp_Product_Classification__c.Jan_Actual_Amount__c => 1000,
			Opp_Product_Classification__c.Feb_Schedule_Amount__c => 1000,
			Opp_Product_Classification__c.Feb_Actual_Amount__c => 1000,
			Opp_Product_Classification__c.Mar_Schedule_Amount__c => 1000,
			Opp_Product_Classification__c.Mar_Actual_Amount__c => 1000,
			Opp_Product_Classification__c.Apr_Schedule_Amount__c => 1000,
			Opp_Product_Classification__c.Apr_Actual_Amount__c => 1000,
			Opp_Product_Classification__c.May_Schedule_Amount__c => 1000,
			Opp_Product_Classification__c.May_Actual_Amount__c => 1000,
			Opp_Product_Classification__c.Jun_Schedule_Amount__c => 1000,
			Opp_Product_Classification__c.Jun_Actual_Amount__c => 1000,
			Opp_Product_Classification__c.Jul_Schedule_Amount__c => 1000,
			Opp_Product_Classification__c.Jul_Actual_Amount__c => 1000,
			Opp_Product_Classification__c.Aug_Schedule_Amount__c => 1000,
			Opp_Product_Classification__c.Aug_Actual_Amount__c => 1000,
			Opp_Product_Classification__c.Sep_Schedule_Amount__c => 1000,
			Opp_Product_Classification__c.Sep_Actual_Amount__c => 1000,
			Opp_Product_Classification__c.Oct_Schedule_Amount__c => 1000,
			Opp_Product_Classification__c.Oct_Actual_Amount__c => 1000,
			Opp_Product_Classification__c.Nov_Schedule_Amount__c => 1000,
			Opp_Product_Classification__c.Nov_Actual_Amount__c => 1000,
			Opp_Product_Classification__c.Dec_Schedule_Amount__c => 1000,
			Opp_Product_Classification__c.Dec_Actual_Amount__c => 1000
		}, count);
		opcList = (List<Opp_Product_Classification__c>)maybeGenerateIds(opcList, generateIds);
		return opcList;
	}
	
	public static List<APT_Credit_Assessment__c> getApttusCreditsAssessment(integer count, Id chargeAccountId, Boolean generateIds){
		return (List<APT_Credit_Assessment__c>)maybeGenerateIds(populateSObjects(APT_Credit_Assessment__c.SObjectType, new Map<SObjectField, Object> {
			APT_Credit_Assessment__c.APT_Legal_Entity_Name__c => 'TestLegalEntity',
			APT_Credit_Assessment__c.APT_Charge_Account__c => chargeAccountId
		}, count), generateIds);
	}
	public static List<APT_Charge_Account__c> getApttusChargeAccountRequest(integer count, Boolean generateIds){
		return (List<APT_Charge_Account__c>)maybeGenerateIds(populateSObjects(APT_Charge_Account__c.SObjectType, new Map<SObjectField, Object> {
			APT_Charge_Account__c.APT_Company_Name__c => 'TestLegalEntity',
			APT_Charge_Account__c.Status__c => 'New'
		}, count), generateIds);
	}
	public static List<Apttus_Proposal__Proposal__c> getApttusProposals(integer count, Id primaryContactId, Boolean generateIds){
		return (List<Apttus_Proposal__Proposal__c>)maybeGenerateIds(populateSObjects(Apttus_Proposal__Proposal__c.SObjectType, new Map<SObjectField, Object> {
			Apttus_Proposal__Proposal__c.Apttus_Proposal__Primary_Contact__c => primaryContactId,
			Apttus_Proposal__Proposal__c.Apttus_Proposal__Proposal_Expiration_Date__c => date.Today().addDays(365)
		}, count), generateIds);
	}
	public static List<Apttus__APTS_Agreement__c> getApttusContracts(integer count, Id primaryContactId, Id relatedOpportunityId, Boolean generateIds){
		return (List<Apttus__APTS_Agreement__c>)maybeGenerateIds(populateSObjects(Apttus__APTS_Agreement__c.SObjectType, new Map<SObjectField, Object> {
			Apttus__APTS_Agreement__c.Name => 'testApttusContract',
			Apttus__APTS_Agreement__c.Apttus__Primary_Contact__c => primaryContactId,
			Apttus__APTS_Agreement__c.Apttus__Related_Opportunity__c => relatedOpportunityId,		  
			Apttus__APTS_Agreement__c.Apttus__Contract_Start_Date__c => date.Today(),
			Apttus__APTS_Agreement__c.RecordTypeId =>  Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('MSA & Service Schedule').getRecordTypeId(),
			Apttus__APTS_Agreement__c.Apttus__Agreement_Category__c => APT_Constants.NETWORK_TYPE_STANDARD
		}, count), generateIds);
	}
	public static List<APT_Agreement_Lodgement_Point__c> getAgreementLodgementPoints(integer count, Id networkId, Id apttusContractId, Id accountId, Boolean generateIds){
		return (List<APT_Agreement_Lodgement_Point__c>)maybeGenerateIds(populateSObjects(APT_Agreement_Lodgement_Point__c.SObjectType, new Map<SObjectField, Object> {
			APT_Agreement_Lodgement_Point__c.APT_Lodgement_Point_Lookup__c => networkId,
			APT_Agreement_Lodgement_Point__c.APT_Agreement__c => apttusContractId,
			APT_Agreement_Lodgement_Point__c.APT_Organisation__c => accountId
		}, count), generateIds);
	}
	
	public static List<Deal_Support_Request__c> getDealSupportRequests(integer count, Id opportunityId, Id organisationId, Boolean generateIds){
		return (List<Deal_Support_Request__c>)maybeGenerateIds(populateSObjects(Deal_Support_Request__c.SObjectType, new Map<SObjectField, Object> {
			Deal_Support_Request__c.Opportunity__c => opportunityId,
			Deal_Support_Request__c.Organisation__c => organisationId
		}, count), generateIds);
	}
	public static List<BAMExternalOnboardingRequest__c> getBAMExternalOnboardingRequests(integer count, Id requestObjId, String objectName, Boolean generateIds){
		return (List<BAMExternalOnboardingRequest__c>)maybeGenerateIds(populateSObjects(BAMExternalOnboardingRequest__c.SObjectType, new Map<SObjectField, Object> {
			BAMExternalOnboardingRequest__c.Request_Object_Id__c => requestObjId,
			BAMExternalOnboardingRequest__c.Request_Object_Name__c => objectName
		}, count), generateIds);
	}   
	public static List<Holding_Role_Reference__c> getHoldingRoleRef(Integer count, Boolean generateIds){
		return (List<Holding_Role_Reference__c>)maybeGenerateIds(populateSObjects(Holding_Role_Reference__c.SObjectType, new Map<SObjectField, Object> {
				Holding_Role_Reference__c.Name => 'New Accounts'
		}, count), generateIds);
	}

	public static List<SSSWRouting__c> getSSSWRoutings(integer count, Id recTypeId, String creditPersonCode, String creditRepEmail, String dsrQueueName, String dsrRoutingType, Boolean generateIds){
		return (List<SSSWRouting__c>)maybeGenerateIds(populateSObjects(SSSWRouting__c.SObjectType, new Map<SObjectField, Object> {
			SSSWRouting__c.RecordTypeId => recTypeId,
			SSSWRouting__c.Credit_Person_Code__c => creditPersonCode,
			SSSWRouting__c.Credit_Representative_Email__c => creditRepEmail,
			SSSWRouting__c.DSR_Queue_Name__c => dsrQueueName,
			SSSWRouting__c.Credit_DSR_Routing__c => dsrRoutingType
		}, count), generateIds);
	}
	
	public static List<BulkLoadRequest__c> getBulkLoadRequests(Integer count, Boolean generateIds) {
		return (List<BulkLoadRequest__c>) maybeGenerateIds(populateSObjects(BulkLoadRequest__c.SObjectType, new Map<SObjectField, Object> {
			BulkLoadRequest__c.FileName__c => 'testfile%count%.csv',
			BulkLoadRequest__c.Status__c => 'New'
		}, count), generateIds);
	}

	public static List<BulkLoadRequestLineItem__c> getBulkLoadRequestLineItems(Integer count, Id bulkLoadRequestId, Boolean generateIds) {
		return (List<BulkLoadRequestLineItem__c>) maybeGenerateIds(populateSObjects(BulkLoadRequestLineItem__c.SObjectType, new Map<SObjectField, Object> {
			BulkLoadRequestLineItem__c.BulkLoadRequest__c => bulkLoadRequestId,
			BulkLoadRequestLineItem__c.LineNumber__c => '%count%',
			BulkLoadRequestLineItem__c.Status__c => 'New',
			BulkLoadRequestLineItem__c.LineItemPayload__c => '{}'
		}, count), generateIds);
	}

	public static List<Disputed_Item__c> getDisputedItems(Integer count, Id caseId, Boolean generateIds) {
		return (List<Disputed_Item__c>) maybeGenerateIds(populateSObjects(Disputed_Item__c.SObjectType, new Map<SObjectField, Object> {
			Disputed_Item__c.Case__c => caseId,
			Disputed_Item__c.Invoice_Number__c => 'testinvoice%count%'
		}, count), generateIds);
	}

	public static List<Credit_Approval__c> getCreditApprovals(Integer count, Boolean generateIds) {

		return (List<Credit_Approval__c>) maybeGenerateIds(populateSObjects(Credit_Approval__c.SObjectType, new Map<SObjectField, Object> {
				Credit_Approval__c.Status__c => 'New'
		}, count), generateIds);
	}

	public static List<CreditApprovalMatrix__c> getCreditApprovalMatrixRecords(Integer count, Boolean generateIds, String creditType, String productFamily, String productSubCategory) {

		return (List<CreditApprovalMatrix__c>) maybeGenerateIds(populateSObjects(CreditApprovalMatrix__c.SObjectType, new Map<SObjectField, Object> {
				CreditApprovalMatrix__c.CreditType__c => creditType,
				CreditApprovalMatrix__c.Product_Family__c => productFamily,
				CreditApprovalMatrix__c.Product_Sub_Category__c => productSubCategory
		}, count), generateIds);
	}

	public static List<EmailTemplate> getVFEmailTemplate(integer count, String name, String developername, String subject, String htmlValue, String body, String markup, Boolean generateIds){
		return (List<EmailTemplate>)maybeGenerateIds(populateSObjects(EmailTemplate.SObjectType, new Map<SObjectField, Object> {
			EmailTemplate.name => name,
			EmailTemplate.developername => developername,
			EmailTemplate.Subject => subject,
			EmailTemplate.HtmlValue => htmlValue,
			EmailTemplate.Body => body,
			EmailTemplate.MarkUp => markup,
			EmailTemplate.TemplateType => 'visualforce',
			EmailTemplate.FolderId => UserInfo.getUserId()
		}, count), generateIds);
	}
	
	public static List<OrgWideEmailAddress> getOrgWideEmail(integer count, String name, String address,Boolean generateIds){
		return (List<OrgWideEmailAddress>)maybeGenerateIds(populateSObjects(OrgWideEmailAddress.SObjectType, new Map<SObjectField, Object> {
			OrgWideEmailAddress.DisplayName => name,
			OrgWideEmailAddress.Address => address
		}, count), generateIds);
	}

	public static List<APT_Sub_Account__c> getSubAccountRequest(integer count, String name , Boolean generateIds){
		return (List<APT_Sub_Account__c>)maybeGenerateIds(populateSObjects(APT_Sub_Account__c.SObjectType, new Map<SObjectField, Object> {
				APT_Sub_Account__c.Name => name
		}, count), generateIds);
	}

	public static List<Qualification_Response_Detail__c> getQualificationResponseDetail(integer count, String question, Id qcd, Boolean generateIds){
		return (List<Qualification_Response_Detail__c>)maybeGenerateIds(populateSObjects(Qualification_Response_Detail__c.SObjectType, new Map<SObjectField, Object> {
			Qualification_Response_Detail__c.Qualification_Category_Detail__c => qcd,
			Qualification_Response_Detail__c.Question__c => question
		}, count), generateIds);
	}
	//Added by Asha | MW0004779
	public static List<Entitlement> getEntitlements(Integer count, Boolean generateIds,String entitlementName, Id slaId, Id accountId) {
		return (List<Entitlement>)maybeGenerateIds(populateSObjects(Entitlement.SObjectType, new Map<SObjectField, Object> {
				Entitlement.SlaProcessId => slaId,
				Entitlement.AccountId => accountId,
				Entitlement.Name => entitlementName,
				Entitlement.StartDate => Date.Today(),
				Entitlement.EndDate => Date.Today() + 365,
				Entitlement.Type => 'Phone Support'
		}, count), generateIds);
	}

	public static List<Entitlement_Rule__c> getEntitlementRules(Integer count, String ruleName, Id escHierarchyId, Boolean generateIds) {
		return (List<Entitlement_Rule__c>)maybeGenerateIds(populateSObjects(Entitlement_Rule__c.SObjectType, new Map<SObjectField, Object> {
				Entitlement_Rule__c.Entitlement_Rule_Name__c => ruleName,
				Entitlement_Rule__c.Escalation_Hierarchy__c => escHierarchyId,
				Entitlement_Rule__c.Active__c => true
		}, count), generateIds);
	}
	
	public static List<Escalation_Hierarchy__c> getEscalationHierarchies(Integer count, String name, Boolean generateIds) {
		return (List<Escalation_Hierarchy__c>)maybeGenerateIds(populateSObjects(Escalation_Hierarchy__c.SObjectType, new Map<SObjectField, Object> {
				Escalation_Hierarchy__c.Name => name
		}, count), generateIds);
	}
	
	/**
	 * @deprecated ApplicationTestDataFactoryCases
	 */
	public static List<EmailMessage> getEmailMessages(Integer count, Boolean generateIds,Boolean isIncoming, String fromAddress, String toAddress, String subject, Id caseId) {
		return getEmailMessages(count, generateIds, isIncoming, fromAddress, toAddress, null, null, subject, caseId);
	}

	/**
	 * @deprecated ApplicationTestDataFactoryCases
	 */
	public static List<EmailMessage> getEmailMessages(Integer count, Boolean generateIds,Boolean isIncoming, String fromAddress, String toAddress, String ccAddress, String bccAddress, String subject, Id caseId) {
		return (List<EmailMessage>)maybeGenerateIds(populateSObjects(EmailMessage.SObjectType, new Map<SObjectField, Object> {
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

	/**
	 * @deprecated ApplicationTestDataFactoryCases
	 */
	public static List<MilestoneType> getMilestoneTypes(Integer count, Boolean generateIds) {
		return (List<MilestoneType>)maybeGenerateIds(populateSObjects(MilestoneType.SObjectType, new Map<SObjectField, Object> {
				MilestoneType.Name => 'Milestone Name %count%',
				MilestoneType.Description => 'Milestone Description %count%'
		}, count), generateIds);
	}

	/**
	 * @deprecated ApplicationTestDataFactoryCases
	 */
	public static List<CaseMilestone> getCaseMilestones(Integer count, Boolean generateIds,Boolean isViolated, Boolean isCompleted, Id milestoneTypeId, Id caseId) {
		List<CaseMilestone> output = (List<CaseMilestone>)maybeGenerateIds(populateSObjects(CaseMilestone.SObjectType, new Map<SObjectField, Object> {}, count), generateIds);

		for(Integer i = 0; i < output.size(); i++) {
			output[i] = (CaseMilestone)setUnwritableFields(output[i], new Map<String, Object>{'MilestoneTypeId' => milestoneTypeId, 'CaseId' => caseId, 'StartDate' => Date.Today(), 'TargetDate' => Date.Today() + 365, 'IsViolated' => isViolated, 'IsCompleted' => isCompleted, 'CompletionDate' => (isCompleted ? Date.Today() + 10 : null)});
		}
		return output;
	}

	public static List<Postcode__c> getPostcodes(Integer count, Boolean generateIds) {
		return (List<Postcode__c>)maybeGenerateIds(populateSObjects(Postcode__c.SObjectType, new Map<SObjectField, Object> {
			Postcode__c.Name => 'Postcode %count%',
			Postcode__c.Suburb__c => 'Suburb %count%'
		}, count), generateIds);
	}

	public static List<PostcodeMapping__c> getPostcodeMappings(Integer count, Id postcodeId, Id networkId, Boolean generateIds) {
		return (List<PostcodeMapping__c>)maybeGenerateIds(populateSObjects(PostcodeMapping__c.SObjectType, new Map<SObjectField, Object> {
				PostcodeMapping__c.Postcode__c => postcodeId,
				PostcodeMapping__c.Network__c => networkId
		}, count), generateIds);
	}

	public static List<FacilityByPass__c> getNetworkBypasses(Integer count, Id fromNetworkId, Id toNetworkId, Boolean generateIds) {
		return (List<FacilityByPass__c>)maybeGenerateIds(populateSObjects(FacilityByPass__c.SObjectType, new Map<SObjectField, Object> {
				FacilityByPass__c.Facility_By_Pass_From__c => fromNetworkId,
				FacilityByPass__c.Facility_By_Pass_To__c => toNetworkId
		}, count), generateIds);
	}

	public static List<EmailToCaseMapping__mdt> getEmailToCaseMappings(Integer count, String emailAddress, Boolean generateIds) {
		return (List<EmailToCaseMapping__mdt>)maybeGenerateIds(populateSObjects(EmailToCaseMapping__mdt.SObjectType, new Map<SObjectField, Object> {
			EmailToCaseMapping__mdt.DeveloperName => 'RECORD%count%',
			EmailToCaseMapping__mdt.IsActive__c => true,
			EmailToCaseMapping__mdt.EmailToCaseAddress__c => emailAddress
		}, count), generateIds);
	}

	public static List<Adjustment__c> getAdjustments(Integer count, Id caseId, Boolean generateIds) {
		return (List<Adjustment__c>) maybeGenerateIds(populateSObjects(Adjustment__c.SObjectType, new Map<SObjectField, Object> {
			Adjustment__c.Status__c => 'New',
			Adjustment__c.Case__c => caseId
		}, count), generateIds);
	}

	public static List<At_Risk_Business__c> getAtRiskBusiness(Integer count, Id accountId, Boolean generateIds) {
		return (List<At_Risk_Business__c>) maybeGenerateIds(populateSObjects(At_Risk_Business__c.SObjectType, new Map<SObjectField, Object> {
			At_Risk_Business__c.Legal_Entity_Name__c => accountId
		}, count), generateIds);
	}

	public static List<Budget_And_Revenue__c> getBudgetAndRevenue(Integer count, Id accountId, Boolean generateIds) {
		return getBudgetAndRevenue(count, accountId, null, null, generateIds);
	}

	public static List<Budget_And_Revenue__c> getBudgetAndRevenue(Integer count, Id accountId, Id productId, Integer financialYear, Boolean generateIds) {
		return (List<Budget_And_Revenue__c>) maybeGenerateIds(populateSObjects(Budget_And_Revenue__c.SObjectType, new Map<SObjectField, Object> {
			Budget_and_Revenue__c.Organisation__c => accountId,
			Budget_and_Revenue__c.Product__c => productId,
			Budget_and_Revenue__c.Financial_Year__c => String.ValueOf(financialYear),
			Budget_and_Revenue__c.Transaction_Type__c => 'REVENUE',
			Budget_and_Revenue__c.Jan_Revenue_Amount__c => 1000,
			Budget_and_Revenue__c.Feb_Revenue_Amount__c => 1000,
			Budget_and_Revenue__c.Mar_Revenue_Amount__c => 1000,
			Budget_and_Revenue__c.Apr_Revenue_Amount__c => 1000,
			Budget_and_Revenue__c.May_Revenue_Amount__c => 1000,
			Budget_and_Revenue__c.Jun_Revenue_Amount__c => 1000,
			Budget_and_Revenue__c.Jul_Revenue_Amount__c => 1000,
			Budget_and_Revenue__c.Aug_Revenue_Amount__c => 1000,
			Budget_and_Revenue__c.Sep_Revenue_Amount__c => 1000,
			Budget_and_Revenue__c.Oct_Revenue_Amount__c => 1000,
			Budget_and_Revenue__c.Nov_Revenue_Amount__c => 1000,
			Budget_and_Revenue__c.Dec_Revenue_Amount__c => 1000
		}, count), generateIds);
	}
	


	public static List<Product2> getProducts(Integer count, Boolean generateIds) {
		return (List<Product2>) maybeGenerateIds(populateSObjects(Product2.SObjectType, new Map<SObjectField, Object> {
			Product2.Name => 'Product %count%'
		}, count), generateIds);
	}

    public static List<PricebookEntry> getPriceBookEntries(Integer count, Id productId, Boolean generateIds) {
        Id pricebookId = Test.getStandardPricebookId();
        return (List<PricebookEntry>) maybeGenerateIds(populateSObjects(PricebookEntry.SObjectType, new Map<SObjectField, Object> {
            PricebookEntry.Pricebook2Id => pricebookId,
            PricebookEntry.Product2Id => productId,
            PricebookEntry.UnitPrice => 100.00,
            PricebookEntry.IsActive => true
        }, count), generateIds);
    }

	public static List<OpportunityLineItem> getOpportunityLineItems(Integer count, Id opportunityId, Id pricebookEntryId, Boolean generateIds) {
		Date todaysDate = Date.today();
		return (List<OpportunityLineItem>) maybeGenerateIds(populateSObjects(OpportunityLineItem.SObjectType, new Map<SObjectField, Object> {
			OpportunityLineItem.OpportunityId => opportunityId,
			OpportunityLineItem.PricebookEntryId => pricebookEntryId,
			OpportunityLineItem.TotalPrice => 1000,
			OpportunityLineItem.Contract_Start_Date__c => todaysDate,
			OpportunityLineItem.Contract_End_Date__c => todaysDate.addDays(3)
		}, count), generateIds);
	}

	public static List<BAMApplication__c> getBamApplications(Integer count, String appName, Id productId, Boolean generateIds) {
		return (List<BAMApplication__c>)maybeGenerateIds(populateSObjects(BAMApplication__c.SObjectType, new Map<SObjectField, Object> {
			BAMApplication__c.Name => appName,
			BAMApplication__c.ConfigurationModel__c => 'Per Customer',
			BAMApplication__c.Status__c => 'Active',
			BAMApplication__c.Product__c =>  productId,
			BAMApplication__c.appKey__c => appName.substring(0,Math.min(appName.length(), 9)),
			BAMApplication__c.ServiceType__c =>  'Salesforce'
		}, count), generateIds);
	}

	public static List<BAMApplicationRole__c> getBamApplicationRoles(Integer count, String roleName, Id appId, Boolean generateIds) {
        return (List<BAMApplicationRole__c>)maybeGenerateIds(populateSObjects(BAMApplicationRole__c.SObjectType, new Map<SObjectField, Object> {
                BAMApplicationRole__c.Role__c => roleName,
                BAMApplicationRole__c.Application__c => appId,
                BAMApplicationRole__c.ShowBillingAccount__c => true,
                BAMApplicationRole__c.ShowGroup__c =>  true,
                BAMApplicationRole__c.ShowOrganisation__c => true,
                BAMApplicationRole__c.status__c =>  'Active'
        }, count), generateIds);
    }

    public static List<BAMContactRole__c> getBamContactRoles(Integer count, String roleId, Id appId, Boolean generateIds) {
        return (List<BAMContactRole__c>)maybeGenerateIds(populateSObjects(BAMContactRole__c.SObjectType, new Map<SObjectField, Object> {
                BAMContactRole__c.ContactApplication__c => appId,
                BAMContactRole__c.ApplicationRole__c => roleId,
                BAMContactRole__c.status__c =>  'Active'
        }, count), generateIds);
    }

    public static List<BAMContactApplication__c> getBamContactApplications(Integer count, Id contactId, Id appId, Boolean generateIds) {
        return (List<BAMContactApplication__c>)maybeGenerateIds(populateSObjects(BAMContactApplication__c.SObjectType, new Map<SObjectField, Object> {
                BAMContactApplication__c.Contact__c => contactId,
                BAMContactApplication__c.Application__c => appId,
                BAMContactApplication__c.Status__c => 'Active'
        }, count), generateIds);
    }

	public static void generateRecordIds(List<SObject> records) {
		for(SObject record : records) {
			record.Id = fflib_IDGenerator.generate(record.getSObjectType());
		}
	}

	/**
	 * This little hack, idea courtesy of Andy Fawcett, will enable us to put values into fields that are not writeable for the purposes of mocking data without using DML operations
	 * An example of such a construct is .Owner on the SObject. The OwnerId field is writable, but we are unable to set the .Owner value (i suppose because it's automatically populated after calling a soql)
	 * NOTE: Not all relationship fields are unwritable, however, for the ones that are.... this method can be used.
	 * I would imagine this is not very performant, however, I'm sure it still trumps doing actual DML and SOQL operations
	 *
	 * NOTE: That Blobs (Attachment.Body for example) do not work with serialisation. Values should be nulled and reset after if you run into problems
	 */
	public static SObject setUnwritableFields(SObject record, Map<String, Object> relationshipFields) {
		Map<String, Object> recordAsMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(record));
		for(String key : relationshipFields.keySet()) {
			recordAsMap.put(key, relationshipFields.get(key));
		}

		System.debug(recordAsMap);
		return (SObject)JSON.deserialize(JSON.serialize(recordAsMap), SObject.class);
	}

	/**
	 * This little hack, idea courtesy of Andy Fawcett, will enable us to put values into fields that are not writeable for the purposes of mocking data without using DML operations
	 * An example of such a construct is .Owner on the SObject. The OwnerId field is writable, but we are unable to set the .Owner value (i suppose because it's automatically populated after calling a soql)
	 * NOTE: Not all relationship fields are unwritable, however, for the ones that are.... this method can be used.
	 * I would imagine this is not very performant, however, I'm sure it still trumps doing actual DML and SOQL operations
	 *
	 * NOTE: That Blobs (Attachment.Body for example) do not work with serialisation. Values should be nulled and reset after if you run into problems
	 */
	public static SObject setChildRelationships(SObject record, Map<String, List<SObject>> childRelationships) {
		Map<String, Object> recordAsMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(record));

		for(String childRelationship : childRelationships.keySet()) {
			recordAsMap.put(childRelationship, new Map<String, Object>{
					'done' => true,
					'totalSize' => childRelationships.get(childRelationship).size(),
					'records' => childRelationships.get(childRelationship)
			});
		}

		return (SObject)JSON.deserialize(JSON.serialize(recordAsMap), SObject.class);
	}

	public static List<SObject> maybeGenerateIds(List<SObject> records, Boolean generateIds) {
		if(generateIds) {
			generateRecordIds(records);
		}

		return records;
	}

	public static List<Compensation__c> getCompensation(Integer count, Id caseId, String recordTypeId, Boolean generateIds) {
		return (List<Compensation__c>)maybeGenerateIds(populateSObjects(Compensation__c.SObjectType, new Map<SObjectField, Object> {
				Compensation__c.Case__c => caseId,
				Compensation__c.Batch_ID__c => 1,
				Compensation__c.Compensation_Amount__c => 50,
				Compensation__c.Cover_Type__c => 'T&C Cover',
				Compensation__c.CostCentreCode__c => 'test',
				Compensation__c.BSB__c => '444333',
				Compensation__c.Account_Number__c => '123234345',
				Compensation__c.recordTypeId => recordTypeId
		}, count), generateIds);
	}

	/**
	 * Attaches field values 
	 */
	public static List<SObject> applyFieldValues(List<SObject> records, Map<String, Object> fieldValues) {
		for(Integer i=0;i<records.size();i++) {
			records[i] = setUnwritableFields(records[i], fieldValues);
		}
		return records;
	}

	public static List<SObject> populateSObjects(SObjectType sObjectType, Map<SObjectField, Object> fields, Integer count) {
		List<SObject> output = new List<SObject>();
		for(Integer i=0;i<count;i++) {
			SObject record = sObjectType.newSObject();
			for(SObjectField fieldName : fields.keySet()) {
				Object value = fields.get(fieldName);
				if(!String.isEmpty(String.valueOf(value)) && String.valueOf(value).contains('%count%')) {
					value = normaliseDataType(fieldName, String.valueOf(value).replace('%count%', String.valueOf(i+1)));

				}
				if(value instanceof List<Id>) {
					record.put(fieldName, ((List<Id>) value).get(i));
				} else if(value instanceof Set<Id>) {
					record.put(fieldName, (new List<Id>((Set<Id>)value)).get(i));
				} else {
					record.put(fieldName, value);
				}
			}
			output.add(record);
		}

		return output;
	}

	private static Object normaliseDataType(SObjectField fieldName, String value) {
		DescribeFieldResult result = fieldName.getDescribe();
		if(result.getType() == Schema.DisplayType.CURRENCY || result.getType() == Schema.DisplayType.DOUBLE || result.getType() == Schema.DisplayType.PERCENT) {
			return Decimal.valueOf(value);
		} else if(result.getType() == Schema.DisplayType.INTEGER) {
			return Integer.valueOf(value);
		} else if(result.getType() == Schema.DisplayType.LONG) {
			return Long.valueOf(value);
		} else {
			return value;
		}
	}

	public static RecordType articleArticleRecordType {
		get {
			if(articleArticleRecordType == null) {
				articleArticleRecordType = [Select Id, Name, DeveloperName From RecordType Where SObjectType = 'Article__c' And DeveloperName = 'Article'];
			}
			return articleArticleRecordType;
		}
		private set;
	}
	public static RecordType articleConsignmentRecordType {
		get {
			if(articleConsignmentRecordType == null) {
				articleConsignmentRecordType = [Select Id, Name, DeveloperName From RecordType Where SObjectType = 'Article__c' And DeveloperName = 'Consignment'];
			}
			return articleConsignmentRecordType;
		}
		private set;
	}
	/**
	* Generates test data for Auspost_Vendors_Email_Address__mdt custom metadata records
	**/
	public static List<Auspost_Vendors_Email_Address__mdt> getVendorEmail(Integer count, String emailAddress, Boolean generateIds) {
		List<Auspost_Vendors_Email_Address__mdt> emailAddresses = new List<Auspost_Vendors_Email_Address__mdt>();
		for (Integer i = 0; i < count; i++) {
			Auspost_Vendors_Email_Address__mdt email = new Auspost_Vendors_Email_Address__mdt();
			email.DeveloperName = 'RECORD' + i;
			email.Vendor_Email__c = emailAddress.replace('%count%', String.valueOf(i));
			emailAddresses.add(email);
		}
		return (List<Auspost_Vendors_Email_Address__mdt>)maybeGenerateIds(emailAddresses, generateIds);
	}

	/**
	 * @deprecated ApplicationTestDataFactoryCases
	 */
	public static Id caseSSSWGeneralEnquiryRecordType {
		get {
			if(caseSSSWGeneralEnquiryRecordType == null) {
				caseSSSWGeneralEnquiryRecordType = [Select Id From RecordType Where SObjectType = 'Case' And DeveloperName = 'SSSWGeneralEnquiry'].Id;
			}
			return caseSSSWGeneralEnquiryRecordType;
		}
		private set;
	}

	/**
	 * @deprecated ApplicationTestDataFactoryCases
	 */
	public static Id caseSSSWDeliveryRecordType {
		get {
			if(caseSSSWDeliveryRecordType == null) {
				caseSSSWDeliveryRecordType = [Select Id From RecordType Where SObjectType = 'Case' And DeveloperName = 'SSSWDelivery'].Id;
			}
			return caseSSSWDeliveryRecordType;
		}
		private set;
	}
	 
	/**
	 * @deprecated ApplicationTestDataFactoryCases
	 */
	public static Id caseStarTrackDeliveryEnquiryRecordType {
		get {
			if(caseStarTrackDeliveryEnquiryRecordType == null) {
				caseStarTrackDeliveryEnquiryRecordType = [Select Id From RecordType Where SObjectType = 'Case' And DeveloperName = 'StarTrack_PUD_Enquiry'].Id;
			  }
			  return caseStarTrackDeliveryEnquiryRecordType;
		 }
		 private set;
	}
	
	/**
	 * @deprecated ApplicationTestDataFactoryCases
	 */
   public static Id caseStarTrackVoiceOfCustRecordType {
	   get {
		   if(caseStarTrackVoiceOfCustRecordType == null) {
				caseStarTrackVoiceOfCustRecordType = [Select Id From RecordType Where SObjectType = 'Case' And DeveloperName = 'StarTrack_Voice_of_Customer'].Id;
			 }
			 return caseStarTrackVoiceOfCustRecordType;
		}
		private set;
   }

   /**
	 * @deprecated ApplicationTestDataFactoryCases
	 */
   public static Id caseStarTransitWarrantyClaimRecordType {
		get {
			if(caseStarTransitWarrantyClaimRecordType == null) {
				caseStarTransitWarrantyClaimRecordType = [Select Id From RecordType Where SObjectType = 'Case' And DeveloperName = 'StarTrack_Transit_Warranty_Claim'].Id;
			}
			return caseStarTransitWarrantyClaimRecordType;
		}
		private set;
	}
	
	/**
	 * @deprecated ApplicationTestDataFactoryCases
	 */
	public static Id casestarTrackGeneralEnquiryRecordType {
		get {
			if(casestarTrackGeneralEnquiryRecordType == null) {
				casestarTrackGeneralEnquiryRecordType = [Select Id From RecordType Where SObjectType = 'Case' And DeveloperName = 'StarTrack_General_Enquiry'].Id;
			}
			return casestarTrackGeneralEnquiryRecordType;
		}
		private set;
	}

	/**
	 * @deprecated ApplicationTestDataFactoryCases
	 */
	public static Id casestarTrackCreditDisputeRecordType {
		get {
			if(casestarTrackCreditDisputeRecordType == null) {
				casestarTrackCreditDisputeRecordType = [Select Id From RecordType Where SObjectType = 'Case' And DeveloperName = 'StarTrack_Credit_Dispute_Claim'].Id;
			}
			return casestarTrackCreditDisputeRecordType;
		}
		private set;
	}
	
	/**
	 * @deprecated ApplicationTestDataFactoryCases
	 */
	public static Id caseServiceDeliveryRecordType {
		get {
			if(caseServiceDeliveryRecordType == null) {
				caseServiceDeliveryRecordType = [Select Id From RecordType Where SObjectType = 'Case' And DeveloperName = 'Sales_Ops_Delivery'].Id;
			}
			return caseServiceDeliveryRecordType;
		}
		private set;
	}
	
	public static Id accountRecordType {
		get {
			if(accountRecordType == null) {
				accountRecordType = [Select Id From RecordType Where SObjectType = 'Account' And DeveloperName = 'Business_Account'].Id;
			}
			return accountRecordType;
		}
		private set;
	}
	public static Id contentVersionReportRecordType {
		get {
			if(contentVersionReportRecordType == null) {
				contentVersionReportRecordType = [Select Id From RecordType Where SObjectType = 'ContentVersion' And DeveloperName = 'Report'].Id;
			}
			return contentVersionReportRecordType;
		}
		private set;
	}
	public static Id personAccountRecordType {
		get {
			if(personAccountRecordType == null) {
				personAccountRecordType = personAccountRecordTypeRecord.Id;
			}
			return personAccountRecordType;
		}
		private set;
	}
	public static RecordType personAccountRecordTypeRecord {
		get {
			if(personAccountRecordTypeRecord == null) {
				personAccountRecordTypeRecord = [Select Id From RecordType Where IsPersonType = true And SObjectType = 'Account'];
			}
			return personAccountRecordTypeRecord;
		}
		private set;
	}
	public static Id assetPSRRecordType {
		get {
			if (assetPSRRecordType == null) {
				assetPSRRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'PSR' AND SObjectType = 'Asset'].Id;
			}
			return assetPSRRecordType;
		}private set;
	}
	public static Id accountFacilityRecordType {
		get {
			if(accountFacilityRecordType == null) {
				accountFacilityRecordType = [Select Id From RecordType Where DeveloperName = 'Facility' And SObjectType = 'Account'].Id;
			}
			return accountFacilityRecordType;
		}
		private set;
	}
	public static Id accountLicenceRecordType {
		get {
			if(accountLicenceRecordType == null) {
				accountLicenceRecordType = [Select Id From RecordType Where DeveloperName = 'Licence' And SObjectType = 'Account'].Id;
			}
			return accountLicenceRecordType;
		}
		private set;
	}
	public static Id membershipAplacRecordType {
		get {
			if(membershipAplacRecordType == null) {
				membershipAplacRecordType = [Select Id From RecordType Where DeveloperName = :Membership_constants.APLAC_RECORD_TYPE And SObjectType = 'Membership__c'].Id;
			}
			return membershipAplacRecordType;
		}
		private set;
	}
	public static Id surchargeExemptionRequestRecordType {
		get {
			if (surchargeExemptionRequestRecordType == null) {
				surchargeExemptionRequestRecordType = [Select Id From RecordType Where DeveloperName = 'Surcharge_Exemption_Request' And SObjectType = 'Deal_Support_Request__c'].Id;
			}
			return surchargeExemptionRequestRecordType;
		}
		private set;
	}
	
	public static Id defaultCommunityUserProfileId {
		get {
			if(defaultCommunityUserProfileId == null) {
				defaultCommunityUserProfileId = [Select Id From Profile Where Name = 'BSP Community User'].Id;
			}
			return defaultCommunityUserProfileId;
		}
		private set;
	}
	public static Id defaultUserProfileId {
		get {
			if(defaultUserProfileId == null) {
				defaultUserProfileId = [Select Id From Profile Where Name = 'System Administrator'].Id;
			}
			return defaultUserProfileId;
		}
		private set;
	}
	public static Id simpleOpportunityRecordType {
		get {
			if(simpleOpportunityRecordType == null) {
				simpleOpportunityRecordType = [Select Id From RecordType Where SObjectType = 'Opportunity' And DeveloperName = 'Simple'].Id;
			}
			return simpleOpportunityRecordType;
		}
		private set;
	}
	public static Id directContributionOverlayType {
		get {
			if(directContributionOverlayType == null) {
				directContributionOverlayType = [Select Id From OpportunitySplitType Where MasterLabel = 'Direct Contribution'].Id;
			}
			return directContributionOverlayType;
		}
		private set;
	}
	public static Id overlayContributionOverlayType {
		get {
			if(overlayContributionOverlayType == null) {
				overlayContributionOverlayType = [Select Id From OpportunitySplitType Where MasterLabel = 'Overlay Contribution'].Id;
			}
			return overlayContributionOverlayType;
		}
		private set;
	}
	public static Id leadBGStandardRecordType {
		get {
			if(leadBGStandardRecordType == null) {
				leadBGStandardRecordType = [Select Id From RecordType Where SObjectType = 'Lead' And DeveloperName = 'BG_Standard'].Id;
			  }
			  return leadBGStandardRecordType;
		 }
		 private set;
	}
}