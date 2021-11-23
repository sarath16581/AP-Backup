import { LightningElement, track, api} from 'lwc';
import getSearchResults from '@salesforce/apex/LookupController.getSearchResults'

export default class AdvancedCustomerSearch extends LightningElement {
    @api searchResultSelectHandler

    @track showModal = false
    @track searchResults

    searchParams = {}
    noResultsFound = false
    
    columns = [
        { label: 'Contact Name', fieldName: 'Name', type: 'text' },
        { label: 'Email', fieldName: 'Email', type: 'String' },
        { label: 'Account Name', fieldName: 'accountName', type: 'text' },
        { label: 'Address', fieldName: 'address', type: 'String' },
        { label: '', type: 'button', initialWidth: 100, typeAttributes: { label: 'Select', name: 'SELECT_CUSTOMER', title: 'Click to Select' } },
    ]

    customerTypeOptions  = [
        { value: 'organisation-contact', label: 'Organisation Contact' },
        { value: 'consumer', label: 'Consumer' }
    ];

    closeModal = () => {
        this.showModal = false
    }

    openModal = () => {
        console.log('open')
        this.showModal = true
    }

    handleParamChange = (event) => {
        const { name, value } = event.target
        this.searchParams[name] = value;
    }

    doSearch = async () => {
        const firstName = this.searchParams.firstName
        console.log(firstName)
        this.isLoading = true

        try {
            const result = await getSearchResults({
                searchTerm: firstName,
                fieldList: 'Id, FirstName, LastName, Name, MobilePhone, Email, IsPersonAccount, Account.Name',
                sobjectName: 'Contact',
                fieldsToSearch: 'Name, Email, Phone',
            })
            this.searchResults = this.formatSearchRecordsForDisplay(result)
            if (this.searchResults.length === 0) {
                this.noResultsFound = true
            }
        } catch (error) {
            // eslint-disable-next-line no-console
            console.log(JSON.parse(JSON.stringify(error)))
        } finally {
            this.isLoading = false
        }
    }

    formatSearchRecordsForDisplay(records) {
        return records.map(record => ({
            ...record,
            accountName: record.Account.Name,
        }))
    }

    handleRowAction(event) {
        const name = event.detail.action.name
        const row = event.detail.row

        console.log(row)

        if (name === "SELECT_CUSTOMER") {
            if (typeof this.searchResultSelectHandler === 'function') this.searchResultSelectHandler(row)
            this.closeModal()
        }
    }
}