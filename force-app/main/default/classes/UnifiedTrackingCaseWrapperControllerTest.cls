@isTest
public class UnifiedTrackingCaseWrapperControllerTest {
	@isTest
    public static void testUnifiedTrackingRecordType() {
		Boolean isUnifiedCase = UnifiedTrackingCaseWrapperController.isUnifiedCase('UnifiedGeneralEnquiry');
		System.assertEquals(true, isUnifiedCase, 'Unified case record');
    }

	@isTest
    public static void testNotUnifiedTrackingRecordType() {
		Boolean isUnifiedCase = UnifiedTrackingCaseWrapperController.isUnifiedCase('Business_Sales_Implementation');
		System.assertEquals(false, isUnifiedCase, 'Unified case record');
    }
}