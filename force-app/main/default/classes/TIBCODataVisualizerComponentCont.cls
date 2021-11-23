/**************************************************
Type:       |
Purpose:    |
Used By:             
History:
--------------------------------------------------
03.01.2014  Mohamed.Atheek@bluewolf.com  Created                                               
**************************************************/

public class TIBCODataVisualizerComponentCont
{	
	public TIBCOSearchResult searchResultVar { get;	set; }
	public boolean enableCreateCaseVar { get;	set; }
	
	public PageReference save()
	{
		try 
		{
			if (searchResultVar.success)
			{
				TIBCODataTranslator translator = new TIBCODataTranslator(searchResultVar.trackResults);
				translator.save();
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Cases Created/Updated'));
			} 
			else 
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Tracking Results to display'));
			}
		} 
		catch (Exception e)
		{
			ApexPages.addMessages(e);
		}
		
		return null;
	}
}