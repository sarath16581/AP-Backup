/**************************************************
Type:       Utility class to process month data for charts
Purpose:    Processes chart data and converts the month data which are in numbers to the names
Used By:    ContactActivityHistoryChartComponentCont.cls, ContactCaseHistoryChartComponentCont.cls         
History:
--------------------------------------------------
15.01.2014  Mohamed.Atheek@bluewolf.com  Created                                               
**************************************************/

public class ChartMonths 
{
	
	private static Map<Integer, String> monthNames = new Map<Integer, String> 
	{
		1 => 'Jan',
		2 => 'Feb',
		3 => 'Mar',
		4 => 'Apr',
		5 => 'May',
		6 => 'Jun',
		7 => 'Jul',
		8 => 'Aug',
		9 => 'Sep',
		10 => 'Oct',
		11 => 'Nov',
		12 => 'Dec'
	};
	
	/*
	 * parameter dataMap : map of month index vs data for that month. eg { 1 => 29, 2 => 45, 3 => 34, 4 => 21, 5 => 74, 6 => 19}
	 * parameter n : number of month data upto the endMonth to return from the map eg 3
	 * parameter endMonth : last month to be return eg 5
	 * 
	 * returns [{'Mar' => 34}, {'Apr' => 21}, {'May' => 74}]
	 */
	public static List<Map<String, Integer>> getLastNMonthsData(Map<Integer, Integer> dataMap, Integer n, Integer endMonth) 
	{
		n = Math.mod(Math.abs(n), 12);
		n = n == 0 ? 12 : n;
		
		Integer startMonth = Math.mod(Math.abs(endMonth - (n - 1) + 12), 12);
		startMonth = startMonth == 0 ? 12 : startMonth;
		
		List<Map<String, Integer>> result = new List<Map<String, Integer>>(); 
		for (Integer i = 0; i < n ; i++) 
		{
			Integer m = Math.mod(startMonth + i, 12);
			m = m == 0 ? 12 : m;
			
			if (dataMap.containsKey(m)) 
			{
				result.add(new Map<String, Integer> {monthNames.get(m) => dataMap.get(m)});
			} 
			else 
			{
				result.add(new Map<String, Integer> {monthNames.get(m) => 0});
			}
		}
		
		return result;
	}

	public static String getMonthName(Integer monthNum) {
		Integer n = Math.mod(Math.abs(monthNum), 12);
		n = n == 0 ? 12 : n;
		
		return monthNames.get(n);
	}

}