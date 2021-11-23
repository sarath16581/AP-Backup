global class ScheduledJobTokenRequest implements Schedulable {   
 
    public static final String DEFAULT_NAME = 'Request Token for Address Validation';
    public static final String CRON_EXP = '0 0 5,12 * * ?'; //runs at 5 am and 12 pm
 
    global void execute(SchedulableContext sc) {
        if(!Test.isRunningTest()) {
            AddressValidationService.updateToken();
        } else {
            system.debug('Temporary fix to avoid YOU have uncommitted work pending. Please commit or rollback before CALLING OUT exception');
        }
    }
    
    public static String schedule() {
        return schedule(DEFAULT_NAME);
    }
    
    public static String schedule(String name) {
        return schedule(name, CRON_EXP);
    }
    
    public static String schedule(String name, String cronExp) {
        return System.schedule(name, cronExp, new ScheduledJobTokenRequest());
    }   
}