import LightningDatatable from 'lightning/datatable';
import customMultilineTextComplexTemplate from './customTypes/customMultilineTextComplex.html';

/**
 * This component is used by the Customer Search Form Results component and extends
 * the Lightning Datatable component with Custom Data Types for multi-line cells.
 *
 * @alias CustomerSearchFormResultsTable
 * @hideconstructor
 */
export default class CustomerSearchFormResultsTable extends LightningDatatable {
	static customTypes = {
		customMultilineTextComplex: {
			template: customMultilineTextComplexTemplate,
			standardCellLayout: true,
			typeAttributes: [
				'iconAlternativeText',
				'iconSize',
				'iconSrc',
				'iconTitle',
			],
		}
	};
}
