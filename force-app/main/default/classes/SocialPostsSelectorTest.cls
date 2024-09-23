@isTest
public class SocialPostsSelectorTest {
	@isTest
	public static void testQueryBuilderString(){
		SocialPostsSelector selector = SocialPostsSelector.newInstance();

		QueryBuilder qa = QueryBuilder.newInstance();
		QueryBuilder.mockFactory.put(SocialPostsSelector.class, qa); 
		selector.search(new Map<String, Object>(), new Set<Object>());
		String queryString = qa.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?is)\\bfrom SocialPost\\b').matcher(queryString).find(), 'Resulting query select from SocialPost');
		System.assertEquals(true, Pattern.compile('\\b' + SocialPost.Provider + ' IN: providers AND ' + SocialPost.ExternalPostId + ' IN: externalPostIds\\b').matcher(queryString).find(), 'Filters by providers and externalPostIds in query');		
	}

	@isTest
	public static void testQueryBuilderStringWithFields(){
		Set<SObjectField> fieldOverrides = new Set<SObjectField>{SocialPost.ExternalPostId};
		SocialPostsSelector selector = SocialPostsSelector.newInstance(fieldOverrides);
		QueryBuilder qa = QueryBuilder.newInstance();
		QueryBuilder.mockFactory.put(SocialPostsSelector.class, qa); 
		selector.selectByResponseContextExternalIds(new Set<String>());
		String queryString = qa.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)ExternalPostId.*?\\bfrom SocialPost\\b').matcher(queryString).find(), 'Resulting query select from SocialPost');
		System.assertEquals(true, Pattern.compile('\\b' + SocialPost.ResponseContextExternalId + ' IN :responseContextExternalIds\\b').matcher(queryString).find(), 'Filters by ResponseContextExternalId in query');	
		
	}
}