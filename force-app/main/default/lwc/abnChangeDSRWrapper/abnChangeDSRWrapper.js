/**
 * @description DSR creation screen action component. Triggered by ABN change DSRs quick action button in At Risk Business
 * @author Harry Wang
 * @date 2024-06-05
 * @group Controller
 * @changelog
 * 2024-06-05 - Harry Wang - Created
 */
import {api, LightningElement, track, wire} from 'lwc';
import getDSRsAndBaR from '@salesforce/apex/ABNChangeController.getDSRsAndBaR';
import createDSRs from '@salesforce/apex/ABNChangeController.createDSRs';
import {refreshApex} from "@salesforce/apex";
import {CloseActionScreenEvent} from "lightning/actions";
import LightningAlert from "lightning/alert";

export default class AbnChangeDsrWrapper extends LightningElement {
	@api recordId;
	isLoading = true;
	errorMessage;
	businessAtRisk = {};
	@track dsrList = [];
	_wiredDSRsAndBaR;
	dsrFailureMessage;

	/**
	 *  Retrieve linked DSRs and BaR record
	 *  Map DSR Id, Owner and Record Type on successful retrieval
	 */
	@wire(getDSRsAndBaR, {businessAtRiskId: "$recordId"})
	wiredData(result) {
		const {data, error} = result;
		this._wiredDSRsAndBaR = result;
		if (error) {
			this.errorMessage = error;
			return;
		}

		if (data?.businessAtRisk) {
			this.businessAtRisk = data.businessAtRisk;

			if (this.businessAtRisk.Related_Organisation__c == null || this.businessAtRisk.Related_Opportunity__c == null) {
				this.errorMessage = 'Please populate Opportunity and Related Organisation links on the Business at Risk record before proceeding with DSR creation.';
				this.isLoading = false;
				return;
			}

			if (data?.dsrList) {
				let nameUrl;
				if (data.dsrList.reduce((a, b) => a || (b.Credit_Work_Type__c != null && b.Credit_Work_Type__c.includes('ABN Change'))
					|| (b.Work_Type__c != null && b.Work_Type__c.includes('ABN Change')), false)) {
					this.dsrList = data.dsrList.map(row => {
						nameUrl = `/${row.Id}`;
						return {...row , nameUrl}
					});
					this.dsrList.forEach(row => {
						row.recordType = row.RecordType?.Name;
						row.owner = row.Owner?.Name;
					});
				}
			}

			this.isLoading = false;
		}
	}

	get hasExistingDSR() {
		return this.dsrList.length > 0;
	}

	get relatedOrganisationName() {
		return this.businessAtRisk.Related_Organisation__r?.Name;
	}

	/**
	 *  Call apex to create DSR. Request wrapper is passed from abnChangeDsrForm.
	 *  Refresh DSR data upon creation.
	 *  Display failed DSR types.
	 */
	handleCreateDSRs(event) {
		const data = event.detail;
		this.isLoading = true;
		createDSRs({request: data}).then(failedDSRTypes => {
			refreshApex(this._wiredDSRsAndBaR).then(() => {
				if (failedDSRTypes.length > 0) {
					this.dsrFailureMessage = 'One or more DSR creation failed, please create the below DSRs that failed manually - ' + failedDSRTypes.join(', ');
				}
				this.isLoading = false;
			});
		}).catch(error => {
			this.isLoading = false;
			LightningAlert.open({
				message: 'Unexpected error : ' + error.body.message,
				theme: 'error',
				label: 'ABN Change DSRs'
			});
		});
	}

	/**
	 *  Close current screen action
	 */
	handleClose() {
		this.dispatchEvent(new CloseActionScreenEvent());
	}
}