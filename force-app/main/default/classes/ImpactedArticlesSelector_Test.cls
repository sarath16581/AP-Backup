/**
* @description Impacted Articles Selector Test class
* @author Vasu Gorakati
* @date 2024-06-18
* @changelog
* 2024-06-18 - Vasu Gorakati - Case Hand-off
* 2024-08-31 - Ranjeewa Silva - Added test to verify search method behaviour.
**/
@isTest
private class ImpactedArticlesSelector_Test {
	
	/**
	 * Test: Ensures that the selectors QueryBuilder is generating the correct output
	 */
	@IsTest
	private static void testEnsureQueryBuilderProducesCorrectString() {
		
		// =====================================
		// Data Preparation
		// =====================================
		// None!
		
		// =====================================
		// Stubbing
		// =====================================
		// None!
		
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		
		ImpactedArticlesSelector selector = ImpactedArticlesSelector.newInstance();
		QueryBuilder qb = selector.newQueryBuilder();
		String soql = qb.toSoqlString();
		
		Assert.isTrue(Pattern.compile('(?ism)\\bfrom ImpactedArticle__c\\b').matcher(soql).find(), 'Resulting query does not select from ImpactedArticle__c: ' + soql);

		// test for field overrides
		selector = (ImpactedArticlesSelector) ImpactedArticlesSelector.newInstance().setFieldOverrides(new Map<SObjectType, Set<SObjectField>>{
				Case.SObjectType => new Set<SObjectField>{Case.Id, Case.IsClosed}
		});
		qb = selector.newQueryBuilder(new Set<Object>{ImpactedArticlesSelector.Options.WITH_CASE});
		soql = qb.toSoqlString();
		Assert.isTrue(Pattern.compile('(?ism)Case__r\\.IsClosed.*?\\bfrom ImpactedArticle__c\\b').matcher(soql).find(), 'Resulting query does not select Case__r fields: ' + soql);

		Test.stopTest();
		
	}

	/**
	 * Test to ensure that the search method QueryBuilder is generating the correct output
	 */
	@IsTest
	public static void testEnsureSearchMethodProducesCorrectString() {
		// =====================================
		// Data Preparation
		// =====================================
		// None!

		// =====================================
		// Stubbing
		// =====================================
		// None!

		// =====================================
		// Testing
		// =====================================
		Test.startTest();

		Map<String, Object> searchParams;

		ImpactedArticlesSelector selector = ImpactedArticlesSelector.newInstance();

		searchParams = new Map<String, Object>{
				'articleIds' => new Set<Id>{'a1h000000000000000'},
				'caseRecordTypeIds' => new Set<Id>{'012900000000000000'},
				'caseEnquirySubTypes' => new Set<String>{'Test'},
				'isCaseOpen' => true
		};

		String soql = selector.getSearchSoql(searchParams, new Set<Object>(), true);
		Assert.isTrue(Pattern.compile('(?ism)\\s+from ImpactedArticle__c\\s+where\\b.*?\\bArticle__c\\s+In\\b').matcher(soql).find(), 'Resulting query does not filter article : '+ + soql);
		Assert.isTrue(Pattern.compile('(?ism)\\s+from ImpactedArticle__c\\s+where\\b.*?\\bCase__r.RecordTypeId\\s+In\\b').matcher(soql).find(), 'Resulting query does not filter case record type : ' + + soql);
		Assert.isTrue(Pattern.compile('(?ism)\\s+from ImpactedArticle__c\\s+where\\b.*?\\bCase__r.EnquirySubType__c\\s+In\\b').matcher(soql).find(), 'Resulting query does not filter case EnquirySubType__c : ' + + soql);
		Assert.isTrue(Pattern.compile('(?ism)\\s+from ImpactedArticle__c\\s+where\\b.*?\\bCase__r.IsClosed\\s*!=\\s').matcher(soql).find(), 'Resulting query does not filter case IsClosed : ' + soql);
		Assert.isTrue(Pattern.compile('(?ism)\\s+from ImpactedArticle__c\\s+where\\b.*?\\bAND\\b').matcher(soql).find(), 'Resulting query does not limit by ALL : ' + + soql);

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, new Set<Object>(),true);

		searchParams = new Map<String, Object>{
				'articleIds' => new Set<Id>{'a1h000000000000000'}
		};

		soql = selector.getSearchSoql(searchParams, new Set<Object>(), true);
		Assert.isTrue(Pattern.compile('(?ism)\\s+from ImpactedArticle__c\\s+where\\b.*?\\bArticle__c\\s+In\\b').matcher(soql).find(), 'Resulting query does not filter article.');
		Assert.isFalse(Pattern.compile('(?ism)\\s+from ImpactedArticle__c\\s+where\\b.*?\\bCase__r.RecordTypeId\\s+In\\b').matcher(soql).find(), 'Resulting query filter case record type, but it should not.');
		Assert.isFalse(Pattern.compile('(?ism)\\s+from ImpactedArticle__c\\s+where\\b.*?\\bCase__r.IsClosed\\s*!=\\s').matcher(soql).find(), 'Resulting query filter case IsClosed, but it should not.');

		// make sure the query is valid (even though no records will be returned)
		// note if the query fails, an exception will be thrown
		selector.search(searchParams, new Set<Object>(), true);

		// make sure an exception is thrown for invalid search parameters
		searchParams = new Map<String, Object>{
				'invalidParam' => new Set<String>{'somevalue'},
				'articleIds' => new Set<Id>{'a1h000000000000000'}
		};

		try {
			soql = selector.getSearchSoql(searchParams, new Set<Object>(), false);
		} catch (Exception e) {
			// ensure correct type of exception thrown
			Assert.isInstanceOfType(e, ApplicationSelector.SelectorException.class);
		}

		Test.stopTest();
	}

	/**
	 * Executes a query to ensure it returns expected results with actual inserted data
	 */
	@IsTest
	private static void testSelectorIntegration() {
		
		// =====================================
		// Data Preparation
		// =====================================
		MockUtility.disableTriggerExecution();
		
		Article__c consignment = ApplicationTestDataFactory.getConsignments(1, false)[0];		
		INSERT consignment;
	   
		
		Article__c article = ApplicationTestDataFactory.getArticles(2, consignment.Id, false)[0];
		INSERT article;
		
		Case caserec = ApplicationTestDataFactory.getCases(1, false)[0];
		INSERT caserec;
		
		List<ImpactedArticle__c> impactedArticles = ApplicationTestDataFactoryCase.getImpactedArticles(1, caserec.Id, article.Id,false);
		INSERT impactedArticles;
		
		// =====================================
		// Stubbing
		// =====================================
		// None!
		
		// =====================================
		// Testing
		// =====================================
		Test.startTest();
		ImpactedArticlesSelector selector = ImpactedArticlesSelector.newInstance();
		List<ImpactedArticle__c> results  = selector.selectByCaseId(new Set<Id>{caserec.Id}, new Set<Object>());
		System.assertEquals(1, results.size(), 'Expected result size of 1');
		Test.stopTest();
		
	}
	
}