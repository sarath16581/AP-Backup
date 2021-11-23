@isTest
public class SideBarSocialPostsCtr_Test {


    static Account a;
    static SocialPersona persona;
    static SocialPost post;
    static Case c,c2;

    public static SelectOption test_SelectOption;
    public static string listViewFullName;
    public static MetadataService.ListView test_listView;


    static MetadataService.ListViewFilter createListViewFilter(String field, String operation, String value){
        //dummy filters
        MetadataService.ListViewFilter lvF = new MetadataService.ListViewFilter();
        lvF.field=field;
        lvF.operation=operation;
        lvF.value=value;
        return lvF;
    }

    static void populateListViews(MetadataService.ListViewFilter lvf){
        test_SelectOption = new SelectOption('Test View Label','Test View FullName');
        listViewFullName = 'Test View FullName';

        //dummy list view
        test_listView = new MetadataService.ListView();
        test_listView.fullName = 'Test View FullName';
        test_listView.booleanFilter=null;
        test_listView.columns = new String[]{'Name', 'Persona', 'Content', 'Headline', 'Posted', 'R6PostId', 'Parent'};
        test_listView.division= null;
        test_listView.filterScope ='Everything';

        if (lvf == null){
            lvf = createListViewFilter('Persona','equals','testPersona');
        }

        test_listView.filters= new MetadataService.ListViewFilter[]{lvf};
        test_listView.label ='Test View Label';
        test_listView.language=null;
        test_listView.queue=null;
        test_listView.sharedTo =null;

    }

    static void populateEnvironment(){

        a = new Account(Name='Test Account');
        insert a;

        c = new Case();
        insert c;

        c2 = new Case();
        insert c2;

        persona = new SocialPersona(Name='testPersona');
        persona.ParentId = a.Id;
        persona.Provider = 'Twitter';
        insert persona;

        post = new SocialPost(Name='testPost');
        post.PersonaId = persona.Id;
        post.ParentId = c.Id;
        post.TopicProfileName = '@testPersona';
        insert post;

        MetadataService.ListViewFilter lv = createListViewFilter('Persona','equals','testPersona');
        populateListViews(lv);
    }

    static testMethod void testCtr(){
        populateEnvironment();

        System.Test.startTest();

            List<SocialPost> sps = new List<SocialPost>();
            sps.add( [ Select Id From SocialPost ] );

            SideBarSocialPostsCtr controller = new SideBarSocialPostsCtr(new ApexPages.StandardSetController( sps ));
            List<SocialPost> l = controller.getSocialPosts();

            //metadata coverage
            controller.dateTimeValuetoString('01/01/2014', '', 'equals', 'posted');
            controller.isPicklist('0','Status');

        System.Test.stopTest();

    }

    static testMethod void testPicklist(){
        populateEnvironment();

        List<SocialPost> sps = new List<SocialPost>();
        sps.add( [ Select Id From SocialPost ] );

        SideBarSocialPostsCtr controller = new SideBarSocialPostsCtr(new ApexPages.StandardSetController( sps ));
        List<SocialPost> l = controller.getSocialPosts();

        //metadata coverage
        controller.dateTimeValuetoString('01/01/2014 ', '', 'equals', 'posted');
        controller.isPicklist('0','Provider');

        controller.dateTimeValuetoString('01/01/2014 ', '', '', 'posted');
    }


    static testMethod void testCreateCases() {
        populateEnvironment();
        System.Test.startTest();

            SideBarSocialPostsCtr controller = new SideBarSocialPostsCtr();
            ApexPages.currentPage().getParameters().put('selectedPosts', post.Id);
            system.assertEquals(controller.createCases(),null);

        System.Test.stopTest();
    }

    static testMethod void testIgnorePosts(){
        populateEnvironment();

        System.Test.startTest();

            SideBarSocialPostsCtr controller = new SideBarSocialPostsCtr();
            ApexPages.currentPage().getParameters().put('selectedPosts', post.Id);
            system.assertEquals(controller.ignorePosts(),null);

        System.Test.stopTest();
    }


