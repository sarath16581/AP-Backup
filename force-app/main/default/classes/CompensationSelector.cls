/**
 * @author Phap Mai
 * @date 2021-07-12
 * @group Selector
 * @tag Selector
 * @tag Compensation
 * @domain Core
 * @description Compensation selector class
 * @changelog
 * 2021-07-12 - Phap Mai - Init
 * 2023-07-25 - Hasantha Liyanage - Modified: added SelectByCaseIds
 * 2023-09-11 - Hasantha Liyanage - Modified: added Compensation__c.RecordTypeId field
 */
public virtual inherited sharing class CompensationSelector extends ApplicationSelector
{
    public enum Options
    {   
        WITH_OVERRIDE_CASE, WITH_OVERRIDE_RECORD_TYPE, WITH_CASE, WITH_RECORD_TYPE
    }
    
    // define fields from parent object of compensation, will be used to override fields in parent selector
    public Map<SObjectType, Set<SObjectField>> moreFields;

    /**
     * Constructor
     */
    public CompensationSelector()
    {
        this.moreFields = new Map<SObjectType, Set<SObjectField>> {
            Case.getSObjectType() => new Set<SObjectField>
            {
                Case.ContactEmail,
                Case.CaseNumber,
                Case.EnquirySubType__c,
                Case.DescriptionofContents__c,
                Case.ContactId,
                Case.Address4__c,
                Case.Address4Line2__c,
                Case.Address4Suburb__c,
                Case.Address4State__c,
                Case.Address4Postcode__c,
                Case.Address4Country__c
            },
            RecordType.getSObjectType() => new Set<SObjectField>
            {
                RecordType.DeveloperName
            }
        };
    }


    public static CompensationSelector newInstance()
    {
		return (CompensationSelector) Application.Selectors.newInstance(CompensationSelector.class);
	}

	public static CompensationSelector newInstance(Integer recordLimit)
    {
		return (CompensationSelector) Application.Selectors.newInstance(CompensationSelector.class).setLimit(recordLimit);
	}

    /**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static CompensationSelector newInstance(Set<SObjectField> fieldOverrides)
    {
		CompensationSelector selector = (CompensationSelector)Application.Selectors.newInstance(CompensationSelector.class);
		selector.setFieldOverrides(fieldOverrides);
		return selector;
	}

    /**
	 * NOTE: Field overrides should only ever be used when the results are not passed from method to method.
	 * This approach removes data consistency and prevents possible caching of results
	 */
	public static CompensationSelector newInstance(Integer recordLimit, Set<SObjectField> fieldOverrides)
    {
		CompensationSelector selector = (CompensationSelector)Application.Selectors.newInstance(CompensationSelector.class).setLimit(recordLimit);
		selector.setFieldOverrides(fieldOverrides);
		return selector;
	}

    public virtual override SObjectType getSObjectType()
    {
        return Compensation__c.getSObjectType();
    }

    public virtual override Set<SObjectField> getSObjectFieldList()
    {
        return new Set<SObjectField>
        {
            Compensation__c.Id,
            Compensation__c.Name,
            Compensation__c.Compensation_Form_Attemps__c,
            Compensation__c.Case__c,
            Compensation__c.Total_Compensation_Amount__c,
            Compensation__c.Status__c,
            Compensation__c.Account_Name__c,
            Compensation__c.Account_Number__c,
            Compensation__c.BSB__c,
            Compensation__c.Bank_Detail_Provided_By_Customer__c,
            Compensation__c.RecordTypeId
        };
	}

    public virtual override QueryBuilder newQueryBuilder() {
		return newQueryBuilder(new Set<Object>());
	}

    public virtual override QueryBuilder newQueryBuilder(Set<Object> selectorOptions)
    {
        QueryBuilder builder = super.newQueryBuilder(selectorOptions);

        if (selectorOptions.contains(Options.WITH_OVERRIDE_CASE))
            builder.addRelatedFields(CasesSelector.newInstance().setFieldOverrides(this.moreFields).newQueryBuilder(), 'Case__r');
        
        if (selectorOptions.contains(Options.WITH_OVERRIDE_RECORD_TYPE))
            builder.addRelatedFields(RecordTypesSelector.newInstance().setFieldOverrides(this.moreFields).newQueryBuilder(), 'RecordType');

        if (selectorOptions.contains(Options.WITH_CASE))
            builder.addRelatedFields(CasesSelector.newInstance().newQueryBuilder(), 'Case__r');

        if (selectorOptions.contains(Options.WITH_RECORD_TYPE))
            builder.addRelatedFields(CasesSelector.newInstance().newQueryBuilder(), 'RecordType');

        return builder;
    }

    public virtual List<Compensation__c> selectByCaseIds(Set<Id> ids, Set<Object> selectorOptions) {
        QueryBuilder qb = newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Compensation__c.Case__c + ' in :ids')).endConditions();
        return (List<Compensation__c>)Database.query(qb.toSoqlString());
    }

    public virtual List<Compensation__c> getByToken(String token, Set<Object> selectorOptions)
    {
        QueryBuilder qb = this.newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Compensation__c.Compensation_Form_Token__c + ' = :token')).endConditions();
        return (List<Compensation__c>) Database.query(qb.toSoqlString());
    }

    public virtual List<Compensation__c> getById(String Id, Set<Object> selectorOptions)
    {
        QueryBuilder qb = this.newQueryBuilder(selectorOptions).addConditions().add(new QueryBuilder.SimpleCondition(Compensation__c.Id + ' = :Id')).endConditions();
        return (List<Compensation__c>) Database.query(qb.toSoqlString());
    }
}