/**
 * @description       : This is a Domain Trigger Handler class for CaseInvestigation
 * @author            : George Nguyen
 * @domain            : Case
 * @changelog
 * 2022-12-05 - George Nguyen - created
 * 2022-12-23 - Dattaraj Deshmukh - Added Case.SobjectType to SObjectType list.
 * @Test CaseInvestigationDomainTrgrHdlr_Test
 **/
public inherited sharing class CaseInvestigationDomainTriggerHandler extends ApplicationDomainTriggerHandler {

	public static CaseInvestigationDomainTriggerHandler newInstance() {
		return (CaseInvestigationDomainTriggerHandler)Application.Utilities.newInstance(CaseInvestigationDomainTriggerHandler.class);
	}

	public override SObjectType getSObjectType() {
		return CaseInvestigation__c.SObjectType;
	}

	public override List<Type> registerDomains() {
		return new List<Type>{ STCaseInvestigationDomain.class };
	}

	public override ApplicationUnitOfWork newUnitOfWork() {
		return ApplicationUnitOfWork.newInstance(getUnitOfWorkSObjectTypes());
	}

	public static List<SObjectType> getUnitOfWorkSObjectTypes() {
		return new List<SObjectType>{ CaseInvestigation__c.SObjectType,  Case.SObjectType };
	}
}
