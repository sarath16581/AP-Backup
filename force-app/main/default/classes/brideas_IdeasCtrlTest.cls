@isTest
private class brideas_IdeasCtrlTest {

	@testSetup
	static void setup() {
		List<Idea> ideasList;
		Idea testIdea_1;
		String cId;
		Profile stdUserProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User'];

		cId = brideas_Helper.getCommunityId('');

        if (cId == NULL || cId == '') {
            throw new brideas_SetupException('To succesfully run the tests you need to crete a Zone with Name="TestPublic"');
        }

		User testUser = new User(Alias = 'testusr', Email='testusr@testorg.com',
							EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
							LocaleSidKey='en_US', ProfileId = stdUserProfile.Id,
							TimeZoneSidKey='America/Los_Angeles', UserName='testusr@testorg.com');

        Test.startTest();

		ideasList = new List<Idea>();
		ideasList.add(new Idea(Title='Test idea_1', Body='Body of test idea_1', Status='New', Categories='test_1', CommunityId=cId));
		ideasList.add(new Idea(Title='Test idea_2', Body='Body of test idea_2', Status='Delivered', Categories='test_1', CommunityId=cId));
		ideasList.add(new Idea(Title='Test idea_3', Body='Body of test idea_3', Status='New', Categories='test_2', CommunityId=cId));
		ideasList.add(new Idea(Title='Test idea_4', Body='Body of test idea_4', Status='New', Categories='test_2', CommunityId=cId));

		insert ideasList;

		testIdea_1 = [SELECT Id FROM Idea WHERE Title = 'Test idea_1' LIMIT 1];

		insert new IdeaComment(CommentBody='First comment', IdeaId=testIdea_1.Id);

		System.runAs(testUser) {
			ideasList = new List<Idea>();
			ideasList.add(new Idea(Title='Test idea_5', Body='Body of test idea_5', Status='New', Categories='test_3', CommunityId=cId));
			ideasList.add(new Idea(Title='Test idea_6', Body='Body of test idea_6', Status='New', Categories='test_2', CommunityId=cId));
			ideasList.add(new Idea(Title='Test idea_7', Body='Body of test idea_7', Status='Delivered', Categories='test_2', CommunityId=cId));
			ideasList.add(new Idea(Title='Test idea_8', Body='Body of test idea_8', Status='New', Categories='test_2', CommunityId=cId));

			insert ideasList;

			insert new Vote(ParentId=testIdea_1.Id, Type='Up');
			insert new IdeaComment(CommentBody='Second comment', IdeaId=testIdea_1.Id);
		}

        Test.stopTest();

        Integer createdIdeasCount = [SELECT COUNT() FROM Idea];
        Integer newStatusCount = [SELECT COUNT() FROM Idea WHERE Status = 'New'];
        Integer deliveredStatusCount = [SELECT COUNT() FROM Idea WHERE Status = 'Delivered'];
        Integer categoryCount = [SELECT COUNT() FROM Idea WHERE Categories = 'test_1'];
        System.assertEquals(8, createdIdeasCount, 'Test data insertion failed');
        System.assertEquals(6, newStatusCount, 'Wrong initial statuses for inserted ideas');
        System.assertEquals(2, deliveredStatusCount, 'Wrong initial statuses for inserted ideas');
        System.assertEquals(2, categoryCount, 'Wrong initial categories for inserted ideas');
    }

	@isTest
	public static void testGetUserInfo() {
        Test.startTest();

		Map<String, String> uInf = brideas_IdeasCtrl.getUserInfo();

        Test.stopTest();

		System.assertEquals(true, String.isNotEmpty(uInf.get('Id')), 'Id property is empty');
		System.assertEquals(true, String.isNotEmpty(uInf.get('Name')), 'Name property is empty');
		System.assertEquals(true, String.isNotEmpty(uInf.get('Username')), 'Username property is empty');
		System.assertEquals(true, String.isNotEmpty(uInf.get('Email')), 'Email property is empty');
		System.assertEquals(true, String.isNotEmpty(uInf.get('Type')), 'Type property is empty');
	}

