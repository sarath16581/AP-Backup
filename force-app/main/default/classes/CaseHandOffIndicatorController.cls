/**
 * @description Case Hand-off Badge for classic view
 * @author Paul Perry
 * @date 2024-06-18
 * @changelog
 * 2024-06-18 - Paul Perry - Case Hand-off
 **/
public with sharing class CaseHandOffIndicatorController {
	private Case caseRecord;

	public CaseHandOffIndicatorController(ApexPages.StandardController controller) {
		Id caseId = controller.getId();
		
		this.caseRecord = CasesSelector.newInstance(
			1,
			new Set<SObjectField>{ Case.CaseTransferDate__c }
		).selectById(
			new Set<Id>{ caseId },
			new Set<Object>{ CasesSelector.Options.WITH_RECORDTYPE }
		).get(caseId);
	}

	public Boolean getShowBanner() {
		return this.caseRecord?.CaseTransferDate__c != null;
	}
	
	public String getBackgroundColor() {
		final String colourAP = '#E5535E';
		final String colourST = '#6FBFDD';

		String recordTypeDevName = this.caseRecord?.RecordType.DeveloperName ?? '';
		String result = colourST;

		if (recordTypeDevName.startsWith('SSSW')) {
			result = colourAP;
		}

		return result;
	}
}