    static testMethod void testPageMethods(){
        populateEnvironment();

        System.Test.startTest();

            List<SocialPost> sps = new List<SocialPost>();
            sps.add( [ Select Id From SocialPost ] );

            SideBarSocialPostsCtr controller = new SideBarSocialPostsCtr(new ApexPages.StandardSetController( sps ));

            controller.first();
            controller.last();
            controller.next();
            controller.prev();
            controller.previous();

            system.assertEquals(controller.resetFilter(), null);
            Integer  OrigNum = controller.pageNumber;
            system.assertEquals(controller.refresh(), null);
            system.assertEquals(OrigNum, controller.pageNumber);

            system.assertEquals(controller.reload(), null);
            system.assertEquals(1, controller.pageNumber);

        System.Test.stopTest();

    }

    static testMethod void testremoveCaseParent(){
        populateEnvironment();

        System.Test.startTest();

        SideBarSocialPostsCtr controller = new SideBarSocialPostsCtr();
        ApexPages.currentPage().getParameters().put('selectedPosts', post.Id);
        system.assertEquals(controller.createCases(),null);

        list<SocialPost> ls = [select id, ParentId from SocialPost where id=:post.Id];

        system.assert(ls[0].ParentId != null);

        ApexPages.currentPage().getParameters().put('selectedPosts', post.Id);
        system.assertEquals(controller.removeCaseParent(),null);

        ls = [select id, ParentId from SocialPost where id=:post.Id];

        system.assertEquals(ls[0].ParentId , null);

        System.Test.stopTest();
     }


    static testMethod void testupdateCaseAssignment(){
        populateEnvironment();

        System.Test.startTest();

        SideBarSocialPostsCtr controller = new SideBarSocialPostsCtr();
        ApexPages.currentPage().getParameters().put('selectedPosts', post.Id);
        ApexPages.currentPage().getParameters().put('caseId', c.Id);
        system.assertEquals(controller.createCases(),null);

        list<SocialPost> ls = [select id, ParentId from SocialPost where id=:post.Id];

        system.assert(ls[0].ParentId != null);

        ApexPages.currentPage().getParameters().put('caseId', c2.Id);
        ApexPages.currentPage().getParameters().put('selectedPosts', post.Id);
        system.assertEquals(controller.updateCaseAssignment(),null);

        ls = [select id, ParentId from SocialPost where id=:post.Id];

        system.assertEquals(ls[0].ParentId , c2.Id);

        System.Test.stopTest();

    }

    static testMethod void testCreateService() {
        SideBarSocialPostsCtr controller = new SideBarSocialPostsCtr();
        MetadataService.MetadataPort service = controller.createService();

        System.assertNotEquals(service, null);
    }

    static testMethod void testGetListViewOptions(){
        SideBarSocialPostsCtr controller = new SideBarSocialPostsCtr();
        MetadataService.ListViewFilter lv = createListViewFilter('TopicProfileName', 'equals', '@testPersona');
        populateListViews(lv);

        controller.buildListViewOptionsList();
        List<SelectOption> listViewOptions = controller.getListViewOptions();

        System.assertNotEquals(listViewOptions, null);
    }

    static testMethod void testCreateCasesPersonaIdNull() {
        populateEnvironment();
        MetadataService.ListViewFilter lv = createListViewFilter('TopicProfileName', 'equals', '@testPersona');
        populateListViews(lv);

        SideBarSocialPostsCtr controller = new SideBarSocialPostsCtr();
        ApexPages.currentPage().getParameters().put('selectedPosts', post.Id);

        post = [select Id, PersonaId, ParentId, Name, TopicProfileName, ReviewedStatus from SocialPost limit 1];
        post.PersonaId = null;
        post.ParentId = null;
        post.TopicProfileName = '@testPersona';
        post.ReviewedStatus = 'Ignore';
        update post;

        controller.createCases();

        post = [select Id, PersonaId, ParentId, Name, TopicProfileName, ReviewedStatus from SocialPost limit 1];

        System.assertEquals( 'Escalate', post.ReviewedStatus);
    }

     static testMethod void testCreateCasesErrorMessages() {
        populateEnvironment();
        MetadataService.ListViewFilter lv = createListViewFilter('TopicProfileName', 'equals', '@testPersona');
        populateListViews(lv);

        post = [select Id, PersonaId, ParentId, Name, TopicProfileName, ReviewedStatus from SocialPost limit 1];
        post.PersonaId = null;
        post.ParentId = null;
        update post;

        SideBarSocialPostsCtr controller = new SideBarSocialPostsCtr();
        ApexPages.currentPage().getParameters().put('selectedPosts', post.Id);

        controller.createCases();

        for(ApexPages.Message msg :  ApexPages.getMessages()) {
            System.assertEquals('Social Person could not be found, please try later.', msg.getSummary());
            System.assertEquals(ApexPages.Severity.ERROR, msg.getSeverity());
        }
    }