	@isTest
	public static void testGetEmptyListIdeas() {
        String communityName = '';
        Map<String, String> filterData = new Map<String, String>();
        Idea testIdea = [SELECT Id FROM Idea WHERE Title = 'Test idea_2' LIMIT 1];

        Test.startTest();

        List<brideas_IdeaWrapper> resultList = brideas_IdeasCtrl.getIdeas(communityName, filterData, 1, 10, '');

        Test.stopTest();

        System.assertEquals(true, resultList.size() > 0, 'No items retrieved');
    }

    @isTest
    public static void testGetIdeasWithPagination() {
        String communityName = '';
        Map<String, String> filterData = new Map<String, String>();

        Test.startTest();

        List<brideas_IdeaWrapper> resultListForFirstPage = brideas_IdeasCtrl.getIdeas(communityName, filterData, 1, 5, '');
        List<brideas_IdeaWrapper> resultListForSecondPage = brideas_IdeasCtrl.getIdeas(communityName, filterData, 2, 5, '');

        Test.stopTest();

        System.assertEquals(5, resultListForFirstPage.size(), 'Wrong number of first page items');
        System.assertEquals(3, resultListForSecondPage.size(), 'Wrong number of second page items');
    }

    @isTest
    public static void testGetIdeasOnFilterData() {
        String communityName = '';
        Map<String, String> filterData = new Map<String, String>();

        Test.startTest();

        filterData.put('status', 'New');
        List<brideas_IdeaWrapper> resultListForStatus = brideas_IdeasCtrl.getIdeas(communityName, filterData, 1, 10, '');

        filterData.put('category', 'test_1');
        List<brideas_IdeaWrapper> resultListForCategory = brideas_IdeasCtrl.getIdeas(communityName, filterData, 1, 10, '');

        filterData = new Map<String,String>();
        filterData.put('showBy', 'createdByMe');
        List<brideas_IdeaWrapper> resultListForCreatedByMe = brideas_IdeasCtrl.getIdeas(communityName, filterData, 1, 10, '');

        filterData = new Map<String,String>();
        filterData.put('showBy', 'commentedByMe');
        List<brideas_IdeaWrapper> resultListForCommentedByMe = brideas_IdeasCtrl.getIdeas(communityName, filterData, 1, 10, '');

        Test.stopTest();

        System.assertEquals(6, resultListForStatus.size(), 'Wrong number of items filtered by Status');
        System.assertEquals(1, resultListForCategory.size(), 'Wrong number of items filtered by Status and Category');
        System.assertEquals(4, resultListForCreatedByMe.size(), 'Wrong number of items filtered by CreatedByMe');
        System.assertEquals(1, resultListForCommentedByMe.size(), 'Wrong number of items filtered by CommentedByMe');
    }

    @isTest
    public static void testGetIdeasOnSearch() {
        String communityName = '';
        Map<String, String> filterData = new Map<String, String>();
        filterData.put('search', 'search');

        Test.startTest();

        List<brideas_IdeaWrapper> resultList = brideas_IdeasCtrl.getIdeas(communityName, filterData, 1, 10, '');

        Test.stopTest();

        System.assertEquals(0, resultList.size(), 'Failed on search test'); //SOSL queries return empty results within test invironment
    }

    @isTest
    public static void testGetIdeasByOrder() {
        String communityName = '';
        Map<String, String> filterData = new Map<String, String>();
        filterData = new Map<String,String>();

        Test.startTest();

        List<brideas_IdeaWrapper> defaultOrderByRes = brideas_IdeasCtrl.getIdeas(communityName, filterData, 1, 10, '');
        List<brideas_IdeaWrapper> trendingOrderByRes = brideas_IdeasCtrl.getIdeas(communityName, filterData, 1, 10, 'Trending');
        List<brideas_IdeaWrapper> popularOrderByRes = brideas_IdeasCtrl.getIdeas(communityName, filterData, 1, 10, 'Popular');

        Test.stopTest();

        //Order by is unpredictable within tests so just check if rows were retrieved
        System.assertEquals(true, defaultOrderByRes.size() > 0, 'Order by default failed');
        System.assertEquals(true, trendingOrderByRes.size() > 0, 'Order by Trending failed');
        System.assertEquals(true, popularOrderByRes.size() > 0, 'Order by Popular failed');
    }

