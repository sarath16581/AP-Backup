/**
  * @author	   :
  * @date		 :
  * @description  : AP Routing service class
  * @test SSSW_Routing_Test, CaseRoutingService_Test, ChasBaseTest
--------------------------------------- History ------------------------------------------------------------------------------------
* 10.28.2020			 naseer.abbasi@auspost.com.au			Updated to cater for Strategic cases
* 2020-10-28 - Ranjeewa Silva - Refactored 'assignCasesAndDescription' to move population of description into it's own method.
* 2020-11-17 - Ranjeewa Silva - Allow Social cases to be routed based on social post tags on Case.
* 2021-03-10 - Hara Sahoo - Included getRules() within an inner class to allow all profiles(including guest users) to access the method
* 2021-06-30 - Steve Judd - Replaced getStrategicCustomerMappings with getArticleAttributesMap to return Extra Cover(Boolean) as well as isStrategic(Boolean)
* 2021-06-30 - Steve Judd - Modified assignCasesAndDescription to allow Extra Cover cases to be routed along with Strategic Cases.
* 2021-08-17 - Alex Volkov - Swapped out Automated_Network_Assignment__c for more generic ByPassRoutingRulesOnCreation__c
* 2022-11-08 - Noel Lim - major update to the logic that handles cases that are sent to async queueable to fetch the Article from SAP-EM via MyCustomerCaseArticleModule queueable.
*				a) route Cases to a holding Queue if it reaches a rule that requires an Article which is not currently in SF database.
*				b) removed logic where cases sent to async queueable are rerouted based on case values at the time it is placed in the holding Queue. Cases are now rerouted with the latest case values
*				c) fixed a bug where the AllocateToQueue__c was not checked and a case would be routed unintentionally
*				d) change of existing boolean parameter's logic and label in assignCasesAndDescription(). Parameter is now 'isFinalPass' and prevents a rerouted Case from being put in the holding queue
* 2022-12-16 - George Nguyen - added processPreferredAgentExpiry
* 2023-03-02 - Noel Lim - added logic to assign cases without a matched routing rule to a default Omni queue
* 2023-05-15 - Nathan Franklin - rejigging routing engine code and debug message tidyup
* 2024-07-16 - Ranjeewa Silva - Changes to support routing for unified cases.
**/

public class SSSW_Routing {

	/**
	 * Mapping between the SSRS_Routing field and the corresponding Case field, provides flexibility
	 * in terms of dealing with the option of adding/removing fields from the Case routing rules
	 * We could potentially put this in a custom setting or dynamically load these from the
	 * Sobject definition, at this point this degree of flexibility is not required
	 * SSSW Routing Rule Field => Case Field..
	 */
	private static final Map<String, SObjectField> fieldsMapping = new Map<String, SObjectField>{
		'Origin__c' => Case.Origin,
		'High_Level_Complaint_Flag__c' => Case.IsHLC__c,
		'EnquirySubType__c' => Case.EnquirySubType__c,
		'Customer_Recovery_Flag__c' => Case.IsCR__c,
		'CaseType__c' => Case.Type,
		'CustomerQueueType__c' => Case.Customer_Type__c,
		'ProductCategory__c' => Case.ProductCategory__c,
		'ProductSubCategory__c' => Case.ProductSubCategory__c,
		'Status__c' => Case.Status,
		'IsNew__c' => Case.IsNewForRouting__c,
		'SocialPostTags__c' => Case.SocialPostTags__c
	};

	/*
	 * Fields in method assignCasesAndDescription for routing a Case, for overriding fields in Case Selector.
	 */
	public static final Set<SObjectField> caseFieldsForRouting {
		get {
			if(caseFieldsForRouting == null) {
				caseFieldsForRouting = new Set<SObjectField>{
					Case.Id, Case.ReferenceID__c,Case.ArticleTest__c,Case.ByPassRoutingRulesOnCreation__c,
					Case.OwnerId,Case.Description,Case.AllocateToQueue__c, Case.PreferredAgentExpiry__c,Case.BusinessHoursId,Case.CaseLocality__c				
				};
				caseFieldsForRouting.addAll(fieldsMapping.values());
			}
			return caseFieldsForRouting;
		}
		private set;
	}

	private static final Set<SObjectField> ssswRoutingFieldsForRouting {
		get {
			if (ssswRoutingFieldsForRouting == null) {
				Map<String, SObjectField> fieldsMap = SSSWRouting__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap();
				Set<SObjectField> results = new Set<SObjectField>();
				for (String routingFieldName: routingFields) {
					if (fieldsMap.containsKey(routingFieldName)) {
						results.add(fieldsMap.get(routingFieldName));
					}
				}
				ssswRoutingFieldsForRouting = results;
			}
			return ssswRoutingFieldsForRouting;
		}
		set;
	}

	/**
	 * Mapping between SSSW_Routing field and the matcher to use when matching case field values.
	 * If a matcher is not specified for the SSSW_Routing field, the default "Exact Match" matcher is used.
	 */
	private static final Map<String, MatcherType> matcherTypeMapping = new Map<String, MatcherType>{
		'SocialPostTags__c' => MatcherType.ANY_EXACT_PHRASE_MATCH
	};