    static testMethod void testQueryFilter() {
        populateEnvironment();
        SideBarSocialPostsCtr controller = new SideBarSocialPostsCtr();

        MetadataService.ListViewFilter lv = createListViewFilter('TopicProfileName', 'notEqual', '@testPersona');
        populateListViews(lv);

        list<SocialPost> posts = controller.getSocialPosts();

        System.assertEquals(posts.size(), 0);
    }

    static testMethod void testQueryFilterStartsWith() {
        populateEnvironment();
        SideBarSocialPostsCtr controller = new SideBarSocialPostsCtr();

        MetadataService.ListViewFilter lv = createListViewFilter('TopicProfileName', 'startsWith', '@testPersona');
        populateListViews(lv);

        list<SocialPost> posts = controller.getSocialPosts();

        System.assertEquals(posts.size(), 1);
    }

    static testMethod void testQueryFilterContains() {
        populateEnvironment();
        SideBarSocialPostsCtr controller = new SideBarSocialPostsCtr();

        MetadataService.ListViewFilter lv = createListViewFilter('TopicProfileName', 'contains', '@testPersona');
        populateListViews(lv);

        list<SocialPost> posts = controller.getSocialPosts();

        System.assertEquals(posts.size(), 1);
    }

    static testMethod void testQueryFilterNotContain() {
        populateEnvironment();
        SideBarSocialPostsCtr controller = new SideBarSocialPostsCtr();

        MetadataService.ListViewFilter lv = createListViewFilter('TopicProfileName', 'notContain', '@testPersona');
        populateListViews(lv);

        list<SocialPost> posts = controller.getSocialPosts();

        System.assertEquals(posts.size(), 0);
    }

    static testMethod void testQueryFilterLessThan() {
        populateEnvironment();
        SideBarSocialPostsCtr controller = new SideBarSocialPostsCtr();

        MetadataService.ListViewFilter lv = createListViewFilter('TopicProfileName', 'lessThan', '@testPersona');
        populateListViews(lv);

        list<SocialPost> posts = controller.getSocialPosts();

        System.assertEquals(posts.size(), 0);
    }

    static testMethod void testQueryFilterGreaterThan() {
        populateEnvironment();
        SideBarSocialPostsCtr controller = new SideBarSocialPostsCtr();

        MetadataService.ListViewFilter lv = createListViewFilter('TopicProfileName', 'greaterThan', '@testPersona');
        populateListViews(lv);

        list<SocialPost> posts = controller.getSocialPosts();

        System.assertEquals(posts.size(), 0);
    }

    static testMethod void testQueryFilterLessOrEqual() {
        populateEnvironment();
        SideBarSocialPostsCtr controller = new SideBarSocialPostsCtr();

        MetadataService.ListViewFilter lv = createListViewFilter('TopicProfileName', 'lessOrEqual', '@testPersona');
        populateListViews(lv);

        list<SocialPost> posts = controller.getSocialPosts();

        System.assertEquals(posts.size(), 1);
    }

    static testMethod void testQueryFilterGreaterOrEqual() {
        populateEnvironment();
        SideBarSocialPostsCtr controller = new SideBarSocialPostsCtr();

        MetadataService.ListViewFilter lv = createListViewFilter('TopicProfileName', 'greaterOrEqual', '@testPersona');
        populateListViews(lv);

        list<SocialPost> posts = controller.getSocialPosts();

        System.assertEquals(posts.size(), 1);
    }

    static testMethod void testQueryFilterExcludes() {
        populateEnvironment();
        SideBarSocialPostsCtr controller = new SideBarSocialPostsCtr();

        MetadataService.ListViewFilter lv = createListViewFilter('TopicProfileName', 'excludes', '@testPersona');
        populateListViews(lv);

        list<SocialPost> posts = controller.getSocialPosts();

        System.assertEquals(posts.size(), 0);
    }

    static testMethod void testQueryFilterIncludes() {
        populateEnvironment();
        SideBarSocialPostsCtr controller = new SideBarSocialPostsCtr();

        MetadataService.ListViewFilter lv = createListViewFilter('TopicProfileName', 'includes', '@testPersona');
        populateListViews(lv);

        list<SocialPost> posts = controller.getSocialPosts();

        System.assertEquals(posts.size(), 1);
    }
}