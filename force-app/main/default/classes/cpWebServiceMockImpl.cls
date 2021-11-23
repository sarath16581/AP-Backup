//WebServiceMock for callout mock for CPMetadataService_Test class
@isTest
global class cpWebServiceMockImpl implements WebServiceMock {
    public void doInvoke(
        Object stub, Object request, Map<String, Object> response,
        String endpoint, String soapAction, String requestName,
        String responseNS, String responseName, String responseType) {
        //Create keywords
        list<cpMetadataService.KeywordLists> keywordList_x = new list<cpMetadataService.KeywordLists>();  
        cpMetadataService.Keyword keyword1 = new cpMetadataService.Keyword();
        keyword1.keyword = 'XXXX1';
        cpMetadataService.Keyword keyword2 = new cpMetadataService.Keyword();
        keyword2.keyword = 'XXXX2';
        
        cpMetadataService.KeywordLists l1 = new cpMetadataService.KeywordLists();
        l1.keywords = new list <cpMetadataService.Keyword> {keyword1};
        
        cpMetadataService.KeywordLists l2 = new cpMetadataService.KeywordLists();
        l2.keywords = new list <cpMetadataService.Keyword> {keyword2};
            
        keywordList_x.add(l1);
        keywordList_x.add(l2);
        cpMetadataService.readKeywordListResponse_element response_x = new cpMetadataService.readKeywordListResponse_element();
        cpMetadataService.ReadKeywordListResult res = new cpMetadataService.ReadKeywordListResult();
        res.records = keywordList_x;
        response_x.result = res;
        response.put('response_x', response_x);
    }
}