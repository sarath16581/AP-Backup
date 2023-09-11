/**
 * @description       : This is the test class for APT_StarTrackApprovalHeaderFooterImage
 * @author            : Darshan Chauhan
 * @group             : 
 * @last modified on  : 06-30-2021
 * @last modified by  : Darshan Chauhan
 * Modifications Log 
History:
2023-08-28	Naveen Rajanna	REQ3286437 - Changed api version and removed hard coded URL to use apex methods to generate URL
**/
@isTest
public with sharing class APT_StarTrackApprvlHeaderFooterImg_Test {

	//creating test data
	@TestSetup
	static void createData(){
		Apttus_Config2__ConfigSystemProperties__c configSystemProperties = new Apttus_Config2__ConfigSystemProperties__c();
		configSystemProperties.Name = 'System Properties';
		configSystemProperties.Apttus_Config2__InstanceUrl__c = System.URL.getSalesforceBaseUrl().toExternalForm();
		insert configSystemProperties;

		Document document;

		document = new Document();
		document.Body = Blob.valueOf('Some Text');
		document.ContentType = 'application/pdf';
		document.DeveloperName = 'APT_StarTrack_Approval_Footer_Logo';
		document.IsPublic = true;
		document.Name = 'My Document';
		// document.FolderId = [select id from folder where name = 'My Test Docs'].id;
		document.AuthorId = UserInfo.getUserId();
		document.FolderId = UserInfo.getUserId();
		insert document;

		Document document1;

		document1 = new Document();
		document1.Body = Blob.valueOf('Some Text');
		document1.ContentType = 'application/pdf';
		document1.DeveloperName = 'APT_StarTrack_Approval_Header_Logo';
		document1.IsPublic = true;
		document1.Name = 'My Document';
		// document.FolderId = [select id from folder where name = 'My Test Docs'].id;
		document1.AuthorId = UserInfo.getUserId();
		document1.FolderId = UserInfo.getUserId();
		insert document1;
	}

	//test method for getHeaderURL
	@isTest
	static void getHeaderURLTest() {
		APT_StarTrackApprovalHeaderFooterImage stphfi = new APT_StarTrackApprovalHeaderFooterImage();
		test.startTest();
		stphfi.getHeaderURL();
		test.stopTest();
	}

	//test method for getFooterURL
	@isTest
	static void getFooterURLTest() {
		APT_StarTrackApprovalHeaderFooterImage stphfi = new APT_StarTrackApprovalHeaderFooterImage();
		test.startTest();
		stphfi.getFooterURL();
		test.stopTest();
	}
	
}