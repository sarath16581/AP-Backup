/**
  * @author alex.volkov@auspost.com.au
  * @date 29/01/2020
  * @description Address Lookup wrapper for exposure on Lightning Pages
--------------------------------------- History --------------------------------------------------
2020-01-20	alex.volkov@auspost.com.au	Initial creation
2021-07-26	naveen.rajanna@auspost.com.au   REQ2573263  Update the country code as AU only for leads
2022-02-21	naveen.rajanna@auspost.com.au   REQ2755163  Minor label change and API version change
2024-06-24 - Ranjeewa Silva - Reload component after successful record update if not navigating away (or page refresh).
**/

import { LightningElement, api, track } from 'lwc';
import getSettings from '@salesforce/apex/AddressLookupWrapperController.getSettings';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import { reduceErrors } from 'c/ldsUtils';
import { NavigationMixin } from 'lightning/navigation';

export default class AddressLookupRecordWrapper extends NavigationMixin(LightningElement) {

  @api addressType;
  @api cardTitle;
  @api addressType2;
  @api cardTitle2;
  @api addressType3;
  @api cardTitle3;
  @api recordId;
  // Alternate record id
  @api altRecordId;
  // Property to determine if the component will refresh after save
  @api noRefreshAfterSave;
  @api refreshAfterSave;
  // pass in containerContext = 'VisualForce', to use old skool
  @api containerContext = 'Lightning';
  @api refreshNotNavigate;

  settings;
  currentRecord;
  params;

  @track objectAPIName;
  @track showSpinner = true;
  @track showAddressInput = true;
  @track addressData = [];

  //retrieve metadata configuration and the record. not using wire due to complex describes that require 1 and only 1 server-side call
  connectedCallback() {
    // Use an alt record id in the event that there is no record id
    this.handleAltRecordId();
    // get settings for record id
    this.loadConfig();
  }

  //verify record id. use alt record id if there is no record id
  handleAltRecordId() {
    if (!this.recordId && !!this.altRecordId) {
      this.recordId = this.altRecordId;
    }
  }

  //new address entered
  handleStreetValueChange(event) {

    this.address = event.detail;

    let changedAddress = this.addressData.find(x => x.addressType === event.target.dataset.id);


    changedAddress.streetValue = this.address.addressLine;
    changedAddress.unitValue = this.address.addressLine2;

    if (changedAddress.unitValue != null) {
      changedAddress.streetValue = changedAddress.streetValue + ' ' + changedAddress.unitValue;
    }
    
    changedAddress.city = this.address.locality;
    changedAddress.postcode = this.address.postcode;
    changedAddress.state = this.address.state;
    changedAddress.latitude = this.address.latitude;
    changedAddress.longitude = this.address.longitude;
    changedAddress.dpid = this.address.dpid;

  }

  //new address entered manually
  handleManualChange(event) {

    this.address = event.detail;

    let changedAddress = this.addressData.find(x => x.addressType === event.target.dataset.id);

    changedAddress.streetValue = this.address.addressLine1;
    changedAddress.streetValue1 = this.address.addressLine;
    changedAddress.unitValue = this.address.addressLine2;
    changedAddress.unitValue1 = this.address.addressLine3;

    if (changedAddress.unitValue != null) {
      changedAddress.streetValue = changedAddress.streetValue + ' ' + changedAddress.unitValue;
    }

    if (changedAddress.unitValue1 != null) {
      changedAddress.streetValue1 = changedAddress.streetValue1 + ' ' + changedAddress.unitValue1;
    }

    changedAddress.city = this.address.city;
    changedAddress.city1 = this.address.locality;
    changedAddress.postcode = this.address.postcode;
    changedAddress.state = this.address.state;

    if (changedAddress.streetValue === changedAddress.streetValue1 && changedAddress.city === changedAddress.city1) {
      changedAddress.latitude = this.address.latitude;
      changedAddress.longitude = this.address.longitude;
      changedAddress.dpid = this.address.dpid;
    }
    else {
      changedAddress.latitude = '';
      changedAddress.longitude = '';
      changedAddress.dpid = '';
    }
  }

