global class TDF_UnfollowWorkOrderScheduler implements Schedulable{    

    global void execute(SchedulableContext SC){        
        TDF_UnfollowWorkOrderBatch objUnfollowBatch = new TDF_UnfollowWorkOrderBatch();
        Database.executeBatch(objUnfollowBatch,25);
    }
}