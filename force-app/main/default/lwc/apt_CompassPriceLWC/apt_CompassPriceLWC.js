/**
 * @author Seth Heang
 * @date 2022-04-01
 * @description LWC component used within the Lightning-out framework, and is embedded in a VF Page (APT_Link_PSR), to be used in the Apttus Shopping cart
 *			It displays an interface for linking the PSR to the APPC product in form of a PSR table, and call Apex Controller for validation, DML and callout operation to COMPASS.
 * @changelog
 * 2022-04-01 - Seth Heang - Created
 * 2022-06-10 - Bharat Patel - Updated the call from client to Server specific to custom pricing execution.
 * 2023-07-24 - Sarath Burra - CI-904- Removed Repricing as its no longer applicable
*/
import { LightningElement, wire, api, track } from 'lwc';
import getPSRList from "@salesforce/apex/APT_CompassPricingController.getPSRList";
import fetchConfigRequestId from "@salesforce/apex/APT_CompassPricingController.fetchConfigRequestId";
import linkPSR from "@salesforce/apex/APT_CompassPricingController.onApply";
import LABEL_INCOMPLETE_APPC_PSR from '@salesforce/label/c.APT_IncompleteAPPCPSR';
import updateCartForCustomPricing from "@salesforce/apex/APT_CompassPricingController.updateCartForCustomPricing";

// building table columns for incomplete PSR table
const incompletePSRColumns = [
	{ label: 'COMPASS Quote ID', fieldName: 'Compass_Quote_Reference__c'},
	{ label: 'Deal Support Request', fieldName: 'psrURL', type:'url',
			typeAttributes: { label: { fieldName: 'Name'}, target:'_blank'} },
	{ label: 'Stage', fieldName: 'Stage__c' },
	{ label: 'Status', fieldName: 'Status__c'},
	{ label: 'Validity End Date', fieldName: 'Quote_Validity_End_Date__c'}
];

// building table columns for completed PSR table
const completedPSRColumns = [
	{ label: 'COMPASS Quote ID', fieldName: 'Compass_Quote_Reference__c'},
	{ label: 'Deal Support Request', fieldName: 'psrURL', type:'url',
			typeAttributes: { label: { fieldName: 'Name'}, target:'_blank'} },
	{ label: 'Approved Pricing Structure', fieldName: 'Approved_Pricing_Structure__c' },
	{ label: 'Validity End Date', fieldName: 'Quote_Validity_End_Date__c'}
];

export default class Apt_CompassPriceLWC extends LightningElement{

	@api configId; // receive as paramenters from VF Page
	@api opportunityId; // receive as paramenters from VF Page
	@api lineitemId; // receive as paramenters from VF Page
	// store url for navigation back to shopping cart
	backToShoppingCartURL = 'https://' + location.host + '/apex/Apttus_Config2__Cart?configRequestId=';
	// selected PSR on the table
	selectedPSR;
	configRequestId;
	success;
	error;
	// flag for disabling the Apply PSR button
	disableApplyPSR;
	completedPSRs = [];
	incompletePSRs = [];
	preSelectedRow = [];
	isLoading;
	errorMsgPSRNotselected = 'Please select one PSR';
	customerTierDefault = "CUST_TIER_DEFAULT:";

	completedPSRTableColumns = completedPSRColumns;
	incompletePSRTableColumns = incompletePSRColumns;
	tierDialogVisible = false;
	cartTier;

	/**
	 * Wire function to retrieve PSR list from apex controller and populate into the PSR table.
	 * @param opportunityId
	 * @return List of PSR records
	 */
	@wire(getPSRList, {oppID : '$opportunityId', selectedLineItemId: '$lineitemId'})
	wiredPSR({data, error}){
		if(data){
			let psrIds = [];
			let validPSRIds = [];
			// build navigation url for PSR's hyperlink to open on a new tab on DSR's click in the table
			let baseUrl = 'https://' + location.host + '/';
			// copy an object in order to store additional attribute for PSR's url for navigation
			data = JSON.parse(JSON.stringify(data));
			data.forEach(psrRec => {
				psrIds.push(psrRec.Id);
				psrRec.psrURL = baseUrl + psrRec.Id;
				if(psrRec.Stage__c === 'Completed' && psrRec.Status__c === 'Completed'){
					this.completedPSRs.push(psrRec);

					// get today date and slice off time details in following format (e.g. 2022-06-24)
					// toISOString returns UTC format
					let today = new Date().toISOString();
					// Salesforce stores and queries date value in UTC format
					let psrValidityDate = new Date(psrRec.Quote_Validity_End_Date__c).toISOString();
					// check for valid PSR by validating quote validity date
					if(psrValidityDate >= today){
						validPSRIds.push(psrRec);
					}
				}else{
					this.incompletePSRs.push(psrRec);
				}


			});
			/**
			 * rebuild array to make the view rerender, @track does not detect array.push() change
			 * same problem here: https://salesforce.stackexchange.com/questions/252996/array-push-wont-update-lightning-web-component-view
			 **/
			this.completedPSRs = [...this.completedPSRs];
			this.incompletePSRs = [...this.incompletePSRs];
			this.validateIncompletePSR();
			// logic to pre-select row in table if there is only one completed PSR
			if(this.completedPSRs.length === 1){
				this.preSelectedRow = [this.completedPSRs[0].Id];
				this.selectedPSR = this.completedPSRs[0];
			}
			// pre-select first valid PSR by checking validity date if there are multiple PSRs
			else if(validPSRIds.length >=1 ){
				this.preSelectedRow = [validPSRIds[0].Id];
				this.selectedPSR = validPSRIds[0];
			}

		} else if(error){
			this.error = error.body.message;
		}
	}

