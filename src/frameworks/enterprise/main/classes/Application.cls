/***
 * @author Nathan Franklin
 * @date 2020-04-10
 * @group Tests
 * @tag Utility
 * @domain Core
 * @description This is the handler for class interaction within the application
				This class is predominately used to enable proper test class mocking
 * @changelog
 * 2020-04-10 - Nathan Franklin - Created
 * 2020-08-02 - Nathan Franklin - Added methods for Domain classes
 * 2022-12-07 - Noel Lim		- Added Cache variables queuesWithRoutingConfig, queueIdVsRoutingConfig
 */
public with sharing class Application {

	public static UtilityFactory Utilities;
	public static SelectorFactory Selectors;
	public static DomainFactory Domains;
	public static ProfileFactory Profiler;

	static {
		Utilities = new UtilityFactory();
		Selectors = new SelectorFactory();
		Domains = new DomainFactory();
		Profiler = new ProfileFactory();
	}

	public static CacheFactory Cache {
		get {
			if(Cache == null) {
				Cache = new CacheFactory();
			}
			return Cache;
		}
		private set;
	}

	public class CacheFactory {

		@TestVisible 
		void resetStaticVariablesForUnitTestOnly() {
			organizationInfo = null;
			CacheManager.put('ORGANISATION_INFO', null);
			profileIds = null;
			CacheManager.put('ALL_PROFILE_IDS', null);
			serviceChannels = null;
			CacheManager.put('ALL_SERVICE_CHANNELS', null);
			queueIdVsRoutingConfig = null;
			CacheManager.put('QUEUE_TO_ROUTING_CONFIG', null);
			queuesWithRoutingConfig = null;
			CacheManager.put('QUEUES_WITH_ROUTING_CONFIG', null);
		}

		public OrganizationWrapper organizationInfo {
			get {
				if(organizationInfo == null) {
					organizationInfo = (OrganizationWrapper)CacheManager.get('ORGANISATION_INFO');
					if(organizationInfo == null) {
						organizationInfo = new OrganizationWrapper([SELECT Name, IsSandbox, InstanceName FROM Organization LIMIT 1]);
						CacheManager.put('ORGANISATION_INFO', organizationInfo);
					}
				}
				return organizationInfo;
			}
			private set;
		}	
	
		public Map<String, Id> profileIds {
			get {
				if(profileIds == null) {
					profileIds = (Map<String, Id>)CacheManager.get('ALL_PROFILE_IDS');
					if(profileIds == null) {
						profileIds = new Map<String, Id>();
						for(Profile p: [SELECT Name FROM Profile]) {
							profileIds.put(p.Name, p.Id);
						}
						CacheManager.put('ALL_PROFILE_IDS', profileIds);
					}
				}
				return profileIds;
			}
			private set;
		}

		public Map<String, ServiceChannel> serviceChannels {
			get {
				if(serviceChannels == null) {
					serviceChannels = (Map<String, ServiceChannel>)CacheManager.get('ALL_SERVICE_CHANNELS');
					if(serviceChannels == null) {
						serviceChannels = new Map<String, ServiceChannel>();
						for(ServiceChannel sc: [SELECT AfterConvoWorkMaxTime,DeveloperName,DoesMinimizeWidgetOnAccept,HasAfterConvoWorkTimer,RelatedEntity,SecRoutingPriorityField FROM ServiceChannel]) {
							serviceChannels.put(sc.DeveloperName, sc);
						}
						CacheManager.put('ALL_SERVICE_CHANNELS', serviceChannels);
					}
				}
				return serviceChannels;
			}
			private set;
		}

		public Map<Id, Group> queuesWithRoutingConfig {
			get {
				if(queuesWithRoutingConfig == null) {
					queuesWithRoutingConfig = (Map<Id, Group>)CacheManager.get('QUEUES_WITH_ROUTING_CONFIG');
					if(queuesWithRoutingConfig == null) {
						queuesWithRoutingConfig = new Map<Id, Group>();
						for(Group queue: [SELECT Id, DeveloperName, QueueRoutingConfigId FROM Group WHERE Type = 'Queue' AND QueueRoutingConfigId != NULL]) {
							queuesWithRoutingConfig.put(queue.Id, queue);
						}
						CacheManager.put('QUEUES_WITH_ROUTING_CONFIG', queuesWithRoutingConfig);
					}
				}
				return queuesWithRoutingConfig;
			}
			private set;
		}

		public Map<Id, QueueRoutingConfig> queueIdVsRoutingConfig {
			get {
				if(queueIdVsRoutingConfig == null) {
					queueIdVsRoutingConfig = (Map<Id, QueueRoutingConfig>)CacheManager.get('QUEUE_TO_ROUTING_CONFIG');
					if(queueIdVsRoutingConfig == null) {
						queueIdVsRoutingConfig = new Map<Id, QueueRoutingConfig>();

						Set<Id> queueRoutingConfigIds = new Set<Id>();	
						for(Group queue : queuesWithRoutingConfig.values()){
							queueRoutingConfigIds.add(queue.QueueRoutingConfigId);
						}

						if(queueRoutingConfigIds.isEmpty() == false){
							List<QueueRoutingConfig> routingConfigs = [SELECT Id, CapacityPercentage, CapacityWeight, DropAdditionalSkillsTimeout, IsAttributeBased, OverflowAssigneeId, 
																PushTimeout, RoutingModel, RoutingPriority, DeveloperName FROM QueueRoutingConfig];
							for(Group queue : queuesWithRoutingConfig.values()){
								for(QueueRoutingConfig routingConfig : routingConfigs){
									if(queue.QueueRoutingConfigId == routingConfig.Id){
										queueIdVsRoutingConfig.put(queue.Id, routingConfig);
									}
								}					
							}
						}		
						CacheManager.put('QUEUE_TO_ROUTING_CONFIG', queueIdVsRoutingConfig);
					}
				}
				return queueIdVsRoutingConfig;
			}
			private set;
		}
	}

	public class OrganizationWrapper {
		public Boolean isSandbox {get; private set;}
		public String sandboxName {get; private set;}

		public OrganizationWrapper(Organization org) {
			isSandbox = org.IsSandbox;
			if(isSandbox == true) {
				sandboxName = System.Url.getSalesforceBaseUrl().getHost().substringBetween('--', '.');
			} else {
				sandboxName = '';
			}
		}
	}

	public class UtilityFactory {

		Map<Type, Object> mockInstances = new Map<Type, Object>();
		Map<Type, Object> instances = new Map<Type, Object>();

		/**
		 * Store a list of type instance mappings to be able grab the correct instance of a selector when needed
		 * This is used to we can provide mocks in test classes to override default functionality
		 */
		@TestVisible
		private void setMock(Type utilityType, Object instance) {
			mockInstances.put(utilityType, instance);
		}

		/**
		 * Used to inject mocking class for writing isolated unit tests
		 * When not running tests, the method simply returns the normal instance
		 */
		public Object getInstance(Type utilityType) {
			if(Test.isRunningTest() && mockInstances.get(utilityType) != null) {
				return mockInstances.get(utilityType);
			} else if(instances.get(utilityType) == null) {
				instances.put(utilityType, utilityType.newInstance());
			}
			return instances.get(utilityType);
		}

		/**
		 * Used to inject mocking class for writing isolated unit tests
		 * When not running tests, the method simply returns the normal instance
		 */
		public Object newInstance(Type utilityType) {
			if(Test.isRunningTest() && mockInstances.get(utilityType) != null) {
				return mockInstances.get(utilityType);
			} else {
				return utilityType.newInstance();
			}
		}
	}

	public class SelectorFactory {

		Map<Type, ApplicationSelector> mockSelectors = new Map<Type, ApplicationSelector>();

		/**
		 * Store a list of type instance mappings to be able grab the correct instance of a selector when needed
		 * This is used to we can provide mocks in test classes to override default functionality of a selector class where we don't care about the results
		 */
		@TestVisible
		private void setMock(Type selectorType, ApplicationSelector selectorInstance) {
			mockSelectors.put(selectorType, selectorInstance);
		}

		/**
		 * Used to inject mocking class for writing isolated unit tests
		 * When not running tests, the method simply returns the normal instance
		 */
		public ApplicationSelector newInstance(Type selectorType) {
			if(Test.isRunningTest() && mockSelectors.get(selectorType) != null) {
				ApplicationSelector selector = mockSelectors.get(selectorType);
				return selector;
			} else {
				return (ApplicationSelector)selectorType.newInstance();
			}
		}
	}

	public class DomainFactory {

		Map<Type, ApplicationDomain> mockDomains = new Map<Type, ApplicationDomain>();

		/**
		 * Store a list of type instance mappings to be able grab the correct instance when needed
		 * This is used to we can provide mocks in test classes to override default functionality where we don't care about the results
		 */
		@TestVisible
		private void setMock(Type domainType, ApplicationDomain domainInstance) {
			mockDomains.put(domainType, domainInstance);
		}

		/**
		 * Used to inject mocking class for writing isolated unit tests
		 * When not running tests, the method simply returns the normal instance
		 */
		public ApplicationDomain newInstance(Type domainType, List<SObject> sObjectList) {
			if(Test.isRunningTest() && mockDomains.get(domainType) != null) {
				ApplicationDomain domain = mockDomains.get(domainType);
				return domain;
			} else {
				return (ApplicationDomain)domainType.newInstance();
			}
		}
	}

	public class GenericFactory {
		private Map<Type, Object> instances = new Map<Type, Object>();

		@TestVisible
		private void put(Type classType, Object instance) {
			instances.put(classType, instance);
		}

		public Object get(Type classType) {
			return instances.get(classType);
		}
	}

	public class ProfileFactory {
		private Map<String, Long> profileMap;

		public ProfileFactory() {
			profileMap = new Map<String, Long>();
		}

		public void start(String key) {
			profileMap.put(key, System.currentTimeMillis());
		}
		public Decimal stop(String key) {
			Decimal timer = (System.currentTimeMillis() - profileMap.get(key));
			System.debug('Profiler Results: ' + key + ' ' + timer + 'ms');
			return timer;
		}
	}

}