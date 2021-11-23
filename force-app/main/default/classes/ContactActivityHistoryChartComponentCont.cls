/**************************************************
Type:       Visualforce controller
Purpose:    Provides the controller logic to create chart data for the Activity History chart 
			in the format expected by the Flot.js charting library
Used By:    ContactActivityHistoryChartComponent.component         
History:
--------------------------------------------------
08.01.2014  Mohamed.Atheek@bluewolf.com  Created                                               
**************************************************/

public with sharing class ContactActivityHistoryChartComponentCont 
{
	private static Integer NUM_OF_MONTHS = 6;
	
	//private static final Set<String> TYPE_CALL = new Set<String>{'Call', 'Phone Call'};
	//private static final Set<String> TYPE_EMAIL = new Set<String>{'Email'};
	//private static final Set<String> TYPE_SMS = new Set<String>{'SMS'};
	
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
	
	public String callChartData
	{
		get;
		private set;
	}
	
	public String emailChartData
	{
		get;
		private set;
	}
	
	public String smsChartData
	{
		get;
		private set;
	}	
	
	public ContactActivityHistoryChartComponentCont() 
	{		
	}
	
	private String getChartData(List<Map<String, Integer>> dataList, String label) 
	{
		JSONGenerator gen = JSON.createGenerator(true);
		gen.writeStartObject();
		
		gen.writeFieldName('label');
		gen.writeString(label);		
		
		gen.writeFieldName('data');
		gen.writeStartArray();
		
		for (Map<String, Integer> m : dataList) 
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
		//Call data
		List<Map<String, Integer>> callHistoryList = new List<Map<String, Integer>>();	
			
		Map<Integer, Integer> callHistMap = new Map<Integer, Integer>();
		for (AggregateResult ar : [SELECT CALENDAR_MONTH(CreatedDate) mon, COUNT(id) callCount
								  FROM Task 
								  WHERE WhoId = :contId AND (CreatedDate = THIS_MONTH OR CreatedDate = LAST_N_MONTHS:5) AND RecordType.DeveloperName = :Constants.RECORDTYPE_NAME_TASK_SSSWCALL
								  GROUP BY CALENDAR_MONTH(CreatedDate) 
								  ORDER BY CALENDAR_MONTH(CreatedDate)]) 
		{
			callHistMap.put((Integer)ar.get('mon'), (Integer)ar.get('callCount'));
		}

		callHistoryList.addAll(ChartMonths.getLastNMonthsData(callHistMap, NUM_OF_MONTHS, System.today().month()));
		
		callChartData = getChartData(callHistoryList, 'Call');
		
		//Email data
		List<Map<String, Integer>> emailHistoryList = new List<Map<String, Integer>>();	
			
		Map<Integer, Integer> emailHistMap = new Map<Integer, Integer>();
		for (AggregateResult ar : [SELECT CALENDAR_MONTH(CreatedDate) mon, COUNT(id) emailCount
								  FROM Task 
								  WHERE WhoId = :contId AND (CreatedDate = THIS_MONTH OR CreatedDate = LAST_N_MONTHS:5) AND Subject Like 'Email:%' //Type IN :TYPE_EMAIL
								  GROUP BY CALENDAR_MONTH(CreatedDate) 
								  ORDER BY CALENDAR_MONTH(CreatedDate)]) 
		{
			emailHistMap.put((Integer)ar.get('mon'), (Integer)ar.get('emailCount'));
		}

		emailHistoryList.addAll(ChartMonths.getLastNMonthsData(emailHistMap, NUM_OF_MONTHS, System.today().month()));
		
		emailChartData = getChartData(emailHistoryList, 'Email');
		
		//SMS data
		List<Map<String, Integer>> smsHistoryList = new List<Map<String, Integer>>();	
			
		Map<Integer, Integer> smsHistMap = new Map<Integer, Integer>();
		for (AggregateResult ar : [SELECT CALENDAR_MONTH(CreatedDate) mon, COUNT(id) smsCount
								  FROM Task 
								  WHERE WhoId = :contId AND (CreatedDate = THIS_MONTH OR CreatedDate = LAST_N_MONTHS:5) AND RecordType.DeveloperName = :Constants.RECORDTYPE_NAME_TASK_SSSWSMS
								  GROUP BY CALENDAR_MONTH(CreatedDate) 
								  ORDER BY CALENDAR_MONTH(CreatedDate)]) 
		{
			smsHistMap.put((Integer)ar.get('mon'), (Integer)ar.get('smsCount'));
		}

		smsHistoryList.addAll(ChartMonths.getLastNMonthsData(smsHistMap, NUM_OF_MONTHS, System.today().month()));
		
		smsChartData = getChartData(smsHistoryList, 'SMS');		
	}
}