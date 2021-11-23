/*------------------------------------------------------------
Author:        Adrian Recio
Company:       Accenture
Description:   Handler class for ContentVersion Trigger
Test Class:    ContentVersionTriggerHandler_Test
History
<Date>      <Authors Name>     <Brief Description of Change>
1/10/18		 Adrian Recio    	Inital Version to handle content version insert and updates.
								Insert and update will evaluate if document type of Contract, DOV, Renewal is populated.
								If Document types exist as child file to apttus contract, checkbox (APT_has_file__c) in Apttus contract will be ticked.
* @changelog
* 2020-07-23 - Nathan Franklin - Removing custom disable trigger logic
------------------------------------------------------------*/
public class ContentVersionTriggerHandler {

	public static Boolean IsFileExistUpdate = false;
    
	/*------------------------------------------------------------
    Author:        Adrian Recio
    Company:       Accenture
    Description:   Trigger after insert handler
    Inputs:        cdlList - List of content documents
    Returns:       void
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    1/11/18   Adrian Recio      Trigger after insert handler
    ------------------------------------------------------------*/
	public static void onAfterInsert(List<ContentVersion> cvList){
		// validate that disable trigger cloning is not disabled
		if(AgreementToSFContractTriggerHandler.disableCloning == false) {
			// method to validate if file exist
			initiateFileCheck_CV(cvList);
		}
	}

	/*------------------------------------------------------------
    Author:        Adrian Recio
    Company:       Accenture
    Description:   Trigger after update handler
    Inputs:        cdlList - List of content documents
    Returns:       void
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    1/11/18   Adrian Recio      	Trigger after update handler
    ------------------------------------------------------------*/
	public static void onAfterUpdate(List<ContentVersion> cvList){
		// validate that disable trigger cloning is not disabled
		if(AgreementToSFContractTriggerHandler.disableCloning == false) {
			// method to validate if file exist
			initiateFileCheck_CV(cvList);
		}
	}

	/*------------------------------------------------------------
    Author:        Adrian Recio
    Company:       Accenture
    Description:   Trigger after delete handler
    Inputs:        cdlList - List of content documents
    Returns:       void
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    1/11/18   Adrian Recio      	Trigger after delete handler
    ------------------------------------------------------------*/
	public static void onAfterDelete(List<ContentVersion> cvList){
		// validate that disable trigger cloning is not disabled
		if(AgreementToSFContractTriggerHandler.disableCloning == false) {
			// method to validate if file exist
			initiateFileCheck_CV(cvList);
		}
	}

	/*------------------------------------------------------------
    Author:        Adrian Recio
    Company:       Accenture
    Description:   Method to identify and query content document links based on inserted content version.
    			   Matching content document links is then passed to fileExistCheck method to update contract
    			   checkbox of parent agreement if valid file with document type of contract, renewal or dov exist.
    Inputs:        cvList - list of content version inserted/updated
    Returns:       void
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    1/11/2018   Adrian Recio     First version.
   ------------------------------------------------------------*/
	public static void initiateFileCheck_CV(List<ContentVersion> cvList){
		// Set of agreement Ids
		Set<Id> cdIdSet = new Set<Id>();

		// Get parent contentdocument
		for(ContentVersion cvVar : cvList){
			if( cvVar.IsLatest == true){
				// get the contentDocument Ids
				cdIdSet.add(cvVar.ContentDocumentID);
			}
		}

		system.debug('cdIdSet:' + cdIdSet);
		if(cdIdSet.size()>0){
			// Query the Existing Content Document Link based on content document Ids
			List<ContentDocumentLink> cdlList = [SELECT LinkedEntityId, ContentDocumentId
												 FROM ContentDocumentLink
												 WHERE ContentDocumentId IN :cdIdSet];
			system.debug('cdlList:' + cdlList);
			if(cdlList.size()>0) {
				// Call method to validate if file with document type renewal, dov or contract exist.
				// If at least one file match, roll up and update the has file checkbox of the parent agreement to true.
				fileExistCheck(cdlList);
			}
		}
	}

