/**
 * @author Prerna Rahangdale
 * @date 2022-22-11
 * @group Selector
 * @tag Selector
 * @tag StartTrackTransferCaseRule SObject
 * @domain Core
 * @description A very simple selector class that sits in the base domain
 * @changelog
 * 2022-04-10 - Prerna Rahangdale - Created
*/

public virtual inherited sharing class StartTrackTransferCaseRulesSelector extends ApplicationSelector {

        public enum Options {
                ORDER_BY_ORDERFIELD
        }

        public static StartTrackTransferCaseRulesSelector newInstance() {
                return (StartTrackTransferCaseRulesSelector)ApplicationSelector.newInstance(StartTrackTransferCaseRulesSelector.class);
        }

        public static StartTrackTransferCaseRulesSelector newInstance(Set<SObjectField> fieldOverrides) {
                StartTrackTransferCaseRulesSelector rulesSelector =
                 (StartTrackTransferCaseRulesSelector)ApplicationSelector.newInstance(StartTrackTransferCaseRulesSelector.class);
                rulesSelector.setFieldOverrides(fieldOverrides);
                return rulesSelector;
        }

        public override SObjectType getSObjectType(){
                return StarTrack_Transfer_Case_Rule__c.getSObjectType();
        }

        public virtual override Set<SObjectField> getSObjectFieldList() {
                return new Set<SObjectField> {
                        StarTrack_Transfer_Case_Rule__c.Id, StarTrack_Transfer_Case_Rule__c.Business_Solutions_Customer__c,
                        StarTrack_Transfer_Case_Rule__c.Case_Purpose__c, StarTrack_Transfer_Case_Rule__c.Case_RecordType__c,
                        StarTrack_Transfer_Case_Rule__c.Case_Type__c, StarTrack_Transfer_Case_Rule__c.Customer_Stream__c,
                        StarTrack_Transfer_Case_Rule__c.Service_Cloud_Rule__c, StarTrack_Transfer_Case_Rule__c.Initial_Caller_Type__c,
                        StarTrack_Transfer_Case_Rule__c.Order__c, StarTrack_Transfer_Case_Rule__c.Product_Group__c,
                        StarTrack_Transfer_Case_Rule__c.Queue_Name__c
                };
        }

        public List<StarTrack_Transfer_Case_Rule__c> selectAll(Set<Object> selectorOptions){
                QueryBuilder builder = newQueryBuilder(selectorOptions);
                if (selectorOptions.contains(Options.ORDER_BY_ORDERFIELD)) {
                        builder.addOrderAsc(StarTrack_Transfer_Case_Rule__c.ORDER__C);
                }
                return new List<StarTrack_Transfer_Case_Rule__c>((List<StarTrack_Transfer_Case_Rule__c>)Database.query(builder.toSoqlString()));
        }
}