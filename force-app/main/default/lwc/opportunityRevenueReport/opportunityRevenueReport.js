/**
 * @author Ken McGuire
 * @date 2024-01-31
 * @description Provides reporting on Opportunity Revenue.
 * @changelog
 * 2024-01-31 - Ken McGuire - Created
 */
import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getRevenueData from '@salesforce/apex/OpportunityRevenueReportController.getRevenueData';


export default class  OpportunityRevenueReport extends LightningElement {
    @api recordId; // This property is automatically populated with the Opportunity record ID

    @track columns = []; // Columns for the datatable
    @track revenueData = []; // Data for the datatable

    // Wire method to get data from Apex controller
    @wire(getRevenueData, { opportunityId: '$recordId' })
    wiredData({ error, data }) {
        if (data) {
            this.processRevenueData(data);
        } else if (error) {
            let errorMessage = typeof error === 'object' ? JSON.stringify(error) : String(error);
            // Handle the error
            this.dispatchEvent( new ShowToastEvent({
				title: 'Error',
				message: 'Error retrieving revenue data: ' + errorMessage,
				variant: 'error'
			}));
            console.error('Error retrieving revenue data: ', errorMessage);
        }
    }

    processRevenueData(data) {
        // Assume that all rows have the same products for simplicity
        let productNames = data.length > 0 ? Object.keys(data[0].productRevenues) : [];

        // Process rows to fit into the datatable format
        this.revenueData = data.map(row => {
            let processedRow = {
                companyName: row.companyName
            };

            productNames.forEach(productName => {
                processedRow[productName] = row.productRevenues[productName];
            });

            return processedRow;
        });

        // Calculate totals after processing data
        let totals = {};
        productNames.forEach(productName => {
            totals[productName] = this.revenueData.reduce((sum, row) => sum + (row[productName] || 0), 0);
        });

        // Create and append totalRow
        let totalRow = {
            companyName: 'Total', // Label for the total row
            ...totals // Spread the totals object to fill in the product revenue fields
        };
        this.revenueData.push(totalRow);

        // Create columns dynamically based on product names
        this.columns = [
            { label: 'Legal Entity Name', fieldName: 'companyName', type: 'text' },
            // Add other static columns here if necessary
            ...productNames.map(productName => {
                return { label: productName, fieldName: productName, type: 'currency' };
            })
        ];
    }

    @api
    async reloadData() {
        console.log('Reloading data in LWC Opportunity Revenue Report');
        try {
            // Fetch the latest data from Apex
            const data = await getRevenueData({ opportunityId: this.recordId });
            this.processRevenueData(data); // Process and display the data
        } catch (error) {
            let errorMessage = typeof error === 'object' ? JSON.stringify(error) : String(error);
            // Handle the error
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Error retrieving revenue data: ' + errorMessage,
                variant: 'error'
            }));
            console.error('Error retrieving revenue data: ', errorMessage);
        }
    }
}