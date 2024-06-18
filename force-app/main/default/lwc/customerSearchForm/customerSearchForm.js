import { LightningElement, api } from "lwc";

/**
 * The Customer Search form allows users to specify criteria and search for
 * customer records. This component wraps the search form inputs and search
 * results components and is exposed for use in Lightning App Builder.
 *
 * @alias CustomerSearchForm
 * @hideconstructor
 */
export default class CustomerSearchForm extends LightningElement {
	/**
	 * The Id of the record to provide context to this component.
	 * @type {string}
	 */
	@api recordId;
}
