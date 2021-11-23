/**************************************************
Type:       Visualforce controller
Purpose:    Provides the controller logic to create chart data for the Case History chart 
			in the format expected by the Flot.js charting library
Used By:    ContactCaseHistoryChartComponent.component         
History:
--------------------------------------------------
08.01.2014  Mohamed.Atheek@bluewolf.com  Created                                               
**************************************************/

public with sharing class ContactCaseHistoryChartComponentCont {
	private static Integer NUM_OF_MONTHS = 6;
	private Set<String> caseCloseStatuses = new Set<String> {'Closed', 'Closed – Manual', 'Closed – Expired'};
	
	public Id contId
	{
		get;
		set
		{
			if (value != null) 
			{
				contId = value;
				initChartData();
			}
		}
	}
	
	public String closedCaseChartData
	{
		get;
		private set;
	}
	
	public String openCaseChartData
	{
		get;
		private set;
	}
		
	private Contact contRecord;
	
	public ContactCaseHistoryChartComponentCont() 
	{
	}
	
	private String getChartData(List<Map<String, Integer>> caseHistoryList, String label, String align) 
	{
		JSONGenerator gen = JSON.createGenerator(true);
		gen.writeStartObject();
		
		gen.writeFieldName('label');
		gen.writeString(label);
		
		gen.writeFieldName('bars');
		gen.writeStartObject();
		gen.writeFieldName('align');
		gen.writeString(align);
		gen.writeEndObject();
		
		gen.writeFieldName('data');
		gen.writeStartArray();
		
		for (Map<String, Integer> m : caseHistoryList) 
		{
			for (String s : m.keySet()) 
			{//always 1 iteration
				gen.writeStartArray();
				gen.writeString(s);
				gen.writeNumber(m.get(s));
				gen.writeEndArray();
			}
		}
		
		gen.writeEndArray();
		gen.writeEndObject();
		
		return gen.getAsString();
	}
	
	private void initChartData() 
	{	
		List<Map<String, Integer>> caseHistoryList = new List<Map<String, Integer>>();
			
		Map<Integer, Integer> caseHistMap = new Map<Integer, Integer>();
		for (AggregateResult ar : [SELECT CALENDAR_MONTH(CreatedDate) mon, COUNT(id) caseCount
								  FROM Case 
								  WHERE ContactId = :contId AND (CreatedDate = THIS_MONTH OR CreatedDate = LAST_N_MONTHS:5) AND Status IN :caseCloseStatuses
								  GROUP BY CALENDAR_MONTH(CreatedDate) 
								  ORDER BY CALENDAR_MONTH(CreatedDate)]) 
		{
			caseHistMap.put((Integer)ar.get('mon'), (Integer)ar.get('caseCount'));
		}		
		caseHistoryList.addAll(ChartMonths.getLastNMonthsData(caseHistMap, NUM_OF_MONTHS, System.today().month()));
		closedCaseChartData = getChartData(caseHistoryList, 'Closed', 'right');
		
		caseHistoryList.clear();
		caseHistMap.clear();
		for (AggregateResult ar : [SELECT CALENDAR_MONTH(CreatedDate) mon, COUNT(id) caseCount
								  FROM Case 
								  WHERE ContactId = :contId AND (CreatedDate = THIS_MONTH OR CreatedDate = LAST_N_MONTHS:5) AND Status NOT IN :caseCloseStatuses
								  GROUP BY CALENDAR_MONTH(CreatedDate) 
								  ORDER BY CALENDAR_MONTH(CreatedDate)]) 
		{
			caseHistMap.put((Integer)ar.get('mon'), (Integer)ar.get('caseCount'));
		}		
		caseHistoryList.addAll(ChartMonths.getLastNMonthsData(caseHistMap, NUM_OF_MONTHS, System.today().month()));		
		openCaseChartData = getChartData(caseHistoryList, 'Open', 'left');
	}
}