	/**
	 * Routing fields to use when matching
	 *
	 * IsStrategic__c doesn't have a mapped case field, instead
	 * its value is determined i.e. case->article->billingAccount.Organization.IsAPStrategicSupportCustomer
	 */
	private static final List<String> routingFields = new List<String>{
		'Origin__c',
		'High_Level_Complaint_Flag__c',
		'EnquirySubType__c',
		'Customer_Recovery_Flag__c',
		'CaseType__c',
		'CustomerQueueType__c',
		'ProductCategory__c',
		'ProductSubCategory__c',
		'Status__c',
		'IsNew__c',
		'IsStrategic__c',
		'SocialPostTags__c',
		'HasExtraCover__c'
	};

	/**
	 * NPS fields to use when matching
	 */
	private static final List<String> npsFields = new List<String>{
		'Origin__c',
		'High_Level_Complaint_Flag__c',
		'EnquirySubType__c',
		'Customer_Recovery_Flag__c',
		'CaseType__c',
		'CustomerQueueType__c',
		'ProductCategory__c',
		'ProductSubCategory__c'
	};

	/**
	 * AutoEscalation fields to use when matching
	 */
	private static final List<String> autoEscalateFields = new List<String>{
		'Origin__c',
		'High_Level_Complaint_Flag__c',
		'EnquirySubType__c',
		'Customer_Recovery_Flag__c',
		'CaseType__c',
		'CustomerQueueType__c',
		'ProductCategory__c',
		'ProductSubCategory__c'
	};
	private static final String LOC_INTERNATIONAL = 'International';
	private static final Map<String,String> CUST_TYPE_QUEUE_MAP = new Map<String,String>{
		'International' => 'SSSW_BOH_Group_1',
		'Consumer' => 'SSSW_BOH_Group_4',
		'Enterprise' => 'SSSW_BOH_Group_1',
		'SMB' => 'SSSW_BOH_Group_2',
		'Gold' => 'SSSW_BOH_Group_2',
		'MyPost Business' => 'SSSW_BOH_Group_3'
	};

	/**
	 * TODO: Only retrieve queues for Case Object.... this is pretty inefficient at the moment
	 */
	private static Map<String, Group> groupNameMap {
		get {
			if(groupNameMap == null) {
				Map<Id, Group> groupIdMap = Utility.getGroups(SSSWConstants.QUEUE);

				groupNameMap = new Map<String, Group>();
				for (Group grp : groupIdMap.values()) {   // fetch queues to create group map
					groupNameMap.put(grp.DeveloperName, grp);
				}
			}
			return groupNameMap;
		}
		set;
	}

	/* Date Modified: 22/06/2021
	 * Removed - using articleWrapper instead
	 * Stores a cached mapping of the existing articles already queried and their mappings to whether they are Extra Cover or not
	 * Key is Article__c.ArticleID__c
	 * Value is true/ false i.e. Strategic Support Customer or not.
	 */

	// private static Map<String, Boolean> strategicCustomerMappings = new Map<String, Boolean>();

	/**
	 * Date added: 22/06/2021
	 * Map for storing linked articles and article attributes for determining strategic customers and Extra cover articles
	 * Neither of these attributes has a case field to map to. Key is referenceId
	 */
	private static  Map<String, ArticleAttributes> articleAttributesMap = new Map<String, ArticleAttributes>();

	// Avoid Description change from Reassign Button
	public static Boolean reassignDescription = false;

	// Avoid Queue Check change from Reassign Button
	public static Boolean reassignNoCheckOwnerQueue = false;

	/**
	  * @description	   This inner class is created to allow guest user profiles access the getRules() method.
						   This would help cases created by guest users to have the case description populated 
						   by retrieving the rules set in the SSSW_Routing object.
	  *					As due to critical update “Secure Object Permissions for Guest Users”
	  *					guest users can’t have more than read access.
	*/
	private without sharing class GetRulesForAllProfiles {
		
		public List<SSSWRouting__c> getRules(Set<String> recordTypeDeveloperNames) {

			Set<SObjectField> fieldOverrides = new Set<SObjectField>{
					SSSWRouting__c.Sequence__c, SSSWRouting__c.Match_Rules_On__c, SSSWRouting__c.NPS_criteria__c, SSSWRouting__c.AutoEscalate__c,
					SSSWRouting__c.Queue_ID__c, SSSWRouting__c.DefaultCaseDetails__c, SSSWRouting__c.RuleRequiresArticleAttributes__c,
					SSSWRouting__c.PreferredAgentExpiry__c
			};
			fieldOverrides.addAll(ssswRoutingFieldsForRouting);

			return ((SSSWRoutingSelector)SSSWRoutingSelector.newInstance().setFieldOverrides(fieldOverrides)).search(new Map<String, Object>{
					'recordtypeDeveloperNames' => recordTypeDeveloperNames,
					'isActive' => true,
					'matchRulesOn' => new Set<String>{'ANY', 'ALL'}
			}, new Set<Object>{SSSWRoutingSelector.Options.WITH_RECORDTYPE}, true);
		}
	}
	

