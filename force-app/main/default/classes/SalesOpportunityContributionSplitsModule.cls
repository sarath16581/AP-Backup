/**
 * @description Domain Module to handle opportunity split related automation on an opportunity.
 * @author Ranjeewa Silva
 * @date 2023-05-04
 * @group Domain
 * @domain Sales
 * @test SalesOppContributionSplitsModule_Test
 * @changelog
 * 2023-05-04 - Ranjeewa Silva - Created.
 */

public inherited sharing class SalesOpportunityContributionSplitsModule extends ApplicationModule {

	// opportunity ids already enqueued in current transaction.
	@TestVisible private static Set<Id> enqueuedOpportunityIds = new Set<Id>();

	public static SalesOpportunityContributionSplitsModule newInstance() {
		return (SalesOpportunityContributionSplitsModule) Application.Utilities.newInstance(SalesOpportunityContributionSplitsModule.class);
	}

	// Setup which trigger events this module should respond to
	public SalesOpportunityContributionSplitsModule() {
		getTriggerEvents().enableAfterInsert().enableBeforeUpdate();
	}


	public override void onAfterInsert(List<SObject> records, ApplicationUnitOfWork uow) {

		try {
			// go through newly inserted opportunities and construct a map by OwnerId as the key
			Map<Id, List<Opportunity>> newOpportunitiesByOwner = new Map<Id, List<Opportunity>>();
			for (Opportunity opp : (List<Opportunity>) records) {
				if (newOpportunitiesByOwner.get(opp.OwnerId) == null) {
					newOpportunitiesByOwner.put(opp.OwnerId, new List<Opportunity>());
				}
				newOpportunitiesByOwner.get(opp.OwnerId).add(opp);
			}

			createOpportunitySplitsForOwnersInSpecialistSalesTeams(newOpportunitiesByOwner, uow);

		} catch (Exception e) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(e), 'Sales', SalesOpportunityContributionSplitsModule.class.getName(),
					'onAfterInsert', String.valueOf(Opportunity.SObjectType), ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	public override void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecords, ApplicationUnitOfWork uow) {
		try {

			Map<Id, Opportunity> opportunitiesChangingOwner = new Map<Id, Opportunity>();
			for (Opportunity record: (List<Opportunity>) records) {
				// check if owner is changing on the opportunity and it is not previously enqueued.
				// we only need to snapshot the opportunity splits once and any subsequent recursions should not
				Opportunity existingRecord = (Opportunity) existingRecords.get(record.Id);
				if (!enqueuedOpportunityIds.contains(record.Id) && record.OwnerId != existingRecord.OwnerId) {
					opportunitiesChangingOwner.put(record.Id, record);
				}
			}

			if (!opportunitiesChangingOwner.isEmpty()) {
				keepSplitsAssignedToPriorOwnerInSpecialistSalesTeams(opportunitiesChangingOwner, (Map<Id, Opportunity>)existingRecords, uow);
			}
		} catch (Exception e) {
			ApplicationLogger.getInstance().logException(ApplicationLogger.wrapException(e), 'Sales', SalesOpportunityContributionSplitsModule.class.getName(),
					'onBeforeUpdate', String.valueOf(Opportunity.SObjectType), ApplicationLogger.LoggingLevel.ERROR);
		}
	}

	/**
	 * Register async operation to create opportunity splits, if an opportunity owner is eligible to receive overlay contribution
	 * splits on the opportunity. Opportunity owners who are also members of specialist sales teams are assigned
	 * opportunity splits on opportunity creation.
	 *
	 * @param opportunitiesByOwner map of opportunities by owner id.
	 * @param uow unit of work instance
	 */
	private void createOpportunitySplitsForOwnersInSpecialistSalesTeams(Map<Id, List<Opportunity>> opportunitiesByOwner, ApplicationUnitOfWork uow) {
		// check if opp owners are eligible for overlay contribution splits
		Map<Id, Set<String>> opportunityOwnerOverlaySplitEligibility = OpportunitySplitUtility.getInstance().getEligibleOverlayContributionTypes(opportunitiesByOwner.keySet(),  new Set<OpportunitySplitUtility.OverlayTypeFilters>{
				OpportunitySplitUtility.OverlayTypeFilters.SUPPORTS_AUTO_ASSIGNMENT
		});

		if (!opportunityOwnerOverlaySplitEligibility.isEmpty()) {
			// found opportunity owners who are eligible to receive overlay contribution splits.
			// go through the list and prepare parameters to be passed into async process.
			List<OpportunitySplitUtility.AutoAssignOpportunitySplitsWorkerParam> params = new List<OpportunitySplitUtility.AutoAssignOpportunitySplitsWorkerParam>();
			for (Id eligibleOpportunityOwner: opportunityOwnerOverlaySplitEligibility.keySet()) {
				if (!opportunityOwnerOverlaySplitEligibility.get(eligibleOpportunityOwner).isEmpty()) {
					for (Opportunity newOpportunity: opportunitiesByOwner.get(eligibleOpportunityOwner)) {
						params.add(new OpportunitySplitUtility.AutoAssignOpportunitySplitsWorkerParam(newOpportunity.Id,
								eligibleOpportunityOwner, opportunityOwnerOverlaySplitEligibility.get(eligibleOpportunityOwner)));
					}
				}
			}

			if (!params.isEmpty()) {
				// enqueue async operation
				uow.registerAsyncWork(new ApplicationUnitOfWork.AsyncStagingWorker(OpportunitySplitUtility.AsyncAutoAssignOpportunitySplitsWorker.class, params));
			}
		}
	}

	/**
	 * Register async operation to reconcile overlay contribution opportunity splits on opportunity transfer when opportunity splits
	 * are owned by prior owner before transferring the opportunity.
	 *
	 * @param opportunities opportunities going through update operation
	 * @param existingOpportunities existing opportunities
	 * @param uow unit of work instance
	 */
	private void keepSplitsAssignedToPriorOwnerInSpecialistSalesTeams(Map<Id, Opportunity> opportunities, Map<Id, Opportunity> existingOpportunities, ApplicationUnitOfWork uow) {

		Map<Id, OpportunitySplitUtility.ReconcileOpportunitySplitsWorkerParam> asyncParams = new Map<Id, OpportunitySplitUtility.ReconcileOpportunitySplitsWorkerParam>();

		// query opportunities with child overlay splits
		Map<Id, Opportunity> opportunitiesWithSplits = OpportunitiesSelector.newInstance().selectById(opportunities.keySet(), new Set<Object>{
				OpportunitiesSelector.Options.WITH_OVERLAY_SPLITS
		});

		for (Opportunity opp: opportunitiesWithSplits.values()) {
			Opportunity existingOpportunity = existingOpportunities.get(opp.Id);

			// new async param for this opportunity
			OpportunitySplitUtility.ReconcileOpportunitySplitsWorkerParam asyncParam = new OpportunitySplitUtility.ReconcileOpportunitySplitsWorkerParam(opp.Id, existingOpportunity.OwnerId);

			// inspect the existing splits to identify splits owned by previous owner before change. these need to be
			// reconciled in async operation after the transfer operation is completed.
			for (OpportunitySplit split: opp.OpportunitySplits) {
				if (split.SplitOwnerId == existingOpportunity.OwnerId) {
					// found opportunity split record owned by prior owner. need to snapshot this so we can restore
					// it during reconciliation performed by async worker process.
					// note that at this stage we do not check if prior owner is a member of specialist sales groups
					// eligible to own overlay contribution types. this additional check is done in async worker process
					// as expanding public groups could be expensive to be performed in synchronous transaction.
					OpportunitySplitUtility.OpportunitySplitSnapshot snapshot = new OpportunitySplitUtility.OpportunitySplitSnapshot(split);
					asyncParam.addOpportunitySplitSnapshot(snapshot);
				}
			}

			if (asyncParam.hasSplitsOwnedByPreviousOwner()) {
				enqueuedOpportunityIds.add(opp.Id);
				asyncParams.put(opp.Id, asyncParam);
			}
		}

		if (!asyncParams.isEmpty()) {
			// register async operation
			uow.registerAsyncWork(new ApplicationUnitOfWork.AsyncStagingWorker(OpportunitySplitUtility.AsyncReconcileOpportunitySplitsWorker.class, asyncParams));
		}
	}

}