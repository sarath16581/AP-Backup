/* @author
* @date 2021-04-15
* @channel Credit Application
* @tag Credit Application
* @description: Step in Credit Application Form to open Digital Id sign in
* @changelog
* 2021-04-15 vcheng@salesforce.com Created
* 2023-05-05 Naveen Rajanna - Included logic to support both Production & Sandbox DigiIdApp script in a single DigitalId Static Resource
*/

import {LightningElement, api, wire, track} from 'lwc';
import DigitalIdResource from '@salesforce/resourceUrl/DigitalIdResource';
import { loadScript } from 'lightning/platformResourceLoader';
import queryDigitalId from "@salesforce/apex/BCAFormController.queryDigitalId";
import getDigitalIdClientId from "@salesforce/apex/BCAFormController.getDigitalIdClientId";

import bcaStepBase from "c/bcaStepBase";

export default class BcaStepDigitalId extends bcaStepBase {

	@track showButton = true;
	@api verified = false;
	@track verificationError = false;

	@track digitalIdClass = '';
	@track clientId = '';

	CONTAINER_DIV_ID = 'digitalid-container';
	DIGITAL_DIV_ID = 'digitalid-verify';
	DIGITAL_DIV_HTML = '<div id="' + this.DIGITAL_DIV_ID + '" data-id="' + this.DIGITAL_DIV_ID + '" ></div>';

	@track isInit;
	timeStamp = Date.now();

	@track _digitalIdResult = {};
	@api get digitalIdResult () {
		return this._digitalIdResult;
	}

	async connectedCallback() {
		let DigitalIdApp;
		// get the server side data first
		await getDigitalIdClientId()
			.then(result => {
				this.clientId = result.clientId;
				DigitalIdApp = result.isProduction ? DigitalIdResource+'/Production.js' : DigitalIdResource+'/Sandbox.js'; 
			});

		const self = this;
		
		await loadScript(this, DigitalIdApp).then(() =>{
			const contDiv = this.template.querySelector('[data-id="' + this.CONTAINER_DIV_ID + '"]');
			contDiv.innerHTML = this.DIGITAL_DIV_HTML;
			digitalId.init({
				clientId: this.clientId,
				uxMode: 'popup',
				buttonConfig: {
					type: 'branded', // supported types: basic | branded. Properties 'label' and 'classNames' only available for type 'basic'
					classNames: 'digitalidbutton-63989', // single css classname as String or multiple as an Array. Applied only for type: 'basic'
				},
				onComplete: function (msg) {
					// hide the digital ID button
					self.showButton = false;

					if(msg.code) {
						// success, 2nd query to get all details
						queryDigitalId({grantCode: msg.code})
							.then(result => {
								self.storeDigitalIdResults(result);
							})
							.catch(error => {
								self.moveToNextStep();
							})
					}
					else
					{
						self.verificationError = true;
						self.moveToNextStep();
					}
				},
				onClick: function (opts) {
					opts.state = 'dummyState';
				},
				onKeepAlive: function () {
				}
			});
			this.isInit = true;
		}).catch(error => {
		});
	}

	storeDigitalIdResults = (objResults) => {
		this.verified = true;

		// format the results to match the businessPerson
		this._digitalIdResult.firstName = objResults.given_name;
		this._digitalIdResult.lastName = objResults.family_name;
		this._digitalIdResult.middleName = objResults.middle_name;
		this._digitalIdResult.dob = objResults.birthdate;

		// show the input page
		this.moveToNextStep();
	}

	disableParentWin = () => {
		//this.digitalIdClass ="disableWin";
		const digitalDiv= this.template.querySelector('[data-id="'+ this.DIGITAL_DIV_ID + '"]');
		digitalDiv.className = "disableWin";
	}

}