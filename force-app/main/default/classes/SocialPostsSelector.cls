/******************************************************************************************************
 * @description 	SocialPost object selector class.
 * @author 			Raghav Ravipati
 * @test			SocialPostsSelectorTest
 * @date 			2024-08-01
 * *****************************************************************************************************
 * @changelog
 * *****************************************************************************************************
 */
public virtual inherited sharing class SocialPostsSelector extends ApplicationSelector {
	public static SocialPostsSelector newInstance() {
		SocialPostsSelector selector = (SocialPostsSelector) Application.Selectors.newInstance(SocialPostsSelector.class);
		return selector;
	}

	/**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static SocialPostsSelector newInstance(Set<SObjectField> fieldOverrides) {
		SocialPostsSelector selector = (SocialPostsSelector) Application.Selectors.newInstance(SocialPostsSelector.class);
		selector.setFieldOverrides(fieldOverrides);
		return selector;
	}

	protected override SObjectType getSObjectType() {
		return SocialPost.SObjectType;
	}

	protected override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField>{
			SocialPost.AnalyzerScore,
			SocialPost.AssignedTo,
			SocialPost.AttachmentType,
			SocialPost.AttachmentUrl,
			SocialPost.Classification,
			SocialPost.CommentCount,
			SocialPost.CreatedById,
			SocialPost.DeletedById,
			SocialPost.EngagementLevel,
			SocialPost.ExternalPostId,
			SocialPost.HarvestDate,
			SocialPost.Headline,
			SocialPost.HiddenById,
			SocialPost.ReplyToId,
			SocialPost.InboundLinkCount,
			SocialPost.IsOutbound,
			SocialPost.KeywordGroupName,
			SocialPost.Language,
			SocialPost.LastModifiedById,
			SocialPost.LikedBy,
			SocialPost.LikesAndVotes,
			SocialPost.OutboundSocialAccountId,
			SocialPost.Content,
			SocialPost.TruncatedContent,
			SocialPost.MessageType,
			SocialPost.Name,
			SocialPost.Notes,
			SocialPost.OwnerId,
			SocialPost.ParentId,
			SocialPost.PostPriority,
			SocialPost.PostTags,
			SocialPost.PostUrl,
			SocialPost.Posted,
			SocialPost.Recipient,
			SocialPost.RecipientType,
			SocialPost.ResponseContextExternalId,
			SocialPost.ReviewScale,
			SocialPost.ReviewScore,
			SocialPost.ReviewedStatus,
			SocialPost.Sentiment,
			SocialPost.Shares,
			SocialPost.Handle,
			SocialPost.Provider,
			SocialPost.PersonaId,
			SocialPost.MediaProvider,
			SocialPost.MediaType,
			SocialPost.R6PostId,
			SocialPost.R6SourceId,
			SocialPost.R6TopicId,
			SocialPost.SourceTags,
			SocialPost.SpamRating,
			SocialPost.Status,
			SocialPost.StatusMessage,
			SocialPost.ThreadSize,
			SocialPost.TopicProfileName,
			SocialPost.TopicType,
			SocialPost.UniqueCommentors,
			SocialPost.ViewCount,
			SocialPost.WhoId
		};
	}

	/**
	 * @description Run a simple query to get records based on Id's
	 * @param responseContextExternalIds Set of SproutSocialApp__Response_Context_External_Id__c from Sprout Social Data Event.
	 * @return List<SocialPost>
	 */
	public List<SocialPost> selectByResponseContextExternalIds(Set<String> responseContextExternalIds) {
		QueryBuilder qb = newQueryBuilder(new Set<Object>());
		QueryBuilder.ConditionsManager cm = qb.conditionsManager;
		// Where clause
		cm.add(new QueryBuilder.SimpleCondition('ResponseContextExternalId IN :responseContextExternalIds'));
		cm.endConditions();
		QueryBuilder.Order orderBy = new QueryBuilder.Order('CreatedDate', 'ASC');
		qb.setOrder( orderBy );
		return (List<SocialPost>) Database.query(qb.toSoqlString());
	}

	public List<SocialPost> search(Map<String, Object> searchParams, Set<Object> selectorOptions) {
		// make sure the parameters received are valid
		// will throw if the parameters passed are invalid
		super.validateSearchParams(searchParams.keySet(), new Set<String>{ 'providers', 'externalPostIds' });

		return (List<SocialPost>) selectSocialPostRecords(searchParams, selectorOptions);
	}

	private List<SObject> selectSocialPostRecords(Map<String, Object> searchParams, Set<Object> selectorOptions) {
		Set<String> providers = searchParams.containsKey('providers') ? (Set<String>) searchParams.get('providers') : new Set<String>();
		Set<String> externalPostIds = searchParams.containsKey('externalPostIds') ? (Set<String>) searchParams.get('externalPostIds') : new Set<String>();
		QueryBuilder qb = newQueryBuilder(selectorOptions)
			.addConditions()
			.add(new QueryBuilder.SimpleCondition('Provider IN: providers'))
			.add(new QueryBuilder.SimpleCondition('ExternalPostId IN: externalPostIds'))
			.setConditionOrder('1 AND 2')
			.endConditions();

		return Database.query(qb.toSoqlString());
	}

	public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
		QueryBuilder builder = super.newQueryBuilder(selectorOptions);

		return builder;
	}
}