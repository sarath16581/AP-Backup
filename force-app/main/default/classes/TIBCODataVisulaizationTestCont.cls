public class TIBCODataVisulaizationTestCont 
{
	
	public String articleId {get; set;}
	public Boolean showSapData {get; set;}
	public TIBCOSearchResult searchResult {get; set;}
	
	public TIBCODataVisulaizationTestCont()
	{
		showSapData = false;
	}
	
	public PageReference search()
	{
		showSapData = true;
		searchResult = TIBCOArticleService.searchArticles(new List<String>{articleId}, true);
		
		/*String p = ApexPages.currentPage().getParameters().get('v');
		if (p != null && p == 'a')
		{
			searchResult = TIBCOArticleService.generateArticleTestData();
		}
		else
		{				
			searchResult = TIBCOArticleService.generateConsignmentTestData();
		}*/
		
		return null;
	}
	
	public PageReference createArticles()
	{
		if (searchResult != null)
		{
			TIBCODataTranslator translator = new TIBCODataTranslator(searchResult.trackResults);
			translator.save();
		}
		return null;
	}
}