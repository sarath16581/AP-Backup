/**
 * @author Hasantha Liyanage
 * @date 2022-07-04
 * @group Chas
 * @domain Help & Support
 * @description ChasBase
 * @changelog
 * 2022-07-04 - Hasantha Liyanage - Created
 */
@IsTest
private class ChasBaseTest {

	@IsTest
	public static void ChasBase_SharingBypass_createComment() {
		try{
			//-- Create Case
			Id SSSWGeneralRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
					.get(ChasConstants.CASE_RECORDTYPE_SSSWGENERALDELIVERY).getRecordTypeId();
			String origin = 'Web';
			String type = 'General Enquiry';
			String typeAndProduct = 'General Enquiry|Domestic Parcels|Parcel Post';
			String enquirySubType = 'Tracking';
			String  productCategory = 'Domestic Parcels';
			String productSubCategory = 'Parcel Post';
			String CHASEnquiryType='Complaints & feedback';
			Case toBeCreateCase = new Case(
					RecordTypeId=SSSWGeneralRecordTypeId,
					Origin=origin,
					First_Name__c = 'Given Name',
					Last_Name__c='A',
					SuppliedEmail='a@gmail.com',
					SuppliedPhone='099999999',
					Subject='subject1',
					Type=type,
					Type_and_Product__c = typeAndProduct,
					EnquirySubType__c = enquirySubType,
					ProductCategory__c = productCategory,
					ProductSubCategory__c = productSubCategory,
					CHASEnquiryType__c = CHASEnquiryType,
					ValueofContents__c =25);
			Case errorCase = new case();
			//-- Crating Case
			Database.SaveResult[] results = Database.insert(new SObject[] {toBeCreateCase,errorCase });
			//-- Parse Case results and create Case Comment
			ChasBase.SharingBypass lSharingBypass = new ChasBase.SharingBypass();
			lSharingBypass.parseInsertedCaseResultsAndCreateComment(results, new ChasBase.CaseWrapper(), new List<CaseComment>{new CaseComment(CommentBody = 'Test comment Body')});
			//-- Create Case Comment
		}catch(Exception ex){
			System.debug(LoggingLevel.ERROR, 'ChasCustomCaseListAndDetailTest::dataSetUp() ==>Error occoured while creating Case/Case comment in data setup of test class==>'+ex);
		}
		// TODO: assertions to be done as last minute fix
	}

	@IsTest
	public static void ChasBase_setDirectRoutingValues() {
		Network__c network = ApplicationTestDataFactory.getNetworks(1,false)[0];
		network.Contact_Facility__c = 'MyNetwork';
		network.Org_ID__c = '12345';
		insert network;

		Case newCase = ApplicationTestDataFactory.getCases(1, false)[0];
		newCase.ReferenceID__c = 'testrefid0000000';
		newCase.Type = 'testcasetype';
		newCase.ProductCategory__c = 'testproductcat';
		newCase.ProductSubCategory__c = 'testproductsubcat';
		newCase.EstimatedDelivery__c = System.date.Today();


		Test.startTest();
		ChasBase.SharingBypass vSharingBypass = new ChasBase.SharingBypass();
		Id vNetworkId = vSharingBypass.getNetworkIdByOrgId('12345');
		system.debug('HASA: '+vNetworkId);
		ChasBase.setDirectRoutingValues(newCase, ChasBase.RoutingBypass.NETWORK, '12345');
		ChasBase.setDirectRoutingValues(newCase, ChasBase.RoutingBypass.HOLD, '12345');
		// TODO: assertions to be done as last minute fix
		Test.stopTest();
	}
}