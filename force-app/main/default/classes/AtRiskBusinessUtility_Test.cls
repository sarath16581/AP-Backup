@isTest
public class AtRiskBusinessUtility_Test {
	private static final List<String> monthNames = new List<String>{'Jul','Aug','Sep','Oct','Nov','Dec', 'Jan','Feb','Mar','Apr','May','Jun'};
    
	// 1) Querying 1 single FY record
	// Running this function with calendar month July 2023 should return only 1 entry for all months in FY2023
	@isTest
	static void testJuly() {
		// 1st July
		Date testDate = Date.newInstance(2023, 7, 1);

		Map<String, List<String>> fyMonths = AtRiskBusinessUtility.getFinancialYearsAndMonths(testDate);

		Assert.isTrue(fyMonths.keySet().contains('2023'));

		List<String> months = fyMonths.get('2023');

		for (Integer m = 0; m < months.size(); m++) {
			Assert.areEqual(monthNames[m], months[m]);
		}
	}

	// 2) Querying 2 FY records (where the previous 12 months cross an FY bounds)
	// Running with April 2023 should return 2 lists:
	// * Jul -> Mar 2023
	// * Apr -> Jun 2022
	@isTest
	static void testApril() {
		// 1st April
		Date testDate = Date.newInstance(2023, 4, 1);

		Map<String, List<String>> fyMonths = AtRiskBusinessUtility.getFinancialYearsAndMonths(testDate);

		Assert.isTrue(fyMonths.keySet().contains('2023'));
		Assert.isTrue(fyMonths.keySet().contains('2022'));

		List<String> monthsFY2023 = new List<String>{'Jul','Aug','Sep','Oct','Nov','Dec','Jan','Feb','Mar'};
		List<String> months = fyMonths.get('2023');
		for (Integer m = 0; m < months.size(); m++) {
			Assert.areEqual(monthsFY2023[m], months[m]);
		}

		List<String> monthsFY2022 = new List<String>{'Apr','May','Jun'};
		months = fyMonths.get('2022');
		for (Integer m = 0; m < months.size(); m++) {
			Assert.areEqual(monthsFY2022[m], months[m]);
		}
	}

	// 3) Querying 2 FY records (where the previous 12 months cross an FY bounds)
	// Running with December 2023 should return 2 lists:
	// * Jul -> Nov 2024
	// * Dec -> Jun 2023
	@isTest
	static void testDecember() {
		// 1st December
		Date testDate = Date.newInstance(2023, 12, 1);

		Map<String, List<String>> fyMonths = AtRiskBusinessUtility.getFinancialYearsAndMonths(testDate);

		Assert.isTrue(fyMonths.keySet().contains('2024'));
		Assert.isTrue(fyMonths.keySet().contains('2023'));

		List<String> monthsFY2024 = new List<String>{'Jul', 'Aug', 'Sep', 'Oct', 'Nov'};
		List<String> months = fyMonths.get('2024');
		for (Integer m = 0; m < months.size(); m++) {
			Assert.areEqual(monthsFY2024[m], months[m]);
		}

		List<String> monthsFY2023 = new List<String>{'Dec', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'};
		months = fyMonths.get('2023');
		for (Integer m = 0; m < months.size(); m++) {
			Assert.areEqual(monthsFY2023[m], months[m]);
		}
	}

	// 4) Querying 2 FY records (where the previous 12 months cross an FY bounds)
	// Running with June 2023 should return 2 lists:
	// * Jul -> May 2023
	// * June 2022
	@isTest
	static void testJune() {
		// 1st December
		Date testDate = Date.newInstance(2023, 6, 1);

		Map<String, List<String>> fyMonths = AtRiskBusinessUtility.getFinancialYearsAndMonths(testDate);

		Assert.isTrue(fyMonths.keySet().contains('2023'));
		Assert.isTrue(fyMonths.keySet().contains('2022'));

		List<String> monthsFY2023 = new List<String>{'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar', 'Apr', 'May'};
		List<String> months = fyMonths.get('2023');
		for (Integer m = 0; m < months.size(); m++) {
			Assert.areEqual(monthsFY2023[m], months[m]);
		}

		List<String> monthsFY2022 = new List<String>{'Jun'};
		months = fyMonths.get('2022');
		for (Integer m = 0; m < months.size(); m++) {
			Assert.areEqual(monthsFY2022[m], months[m]);
		}
	}

	// 5) Querying 2 FY records (where the previous 12 months cross an FY bounds)
	// Running with October 2023 should return 2 lists:
	// * Jul -> Sep 2024
	// * Oct -> Jun 2023
	@isTest
	static void testOctober() {
		// 1st December
		Date testDate = Date.newInstance(2023, 10, 1);

		Map<String, List<String>> fyMonths = AtRiskBusinessUtility.getFinancialYearsAndMonths(testDate);

		Assert.isTrue(fyMonths.keySet().contains('2024'));
		Assert.isTrue(fyMonths.keySet().contains('2023'));

		List<String> monthsFY2024 = new List<String>{'Jul', 'Aug', 'Sep'};
		List<String> months = fyMonths.get('2024');
		for (Integer m = 0; m < months.size(); m++) {
			Assert.areEqual(monthsFY2024[m], months[m]);
		}

		List<String> monthsFY2023 = new List<String>{ 'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'};
		months = fyMonths.get('2023');
		for (Integer m = 0; m < months.size(); m++) {
			Assert.areEqual(monthsFY2023[m], months[m]);
		}
	}
}