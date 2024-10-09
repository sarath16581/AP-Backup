@isTest
public with sharing class GenerateSocialCaseActionTest {
	@isTest
	public static void testUpdateCase() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Case> cases = ApplicationTestDataFactoryCase.getCases(1, false);
		cases[0].Status = 'Closed';
		cases[0].ResolutionCode__c='tests';
		cases[0].Requestor__c=userinfo.getUserId();
		cases[0].Requestor_Workgroup__c='test';

		insert cases;

		SocialPost dummyPost = new SocialPost();
		dummyPost.Name = 'DummyName';
		dummyPost.Posted = Datetime.now();

		insert dummyPost;

		SocialPersona existingPersona = new SocialPersona();
		existingPersona.Name = 'Test Name';
		existingPersona.RealName = 'Test Name';
		existingPersona.Provider = 'Other';
		existingPersona.MediaProvider = 'Facebook';
		existingPersona.ExternalPictureURL = '/api/hv/media/profile/third_party/dasdasddas/';
		existingPersona.ProfileUrl = 'https://www.facebook.com/';
		existingPersona.Followers = 2;
		existingPersona.ParentId = dummyPost.Id;

		insert existingPersona;

		SocialPost parentPost = new SocialPost();
		parentPost.Name = 'Existing Post';
		parentPost.Posted = Datetime.now();
		parentPost.ExternalpostId = '01234';
		parentPost.ParentId = cases[0].Id;
		parentPost.PersonaId = existingPersona.Id;

		insert parentPost;

		SocialPost post = new SocialPost();
		post.Name = 'Existing Post';
		post.Posted = Datetime.now();
		post.ExternalpostId = '01234';
		post.ReplyTo = parentPost;
		Post.PersonaId = existingPersona.Id;

		insert post;

		// =====================================
		// Stubbing
		// =====================================

		CasesSelector caseSelector = (CasesSelector) MockUtility.mockSelector(CasesSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		// Database
		MockUtility.Mocks.when(caseSelector.selectById((Set<Id>) fflib_Match.eq(new Set<Id>{ cases[0].Id })))
			.thenReturn(new Map<Id, case>(cases));
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		GenerateSocialCaseAction.SocialBusinessCaseParams params = new GenerateSocialCaseAction.SocialBusinessCaseParams();
		params.socialPersona = existingPersona;
		params.socialPost = post;
		List<Case> casesAfterUpdate = GenerateSocialCaseAction.processCases(new list<GenerateSocialCaseAction.SocialBusinessCaseParams>{ params });
		System.assertEquals(1, casesAfterUpdate.size(), 'Case updated');
		System.assertEquals('New', casesAfterUpdate[0].Status, 'Case status changed to new');
		((CasesSelector) MockUtility.Mocks.verify(caseSelector, MockUtility.Mocks.times(1)))
			.selectById((Set<Id>) fflib_Match.eq(new Set<Id>{ cases[0].Id }));

	}

	@isTest
	public static void testCreateCase() {
		// =====================================
		// Data Preparation
		// =====================================
		Account account = ApplicationTestDataFactory.getAccounts(1, false)[0];
		insert account;
		Contact contact = ApplicationTestDataFactory.getContacts(1, account.Id, false)[0];
		
		insert contact;

		SocialPersona existingPersona = new SocialPersona();
		existingPersona.Name = 'Test Name';
		existingPersona.RealName = 'Test Name';
		existingPersona.Provider = 'Other';
		existingPersona.MediaProvider = 'Facebook';
		existingPersona.ExternalPictureURL = '/api/hv/media/profile/third_party/dasdasddas/';
		existingPersona.ProfileUrl = 'https://www.facebook.com/';
		existingPersona.Followers = 2;
		existingPersona.ParentId = contact.Id;

		insert existingPersona;

		SocialPost post = new SocialPost();
		post.Name = 'Existing Post';
		post.Posted = Datetime.now();
		post.ExternalpostId = '01234';
		Post.PersonaId = existingPersona.Id;
		
		insert post;

		// =====================================
		// Testing
		// =====================================
		GenerateSocialCaseAction.SocialBusinessCaseParams params = new GenerateSocialCaseAction.SocialBusinessCaseParams();
		params.socialPersona = existingPersona;
		params.socialPost = post;
		List<Case> newCases = GenerateSocialCaseAction.processCases(new list<GenerateSocialCaseAction.SocialBusinessCaseParams>{params});

		System.assertEquals(1, newCases.size(), 'Case created');
		System.assertEquals('Social', newCases[0].Origin, 'case Origin Social');
		System.assertEquals(contact.Id, newCases[0].ContactId, 'Mapped Contact Id');

	}

	@isTest
	public static void testCreateCaseIfTheExistingOneIsGreaterThan3Days() {
		// =====================================
		// Data Preparation
		// =====================================
		List<Case> cases = ApplicationTestDataFactoryCase.getCases(1, false);
		cases[0].Status = 'Closed';
		cases[0].ResolutionCode__c='tets';
		cases[0].Requestor__c=userinfo.getUserId();
		cases[0].Requestor_Workgroup__c='test';
		insert cases;
		cases[0] = (Case)ApplicationTestDataFactory.setUnwritableFields(cases[0], new Map<String, Object>{'ClosedDate' => Date.Today().addDays(-6), 'IsClosed' => true});

		update cases;

		SocialPost dummyPost = new SocialPost();
		dummyPost.Name = 'DummyName';
		dummyPost.Posted = Datetime.now();

		insert dummyPost;


		SocialPersona existingPersona = new SocialPersona();
		existingPersona.Name = 'Test Name';
		existingPersona.RealName = 'Test Name';
		existingPersona.Provider = 'Other';
		existingPersona.MediaProvider = 'Facebook';
		existingPersona.ExternalPictureURL = '/api/hv/media/profile/third_party/dasdasddas/';
		existingPersona.ProfileUrl = 'https://www.facebook.com/';
		existingPersona.Followers = 2;
		existingPersona.ParentId = dummyPost.Id;

		insert existingPersona;

		SocialPost parentPost = new SocialPost();
		parentPost.Name = 'Existing Post';
		parentPost.Posted = Datetime.now();
		parentPost.ExternalpostId = '01234';
		parentPost.ParentId = cases[0].Id;
		parentPost.PersonaId = existingPersona.Id;

		insert parentPost;

		SocialPost post = new SocialPost();
		post.Name = 'Existing Post';
		post.Posted = Datetime.now();
		post.ExternalpostId = '01234';
		post.ReplyTo = parentPost;
		Post.PersonaId = existingPersona.Id;

		insert post;

		// =====================================
		// Stubbing
		// =====================================

		CasesSelector caseSelector = (CasesSelector) MockUtility.mockSelector(CasesSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		// Database
		MockUtility.Mocks.when(caseSelector.selectById((Set<Id>) fflib_Match.eq(new Set<Id>{ cases[0].Id })))
			.thenReturn(new Map<Id, case>(cases));
		MockUtility.Mocks.stopStubbing();
		// =====================================
		// Testing
		// =====================================
		GenerateSocialCaseAction.SocialBusinessCaseParams params = new GenerateSocialCaseAction.SocialBusinessCaseParams();
		params.socialPersona = existingPersona;
		params.socialPost = post;
		List<Case> newCaseLst = GenerateSocialCaseAction.processCases(new list<GenerateSocialCaseAction.SocialBusinessCaseParams>{ params });

		System.assertEquals(1, newCaseLst.size(), 'New Case Created');
		System.assert(newCaseLst[0].Id == null, 'New Case Instance Created');
		((CasesSelector) MockUtility.Mocks.verify(caseSelector, MockUtility.Mocks.times(1)))
			.selectById((Set<Id>) fflib_Match.eq(new Set<Id>{ cases[0].Id }));
	}	
}