/**
 * @description
 * Module to handle Adjustment__c object functionality
 * @author Pratyush Chalasani
 * @group Domain
 * @domain Adjustment
 * @changelog
 * 2023-06-28 - Pratyush Chalasani - Created
 *
 */
public inherited sharing class AdjustmentModule extends ApplicationModule {
	private static final String context = 'AdjustmentModule';
	private static final Set<SObjectField> monitoredFields = new Set<SObjectField>{Adjustment__c.Case__c, Adjustment__c.Is_APPC__c};

	private final ApplicationRecursion recursion = ApplicationRecursion.getInstance();

    public static AdjustmentModule newInstance() {
		return (AdjustmentModule) Application.Utilities.newInstance(AdjustmentModule.class);
	}

    // Setup which trigger events this module should respond to
	public AdjustmentModule() {
		getTriggerEvents().enableAfterInsert().enableAfterUpdate();
	}

	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {
		bindCAandDIfromCase((List<Adjustment__c>)records, null, uow);
	}

	public override void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		bindCAandDIfromCase((List<Adjustment__c>)records, (Map<Id, Adjustment__c>)existingRecords, uow);
	}

	/* Method for binding the Credit Approval and Disputed Item fronm Case Record */
    public void bindCAandDIfromCase(List<Adjustment__c> records, Map<Id, Adjustment__c> oldMap, ApplicationUnitOfWork uow) {
		List<ApplicationRecursion.RecordState> changedRecords = recursion.getProcessableRecords(context, records, oldMap, monitoredFields);

		List<Adjustment__c> adjustmentList = new List<Adjustment__c>();

    	set<Id> caseIdSet = new Set<Id>();

    	for (ApplicationRecursion.RecordState recordState: changedRecords) {
			Adjustment__c adjustment = (Adjustment__c)recordState.record;
    		caseIdSet.add(adjustment.Case__c);
			adjustmentList.add(adjustment);
    	}

        if (caseIdSet.size() > 0) {
			Set<Object> selectorOptions = new Set<Object>{CasesSelector.WITH_DISPUTED_ITEMS, CasesSelector.WITH_CREDIT_APROVALS};

			Map<Id, Case> pCaseMap = CasesSelector.newInstance().selectById(caseIdSet, selectorOptions);

        	List<Credit_Approval__c> caUpdateList = new List<Credit_Approval__c>();
        	List<Disputed_Item__c> diUpdateList = new List<Disputed_Item__c>();
			Map<Id, Adjustment__c> adUpdateMap = new Map<Id, Adjustment__c>();

        	for (Adjustment__c adVar: adjustmentList) {
        		Boolean IsChanged = true;

        		// Fire adjustment recalculation only if case is updated for trigger updates
        		if (oldMap!=null && adVar.Case__c!=null) {
        			Adjustment__c oldAdj = oldMap.get(adVar.Id);
        			if (oldAdj.Case__c == adVar.Case__c ) {
        				IsChanged = false;
        			}
        		}

        		if (adVar.Case__c!=null && IsChanged) {
        			Case pCaseVar = pCaseMap.get(adVar.Case__c);

      				if (pCaseVar!=null) {
    	    			for (Credit_Approval__c caVar: pCaseVar.Credit_Adjustments__r) {
    	    				if (adVar.Type__c == caVar.Type__c) {
                                if (caVar.Adjustment__c!=adVar.Id) {
    	    					  caVar.Adjustment__c = adVar.Id;
                                  caUpdateList.add(caVar);
                                }
    	    				}
    	    			}

    	    			for (Disputed_Item__c diVar: pCaseVar.Disputed_Items__r) {
    	    				if (adVar.Type__c == diVar.Type__c) {
    	    					diVar.Adjustment__c = adVar.Id;
    	    					diUpdateList.add(diVar);

								if (adUpdateMap.get(adVar.Id) == null) {
									adUpdateMap.put(adVar.Id, new Adjustment__c(Id = adVar.Id, Is_APPC__c = (diVar.Is_APPC__c == 'Yes')));
								}
    	    				}
    	    			}
        			}
        		}
        	}


			if (!adUpdateMap.isEmpty()) {
				try {
					List<Adjustment__c> changedAdjustments = adUpdateMap.values();

					recursion.updateRecordState(context, changedAdjustments, monitoredFields);

					uow.registerDirty(changedAdjustments, true, AdjustmentModule.class.getName());
				} catch(exception e) { 
					system.debug('AdjustmentUpdateError:' + e.getStackTraceString());
					for (Adjustment__c adVar: adjustmentList) {
					  adVar.addError('Adjustment creation failed. Please contact your administrator.'); 
					}
				}
			}
        	
        	if (!diUpdateList.isEmpty()) {
                try {
                    uow.registerDirty(diUpdateList, true, AdjustmentModule.class.getName());
                } catch (exception e) { 
                    system.debug('DisputeCreateError:' + e.getStackTraceString());
                    for (Adjustment__c adVar: adjustmentList) {
                      adVar.addError('Adjustment creation failed. Please contact your administrator.'); 
                    }
                }
    		}

            if (!caUpdateList.isEmpty()) {
                try {
                    uow.registerDirty(caUpdateList, true, AdjustmentModule.class.getName());
                } catch (exception e) {
                    system.debug('CACreateError:' + e.getStackTraceString());
                    for (Adjustment__c adVar: adjustmentList) {
                      adVar.addError('Adjustment creation failed. Please contact your administrator.');
                    }
                }
            }
        }
    }
}