	@isTest
	static void testGetIdeasCount() {
		String communityName = '';
		Map<String,String> filterData = new Map<String,String>();

        Test.startTest();

        Integer countWithoutFilter = brideas_IdeasCtrl.getIdeasCount(communityName, filterData);

        filterData.put('category', 'test_2');
        Integer countWithCategoryFilter = brideas_IdeasCtrl.getIdeasCount(communityName, filterData);

        filterData.put('status', 'Delivered');
        Integer countWithStatusFilter = brideas_IdeasCtrl.getIdeasCount(communityName, filterData);

        Test.stopTest();

		System.assertEquals(8, countWithoutFilter, 'Invalid count without filter');
		System.assertEquals(5, countWithCategoryFilter, 'Invalid count with category filter');
		System.assertEquals(1, countWithStatusFilter, 'Invalid count with category and status filter');
	}

	@isTest
	static void testCreateNewIdeaWIthError() {
		Map<String, String> fields = new Map<String, String>();
		fields.put('community', '');
		fields.put('title', 'Test idea_created');
		fields.put('body', 'Body of test idea_created');
		fields.put('status','New');
		fields.put('category', 'test_1');

		Test.startTest();

        try {
            brideas_IdeaWrapper newIdea = brideas_IdeasCtrl.createNewIdea(fields);
        }catch (Exception e) {
            System.assertEquals('Script-thrown exception', e.getMessage());
        }

        Test.stopTest();
	}

    @isTest
    static void testCreationNewIdeaBySuperUser() {
        Profile stdUserProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        User testUser = new User(Alias = 'testusr', Email='testsuperusr@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = stdUserProfile.Id,
        TimeZoneSidKey='America/Los_Angeles', UserName='testsuperusr@testorg.com', IdeasSuperUser__c = true);
        insert testUser;

        Map<String, String> fields = new Map<String, String>();
        fields.put('community', '');
        fields.put('title', 'Test idea_created');
        fields.put('body', 'Body of test idea_created');
        fields.put('status','New');
        fields.put('category', 'test_1');

        Test.startTest();

        System.runAs(testUser) {
            brideas_IdeaWrapper newIdea = brideas_IdeasCtrl.createNewIdea(fields);
            Idea testItem = [SELECT Title FROM Idea WHERE Id = :newIdea.item.Id];
            System.assertEquals('Test idea_created', testItem.Title);
        }

        Test.stopTest();
    }

	@isTest
	static void testGetFilterOptions() {
		Map<String, String> options = new Map<String, String>();
        options.put('categoriesSource', 'Custom Settings');
        options.put('zone', 'TestPublic');

        Test.startTest();

        Map<String, List<Map<String, String>>> data = brideas_IdeasCtrl.getFilterOptions(options);

        Test.stopTest();

        System.assertEquals(true, data.containsKey('category'));
        System.assertEquals(true, data.containsKey('status'));
	}

	@isTest
	static void testGetIdeaVotes() {
		Idea testIdea = [SELECT Id FROM Idea WHERE Title = 'Test idea_1' LIMIT 1];

        Test.startTest();

		List<Vote> vts = brideas_IdeasCtrl.getIdeaVotes(testIdea.Id);

        Test.stopTest();

		System.assertEquals(2, vts.size());
	}

