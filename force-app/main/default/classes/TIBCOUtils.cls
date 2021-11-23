/*
 * changelog:
 * 2021-09-09	seth.heang@auspost.com.au	Uplift SF API version to 52
*/
public class TIBCOUtils {
	public static Date parseDateYYYYMMDD(String s) 
	{
		try 
		{
			Integer y = Integer.valueOf(s.substring(0, 4));
			Integer m = Integer.valueOf(s.substring(4, 6));
			Integer d = Integer.valueOf(s.substring(6, 8));
			return Date.newInstance(y, m, d);
		}
		catch (Exception e)
		{
			return null;
		}
	}
	
	public static String removeNull(String s)
	{
		return s == null ? '' : s;
	}

}