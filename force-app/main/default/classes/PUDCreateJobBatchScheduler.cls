global class PUDCreateJobBatchScheduler implements Schedulable{    

    global void execute(SchedulableContext SC) {        
        Boolean bolRefreshAll = false;
        //Call batch job to just create new jobs 
        Id batchInstanceId = Database.executeBatch(new PUDCreateJobBatch(bolRefreshAll),1000);
    }

}