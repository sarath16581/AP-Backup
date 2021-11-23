/**************************************************
Type:       Utility Class for Budget and Revenue
Purpose:    
Used By:    
History:
--------------------------------------------------
16.08.2012  M. Isidro (Cloud Sherpas)   	Created
17.08.2012	M. Isidro (Cloud Sherpas) 		Added methods to support BudgetRevenueBatchable Class
27.08.2012	Richard Enojas (Salesforce.com)	Added other fields in SOQL for requeryBARByMonthsList
28.08.2012	M. Isidro (Cloud Sherpas)		Fixed SOQL error on MTD field not included in the query / Changed Budget to Target MTD and Actual to Revenue MTD
04.09.2012	M. Isidro (Cloud Sherpas)		Added test coverage
26.09.2012 	M. Isidro (Cloud Sherpas)   	Modified test coverage (Removed @isTest(seeAllData=true), added test data) 
**************************************************/
public with sharing class BudgetRevenueUtility {
	
	
	public static void deleteBudgetandRevenueByMonth(String strYear, String strMonth) {
		// Delete the record/s for current month and FY
		List<Budget_and_Revenue_by_Months__c> delBARByMonthsList = 
		[Select Id from Budget_and_Revenue_by_Months__c 
		where CreatedDate <> today And Financial_Year__c = :strYear and Month__c = :strMonth]; 
	
		if (!delBARByMonthsList.isEmpty()) {
			delete delBARByMonthsList;
		}		
	}
	
	
	public static void createRevenueandBudgetByMonth(Map<String, Decimal> mapRepSegmentTotal, Map<String, Decimal> mapRepSegmentBudget, List<Budget_and_Revenue_by_Months__c> addBARBMList, String strYear, String strMonth) {
		// Create Revenue By Month records based on the Mapping
		for (String str : mapRepSegmentTotal.keySet()) {
			List<String> strRepSegment = new List<String>();
			strRepSegment = str.split(':', 0);
			addBARBMList.add(
				new Budget_and_Revenue_by_Months__c(
					Financial_Year__c = strYear,
					Month__c = strMonth,
					Budget_or_Revenue__c = 'Revenue MTD',
					OwnerId = strRepSegment[0],
					Sales_Rep__c = strRepSegment[0],
					Sales_Segment__c = strRepSegment[1],
					MTD__c = mapRepSegmentTotal.get(str) )
			);	
		}
		
		// Create Budget By Month records based on the Mapping
		for (String str : mapRepSegmentBudget.keySet()) {
			List<String> strRepSegment = new List<String>();
			strRepSegment = str.split(':', 0);
			addBARBMList.add(
				new Budget_and_Revenue_by_Months__c(
					Financial_Year__c = strYear,
					Month__c = strMonth,
					Budget_or_Revenue__c = 'Target MTD',
					OwnerId = strRepSegment[0],
					Sales_Rep__c = strRepSegment[0],
					Sales_Segment__c = strRepSegment[1],
					MTD__c = mapRepSegmentBudget.get(str) )
			);	
		}	
	}
	
	
	public static void updateExistingBARBYM(Budget_and_Revenue_by_Months__c barbymExisting, Budget_and_Revenue_by_Months__c barbymNew) {
		barbymExisting.MTD__c = checkAmount(barbymExisting.MTD__c) + checkAmount(barbymNew.MTD__c);      
	}	
	
	public static void compareNewandExistingBARBYM(Map<String, Budget_and_Revenue_by_Months__c> mapNewRepSegmentTotal, Map<String, Budget_and_Revenue_by_Months__c> mapNewRepSegmentBudget, Map<String, Budget_and_Revenue_by_Months__c> mapRequeryRepSegmentTotal, Map<String, Budget_and_Revenue_by_Months__c> mapRequeryRepSegmentBudget, List<Budget_and_Revenue_by_Months__c> insertBARBYMList, List<Budget_and_Revenue_by_Months__c> updateBARBYMList) {
		// Compare New and Existing Revenue By Month records
		for (Budget_and_Revenue_by_Months__c barbymNew : mapNewRepSegmentTotal.values()) {
			String uniqueId = barbymNew.Sales_Rep__c + ':'
			+ barbymNew.Sales_segment__c + ':'
			+ barbymNew.Budget_or_Revenue__c;
		
			if (mapRequeryRepSegmentTotal.containsKey(uniqueId)) {
            	Budget_and_Revenue_by_Months__c barbymExisting = mapRequeryRepSegmentTotal.get(uniqueId);	
        		updateExistingBARBYM(barbymExisting, barbymNew);    	
        		updateBARBYMList.add(barbymExisting);						
			} else {
				insertBARBYMList.add(barbymNew);					
			}	
		}
		
		// Compare New and Existing Budget By Month records
		for (Budget_and_Revenue_by_Months__c barbymNew : mapNewRepSegmentBudget.values()) {
			String uniqueId = barbymNew.Sales_Rep__c + ':'
			+ barbymNew.Sales_segment__c + ':'
			+ barbymNew.Budget_or_Revenue__c;
		
			if (mapRequeryRepSegmentBudget.containsKey(uniqueId)) {
            	Budget_and_Revenue_by_Months__c barbymExisting = mapRequeryRepSegmentBudget.get(uniqueId);	
        		updateExistingBARBYM(barbymExisting, barbymNew);    	
        		updateBARBYMList.add(barbymExisting);						
			} else {
				insertBARBYMList.add(barbymNew);					
			}	
		}	
		
		// Update existing
		if (!updateBARBYMList.isEmpty()) {
			Database.SaveResult[] SR = Database.update(updateBARBYMList, false);
			system.debug('***SR: ' + SR);	
		}	
		
		// Save new
		if (!insertBARBYMList.isEmpty()) {
			Database.SaveResult[] SR = Database.insert(insertBARBYMList, false);
			system.debug('***SR: ' + SR);				
		}
			
	}
	
	
	public static void mapNewBARByMonth(List<Budget_and_Revenue_by_Months__c> addBARBMList, Map<String, Budget_and_Revenue_by_Months__c> mapNewRepSegmentTotal, Map<String, Budget_and_Revenue_by_Months__c> mapNewRepSegmentBudget) {
		// Map new budget and revenue by month
		for (Budget_and_Revenue_by_Months__c barbym : addBARBMList) {
			if ( (!mapNewRepSegmentTotal.containsKey(barbym.Sales_Rep__c + ':' + barbym.Sales_Segment__c) ) && (barbym.Budget_or_Revenue__c == 'Revenue MTD') ) {
				mapNewRepSegmentTotal.put(barbym.Sales_Rep__c + ':' + barbym.Sales_Segment__c + ':' + barbym.Budget_or_Revenue__c, barbym);
			} else if ( (!mapNewRepSegmentBudget.containsKey(barbym.Sales_Rep__c + ':' + barbym.Sales_Segment__c) ) && (barbym.Budget_or_Revenue__c == 'Target MTD') ) {
				mapNewRepSegmentBudget.put(barbym.Sales_Rep__c + ':' + barbym.Sales_Segment__c + ':' + barbym.Budget_or_Revenue__c, barbym);				
			} 				
		}	
	}
	
	
	public static List<Budget_and_Revenue_by_Months__c> requeryBudgetandRevenueByMonth(String strYear, String strMonth) {
		// Requery the budget and revenue for the current FY and month
		List<Budget_and_Revenue_by_Months__c> requeryBARByMonthsList = 
		[Select Id, Sales_Rep__c, Sales_Segment__c, Budget_or_Revenue__c, MTD__c from Budget_and_Revenue_by_Months__c 
		where CreatedDate = today And Financial_Year__c = :strYear and Month__c = :strMonth]; 
	
		return requeryBARByMonthsList;
	}	
	
	
	public static void mapExistingBARByMonth(List<Budget_and_Revenue_by_Months__c> requeryBARByMonthsList, Map<String, Budget_and_Revenue_by_Months__c> mapRequeryRepSegmentTotal, Map<String, Budget_and_Revenue_by_Months__c> mapRequeryRepSegmentBudget) {
		// Map existing budget and revenue by month
		for (Budget_and_Revenue_by_Months__c barbym : requeryBARByMonthsList) {
			if ( (!mapRequeryRepSegmentTotal.containsKey(barbym.Sales_Rep__c + ':' + barbym.Sales_Segment__c) ) && (barbym.Budget_or_Revenue__c == 'Revenue MTD') ) {
				mapRequeryRepSegmentTotal.put(barbym.Sales_Rep__c + ':' + barbym.Sales_Segment__c + ':' + barbym.Budget_or_Revenue__c, barbym);
			} else if ( (!mapRequeryRepSegmentBudget.containsKey(barbym.Sales_Rep__c + ':' + barbym.Sales_Segment__c) ) && (barbym.Budget_or_Revenue__c == 'Target MTD') ) {
				mapRequeryRepSegmentBudget.put(barbym.Sales_Rep__c + ':' + barbym.Sales_Segment__c + ':' + barbym.Budget_or_Revenue__c, barbym);				
			} 
		}	
	} 


	public static void mapBudgetandRevenue(List<Budget_and_Revenue__c> barList, Integer iMonth, Map<String, Decimal> mapRepSegmentTotal, Map<String, Decimal> mapRepSegmentBudget) {
		// Map the budget and revenue per Account Owner:Sales Segment
		for (Budget_and_Revenue__c bar : barList) {
			Decimal revenueAmount = getRevenueAmount(bar, iMonth);
			Decimal budgetAmount = getBudgetAmount(bar, iMonth);
			
			if (mapRepSegmentTotal.containsKey(bar.Organisation__r.OwnerId + ':' + bar.Organisation__r.Sales_Segment__c)) {
				if (revenueAmount > 0) {
					mapRepSegmentTotal.put(bar.Organisation__r.OwnerId + ':' + bar.Organisation__r.Sales_Segment__c,
					mapRepSegmentTotal.get(bar.Organisation__r.OwnerId + ':' + bar.Organisation__r.Sales_Segment__c) + revenueAmount
					);						
				}
			} else {
				if (revenueAmount > 0) {
					mapRepSegmentTotal.put(bar.Organisation__r.OwnerId + ':' + bar.Organisation__r.Sales_Segment__c, revenueAmount);
				}
			}
			
			if (mapRepSegmentBudget.containsKey(bar.Organisation__r.OwnerId + ':' + bar.Organisation__r.Sales_Segment__c)) {
				SYSTEM.DEBUG('***mapRepSegmentBudget: ' + mapRepSegmentBudget);
				if (budgetAmount > 0) {
					mapRepSegmentBudget.put(bar.Organisation__r.OwnerId + ':' + bar.Organisation__r.Sales_Segment__c,
					mapRepSegmentBudget.get(bar.Organisation__r.OwnerId + ':' + bar.Organisation__r.Sales_Segment__c) +	budgetAmount
					);						
				}
			} else {
				if (budgetAmount > 0) {
					mapRepSegmentBudget.put(bar.Organisation__r.OwnerId + ':' + bar.Organisation__r.Sales_Segment__c, budgetAmount);
				}
			}
			
		}			
	}
	

	public static Decimal checkAmount(Decimal amt) {
		// Check for the amount and return 0 for any amount which is not greater than 0
        if (amt > 0) {
            return amt;
        } else {
            return 0;
        }   
    }
    
    
    public static Decimal getRevenueAmount(Budget_and_Revenue__c bar, Integer iMonth) {
    	// Get the revenue amount for a given month
    	Decimal revenueAmount;
		if (iMonth == 1) {
			revenueAmount = bar.Jan_Revenue_Amount__c;
		} else if (iMonth == 2) {
			revenueAmount = bar.Feb_Revenue_Amount__c;
		} else if (iMonth == 3) {
			revenueAmount = bar.Mar_Revenue_Amount__c;
		} else if (iMonth == 4) {
			revenueAmount = bar.Apr_Revenue_Amount__c;
		} else if (iMonth == 5) {
			revenueAmount = bar.May_Revenue_Amount__c;
		} else if (iMonth == 6) {
			revenueAmount = bar.Jun_Revenue_Amount__c;
		} else if (iMonth == 7) {
			revenueAmount = bar.Jul_Revenue_Amount__c;
		} else if (iMonth == 8) {
			revenueAmount = bar.Aug_Revenue_Amount__c;
		} else if (iMonth == 9) {
			revenueAmount = bar.Sep_Revenue_Amount__c;
		} else if (iMonth == 10) {
			revenueAmount = bar.Oct_Revenue_Amount__c;
		} else if (iMonth == 11) {
			revenueAmount = bar.Nov_Revenue_Amount__c;
		} else if (iMonth == 12) {
			revenueAmount = bar.Dec_Revenue_Amount__c;
		}
		return revenueAmount;	    	
    }
   
   
    public static Decimal getBudgetAmount(Budget_and_Revenue__c bar, Integer iMonth) {
    	// Get the budget amount for a given month
    	Decimal budgetAmount;
		if (iMonth == 1) {
			budgetAmount = bar.Jan_Original_Budget__c;
		} else if (iMonth == 2) {
			budgetAmount = bar.Feb_Original_Budget__c;
		} else if (iMonth == 3) {
			budgetAmount = bar.Mar_Original_Budget__c;
		} else if (iMonth == 4) {
			budgetAmount = bar.Apr_Original_Budget__c;
		} else if (iMonth == 5) {
			budgetAmount = bar.May_Original_Budget__c;
		} else if (iMonth == 6) {
			budgetAmount = bar.Jun_Original_Budget__c;
		} else if (iMonth == 7) {
			budgetAmount = bar.Jul_Original_Budget__c;
		} else if (iMonth == 8) {
			budgetAmount = bar.Aug_Original_Budget__c;
		} else if (iMonth == 9) {
			budgetAmount = bar.Sep_Original_Budget__c;
		} else if (iMonth == 10) {
			budgetAmount = bar.Oct_Original_Budget__c;
		} else if (iMonth == 11) {
			budgetAmount = bar.Nov_Original_Budget__c;
		} else if (iMonth == 12) {
			budgetAmount = bar.Dec_Original_Budget__c;
		}
		return budgetAmount;	    	
    }
    
       
    public static String getMonth(Integer iMonth) {
    	// Get the 3-letter month name from month value
    	if (iMonth == 1) {
    		return 'Jan';	
    	} else if (iMonth == 2) {
    		return 'Feb';
    	} else if (iMonth == 3) {
    		return 'Mar';
    	} else if (iMonth == 4) {
    		return 'Apr';
    	} else if (iMonth == 5) {
    		return 'May';
    	} else if (iMonth == 6) {
    		return 'Jun';
    	} else if (iMonth == 7) {
    		return 'Jul';
    	} else if (iMonth == 8) {
    		return 'Aug';
    	} else if (iMonth == 9) {
    		return 'Sep';
    	} else if (iMonth == 10) {
    		return 'Oct';
    	} else if (iMonth == 11) {
    		return 'Nov';
    	} else if (iMonth == 12) {
    		return 'Dec';
    	}	
		else {
			return '';
		}    	
    }


	public static void updateMTDFields(List<Budget_and_Revenue__c> barList) {
		if (barList.size() > 0) {
			for (Budget_and_Revenue__c bar : barList) {
				system.debug('BEFORE: bar: ' + bar);
				bar.MTDActual__c = bar.MTD_Actual__c;
				bar.MTD_Actual_Last_Year_R__c = bar.MTD_Actual_Last_Year__c;
				bar.MTD_Original_Budget_R__c = bar.MTD_Original_Budget__c;
				system.debug('AFTER: bar: ' + bar);
			}
			update barList;
		}	
	}    
    
	//@isTest(seeAllData=true)
	private static testMethod void testBudgetRevenueUtility() {
		
        RecordType orgrectype = [SELECT Id 
                                FROM RecordType 
                                WHERE IsActive = true AND SobjectType = 'Account' AND Name = 'Organisation' limit 1];
        
        //create account
        Account bacct = new Account(name='test org', recordtypeid=orgrectype.Id, type='Small Business',  phone='11111111', email__c='test@test.com', abn__c='12345678901', Website='www.google.com');
        insert bacct; 
        		
		List<Budget_and_Revenue__c> barList = new List<Budget_and_Revenue__c>();
		Integer nCount = 12;
		for( Integer i=0; i<nCount; i++){
			Budget_and_Revenue__c bar = new Budget_and_Revenue__c(
				Organisation__c=bacct.id, 
				Financial_Year__c= String.valueOf(2010 + Math.mod(i, 4)), 
				Jan_Revenue_Amount__c=100, 
				Feb_Revenue_Amount__c=200,
				Mar_Revenue_Amount__c=300,
				Apr_Revenue_Amount__c=400,
				May_Revenue_Amount__c=500,
				Jun_Revenue_Amount__c=600,
				Jul_Revenue_Amount__c=700,
				Aug_Revenue_Amount__c=800,
				Sep_Revenue_Amount__c=900,
				Oct_Revenue_Amount__c=1000,
				Nov_Revenue_Amount__c=1100,
				Dec_Revenue_Amount__c=1200,
				Jan_Original_Budget__c=1000,
				Feb_Original_Budget__c=2000,
				Mar_Original_Budget__c=3000,
				Apr_Original_Budget__c=4000,
				May_Original_Budget__c=5000,
				Jun_Original_Budget__c=6000,
				Jul_Original_Budget__c=7000,
				Aug_Original_Budget__c=8000,
				Sep_Original_Budget__c=9000,
				Oct_Original_Budget__c=10000,
				Nov_Original_Budget__c=11000,
				Dec_Original_Budget__c=12000
				);
				
			barList.add(bar);									
		}
		insert barList;		
		
		system.debug('*** barList: ' + barList);
		
		for (Integer i=1; i <= nCount; i++) {
			BudgetRevenueUtility.getRevenueAmount(barList[i-1], i);
			BudgetRevenueUtility.getBudgetAmount(barList[i-1], i);
			BudgetRevenueUtility.getMonth(i);
		}
				
		test.startTest();
		
		BudgetRevenueBatchable brb = new BudgetRevenueBatchable();
		Database.executeBatch(brb, 1000);

		test.stopTest();
	}      
}