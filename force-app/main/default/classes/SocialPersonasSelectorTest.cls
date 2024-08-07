/******************************************************************************************************
 * @description 	Test class for SocialPersonasSelector class.
 * @author 			Raghav Ravipati
 * @test			SocialPersonasSelectorTest
 * @date 			2024-07-29
 * *****************************************************************************************************
 * @changelog
 * *****************************************************************************************************
 */
@isTest
public class SocialPersonasSelectorTest {
	@isTest
	public static void testQueryBuilderString(){
		SocialPersonasSelector selector = SocialPersonasSelector.newInstance();

		QueryBuilder qa = QueryBuilder.newInstance();
		QueryBuilder.mockFactory.put(SocialPersonasSelector.class, qa); 
		selector.search(new Map<String, Object>(), new Set<Object>());
		String queryString = qa.toSoqlString();
		system.debug(qa.toSoqlString());
		System.assertEquals(true, Pattern.compile('(?is)\\bfrom SocialPersona\\b').matcher(queryString).find(), 'Resulting query select from SocialPersona');
		System.assertEquals(true, Pattern.compile('\\b('+ SocialPersona.Provider + ' IN: providers AND ' + SocialPersona.ExternalId + ' IN: externalIds'+')\\b').matcher(queryString).find(), 'Filters by Providers and ExternalIds in query');
		System.assertEquals(true, Pattern.compile('\\b'+ SocialPersona.Provider + ' =: providerOther\\b').matcher(queryString).find(), 'Filters by Provider  is other');
		System.assertEquals(true, Pattern.compile('\\b('+ SocialPersona.MediaProvider + ' IN: mediaProviders AND ' + SocialPersona.ExternalId + ' IN: externalIds'+')\\b').matcher(queryString).find(), 'Filters by MediaProvider and ExternalIds in query');
		
	}

	@isTest
	public static void testQueryBuilderStringWithFields(){
		Set<SObjectField> fieldOverrides = new Set<SObjectField>{SocialPersona.ExternalId};
		SocialPersonasSelector selector = SocialPersonasSelector.newInstance(fieldOverrides);
		QueryBuilder qa = QueryBuilder.newInstance();
		QueryBuilder.mockFactory.put(SocialPersonasSelector.class, qa); 
		selector.search(new Map<String, Object>(), new Set<Object>());
		String queryString = qa.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)ExternalId.*?\\bfrom SocialPersona\\b').matcher(queryString).find(), 'Resulting query select from SocialPersona with selected fields');
		
	}
}