	public static boolean processAny(Case cs, SSSWRouting__c rule, List<String> matchingFields) {

		String referenceId = (String.isEmpty(cs.ReferenceID__c) ? '' : cs.ReferenceID__c.toLowerCase());
		Boolean ruleMatched = false;

		for (String matchingField : matchingFields) {
			String ruleValues = rule.get(matchingField) != null && !String.isEmpty(String.valueOf(rule.get(matchingField))) ? String.valueOf(rule.get(matchingField)) : '';
			// get the case value, defaults to empty String
			String caseValue;

			String caseFieldName = fieldsMapping.get(matchingField)?.getDescribe().getName();

			/**
			 * Modified 2021-06-30 changed to use articleAttributesMap
			 * IsStrategic doesn't have a corresponding case field defined in the routing mappings
			 * HasExtraCover also does not have a corresponding case field defined in the routing mappings
			 * IsStrategic value is determined by a static defined articleAttributesMap.isStrategic
			 * Has ExtraCover is determined by a static defined articleAttributesMap.hasExtraCover
			 */
			if(!matchingField.equalsIgnoreCase('IsStrategic__c') && !matchingField.equalsIgnoreCase('HasExtraCover__c')) {
				caseValue = caseFieldName != null && !String.isEmpty(String.valueOf(cs?.get(caseFieldName))) ? String.valueOf(cs.get(caseFieldName)) : '' ;
			} else if(matchingField.equalsIgnoreCase('IsStrategic__c') && articleAttributesMap.get(referenceId) != null ) {
				caseValue = (!String.isEmpty(String.valueOf(articleAttributesMap.get(referenceId).isStrategic)) ? String.valueOf(articleAttributesMap.get(referenceId).isStrategic) : '');
			} else if(matchingField.equalsIgnoreCase('HasExtraCover__c') && articleAttributesMap.get(referenceId) != null ) {
				caseValue = (!String.isEmpty(String.valueOf(articleAttributesMap.get(referenceId).hasExtraCover)) ? String.valueOf(articleAttributesMap.get(referenceId).hasExtraCover) : '');
			}

			if(ruleValues != null && ruleValues != '' && ruleValues != 'false') {
				for (String ruleValue : (String.valueOf(ruleValues)).split(SSSWRoutingController.MULTI_SELECT_DELIM)) {
					if (valueMatches(matchingField, caseValue, ruleValue)) {
						ruleMatched = true;
						break;
					}
				}
			}
		}
		
		return ruleMatched;
	}

	public static boolean processAll(Case cs, SSSWRouting__c rule, List<String> matchingFields) {
		String referenceId = (String.isEmpty(cs.ReferenceID__c) ? '' : cs.ReferenceID__c.toLowerCase());
		Map<String, Boolean> valueMatches = new Map<String, Boolean>();

		for (String matchingField : matchingFields) {
			// in some cases this will be a comma sparated list
			String ruleValues = (!String.isEmpty(String.valueOf(rule.get(matchingField))) ? String.valueOf(rule.get(matchingField)) : '');

			// get the case value, defaults to empty String
			String caseValue;


			String caseFieldName = fieldsMapping.get(matchingField)?.getDescribe().getName();

			/**
			 * IsStrategic doesn't have a corresponding case field defined in the routing mappings
			 * Its value is determined by a static defined 'articleAttributesMap' Map
			 * Modified 21/6/2021: HasExtraCover__c is defined in 'extraCoverArticleMappings' Map
			 */
			if(!matchingField.equalsIgnoreCase('IsStrategic__c') && !matchingField.equalsIgnoreCase('HasExtraCover__c')) {
				caseValue = caseFieldName != null && !String.isEmpty(String.valueOf(cs?.get(caseFieldName))) ? String.valueOf(cs.get(caseFieldName)) : '' ;
			} else if(matchingField.equalsIgnoreCase('IsStrategic__c') && articleAttributesMap.get(referenceId) != null ) {
				caseValue = (!String.isEmpty(String.valueOf(articleAttributesMap.get(referenceId).isStrategic)) ? String.valueOf(articleAttributesMap.get(referenceId).isStrategic) : '');
			} else if(matchingField.equalsIgnoreCase('HasExtraCover__c') && articleAttributesMap.get(referenceId) != null ) {
				caseValue = (!String.isEmpty(String.valueOf(articleAttributesMap.get(referenceId).hasExtraCover)) ? String.valueOf(articleAttributesMap.get(referenceId).hasExtraCover) : '');
			}
			if(ruleValues != null && ruleValues != '' && ruleValues != 'false') {

				for (String ruleValue : (String.valueOf(ruleValues)).split(SSSWRoutingController.MULTI_SELECT_DELIM)) {
					if (valueMatches(matchingField, caseValue, ruleValue)) {
						valueMatches.put(matchingField, true);
						break;
					} else {
						valueMatches.put(matchingField, false);
					}
				}
			}
		}

		Boolean ruleMatched = false;
		if(valueMatches.values().size() > 0) {
			ruleMatched = true;
			for (Boolean b : valueMatches.values()) {
				if(!b) {
					ruleMatched = false;
					break;
				}
			}
		}
		
		return ruleMatched;
	}

