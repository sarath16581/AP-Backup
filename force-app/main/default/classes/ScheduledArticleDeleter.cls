global class ScheduledArticleDeleter implements Schedulable {
	public static final String DEFAULT_NAME = 'ScheduledArticleDeleter';
	public static final String CRON_EXP = '0 0 1 ? * 7L';//runs last Saturday of the month at 1 am
	
	global void execute(SchedulableContext sc) {
		Database.executeBatch(new BatchableArticleDeleter());
	}
	
	public static String start() {
		return start(DEFAULT_NAME, CRON_EXP);
	}		
	
	public static String start(String name) {
		return start(name, CRON_EXP);
	}
	
	public static String start(String name, String cronExp) {
		return System.schedule(name, cronExp, new ScheduledArticleDeleter());
	}
}