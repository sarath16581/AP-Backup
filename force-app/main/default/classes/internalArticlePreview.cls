/* Authored by BlueWolf as part of SSSW project.
@changelog
2015-05-28 - Updated to include "with sharing" as part of security audit
2021-08-27 - Seth Heang - uplift SF API version to 52, the class is pending for decommission in future date
*/

public with sharing class internalArticlePreview
{

    public FAQ__kav thisArticle;
    public String myPage {get; set;}

    public internalArticlePreview(ApexPages.StandardController stdController) 

    {
  

        thisArticle = (FAQ__kav)stdController.getRecord();
        thisArticle = [SELECT Id, ArticleNumber, UrlName, PublishStatus 

                        FROM FAQ__kav 

                        WHERE Id = :thisArticle.Id LIMIT 1];
                        
        String pagePrefix = ExternalURL__c.getValues('ArticlePreview').myURL__c;
        String articleUrl = '#articleNumber=' + thisArticle.ArticleNumber;
        String articleUrlId = '&title=&draft=';
        if(thisArticle.PublishStatus=='Online')
        {
           articleUrlID = articleUrlId+'0';
        }
        else
        {
           articleUrlID = articleUrlId+'1';
        }
        myPage = pagePrefix + articleUrl + articleUrlID;
        system.debug(myPage);
        //comment the below post deployment
        //myPage = 'https://test.npe.auspost.com.au/help/#/help_and_support/search_for#articleNumber= 000001787&title';
    }


//This bit of code is not needed anymore
    public PageReference previewRedirect() 

    {


        

        

        String pagePrefix = 'http://nrss-pdev-elasticl-6pdniyciv1xy-90957674.ap-southeast-2.elb.amazonaws.com/help/#/help_and_support/search_for';

        String articleUrl = '#articleNumber=' + thisArticle.ArticleNumber;

String articleUrlID = '&title';
String URL = EncodingUtil.urlEncode('https://test.npe.auspost.com.au/help/#/help_and_support/search_for#articleNumber=000001371&title','UTF-8');

        system.debug(URL);

        //PageReference p = new PageReference(pagePrefix + articleUrl + articleUrlID);
        PageReference pg = new PageReference('https://test.npe.auspost.com.au/help/#/help_and_support/search_for#articleNumber=000001371&title');
        pg.setRedirect(true);
       system.debug(pg);

        return pg;

    }


}