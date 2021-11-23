/* 
 * Report Aggregate Util class built by Carl Vescovi (Australia Post) 24/11/11
 * Purpose of the Class follows;
 * Aggregates are custom object records of 'Report Aggregate' sObject, that exists to 
 * pull together opportunity, line item, product and other information in a way that allows std
 * reporting engine to generate a weekly summary of top 3 OLI values and Oppty details per product family.
 * this is a requirement of the Sales Management Team reporting pack for R1
 * this schedulable class generates these records on a regular automated basis per the apex scheduler.
 * 
 * @changelog
 * 2021-08-27 - Seth Heang - Uplift the class to SF version 52
 */

global class runReportingAggregates implements Schedulable {
    
    global void execute(SchedulableContext SC) {
        reportingAggregateUtils.deleteAggregates();
        reportingAggregateUtils.generateAggregatesForFamily();
        reportingAggregateUtils.generateAggregatesforSector();
        }
}