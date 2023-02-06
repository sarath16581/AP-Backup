/* @author Nathan Franklin
 * @date 2020-11-18
 * @group Tests
 * @tag Selector
 * @tag Credit Assessment
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2020-11-18 - arjun.singh@austpost.com.au - Created
 * 2020-12-09 - Shashwat.Nath@Auspost.com - Added WITH_PROPOSAL option
 * 2022-08-04 - Seth Heang - Added APT_APPC_Count__c, Apttus__FF_Agreement_Number__c in the query
 * 2022-11-26 - Harry Wang - added selector method for sales intermediary
 */
public with sharing class ApttusContractsSelector extends ApplicationSelector{
    public enum Options {
        WITH_RECORDTYPE, WITH_OWNER, WITH_ORGANISATION, WITH_CONTACT, WITH_CREDIT_ASSESSMENT , WITH_PROPOSAL , WITH_OPPORTUNITY
    }
    public static ApttusContractsSelector newInstance() {
        return (ApttusContractsSelector)Application.Selectors.newInstance(ApttusContractsSelector.class);
    }
    public static ApttusContractsSelector newInstance(Integer recordLimit) {
        return (ApttusContractsSelector)Application.Selectors.newInstance(ApttusContractsSelector.class).setLimit(recordLimit);
    }

    /**
	* NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	* This approach removes data consistency and prevents possible caching of results
	*/
    public static ApttusContractsSelector newInstance(Map<SObjectType, Set<SObjectField>> fieldOverrides) {
        ApttusContractsSelector selector = (ApttusContractsSelector)Application.Selectors.newInstance(ApttusContractsSelector.class).setFieldOverrides(fieldOverrides);
        return selector;
    }

    /**
     * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
     * This approach removes data consistency and prevents possible caching of results
     */
    public static ApttusContractsSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides) {
        ApttusContractsSelector selector = (ApttusContractsSelector)Application.Selectors.newInstance(ApttusContractsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
        return selector;
    }
    /**
     * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
     * This approach removes data consistency and prevents possible caching of results
     */
    public static ApttusContractsSelector newInstance(Integer recordLimit, Map<SObjectType, Set<SObjectField>> fieldOverrides) {
        ApttusContractsSelector selector = (ApttusContractsSelector)Application.Selectors.newInstance(ApttusContractsSelector.class).setLimit(recordLimit).setFieldOverrides(fieldOverrides);
        return selector;
    }
    public virtual override SObjectType getSObjectType() {
        return Apttus__APTS_Agreement__c.getSObjectType();
    }
    public virtual override Set<SObjectField> getSObjectFieldList() {
        return new Set<SObjectField> {
            Apttus__APTS_Agreement__c.Id,Apttus__APTS_Agreement__c.Name, Apttus__APTS_Agreement__c.Apttus__Account__c,
                Apttus__APTS_Agreement__c.APT_Review_Date__c,Apttus__APTS_Agreement__c.Apttus__Related_Opportunity__c,
                Apttus__APTS_Agreement__c.Apttus__Contract_Start_Date__c, Apttus__APTS_Agreement__c.Apttus__Contract_End_Date__c,
                Apttus__APTS_Agreement__c.Term__c, Apttus__APTS_Agreement__c.APT_APPC_Count__c, Apttus__APTS_Agreement__c.Apttus__FF_Agreement_Number__c
        };
    }
    /**
     * @description Run a simple query to get records based on Id's
     */
    public virtual Map<Id, Apttus__APTS_Agreement__c> selectById(Set<Id> ids) {
        return selectById(ids, new Set<Object>());
    }
    /**
     * @description Run a simple query to get records based on Id's
     */

    public virtual Map<Id, Apttus__APTS_Agreement__c> selectById(Set<Id> ids, Set<Object> selectorOptions) {
        System.debug('selectorOptions>>>'+selectorOptions);
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Apttus__APTS_Agreement__c.Id + ' in :ids')).endConditions();
        System.debug('qb.toSoqlString()>>>>>'+qb.toSoqlString());
        System.debug('Database.query(qb.toSoqlString())>>>>'+Database.query(qb.toSoqlString()));
        return new Map<Id, Apttus__APTS_Agreement__c>((List<Apttus__APTS_Agreement__c>)Database.query(qb.toSoqlString()));
    }

    /**
	* Returns a query locator to retrieve Apttus Contracts (Apttus__APTS_Agreement__c) based on the account ids passed in.
	* If set of account ids is null or empty, returns all Apttus Contract records having a parent account.
	* Query results are ordered by parent account Id desc
	* @param accountIds set of parent account ids. returns all child Apttus Contract records associated with a parent account if null
	*                   or empty set is supplied.
	* @param selectorOptions set of additional selector options to augment the result set
	* @return query locator of Apttus Contract records
	*/
    public Database.QueryLocator selectByAccountOrderByAccountIdQueryLocator(Set<Id> accountIds, Set<Object> selectorOptions) {

        Set<Object> options = (selectorOptions != null ? selectorOptions : new Set<Object>());
        options.add(ApplicationSelector.Options.WITHOUT_DEFAULT_ORDER);

        QueryBuilder qb = newQueryBuilder(options);
        QueryBuilder.ConditionsManager conditions = qb.addConditions();
        if (accountIds != null && !accountIds.isEmpty()) {
            conditions.add(new QueryBuilder.SimpleCondition(Apttus__APTS_Agreement__c.Apttus__Account__c + ' in :accountIds'));
        } else {
            conditions.add(new QueryBuilder.SimpleCondition(Apttus__APTS_Agreement__c.Apttus__Account__c + ' != null'));
        }

        qb = conditions.endConditions().addOrderDesc(Apttus__APTS_Agreement__c.Apttus__Account__c);
        return Database.getQueryLocator(qb.toSoqlString());
    }

    public virtual override QueryBuilder newQueryBuilder() {
        return newQueryBuilder(new Set<Object>());
    }

    public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions) {
        QueryBuilder builder = super.newQueryBuilder(selectorOptions);

        if(selectorOptions.contains(Options.WITH_RECORDTYPE)) {
            builder.addRelatedFields(RecordTypesSelector.newInstance().newQueryBuilder(), 'RecordType');
        }

        if(selectorOptions.contains(Options.WITH_OWNER)) {
            builder.addRelatedFields(OwnersSelector.newInstance().newQueryBuilder(), 'Owner');
        }
        if(selectorOptions.contains(Options.WITH_ORGANISATION)) {
            builder.addRelatedFields(AccountsSelector.newInstance().setFieldOverrides(fieldOverrides).newQueryBuilder(), 'Apttus__Account__r');
        }
        if(selectorOptions.contains(Options.WITH_CONTACT)) {
            builder.addRelatedFields(ContactsSelector.newInstance().newQueryBuilder(), 'Apttus__Primary_Contact__r');
        }
        if(selectorOptions.contains(Options.WITH_CREDIT_ASSESSMENT)) {
            builder.addRelatedFields(CreditsAssessmentSelector.newInstance().newQueryBuilder(), 'Apttus_QPComply__RelatedProposalId__r.APT_Credit_Assessment__r');
        }
        if(selectorOptions.contains(Options.WITH_PROPOSAL)) {
            builder.addRelatedFields(ProposalSelector.newInstance().newQueryBuilder(), 'Apttus_QPComply__RelatedProposalId__r');
        }
        if(selectorOptions.contains(Options.WITH_OPPORTUNITY)) {
            builder.addRelatedFields(OpportunitySelector.newInstance().newQueryBuilder(), 'Apttus__Related_Opportunity__r');
        }
        return builder;
    }
}