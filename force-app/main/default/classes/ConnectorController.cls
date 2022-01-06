global class ConnectorController {
    @RemoteAction global static Object findContact(String searchId, String searchValue) {
        system.debug('findContact: searchId - ' + searchId +', searchValue - ' + searchValue);
        
        String query = 'SELECT Id, Name, AccountId FROM Contact WHERE ' + searchId  + ' = \'' + searchValue + '\'';
        system.debug('query = ' + query);            
        List<Contact> contacts = Database.query(query);
        
        if (!contacts.isEmpty()) {
			Integer numContacts = contacts.size();
			system.debug('contacts found=' + numContacts);
			
			if (numContacts > 1) {
				Contact c = contacts[0];
				c.Id = null; // indicator for multiple contacts
				return c;
			}
			else if (numContacts == 1) {
				return contacts[0];
			}
        }
        
        // throw in an account search if we've found nothing while we're here
        query = 'SELECT Id, Name FROM Account WHERE ' + searchId  + ' = \'' + searchValue + '\'';
        List<Account> accounts = Database.query(query);
        
        if (!accounts.isEmpty()) {
			Integer numAccounts = accounts.size();
			system.debug('accounts found=' + numAccounts);
			
			if (numAccounts > 1) {
				Account c = accounts[0];
				c.Id = null; // indicator for multiple contacts
				return c;
			}
			else if (numAccounts == 1) {
				return accounts[0];
			}
        }
        
        return null;
    } 
    
    @RemoteAction global static Contact getContact(String contactId, String field) {
        system.debug('getContact: contactId - ' + contactId);
        if (field != null) {
        	field = ', ' + field;
        }
        else {
        	field = '';
        }
        
        String query = 'SELECT Id, Name, AccountId' + field + ' FROM Contact WHERE Id= :contactId';
        system.debug('query = ' + query);            
        List<Contact> contacts = Database.query(query);
        if (!contacts.isEmpty()) {
        	return contacts[0];
        }
        else {
        	return null;
        }
    }  
    
     @RemoteAction global static Task getContactByTask(String taskId) {
        system.debug('getContactByTask: taskId - ' + taskId);
        
        Task task = [SELECT WhoId, WhatId FROM Task WHERE Id= :taskId];
        system.debug('contact id = '  + task.WhoId);
        
        // see if this task has an associated case
        List<Case> cases = [SELECT CaseNumber FROM Case WHERE Id= :task.WhatId];
        
       	if (!cases.isEmpty()) {
       		// return the case number in the call object field
       		task.CallObject = cases[0].CaseNumber;
       	}
       	               
        return task;
    } 
    
    @RemoteAction global static Task createTask(String contactId, 
    		String whatId,
    		String subject,
    		Map<String, String> userData,
    		Map<String, String> taskMap) {
		system.debug('createActivity: ' + contactId);
		  
		// check to see if this is an account and not a contact
		String accountPrefix = Schema.SObjectType.Account.getKeyPrefix();
        String prefix = contactId.substring(0, 3);
        if (prefix == accountPrefix) {
        	// see if the 'what' needs to be an account
        	String casePrefix = Schema.SObjectType.Case.getKeyPrefix();
        	if (whatId == null || whatId.substring(0, 3) != casePrefix) {
        		whatId = contactId;
        	}
        	
        	contactId = null;
        }
        
		Task task = new Task (
		  	Status = 'In Progress',
		  	Subject = subject,
		  	WhoId = contactId,
		  	WhatId = whatId
		);          
	      
	    if (taskMap != null) {
		    for (String sfdcField : taskMap.keySet()) {
	    		system.debug(sfdcField + ':' + taskMap.get(sfdcField));
	    		task.put(sfdcField, taskMap.get(sfdcField));
			}
	    }
		  
        insert task;
        system.debug('Task id = '  + task.Id);
        return task;
 	}
 	
    @RemoteAction global static Task closeTask(ID taskId, 
    		ID whatId,
 			String subject,
    		String comments, 
    		Map<String, String> userData,
    		String dispositionKVP,
    		Map<String, String> taskMap, 
    		Integer callDuration) {
		system.debug('closeActivity: ' + taskId);
		  
		Task[] tasks = [SELECT Id, Description FROM Task WHERE Id= :taskId];
		Task task = null;
		
		if (tasks.size() == 0) { // created yet?
			task = createTask(taskId, whatId, subject, userData, taskMap); // task id is actually the contact id
			if (task == null) {
				return null;
			}
		}
		else {
			task = tasks[0];
		}
		
        String disposition = '';
        if (userData != null && userData.containsKey(dispositionKVP)) {
        	disposition = userData.get(dispositionKVP);
        }
        
        for (String sfdcField : taskMap.keySet()) {
    		system.debug(sfdcField + ':' + taskMap.get(sfdcField));
    		task.put(sfdcField, taskMap.get(sfdcField));
		}
		
        task.CallDisposition = disposition;
        task.CallDurationInSeconds = callDuration;
        task.Status = 'Completed';
        task.Subject = subject;
        
        if (comments != '') {
        	if (task.Description == null) {
        		task.Description = '';
        	}
        	
        	task.Description += '\n' + comments;
        }
        
        for (String sfdcField : taskMap.keySet()) {
    		system.debug(sfdcField + ':' + taskMap.get(sfdcField));
    		task.put(sfdcField, taskMap.get(sfdcField));
		}
           
        update task;
        system.debug('Task id = '  + task.Id);
        return task;
 	}
 	
    @RemoteAction global static Case findCase(String caseNumber) {
        system.debug('findCase: ' + caseNumber);
        List<Case> cases = [SELECT CaseNumber, ContactId FROM Case WHERE CaseNumber= :caseNumber];
        
       	if (!cases.isEmpty()) {
        	return cases[0];
       	}
       	                            
        return null; 
    }
    
    @RemoteAction global static Case createCase(String contactId, String accountId, String mediaType, String subject, Map<String, String> userData, Map<String, String> caseMap) {        
        system.debug('createCase: ' + subject);
		
		// check to see if this is an account and not a contact
		String accountPrefix = Schema.SObjectType.Account.getKeyPrefix();
        String prefix = contactId.substring(0, 3);
        if (prefix == accountPrefix) {
        	accountId = contactId;
        	contactId = null;
        }
        
        Case c = new Case (
        	ContactId = contactId,
        	AccountId = accountId,
        	Subject = subject,
        	Priority = 'Medium',
        	Origin = mediaType       	
        );
        
        if (caseMap != null) {
	        for (String sfdcField : caseMap.keySet()) {
	    		system.debug(sfdcField + ':' + caseMap.get(sfdcField));
	    		c.put(sfdcField, caseMap.get(sfdcField));
			}
        }

        try {                        
            insert c;
            c = [select id, CaseNumber from Case where id=:c.id];
        }
        catch (QueryException e) {
        	system.debug('QueryException ' + e); 
        	return null; 
        }
        
        system.debug('Case id = '  + c.Id);
        return c;
    }
}