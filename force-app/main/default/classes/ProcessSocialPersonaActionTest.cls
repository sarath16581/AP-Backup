@isTest
public class ProcessSocialPersonaActionTest {
	@isTest
	public static void testSocialPersonaUpdateWithSocialDataEventInfo() {
		// =====================================
		// Data Preparation
		// =====================================
		SocialPost post = new SocialPost();
		post.Name = 'DummyName';
		post.Posted = Datetime.now();

		insert post;

		SocialPersona existingPersona = new SocialPersona();
		existingPersona.Name = 'Test Name';
		existingPersona.RealName = 'Test Name';
		existingPersona.Provider = 'Facebook';
		existingPersona.ExternalId = 'das213s2d54sad';
		existingPersona.MediaProvider = 'Facebook';
		existingPersona.ExternalPictureURL = '/api/hv/media/profile/third_party/012345/';
		existingPersona.ProfileUrl = 'https://www.facebook.com/';
		existingPersona.Followers = 2;
		existingPersona.ParentId = post.Id;

		insert existingPersona;

		SproutSocialApp__Sprout_Social_Data_Event__c socialDataEvent = new SproutSocialApp__Sprout_Social_Data_Event__c();
		socialDataEvent.SproutSocialApp__Persona_External_Id__c = 'das213s2d54sad';
		socialDataEvent.SproutSocialApp__Post_Provider__c = 'Facebook';
		socialDataEvent.SproutSocialApp__Persona_Real_Name__c = 'TestName';
		socialDataEvent.SproutSocialApp__Persona_Name__c = 'Test Name';
		// =====================================
		// Stubbing
		// =====================================

		SocialPersonasSelector personasSelector = (SocialPersonasSelector) MockUtility.mockSelector(SocialPersonasSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		Map<String, Object> searchParams = new Map<String, Object>();
		searchParams.put('providers', new Set<String>{ 'Facebook' });
		searchParams.put('externalIds', new Set<String>{ 'das213s2d54sad' });
		searchParams.put('personaNames', new Set<String>{ 'Test Name' });
		searchParams.put('mediaProviders', new Set<String>());
		// Database
		MockUtility.Mocks.when(personasSelector.search((Map<String, Object>)fflib_Match.eq(searchParams), (Set<Object>) fflib_Match.eq(new Set<Object>())))
			.thenReturn(new List<socialPersona>{ existingPersona });
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<socialPersona> existingPersonas = ProcessSocialPersonaAction.processSocialPersonas(new List<SproutSocialApp__Sprout_Social_Data_Event__c>{ socialDataEvent });
		System.assertEquals(1, existingPersonas.size(), 'found one social record');
		System.assertEquals('TestName', existingPersonas[0].RealName, 'RealName field updated using social data event');
		((SocialPersonasSelector) MockUtility.Mocks.verify(personasSelector, MockUtility.Mocks.times(1)))
		.search((Map<String, Object>)fflib_Match.eq(searchParams), (Set<Object>) fflib_Match.eq(new Set<Object>()));
	}

	@isTest
	public static void testSocialPersonaUpdateWithMediaProvider() {
		// =====================================
		// Data Preparation
		// =====================================
		SocialPost post = new SocialPost();
		post.Name = 'DummyName';
		post.Posted = Datetime.now();

		insert post;

		SocialPersona existingPersona = new SocialPersona();
		existingPersona.Name = 'Test Name';
		existingPersona.RealName = 'Test Name';
		existingPersona.Provider = 'Other';
		existingPersona.ExternalId = 'das213s2d54sad';
		existingPersona.MediaProvider = 'Facebook';
		existingPersona.ExternalPictureURL = '/api/hv/media/profile/third_party/012345/';
		existingPersona.ProfileUrl = 'https://www.facebook.com/';
		existingPersona.Followers = 2;
		existingPersona.ParentId = post.Id;

		insert existingPersona;

		SproutSocialApp__Sprout_Social_Data_Event__c socialDataEvent = new SproutSocialApp__Sprout_Social_Data_Event__c();
		socialDataEvent.SproutSocialApp__Persona_External_Id__c = 'das213s2d54sad';
		socialDataEvent.SproutSocialApp__Post_Provider__c = 'Other';
		socialDataEvent.SproutSocialApp__Persona_Real_Name__c = 'TestName';
		socialDataEvent.SproutSocialApp__Media_Provider__c = 'Facebook';
		socialDataEvent.SproutSocialApp__Persona_Name__c = 'Test Name';
		// =====================================
		// Stubbing
		// =====================================

		SocialPersonasSelector personasSelector = (SocialPersonasSelector) MockUtility.mockSelector(SocialPersonasSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		Map<String, Object> searchParams = new Map<String, Object>();
		searchParams.put('providers', new Set<String>());
		searchParams.put('externalIds', new Set<String>{ 'das213s2d54sad' });
		searchParams.put('mediaProviders', new Set<String>{ 'Facebook' });
		searchParams.put('personaNames', new Set<String>{ 'Test Name' });
		// Database
		MockUtility.Mocks.when(personasSelector.search((Map<String, Object>)fflib_Match.eq(searchParams), (Set<Object>) fflib_Match.eq(new Set<Object>())))
			.thenReturn(new List<socialPersona>{ existingPersona });
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<socialPersona> existingPersonas = ProcessSocialPersonaAction.processSocialPersonas(new List<SproutSocialApp__Sprout_Social_Data_Event__c>{ socialDataEvent });
		System.assertEquals(1, existingPersonas.size(), 'found one social record');
		System.assertEquals('TestName', existingPersonas[0].RealName, 'RealName field updated using social data event');
		((SocialPersonasSelector) MockUtility.Mocks.verify(personasSelector, MockUtility.Mocks.times(1)))
		.search((Map<String, Object>)fflib_Match.eq(searchParams), (Set<Object>) fflib_Match.eq(new Set<Object>()));
	}

	@isTest
	public static void testSocialPersonaUpdateWithPersonName() {
		// =====================================
		// Data Preparation
		// =====================================
		SocialPost post = new SocialPost();
		post.Name = 'DummyName';
		post.Posted = Datetime.now();

		insert post;

		SocialPersona existingPersona = new SocialPersona();
		existingPersona.Name = 'Test Name';
		existingPersona.RealName = 'Test Name';
		existingPersona.Provider = 'Other';
		existingPersona.MediaProvider = 'Facebook';
		existingPersona.ExternalPictureURL = '/api/hv/media/profile/third_party/012345/';
		existingPersona.ProfileUrl = 'https://www.facebook.com/';
		existingPersona.Followers = 2;
		existingPersona.ParentId = post.Id;

		insert existingPersona;

		SproutSocialApp__Sprout_Social_Data_Event__c socialDataEvent = new SproutSocialApp__Sprout_Social_Data_Event__c();
		socialDataEvent.SproutSocialApp__Persona_Name__c = 'Test Name';
		socialDataEvent.SproutSocialApp__Post_Provider__c = 'Other';
		socialDataEvent.SproutSocialApp__Persona_Real_Name__c = 'TestName';
		socialDataEvent.SproutSocialApp__Media_Provider__c = 'Facebook';

		// =====================================
		// Stubbing
		// =====================================
		SocialPersonasSelector personasSelector = (SocialPersonasSelector) MockUtility.mockSelector(SocialPersonasSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		// Database
		Map<String, Object> searchParams = new Map<String, Object>();
		searchParams.put('providers', new Set<String>());
		searchParams.put('mediaProviders', new Set<String>{ 'Facebook' });
		searchParams.put('personaNames', new Set<String>{ 'Test Name' });
		searchParams.put('externalIds', new Set<String>());
		MockUtility.Mocks.when(personasSelector.search((Map<String, Object>)fflib_Match.eq(searchParams), (Set<Object>) fflib_Match.eq(new Set<Object>())))
			.thenReturn(new List<socialPersona>{ existingPersona });
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<socialPersona> existingPersonas = ProcessSocialPersonaAction.processSocialPersonas(new List<SproutSocialApp__Sprout_Social_Data_Event__c>{ socialDataEvent });
		System.assertEquals(1, existingPersonas.size(), 'found one social record');
		System.assertEquals('TestName', existingPersonas[0].RealName, 'RealName field updated using social data event');
		((SocialPersonasSelector) MockUtility.Mocks.verify(personasSelector, MockUtility.Mocks.times(1)))
		.search((Map<String, Object>)fflib_Match.eq(searchParams), (Set<Object>) fflib_Match.eq(new Set<Object>()));
	}


	@isTest
	public static void testSocialPersonaCreateWithSocialDataEventInfo(){
		// =====================================
		// Data Preparation
		// =====================================
		SproutSocialApp__Sprout_Social_Data_Event__c socialDataEvent = new SproutSocialApp__Sprout_Social_Data_Event__c();
		socialDataEvent.SproutSocialApp__Persona_External_Id__c = 'das213s2d54sad';
		socialDataEvent.SproutSocialApp__Post_Provider__c = 'Facebook';
		socialDataEvent.SproutSocialApp__Persona_Real_Name__c = 'Test Name';
		socialDataEvent.SproutSocialApp__Persona_Name__c = 'Test Name';

		// =====================================
		// Stubbing
		// =====================================
		SocialPersonasSelector personasSelector = (SocialPersonasSelector) MockUtility.mockSelector(SocialPersonasSelector.class);
		// set up our responses
		MockUtility.Mocks.startStubbing();
		// Database
		Map<String, Object> searchParams = new Map<String, Object>();
		searchParams.put('providers', new Set<String>{ 'Facebook' });
		searchParams.put('personaNames', new Set<String>{ 'Test Name' });
		searchParams.put('externalIds', new Set<String>{ 'das213s2d54sad' });
		searchParams.put('mediaProviders', new Set<String>());
		MockUtility.Mocks.when(personasSelector.search((Map<String, Object>)fflib_Match.eq(searchParams), (Set<Object>) fflib_Match.eq(new Set<Object>())))
			.thenReturn(new List<socialPersona>());
		MockUtility.Mocks.stopStubbing();

		// =====================================
		// Testing
		// =====================================
		List<socialPersona> newPersonas = ProcessSocialPersonaAction.processSocialPersonas(new List<SproutSocialApp__Sprout_Social_Data_Event__c>{ socialDataEvent });
		List<SocialPost> socialPost = [SELECT Id, Name from SocialPost LIMIT 1];
		System.assertEquals(1, newPersonas.size(), 'A New social persona record is created');
		System.assertEquals(1, socialPost.size(), 'A Dummy social record is created');
		System.assertEquals('DummyTestName', socialPost[0].Name, 'A Dummy social record is created');
		System.assertEquals(socialPost[0].Id, newPersonas[0].ParentId, 'A New social persona record is created');
		((SocialPersonasSelector) MockUtility.Mocks.verify(personasSelector, MockUtility.Mocks.times(1)))
		.search((Map<String, Object>)fflib_Match.eq(searchParams), (Set<Object>) fflib_Match.eq(new Set<Object>()));
	}
}
