/**************************************************
Type:       Test class for the ChartMonths class
Purpose:    Tests the correct chart month data is returned 
       
History:
--------------------------------------------------
15.01.2014  Mohamed.Atheek@bluewolf.com  Created                                               
**************************************************/

@isTest
private class TestChartMonths 
{

    static testMethod void testChartMonths() 
    {
        Map<Integer, Integer> dataMap = new Map<Integer, Integer> 
        {
        			//Jan 
        	2 => 2, //Feb
        	3 => 3, //Mar
        	4 => 4, //Apr
        	5 => 5, //May
        	6 => 6, //Jun
        	7 => 7, //Jul
        	8 => 8, //Aug
        	9 => 9, //Sep
        	10 => 10, //Oct
        	11 => 11, //Nov
        	12 => 12 //Dec
        };
        
        List<Map<String, Integer>> res = ChartMonths.getLastNMonthsData(dataMap, 6, 8);
        
        System.assertEquals(6, res.size());
        System.assertEquals(3, res[0].get('Mar'));
        System.assertEquals(8, res[5].get('Aug'));
        
        res = ChartMonths.getLastNMonthsData(dataMap, 7, 2);
        
        System.assertEquals(7, res.size());
        System.assertEquals(8, res[0].get('Aug'));
        System.assertEquals(2, res[6].get('Feb'));
        
        res = ChartMonths.getLastNMonthsData(dataMap, 12, 11);
        
        System.assertEquals(12, res.size());
        System.assertEquals(12, res[0].get('Dec'));
        System.assertEquals(11, res[11].get('Nov'));
        
        res = ChartMonths.getLastNMonthsData(dataMap, 0, 8);
        
        System.assertEquals(12, res.size());
        System.assertEquals(9, res[0].get('Sep'));
        System.assertEquals(8, res[11].get('Aug'));
        
        System.assertEquals('Jan', ChartMonths.getMonthName(1));
        System.assertEquals('Dec', ChartMonths.getMonthName(12));
    }
}