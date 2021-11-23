@isTest
private class SSSWFaxUtilityTest {
	/*
	private static void sendMail(String subject, String message, Messaging.InboundEmail.TextAttachment textAttachment, Messaging.InboundEmail.BinaryAttachment binAttachment) {
 		
 		Messaging.InboundEmail email = new Messaging.InboundEmail();
   		Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
 		
        //Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        //String[] toAddresses = new String[] {'ssswfaxemailservice@cj35z9f3qv9r3065bf6jq4xzsv6baqouiiqjbibyxg4fftl2.o-4xdrvma2.cs5.apex.sandbox.salesforce.com'};
        //email.setToAddresses(toAddresses);
 
        email.subject = subject;
        email.plainTextBody = message;
        email.textAttachments = new Messaging.InboundEmail.TextAttachment[] {textAttachment};
        email.binaryAttachments = new Messaging.InboundEmail.BinaryAttachment[] {binAttachment};
        
        // Send the email
        //Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
 
 		SSSWFaxHandler handler = new SSSWFaxHandler();
 		handler.handleInboundEmail(email, env);
    }   
 
    public static testMethod void testSendEmailWithAttachment() {
    	test.startTest();
    	RecordType rt;
    	
    	for (RecordType ret : [select Id, Name, DeveloperName from RecordType where sobjecttype = 'case']) {
    		if (!ret.DeveloperName.contains('SSSW')) {
    			rt = ret;
    			break;
    		}
    	}
    	
		Case c = TestDataProvider.createCase('Domestic Item Search', 'SSSWFaxHandlerTest_Case', null);
		c.Type = 'General Enquiry';
		if (rt != null) c.RecordTypeId = rt.Id; 
        insert c;
    	
    	
    	//Integer preEmailFaxCount = [SELECT Id FROM Fax__c].size();
    	//System.debug('Number of Faxes before test email is sent: ' + preEmailFaxCount);
    	
    	// Create the email attachments
	    Messaging.InboundEmail.TextAttachment txt = new Messaging.InboundEmail.TextAttachment();
	    txt.fileName = 'text.txt';
	    txt.body = 'blob';
	    
	    Messaging.InboundEmail.BinaryAttachment bin = new Messaging.InboundEmail.BinaryAttachment();
	    bin.fileName = 'bin.jpg';
	    bin.body = Blob.valueOf('blob');
	    
        sendMail('SSSWFaxHandlerTest_Email', 'SSSWFaxHandlerTest_Email', txt, bin);
        
        //Integer postEmailFaxCount = [SELECT Id FROM Fax__c].size();
        //System.debug('Number of Faxes after test email is sent: ' + postEmailFaxCount);
        
        // TEST 1: Check Fax object created.
        //System.assert((preEmailFaxCount + 1) == postEmailFaxCount);
        
        Fax__c testFax = [SELECT Id FROM Fax__c WHERE Subject__c = 'SSSWFaxHandlerTest_Email' ORDER BY CreatedDate DESC LIMIT 1];
        //System.assert(testFax != null);
        
        
        // TEST 2: Link Fax to Case. Case Status changed and Status Tracking created.
        //c = [SELECT Id, Status FROM Case WHERE Id = :c.Id LIMIT 1];
        //System.debug('Case status before Fax is linked: ' + c.Status);
        
        StatusTracking__c preFaxST = new StatusTracking__c();
        for(StatusTracking__c st : [SELECT Id, StatusValue__c FROM StatusTracking__c WHERE Case__c = :c.Id and BusinessTime__c = 'Current State' LIMIT 1]){
        	preFaxST = st;
        }
        //System.debug('Current Status Tracking status value before changing Case status: ' + preFaxST.StatusValue__c);
        
        
        
        testFax.Case__c = c.Id;
        update testFax;
        
        //c = [SELECT Id, Status FROM Case WHERE Id = :c.Id LIMIT 1];
        //System.debug('Case status after Fax is linked: ' + c.Status);
        
		StatusTracking__c faxST = new StatusTracking__c();
        for(StatusTracking__c st : [SELECT Id, StatusValue__c FROM StatusTracking__c WHERE Case__c = :c.Id and BusinessTime__c = 'Current State' LIMIT 1]){
        	faxST = st;
        }
        //System.debug('Current Status Tracking status value after changing Case status: ' + faxST.StatusValue__c);
        
        //System.assertEquals(c.Status, 'Facility Updated');
        
        
        // TEST 3: Change Case Status. Check Status Tracking before and after.
		
        //System.assertNotEquals(preFaxST, faxST);
        
        c.Status = 'In Progress';
        update c;
		
		
		// TEST 4: Remove previous Fax link to Case. Check Status Tracking before and after.
		List<StatusTracking__c> stList = [SELECT Id, StatusValue__c, Duration__c, BusinessTime__c FROM StatusTracking__c WHERE Case__c = :c.Id];
        System.debug('Number of Status Tracking items before Fax link is removed: ' + stList.size());
        
        Decimal preFaxSTDuration = 0;
        Decimal faxSTDuration = 0;
        for (StatusTracking__c item : stList) {
        	if (item.Id == preFaxST.Id) {
        		preFaxSTDuration = item.Duration__c;
        	} else if (item.Id == faxST.Id) {
        		faxSTDuration = item.Duration__c;
        	}
        }  
        System.debug('preFaxSTDuration: ' + preFaxSTDuration);
        System.debug('faxSTDuration: ' + faxSTDuration);
        
        System.debug('testFax.Case__c: ' + testFax.Case__c);
        testFax.Case__c = null;
        update testFax;
        
        test.stopTest();
		
		//stList = [SELECT Id, StatusValue__c, Duration__c, BusinessTime__c FROM StatusTracking__c WHERE Case__c = :c.Id];
        //System.debug('Number of Status Tracking items after Fax link is removed: ' + stList.size());
        
        Decimal newPreFaxSTDuration = 0;
        for (StatusTracking__c item : stList) {
        	if (item.Id == preFaxST.Id) {
        		newPreFaxSTDuration = item.Duration__c;
        	}
        } 
        System.debug('newPreFaxSTDuration: ' + newPreFaxSTDuration);
        
        //System.assertEquals((preFaxSTDuration + faxSTDuration), newPreFaxSTDuration);
		
        
        // TEST 5: Link Fax to Case again and unlink. Check Status Tracking.
        preFaxST = null;
        for (StatusTracking__c item : stList) {
        	if (item.BusinessTime__c == 'Current State') {
        		preFaxST = item;
        	}
        } 
        System.debug('Current Status Tracking item before Fax is linked: ' + preFaxST.BusinessTime__c);
        
        //testFax.Case__c = c.Id;
        //update testFax;
        
        //preFaxST = [SELECT Id, BusinessTime__c FROM StatusTracking__c WHERE Id = :preFaxST.Id LIMIT 1];
        //System.assertNotEquals(preFaxST.BusinessTime__c, 'Current State');
        
        //testFax.Case__c = null;
        //update testFax;
        
        //preFaxST = [SELECT Id, BusinessTime__c FROM StatusTracking__c WHERE Id = :preFaxST.Id LIMIT 1];
        //System.debug('SAY WHAT?: ' + [SELECT Id, StatusValue__c FROM StatusTracking__c WHERE BusinessTime__c = 'Current State' LIMIT 1].StatusValue__c);
        //System.assertEquals(preFaxST.BusinessTime__c, 'Current State');
    }
    */
}