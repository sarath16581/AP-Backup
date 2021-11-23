/**************************************************
Type:       |
Purpose:    |
Used By:             
History:
--------------------------------------------------
07.02.2014  Mohamed.Atheek@bluewolf.com  Created
2021-09-09	seth.heang@auspost.com.au	Uplift SF API version to 52
**************************************************/

public class TIBCOSearchResult
{
	public List<String> errors {get; set;}

	public Boolean success {get; set;}

	public List<TIBCOTrackingResultWrapper> trackResults {get; set;}
	
	public TIBCOSearchResult()
	{
		errors = new List<String>();
		success = true;
		trackResults = new List<TIBCOTrackingResultWrapper>();
	}
}