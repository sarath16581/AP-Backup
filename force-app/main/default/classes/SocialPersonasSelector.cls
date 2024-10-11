/******************************************************************************************************
 * @description 	SocialPersona object Selector Class.
 * @author 			Raghav Ravipati
 * @test			SocialPersonasSelectorTest
 * @date 			2024-07-29
 * *****************************************************************************************************
 * @changelog
 * *****************************************************************************************************
 */
public virtual inherited sharing class SocialPersonasSelector extends ApplicationSelector {
	public static SocialPersonasSelector newInstance() {
		SocialPersonasSelector selector = (SocialPersonasSelector) Application.Selectors.newInstance(SocialPersonasSelector.class);
		return selector;
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static SocialPersonasSelector newInstance(Set<SObjectField> fieldOverrides) {
		SocialPersonasSelector selector = (SocialPersonasSelector) Application.Selectors.newInstance(SocialPersonasSelector.class);
		selector.setFieldOverrides(fieldOverrides);
		return selector;
	}

	protected override SObjectType getSObjectType() {
		return SocialPersona.SObjectType;
	}

	protected override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField>{
			SocialPersona.AreWeFollowing,
			SocialPersona.AuthorLabels,
			SocialPersona.AvatarUrl,
			SocialPersona.Bio,
			SocialPersona.CreatedById,
			SocialPersona.CreatedDate,
			SocialPersona.ExternalId,
			SocialPersona.ExternalPictureURL,
			SocialPersona.Followers,
			SocialPersona.Following,
			SocialPersona.Id,
			SocialPersona.InfluencerScore,
			SocialPersona.IsBlacklisted,
			SocialPersona.IsDefault,
			SocialPersona.IsDeleted,
			SocialPersona.IsFollowingUs,
			SocialPersona.IsVerified,
			SocialPersona.LastModifiedById,
			SocialPersona.LastModifiedDate,
			SocialPersona.LastReferencedDate,
			SocialPersona.LastViewedDate,
			SocialPersona.ListedCount,
			SocialPersona.MediaProvider,
			SocialPersona.MediaType,
			SocialPersona.Name,
			SocialPersona.NumberOfFriends,
			SocialPersona.NumberOfTweets,
			SocialPersona.ParentId,
			SocialPersona.ProfileType,
			SocialPersona.ProfileUrl,
			SocialPersona.Provider,
			SocialPersona.R6SourceId,
			SocialPersona.RealName,
			SocialPersona.SourceApp,
			SocialPersona.SystemModstamp,
			SocialPersona.TopicType
		};
	}

	public List<SocialPersona> search(Map<String, Object> searchParams, Set<Object> selectorOptions) {
		// make sure the parameters received are valid
		// will throw if the parameters passed are invalid
		super.validateSearchParams(searchParams.keySet(), new Set<String>{ 'providers', 'externalIds', 'mediaProviders', 'personaNames' });

		return (List<SocialPersona>) selectSocialPersonaRecords(searchParams, selectorOptions);
	}

	private List<SObject> selectSocialPersonaRecords(Map<String, Object> searchParams, Set<Object> selectorOptions) {
		String providerOther = 'Other';
		Set<String> providers = searchParams.containsKey('providers') ? (Set<String>) searchParams.get('providers') : new Set<String>();
		Set<String> externalIds = searchParams.containsKey('externalIds') ? (Set<String>) searchParams.get('externalIds') : new Set<String>();
		Set<String> mediaProviders = searchParams.containsKey('mediaProviders') ? (Set<String>) searchParams.get('mediaProviders') : new Set<String>();
		Set<String> personaNames = searchParams.containsKey('personaNames') ? (Set<String>) searchParams.get('personaNames') : new Set<String>();

		QueryBuilder qb = newQueryBuilder(selectorOptions)
			.addConditions()
			.add(new QueryBuilder.SimpleCondition('Provider IN: providers AND ExternalId IN: externalIds'))
			.add(new QueryBuilder.SimpleCondition('Provider =: providerOther'))
			.add(new QueryBuilder.SimpleCondition('MediaProvider IN: mediaProviders AND ExternalId IN: externalIds'))
			.add(new QueryBuilder.SimpleCondition('MediaProvider IN: mediaProviders AND Name IN: personaNames'))
			.setConditionOrder('(1) OR (2 AND ((3) OR (4)))')
			.endConditions();

		return Database.query(qb.toSoqlString());
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		return builder;
	}
}