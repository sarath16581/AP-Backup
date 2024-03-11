/**
	MIT License

	Copyright (c) 2018 Alex

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
*/

@IsTest
private with sharing class QueryBuilder_Test {

	@IsTest
	private static void ensureAggregateFieldsAreAddedToTheQuery() {
		QueryBuilder qb = new QueryBuilder(Contact.SObjectType);
		qb.addAggregate(Contact.Lead_Score__c, QueryBuilder.AggregateFunction.AVG);
		qb.addAggregate(Contact.Lead_Score__c, QueryBuilder.AggregateFunction.COUNT);
		qb.addAggregate(Contact.Lead_Score__c, QueryBuilder.AggregateFunction.MAX);
		qb.addAggregate(Contact.Lead_Score__c, QueryBuilder.AggregateFunction.MIN);
		qb.addAggregate(Contact.Lead_Score__c, QueryBuilder.AggregateFunction.SUM);
		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('\\bAVG\\(Lead_Score__c\\) AVG_Lead_Score__c\\b').matcher(soql).find(), 'Resulting query should contain field and alias');
		System.assertEquals(true, Pattern.compile('\\bCOUNT\\(Lead_Score__c\\) COUNT_Lead_Score__c\\b').matcher(soql).find(), 'Resulting query should contain field and alias');
		System.assertEquals(true, Pattern.compile('\\bMAX\\(Lead_Score__c\\) MAX_Lead_Score__c\\b').matcher(soql).find(), 'Resulting query should contain field and alias');
		System.assertEquals(true, Pattern.compile('\\bMIN\\(Lead_Score__c\\) MIN_Lead_Score__c\\b').matcher(soql).find(), 'Resulting query should contain field and alias');
		System.assertEquals(true, Pattern.compile('\\bSUM\\(Lead_Score__c\\) SUM_Lead_Score__c\\b').matcher(soql).find(), 'Resulting query should contain field and alias');
	}

	@IsTest
	private static void testEnsureAllFieldsMethodsAddToTheQuery() {
		QueryBuilder qb = new QueryBuilder(Account.SObjectType);
		qb.addField('Name');
		qb.addField(Account.NumberOfEmployees);
		qb.addFields(new List<SObjectField>{Account.Industry});
		qb.addFields(new Set<SObjectField>{Account.Phone});
		qb.addFields(new List<String>{'AnnualRevenue'});
		qb.addFields(new Set<String>{'AccountSource'});

		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b').matcher(soql).find(), 'Resulting query does not select from Account');
		System.assertEquals(true, Pattern.compile('(?ism)\\bName\\b.*?from account\\b').matcher(soql).find(), 'Resulting query does not select Name field');
		System.assertEquals(true, Pattern.compile('(?ism)\\bNumberOfEmployees\\b.*?from account\\b').matcher(soql).find(), 'Resulting query does not select NumberOfEmployees field');
		System.assertEquals(true, Pattern.compile('(?ism)\\bIndustry\\b.*?from account\\b').matcher(soql).find(), 'Resulting query does not select Industry field');
		System.assertEquals(true, Pattern.compile('(?ism)\\bPhone\\b.*?from account\\b').matcher(soql).find(), 'Resulting query does not select Phone field');
		System.assertEquals(true, Pattern.compile('(?ism)\\bAnnualRevenue\\b.*?from account\\b').matcher(soql).find(), 'Resulting query does not select AnnualRevenue field');
		System.assertEquals(true, Pattern.compile('(?ism)\\bAccountSource\\b.*?from account\\b').matcher(soql).find(), 'Resulting query does not select AccountSource field');

		// ensure the generated query does not throw an error
		System.assertEquals(true, Database.query(soql).isEmpty());
	}

	@IsTest
	private static void testEnsureThatLimitAndOffsetProducesCorrectQueryOutput() {
		QueryBuilder qb = new QueryBuilder(Account.SObjectType);
		qb.addField('Name');
		qb.setLimit(20);
		qb.setOffset(5);
		String soql = qb.toSoqlString();

		// verify query structure
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b.*?LIMIT\\s+20\\s+OFFSET\\s+5\\s*$').matcher(soql).find(), 'Resulting query does not set LIMIT and OFFSET correctly');
		System.assertEquals(true, Database.query(soql).isEmpty());

		qb = new QueryBuilder(Account.SObjectType);
		qb.addField('Name');
		qb.setLimit(20);
		soql = qb.toSoqlString();

		// verify query structure
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b.*?LIMIT\\s+20\\s*$').matcher(soql).find(), 'Resulting query does not set LIMIT correctly');
		System.assertEquals(true, Database.query(soql).isEmpty());

		qb = new QueryBuilder(Account.SObjectType);
		qb.addField('Name');
		qb.setOffset(5);
		soql = qb.toSoqlString();

		// verify query structure
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b.*?OFFSET\\s+5\\s*$').matcher(soql).find(), 'Resulting query does not set OFFSET correctly');
		System.assertEquals(true, Database.query(soql).isEmpty());

	}

	@IsTest
	private static void testEnsureThatOrderByProducesCorrectQueryOutput() {
		QueryBuilder qb = new QueryBuilder(Account.SObjectType);
		qb.addField('Name');
		qb.addOrder(new QueryBuilder.Order('Id', 'Desc'));
		String soql = qb.toSoqlString();

		// verify query structure
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b.*?Order\\s+By\\s+Id\\s+Desc\\s*$').matcher(soql).find(), 'Resulting query does not set Order By correctly: ' + soql);
		System.assertEquals(true, Database.query(soql).isEmpty());

		qb = new QueryBuilder(Account.SObjectType);
		qb.addField('Name');
		qb.addOrder(new QueryBuilder.Order('Id'));
		qb.addOrder(new QueryBuilder.Order(Account.Name));
		qb.addOrder((new QueryBuilder.Order(Account.Industry)).setSortingOrderAsc());
		qb.addOrder((new QueryBuilder.Order(Account.CreatedDate)).setSortingOrderDesc());
		soql = qb.toSoqlString();

		// verify query structure
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b.*?Order\\s+By\\s+Id\\s+Asc\\s*,\\s*Name\\s+Asc\\s*,\\s*Industry\\s+Asc\\s*,\\s*CreatedDate\\s+Desc\\s*$').matcher(soql).find(), 'Resulting query does not set Order By correctly: ' + soql);
		System.assertEquals(true, Database.query(soql).isEmpty());

		// verify that multiple order by clauses work
		qb = new QueryBuilder(Account.SObjectType);
		qb.addField('Name');
		qb.addOrder(new QueryBuilder.Order('Id', 'Desc'));
		qb.addOrder(new QueryBuilder.Order('Name', 'Asc'));
		soql = qb.toSoqlString();

		// verify query structure
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b.*?Order\\s+By\\s+Id\\s+Desc\\s*,\\s*Name\\s+Asc\\s*$').matcher(soql).find(), 'Resulting query does not set Order By correctly: ' + soql);
		System.assertEquals(true, Database.query(soql).isEmpty());

		// verify that multiple ASC order by clauses work
		qb = new QueryBuilder(Account.SObjectType);
		qb.addField('Name');
		qb.addOrderAsc('Id');
		qb.addOrderAsc(Account.Name);
		soql = qb.toSoqlString();

		// verify query structure
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b.*?Order\\s+By\\s+Id\\s+Asc\\s*,\\s*Name\\s+Asc\\s*$').matcher(soql).find(), 'Resulting query does not set Order By correctly: ' + soql);
		System.assertEquals(true, Database.query(soql).isEmpty());

		// verify that multiple DESC order by clauses work
		qb = new QueryBuilder(Account.SObjectType);
		qb.addField('Name');
		qb.addOrderDesc('Id');
		qb.addOrderDesc(Account.Name);
		soql = qb.toSoqlString();

		// verify query structure
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b.*?Order\\s+By\\s+Id\\s+Desc\\s*,\\s*Name\\s+Desc\\s*$').matcher(soql).find(), 'Resulting query does not set Order By correctly: ' + soql);
		System.assertEquals(true, Database.query(soql).isEmpty());

		qb = new QueryBuilder(Account.SObjectType);
		qb.addField('Name');
		qb.addOrderDesc('ParentId');
		qb.setOrder(new QueryBuilder.Order('Industry', 'Asc'));
		soql = qb.toSoqlString();

		// verify query structure
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b.*?Order\\s+By\\s+Industry\\s+Asc\\s*$').matcher(soql).find(), 'Resulting query does not set Order By correctly: ' + soql);
		System.assertEquals(false, Pattern.compile('(?ism)\\bParentId\\b').matcher(soql).find(), 'Resulting query does not set Order By correctly: ' + soql);
		System.assertEquals(true, Database.query(soql).isEmpty());

		QueryBuilder.Order orderByVar = new QueryBuilder.Order('Industry', 'Asc');
		System.assertEquals('Industry', orderByVar.getSortingField());
		System.assertEquals('Asc', orderByVar.getSortingOrder());

	}

	@IsTest
	private static void testEnsureThatGroupByProducesCorrectQueryOutput() {
		QueryBuilder qb = new QueryBuilder(Account.SObjectType);
		qb.addField('Name');
		qb.addGroupBy('Name');
		String soql = qb.toSoqlString();

		// verify query structure
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b.*?Group\\s+By\\s+Name\\s*$').matcher(soql).find(), 'Resulting query does not set Group By correctly: ' + soql);
		System.assertEquals(true, Database.query(soql).isEmpty());

		// verify that multiple order by clauses work
		qb = new QueryBuilder(Account.SObjectType);
		qb.addField('Name');
		qb.addField('Industry');
		qb.addGroupBy('Name');
		qb.addGroupBy(Account.Industry);
		soql = qb.toSoqlString();

		// verify query structure
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b.*?Group\\s+By\\s+Name\\s*,\\s*Industry\\s*$').matcher(soql).find(), 'Resulting query does not set Group By correctly: ' + soql);
		System.assertEquals(true, Database.query(soql).isEmpty());

	}

	@IsTest
	private static void testEnsureThatSelectCountProducesCorrectQueryOutput() {
		QueryBuilder qb = new QueryBuilder(Account.SObjectType);
		qb.addConditions().add(new QueryBuilder.CompareCondition('Name').eq('Nathan')).endConditions();
		String soql = qb.toCountString();

		// verify query structure
		System.assertEquals(true, Pattern.compile('(?ism)\\bSelect\\s+COUNT\\s*\\(\\s*\\)\\s+\\bfrom account\\b.*?Where.*$').matcher(soql).find(), 'Resulting query does not select COUNT correctly: ' + soql);
		System.assertEquals(0, Database.countQuery(soql));

	}

	@IsTest
	private static void testEnsureRelatedParentFieldsCanBeAddedToQuery() {
		QueryBuilder parentQb = new QueryBuilder(Account.SObjectType);
		parentQb.addFields(new List<SObjectField>{Account.Name});

		QueryBuilder qb = new QueryBuilder(Contact.SObjectType);
		qb.addFields(new List<SObjectField>{Contact.FirstName, Contact.LastName, Contact.AccountId});
		qb.addRelatedFields(parentQb, 'Account');

		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom contact\\b').matcher(soql).find(), 'Resulting query does not select from Contact');
		System.assertEquals(true, Pattern.compile('(?ism)\\bAccount\\.Name\\b.*?from contact').matcher(soql).find(), 'Resulting query does not select Account.Name field');

		// ensure the generated query does not throw an error
		List<Contact> records = Database.query(soql);
		System.assertEquals(true, records.isEmpty());
	}

	@IsTest
	private static void testEnsureSubQueryCanBeAddedToQuery() {
		QueryBuilder childrenQb = new QueryBuilder('Contacts'); // note the extra 's' on the end
		childrenQb.addFields(new List<SObjectField>{Contact.FirstName, Contact.LastName});

		QueryBuilder qb = new QueryBuilder(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Name});
		qb.addSubQuery(childrenQb);

		String soql = qb.toSoqlString();
		System.assertEquals(true, Pattern.compile('(?ism)\\bFrom Contacts\\b').matcher(soql).find(), 'Resulting query does not select from Contacts');
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b').matcher(soql).find(), 'Resulting query does not select from Account');
		System.assertEquals(true, Pattern.compile('(?ism)\\bName\\b').matcher(soql).find(), 'Resulting query does not select Name field');
		System.assertEquals(true, qb.hasSubQueries());

		// ensure the generated query does not throw an error
		List<Account> records = Database.query(soql);
		System.assertEquals(true, records.isEmpty());
	}

	@IsTest
	private static void testEnsureAllConstructorsLinkTheCorrectSObject() {
		QueryBuilder qb;

		qb = QueryBuilder.newInstance().addFrom(Account.SObjectType);
		System.assertEquals('Account', qb.fromSobject);

		qb = new QueryBuilder(Account.SObjectType);
		System.assertEquals('Account', qb.fromSobject);

		qb = new QueryBuilder('Account');
		System.assertEquals('Account', qb.fromSobject);

		qb = QueryBuilder.newInstance(AccountsSelector.class).addFrom('Account');
		System.assertEquals('Account', qb.fromSobject);

	}

	@IsTest
	private static void testEnsureThatCorrectCompareConditionLogicHasBeenAppliedToQueryBuilderIntegration() {
		MockUtility.disableTriggerExecution();

		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, false);
		insert accounts;

		List<Contact> contacts = ApplicationTestDataFactory.getContacts(2, accounts[0].Id, false);
		insert contacts;

		// eq string
		QueryBuilder qb = new QueryBuilder(Contact.SObjectType);
		qb.addFields(new List<SObjectField>{Contact.Id});
		String soql = qb.addConditions().add(new QueryBuilder.CompareCondition(Contact.FirstName).eq('First Name 1')).endConditions().toSoqlString();
		List<SObject> records = Database.query(soql);
		System.assertEquals(1, records.size());

		qb = new QueryBuilder(Contact.SObjectType);
		qb.addFields(new List<SObjectField>{Contact.Id});
		soql = qb.addConditions().add(new QueryBuilder.CompareCondition('FirstName').eq('First Name 1')).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(1, records.size());

		// not equal string
		qb = qb.newQuery().addFrom(Contact.SObjectType);
		qb.addFields(new List<SObjectField>{Contact.Id});
		soql = qb.addConditions().add(new QueryBuilder.CompareCondition(Contact.FirstName).ne('First Name 1')).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(1, records.size());

		// equals boolean
		qb = qb.newQuery().addFrom(Contact.SObjectType);
		qb.addFields(new List<SObjectField>{Contact.Id});
		soql = qb.addConditions().add(new QueryBuilder.CompareCondition(Contact.DoNotCall).eq(true)).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(2, records.size());

		// not equal boolean
		qb = qb.newQuery().addFrom(Contact.SObjectType);
		qb.addFields(new List<SObjectField>{Contact.Id});
		soql = qb.addConditions().add(new QueryBuilder.CompareCondition(Contact.DoNotCall).ne(true)).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(0, records.size());

		// eq decimal
		qb = qb.newQuery().addFrom(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new QueryBuilder.CompareCondition(Account.AnnualRevenue).eq(1000000)).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(1, records.size());

		// not eq decimal
		qb = qb.newQuery().addFrom(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new QueryBuilder.CompareCondition(Account.AnnualRevenue).ne(1000000)).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(0, records.size());

		// less than decimal
		qb = qb.newQuery().addFrom(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new QueryBuilder.CompareCondition(Account.AnnualRevenue).lt(1000000)).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(0, records.size());

		// less than equals decimal
		qb = qb.newQuery().addFrom(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new QueryBuilder.CompareCondition(Account.AnnualRevenue).lte(1000000)).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(1, records.size());

		// greater than decimal
		qb = qb.newQuery().addFrom(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new QueryBuilder.CompareCondition(Account.AnnualRevenue).gt(999999)).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(1, records.size());

		// greater than decimal
		qb = qb.newQuery().addFrom(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new QueryBuilder.CompareCondition(Account.AnnualRevenue).gte(1000000)).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(1, records.size());

		// not equal decimal
		qb = qb.newQuery().addFrom(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new QueryBuilder.CompareCondition(Account.AnnualRevenue).ne(1000000)).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(0, records.size());

	}

	@IsTest
	private static void testEnsureThatCorrectNullConditionLogicHasBeenAppliedToQueryBuilderIntegration() {
		MockUtility.disableTriggerExecution();

		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, false);
		accounts[0].Industry = null;
		insert accounts;

		// is null
		QueryBuilder qb = new QueryBuilder(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		String soql = qb.addConditions().add(new QueryBuilder.NullCondition(Account.Industry).isNull()).endConditions().toSoqlString();
		List<SObject> records = Database.query(soql);
		System.assertEquals(1, records.size());
		System.assertEquals(accounts[0].Id, records[0].Id);

		// is null string field
		qb = new QueryBuilder(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new QueryBuilder.NullCondition('Industry').isNull()).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(1, records.size());
		System.assertEquals(accounts[0].Id, records[0].Id);

		// not null
		qb = qb.newQuery().addFrom(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new QueryBuilder.NullCondition(Account.Industry).notNull()).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(1, records.size());
		System.assertEquals(accounts[1].Id, records[0].Id);

	}

	@IsTest
	private static void testEnsureThatCorrectLikeConditionLogicHasBeenAppliedToQueryBuilderIntegration() {
		MockUtility.disableTriggerExecution();

		List<Account> accounts = ApplicationTestDataFactory.getAccounts(2, false);
		insert accounts;

		QueryBuilder qb = new QueryBuilder(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		String soql = qb.addConditions().add(new QueryBuilder.LikeCondition(Account.Name).likeAnyBoth('Test Name')).endConditions().toSoqlString();
		List<SObject> records = Database.query(soql);
		System.assertEquals(2, records.size());

		qb = new QueryBuilder(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new QueryBuilder.LikeCondition('Name').likeAnyBoth('Test Name')).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(2, records.size());

		qb = qb.newQuery().addFrom(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new QueryBuilder.LikeCondition(Account.Name).likeAnyLeft('Name 1')).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(1, records.size());

		qb = qb.newQuery().addFrom(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new QueryBuilder.LikeCondition(Account.Name).likeAnyRight('Test Name 1')).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(1, records.size());

	}

	@IsTest
	private static void testEnsureThatCorrectInConditionLogicHasBeenAppliedToQueryBuilderIntegration() {
		MockUtility.disableTriggerExecution();

		List<Account> accounts = ApplicationTestDataFactory.getAccounts(1, false);
		insert accounts;

		List<Contact> contacts = ApplicationTestDataFactory.getContacts(2, accounts[0].Id, false);
		insert contacts;

		QueryBuilder qb = new QueryBuilder(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		String soql = qb.addConditions().add(new QueryBuilder.InCondition(Account.Name).inCollection(new Set<String>{'Test Name 1'})).endConditions().toSoqlString();
		List<SObject> records = Database.query(soql);
		System.assertEquals(1, records.size());

		qb = new QueryBuilder(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new QueryBuilder.InCondition('Name').inCollection(new Set<String>{'Test Name 1'})).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(1, records.size());

		qb = qb.newQuery().addFrom(Contact.SObjectType);
		qb.addFields(new List<SObjectField>{Contact.Id});
		soql = qb.addConditions().add(new QueryBuilder.InCondition(Contact.Id).inCollection(contacts)).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(2, records.size());

		qb = qb.newQuery().addFrom(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new QueryBuilder.InCondition(Account.AnnualRevenue).inCollection(new Set<Decimal>{1000000})).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(1, records.size());

		qb = qb.newQuery().addFrom(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new QueryBuilder.InCondition(Account.Id).notIn(accounts)).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(0, records.size());

		QueryBuilder qbInner = new QueryBuilder(Account.SObjectType);
		qbInner.addFields(new List<SObjectField>{Account.Id});
		qbInner.addConditions().add(new QueryBuilder.InCondition(Account.Id).inCollection(accounts)).endConditions();

		qb = qb.newQuery().addFrom(Contact.SObjectType);
		qb.addFields(new List<SObjectField>{Contact.Id});
		soql = qb.addConditions().add(new QueryBuilder.InCondition(Contact.AccountId).inCollection(qbInner)).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(2, records.size());

		qb = qb.newQuery().addFrom(Contact.SObjectType);
		qb.addFields(new List<SObjectField>{Contact.Id});
		soql = qb.addConditions().add(new QueryBuilder.InCondition(Contact.AccountId).notIn(qbInner)).endConditions().toSoqlString();
		records = Database.query(soql);
		System.assertEquals(0, records.size());

		qb = qb.newQuery().addFrom(Account.SObjectType);
		qb.addFields(new List<SObjectField>{Account.Id});
		soql = qb.addConditions().add(new QueryBuilder.InCondition(Account.Name).notInCollection(new Set<String>{'Test Name 1'})).endConditions().toSoqlString();
		// make sure there is NOT IN operator
		System.assertEquals(true, Pattern.compile('(?is)\\bName NOT IN\\b').matcher(soql).find(), 'Resulting query does not include NOT IN operator');

	}

	@IsTest
	private static void testEnsureThatForUpdateProducesCorrectQueryOutput() {
		QueryBuilder qb = new QueryBuilder(Account.SObjectType);
		qb.addField('Name');
		qb.setLimit(20);
		qb.setForUpdate();
		String soql = qb.toSoqlString();

		// verify query structure
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b.*?LIMIT\\s+20\\s+FOR\\s+UPDATE\\s*$').matcher(soql).find(), 'Resulting query does not set FOR UPDATE correctly');
		System.assertEquals(true, Database.query(soql).isEmpty());

		qb = new QueryBuilder(Account.SObjectType);
		qb.addField('Name');
		qb.addOrder(new QueryBuilder.Order('Id', 'Desc'));
		qb.setLimit(20);
		qb.setOffset(5);
		qb.setForUpdate(true);
		soql = qb.toSoqlString();

		// verify query structure
		System.assertEquals(true, Pattern.compile('(?ism)\\bfrom account\\b.*?LIMIT\\s+20\\s+FOR\\s+UPDATE\\s*$').matcher(soql).find(), 'Resulting query does not set FOR UPDATE correctly');
		System.assertEquals(false, Pattern.compile('(?ism)\\bfrom account\\b.*?OFFSET\\s+5\\s*$').matcher(soql).find(), 'Resulting query should not set OFFSET when FOR UPDATE is used');
		System.assertEquals(false, Pattern.compile('(?ism)\\bfrom account\\b.*?Order\\s+By\\s+Id\\s+Desc\\s*$').matcher(soql).find(), 'Resulting query should not set Order By when FOR UPDATE is used');
		System.assertEquals(true, Database.query(soql).isEmpty());

	}
}