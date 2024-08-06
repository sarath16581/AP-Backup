/**************************************************
Type:	Service Class for business hours related functionalities
History:
--------------------------------------------------
2023-04-19 - hasantha.liyanage@auspost.com.au - created DDS-15568 FOHS -BSP - Holding Bay - Case held before EDD+10 day
2024-08-01 - Seth Heang - Added Default Business Hours into Platform Cache
**************************************************/

public with sharing class BusinessHoursService extends ApplicationDomain.Module {
	/**
	 * @description Retrieve default BusinessHours, and save as a constant for repeated usage
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
	 * Add business days to a given date based on the parameters passed
	 * */
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