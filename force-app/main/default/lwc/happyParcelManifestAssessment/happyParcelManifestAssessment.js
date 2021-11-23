/**
 * @description Happy Parcel Manifest Assessment
 * @author Nathan Franklin
 * @date 2020-05-10
 * @group Tracking
 * @changelog
 */
import {LightningElement, api, track} from "lwc";
import { get, getConfig, CONSTANTS } from "c/happyParcelService";
import HappyParcelBase from "c/happyParcelBase";

export default class HappyParcelManifestAssessment extends HappyParcelBase {

	_manifestAssessmentMappings;

	@api loading = false;
	@api analyticsApiResult;

	helpText = CONSTANTS.LABEL_HAPPYPARCELMANIFESTASSESSMENTHELPTEXT;

	connectedCallback() {
		getConfig().then(config => {
			this._manifestAssessmentMappings = config.manifestAssessmentMappings;
		})
	}

	get displayValue() {
		return this.assessmentMapping.StatusText__c;
	}

	get statusHelpText() {
	 	return this.assessmentMapping.HelpText__c;
	}
	get icon() {
		return this.assessmentMapping.IconName__c;
	}

	get assessmentMapping() {
		if(!this._manifestAssessmentMappings)
			return [];

		const assessmentMapping = this._manifestAssessmentMappings[get(this.analyticsApiResult, 'flag_manifest_quality', null)];
		return (assessmentMapping ? assessmentMapping : []);
	}

	get isOkStatus() {
		return this.manifestAverage === 'standard';
	}

	get isPoorStatus() {
		return this.manifestAverage === 'poor';
	}
}