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
			financialYearMonths.put(String.valueOf(year), monthNames);
		} else {
			Integer previousFY = (month <= 6) ? (year - 1) : year;
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