	/**
	 * function to validate if theres exist only incomplete PSR, then display appropriate error msg from custom label
	 */
	validateIncompletePSR(){
		if(this.completedPSRs.length === 0 && this.incompletePSRs.length > 0){
			// throw error message from custom label
			this.error = LABEL_INCOMPLETE_APPC_PSR;
		}
	}

	/**
	 * Wire function to retrieve the Apttus temporary configuration record Id, in order to build the 'Back to Cart' navigation url
	 * @param configId
	 * @return configRequestId
	 */
	@wire(fetchConfigRequestId, {configId : '$configId'})
	wiredConfigRequest({data, error}){
		if(data){
			this.configRequestId = data;
		} else if(error){
			this.error = error.body.message;
		}
	}

	/**
	 * function to link PSR by running through various validation scenarios
	 * and determine if standard delegated pricing or custom pricing is required in apex controller.
	 */
	handleApplyPSR(){
		this.isLoading = true;
		if(this.isUndefinedOrNull(this.selectedPSR)){
			this.isLoading = false;
			this.error = this.errorMsgPSRNotselected;
			return;
		}

		linkPSR(
			{
				selectedLineItemId: this.lineitemId,
				objDSR: this.selectedPSR,
				configId: this.configId
			})
			.then((result)=>{
				// display success message on successful link

				var reseultValue = result;
				if(result != null && reseultValue.indexOf(this.customerTierDefault) > -1 ) {
					// display success message on successful link
					this.error = null;
					updateCartForCustomPricing(
						{
							selectedLineItemId: this.lineitemId,
							objDSR: this.selectedPSR,
							configId: this.configId,
						})
						.then((result)=>{
							// display success message on successful link
							this.disableApplyPSR = true;
							this.success = result;
							this.error = null;
							// disable Apply PSR button once successful link
							this.isLoading = false;
						})
						.catch((error) => {
							this.isLoading = false;
							this.error = error.body.message;
						})

					.catch((error) => {
						this.isLoading = false;
						this.error = error.body.message;
					})

				}
			})
			.catch((error) => {
				this.isLoading = false;
				this.error = error.body.message;
			})
	}

	/**
	 * function to navigate back to cart summary page by sending a custom event to VF page to directly perform navigation using PageReference
	 * limitation:
	 * 	-window.history.back() or location.href() does not work correctly in Apttus shopping cart's lightning experience
	 * 	-'lightning/navigation' lwc library and pageReference are not being supported in Lightning Out framework
	 * @param event
	 */
	handleBackToCart(event){
		this.isLoading = true;
		// finish building the url for navigate back to shopping cart
		this.backToShoppingCartURL +=  this.configRequestId + '&Id=' + this.configId + '#/cart';
		const detail = {
			url: this.backToShoppingCartURL
		};
		this.dispatchEvent(new CustomEvent(
			'backToCart',
			{
				detail: detail,
				bubbles: true,
				composed: true,
			}
		));
		this.isLoading = false;
		event.preventDefault();
	}

	/**
	 * function to retrieve the PSR object selected in the table
	 * @param event
	 */
	handleSelectedPSR(event){
		// convert array of obj to a single obj
		this.selectedPSR = Object.assign({}, ...event.detail.selectedRows);
		// remove error msg related to not selecting PSR, when a PSR is selected
		if(this.error === this.errorMsgPSRNotselected){
			this.error = null;
		}
	}

	/**
	 * function checks if field is undefined or null
	 * @param  field
	 * @returns boolean
	 */
	isUndefinedOrNull(field) {
		return (typeof field === 'undefined' || field === null);
	}
}