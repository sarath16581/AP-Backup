/**
 * @author Harry Wang
 * @date 2022-03-21
 * @group Tests
 * @domain ICPS
 * @description Contains all the test data methods for ICPS test classes
 * @changelog
 * 2022-03-21 - Harry Wang - Created
 */
@IsTest
public class ICPSTestDataFactory {
    public static List<ICPS__c> getICPS(Integer count, Boolean generateIds) {
        return (List<ICPS__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(ICPS__c.SObjectType, new Map<SObjectField, Object> {
                ICPS__c.MailCategory__c => 'Ordinary',
                ICPS__c.StoredLocation__c => 'Bulk I',
                ICPS__c.ItemType__c => 'Air',
                ICPS__c.ReceiverName__c => 'Test Receiver',
                ICPS__c.CountryofOrigin__c => 'USA',
                ICPS__c.FirstNoticeDate__c => Date.newInstance(2022, 2, 22),
                ICPS__c.FinalNoticeDate__c => Date.newInstance(2022, 2, 22)
        }, count), generateIds);
    }

    public static List<ICPSArticle__c> getICPSArticles(Id icpsId, Integer count, Boolean generateIds) {
        return (List<ICPSArticle__c>)ApplicationTestDataFactory.maybeGenerateIds(ApplicationTestDataFactory.populateSObjects(ICPSArticle__c.SObjectType, new Map<SObjectField, Object> {
                ICPSArticle__c.ICPS__c => icpsId,
                ICPSArticle__c.DeclaredValue__c => 999.99,
                ICPSArticle__c.Weight__c => 0,
                ICPSArticle__c.PostageInsurance__c => 0
        }, count), generateIds);
    }
}