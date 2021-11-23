/**************************************************
Type:       Visualforce controller
Purpose:    Provides the controller logic to create chart data for the Contact Case 
			product category mix in the format expected by the Flot.js charting library.
Used By:    ContactProductChartComponent.component         
History:
--------------------------------------------------
1.05.2014  Amy.Tran@bluewolf.com  Created                                               
**************************************************/

public with sharing class ContactProductChartComponentCont {
	
	public Id contId {
		get;
		set {
			if (value != null) {
				contId = value;
				initChartData();
			}
		}
	}
	
	public transient String productChartData { get; private set; }
	
	public ContactProductChartComponentCont() {}
	
	private String getChartData(Map<String, Decimal> productMixMap) {
		Decimal total = 0;
		
		for (Decimal i : productMixMap.values()) {
			total = total + i;
		}
		
		JSONGenerator gen = JSON.createGenerator(true);
		
		gen.writeStartArray();
		
		for (String s : productMixMap.keySet()) {
			gen.writeStartObject();
			gen.writeStringField('label', s);
			gen.writeNumberField('data', Math.round((productMixMap.get(s) / total) * 100));
			gen.writeEndObject();
		}
		
		gen.writeEndArray();
		
		return gen.getAsString();
	}
	
	private void initChartData() {	
		Map<String, Decimal> productMixMap = new Map<String, Decimal>();
		
		for (Case c : [SELECT ProductCategory__c FROM Case WHERE ContactId = :contId]) {
			if (c.ProductCategory__c != null) {
				Decimal count = productMixMap.get(c.ProductCategory__c) != null ? productMixMap.get(c.ProductCategory__c) : 0;
				productMixMap.put(c.ProductCategory__c, count + 1);
			}
		}
		
		if (productMixMap != null) {
			productChartData = getChartData(productMixMap);
		}
	}
}