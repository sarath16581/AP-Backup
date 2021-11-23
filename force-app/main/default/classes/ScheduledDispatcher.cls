/***
This class can be used to schedule any scheduled job without risk of locking the class.
DO NOT CHANGE THIS CLASS! It is locked by the scheduler. Instead make changes to ScheduledHelper or your own IScheduleDispatched class
To use:
	1) Create a new class to handle your job. This class should implement ScheduledDispatcher.IScheduleDispatched
	2) Create a new instance of ScheduledDispatcher with the type of your new class.
	3) Schedule the ScheduledDispatcher instead of directly scheduling your new class.
	See ScheduledRenewalsHandler for a working example.
***/
global class ScheduledDispatcher implements Schedulable {
	private Type targetType; 
	
	public ScheduledDispatcher(Type targetType) {
		System.debug('Creating new dispatcher for class: ' + targetType.getName());
		this.targetType = targetType;
	}
	
	global void execute(SchedulableContext sc) {
		((IScheduleDispatched)targetType.newInstance()).execute(sc); 
	}
	
	
	public interface IScheduleDispatched {
		void execute(SchedulableContext sc);
	}
	
}