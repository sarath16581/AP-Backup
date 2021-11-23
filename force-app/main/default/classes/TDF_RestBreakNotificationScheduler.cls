global class TDF_RestBreakNotificationScheduler implements Schedulable{
    
	public String chatterFeedMessageStr = '';

    public TDF_RestBreakNotificationScheduler(String msg){
    	chatterFeedMessageStr = msg;
    }

    global void execute(SchedulableContext SC) {    	
    	TDF_SchedulerUtility objScheduler = new TDF_SchedulerUtility(chatterFeedMessageStr);
    	objScheduler.restBreakNotifications();
    }
}