import {
    api,
    track,
    LightningElement
} from 'lwc';
import {
    getValue
} from 'c/myNetworkStarTrackCaseArticlesService';

export default class MyNetworkStarTrackCaseArticlesDatatable extends LightningElement {

    @api articleDetails; //article details received from parent
    @track selectedRows = []; //selected rows

    tableColumns = [{
            label: 'Article',
            fieldName: 'ArticleID__c',
            objName: 'Article__c',
            editable: false,
            sortedColumn: false,
            fieldType: 'URL',
            headerCssClass: 'slds-th__action slds-text-link_reset',
            dataCssClass: 'slds-cell-wrap'
        },
        {
            label: 'Last Event Description',
            objName: 'EventMessage__c',
            fieldName: 'EventDescription__c',
            editable: false,
            sortedColumn: false,
            fieldType: 'TEXT',
            headerCssClass: 'slds-th__action slds-text-link_reset',
            dataCssClass: 'slds-cell-wrap'
        },
        {
            label: 'Last Scan Date',
            objName: 'EventMessage__c',
            fieldName: 'ActualDateTime__c',
            editable: false,
            sortedColumn: false,
            fieldType: 'DATETIME',
            headerCssClass: 'slds-th__action slds-text-link_reset',
            dataCssClass: 'slds-cell-wrap'
        },
        {
            label: 'Last AP Network Scan',
            objName: 'EventMessage__c',
            fieldName: 'Facility__c',
            editable: false,
            sortedColumn: false,
            fieldType: 'PILL',
            headerCssClass: 'slds-th__action slds-text-link_reset',
            dataCssClass: 'slds-cell-wrap'
        }
    ];
    tableData; //data to be rendered in table


    /**
     * Formatted table data with required columns to render
     */
    get formattedArticles() {
        let tableData = this.articleDetails.map(item => {
            let rowData = this.tableColumns.map(column => {
                let row = {
                    ...column,
                    fieldValue: column.objName === 'Article__c' ? getValue(item.article, column.fieldName, null) : getValue(item.eventMessages[0]?.eventMessage ?? null, column.fieldName, null),
                    key: item.article.Id,
                    networkPillItems: this.getNeworkPillItems(item.eventMessages[0]?.eventMessage ?? null, column),
                    fieldUrl: this.getFieldUrl(item, column),
                    eventMessageId: item.eventMessages[0] !== null || item.eventMessages[0] !== undefined ? item.eventMessages[0].eventMessage.Id : null
                };
                return row;
            });

            return {
                ...item,
                rowData: rowData
            }
        })

        this.tableData = tableData;
        return this.tableData;
    }

    getNeworkPillItems(item, column) {
        let networkPillItems = [];
        if (column.fieldType === 'PILL' && item !== null) {
            networkPillItems.push({
                label: item.Facility__r.Name,
                name: item.Facility__c,
                contactMethod: item.Facility__r.Contact_Facility__c
            });
        }
        return networkPillItems;
    }

    getFieldUrl(item, column) {
        let target = null;
        if (column.fieldType === 'URL' && column.objName === 'Article__c') {
            target = '/' + item.article.Id;
        }
        return target;
    }

    //handler for networksearch event from the child
    handleNetworkSearch(event) {
        console.log('in parent');
        console.log(JSON.parse(JSON.stringify(event.detail)));
    }

    //handler on article select checkbox
    handleRowChange(event) {
        if (event.target.checked) {
            let networks = this.getSelectedNetworks(event.target.dataset.id);
            let row = {
                articleId: event.target.dataset.id,
                networks: networks
            }
            this.selectedRows.push(row);
        } else {
            let index = this.selectedRows.findIndex(row => row.articleId === event.target.dataset.id);
            if (index > -1) {
                this.selectedRows.splice(index, 1);
            }
        }
        this.selectedRows = [...this.selectedRows];
        this.dispatchEvent(new CustomEvent('rowselect', {
            detail: {
                selectedRows: this.selectedRows
            }
        }));
    }

    getSelectedNetworks(articleId) {
        let selectedRowData = this.tableData.find(data => data.article.Id === articleId).rowData;
        return selectedRowData.find(row => row.fieldName === 'Facility__c').networkPillItems;
    }


}