	@isTest
	static void testGetIdeaVotesCount() {
		Idea testIdea = [SELECT Id FROM Idea WHERE Title = 'Test idea_1' LIMIT 1];

        Test.startTest();

		Integer vcount = brideas_IdeasCtrl.getIdeaVotesCount(testIdea.Id);

        Test.stopTest();

		System.assertEquals(2, vcount);
	}

	@isTest
	static void testAddVote() {
		Idea testIdea_1 = [SELECT Id FROM Idea WHERE Title = 'Test idea_2' LIMIT 1];
		Idea testIdea_2 = [SELECT Id FROM Idea WHERE Title = 'Test idea_3' LIMIT 1];
		User testUser = [SELECT Id FROM User WHERE UserName = 'testusr@testorg.com'];

        Test.startTest();

		System.runAs(testUser) {
			String result = brideas_IdeasCtrl.addVote(testIdea_1.Id);

			System.assertEquals('2', result);
		}

        String res = brideas_IdeasCtrl.addVote(testIdea_2.Id);

        Test.stopTest();

		System.assertEquals('error', res);

	}

	@isTest
	static void testAddVoteAndChangeStatus() {
        Idea testIdea_1 = [SELECT Status FROM Idea WHERE Title = 'Test idea_2' LIMIT 1];
		testIdea_1.Status = 'New';
        User testUser = [SELECT Id FROM User WHERE UserName = 'testusr@testorg.com'];

        Test.startTest();

		update  testIdea_1;

		System.assertNotEquals(null, testIdea_1);
		System.assertEquals('New', testIdea_1.Status);

		System.runAs(testUser) {
            String res = brideas_IdeasCtrl.addVote(testIdea_1.Id);

			System.assertEquals('2', res);

            String status = brideas_IdeasCtrl.getStatus(testIdea_1.Id);

			System.assertEquals('Under Consideration', status);
		}

        Test.stopTest();
	}

	@isTest
	static void testGetIdeaComments() {
		Idea testIdea = [SELECT Id FROM Idea WHERE Title = 'Test idea_1' LIMIT 1];

        Test.startTest();

		List<brideas_IdeaCommentWrapper> comments = brideas_IdeasCtrl.getIdeaComments(testIdea.Id, '5', 'desc', null);

        Test.stopTest();

        System.assertEquals(2, comments.size());
	}

	@isTest
	static void testGetIdeaCommentsNumber() {
		Idea testIdea = [SELECT Id FROM Idea WHERE Title = 'Test idea_1' LIMIT 1];

        Test.startTest();

		Integer commentsNum = brideas_IdeasCtrl.getIdeaCommentsNumber(testIdea.Id);

        Test.stopTest();

		System.assertEquals(2, commentsNum);
	}

	@isTest
	static void testSaveComment() {
		Idea testIdea = [SELECT Id FROM Idea WHERE Title = 'Test idea_1' LIMIT 1];

        Test.startTest();

		brideas_IdeaCommentWrapper testComment = brideas_IdeasCtrl.saveComment(testIdea.Id, 'Test comment');

        Test.stopTest();

		System.assertEquals('Test comment', testComment.ideaComment.CommentBody);
	}

	@isTest
	static void testSaveCommentAndSendEmail() {
		Idea testIdea = [SELECT Id FROM Idea WHERE Title = 'Test idea_5' LIMIT 1];

        Test.startTest();

		brideas_IdeaCommentWrapper testComment = brideas_IdeasCtrl.saveComment(testIdea.Id, 'Test comment');

        Test.stopTest();

		System.assertEquals('Test comment', testComment.ideaComment.CommentBody);
	}

	@isTest
	static void testGetSimilarIdeas() {
        Test.startTest();

		List<Idea> similar = brideas_IdeasCtrl.getSimilarIdeas('', 'Test idea_1');

        Test.stopTest();

		System.assertEquals(1, similar.size());
	}

	@isTest
	static void testGetStatusColors() {
        Test.startTest();

		Map<String,String> statusColors = brideas_IdeasCtrl.getStatusColors();

        Test.stopTest();

		System.assertNotEquals(null, statusColors);
	}

