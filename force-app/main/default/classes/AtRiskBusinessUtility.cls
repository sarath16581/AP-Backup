public inherited sharing class AtRiskBusinessUtility {
	private static final List<String> monthNames = new List<String>{'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};

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
			List<String> previousFYMonths = new List<String>();
			List<String> currentFYMonths = new List<String>();
	
			if (month <= 6) {
				for (Integer m = 6; m < 12; m++) {
					currentFYMonths.add(monthNames[m]);
				}
				for (Integer m = 0; m < (month - 1); m++) {
					currentFYMonths.add(monthNames[m]);
				}
				for (Integer m = (month - 1); m < 6; m++) {
					previousFYMonths.add(monthNames[m]);
				}
			} else {
				for (Integer m = 6; m < (month - 1); m++) {
					currentFYMonths.add(monthNames[m]);
				}
				
				for (Integer m = (month - 1); m < 12; m++) {
					previousFYMonths.add(monthNames[m]);
				}
				for (Integer m = 0; m < 6; m++) {
					previousFYMonths.add(monthNames[m]);
				}
				
			}
	
			financialYearMonths.put(String.valueOf(year - 1), previousFYMonths);
			financialYearMonths.put(String.valueOf(year), currentFYMonths);
		}

		return financialYearMonths;
	}
}