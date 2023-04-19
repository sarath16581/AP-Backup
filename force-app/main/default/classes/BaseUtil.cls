/**************************************************
Type:         Commonly shared utilities for tracking related classes
History:
--------------------------------------------------
19/04/2023    Created : hasantha.liyanage@auspost.com.au DDS-15568 FOHS -BSP - Holding Bay - Case held before EDD+10 day
**************************************************/
public virtual inherited sharing class BaseUtil {

	/**
		 @Description : Returns the next business day considering the weekends and holidays
		 @param : date dateSent(EDD derived from consignment service) , integer maxDays(days configured as the latest date by which consignments shoulf arrive)
		 @return : NA
	 */
	public static Date calculateNextBusinessDay(Date dateSent, Integer maxDays) {
		Datetime maxDeliveryDate = addDays(dateSent, maxDays);
		return maxDeliveryDate.date();
	}

	/**
	 * Add business days to a given date based on the parameters passed
	 * */
	public static Datetime addDays(Datetime startDate, Integer days) {
		Id bHours = getDefaultBusinessHours().Id;

		for (Integer elapsed = 0; elapsed < days; elapsed++) {
			//Add 1 day
			startDate = startDate.addDays(1);

			//Check if new date is within working days
			if (!BusinessHours.isWithin(bHours, startDate)) {
				//If new date is not within working days, get new working day
				startDate = BusinessHours.nextStartDate(bHours, startDate);
			}
		}
		return startDate;
	}

	public static BusinessHours getDefaultBusinessHours() {
		return BusinessHoursSelector.newInstance().selectDefault(true);
	}

}