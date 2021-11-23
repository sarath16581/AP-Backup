/* @author Seth Heang
 * @date 2020-12-18
 * @group Selector
 * @tag Selector
 * @tag EmailTemplate
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 */
public virtual inherited sharing class EmailTemplatesSelector extends ApplicationSelector {
    public static EmailTemplatesSelector newInstance() {
        return (EmailTemplatesSelector)Application.Selectors.newInstance(EmailTemplatesSelector.class);
    }
    public static EmailTemplatesSelector newInstance(Integer recordLimit) {
        return (EmailTemplatesSelector)Application.Selectors.newInstance(EmailTemplatesSelector.class).setLimit(recordLimit);
    }
    
    public virtual override SObjectType getSObjectType() {
        return EmailTemplate.getSObjectType();
    }    
    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField> {
            EmailTemplate.Id,EmailTemplate.developername, EmailTemplate.Subject, EmailTemplate.HtmlValue , EmailTemplate.Body , EmailTemplate.MarkUp
        };
    }

	/**
	 * @description Run a simple query to get records based on developer name
	 */
	public virtual Map<Id, EmailTemplate> selectByDeveloperName(String devName) {
		return selectByDeveloperName(devName, new Set<Object>());
    }
    
    /**
     * @description Run a simple query to get records based on developer name
     */
    public virtual Map<Id, EmailTemplate> selectByDeveloperName(String devName, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions);
        qb.addConditions()
        .add(new QueryBuilder.SimpleCondition(EmailTemplate.developername + ' =: devName'))
        .endConditions();
        System.debug('qb.toSoqlString()>>>>>>>>>>>'+qb.toSoqlString());
        return new Map<Id, EmailTemplate>((List<EmailTemplate>)Database.query(qb.toSoqlString()));
    }
}