	/**
	 * Checks if the field value match the rule value based on the matcher type defined for the SSSW_Routing field.
	 *
	 * @param fieldName SSSW_Routing field. Determines the matcher to use.
	 * @param fieldValue Field value specified in the case field.
	 * @param ruleValue SSSW_Routing rule value to match
	 *
	 * @return true if match succefful, false otherwise.
	 */
	@TestVisible private static Boolean valueMatches(String fieldName, String fieldValue, String ruleValue) {
		if  (matcherTypeMapping.get(fieldName) == MatcherType.ANY_EXACT_PHRASE_MATCH) {
			String regex = '(?i)(:?^|,)(' + ruleValue.trim() + ')(:?$|,)';
			return (Pattern.compile(regex).matcher(fieldValue).find());
		}

		// No special matcher types defined for the field. Use the default - exact match.
		return ruleValue.trim().equalsIgnoreCase(fieldValue);
	}

	/**
	 * Method overridden, see next method.
	 */
	public static void assignCasesAndDescription(list<Case> cases, Map<Id,Case> oldMap, Boolean isInsert) {
		assignCasesAndDescription(cases, oldMap, isInsert, false, false);
	}

	/**
	 * Modified 2021-06-30 steve.judd6@auspost.com.au now caters for Has Extra Cover routing
	 * Method serves below on the basis of rules defined in the SSSWRouting object.
	 * 1. to route cases to the right Queue based on Routing rules
	 * 2. to set Description on cases based on Description rules
	 *
	 *
	 * Strategic Customer Cases have (Organization.IsStrategicSupportCustomer = true)
	 * Extra Cover cases have ArticleTest.Article__c.Insurance_Amount__c > 0 && Article.MLID__c = null.
	 * Routing engine skips routing in beforeInsert if:
	 * 1. Rule is IsStrategic or hasExtraCover
	 * 2. ArticleTest__c is null
	 * Such cases to be re-routed once the ArticleTest__c gets populated in After Insert.
	 *
	 * H&S cases tracked via Automated_Network_Assignment__c flag to skip the routing
	 * H&S will set ByPassRoutingRulesOnCreation__c flag for direct assignment
	 *
	 * @param skipDescriptionRules is meant to skip Description Rules and used only in context of Strategic cases
	 * @param isFinalPass If routing was deferred because a rule was trigger that required article attributes, the second time routing is called from the MyCustomersCaseArticleModule, this flag will be true
	 *					It implies that on final pass, if the article exists and is linked to a case, the rule can be processed, if the article does not exist (error quering sap-em or not found), then skip the article rule and move to the next
	 *
	 */
	public static void assignCasesAndDescription(list<Case> cases, Map<Id,Case> oldMap, Boolean isInsert, Boolean skipDescriptionRules, Boolean isFinalPass) {
		String recType = SSSWConstants.RECTYPEROUTING + '\' OR RecordType.DeveloperName=\'' + SSSWConstants.RECTYPEDESCRIPTION;

		//Replacing it with GetRulesForAllProfiles
		//List<SSSWRouting__c> rules = getRules(recType);
		GetRulesForAllProfiles obj = new GetRulesForAllProfiles ();
		List<SSSWRouting__c> rules = obj.getRules(new Set<String>{
				SSSWConstants.RECTYPEROUTING, SSSWConstants.RECTYPEDESCRIPTION, SSSWConstants.SSSWROUTING_RECTYPE_UNIFIEDROUTING
		});

		List<SSSWRouting__c> routeRule = new List<SSSWRouting__c>();
		List<SSSWRouting__c> descRule = new List<SSSWRouting__c>();
		List<SSSWRouting__c> unifiedRoutingRules = new List<SSSWRouting__c>();
		for(SSSWRouting__c rule : rules){
			if(rule.DefaultCaseDetails__c != '' && rule.RecordType.DeveloperName == SSSWConstants.RECTYPEDESCRIPTION) {
				descRule.add(rule);
			} else if (String.isNotBlank(rule.Queue_ID__c) && rule.RecordType.DeveloperName == SSSWConstants.RECTYPEROUTING) {
				routeRule.add(rule);
			} else if (String.isNotBlank(rule.Queue_ID__c) && rule.RecordType.DeveloperName == SSSWConstants.SSSWROUTING_RECTYPE_UNIFIEDROUTING) {
				unifiedRoutingRules.add(rule);
			}
		}
		// system caches mapping for cases articles(based on ReferenceID__c) to strategic customers
		// Where strategic customer value is determined by Organization.IsStrategicSupportCustomer
		// skipDescriptionRules explicitly gets set from queueable in MyCustomerCaseArticleModule
		// Where we are re-attempting to route the cases that have Article linked to them
		Set<String> referenceIds = new Set<String>();
		for(Case c : cases) {
			if(!String.isEmpty(c.ReferenceID__c)) {
				referenceIds.add(c.ReferenceID__c);
			}
		}

		if(!referenceIds.isEmpty()) {
			getArticleAttributesMap(referenceIds);		 
		}

		OmniChannelService omniService = OmniChannelService.getInstance();

		for (Case cs : cases) {
			Id routingOwner; 
			Case oldCase = oldMap != null ? oldMap.get(cs.Id) : null;

			Boolean isUnifiedCase = CaseRoutingService.unifiedRecordTypeIds.contains(cs.RecordTypeId);
			
			// we only want to process the routing rules in these scenarios:
			// 1. if the case is being reassigned (through the ui) - CaseDetails page
			// 2. If a reroute is triggered by setting allocatetoqueue__c = true)
			// 3. routing rules are not being bypassed on creation (when the caller already knows the queue the case should be assigned to... there is automation in the system that still seems to set allocatetoqueue__c so we use ByPassRoutingRulesOnCreation__c to override it)
			if(reassignNoCheckOwnerQueue || (cs.AllocateToQueue__c != null && cs.AllocateToQueue__c == true)) {
				Boolean routingRuleMatched = false;

				for (SSSWRouting__c rule : (isUnifiedCase ? unifiedRoutingRules : routeRule)) {
					
					if (rule.Match_Rules_On__c.equals('ANY')) {

						// Ensuring cases follow the default routing logic if rule is not Strategic
						// Also ensuring incase of a Strategic rule (ordered by sequence__c and ArticleID isn't present),
						// then skip such cases for later queue assignment since ArticleId gets determined later in the context.
						// We will check for Article Id in SF once in beforeInsert (in MyCustomerCaseArticlesModule),
						// if found in SF, system will make an explicit call to assignCasesAndDescription() to find the queue.
						// if not found in SF, system to search SAP-EM in afterInsert (queueable in MyCustomerCaseArticlesModule),
						// if found in SAP-EM, explicit call to assignCasesAndDescription() to find the queue
						//TODO: have to set AllocateToQueue = false for portal cases
						// Network cases to be skipped from routing in Insert Context
						if (!rule.RuleRequiresArticleAttributes__c || (rule.RuleRequiresArticleAttributes__c && cs.ArticleTest__c != null)) {
							if (processAny(cs, rule, routingFields)) {
								routingOwner = rule.Queue_ID__c;

								// set the new owner
								setRoutingCaseOwner(cs, routingOwner, rule.Id);

								// setting flag on case since selected routing rule is a strategic one
								// its required to avoid triggering the specific workflow rules that might reset the case owner
								cs.LastRoutingRuleIsStrategic__c = rule.RuleRequiresArticleAttributes__c ? true : false;

								// this is set here since the value is derived from the routing rule
								processPreferredAgentExpiry(cs, oldCase, rule, isFinalPass);

								routingRuleMatched = true;

								break;
							}

						} else if (rule.RuleRequiresArticleAttributes__c && cs.ArticleTest__c == null && !isFinalPass && !String.isEmpty(cs.ReferenceID__c)) {

							//Assign the case to a holding queue. This case will be processed in a queueable which will fetch the Article data and then perform a re-route to move it out of the holding queue
							setRoutingCaseOwner(cs, omniService.omniHoldingQueueId, rule.Id);

							routingRuleMatched = true;

							break;
						}
					} else if (Rule.Match_Rules_On__c.equals('ALL')) {

						// Ensuring cases follow the default routing logic if rule is not Strategic
						// Also ensuring incase of a Strategic rule (ordered by sequence__c and ArticleID isn't present),
						// then skip such cases for later queue assignment since ArticleId gets determined later in the context.
						// We will check for Article Id in SF once in beforeInsert (in MyCustomerCaseArticlesModule),
						// if found in SF, system will make an explicit call to assignCasesAndDescription() to find the queue.
						// if not found in SF, system to search SAP-EM in afterInsert (queueable in MyCustomerCaseArticlesModule),
						// if found in SAP-EM, explicit call to assignCasesAndDescription() to find the queue
						//TODO: have to set AllocateToQueue = false for portal cases
						// Network cases to be skipped from routing in Insert context
						if (!rule.RuleRequiresArticleAttributes__c || (rule.RuleRequiresArticleAttributes__c && cs.ArticleTest__c != null)) {
							if (processAll(cs, rule, routingFields)) {

								routingOwner = rule.Queue_ID__c;

								// set the new owner
								setRoutingCaseOwner(cs, routingOwner, rule.Id);

								// setting flag on case since selected routing rule is a strategic one
								// its required to avoid triggering the specific workflow rules that might reset the case owner
								cs.LastRoutingRuleIsStrategic__c = rule.RuleRequiresArticleAttributes__c ? true : false;

								// this is set here since the value is derived from the routing rule
								processPreferredAgentExpiry(cs, oldCase, rule, isFinalPass);

								routingRuleMatched = true;

								break;
							}

							// Cases being created from H&S can be routed direct to network (currently via a queueable)
							// In this scenario we ignore any strategic routing checks
						} else if (rule.RuleRequiresArticleAttributes__c && cs.ArticleTest__c == null && !isFinalPass && !String.isEmpty(cs.ReferenceID__c)) {

							//Assign the case to a holding queue. This case will be processed in a queueable which will fetch the Article data and then perform a re-route to move it out of the holding queue
							setRoutingCaseOwner(cs, omniService.omniHoldingQueueId, rule.Id);

							routingRuleMatched = true;

							break;
						}
					}
				}

				if(!routingRuleMatched) {
					System.debug('DEFAULT ROUTING RULE TRIGGERED!');
					setRoutingCaseOwner(cs, (isUnifiedCase ? omniService.omniUnifiedDefaultQueueId : omniService.omniDefaultQueueId), null);

					if (isUnifiedCase) {
						// for unified cases, a default preferred agent expiry is configured. this is to support
						// routing to be evaluated for unified cases in H1 where only one default omni queue is used along with a
						// default agent expiry.
						processPreferredAgentExpiry(cs, oldCase, null, isFinalPass);
					}

					// debug messaging to inform admin of routing path
					CaseRoutingService.getInstance().populateRoutingDebug(cs, 'default routing rule hit!');
				}

			}

			// skipDescriptionRules is false for cases in the normal context
			// its only set to true in re-routing context for Strategic cases
			if(!skipDescriptionRules) {
				//Evaluating description rules and set description field on case
				setCaseDescription(cs, oldCase, descRule);
			}
		}
	}

