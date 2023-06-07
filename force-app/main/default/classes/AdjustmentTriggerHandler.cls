/**
 * Date            Version          Owner               Desription
 * 28-Mar-17        1.0             Adrian A            Main Adjustment Trigger Handler Class
 * 02-Jun-23        1.1             Pratyush Chalasani  Carry-over Is_APPC__c from related Disputed Item
 */
public without sharing class AdjustmentTriggerHandler {

	public static Boolean adjustmentLink = false;
	public static Boolean adjRecursiveFlag = false;

	/* @created by: Adrian Recio
     * @description Main before insert trigger handler method              
     */        
    /*public static void beforeInsertTriggerHandler(List <Adjustment__c> newList){
    }*/
    
    /* @created by: Adrian Recio
     * @description Main before update trigger handler method              
     */  
    /*public static void beforeUpdateTriggerHandler(Map <Id, Adjustment__c> oldMap, List <Adjustment__c> newList){

    }*/

    /* @created by: Adrian Recio
     * @description Main after insert trigger handler method              
     */ 
    public static void afterInsertTriggerHandler(List <Adjustment__c> newList){
        system.debug('AdjRecursiveFlagInsert:' + AdjustmentTriggerHandler.adjRecursiveFlag);
    	if(AdjustmentTriggerHandler.adjRecursiveFlag == false){
    		bindCAandDIfromCase(null, newList);
    	}
    }

    /* @created by: Adrian Recio
     * @description Main after update trigger handler method              
     */ 
    public static void afterUpdateTriggerHandler(Map <Id, Adjustment__c> oldMap, List <Adjustment__c> newList){
        system.debug('AdjRecursiveFlagUpdate:' + AdjustmentTriggerHandler.adjRecursiveFlag);
    	if(AdjustmentTriggerHandler.adjRecursiveFlag == false){
    		bindCAandDIfromCase(oldMap, newList);
    	}
    }

    /* @created by: Adrian Recio
     * @description Main before delete trigger handler method       
     */  
    public static void beforeDeleteTriggerHandler(Map <Id, Adjustment__c> oldMap, List <Adjustment__c> oldList){
    }
	
    /* Method for binding the Credit Approval and Disputed Item fronm Case Record */
    public static void bindCAandDIfromCase(Map <Id, Adjustment__c> oldMap, List<Adjustment__c> adjustmentList){
    	
    	set<Id>caseIdSet = new set<Id>();

    	for(Adjustment__c adVar: adjustmentList){
    		caseIdSet.add(adVar.Case__c);
    	}

        if(caseIdSet.size()>0){
        	Map<Id, Case> pCaseMap = new Map<Id, Case>([Select Id, Related_Billing_Account__r.Source_System__c, 
                                                                    (Select Id, Type__c, Adjustment__c 
                                                                        from Credit_Adjustments__r where Status__c = 'Approved'), 
        															(Select Id, Type__c, Adjustment__c, ERP_Status__c, Is_APPC__c
                                                                        from Disputed_Items__r where Status__c = 'Verified Claim')
        															from Case where Id IN :caseIdSet]);

        	List<Credit_Approval__c> caUpdateList = new List<Credit_Approval__c>();
        	List<Disputed_Item__c> diUpdateList = new List<Disputed_Item__c>();
			List<Adjustment__c> adUpdateList = new List<Adjustment__c>();

        	for(Adjustment__c adVar: adjustmentList){

        		Boolean IsChanged = true;

        		// Fire adjustment recalculation only if case is updated for trigger updates
        		if(oldMap!=null && adVar.Case__c!=null){
        			Adjustment__c oldAdj = oldMap.get(adVar.Id);
        			if(oldAdj.Case__c == adVar.Case__c ){
                        //&& oldAdj.Status__c == adVar.Status__c){
        				IsChanged = false;
        			}
        		}

                //adVar.addError(string.valueOf(IsChanged));
                system.debug('Adjustment Changed:' + string.valueOf(IsChanged));

        		if(adVar.Case__c!=null && IsChanged){
        			Case pCaseVar = pCaseMap.get(adVar.Case__c);

        			system.debug('Matching Case:' + pCaseVar);

      				if(pCaseVar!=null){
    	    			for(Credit_Approval__c caVar: pCaseVar.Credit_Adjustments__r){
    	    				if(adVar.Type__c == caVar.Type__c){
                                if(caVar.Adjustment__c!=adVar.Id){
    	    					  caVar.Adjustment__c = adVar.Id;
                                  caUpdateList.add(caVar);
                                }
    	    				}
    	    			}

    	    			for(Disputed_Item__c diVar: pCaseVar.Disputed_Items__r){
    	    				if(adVar.Type__c == diVar.Type__c){
    	    					diVar.Adjustment__c = adVar.Id;
                                //diVar.ERP_Status__c = adVar.Status__c;
    	    					diUpdateList.add(diVar);

								adUpdateList.add(new Adjustment__c(Id = adVar.Id, Is_APPC__c = (diVar.Is_APPC__c == 'Yes')));
    	    				}
    	    			}
        			}
        		}

                //adVar.addError('DI Size:' + diUpdateList.size());
                system.debug('DI Size:' + diUpdateList.size());
        	}

        	
        	system.debug('recursivehit');
        	adjRecursiveFlag = true;
        	adjustmentLink = true;

			if (adUpdateList.size()>0) {
                try {
                    update adUpdateList; 
                } catch(exception e){ 
                    system.debug('AdjustmentUpdateError:' + e.getStackTraceString());
                    for(Adjustment__c adVar: adjustmentList){
                      adVar.addError('Adjustment creation failed. Please contact your administrator.'); 
                    }
                }
    		}
        	
        	if(diUpdateList.size()>0){
                try{
                    update diUpdateList; 
                }catch(exception e){ 
                    system.debug('DisputeCreateError:' + e.getStackTraceString());
                    for(Adjustment__c adVar: adjustmentList){
                      adVar.addError('Adjustment creation failed. Please contact your administrator.'); 
                    }
                }
    		}

            if(caUpdateList.size()>0){
                try{
                    update caUpdateList;
                }catch(exception e){
                    system.debug('CACreateError:' + e.getStackTraceString());
                    for(Adjustment__c adVar: adjustmentList){
                      adVar.addError('Adjustment creation failed. Please contact your administrator.');
                    }
                }
            }
        }
    }
}