/***
 * Cloning CSQ records including related child records
 * 
 * @domain	CSQ
 * @author	Paul Perry
 * @since	2023-10-10
 */
public virtual without sharing class CSQCloneService {
	public Map<Id,SObject> cloneBySource;
	public Map<Id,SObject> sourceBySourceId;
	public Map<SObjectType,Set<String>> cloneFieldSetBySObjType;
	public Set<String> cloneOptions;

	public static String OPTION_CLONE_REAPPROVE = 'reapprove';
	public static String OPTION_CLONE_FULL = 'full';

	// CONFIGURATION SECTION
	/***
	 * Configuration for CSQ child relations providing SObjectType and parent field by relationship name
	 */
	public static Map<SObjectType,Map<String,ChildParentDef>> csqChildRelations = new Map<SObjectType,Map<String,ChildParentDef>>{
		Customer_Scoping_Questionnaire__c.SObjectType => new Map<String,ChildParentDef>{
			'Freight_Offerings__r' => new ChildParentDef(
				Freight_Offering__c.SObjectType,
				Freight_Offering__c.Customer_Scoping_Questionnaire__c
			),
			'Locations__r' => new ChildParentDef(
				Pick_Up_Location__c.SObjectType,
				Pick_Up_Location__c.CSQ__c
			),
			'IT_Contacts_and_Integration_Details__r' => new ChildParentDef(
				IT_Contacts_and_Integration_Details__c.SObjectType,
				IT_Contacts_and_Integration_Details__c.Customer_Scoping_Questionnaire_CSQ__c
			)
		}
	};

	/***
	 * Configured order of execution for child records cloning
	 */
	public static List<Set<String>> relationshipOrder = new List<Set<String>>{
		new Set<String>{ 'Freight_Offerings__r', 'IT_Contacts_and_Integration_Details__r' },
		new Set<String>{ 'Locations__r' }
	};

	/***
	 * Configured values to be apply clone source reference on cloned records
	 */
	private static Map<SObjectType,SObjectField> parentCloneReferences = new Map<SObjectType,SObjectField> {
		Customer_Scoping_Questionnaire__c.SObjectType => Customer_Scoping_Questionnaire__c.Clone_Source__c,
		Pick_Up_Location__c.SObjectType => Pick_Up_Location__c.Clone_Source__c,
		Freight_Offering__c.SObjectType => Freight_Offering__c.Clone_Source__c
	};

	/***
	 * Configured fields for cloning
	 */
	public static Map<SObjectType,Set<SObjectField>> csqFullFieldSet = new Map<SObjectType,Set<SObjectField>>{
		Customer_Scoping_Questionnaire__c.SObjectType => new Set<SObjectField>{
			Customer_Scoping_Questionnaire__c.Additional_Account_Management__c,
			Customer_Scoping_Questionnaire__c.Additional_Assets__c,
			Customer_Scoping_Questionnaire__c.Additional_information_if_required__c,
			Customer_Scoping_Questionnaire__c.CSQ_Sales_team__c,
			Customer_Scoping_Questionnaire__c.CSQ_Status__c,
			Customer_Scoping_Questionnaire__c.Customer_brief__c,
			Customer_Scoping_Questionnaire__c.Customer_Industry__c,
			Customer_Scoping_Questionnaire__c.CSQ_Compliance_Check__c,
			Customer_Scoping_Questionnaire__c.Estimated_go_Live_Date__c,
			Customer_Scoping_Questionnaire__c.Opportunity__c,
			Customer_Scoping_Questionnaire__c.RecordTypeId,
			Customer_Scoping_Questionnaire__c.Type__c,
			Customer_Scoping_Questionnaire__c.Website__c
		},
		Freight_Offering__c.SObjectType => new Set<SObjectField>{
			Freight_Offering__c.Additional_equipment__c,
			Freight_Offering__c.Additional_Freight_Presentation__c,
			Freight_Offering__c.Approx_loading_time__c,
			Freight_Offering__c.B2BBBP__c,
			Freight_Offering__c.B2BCartons__c,
			Freight_Offering__c.B2BSatchels__c,
			Freight_Offering__c.B2CBBP__c,
			Freight_Offering__c.B2CCartons__c,
			Freight_Offering__c.B2CSatchels__c,
			Freight_Offering__c.Break_Bulk_cartons__c,
			Freight_Offering__c.Bulk_Pallets__c,
			Freight_Offering__c.Cartons__c,
			Freight_Offering__c.Closing_time__c,
			Freight_Offering__c.Cold_Storage_Qty_Connotes__c,
			Freight_Offering__c.Cold_Storage_Qty_Items__c,
			Freight_Offering__c.Current_vehicle_arrival_time__c,
			Freight_Offering__c.Customer_Scoping_Questionnaire__c,
			Freight_Offering__c.Customer_uses_own_satchels__c,
			Freight_Offering__c.DG_Surcharge__c,
			Freight_Offering__c.DGs_are_required__c,
			Freight_Offering__c.Direct_LoadBP__c,
			Freight_Offering__c.Dispatch_Depot__c,
			Freight_Offering__c.Distribution_Network_Interstate_metro__c,
			Freight_Offering__c.Distribution_Network_Interstate_region__c,
			Freight_Offering__c.Distribution_Network_Intrastate_metro__c,
			Freight_Offering__c.Distribution_Network_Intrastate_region__c,
			Freight_Offering__c.Foreign_Currency_Qty_Connotes__c,
			Freight_Offering__c.Foreign_Currency_Qty_Items__c,
			Freight_Offering__c.Freight_Offering__c,
			Freight_Offering__c.Freight_ready_time__c,
			Freight_Offering__c.Incompatible_Freight__c,
			Freight_Offering__c.Jewellery_Qty_Connotes__c,
			Freight_Offering__c.Jewellery_Qty_Items__c,
			Freight_Offering__c.LastActivityDate,
			Freight_Offering__c.Latest_DGs_shipping_document_for_all_D__c,
			Freight_Offering__c.Location_TypeBBP__c,
			Freight_Offering__c.Location_TypeCartons__c,
			Freight_Offering__c.Location_TypeSatchels__c,
			Freight_Offering__c.Loose_Cartons__c,
			Freight_Offering__c.Loose_undersize_Qty_Connotes__c,
			Freight_Offering__c.Loose_undersize_Qty_Items__c,
			Freight_Offering__c.Material_Safety_Data_MSD_for_all_DGs__c,
			Freight_Offering__c.Max_height_under_1_8mBBP__c,
			Freight_Offering__c.Max_weightBP__c,
			Freight_Offering__c.Medical_Qty_Connotes__c,
			Freight_Offering__c.Medical_Qty_ItemsIFMedical__c,
			Freight_Offering__c.Number_of_ULDs__c,
			Freight_Offering__c.Other_IncompatibleFreights__c,
			Freight_Offering__c.Oversize_Cartons_Qty_Connotes__c,
			Freight_Offering__c.Oversize_cartons_Qty_Items__c,
			Freight_Offering__c.Oversize_Qty_Connotes__c,
			Freight_Offering__c.Oversize_Qty_Items__c,
			Freight_Offering__c.Packing__c,
			Freight_Offering__c.Pallet_Account_Cartons__c,
			Freight_Offering__c.Pallet_AccountBBP__c,
			Freight_Offering__c.Pallet_overhang_over_100mmBBP__c,
			Freight_Offering__c.Pallet_Quantity__c,
			Freight_Offering__c.Perishables_Qty_Connotes__c,
			Freight_Offering__c.Perishables_Qty_Items__c,
			Freight_Offering__c.Permanent_pick_up_days__c,
			Freight_Offering__c.Pick_up_Scheduling__c,
			Freight_Offering__c.Product_Description__c,
			Freight_Offering__c.Qty_ConnotesBBP__c,
			Freight_Offering__c.Qty_ConnotesCartons__c,
			Freight_Offering__c.Qty_Items_cartons__c,
			Freight_Offering__c.Qty_Items_IF__c,
			Freight_Offering__c.Qty_Items_Monthly_satchels__c,
			Freight_Offering__c.Qty_ItemsBBP__c,
			Freight_Offering__c.Qty_PalletsBBP__c,
			Freight_Offering__c.Qty_PalletsBP__c,
			Freight_Offering__c.Qty_SkidsBP__c,
			Freight_Offering__c.Quantity_1kgSatchels__c,
			Freight_Offering__c.Quantity_3kgSatchels__c,
			Freight_Offering__c.Quantity_5kgSatchels__c,
			Freight_Offering__c.RecordTypeId,
			Freight_Offering__c.Required_vehicle_arrival_time__c,
			Freight_Offering__c.S8_Drugs_Qty_Connotes__c,
			Freight_Offering__c.S8_Drugs_Qty_Items__c,
			Freight_Offering__c.Satchels_Jiffy_Bags__c,
			Freight_Offering__c.Service__c,
			Freight_Offering__c.Service_Requirements__c,
			Freight_Offering__c.Stair_climber__c,
			// Freight_Offering__c.Submit_for_Approval__c,
			Freight_Offering__c.Tail_lift_delivery__c,
			Freight_Offering__c.Tail_lift_pick_up__c,
			Freight_Offering__c.Top_load_onlyBBP__c,
			Freight_Offering__c.Type_of_vehicle_required__c,
			Freight_Offering__c.ULD_Cage__c,
			Freight_Offering__c.Unpacking_and_rubbish_removal__c,
			Freight_Offering__c.Urgent_notification_delivery_problems__c,
			Freight_Offering__c.Weekend_public_holiday_delivery_Ad_Hoc__c
		},
		Pick_Up_Location__c.SObjectType => new Set<SObjectField>{
			Pick_Up_Location__c.Address__c,
			Pick_Up_Location__c.CSQ__c,
			Pick_Up_Location__c.CSQ_Sales_team__c,
			Pick_Up_Location__c.DPID__c,
			Pick_Up_Location__c.Freight_Offering__c,
			Pick_Up_Location__c.Inspector_Name__c,
			Pick_Up_Location__c.Location_Type__c,
			Pick_Up_Location__c.Notes__c,
			Pick_Up_Location__c.Pick_Up_location_Details__c,
			Pick_Up_Location__c.Pick_up_Location_Status__c,
			Pick_Up_Location__c.Postcode__c,
			Pick_Up_Location__c.Primary_Pick_Up_Location__c,
			Pick_Up_Location__c.Reason__c,
			Pick_Up_Location__c.Required_Site_Inspection__c,
			Pick_Up_Location__c.Site_Inspection_Completed__c,
			Pick_Up_Location__c.Site_Inspection_Status__c,
			Pick_Up_Location__c.State__c,
			// Pick_Up_Location__c.Submit_for_Approval__c,
			Pick_Up_Location__c.Suburb__c
		},
		IT_Contacts_and_Integration_Details__c.SObjectType => new Set<SObjectField>{
			IT_Contacts_and_Integration_Details__c.Additional_Notes__c,
			IT_Contacts_and_Integration_Details__c.Additional_Notes_Integration__c,
			IT_Contacts_and_Integration_Details__c.Company_name_owning_the_GS1_code__c,
			IT_Contacts_and_Integration_Details__c.CreatedById,
			IT_Contacts_and_Integration_Details__c.CreatedDate,
			IT_Contacts_and_Integration_Details__c.Customer_Scoping_Questionnaire_CSQ__c,
			IT_Contacts_and_Integration_Details__c.ERP_WMS_system__c,
			IT_Contacts_and_Integration_Details__c.IT_Contact_Email__c,
			IT_Contacts_and_Integration_Details__c.IT_Contact_Name__c,
			IT_Contacts_and_Integration_Details__c.IT_Contact_Phone__c,
			IT_Contacts_and_Integration_Details__c.IT_Integration_Type__c,
			IT_Contacts_and_Integration_Details__c.New_Despatch_Code_Required__c,
			IT_Contacts_and_Integration_Details__c.Number_of_logins_required__c,
			IT_Contacts_and_Integration_Details__c.Sample_label_provided__c,
			IT_Contacts_and_Integration_Details__c.SSCC_GS1_barcode_on_labels__c,
			IT_Contacts_and_Integration_Details__c.Tracking_Information_Required__c,
			IT_Contacts_and_Integration_Details__c.X3rd_party_contact_name__c,
			IT_Contacts_and_Integration_Details__c.X3rd_party_email__c,
			IT_Contacts_and_Integration_Details__c.X3rd_party_phone__c,
			IT_Contacts_and_Integration_Details__c.X3rd_Party_systems__c
		}
	};

	/***
	 * Configuration for subset of fields that should not be copied compared to the full field set
	 */
	public static Map<SObjectType,Set<SObjectField>> csqReapprovalFieldSet = new Map<SObjectType,Set<SObjectField>>{
		Customer_Scoping_Questionnaire__c.SObjectType => new Set<SObjectField>{
			Customer_Scoping_Questionnaire__c.CSQ_Compliance_Check__c,
			Customer_Scoping_Questionnaire__c.CSQ_Status__c
		},
		Pick_Up_Location__c.SObjectType => new Set<SObjectField>{
			Pick_Up_Location__c.Submit_for_Approval__c,
			Pick_Up_Location__c.Pick_up_Location_Status__c
		},
		Freight_Offering__c.SObjectType => new Set<SObjectField>{
			Freight_Offering__c.Submit_for_Approval__c
		}
	};
	

	public CSQCloneService() {
		this(new Set<String>());
	}

	public CSQCloneService(Set<String> cloneOptions) {
		this.cloneOptions = cloneOptions;
	}

	public Map<SObjectType,Set<SObjectField>> csqCloneFieldSet {
		get {
			if (csqCloneFieldSet == null) {
				csqCloneFieldSet = new Map<SObjectType,Set<SObjectField>>(csqFullFieldSet);
				
				if (cloneOptions.contains(OPTION_CLONE_REAPPROVE)) {
					// subtract approval fields
					for (SObjectType sObjType :csqReapprovalFieldSet.keySet()) {
						for (SObjectField field :csqReapprovalFieldSet.get(sObjType)) {
							csqCloneFieldSet.get(sObjType).remove(field);
						}
					}
				}
			}

			return csqCloneFieldSet;
		}
		set;
	}

	/***
	 * Return a list of records including nested child records by stacking QueryBuilder instances
	 * @param recordIds parentRecordIds
	 * @param sObjType 
	 * @return  `List<SObject>`
	 */
	public virtual List<SObject> getSourceRecords(Set<Id> recordIds, SObjectType sObjType) {
		return Database.query(
			getQueryBuilder(sObjType, csqFullFieldSet.get(sObjType), csqChildRelations.get(sObjType).keySet())
				.addConditions()
				.add(new QueryBuilder.SimpleCondition('Id IN :recordIds'))
				.endConditions()
				.addOrderDesc('Id')
				.toSoqlString()
		);
	}

	/***
	 * 
	 * @param source Return whether or not a field should be cloned
	 * @param sObjType 
	 * @param fieldName 
	 * @return  `Boolean`
	 */
	public virtual Boolean allowCloneField(SObject source, SObjectType sObjType, String fieldName) {
		if (cloneFieldSetBySObjType == null) {
			cloneFieldSetBySObjType = new Map<SObjectType,Set<String>>();
		}

		if (!cloneFieldSetBySObjType.containsKey(sObjType)) {
			Set<String> fieldSet = new Set<String>();

			for (SObjectField field :csqCloneFieldSet.get(sObjType)) {
				fieldSet.add(String.valueOf(field));
			}

			cloneFieldSetBySObjType.put(sObjType, fieldSet);
		}

		return cloneFieldSetBySObjType.containsKey(sObjType) && cloneFieldSetBySObjType.get(sObjType).contains(fieldName);
	}

	/***
	 * Overrideable method invoked prior to committing records.
	 * Used to add source reference to target records
	 * @param cloneBySource Map of (to be) cloned records by their original record
	 */
	public virtual void beforeCommit(Map<SObject,SObject> cloneBySource) {
		for (SObject source :cloneBySource.keySet()) {
			SObjectType sObjType = source.getSObjectType();
			if (parentCloneReferences.containsKey(sObjType)) {
				cloneBySource.get(source).put(
					parentCloneReferences.get(sObjType),
					source.Id
				);
			}
		}
	}

	/***
	 * Overrideable method invoked prior to committing records
	 * @param cloneBySource Map of cloned records by their original record
	 */
	public virtual void afterCommit(Map<SObject,SObject> clonedBySource) { }

	/***
	 * Clone list of CSQ records with nested child records
	 * @param csqList 
	 * @return  `List<CloneRecordResult>`
	 */
	private List<CloneRecordResult> cloneCSQ(List<Customer_Scoping_Questionnaire__c> csqList) {
		cloneBySource = new Map<Id,SObject>();
		sourceBySourceId = new Map<Id,SObject>();
		Map<Id,CloneRecordResult> cloneRecordResultBySourceId = commitClonedRecords(clone(csqList));
		Map<String,ChildParentDef> relationships = csqChildRelations.get(Customer_Scoping_Questionnaire__c.SObjectType);
		
		for (Set<String> rsOrder :relationshipOrder) {
			Map<Id,SObject> cloneMap = new Map<Id,SObject>();

			for (String relationshipName :rsOrder) {
				for (Customer_Scoping_Questionnaire__c csq :csqList) {
					List<SObject> childRecords = csq.getSObjects(relationshipName);
					ChildParentDef childParentDef = relationships.get(relationshipName);

					if (childRecords == null || !cloneRecordResultBySourceId.get(csq.Id).success) {
						continue;
					}

					cloneMap.putAll(clone(
						childRecords,
						String.valueOf(childParentDef.parentReferenceField),
						cloneBySource.get(csq.Id).Id
					));
				}
			}

			cloneRecordResultBySourceId.putAll(commitClonedRecords(cloneMap));
		}

		return cloneRecordResultBySourceId.values();
	}

	/***
	 * 
	 * @param cloneMap Commit a list of records to the database
	 * @return  `Map<Id,CloneRecordResult>`
	 */
	private Map<Id,CloneRecordResult> commitClonedRecords(Map<Id,SObject> cloneMap) {
		List<SObject> sourceList = new List<SObject>();
		Map<SObject,SObject> cloneBySource = new Map<SObject,SObject>();

		for (Id recId :cloneMap.keySet()) {
			sourceList.add(sourceBySourceId.get(recId));
			cloneBySource.put(sourceBySourceId.get(recId), cloneMap.get(recId));
		}

		Database.SaveResult[] saveResults;

		if (!cloneMap.isEmpty()) {
			beforeCommit(cloneBySource);
			saveResults = ApplicationDatabase.getInstance().dmlInsert(cloneMap.values(), false);
			afterCommit(cloneBySource);
		}

		Map<Id,CloneRecordResult> result = new Map<Id,CloneRecordResult>();
		
		for (Integer idx = 0; idx < sourceList.size(); idx++) {
			Id sourceId = sourceList[idx].Id;
			result.put(
				sourceId,
				new CloneRecordResult(
					sourceBySourceId.get(sourceId),
					cloneMap.get(sourceId),
					saveResults[idx]
				)
			);
		}

		return result;
	}

	private Map<Id,SObject> clone(List<SObject> records) {
		return clone(records, null, null);
	}

	private Map<Id,SObject> clone(List<SObject> records, String parentField, Id parentId) {
		Map<Id,SObject> result = new Map<Id,SObject>();
		Set<String> errors = new Set<String>();

				
		for (SObject rec :records) {
			sourceBySourceId.put(rec.Id, rec);
			Map<String,Object> recordMap = rec.getPopulatedFieldsAsMap();
			SObjectType sObjType = rec.getSObjectType();
			SObject clone = sObjType.newSObject();

			if (String.isNotBlank(parentField)) {
				clone.put(parentField, parentId);
			}

			for (String fieldName :recordMap.keySet()) {
				Object value = recordMap.get(fieldName);

				// Don't copy source field when:
				// - it's a parent reference
				// - it's null
				// - it's not a field to be cloned
				if (fieldName == parentField || value == null || !allowCloneField(rec, sObjType, fieldName)) {
					continue;
				} else if (value instanceOf Id && cloneBySource.containsKey((Id)value)) {
					value = cloneBySource.get((Id)value).Id;
				} else {
					value = rec.get(fieldName);
				}

				try {
					clone.put(fieldName, value);
				} catch(Exception ex) {
					// Field is not writable
					errors.add(String.format(
						'{0}.{1}',
						new Object[]{
							sObjType,
							fieldName
						}
					));
				}
				
			}

			result.put(rec.Id, clone);
			cloneBySource.put(rec.Id, clone);
		}

		// Used for adjusting configuration during development
		// if (!errors.isEmpty()) {
		// 	// System.debug(LoggingLevel.ERROR, 'Fields not writable:\r\n' + String.join(errors, '\r\n'));
		// }

		return result;
	}

	/***
	 * 
	 * @param recordIds Execute the clone proces for provided CSQ record Ids
	 * @return  `CloneResult`
	 */
	public CloneResult execute(Set<Id> recordIds) {
		Savepoint sp = Database.setSavepoint();

		CloneResult result = new CloneResult(
			cloneCSQ(getSourceRecords(recordIds, Customer_Scoping_Questionnaire__c.SObjectType))
		);

		// In case one or more records failed to commit
		if (!result.success) {
			Database.rollback(sp);
		}
		
		return result;
	}

	public static QueryBuilder getQueryBuilder(SObjectType sObjType, Set<SObjectField> fields) {
		return getQueryBuilder(sObjType, fields, null);
	}

	public static QueryBuilder getQueryBuilder(SObjectType sObjType, Set<SObjectField> fields, Set<String> childRelations) {
		QueryBuilder qb = new QueryBuilder(sObjType);
		qb.addFields(fields);
		
		if (childRelations != null && csqChildRelations.containsKey(sObjType)) {
			for (String relationShipname :childRelations) {
				SObjectType childSObjType = csqChildRelations.get(sObjType).get(relationShipname).sObjType;

				qb.addSubQuery(
					getQueryBuilder(childSObjType, csqFullFieldSet.get(childSObjType)),
					relationShipname
				);
			}
		}
		
		return qb;
	}
	
	/**
	 * Container to capture parent child relationship
	 */
	public class ChildParentDef {
		public SObjectType sObjType;
		public SObjectField parentReferenceField;

		public ChildParentDef(SObjectType sObjType, SObjectField parentReferenceField) {
			this.sObjType = sObjType;
			this.parentReferenceField = parentReferenceField;
		}
	}

	/**
	 * Container to capture clone record result providing success, source recordId, dml error message
	 */
	public class CloneRecordResult {
		private Database.SaveResult saveResult;
		public SObject target;
		public SObject source;
		@AuraEnabled public Id sourceId {
			get { return source.Id; }
		}
		@AuraEnabled public Id targetId {
			get {
				return saveResult?.getId();
			}
		}
		@AuraEnabled public Database.Error[] errors { get { return saveResult?.getErrors(); } }
		@AuraEnabled public Boolean success { 
			get {
				Boolean result = false;

				if (saveResult?.isSuccess() == true) {
					result = true;
				}

				return result;
			}
		}

		public CloneRecordResult(SObject source, SObject target, Database.SaveResult saveResult) {
			this.source = source;
			this.target = target;
			this.saveResult = saveResult;
		}
	}

	public class CloneResult {
		@AuraEnabled public List<CloneRecordResult> dmlResults;
		@AuraEnabled public Boolean success {
			get {
				Boolean result = !dmlResults.isEmpty();

				for (CloneRecordResult crs :dmlResults) {
					if (!crs.success) {
						result = false;
						break;
					}
				}

				return result;
			}
		}

		public CloneResult(List<CloneRecordResult> cloneRecResult) {
			this.dmlResults = cloneRecResult;
		}
	}
}