	/*
	* This method will set the PreferredAgentExpiry__c field on the case only if it is blank AND the oldCase was blank AND the rule has PreferredAgentExpiry__c set. 
	* NOTE: 
	* There is a batch that checks for PSRs against the Case.PreferredAgentExpiry__c and it will set this field to null if it has expired. 
	* It will then push the case through the normal routing by setting the Case.AllocateToQueue__c = true and will set the Case.PreferredAgentExpiry__c = null. 
	* This check is required so this field is not set to a new date. 
	*
	* IsFinalPass flag is passed in because AsyncLinkArticlesToCasesQueueable calls assignCasesAndDescription() with oldCase as null
	*/
	@TestVisible
	private static void processPreferredAgentExpiry(Case cs, Case oldCase, SSSWRouting__c rule, Boolean isFinalPass) {
		if(cs.PreferredAgentExpiry__c == null &&
				(isFinalPass || (oldCase != null && oldCase.PreferredAgentExpiry__c == null)) && 
				cs.BusinessHoursId != null &&
				(rule?.PreferredAgentExpiry__c != null || (CaseRoutingService.unifiedRecordTypeIds.contains(cs.RecordTypeId) && OmniChannelService.omniUnifiedPreferredAgentExpiry != null))) {

			Decimal preferredAgentExpiryInHours = (rule?.PreferredAgentExpiry__c != null ? rule.PreferredAgentExpiry__c : OmniChannelService.omniUnifiedPreferredAgentExpiry);
			cs.PreferredAgentExpiry__c = BusinessHours.add(cs.BusinessHoursId, Datetime.now(), preferredAgentExpiryInHours.longValue() * 3600000);
		}
	}