	/*------------------------------------------------------------
    Author:        Adrian Recio
    Company:       Accenture
    Description:   Method to validate if file with document type renewal, dov or contract exist.
				   If at least one file match, roll up and update the has file checkbox of the parent agreement to true.
    Inputs:        cdlList - list of content document links related to a content version and agreement
    Returns:       void
    History
    <Date>      <Authors Name>     <Brief Description of Change>
    1/11/2018   Adrian Recio       First version.
   ------------------------------------------------------------*/
	public static void fileExistCheck( List<ContentDocumentLink> cdlList){
		// Set of valid document types
		Set<string> docTypeSet = new Set<string>();
		docTypeSet.add('Contract');
		docTypeSet.add('Deed of Variation');
		docTypeSet.add('Renewal');
		system.debug('docTypeSet:' + docTypeSet);

		// set of link entity Ids
		set<Id> linkEntityIds = new set<Id>();
		for(ContentDocumentLink cdlVar: cdlList){
			if( cdlVar.LinkedEntityId.getSObjectType().getDescribe().getName() == 'Apttus__APTS_Agreement__c') {
				linkEntityIds.add(cdlVar.LinkedEntityId);
			}
		}

		system.debug('linkEntityIds:' + linkEntityIds);
		List<ContentDocumentLink> siblingCdlList = new List<ContentDocumentLink>();

		// Query sibling cdl if set of link entity Id exist
		if(linkEntityIds.size()>0) {
			// Query sibling content document links
			siblingCdlList = [SELECT LinkedEntityId, ContentDocumentId
							  FROM ContentDocumentLink
							  WHERE LinkedEntityId IN :linkEntityIds and Id not IN :cdlList];
			// Merge sibling and original cdls based on inserted content version
			siblingCdlList.addAll(cdlList);
		}

		system.debug('siblingCdlList:' + siblingCdlList);

		// build set of content document Ids based on child cdls
		set<Id> completeCdIdSet = new set<Id>();
		for(ContentDocumentLink cdlVar: siblingCdlList){
			completeCdIdSet.add(cdlVar.ContentDocumentId);
		}

		system.debug('completeCdIdSet:' + completeCdIdSet);

		// build map of parent link entity id and content document
		Map<Id,set<Id>> cdAndAgrIdMap = new Map<Id,set<Id>>();
		for(ContentDocumentLink cdlVar: siblingCdlList){
			if( cdlVar.LinkedEntityId.getSObjectType().getDescribe().getName() == 'Apttus__APTS_Agreement__c') {
				if (cdAndAgrIdMap.containsKey(cdlVar.LinkedEntityId)) {
					set<Id> childCdSet = cdAndAgrIdMap.get(cdlVar.LinkedEntityId);
					childCdSet.add(cdlVar.ContentDocumentId);
					cdAndAgrIdMap.put(cdlVar.LinkedEntityId, childCdSet);
				} else {
					set<Id> childCdSet = new set<Id>();
					childCdSet.add(cdlVar.ContentDocumentId);
					cdAndAgrIdMap.put(cdlVar.LinkedEntityId, childCdSet);
				}
			}
		}

		system.debug('cdAndAgrIdMap:' + cdAndAgrIdMap);


		// Query aggregate count of content version based on Document Type, ContentDocumentId and is latest version
		AggregateResult[] groupedResults = [SELECT Count(Document_Type__c) dtCount, ContentDocumentId
											FROM ContentVersion
											WHERE (Document_Type__c != null
											and	Document_Type__c In :docTypeSet
											and ContentDocumentId IN :completeCdIdSet
											and IsLatest = true)
											GROUP BY ContentDocumentId];

		system.debug('groupedResults:' + groupedResults);
		system.debug('groupedResults.size():' + groupedResults.size());

		// Build map of content document and count of valid contentversion document types
		Map<Id, Integer> cdContentVersionMap = new Map<Id, Integer>();
		for (AggregateResult ar : groupedResults)  {
			cdContentVersionMap.put(String.valueOf(ar.get('ContentDocumentId')),
					Integer.valueOf(ar.get('dtCount')));
		}

		system.debug('cdContentVersionMap:' + cdContentVersionMap);

		// Query Map of matching link entity Id agreements
		Map<Id,Apttus__APTS_Agreement__c> origAgrMap = new Map<Id,Apttus__APTS_Agreement__c>([Select Id, APT_Contract_Type__C, APT_has_file__c, RecordType.Name
																							  from Apttus__APTS_Agreement__c where Id IN :cdAndAgrIdMap.keySet()]);

		system.debug('origAgrMap:' + origAgrMap);

		// List Apttus__APTS_Agreement__c records for apt has file update
		List<Apttus__APTS_Agreement__c> agreementListToUpdate = new List<Apttus__APTS_Agreement__c>();

		// If aggregate results of child contentversion is zero, roll up value of false to APT_has_file__c to all parent apttus contract
		if(groupedResults.size()==0){
			for(Id lEId: cdAndAgrIdMap.keySet()){
				Apttus__APTS_Agreement__c agreement = origAgrMap.get(lEId);
				if(agreement!=null) {
					agreement.Id = lEId;
					agreement.APT_has_file__c = false; // True if files count if greater than 1
					agreementListToUpdate.add(agreement);
				}
			}
		// else set value of APT_has_file__c depending on groupedResults list value.
		// Value will be true if
		}else {
			// Build map of agreement and count of valid files
			for (Id lEId : cdAndAgrIdMap.keySet()) {
				// Retrieve original agreement value
				Apttus__APTS_Agreement__c origAgVar = origAgrMap.get(lEId);
				system.debug('origAgVar:' + origAgVar);

				if (origAgVar != null) {
					set<Id> childCdSet = cdAndAgrIdMap.get(lEId);
					Integer childCountVar = 0;
					Boolean hasFilesVar = false;
					for (Id cdIdVar : childCdSet) {
						if (cdContentVersionMap.containsKey(cdIdVar)) {
							childCountVar = childCountVar + cdContentVersionMap.get(cdIdVar);
						}
					}

					system.debug('Child valid cv count:' + childCountVar);
					system.debug('hasFilesVar:' + hasFilesVar);

					if (childCountVar > 0) {
						hasFilesVar = true;
					}

					origAgVar.APT_has_file__c = hasFilesVar; // True if files count if greater than 1
					agreementListToUpdate.add(origAgVar);
				}
			}
		}

		system.debug('agreementListToUpdate:' + agreementListToUpdate);
		system.debug('agreementListToUpdate.size():' + agreementListToUpdate.size());
		system.debug('IsFileExistUpdate:' + IsFileExistUpdate);

		// update the list of parent agreements with new APT_has_file__c value
		if(agreementListToUpdate.size() > 0){
			// Make sure that agreement trigger wont refire for has file update
			IsFileExistUpdate = true;
			update agreementListToUpdate;

			// Convert to map
			Map<Id,Apttus__APTS_Agreement__c> agUpdateMap = new Map<Id,Apttus__APTS_Agreement__c>(agreementListToUpdate);

			// Sync clone sf contract file roll up boolean
			List<Contract> cContractList = [Select Id, APT_has_file__c, Parent_Agreement__c
											from Contract
											where Parent_Agreement__c IN :agUpdateMap.keySet()];

			// List of salesforce contract for file roll up boolean update
			List<Contract> sfConUpdateList = new List<Contract>();

			if(cContractList.size()>0){
				for(Contract conVar: cContractList){
					Apttus__APTS_Agreement__c pAgVar = agUpdateMap.get(conVar.Parent_Agreement__c);
					if(pAgVar!=null){
						if(conVar.APT_has_file__c != pAgVar.APT_has_file__c){
							conVar.APT_has_file__c = pAgVar.APT_has_file__c;
							sfConUpdateList.add(conVar);
						}
					}
				}

				// Update clone sf contract with new APT_has_file__c boolean value
				if(sfConUpdateList.size()>0){
					update sfConUpdateList;
				}
			}
		}

		system.debug('after update agreementListToUpdate:' + agreementListToUpdate);

	}
}