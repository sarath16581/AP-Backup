/**
  * @author       : eric.shen@auspost.com.au
  * @date         : 2016-09-05
  * @description  : Trigger Class for Email Message
  * @changelog
-----------------------------------------------------------------------------------------
2016-09-05  eric.shen@auspost.com.au  add methods to parse email body for snap it case
2018-07-10  nathan.franklin@auspost.com.au  Renamed checkNPS to setEmailToCaseAddress as it's a more meaningful name
2019-02-22  nathan.franklin@auspost.com.au  Added CaseActivity__c integration for first response SLA reporting
2021-11-30  ashapriya.gadi@auspost.com.au   Added a call to ServiceAdvisorEmailMessageTriggerHandler as part of SMWD-312 - MW0004779
2022-02-10  naveen.rajanna@auspost.com.au   REQ2723199 - Modified API version and commented Debug statements
2022-05-03  saiswetha.pingali@auspost.com.au Removed call to EmailMessageUtil.parseEmailbodySnapIT as this is no more used.
2022-10-13  naveen.rajanna@auspost.com.au   REQ2859152 - Moved the triggerhandler dispatch outside of Trigger.isAfter if condition and removed debug statements, changed api version to 55
*****************************************************************************************/

trigger EmailMessageTrigger on EmailMessage(after insert, before insert, after update, before update) {
	if (!SystemSettings__c.getInstance().Disable_Triggers__c) {
		if (Trigger.isInsert) {
			if (Trigger.isBefore) {
				//Removing Cloning of Cases - change to not allow networks to reopen closed cases.
				//EmailMessageUtil.clonePermanentlyClosedCases(Trigger.new);
				EmailMessageUtil.switchInboundToOutbound(Trigger.new);
				EmailMessageUtil.detectPermanentSpam(Trigger.new);
				EmailMessageUtil.startrackDuplicateInboundEmail(Trigger.new); //StarTrack method to check for inbound email duplication.
				EmailMessageUtil.processVOCIncidentEmails(Trigger.new); //StarTrack method to handle inbound emails for VOC incident.
			}

			if (Trigger.isAfter) {
				EmailMessageUtil.detectSpamEmailOnCases(Trigger.new);
				// when an email is received from email to case, this is used to set the email-to-case address on the parent case record
				EmailMessageUtil.setEmailToCaseAddress(Trigger.newMap);
				// Given agent sends email to the customer (via Send Email action in case record)
				// And cases are under customer centre
				// Then create CaseActivity record for SLA Reporting
				SLAReportingUtility.generateCaseActivity(Trigger.new);
			}
		}
		(new EmailMessageTriggerHandler()).dispatch(); // invoke domain based trigger dispatch
	}
}