	@TestVisible
	private static Boolean setRoutingCaseOwner(case cs, Id routingOwner){
		return setRoutingCaseOwner(cs, routingOwner, null);
	}

	@TestVisible
	private static Boolean setRoutingCaseOwner(case cs, Id routingOwner, Id ruleId) {

		Boolean isHoldingQueue = OmniChannelService.getInstance().omniHoldingQueueId == routingOwner;

		String queueKey = LOC_INTERNATIONAL.equalsIgnoreCase(cs.CaseLocality__c) ?
							LOC_INTERNATIONAL : cs.Customer_Type__c;
		cs.OwnerId = (routingOwner != null) ? routingOwner : (String.isNotBlank(queueKey) && groupNameMap.containsKey(CUST_TYPE_QUEUE_MAP.get(queueKey))) ?
																	groupNameMap.get(CUST_TYPE_QUEUE_MAP.get(queueKey)).Id : cs.OwnerId;
		cs.AllocateToQueue__c = false;	 // disable case queue allocation

		// debug messaging to inform admin of routing path
		CaseRoutingService.getInstance().populateRoutingDebug(cs, (isHoldingQueue ? 'routing deferred: rule id: ' + ruleId : 'routed: ' + cs.OwnerId + ' rule id: ' + ruleId) + (reassignNoCheckOwnerQueue ? ' (reassignment)' : ''));

		return true;
	}

