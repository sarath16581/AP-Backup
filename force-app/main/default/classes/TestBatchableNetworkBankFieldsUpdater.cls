@isTest
private class TestBatchableNetworkBankFieldsUpdater {
	
	@isTest static void testBacth() {
		//creating custom settings
        insert new List<BankMapping__c> {
        	new BankMapping__c(Name = '1', Network_Field__c = 'ANZ__c'), 
        	new BankMapping__c(Name = '2', Network_Field__c = 'CBA__c'),
        	new BankMapping__c(Name = '5', Network_Field__c = 'RBA__c'),
        	new BankMapping__c(Name = '9', Network_Field__c = 'Westpac__c')
        };
        
        Network__c n1 = new Network__c();
        n1.Name = 'Melb CBD';
        n1.BusBankChq__c = '1, 2,3';
        n1.BusBankChqCash__c = ' 2,3,5';
        
        Network__c n2 = new Network__c();
        n2.Name = 'Syd CBD';
        n2.BusBankChq__c = '3, 6,10 ';
        n2.BusBankChqCash__c = '4,7,11';
        
        insert new List<Network__c> {n1, n2};

        Test.startTest();
        BatchableNetworkBankFieldsUpdater.run();
        Test.stopTest();
        
        List<Network__c> nwList = [SELECT ANZ__c, CBA__c, RBA__c, Westpac__c FROM Network__c WHERE ID IN (:n1.Id, :n2.Id) ORDER BY Name ASC];
       	
       	//Melb CBD
       	System.assertEquals(nwList[0].ANZ__c, NetworkUtil.PICKLIST_VALUE_CHECK_ONLY);
        System.assertEquals(nwList[0].CBA__c, NetworkUtil.PICKLIST_VALUE_CASH_AND_CHECK);
        System.assertEquals(nwList[0].RBA__c, NetworkUtil.PICKLIST_VALUE_CASH_AND_CHECK);
        System.assertEquals(nwList[0].Westpac__c, null);
        
        //Syd CBD
        System.assertEquals(nwList[1].ANZ__c, null);
        System.assertEquals(nwList[1].CBA__c, null);
        System.assertEquals(nwList[1].RBA__c, null);
        System.assertEquals(nwList[1].Westpac__c, null);
        
        //checking update
        n2.BusBankChq__c += ',1';
        n2.BusBankChqCash__c += ',1,2';
        update n2;
        
        Network__c nw = [SELECT ANZ__c, CBA__c, RBA__c, Westpac__c FROM Network__c WHERE ID = :n2.Id];
        System.assertEquals(nw.ANZ__c, NetworkUtil.PICKLIST_VALUE_CASH_AND_CHECK);
        System.assertEquals(nw.CBA__c, NetworkUtil.PICKLIST_VALUE_CASH_AND_CHECK);
        System.assertEquals(nw.RBA__c, null);
        System.assertEquals(nw.Westpac__c, null);
	}
	
}