  //validate and save
  saveRecord() {
    let isValid = true;
    this.template.querySelectorAll("c-ame-address-validation1").forEach(cmp => { if (!cmp.checkValidity()) isValid = false });
    if (isValid) {
      this.showSpinner = true;
      let dataUpdated = false;
      let record = {
        "fields": {
          "Id": this.recordId
        }
      };
      for (let i = 0; i < this.addressData.length; i++) {
        let addr = this.addressData[i];
        //new address entered and all components present
        if (addr.streetValue && addr.postcode && addr.city && addr.state) {
          record.fields[[this.settings[addr.addressType].Street]] = addr.streetValue;
          record.fields[[this.settings[addr.addressType].PostCode]] = addr.postcode;
          record.fields[[this.settings[addr.addressType].City]] = addr.city;
          record.fields[[this.settings[addr.addressType].State]] = addr.state;
          //REQ2573263
          if (this.settings && this.settings.hasOwnProperty('Lead_Physical')){
            record.fields[[this.settings[addr.addressType].Country]] = 'AU';
          }
          if (this.settings[addr.addressType].DPID) {
            record.fields[[this.settings[addr.addressType].DPID]] = addr.dpid;
          }
          if (this.settings[addr.addressType].AddressValidated) {
            record.fields[[this.settings[addr.addressType].AddressValidated]] = true;
          }
          if (this.settings[addr.addressType].Latitude && this.settings[addr.addressType].Longitude) {
            record.fields[[this.settings[addr.addressType].Latitude]] = addr.latitude;
            record.fields[[this.settings[addr.addressType].Longitude]] = addr.longitude;
          }
          //set flag that there is something to save
          dataUpdated = true;
        }
        //new address entered but some components missing
        else if (addr.streetValue || addr.postcode || addr.city || addr.state) {
          isValid = false;
          this.dispatchEvent(new ShowToastEvent({
            title: 'Error on Address save',
            message: 'Incomplete address entry (must contain Street, Suburb, State and Postcode)',
            variant: 'error',
          }),
          );
        }
      }
      //there is a change to save and all entries are valid
      if (dataUpdated && isValid) {
        if (this.containerContext.toLowerCase() == 'visualforce') {
          // need to use regular js
          updateRecord(record).then(() => {
            this.showSpinner = false;
            window.open('/' + this.recordId, "_parent");
          });
        }
        else {
          // do the usual lightning stuff
          updateRecord(record)
            .then(() => {
              this.showSpinner = false;
              if (this.refreshNotNavigate) {
                window.location.reload();
              }
              if (!this.noRefreshAfterSave) {
                this[NavigationMixin.Navigate]({
                  type: 'standard__recordPage',
                  attributes: {
                    recordId: this.recordId,
                    actionName: 'view'
                  }
                });
              } else {
                  // component is configured to keep showing address component after successful save.
                  // ensure the component is refreshed to ensure latest updates are reflected on the component.
                  // this approach ensures minimum changes to current component and not impact any existing use cases
                  // using this component.
                  this.addressData = [];
                  this.loadConfig();
              }
            })
            .catch(error => {
              this.showSpinner = false;
              this.dispatchEvent(new ShowToastEvent({
                title: 'Error on Address save',
                message: 'You do not have access to update this record. Please raise a case record to the Sales Operations Support team with your change request.',
                variant: 'error',
              })
              );
            });
        }
      }
      else {
        this.showSpinner = false;
      }
    }
  }

	/**
	 * load address configuration and record data to initialise the component.
	 */
	async loadConfig() {

		try {
			this.showSpinner = true;
			// get settings for record id
			const result = await getSettings({pRecordId: this.recordId});
			this.objectAPIName = result.objectApiName;

			if (!result.settings) {
				this.dispatchEvent(new ShowToastEvent({
					title: 'Error on Address component load',
					message: 'Address metadata configuration not found. Please contact your system administrator.',
					variant: 'error'
				}));
			} else {
				//populate configuration
				this.settings = result.settings;
				this.currentRecord = result.currentRecord;
				this.params = { [this.addressType]: this.cardTitle, [this.addressType2]: this.cardTitle2, [this.addressType3]: this.cardTitle3 };

				for (let aType in this.settings) {
					if (this.params.hasOwnProperty(aType)) {
						let add = {
							streetValue: '', streetValue1: '', unitValue: '', unitValue1: '', city: '',
							city1: '', postcode: '', postcode1: '', state: '', state1: '', addressType: aType, cTitle: this.params[aType]
						}
						if (this.currentRecord[[this.settings[aType].Street]]) {
							add.currentAddress = this.currentRecord[[this.settings[aType].Street]] + ' ' + result.currentRecord[[this.settings[aType].City]] + ' ' + result.currentRecord[[this.settings[aType].State]] + ' ' + result.currentRecord[[this.settings[aType].PostCode]];
						}
						this.addressData = [...this.addressData, add];
					}
				}
			}

		} catch (error) {
			this.dispatchEvent(new ShowToastEvent({
				title: 'Error on Address component load',
				message: 'Address metadata configuration appears incorrect. Please contact your system administrator.' + error,
				variant: 'error',
			}));
		} finally {
			this.showSpinner = false;
		}
	}
}