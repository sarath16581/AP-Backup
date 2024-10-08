/**************************************************
Type:       Test class for ComparableSObjectWrapper
Purpose:	Tests that the comparable behaviour is added to the SObject
          
History:
--------------------------------------------------
17.01.2014  Mohamed.Atheek@bluewolf.com  Created                                               
**************************************************/

@isTest
private class TestComparableSObjectWrapper {

    static testMethod void testWrapper() {
        //using a standard object with the a srtandard number field
        List<ComparableSObjectWrapper> wrappers = new List<ComparableSObjectWrapper> {
        	new ComparableSObjectWrapper(new Account(Name = 'Acc50', NumberOfEmployees = 50), 'NumberOfEmployees'),
        	new ComparableSObjectWrapper(new Account(Name = 'Acc20', NumberOfEmployees = 20), 'NumberOfEmployees'),
        	new ComparableSObjectWrapper(new Account(Name = 'Acc25', NumberOfEmployees = 25), 'NumberOfEmployees'),
        	new ComparableSObjectWrapper(new Account(Name = 'Acc10', NumberOfEmployees = 10), 'NumberOfEmployees')
        };
        
        wrappers.sort();
        
        System.assertEquals('Acc10', wrappers[0].sObj.get('Name'));
        System.assertEquals('Acc20', wrappers[1].sObj.get('Name'));
        System.assertEquals('Acc25', wrappers[2].sObj.get('Name'));
        System.assertEquals('Acc50', wrappers[3].sObj.get('Name'));
        
        //specifying a sort field that is not a decimal
        List<ComparableSObjectWrapper> wrappers2 = new List<ComparableSObjectWrapper> {
        	new ComparableSObjectWrapper(new Account(Name = 'Acc50', AccountNumber = '50'), 'AccountNumber'),
        	new ComparableSObjectWrapper(new Account(Name = 'Acc20', AccountNumber = '20'), 'AccountNumber'),
        	new ComparableSObjectWrapper(new Account(Name = 'Acc25', AccountNumber = '25'), 'AccountNumber'),
        	new ComparableSObjectWrapper(new Account(Name = 'Acc10', AccountNumber = '10'), 'AccountNumber')
        };
        
        wrappers2.sort();
        
        //if the sort field is not a number field then still sort the SObjects
        System.assertEquals('Acc50', wrappers2[3].sObj.get('Name'));
        System.assertEquals('Acc20', wrappers2[1].sObj.get('Name'));
        System.assertEquals('Acc25', wrappers2[2].sObj.get('Name'));
        System.assertEquals('Acc10', wrappers2[0].sObj.get('Name'));        
    }
}