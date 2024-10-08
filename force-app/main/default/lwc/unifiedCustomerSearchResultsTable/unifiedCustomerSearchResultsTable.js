import LightningDatatable from 'lightning/datatable';
import customMultilineTextComplexTemplate from './customTypes/customMultilineTextComplex.html';

/**
 * This component is used by the `UnifiedCustomerSearchResults` component and extends the Lightning Datatable component
 * with Custom Data Types for multi-line cells.
 *
 * @alias UnifiedCustomerSearchResultsTable
 * @hideconstructor
 */
export default class UnifiedCustomerSearchResultsTable extends LightningDatatable {
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