	public static void applyNPSRules(List<Case> cases) {
		//Replacing it with GetRulesForAllProfiles
		//List<SSSWRouting__c> rules = getRules(SSSWConstants.RECTYPENPS);
		GetRulesForAllProfiles obj = new GetRulesForAllProfiles ();
		List<SSSWRouting__c> rules = obj.getRules(new Set<String>{SSSWConstants.RECTYPENPS});
		Boolean ruleFound = false; //Check if rule exist else set NPS details
		DateTime currentTime = Datetime.now();
		System.debug('NPS rules--->'+rules);
		for (Case cs : cases) {
			System.debug('cs.closedDate--->'+ cs.closedDate);
			for (SSSWRouting__c rule : rules) {
				if(Rule.Match_Rules_On__c.equals('ANY')) {
					System.debug(LoggingLevel.ERROR,'**Processing ANY rule NPS');
					if(processAny(cs, rule, npsFields)) {
						ruleFound = true;
						//cs.NPSRequired__c = rule.NPS_criteria__c == 'Exclude' ? false : true;
						if(rule.NPS_criteria__c != 'Exclude') {
							// set the NPS specific values and use  Bypass_Data_enforcement__c to ensure no validation errors will occur during the update
							cs.NPSScheduledDate__c = currentTime.AddDays(1);
							cs.NPSAgent__c = cs.LastModifiedById; // set NPS agent as last modified user
							//cs.Bypass_Data_enforcement__c = true;  // by pass validation
						}
						break;
					}
				} else if(Rule.Match_Rules_On__c.equals('ALL')) {
					System.debug(LoggingLevel.ERROR,'**Processing ALL rule NPS');
					if(processAll(cs, rule, npsFields)) {
						ruleFound = true;
						// cs.NPSRequired__c = rule.NPS_criteria__c == 'Exclude' ? false : true;
						if(rule.NPS_criteria__c != 'Exclude'){
							// set the NPS specific values and use  Bypass_Data_enforcement__c to ensure no validation errors will occur during the update
							cs.NPSScheduledDate__c = currentTime.AddDays(1);
							cs.NPSAgent__c = cs.LastModifiedById; // set NPS agent as last modified user
							//cs.Bypass_Data_enforcement__c = true;  // by pass validation
						}
						break;
					}
				}
			}
			//Set default value if no rule found
			if(!ruleFound){
				System.debug('Set default value if no rule found--->');
				cs.NPSScheduledDate__c = currentTime.AddDays(1);
				cs.NPSAgent__c = cs.LastModifiedById; // set NPS agent as last modified user
				//cs.Bypass_Data_enforcement__c = true;  // by pass validation
			}
		}
	}

	public static Boolean checkAutoEscalate(Case cs) {
		Boolean retValue = false;
		//Replacing it with GetRulesForAllProfiles
		//List<SSSWRouting__c> rules = getRules(SSSWConstants.RECTYPEESCALATION);
		GetRulesForAllProfiles obj = new GetRulesForAllProfiles ();
		List<SSSWRouting__c> rules = obj.getRules(new Set<String>{SSSWConstants.RECTYPEESCALATION});
		DateTime currentTime = Datetime.now();
		for (SSSWRouting__c rule : rules) {
			if(Rule.Match_Rules_On__c.equals('ANY')) {
				System.debug(LoggingLevel.ERROR,'**Processing ANY rule Escalate');
				if(processAny(cs, rule, autoEscalateFields)) {
					retValue = rule.AutoEscalate__c;
					break;
				}
			} else if(Rule.Match_Rules_On__c.equals('ALL')) {
				System.debug(LoggingLevel.ERROR,'**Processing ALL rule Escalate');
				if(processAll(cs, rule, autoEscalateFields)) {
					retValue = rule.AutoEscalate__c;
					break;
				}
			}
		}
		return retValue;
	}

	/**
	* Modified 22/6/2021: changed from returning single map to return multiple article
	* attributes
	* Determine if the Customer related to an article is a Strategic Support Customer
	* @param - Set of case key i.e. Reference Id
	* @return - Maps of ReferenceId and ArticleAttributes (Boolean  IsStrategicSupportCustomer__c i.e. True/False
	* and Boolean for HasExtraCover i.e. True/False)
	 */
	public static Map<String, ArticleAttributes> getArticleAttributesMap(Set<String> referenceIdSet) {

		Set<String> queryableReferenceIds = new Set<String>(referenceIdSet);

		queryableReferenceIds.removeAll(articleAttributesMap.keySet());

		if(!queryableReferenceIds.isEmpty()) {
			SSSWCaseRelatedData obj = new SSSWCaseRelatedData();
			List<Article__c> articles = obj.getArticles(queryableReferenceIds);
			
			for(Article__c a : articles) {
				ArticleAttributes attributes = new ArticleAttributes();
				// initialise values to false
				attributes.isStrategic = false;
				if(!String.isEmpty(a.ArticleID__c) && a.Billing_Account__r != null && a.Billing_Account__r.Organisation__r != null && a.Billing_Account__r.Organisation__r.IsStrategicSupportCustomer__c !=  null) {
					attributes.isStrategic = a.Billing_Account__r.Organisation__r.IsStrategicSupportCustomer__c;
				}
				attributes.hasExtraCover = a.HasExtraCover__c;
				articleAttributesMap.put(a.ArticleID__c.toLowerCase(), attributes);
			}
		}
		system.debug('articleAttributesMap'+articleAttributesMap);
		return articleAttributesMap;
	}

	/**
	 *
	 * @param - N/A
	 * @return - N/A
	 */
	public static void FlipReassignDescription() {
		reassignDescription = true;
	}

	/**
	 * Get the defined SSSWRouting fields to Case field mappings
	 * @param - N/A
	 * @return - Map of SSSWRouting to Case fields
	 */
	public static Map<String, SObjectField> getFieldsMapping() {
		return fieldsMapping;
	}

