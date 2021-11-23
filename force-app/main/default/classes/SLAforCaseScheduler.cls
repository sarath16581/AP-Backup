/*
 * @author: Rajesh P. (Mav3rik)
 * @description: This is scheduler class, calling SLAforCases Batch Job.
 * @history:11-APR-2019, class created.
*/
global with sharing class SLAforCaseScheduler implements Schedulable{
    global void execute(SchedulableContext sc) {
        SLAforCases slabatch = new SLAforCases();
        Database.executeBatch(slabatch);
    }
}