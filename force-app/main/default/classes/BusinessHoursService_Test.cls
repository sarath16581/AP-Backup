/**************************************************
Type:	Unit test class for BusinessHoursService
History:
--------------------------------------------------
changelog:
2023-04-19 - hasantha.liyanage@auspost.com.au - created
2024-07-26 - Seth Heang - Add test coverage for calculateNextBusinessDateTime()
**************************************************/
@IsTest(IsParallel=true)
private class BusinessHoursService_Test {
	@IsTest
	static void testCalculateNextBusinessDay() {
		Date dateSent = Date.newInstance(2023, 4, 19);
		Integer maxDays = 3;

		Date expected = Date.newInstance(2023, 4, 24);
		Date actual = BusinessHoursService.newInstance().calculateNextBusinessDay(dateSent, maxDays);

		System.assertEquals(expected, actual);
	}

	@IsTest
	static void testAddDays() {
		Datetime startDate = Datetime.newInstanceGmt(2023, 4, 19);
		Integer days = 3;

		// Expected result, 22nd and 23rd are Weekend days
		Datetime expected = Datetime.newInstanceGmt(2023, 4, 24);
		Datetime actual = BusinessHoursService.newInstance().addDays(startDate, days).date();

		System.assertEquals(expected, actual);
	}

	/**
	 * Scenario: Test the next business date calculation including pre-business and post-business hours on weekdays and weekend
	 *			And validate that the correct dateTime is returned
	 */
	@IsTest
	static void testCalculateNextBusinessDateTime() {
		Integer maxDays = 3;
		BusinessHoursService service = BusinessHoursService.newInstance();

		// pre-business hours calculation after 3 days
		Datetime preBizHourMon = Datetime.newInstance(2024, 7, 22, 7, 0, 0); // 2024-07-22 7AM
		Datetime preBizHourMonExpectedResult = Datetime.newInstance(2024, 7, 25, 8, 0, 0); // 2024-07-25 8AM
		Datetime preBizHourMonActualResult = service.calculateNextBusinessDateTime(preBizHourMon, maxDays);
		Assert.areEqual(preBizHourMonExpectedResult, preBizHourMonActualResult, 'Expect 2024-07-25 8AM but instead got: ' + preBizHourMonActualResult);

		// at closing business hours (Exactly 6 PM) calculation after 3 days
		Datetime atClosingBizHourMon = Datetime.newInstance(2024, 7, 22, 18, 0, 0); // 2024-07-22 6PM
		Datetime atClosingBizHourMonExpectedResult = Datetime.newInstance(2024, 7, 26, 8, 0, 0); // 2024-07-26 8AM
		Datetime atClosingBizHourMonActualResult = service.calculateNextBusinessDateTime(atClosingBizHourMon, maxDays);
		Assert.areEqual(atClosingBizHourMonExpectedResult, atClosingBizHourMonActualResult, 'Expect 2024-07-26 8AM but instead got: ' + atClosingBizHourMonActualResult);

		// post-business hours calculation after 3 days
		Datetime postBizHourMon = Datetime.newInstance(2024, 7, 22, 19, 0, 0); // 2024-07-22 7PM
		Datetime postBizHourMonExpectedResult = Datetime.newInstance(2024, 7, 26, 8, 0, 0); // 2024-07-26 8AM
		Datetime postBizHourMonActualResult = service.calculateNextBusinessDateTime(postBizHourMon, maxDays);
		Assert.areEqual(postBizHourMonExpectedResult, postBizHourMonActualResult, 'Expect 2024-07-26 8AM but instead got: ' + postBizHourMonActualResult);

		// within business hours calculation after 3 days on weekdays
		Datetime withinBizHourMon = Datetime.newInstance(2024, 7, 22, 15, 33, 33); // 2024-07-22 3:33:33PM
		Datetime withinBizHourMonExpectedResult = Datetime.newInstance(2024, 7, 25, 15, 33, 33); // 2024-07-25 3:33:33PM
		Datetime withinBizHourMonActualResult = service.calculateNextBusinessDateTime(withinBizHourMon, maxDays);
		Assert.areEqual(withinBizHourMonExpectedResult, withinBizHourMonActualResult, 'Expect 2024-07-25 3:33:33PM but instead got: ' + withinBizHourMonActualResult);

		// within business hours calculation after 3 days over the weekend
		Datetime withinBizHourFri = Datetime.newInstance(2024, 7, 26, 10, 33, 33); // 2024-07-26 10:15:00 AM
		Datetime withinBizHourFriExpectedResult = Datetime.newInstance(2024, 7, 31, 10, 33, 33); // 2024-07-31 10:15:00 AM
		Datetime withinBizHourFriActualResult = service.calculateNextBusinessDateTime(withinBizHourFri, maxDays);
		Assert.areEqual(withinBizHourFriExpectedResult, withinBizHourFriActualResult, 'Expect 2024-07-25 3:33:33PM but instead got: ' + withinBizHourFriActualResult);

		// outside business hours where startdate is on weekend calculation after 3 days
		Datetime outsideBizHourSat = Datetime.newInstance(2024, 7, 27, 10, 33, 33); // 2024-07-27 10:15:00 AM
		Datetime outsideBizHourSatExpectedResult = Datetime.newInstance(2024, 8, 1, 8, 0, 0); // 2024-08-01 8AM
		Datetime outsideBizHourSatActualResult = service.calculateNextBusinessDateTime(outsideBizHourSat, maxDays);
		Assert.areEqual(outsideBizHourSatExpectedResult, outsideBizHourSatActualResult, 'Expect 2024-07-25 3:33:33PM but instead got: ' + outsideBizHourSatActualResult);
	}
}