	/**
	 * Populate 'Description' field on the cases passed on based on the rules in SSSWRouting__c records.
	 * All description case rules have 'SSSWDescription' record type.
	 *
	 * @param cases list of case records to populate description
	 * @param oldMap  old versions of case records if records are updated. Pass null otherwise.
	 */
	public static void populateCaseDescriptionFromDescriptionRules(List<Case> cases, Map<Id,Case> oldMap) {

		// Replacing it with GetRulesForAllProfiles
		//List<SSSWRouting__c> rules = getRules(SSSWConstants.RECTYPEDESCRIPTION);
		GetRulesForAllProfiles obj = new GetRulesForAllProfiles ();
		List<SSSWRouting__c> rules = obj.getRules(new Set<String>{SSSWConstants.RECTYPEDESCRIPTION});
		List<SSSWRouting__c> descRule = new List<SSSWRouting__c>();
		for(SSSWRouting__c rule : rules){
			if(rule.DefaultCaseDetails__c!='' && rule.recordtype.developerName == SSSWConstants.RECTYPEDESCRIPTION){
				descRule.add(rule);
			}
		}

		for (Case cs : cases) {
			Case oldCase = oldMap != null ? oldMap.get(cs.Id) : null;
			setCaseDescription(cs, oldCase, descRule);
		}
	}

	/**
	 * Evaluate description rules passed in and populate case description based on the rules.
	 * Code orginally in assignCasesAndDescription() moved into a own method to promote reuse.
	 *
	 * @param newCase case record to populate description
	 * @param oldCase old version of case record if case is updated. Pass null otherwise.
	 * @param descriptionRules list of description rules (SSSWRount__c) to evaluate
	 */
	private static void setCaseDescription(Case newCase, Case oldCase, List<SSSWRouting__c> descriptionRules) {

		//NOTE - Code initially in assignCasesAndDescription(). Moved here for re-use.

		for(SSSWRouting__c rule : descriptionRules){
			if(rule.Match_Rules_On__c.equals('ANY')) {
				System.debug(LoggingLevel.ERROR,'**Processing ANY rule');
				if(processAny(newCase, rule, routingFields) && (String.isBlank(newCase.Description) || oldCase == null) && !reassignDescription){
					System.debug(LoggingLevel.ERROR,'Inside ANY rule Description--->'+rule);
					newCase.Description = (newCase.Description !=null && !String.isEmpty(newCase.Description)?newCase.Description +'\n' :'')
							+ (rule.DefaultCaseDetails__c!=null &&!String.isEmpty(rule.DefaultCaseDetails__c) ? rule.DefaultCaseDetails__c:'');
					break;
				}
			} else if(Rule.Match_Rules_On__c.equals('ALL')) {
				System.debug(LoggingLevel.ERROR,'Inside ALL rule Description--->'+rule);
				if(processAll(newCase, rule, routingFields) && (String.isBlank(newCase.Description) || oldCase == null) && !reassignDescription){
					newCase.Description = (newCase.Description !=null && !String.isEmpty(newCase.Description)?newCase.Description +'\n' :'')
							+ (rule.DefaultCaseDetails__c!=null &&!String.isEmpty(rule.DefaultCaseDetails__c) ? rule.DefaultCaseDetails__c:'');
					break;
				}
			}
		}
	}
	
	/**
	 * @description
	 * Inner class for the Strategic Customer routing requirement.
	 * Specifically required for DDC Consumer Community Users creating/reading Articles.
	 */
	public without sharing class SSSWCaseRelatedData {
		private List<Article__c> articleList;

		public SSSWCaseRelatedData() {
			articleList = new List<Article__c>();
		}
	
		/**
		 * Get Articles by tracking ids
		 * @param - Set of String i.e Referernce Ids
		 * @return - Article list
		 */
		public List<Article__c> getArticles(Set<String> queryableReferenceIds) {
			Map<SObjectType, Set<SObjectField>> fieldOverrides = new Map<SObjectType, Set<SObjectField>>{
				Article__c.SObjectType => new Set<SObjectField>{Article__c.Id, Article__c.ArticleID__c, Article__c.MLID__c, Article__c.InsuranceAmount__c, Article__c.HasExtraCover__c},
				Billing_Account__c.SObjectType => new Set<SObjectField>(),
				Account.SObjectType => new Set<SObjectField>{Account.IsStrategicSupportCustomer__c}
			};
	
			articleList = ArticlesSelector.newInstance(0, fieldOverrides).selectByTracking(queryableReferenceIds, new Set<Object>{
				ArticlesSelector.Options.WITH_BILLINGACCOUNT, BillingAccountsSelector.Options.WITH_ORGANISATION
			}, false).values();
			
			System.debug('articles >>'+articleList);
			return articleList;
		}
	}

	private enum MatcherType {
		EXACT_MATCH, // case field value should exactly match the SSSW rule field value (case insensitive).
		ANY_EXACT_PHRASE_MATCH // SSSW_Rule field value (word or a phrase) should match any one phrase in a comma separated list of phrases in the case field value.
	}
	/**
	 * Holds Booleans for isStrategic and HasExtraCover
	 */
	@TestVisible
	public class ArticleAttributes {
		public Boolean isStrategic {get; set;}
		public Boolean hasExtraCover {get; set;}
	}

	 /**
	 * Generic Error Exception 
	 */
	@TestVisible
	private class ErrorException extends Exception { }
}