/**
 *	Test class for trigger EmailMessage_AI_createOutBoundMessage
 * 
 @author 	Yuanyuan Zhang
 @created 	2014-07-10
 @version 	1.0 
 @since 	29.0 (Force.com ApiVersion)
 *
 @changelog
 * 2014-07-10 Yuanyuan Zhang <yuanyuan.zhang@bluewolf.com>
 * - Created
 * - Coverage 100%
 * 2021-08-11 - Seth Heang - Uplift API version to 52
 */
 @isTest
private class ClsEmailMessage_AI_createOutBounMsg_Test {
	static testmethod void testMessage () {
		test.startTest();
		Case c = new Case(EnquirySubType__c ='Problem', Subject='My Subject', type='General Enquiry', ReopenDate__c=System.today(),Service_Now_Ticket_Number__c='a');
        insert c;
        
        EmailMessage em = new EmailMessage();
        em.BccAddress = 'carmelo.andronaco@bluewolfgroup.com';
		//em.CcAddress = 'test';
		em.FromAddress = 'mohamed.atheek@sm9s4pdfa5vgsz9nw0dhqn78ue7klohjj10mgz7fxplne8fdw.o-vluvmas.cs5.case.sandbox.salesforce.com';
		em.FromName = 'mohamed.atheek@sm9s4pdfa5vgsz9nw0dhqn78ue7klohjj10mgz7fxplne8fdw.o-vluvmas.cs5.case.sandbox.salesforce.com';
		//em.HasAttachment = false;
		em.Headers = 'Return-Path: X-SFDC-Original-RCPT: mohamed.atheek@7-28x4xajpl6prpzkou885d32xtd4u1fw6a5mh6zqdrtyzwe64tu.o-vluvmas.cs5.case.sandbox.salesforce.comX-SFDC-Binding: coremailprocessorX-SFDC-DOMAINKEYS: NoneX-SFDC-TLS-VERIFIED: noX-SFDC-TLS-CIPHER: AES256-SHAX-SFDC-TLS-STATUS: trueX-SFDC-SENDERID-PRA: PassX-SFDC-SENDERID: NoneX-SFDC-SPF: NoneSFDC-Interface: externalReceived: from [182.50.78.79] ([182.50.78.79:39388] helo=smtp16-tyo.mta.salesforce.com) by mx4-sjl.mta.salesforce.com (envelope-from <>) (ecelerity 2.2.2.45 r()) with ESMTPS (cipher=AES256-SHA)  id 83/4F-23732-69D72A35; Thu, 19 Jun 2014 06:05:10 +0000Message-ID: <0D.1F.12049.19D72A35@mx2-tyo.mta.salesforce.com>From: Mail Delivery System <mailer-daemon@salesforce.com>To: mohamed.atheek@7-28x4xajpl6prpzkou885d32xtd4u1fw6a5mh6zqdrtyzwe64tu.o-vluvmas.cs5.case.sandbox.salesforce.comSubject: Undeliverable: Sandbox: Case: 00093671 requires your attention.Date: Thu, 19 Jun 2014 06:05:05 +0000';
		em.HtmlBody = '<html><body>asdfasf<br><br><img src="http://cs5.salesforce.com/servlet/servlet.ImageServer?oid=00DO0000000VluV&esid=018O0000000D0j7"><br><br><DIV style="display:none;">ref:_00DO0VluV._500O03I3Gr:ref</DIV></body></html>';
		em.Incoming = false;
		em.MessageDate = date.today();
		em.Status = '3';
		em.Subject = 'test';
		em.TextBody = 'test';
		em.ToAddress = 'carmelo.andronaco@bluewolf.com';
		em.parentId = c.Id;
		insert em;
		test.stopTest();
	}
}