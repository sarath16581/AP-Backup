import { LightningElement, track, api } from 'lwc'
import getSearchResults from '@salesforce/apex/LookupController.getSearchResults'
import { debounce } from 'c/utils'

export default class Lookup extends LightningElement {
    @api fieldList;
    @api sobjectName;
    @api fieldsToSearch;
    @api iconName;
    @api placeholder;
    @api searchResultSelectHandler;
    @api networkSearchResultSelectHandler;
    @api label
    @api searchResultTitleFormatter
    @api searchResultSubtitleFormatter
    @api customerlookup
    @api numCharsToSearch = 4;
    @api filterMap = new Map();
    @api searchDelay = 0;
    @api context;
    searchDelayTimeout;

    @track selectedRecord;
    @track isLoading;
    @track searchResults = [];
    @track shouldShowDropDown = false;
    @track searchTerm = ''
    @api selectedPostCode;
    connectedCallback(){
        this.selectedRecord = this.selectedPostCode;
    }

    @api
    setSelectedRecord = record => {
        this.selectedRecord = record
    }

    // populates the pill container when a search result is selected
    get pillItem() {
        return this.selectedRecord
            ? [{
                type: 'icon',
                label: this.selectedRecord.Name,
                iconName: this.iconName,
            }]
            : [];
    }

    search(event) {
        const searchTerm = event.target.value
        this.searchTerm = searchTerm
        // Apply search throttling (prevents search if user is still typing) if search delay specified
        if (this.searchDelay > 0)
        {
         if (this.searchDelayTimeout) {
                    clearTimeout(this.searchDelayTimeout);
                }
                // eslint-disable-next-line @lwc/lwc/no-async-operation
                this.searchDelayTimeout = setTimeout(() => {
                    if (searchTerm.length >= this.numCharsToSearch) {
                        this.handleSearch(searchTerm);
                    }
                    this.searchThrottlingTimeout = null;
                }, this.searchDelay);
          }
       //otherwise just debounced search
       else  if (searchTerm.length >= this.numCharsToSearch) {
            this.debouncedSearchHandler(searchTerm);
        }
    }

    focusOnSearchInput() {
        const searchInput = this.template.querySelector('input')
        if (searchInput) {
            searchInput.focus()
        }
    }

    @api
    clearSearchTerm() {
        this.searchTerm = ''
        this.focusOnSearchInput()
    }

    // eslint-disable-next-line no-undef
    debouncedSearchHandler = debounce(this.handleSearch, 200)

    /* 
        we call the 'getSearchResults' apex method imperatively instead of using the 
        @wire service and wiring the data returned from apex to a property because we 
        want to handle the interval where the server call has been made and we are 
        waiting for the results and show the message 'searching...' to the user so they 
        know that something is happening while they are waiting.
    */
    async handleSearch(searchTerm) {
        const {
            fieldList,
            sobjectName,
            fieldsToSearch,
            filterMap,
        } = this

        this.isLoading = true
        this.openSearchResultsList()

        try {
            const result = await getSearchResults({
                searchTerm,
                fieldList,
                sobjectName,
                fieldsToSearch,
                filterMap,
            })
            this.searchResults = this.formatSearchRecordsForDisplay(result)
            if (this.searchResults.length === 0) {
                this.closeSearchResultsList()
            }
        } catch (error) {
            // eslint-disable-next-line no-console
            console.log(JSON.parse(JSON.stringify(error)))
        } finally {
            this.isLoading = false
        }
    }

    // takes the records returned from the search and concatanates the data contained
    // in the queried fields (except 'Id', 'Name', 'FirstName' and 'LastName') joins it with a '|' for diplay
    // and puts in in a new field called 'additionalFieldData'
    defaultSearchResultSubtitleFormatter = record => {
        const additionalFieldData = Object.entries(record)
            .filter(([key, value]) => !!(!['Id', 'Name', 'FirstName', 'LastName'].includes(key) && !!value))
            .reduce((acc, [, value]) => {
                return acc ? `${acc}  ·  ${value}` : `${value}`
            }, '')
        return additionalFieldData
    }

    defaultSearchResultTitleFormatter = record => record.Name
    

    /* 
        we take the search records and format them for display but generating the title and subtitle 
        using the 'searchResultTitleFormatter' and the 'searchResultSubtitleFormatter' functions 
        passed in from the parent component.

        if the formatter functionas are not passed in, the two above functions 
        ('defaultSearchResultTitleFormatter' and 'defaultSearchResultSubtitleFormatter') 
        are used by default.
    */ 
    formatSearchRecordsForDisplay(records) {
        const titleMapper = typeof this.searchResultTitleFormatter === 'function'
            ? this.searchResultTitleFormatter : this.defaultSearchResultTitleFormatter

        const subtitleMapper = typeof this.searchResultSubtitleFormatter === 'function' 
            ? this.searchResultSubtitleFormatter : this.defaultSearchResultSubtitleFormatter
        
        const titles = records.map(titleMapper)
        const subtitles = records.map(subtitleMapper)

        return records.map((record, index) => ({ 
            ...record, 
            title: titles[index], 
            subtitle: subtitles[index],
        }))
    }

    handleSearchResultSelect(event) {
        this.selectedRecord = event.detail
        console.log('this.selectedRecord>>>>',this.selectedRecord);
        if (typeof this.searchResultSelectHandler === 'function') {
            this.searchResultSelectHandler(event.detail)
        }
        if (typeof this.networkSearchResultSelectHandler === 'function') {
            this.networkSearchResultSelectHandler(event.detail)
        }
        if (event.type === 'selected' && !this.searchResultSelectHandler && !this.networkSearchResultSelectHandler) {
            // publish the recordselected event.
            // for backward compatibility - only do this if existing callback functions are not set.
            const recordSelected = new CustomEvent('recordselected', { detail: { record: this.selectedRecord, context: this.context } });
            this.dispatchEvent(recordSelected);
        }

        this.closeSearchResultsList()
    }

    handleItemRemove() {
        this.selectedRecord = null
        const listOfFieldsToSearch = this.fieldList.split(',').map(field => field.trim());
        const epmtyFieldsRecord = listOfFieldsToSearch.reduce((acc,field) => ({ ...acc,[field]: '' }),{})
        if (typeof this.searchResultSelectHandler === 'function') {
            this.searchResultSelectHandler(epmtyFieldsRecord)
        }
        if (typeof this.networkSearchResultSelectHandler === 'function') {
            this.networkSearchResultSelectHandler(epmtyFieldsRecord)
        }
        this.clearSearchTerm();
    }

    openSearchResultsList() {
        if (this.searchResults.length > 0 || this.isLoading) {
            this.shouldShowDropDown = true
        }
    }

    closeSearchResultsList() {
        this.shouldShowDropDown = false
    }
}