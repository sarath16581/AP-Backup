/******************************************************************************************************
 * @description 	Test Class for ProcessSocialPostAction
 * @author 			Raghav Ravipati
 * @date 			2024-07-29
 * *****************************************************************************************************
 * @changelog
 * *****************************************************************************************************
 */
@isTest
public with sharing class ProcessSocialPostActionTest {
	@isTest
	public static void testSocialPostUpdate() {
		// =====================================
		// Data Preparation
		// =====================================
		SocialPost dummyPost = new SocialPost();
		dummyPost.Name = 'DummyName';
		dummyPost.Posted = Datetime.now();

		insert dummyPost;

		SocialPost post = new SocialPost();
		post.Name = 'Test Post';
		post.Posted = Datetime.now();
		post.ExternalpostId = 'dasdasddas';

		insert post;

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

		SproutSocialApp__Sprout_Social_Data_Event__c socialDataEvent = new SproutSocialApp__Sprout_Social_Data_Event__c();
		socialDataEvent.SproutSocialApp__Persona_Name__c = 'Test Name';
		socialDataEvent.SproutSocialApp__Post_Content__c = 'Test Content';
		socialDataEvent.SproutSocialApp__Post_Provider__c = 'Other';
		socialDataEvent.SproutSocialApp__Persona_Real_Name__c = 'TestName';
		socialDataEvent.SproutSocialApp__Media_Provider__c = 'Facebook';
		socialDataEvent.SproutSocialApp__Post_External_ID__c = 'dasdasddas';
		socialDataEvent.SproutSocialApp__Response_Context_External_Id__c = '01234';
		socialDataEvent.SproutSocialApp__Post_Name__c = 'Test Post';
		socialDataEvent.SproutSocialApp__Posted_At__c = Datetime.now();
		// =====================================
		// Stubbing
		// =====================================

		SocialPostsSelector postSelector = (SocialPostsSelector) MockUtility.mockSelector(SocialPostsSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		// Database
		MockUtility.Mocks.when(postSelector.search((Map<String, object>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject()))
			.thenReturn(new List<SocialPost>{ post });
		MockUtility.Mocks.when(postSelector.selectByResponseContextExternalIds((Set<String>) fflib_Match.anyObject()))
			.thenReturn(new List<SocialPost>());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		ProcessSocialPostAction.SocialPostParams params = new ProcessSocialPostAction.SocialPostParams();
		params.socialDataEvents = new List<SproutSocialApp__Sprout_Social_Data_Event__c>{ socialDataEvent };
		params.socialPersonas = new List<SocialPersona>{ existingPersona };
		List<SocialPost> existingPosts = ProcessSocialPostAction.processSocialPosts(new List<ProcessSocialPostAction.SocialPostParams>{params});
		System.assertEquals(post.Id, existingPosts[0].Id, 'Picked existing record while upsert');
		System.assertEquals(1, existingPosts.size(), 'Returned updated social post records');
		System.assertEquals('Test Content', existingPosts[0].Content, 'Content field updated');
		((SocialPostsSelector) MockUtility.Mocks.verify(postSelector, MockUtility.Mocks.times(1)))
		.search((Map<String, object>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject());
	}

	@isTest
	public static void testSocialPostCreate() {
		// =====================================
		// Data Preparation
		// =====================================
		SocialPost dummyPost = new SocialPost();
		dummyPost.Name = 'DummyName';
		dummyPost.Posted = Datetime.now();

		insert dummyPost;

		SocialPost post = new SocialPost();
		post.Name = 'Existing Post';
		post.Posted = Datetime.now();
		post.ExternalpostId = '01234';
		
		insert post;

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

		SproutSocialApp__Sprout_Social_Data_Event__c socialDataEvent = new SproutSocialApp__Sprout_Social_Data_Event__c();
		socialDataEvent.SproutSocialApp__Persona_Name__c = 'Test Name';
		socialDataEvent.SproutSocialApp__Post_Content__c = 'Test Content';
		socialDataEvent.SproutSocialApp__Post_Provider__c = 'Other';
		socialDataEvent.SproutSocialApp__Persona_Real_Name__c = 'TestName';
		socialDataEvent.SproutSocialApp__Media_Provider__c = 'Facebook';
		socialDataEvent.SproutSocialApp__Post_External_ID__c = '0123456';
		socialDataEvent.SproutSocialApp__Response_Context_External_Id__c = '01234';
		socialDataEvent.SproutSocialApp__Post_Name__c = 'Test Post';
		socialDataEvent.SproutSocialApp__Posted_At__c = Datetime.now();
		// =====================================
		// Stubbing
		// =====================================

		SocialPostsSelector postSelector = (SocialPostsSelector) MockUtility.mockSelector(SocialPostsSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		// Database
		MockUtility.Mocks.when(postSelector.search((Map<String, object>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject()))
			.thenReturn(new List<SocialPost>());
		MockUtility.Mocks.when(postSelector.selectByResponseContextExternalIds((Set<String>) fflib_Match.anyObject()))
			.thenReturn(new List<SocialPost>{ post });
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		ProcessSocialPostAction.SocialPostParams params = new ProcessSocialPostAction.SocialPostParams();
		params.socialDataEvents = new List<SproutSocialApp__Sprout_Social_Data_Event__c>{ socialDataEvent };
		params.socialPersonas = new List<SocialPersona>{ existingPersona };
		List<SocialPost> newPostRecords = ProcessSocialPostAction.processSocialPosts(new List<ProcessSocialPostAction.SocialPostParams>{params});
		System.assertEquals(1, newPostRecords.size(), 'Returned updated social post records');
		System.assertEquals('0123456', newPostRecords[0].ExternalPostId, 'ExternalPostId field mapped');
		System.assertEquals(existingPersona.Id, newPostRecords[0].PersonaId, 'PersonaId field mapped');
		((SocialPostsSelector) MockUtility.Mocks.verify(postSelector, MockUtility.Mocks.times(1)))
		.search((Map<String, object>) fflib_Match.anyObject(), (Set<Object>) fflib_Match.anyObject());
	}
}