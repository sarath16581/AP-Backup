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

/**
 * Basic class and a namespace for all query building methods.
 *
 * @author github.com/4an70m
 * @version 1.0
 * @changelog
 * 2020-08-02 - Nathan Franklin - Added option for fieldOverrides
 * 2021-12-02 - Alex Volkov - Added datetime comparison conditions
 * 2022-11-23 - Mahesh Parvathaneni - Added notInCollection conditions
 * 2023-03-06 - Nathan Franklin - Added ability to reset order by and retrieve current values
 * 2024-03-07 - Mahesh Parvathaneni - Added ability to include FOR UPDATE in the query
 * 2024-07-22 - Marcel HK - Fixed bug with `ConditionsManager.bracketConditions()` where 10+ conditions produced incorrect WHERE clause
 */
public virtual inherited sharing class QueryBuilder {

	/**
	 * Store a list of type instance mappings to be able grab the correct instance when needed
	 * This is used to provide mocks in test classes to override default functionality where we don't care about the results
	 */
	@TestVisible
	private static Application.GenericFactory mockFactory = new Application.GenericFactory();

	public static QueryBuilder newInstance(Type selectorType) {
		if(Test.isRunningTest() && mockFactory.get(selectorType) != null) {
			return (QueryBuilder)mockFactory.get(selectorType);
		} else {
			return newInstance();
		}
	}
	public static QueryBuilder newInstance() {
		return new QueryBuilder();
	}

	public enum FilterScope {
		Delegated,
		Everything,
		Mine,
		MineAndMyGroups,
		My_Territory,
		My_Team_Territory,
		Team
	}

	public enum AggregateFunction {
		COUNT,
		MIN,
		MAX,
		AVG,
		SUM
	}


	@TestVisible
	private String fromSobject;

	private Set<String> fieldTokens;
	private Set<String> groupByFields;
	private List<Order> sortingOrder;
	private FilterScope scope;
	private Integer queryLimit;
	private Integer queryOffset;
	private Integer countResult;
	private Boolean updateTracking;
	private Boolean updateViewstat;
	private Boolean forView;
	private Boolean forReference;
	private Boolean withSecurityEnforced;
	private Boolean hasSubQueries;
	private Boolean forUpdate;

	/**
	 * When calling attachTo, we store a reference here to show that parent relationships are contained within the query
	 */
	private Map<String, Set<String>> parentRelationships;

	public ConditionsManager conditionsManager;

	/**
	 * Constructs a QueryBuilder instance for
	 * given SObject name in a string form.
	 *
	 * <br/><br/>
	 * <p><b>Example</b></p>
	 * <pre>
	 * <code>
	 * new QueryBuilder('Account');
	 * </code>
	 * </pre>
	 *
	 * @param fromSobject
	 */
	public QueryBuilder(String fromSobject) {
		this();
		this.fromSobject = fromSobject.trim();
	}

	/**
	 * Constructs a QueryBuilder instance for
	 * given SObject name in an SObjectType form.
	 *
	 * <br/><br/>
	 * <p><b>Example</b></p>
	 * <pre>
	 * <code>
	 * new QueryBuilder(Account.getSObjectType());
	 * </code>
	 * </pre>
	 *
	 * @param type
	 */
	public QueryBuilder(SObjectType type) {
		this();
		addFrom(type);
	}

	/**
	 * Constructs an empty QueryBuilder instance.
	 * Requires a call to addFrom() method for selecting
	 * an sobject to build query for.
	 *
	 * @see QueryBuilder.addFrom
	 */
	public QueryBuilder() {
		this.parentRelationships = new Map<String, Set<String>>();
		this.fieldTokens = new Set<String>();
		this.groupByFields = new Set<String>();
		this.sortingOrder = new List<Order>();
		this.conditionsManager = new ConditionsManager(this);
		this.queryLimit = 0;
		this.queryOffset = 0;
		this.countResult = null;
		this.updateTracking = false;
		this.updateViewstat = false;
		this.forView = false;
		this.forReference = false;
		this.withSecurityEnforced = false;
		this.scope = FilterScope.Everything;
		this.hasSubQueries = false;
		this.forUpdate = false;
	}

	/**
	 * Sets the FROM statement in the query.
	 * Always overrides the constructor-selected FROM value.
	 * <br/>
	 * The name of the SObject is accepted as a string.
	 *
	 * <br/><br/>
	 * <p><b>Example</b></p>
	 * <pre>
	 * <code>
	 * new QueryBuilder()
	 * .addFrom('Account');
	 * </code>
	 * </pre>
	 *
	 * @param fromSobject
	 *
	 * @return this - current instance of QueryBuilder.class
	 */
	public QueryBuilder addFrom(String fromSobject) {
		this.fromSobject = fromSobject;
		return this;
	}

	/**
	 * Sets the FROM statement in the query.
	 * Always overrides the constructor-selected FROM value.
	 * <br/>
	 * The name of the SObject is accepted as a string.
	 *
	 * <br/><br/>
	 * <p><b>Example</b></p>
	 * <pre>
	 * <code>
	 * new QueryBuilder()
	 * .addFrom(Account.SObjectType);
	 * </code>
	 * </pre>
	 *
	 * @param fromSobject
	 *
	 * @return this - current instance of QueryBuilder.class
	 */
	public QueryBuilder addFrom(SObjectType fromSobject) {
		this.fromSobject = String.valueOf(fromSobject);
		return this;
	}

	/**
	 * Attaches the fields from another object to the current QueryBuilder
	 * If there are fieldOverrides defined for the related object then the field overrides will be used rather than the default field list
	 */
	public QueryBuilder addRelatedFields(QueryBuilder relatedBuilder, String relationshipName) {
		for(String fieldToken : relatedBuilder.getFields()) {
			addField(relationshipName + '.' + fieldToken);
		}
		return this;
	}

	public QueryBuilder addSubQuery(QueryBuilder queryBuilder) {
		hasSubQueries = true;
		return this.addField('(' + queryBuilder.toSoqlString() + ')');
	}

	public QueryBuilder addSubQuery(QueryBuilder queryBuilder, String relationshipName) {
		hasSubQueries = true;
		QueryBuilder qb = queryBuilder.clone();
		qb.addFrom(relationshipName);
		return this.addField('(' + qb.toSoqlString() + ')');
	}

	/**
	 * Adds a field or number of comma-separated fields
	 * into the query selection Set.
	 *
	 * <br/><br/>
	 * <p><b>Example</b></p>
	 * <pre>
	 * <code>
	 * new QueryBuilder(Account.class)
	 * .addField('Id')
	 * .addField('Name, ParentId');
	 * </code>
	 * </pre>
	 *
	 * @param fieldName
	 *
	 * @return this - current instance of QueryBuilder.class
	 */
	public QueryBuilder addField(String fieldName) {
		this.fieldTokens.add(fieldName.trim());
		return this;
	}

	/**
	 * Adds a field in a form of SObjectField
	 * into the query selection Set.
	 *
	 * <br/><br/>
	 * <p><b>Example</b></p>
	 * <pre>
	 * <code>
	 * new QueryBuilder(Account.class)
	 * .addField(Account.Name);
	 * </code>
	 * </pre>
	 *
	 * @param fieldName
	 *
	 * @return this - current instance of QueryBuilder.class
	 */
	public QueryBuilder addField(SObjectField field) {
		return this.addField('' + field);
	}

	/**
	 * Adds a field in a form of SObjectField
	 * into the query selection Set.
	 *
	 * <br/><br/>
	 * <p><b>Example</b></p>
	 * <pre>
	 * <code>
	 * new QueryBuilder(Account.class)
	 * .addField(Account.Name);
	 * </code>
	 * </pre>
	 *
	 * @param fieldName
	 *
	 * @return this - current instance of QueryBuilder.class
	 */
	public QueryBuilder addFields(List<SObjectField> fields) {
		for (SObjectField field : fields) {
			System.debug(field);
			this.fieldTokens.add('' + field);
		}
		return this;
	}
	/**
	 * Adds a field in a form of SObjectField
	 * into the query selection Set.
	 *
	 * <br/><br/>
	 * <p><b>Example</b></p>
	 * <pre>
	 * <code>
	 * new QueryBuilder(Account.class)
	 * .addField(Account.Name);
	 * </code>
	 * </pre>
	 *
	 * @param fieldName
	 *
	 * @return this - current instance of QueryBuilder.class
	 */
	public QueryBuilder addFields(Set<SObjectField> fields) {
		for (SObjectField field : fields) {
			this.fieldTokens.add('' + field);
		}
		return this;
	}

	/**
	 * Adds a list of fields into the query selection Set.
	 *
	 * <br/><br/>
	 * <p><b>Example</b></p>
	 * <pre>
	 * <code>
	 * new QueryBuilder(Account.class)
	 * .addFields(new List<String> {'Name'});
	 * </code>
	 * </pre>
	 *
	 * @param fieldNames
	 *
	 * @return this - current instance of QueryBuilder.class
	 */
	public QueryBuilder addFields(List<String> fieldNames) {
		this.fieldTokens.addAll(fieldNames);
		return this;
	}

	/**
	 * Adds a set of fields into the query selection Set.
	 *
	 * <br/><br/>
	 * <p><b>Example</b></p>
	 * <pre>
	 * <code>
	 * new QueryBuilder(Account.class)
	 * .addFields(new Set<String> {'Name'});
	 * </code>
	 * </pre>
	 *
	 * @param fieldNames
	 *
	 * @return this - current instance of QueryBuilder.class
	 */
	public QueryBuilder addFields(Set<String> fieldNames) {
		this.fieldTokens.addAll(fieldNames);
		return this;
	}

	public Set<String> getFields() {
		return fieldTokens;
	}

	public Boolean hasSubQueries() {
		return hasSubQueries;
	}

	/**
	 * Returns an instance of ConditionsManage for current QueryBuilder instance.
	 * Allows creation of conditions for a query.
	 * <p>To finish work with conditions and return to work with QueryBuilder instance
	 * it is required to call the endConditions() method of ConditionsManager</p>
	 *
	 * @return an instance of ConditionsManager.class
	 *
	 * @see QueryBuilder.ConditionsManager
	 */
	public ConditionsManager addConditions() {
		return this.conditionsManager;
	}

	/**
	 * Returns an instance of ConditionsManage for current QueryBuilder instance.
	 * Allows creation of conditions for a query.
	 * <p>As a parameter accepts a string with order of conditions execution and there relations</p>
	 * <p>To finish work with conditions and return to work with QueryBuilder instance
	 * it is required to call the endConditions() method of ConditionsManager</p>
	 * <p>Condition index is 1-based<p>
	 *
	 * <br/><br/>
	 * <p><b>Example</b></p>
	 * <pre>
	 * <code>
	 * new QueryBuilder()
	 * .addConditionsWithOrder('1 and (2 or 3) and 4')
	 * .endConditions();
	 * </code>
	 * </pre>
	 *
	 * @param conditionOrder
	 *
	 * @return an instance of ConditionsManager.class
	 *
	 * @see QueryBuilder.ConditionsManager
	 */
	public ConditionsManager addConditionsWithOrder(String conditionOrder) {
		return this.conditionsManager.setConditionOrder(conditionOrder);
	}

	/**
	 * Sets a limit for current query. Accepts an integer.
	 *
	 * @param queryLimit
	 *
	 * @return this - current instance of QueryBuilder.class
	 */
	public QueryBuilder setLimit(Integer queryLimit) {
		this.queryLimit = queryLimit;
		return this;
	}

	/**
	 * Sets an offset for current query. Accepts an integer.
	 *
	 * @param queryOffset
	 *
	 * @return this - current instance of QueryBuilder.class
	 */
	public QueryBuilder setOffset(Integer queryOffset) {
		this.queryOffset = queryOffset;
		return this;
	}

	/**
	 * Resets the order by parameter
	 */
	public QueryBuilder setOrder(Order order) {
		this.sortingOrder = new List<Order>{order};
		return this;
	}

	/**
	 * Adds a SORT BY {Order} statement to the query.
	 *
	 * <br/><br/>
	 * <p><b>Example</b></p>
	 * <pre>
	 * <code>
	 * new QueryBuilder(Account.class)
	 * .addOrder(
	 *  new QueryBuilder.Order(Account.Id)
	 *  .setSortingOrderAsc()
	 *  .setNullsOrderLast()
	 *  );
	 * </code>
	 * </pre>
	 *
	 * @param fieldName
	 *
	 * @return this - current instance of QueryBuilder.class
	 */
	public QueryBuilder addOrder(Order order) {
		return addOrder(new List<Order>{order});
	}

	/**
	 * Adds a SORT BY {Order} statement to the query.
	 *
	 * <br/><br/>
	 * <p><b>Example</b></p>
	 * <pre>
	 * <code>
	 * new QueryBuilder(Account.class)
	 * .addOrder(
	 *  new QueryBuilder.Order(Account.Id)
	 *  .setSortingOrderAsc()
	 *  .setNullsOrderLast()
	 *  );
	 * </code>
	 * </pre>
	 *
	 * @param fieldName
	 *
	 * @return this - current instance of QueryBuilder.class
	 */
	public QueryBuilder addOrder(List<Order> order) {
		this.sortingOrder.addAll(order);
		return this;
	}

	/**
	 * Adds a SORT BY {field} ASC statement to the query.
	 * Field name is specified as a string.
	 *
	 * <br/><br/>
	 * <p><b>Example</b></p>
	 * <pre>
	 * <code>
	 * new QueryBuilder(Account.class)
	 * .addOrderAsc('Account');
	 * </code>
	 * </pre>
	 *
	 * @param fieldName
	 *
	 * @return this - current instance of QueryBuilder.class
	 */
	public QueryBuilder addOrderAsc(String fieldName) {
		this.sortingOrder.add(new AscOrder(fieldName));
		return this;
	}

	/**
	 * Adds a SORT BY {field} ASC statement to the query.
	 * Field is specified as an SObjectField.
	 *
	 * <br/><br/>
	 * <p><b>Example</b></p>
	 * <pre>
	 * <code>
	 * new QueryBuilder(Account.class)
	 * .addOrderAsc(Account.Name);
	 * </code>
	 * </pre>
	 *
	 * @param field
	 *
	 * @return this - current instance of QueryBuilder.class
	 */
	public QueryBuilder addOrderAsc(SObjectField field) {
		this.sortingOrder.add(new AscOrder(String.valueOf(field)));
		return this;
	}

	/**
	 * Adds a SORT BY {field} DESC statement to the query.
	 * Field name is specified as a string.
	 *
	 * <br/><br/>
	 * <p><b>Example</b></p>
	 * <pre>
	 * <code>
	 * new QueryBuilder(Account.class)
	 * .addOrderDesc('Account');
	 * </code>
	 * </pre>
	 *
	 * @param fieldName
	 *
	 * @return this - current instance of QueryBuilder.class
	 */
	public QueryBuilder addOrderDesc(String fieldName) {
		this.sortingOrder.add(new DescOrder(fieldName));
		return this;
	}

	/**
	 * Adds a SORT BY {field} DESC statement to the query.
	 * Field is specified as an SObjectField.
	 *
	 * <br/><br/>
	 * <p><b>Example</b></p>
	 * <pre>
	 * <code>
	 * new QueryBuilder(Account.class)
	 * .addOrderDesc(Account.Name);
	 * </code>
	 * </pre>
	 *
	 * @param field
	 *
	 * @return this - current instance of QueryBuilder.class
	 */
	public QueryBuilder addOrderDesc(SObjectField field) {
		this.sortingOrder.add(new DescOrder(String.valueOf(field)));
		return this;
	}

	/**
	 * Adds a field in an SObjectField form to the Set of fields.
	 *
	 * <br/><br/>
	 * <p><b>Example</b></p>
	 * <pre>
	 * <code>
	 * new QueryBuilder(Account.class)
	 * .addAggregate(Account.Name, AggregateFunction.COUNT);
	 * </code>
	 * </pre>
	 *
	 * @param field
	 * @param aggregateFunction
	 *
	 * @return this - current instance of QueryBuilder.class
	 *
	 */
	public QueryBuilder addAggregate(SObjectField field, AggregateFunction aggregate) {
		switch on aggregate {
			when COUNT {
				this.addField('COUNT(' + field + ') COUNT_' + field);
			}
			when MIN {
				this.addField('MIN(' + field + ') MIN_' + field);
			}
			when MAX {
				this.addField('MAX(' + field + ') MAX_' + field);
			}
			when AVG {
				this.addField('AVG(' + field + ') AVG_' + field);
			}
			when SUM {
				this.addField('SUM(' + field + ') SUM_' + field);
			}
		}
		return this;
	}

	/**
	 * Adds a field or number of comma-separated fields to the
	 * group by Set of fields.
	 *
	 * <br/><br/>
	 * <p><b>Example</b></p>
	 * <pre>
	 * <code>
	 * new QueryBuilder(Account.class)
	 * .groupBy('Name')
	 * .groupBy('Id, ParentId');
	 * </code>
	 * </pre>
	 *
	 * @param fields
	 *
	 * @return this - current instance of QueryBuilder.class
	 */
	public QueryBuilder addGroupBy(String fields) {
		return this.addGroupBy(fields.trim().split(','));
	}

	/**
	 * Adds a field in an SObjectField form to the
	 * group by Set of fields.
	 *
	 * <br/><br/>
	 * <p><b>Example</b></p>
	 * <pre>
	 * <code>
	 * new QueryBuilder(Account.class)
	 * .groupBy(Account.Name);
	 * </code>
	 * </pre>
	 *
	 * @param field
	 *
	 * @return this - current instance of QueryBuilder.class
	 */
	public QueryBuilder addGroupBy(SObjectField field) {
		return this.addGroupBy(String.valueOf(field));
	}

	/**
	 * Adds a set of fields in an SObjectField form to the
	 * group by Set of fields.
	 *
	 * <br/><br/>
	 * <p><b>Example</b></p>
	 * <pre>
	 * <code>
	 * new QueryBuilder(Account.class)
	 * .groupBy(new Set<SObjectField> { Account.Name} );
	 * </code>
	 * </pre>
	 *
	 * @param fields
	 *
	 * @return this - current instance of QueryBuilder.class
	 */
	public QueryBuilder addGroupBy(Set<SObjectField> fields) {
		for(SObjectField f: fields) {
			this.addGroupBy(String.valueOf(f));
		}
		return this;
	}

	/**
	 * Adds a list of field to the
	 * group by Set of fields.
	 *
	 * <br/><br/>
	 * <p><b>Example</b></p>
	 * <pre>
	 * <code>
	 * new QueryBuilder(Account.class)
	 * .groupBy(new List<String> {'Name'});
	 * </code>
	 * </pre>
	 *
	 * @param fields
	 *
	 * @return this - current instance of QueryBuilder.class
	 */
	public QueryBuilder addGroupBy(List<String> fields) {
		this.groupByFields.addAll(fields);
		return this;
	}



	/**
	 * Adds a set of field to the
	 * group by Set of fields.
	 *
	 * <br/><br/>
	 * <p><b>Example</b></p>
	 * <pre>
	 * <code>
	 * new QueryBuilder(Account.class)
	 * .groupBy(new Set<String> {'Name'});
	 * </code>
	 * </pre>
	 *
	 * @param fields
	 *
	 * @return this - current instance of QueryBuilder.class
	 */
	public QueryBuilder addGroupBy(Set<String> fields) {
		this.groupByFields.addAll(fields);
		return this;
	}

	/**
	 * Adds the optional USING SCOPE clause of a SOQL query returns
	 * records within a specified scope. For example, you can limit
	 * the records to return only objects that the user owns
	 * or only records in the user’s territory.
	 *
	 * <br/><br/>
	 * <p><b>Example</b></p>
	 * <pre>
	 * <code>
	 * new QueryBuilder(Account.class)
	 * .setScope(QueryBuilder.FilterScope.Mine);
	 * </code>
	 * </pre>
	 *
	 * @param scope
	 *
	 * @return this - current instance of QueryBuilder.class
	 */
	public QueryBuilder setScope(QueryBuilder.FilterScope scope) {
		this.scope = scope;
		return this;
	}

	/**
	 * Adds FOR VIEW clause in to the query.
	 * Allows to update LastViewedDate on retrieved objects.
	 *
	 * <br/><br/>
	 * <p><b>Example</b></p>
	 * <pre>
	 * <code>
	 * new QueryBuilder(Account.class)
	 * .setForView(true);
	 * </code>
	 * </pre>
	 *
	 * @param forView
	 *
	 * @return this - current instance of QueryBuilder.class
	 */
	public QueryBuilder setForView(Boolean forView) {
		this.forView = this.forView;
		return this;
	}

	/**
	 * Adds FOR VIEW clause in to the query.
	 * Allows to update LastViewedDate on retrieved objects.
	 *
	 * <br/><br/>
	 * <p><b>Example</b></p>
	 * <pre>
	 * <code>
	 * new QueryBuilder(Account.class)
	 * .setForView();
	 * </code>
	 * </pre>
	 *
	 * @param forView
	 *
	 * @return this - current instance of QueryBuilder.class
	 */
	public QueryBuilder setForView() {
		this.forView = true;
		return this;
	}

	/**
	 * Adds FOR UPDATE clause in to the query.
	 * Allows to lock sObject records while they’re being updated in order to prevent race conditions and other thread safety problems
	 *
	 * <br/><br/>
	 * <p><b>Example</b></p>
	 * <pre>
	 * <code>
	 * new QueryBuilder(Account.class)
	 * .setForUpdate(true);
	 * </code>
	 * </pre>
	 *
	 * @param forUpdate
	 *
	 * @return this - current instance of QueryBuilder.class
	 */
	public QueryBuilder setForUpdate(Boolean forUpdate) {
		this.forUpdate = forUpdate;
		return this;
	}

	/**
	 * Adds FOR UPDATE clause in to the query.
	 * Allows to lock sObject records while they’re being updated in order to prevent race conditions and other thread safety problems
	 *
	 * <br/><br/>
	 * <p><b>Example</b></p>
	 * <pre>
	 * <code>
	 * new QueryBuilder(Account.class)
	 * .setForUpdate();
	 * </code>
	 * </pre>
	 *
	 * @return this - current instance of QueryBuilder.class
	 */
	public QueryBuilder setForUpdate() {
		this.forUpdate = true;
		return this;
	}

	///**
	// * Adds FOR REFERENCE clause in to the query.
	// * Allows to update LastReferencedDate on retrieved objects.
	// *
	// * <br/><br/>
	// * <p><b>Example</b></p>
	// * <pre>
	// * <code>
	// * new QueryBuilder(Account.class)
	// * .setForReference(true);
	// * </code>
	// * </pre>
	// *
	// * @param forReference
	// *
	// * @return this - current instance of QueryBuilder.class
	// */
	//public QueryBuilder setForReference(Boolean forReference) {
	//this.forReference = this.forReference;
	//return this;
	//}
	//
	///**
	// * Adds FOR REFERENCE clause in to the query.
	// * Allows to update LastReferencedDate on retrieved objects.
	// *
	// * <br/><br/>
	// * <p><b>Example</b></p>
	// * <pre>
	// * <code>
	// * new QueryBuilder(Account.class)
	// * .setForView();
	// * </code>
	// * </pre>
	// *
	// * @param forReference
	// *
	// * @return this - current instance of QueryBuilder.class
	// */
	//public QueryBuilder setForReference() {
	//this.forReference = true;
	//return this;
	//}

	///**
	// * Sets the UPDATE TRACKING optional clause on a SOQL query.
	// * UPDATE TRACKING can be added to a SELECT statement of a
	// * SOQL query to report on article searches and views to track
	// * the keywords that are used in Salesforce Knowledge article searches
	// *
	// * <br/><br/>
	// * <p><b>Example</b></p>
	// * <pre>
	// * <code>
	// * new QueryBuilder(Account.class)
	// * .setUpdateTracking(true);
	// * </code>
	// * </pre>
	// *
	// * @return
	// */
	//public QueryBuilder setUpdateTracking(Boolean updateTracking) {
	//this.updateTracking = updateTracking;
	//return this;
	//}
	//
	///**
	// * Sets the UPDATE TRACKING optional clause on a SOQL query.
	// * UPDATE TRACKING can be added to a SELECT statement of a
	// * SOQL query to report on article searches and views to track
	// * the keywords that are used in Salesforce Knowledge article searches
	// *
	// * <br/><br/>
	// * <p><b>Example</b></p>
	// * <pre>
	// * <code>
	// * new QueryBuilder(Account.class)
	// * .setUpdateTracking();
	// * </code>
	// * </pre>
	// *
	// * @return
	// */
	//public QueryBuilder setUpdateTracking() {
	//return this.setUpdateTracking(true);
	//}
	//
	///**
	// * Adds the UPDATE VIEWSTAT optional clause to the SOQL query.
	// * Allows get a view count for every article that you have access to online.
	// *
	// * <br/><br/>
	// * <p><b>Example</b></p>
	// * <pre>
	// * <code>
	// * new QueryBuilder(Account.class)
	// * .setUpdateViewstat(true);
	// * </code>
	// * </pre>
	// *
	// * @return
	// */
	//public QueryBuilder setUpdateViewstat(Boolean updateViewstat) {
	//this.updateViewstat = updateViewstat;
	//return this;
	//}
	//
	///**
	// * Adds the UPDATE VIEWSTAT optional clause to the SOQL query.
	// * Allows get a view count for every article that you have access to online.
	// *
	// * <br/><br/>
	// * <p><b>Example</b></p>
	// * <pre>
	// * <code>
	// * new QueryBuilder(Account.class)
	// * .setUpdateViewstat();
	// * </code>
	// * </pre>
	// *
	// * @return
	// */
	//public QueryBuilder setUpdateViewstat() {
	//return this.setUpdateViewstat(true);
	//}

	/**
	 * <h1>THIS IS BETA FUNCTIONALITY</h1>
	 * Enables CRUD and FLS check for current query.
	 *
	 * @return this - current instance of QueryBuilder.class
	 */
	public QueryBuilder setWithSecurityEnforced() {
		return this.setWithSecurityEnforced(true);
	}

	/**
	 * <h1>THIS IS BETA FUNCTIONALITY</h1>
	 * Enables CRUD and FLS check for current query.
	 *
	 * @return this - current instance of QueryBuilder.class
	 */
	public QueryBuilder setWithSecurityEnforced(Boolean withSecurityEnforced) {
		this.withSecurityEnforced = withSecurityEnforced;
		return this;
	}

	/**
	 * Builds a current state of query and outputs it to the debug console.
	 *
	 * @return this - current instance of QueryBuilder.class
	 */
	public QueryBuilder preview() {
		String logRecord = '\n============RESULTING QUERY============\n\n'
				+ this.toSoqlString()
				+ '\n\n=======================================\n';
		System.debug(logRecord);
		return this;
	}

	/**
	 * Nullifies and re-creates all of the fields in current QueryBuilder instance.
	 *
	 * @return this - current instance of QueryBuilder.class
	 */
	public QueryBuilder newQuery() {
		this.fieldTokens = new Set<String>();
		this.groupByFields = new Set<String>();
		this.sortingOrder = new List<Order>();
		this.conditionsManager = new ConditionsManager(this);
		this.queryLimit = 0;
		this.queryOffset = 0;
		this.countResult = null;
		this.updateTracking = false;
		this.updateViewstat = false;
		this.forView = false;
		this.forReference = false;
		this.withSecurityEnforced = false;
		this.scope = FilterScope.Everything;
		this.hasSubQueries = false;
		this.forUpdate = false;
		return this;
	}

	/**
	 * Builds a query based in current params.
	 *
	 * @return string representation of query
	 */
	public String toSoqlString() {
		String result = 'SELECT ';
		String fields = '';
		if (this.fieldTokens.isEmpty()) {
			fields = 'Id';
		} else {
			fields = String.join(new List<String>(this.fieldTokens), ', ');
		}
		result += fields + ' \n';
		result += 'FROM ' + this.fromSobject + ' \n';
		if (this.scope != FilterScope.Everything) {
			result += 'USING SCOPE ' + this.scope.name() + ' \n';
		}
		if (this.conditionsManager.hasConditions()) {
			result += 'WHERE ' + this.conditionsManager.builtCondition + ' \n';
		}
		if (this.withSecurityEnforced) {
			result += 'WITH SECURITY_ENFORCED \n';
		}

		if (!this.groupByFields.isEmpty() && !this.forUpdate) {
			result += 'GROUP BY ';
			result += String.join(new List<String>(this.groupByFields), ', ') + ' \n';
		}
		if (!this.sortingOrder.isEmpty() && !this.forUpdate) {
			result += 'ORDER BY ';
			List<String> orders = new List<String>();
			for (Order order : this.sortingOrder) {
				orders.add(order.toString());
			}
			result += String.join(orders, ', ') + ' \n';
		}
		if (this.queryLimit > 0) {
			result += 'LIMIT ' + this.queryLimit + ' \n';
		}
		if (this.queryOffset > 0 && !this.forUpdate) {
			result += 'OFFSET ' + this.queryOffset + ' \n';
		}

		if ((this.forView && !this.forReference) || (this.forView && this.forReference)) {
			result += 'FOR VIEW \n';
		}
		if (!this.forView && this.forReference) {
			result += 'FOR REFERENCE \n';
		}

		if (this.forUpdate) {
			result += 'FOR UPDATE \n';
		}

		if (this.updateTracking && this.updateViewstat) {
			result += 'UPDATE TRACKING, VIEWSTAT';
		}
		if (this.updateTracking && !this.updateViewstat) {
			result += 'UPDATE TRACKING';
		}
		if (!this.updateTracking && this.updateViewstat) {
			result += 'UPDATE VIEWSTAT';
		}

		String output = result.trim();
		return output;
	}

	/**
	 * Builds a query, replacing all the selected fields with COUNT(Id)
	 * and returns as a string.
	 *
	 * @return string representation of query with COUNT(ID) instead of fields
	 */
	public String toCountString() {
		String result = 'SELECT ';
		String countString = 'count() ';
		result += countString;
		result += 'FROM ' + this.fromSobject + ' ';
		if (this.conditionsManager.hasConditions()) {
			result += 'WHERE ' + this.conditionsManager.builtCondition + ' ';
		}
		if (this.scope != FilterScope.Everything) {
			result += 'USING SCOPE ' + this.scope.name() + ' ';
		}
		if (this.queryLimit > 0) {
			result += 'LIMIT ' + this.queryLimit + ' ';
		}
		if (this.queryOffset > 0) {
			result += 'OFFSET ' + this.queryOffset + ' ';
		}
		return result.trim();
	}

	/**
	 * Class, which allows building query conditions.
	 *
	 * @author github.com/4an70m
	 * @version 1.0
	 */
	public class ConditionsManager {

		private final String BRACKET_L = '{';
		private final String BRACKET_R = '}';

		public List<Condition> conditions;
		private String conditionOrder;
		private final QueryBuilder queryBuilder;

		private String builtCondition;

		public ConditionsManager(QueryBuilder queryBuilder) {
			this.queryBuilder = queryBuilder;
			this.conditions = new List<Condition>();
		}

		public ConditionsManager add(Condition condition) {
			//if (condition instanceof ObjectTypeDependentCondition) {
			//((ObjectTypeDependentCondition) condition).setRelatedObjectType(this.queryBuilder.fromSobject);
			//}
			if (condition.isEmpty()) {
				return this;
			}
			this.conditions.add(condition);
			return this;
		}

		public ConditionsManager setConditionOrder(String conditionOrder) {
			this.conditionOrder = conditionOrder;
			return this;
		}

		public QueryBuilder endConditions() {
			this.builtCondition = this.toString();
			return this.queryBuilder;
		}

		public override String toString() {
			String result = this.conditionOrder;
			if (String.isEmpty(result)) {
				result = '';
				for (Integer i = 0; i < this.conditions.size(); i++) {
					result += (!String.isEmpty(result) ? ' AND ' : '') + (i+1);
				}
			}
			result = this.bracketConditions(result);
			for (Integer i = 0; i < this.conditions.size(); i++) {
				Condition condition = this.conditions[i];
				//if (condition instanceof ObjectTypeDependentCondition) {
				//((ObjectTypeDependentCondition) condition).setRelatedObjectType(this.queryBuilder.fromSobject);
				//}
				String conditionNumber = this.bracket('' + (i + 1));
				if (result.contains(conditionNumber)) {
					result = result.replace(conditionNumber, condition.toString());
				}
			}
			return result;
		}

		private Boolean hasConditions() {
			return !this.conditions.isEmpty();
		}

		private String bracketConditions(String conditions) {
			return conditions.replaceAll('(\\d+)', this.BRACKET_L + '$1' + this.BRACKET_R);
		}

		private String bracket(String condition) {
			return this.BRACKET_L + condition.trim() + this.BRACKET_R;
		}
	}

	/**
	 * Abstract class, which represent a condition, which can be added into ConditionsManager.
	 *
	 * @author github.com/4an70m
	 * @version 1.0
	 */
	public abstract class Condition {

		public final String QUOTE = '\'';
		public final String BRACKET_L = '(';
		public final String BRACKET_R = ')';
		public final String DATETIME_FORMAT = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'';
		protected String formedCondition;

		public Condition() {
			this.formedCondition = '';
		}

		protected String quote(String field) {
			return this.QUOTE + String.escapeSingleQuotes(field.trim()) + this.QUOTE;
		}

		protected String bracket(String field) {
			return BRACKET_L + field.trim() + BRACKET_R;
		}

		protected String datetimeLiteral(Datetime field) {
			return field.formatGmt(DATETIME_FORMAT);
		}

		public virtual override String toString() {
			return this.formedCondition;
		}

		public virtual Boolean isEmpty() {
			return String.isEmpty(this.toString());
		}
	}

	public class SimpleCondition extends Condition {

		public SimpleCondition() {
			super();
		}

		public SimpleCondition(String condition) {
			super();
			this.formedCondition = condition;
		}
	}

	/**
	 * Abstract class, which represent a condition, which can be added into ConditionsManager.
	 * The condition is field-dependent.
	 *
	 * @author github.com/4an70m
	 * @version 1.0
	 */
	public abstract class FieldCondition extends Condition {

		protected String fieldName;

		public FieldCondition(String fieldName) {
			super();
			this.fieldName = fieldName;
		}

		public FieldCondition(SObjectField fieldName) {
			super();
			this.fieldName = String.valueOf(fieldName);
		}

		public override Boolean isEmpty() {
			return String.isEmpty(this.fieldName);
		}
	}

	public class NullCondition extends FieldCondition {

		public NullCondition(String fieldName) {
			super(fieldName);
		}

		public NullCondition(SObjectField fieldName) {
			super(fieldName);
		}

		//null
		public Condition isNull() {
			this.formedCondition = this.fieldName + ' = NULL';
			return this;
		}

		public Condition notNull() {
			this.formedCondition = this.fieldName + ' != NULL';
			return this;
		}
	}

	public class CompareCondition extends FieldCondition {

		public CompareCondition(String fieldName) {
			super(fieldName);
		}

		public CompareCondition(SObjectField fieldName) {
			super(fieldName);
		}

		//string
		public Condition eq(String fieldValue) {
			this.formedCondition = this.fieldName + ' = ' + this.quote(fieldValue);
			return this;
		}

		public Condition ne(String fieldValue) {
			this.formedCondition = this.fieldName + ' != ' + this.quote(fieldValue);
			return this;
		}

		//boolean
		public Condition eq(Boolean fieldValue) {
			this.formedCondition = this.fieldName + ' = ' + fieldValue;
			return this;
		}

		public Condition ne(Boolean fieldValue) {
			this.formedCondition = this.fieldName + ' != ' + fieldValue;
			return this;
		}

		//number
		public Condition eq(Decimal fieldValue) {
			this.formedCondition = this.fieldName + ' = ' + fieldValue;
			return this;
		}

		public Condition lt(Decimal fieldValue) {
			this.formedCondition = this.fieldName + ' < ' + fieldValue;
			return this;
		}

		public Condition gt(Decimal fieldValue) {
			this.formedCondition = this.fieldName + ' > ' + fieldValue;
			return this;
		}

		public Condition lte(Decimal fieldValue) {
			this.formedCondition = this.fieldName + ' <= ' + fieldValue;
			return this;
		}

		public Condition gte(Decimal fieldValue) {
			this.formedCondition = this.fieldName + ' >= ' + fieldValue;
			return this;
		}

		public Condition ne(Decimal fieldValue) {
			this.formedCondition = this.fieldName + ' != ' + fieldValue;
			return this;
		}

		/**
		 * DateTime values need to be converted to GMT before being used as strings in SOQL due to variable timezone offset
		*/
		public Condition lte(Datetime fieldValue) {
			this.formedCondition = this.fieldName + ' <= ' + this.datetimeLiteral(fieldValue);
			return this;
		}

		public Condition gte(Datetime fieldValue) {
			this.formedCondition = this.fieldName + ' >= ' + this.datetimeLiteral(fieldValue);
			return this;
		}

		public Condition lt(Datetime fieldValue) {
			this.formedCondition = this.fieldName + ' < ' + this.datetimeLiteral(fieldValue);
			return this;
		}

		public Condition gt(Datetime fieldValue) {
			this.formedCondition = this.fieldName + ' > ' + this.datetimeLiteral(fieldValue);
			return this;
		}
	}

	public class LikeCondition extends FieldCondition {

		public LikeCondition(String fieldName) {
			super(fieldName);
		}

		public LikeCondition(SObjectField fieldName) {
			super(fieldName);
		}

		//like
		public Condition likeAnyBoth(String fieldValue) {
			this.formedCondition = this.fieldName + ' LIKE ' + this.quote('%' + fieldValue + '%');
			return this;
		}

		public Condition likeAnyLeft(String fieldValue) {
			this.formedCondition = this.fieldName + ' LIKE ' + this.quote('%' + fieldValue);
			return this;
		}

		public Condition likeAnyRight(String fieldValue) {
			this.formedCondition = this.fieldName + ' LIKE ' + this.quote(fieldValue + '%');
			return this;
		}
	}

	/**
	 * DO NOT USE this class. Use dynamic bind variables for these types of conditions.
	 */
	//@Deprecated
	public class InCondition extends FieldCondition {

		//@Deprecated
		public InCondition(String fieldName) {
			super(fieldName);
		}

		//@Deprecated
		public InCondition(SObjectField fieldName) {
			super(fieldName);
		}

		//@Deprecated
		public Condition inCollection(QueryBuilder queryBuilder) {
			this.formedCondition = this.fieldName + ' IN ' + this.bracket(queryBuilder.toSoqlString());
			return this;
		}

		//in - set
		//@Deprecated
		public Condition inCollection(List<SObject> inList) {
			return inCollection(new Map<Id, SObject>(inList));
		}

		//@Deprecated
		public Condition inCollection(Map<Id, SObject> inKeySet) {
			return inCollection(inKeySet.keySet());
		}

		//@Deprecated
		public Condition inCollection(Set<String> inSet) {
			return inCollection(new List<String>(inSet));
		}

		//@Deprecated
		public Condition inCollection(Set<Id> inSet) {
			return inCollection(new List<Id>(inSet));
		}

		//@Deprecated
		public Condition inCollection(Set<Decimal> inSet) {
			return inCollection(new List<Decimal>(inSet));
		}

		//set helpers
		//@Deprecated
		private String buildIn(Set<String> inSet) {
			return buildIn(new List<String>(inSet));
		}

		//@Deprecated
		private String buildIn(Set<Id> inSet) {
			return buildIn(new List<Id>(inSet));
		}

		//@Deprecated
		private String buildInNoQuote(Set<Decimal> inSet) {
			return buildInNoQuote(new List<Decimal>(inSet));
		}


		//in - list
		//@Deprecated
		public Condition inCollection(List<Id> inList) {
			if (inList.isEmpty()) {
				this.formedCondition = '';
			}
			this.formedCondition = this.fieldName + ' IN ' + this.buildIn(inList);
			return this;
		}

		//@Deprecated
		public Condition inCollection(List<String> inList) {
			if (inList.isEmpty()) {
				this.formedCondition = '';
			}
			this.formedCondition = this.fieldName + ' IN ' + this.buildIn(inList);
			return this;
		}

		//@Deprecated
		public Condition inCollection(List<Decimal> inList) {
			if (inList.isEmpty()) {
				this.formedCondition = '';
			}
			this.formedCondition = this.fieldName + ' IN ' + this.buildInNoQuote(inList);
			return this;
		}

		//public Condition inCollection(List<PicklistEntry> inList) {
		//if (inList.isEmpty()) {
		//this.formedCondition = '';
		//}
		//Set<String> picklistEntryValues = new Set<String>();
		//for (PicklistEntry entry : inList) {
		//picklistEntryValues.add(entry.value);
		//}
		//this.inCollection(picklistEntryValues);
		//return this;
		//}

		//list helpers
		//@Deprecated
		private String buildIn(List<String> inList) {

			// escape strings
			List<String> escapedValues = new List<String>();
			for(String item : inList) {
				escapedValues.add(this.quote(item));
			}

			return this.bracket(String.join(escapedValues, ', '));
		}

		//@Deprecated
		private String buildIn(List<Id> inList) {
			return this.bracket(
					+this.QUOTE
							+ String.join(inList, this.QUOTE + ', ' + this.QUOTE)
							+ this.QUOTE
			);
		}

		//@Deprecated
		private String buildInNoQuote(List<Decimal> inList) {
			return this.bracket(String.join(inList, ', '));
		}


		//not in
		//@Deprecated
		public Condition notIn(List<SObject> inList) {
			return notIn(new Map<Id, SObject>(inList));
		}

		//@Deprecated
		public Condition notIn(Map<Id, SObject> inSet) {
			return notIn(inSet.keySet());
		}

		//@Deprecated
		public Condition notIn(Set<Id> inSet) {
			if (inSet.isEmpty()) {
				this.formedCondition = '';
				return this;
			}
			this.formedCondition = this.fieldName + ' NOT IN ' + this.buildIn(inSet);
			return this;
		}

		//@Deprecated
		public Condition notIn(QueryBuilder queryBuilder) {
			String builtSubQuery = queryBuilder.toSoqlString();
			if (String.isEmpty(builtSubQuery)) {
				this.formedCondition = '';
				return this;
			}
			this.formedCondition = this.fieldName + ' NOT IN ' + this.bracket(builtSubQuery);
			return this;
		}

		//@Deprecated
		public Condition notInCollection(Set<String> notInSet) {
			return notInCollection(new List<String>(notInSet));
		}

		//@Deprecated
		public Condition notInCollection(List<String> notInList) {
			if (notInList.isEmpty()) {
				this.formedCondition = '';
			}
			this.formedCondition = this.fieldName + ' NOT IN ' + this.buildIn(notInList);
			return this;
		}
	}

	/**
	 * Virtual class for creating Order in Query.
	 *
	 * @author github.com/4an70m
	 * @version 1.0
	 */
	public virtual class Order {

		private final String sortingField;
		private String sortingOrder;
		private String nullsOrder;

		protected Order(String sortingField, String sortingOrder, String nullsOrder) {
			this.sortingField = sortingField;
			this.sortingOrder = sortingOrder;
			this.nullsOrder = nullsOrder;
		}

		public Order(String sortingField, String sortingOrder) {
			this(sortingField, sortingOrder, '');
		}

		public Order(String sortingField) {
			this(sortingField, 'ASC', '');
		}

		public Order(SObjectField sortingField) {
			this(String.valueOf(sortingField));
		}

		public Order setSortingOrder(String sortingOrder) {
			this.sortingOrder = sortingOrder;
			return this;
		}

		public Order setSortingOrderAsc() {
			return this.setSortingOrder('ASC');
		}

		public Order setSortingOrderDesc() {
			return this.setSortingOrder('DESC');
		}

		public Order setNullsOrder(String nullsOrder) {
			this.nullsOrder = nullsOrder;
			return this;
		}

		public Order setNullsOrderFirst() {
			return this.setNullsOrder('FIRST');
		}

		public Order setNullsOrderLast() {
			return this.setNullsOrder('LAST');
		}

		public String getSortingField() {
			return this.sortingField;
		}

		public String getSortingOrder() {
			return this.sortingOrder;
		}

		public override String toString() {
			return this.sortingField
					+ ' ' + this.sortingOrder
					+ (String.isNotEmpty(this.nullsOrder) ? ' NULLS ' + this.nullsOrder : '');
		}
	}

	/**
	 * Class for ordering records Ascending.
	 *
	 * @author github.com/4an70m
	 * @version 1.0
	 */
	public class AscOrder extends Order {

		public AscOrder(String sortingField) {
			super(sortingField, 'ASC');
		}
	}

	/**
	 * Class for ordering records Descending.
	 *
	 * @author github.com/4an70m
	 * @version 1.0
	 */
	public class DescOrder extends Order {

		public DescOrder(String sortingField) {
			super(sortingField, 'DESC');
		}
	}

	public class QueryBuilderException extends Exception {
	}
}