    @isTest
    static void testUnsubscribe() {
        String ideaId = [SELECT Id FROM Idea WHERE Title = 'Test idea_5' LIMIT 1].Id;

        brideas_Subscription__c subscr = new brideas_Subscription__c(Idea__c = ideaId, User__c = UserInfo.getUserId());

        insert subscr;

        Test.startTest();

        Boolean isUnsubscribe = brideas_IdeasCtrl.unsubscribe(ideaId);

        Test.stopTest();

        System.assertEquals(true, isUnsubscribe, 'should be true value');
    }

    @isTest
    static void testUnsubscribeAll() {
        Test.startTest();

        Boolean isUnsubscribeAll = brideas_IdeasCtrl.unsubscribeAll();

        Test.stopTest();

        System.assertEquals(true, isUnsubscribeAll, 'should be true value');
    }

    @isTest
    private static void testGetBrideasFlags(){
        List<brideas_Flag__c> flags = new List<brideas_Flag__c>();

        for (Integer i = 0; i < 3; i++) {
            flags.add(new brideas_Flag__c(userId__c = UserInfo.getUserId()));
        }

        insert flags;

        Test.startTest();

        List<brideas_Flag__c> brideasFlags = brideas_IdeasCtrl.getBrideasFlags();

        Test.stopTest();

        System.assertEquals(3, brideasFlags.size() , 'result contains three flags');
    }

    @isTest
    private static void testSetFlagOnIdeaComments(){
        Test.startTest();

        String cId = brideas_Helper.getCommunityId('');

        Idea testIdea = new Idea(Title = 'Test idea', Body = 'Body of test idea', Status = 'New',
                Categories = 'test', CommunityId = cId);

        insert testIdea;

        IdeaComment testComment = new IdeaComment(CommentBody = 'test comment', IdeaId = testIdea.Id);

        insert testComment;

        Boolean isSetFlagOnIdeaComment = brideas_IdeasCtrl.setFlagOnIdeaComment(testComment.Id);

        Test.stopTest();

        System.assertEquals(true, isSetFlagOnIdeaComment , 'result contains three flags');
    }

    @isTest
    private static void testGetMergedIdeas(){
        String parentIdeaId = [SELECT ParentIdeaId FROM Idea LIMIT 1].ParentIdeaId;

        Test.startTest();

        List<Idea> ideas = brideas_IdeasCtrl.getMergedIdeas(parentIdeaId);

        Test.stopTest();

        System.assertEquals(8, ideas.size() , 'result contain eight ideas');
    }

    @isTest
    private static void testGetCategoryOptions(){
        List<brideas_Categories__c> categories = new List<brideas_Categories__c>();

        for (Integer i = 0; i < 3; i++) {
            categories.add(new brideas_Categories__c(Name = 'category' + i, Label__c = 'Test' + i,
                    Parent__c = 'Test parent' + i, Zone__c = 'Test zone ' + i));
        }

        insert categories;

        Test.startTest();

        List<Map<String, String>> options  = brideas_IdeasCtrl.getCategoryOptions('Custom settings', 'Test zone 1');

        Test.stopTest();

        System.assertEquals('Test1', options[0].get('label'), 'result contains category label');
        System.assertEquals('category1', options[0].get('value'), 'result contains category value');
    }

    @isTest
    private static void testSetFlagOnIdea(){
        String ideaId = [SELECT Id FROM Idea LIMIT 1].Id;

        Test.startTest();

        Boolean isSetFlag = brideas_IdeasCtrl.setFlagOnIdea(ideaId);

        Test.stopTest();

        System.assertEquals(true, isSetFlag , 'result contain true value');
    }

    @isTest
    private static void testGetFeaturedCategory(){
        Test.startTest();

        String featuredCategory = brideas_IdeasCtrl.getFeaturedCategory();

        Test.stopTest();

        System.assertEquals('FeaturedCategory', featuredCategory , 'result contains featured category');
    }
}