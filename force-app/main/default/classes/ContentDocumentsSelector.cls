/**
 * @description Selector case to get ContentDocument (File) records
 * @author Victor Cheng
 * @date 2021-04-14
 * @group Selector
 * @domain Core
 * @changelog
 * -----------------------------------------------------------------------------------
 * 15-07-2023 hasantha.liyanage@auspost.com.au Added extra field to getSObjectFieldList
*/

public virtual inherited sharing class ContentDocumentsSelector extends ApplicationSelector {

	public static ContentDocumentsSelector newInstance() {
		return (ContentDocumentsSelector)Application.Selectors.newInstance(ContentDocumentsSelector.class);
	}

	protected override SObjectType getSObjectType() {
		return ContentDocument.getSObjectType();
	}

	protected override Set<SObjectField> getSObjectFieldList() {
		return new Set<SObjectField> {
			ContentDocument.CreatedDate, ContentDocument.Id, ContentDocument.Title, ContentDocument.FileType, ContentDocument.ContentSize, ContentDocument.ParentId
		};
	}

	public virtual Map<Id, ContentDocument> selectById(Set<Id> ids) {
		return selectById(ids, new Set<Object>());
	}

	public virtual Map<Id, ContentDocument> selectById(Set<Id> ids, Set<Object> selectorOptions) {
		QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(ContentDocument.Id + ' in :ids')).endConditions();
		return new Map<Id, ContentDocument>((List<ContentDocument>)Database.query(qb.toSoqlString()));
	}
}