public inherited sharing class AtRiskBusinessUtility {
	private static final List<String> monthNames = new List<String>{'Jul','Aug','Sep','Oct','Nov','Dec', 'Jan','Feb','Mar','Apr','May','Jun'};

	private static Integer getFYMonth(Integer calendarMonth) {
		return calendarMonth > 7 ? (calendarMonth - 6) : (calendarMonth + 6);
	}

    /*
	 * @description Given a date, return the financial years and names of months going back 12 months (from before the month of the given date)
	 */
	public static Map<String, List<String>> getFinancialYearsAndMonths(Date atRiskDate) {
		Integer year = atRiskDate.year();
		Integer month = atRiskDate.month();
		
		Map<String, List<String>> financialYearMonths = new Map<String, List<String>>();

		if (month == 7) {
			// When the Calendar Month is July, the Financial Year is the same as the Calendar Year
			// and all months of the previous FY should be returned
			financialYearMonths.put(String.valueOf(year), monthNames);
		} else {
			// If the Calendar Month is between Jan and Jun, then the Previous FY is (Current Calendar Year - 1),
			// or else FY and Calendar Year are the same
			Integer previousFY = (month <= 6) ? (year - 1) : year;

			// If the Calendar Month is between Jul and Dec, then the Current FY is (Current Calendar Year + 1),
			// or else FY and Calendar Year are the same
			Integer currentFY  = (month > 6) ?  (year + 1): year;

			List<String> previousFYMonths = new List<String>();
			List<String> currentFYMonths = new List<String>();

			Integer fyMonth = getFYMonth(month);

			for (Integer m = (fyMonth - 1); m < 12; m++) {
				previousFYMonths.add(monthNames[m]);
			}

			for (Integer m = 0; m < (fyMonth - 1); m++) {
				currentFYMonths.add(monthNames[m]);
			}
	
			financialYearMonths.put(String.valueOf(previousFY), previousFYMonths);
			financialYearMonths.put(String.valueOf(currentFY), currentFYMonths);
		}

		return financialYearMonths;
	}
}