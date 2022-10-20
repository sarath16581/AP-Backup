/**
 * @author Naveen Rajanna
 * @date 2022-10-12
 * @group Tests
 * @description Test class covering EmailMessageCasesDomain
 * @changelog
 */
@IsTest
private class EmailMessageCasesDomain_Test {
	/**
	 * Validate if the filter on EmailMessageCasesDomain filters records as expected
	 */
	@IsTest
	private static void testEmailMessageCasesDomain() {
		Case caseRec = ApplicationTestDataFactory.getCases(1, true)[0];
		List<EmailMessage> emailList = ApplicationTestDataFactory.getEmailMessages(
			2,
			true,
			true,
			'fromAddress@test.com',
			'toAddress@auspost.com.au',
			null,
			null,
			'Subject Inbound',
			null
		);
		emailList[1] = (EmailMessage) ApplicationTestDataFactory.setUnwritableFields(
			emailList[1],
			new Map<String, Object>{ 'ParentId' => caseRec.Id }
		);

		EmailMessageCasesDomain domain = EmailMessageCasesDomain.newInstance(emailList);

		// Verify if records have been filtered based on ParentId
		System.assertEquals(1, domain.records.size(), 'Records should have been filtered in call to newInstance');
		System.assertEquals(caseRec.Id, ((EmailMessage) domain.records[0]).ParentId, 'Expected ParentId to be populated');
	}
}
