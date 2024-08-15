/**************************************************
Type:	Service Class for business hours related functionalities
History:
--------------------------------------------------
2023-04-19 - hasantha.liyanage@auspost.com.au - created DDS-15568 FOHS -BSP - Holding Bay - Case held before EDD+10 day
2024-08-01 - Seth Heang - Added Default Business Hours into Platform Cache
2024-07-23 - Seth Heang - Added calculateNextBusinessDateTime method to return dateTime value
**************************************************/

public with sharing class BusinessHoursService extends ApplicationDomain.Module {
	/**
	 * @description Retrieve default BusinessHours from PlatformCache if exists
	 */
	private static final BusinessHours DEFAULT_BUSINESS_HOURS {
		get {
			if (DEFAULT_BUSINESS_HOURS == null) {
				DEFAULT_BUSINESS_HOURS = (BusinessHours) CacheManager.get('DEFAULT_BUSINESS_HOURS');
				if (DEFAULT_BUSINESS_HOURS == null) {
					DEFAULT_BUSINESS_HOURS = BusinessHoursSelector.newInstance().selectDefault(true);
					CacheManager.put('DEFAULT_BUSINESS_HOURS', DEFAULT_BUSINESS_HOURS);
				}
			}
			return DEFAULT_BUSINESS_HOURS;
		}
		private set;
	}
	
	public static BusinessHoursService newInstance() {
		return (BusinessHoursService) Application.Utilities.getInstance(BusinessHoursService.class);
	}

	/**
		 @Description : Returns the next business day considering the weekends and holidays
		 @param : date dateSent(EDD derived from consignment service) , integer maxDays(days configured as the latest date by which consignments shoulf arrive)
		 @return : NA
	 */
	public Date calculateNextBusinessDay(Date dateSent, Integer maxDays) {
		Datetime maxDeliveryDate = addDays(dateSent, maxDays);
		return maxDeliveryDate.date();
	}

	/**
	 * @description Returns the next business day considering the weekends and holidays
	 * @param dateTimeSent starting date where the next business date calculation is based on
	 * @param maxDays number of days in the future
	 * @return Datetime
	 */
	public Datetime calculateNextBusinessDateTime(Datetime dateTimeSent, Integer maxDays) {
		Id bHours = DEFAULT_BUSINESS_HOURS.Id;
		Datetime bizDate = dateTimeSent;
		for (Integer elapsed = 0; elapsed < maxDays; elapsed++) {
			// format day and get the day of week
			String bizDayOfWeek = bizDate.format('EEEE');
			if (bizDayOfWeek.equals('Saturday') || bizDayOfWeek.equals('Sunday')) {
				// Set to Next Monday and reset the time to opening business hour on Monday e.g. 8AM
				bizDate = BusinessHours.nextStartDate(bHours, bizDate);
			} else if (bizDayOfWeek.equals('Friday')) {
				// Add 2 days and keep time value intact
				bizDate = bizDate.addDays(2);
			}
			// Add 1 day
			bizDate = bizDate.addDays(1);
			//Check if new date is within working days
			if (!BusinessHours.isWithin(bHours, bizDate)) {
				//If new date is not within working days, get new working day
				bizDate = BusinessHours.nextStartDate(bHours, bizDate); // 7AM -> 8AM same day, 7PM -> 8AM next day
			}
		}
		return bizDate;
	}

	/**
	 * @description Add business days to a given date based on the parameters passed
	 * @param startDate
	 * @param days
	 * @return Datetime
	 */
	public Datetime addDays(Datetime startDate, Integer days) {
		Id bHours = DEFAULT_BUSINESS_HOURS.Id;

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
}