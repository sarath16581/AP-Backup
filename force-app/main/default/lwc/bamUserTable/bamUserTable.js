/* eslint-disable no-undef */
/* eslint-disable no-extra-boolean-cast */
import { LightningElement, track } from 'lwc'
import retrieveUserDetails from '@salesforce/apex/BAMUserTableController.retrieveUserDetails'
import searchContactApplicationData from '@salesforce/apex/BAMUserTableController.searchContactApplicationData'

//input actions
import deactivateContact from '@salesforce/apex/BAMUserTableController.deactivateContact'
import reactivateContact from '@salesforce/apex/BAMUserTableController.reactivateContact'
import reinviteContact from '@salesforce/apex/BAMUserTableController.reinviteContact'
import cancelContactRequest from '@salesforce/apex/BAMUserTableController.cancelContactRequest'

// navigation
import retrieveMerchantPortalCommunityURL from '@salesforce/apex/BAMUserController.retrieveMerchantPortalCommunityURL';
import { navigation } from 'c/bamNavigationUtils';
import { showToast, poll, debounce } from 'c/bamUtils'

import ASSETS_URL from '@salesforce/resourceUrl/MerchantPortalAssets';

export default class BamUserTable extends LightningElement {

    // top-level gate check
    @track isBAMUser = true;

    // time elapsed
    reinviteTimeInterval = 300

    // the account/org ID
    orgId = '';

    // for search typing
    debouncedSearch;

    // navigational links
    navigate;

    @track showLoading = true;

    // search
    @track includeDeactivated;
    @track searchString = '';

    @track searchResults = [];
    totalResults = 0;

    @track maxPageNumber = 1;
    @track currentPageNumber = 1;
    pageSize = 20;

    @track showFilters
    @track tableDisplayListData = []
    @track selectedUserId = ''
    @track userView = false
    @track billingAccounts

    @track loggedInUserContactId

    // requests
    @track showRequestCancellationResultModal = false;
    @track showConfirmDeactivateModal = false;
    @track showConfirmRequestCancellationModal = false;
    @track selectedUserForDeactivation = {};
    @track selectedUserForRequestCancellation = {};

    // results
    @track showDeactivateResultModal = false;
    @track deactivateResultMessage = '';
    @track requestCancellationResultMessage = '';

    @track showReactivateResultModal = false;
    @track reactivateResultMessage = '';

    get noResultsIconUrl() {
        return ASSETS_URL + '/svg/symbols.svg#no-search-result'
    }

    // Identify if being loaded on IE11, to handle how we render SVGs
    get ie11() {
        return !!window.MSInputMethodContext && !!document.documentMode;
    }

    get noResultsIconUrl_IE11() {
        return ASSETS_URL + '/svg/no-search-result.svg'
    }
    
    get tableHeaders() {
        return [
            "Name",
            "Email",
            "Status",
            "Application",
        ];
    }

    get filterIcon() {
        return this.showFilters ? 'utility:chevronup' : 'utility:chevrondown';
    }

    get noTableData() {
        // we display the no results message if there is no spinner and if the table has not been populated
        return this.searchResults.length === 0 && !this.showLoading
    }

    async connectedCallback() {
        try {
            this.showLoading = true;

            // retrieve the community prefix and initialise the navigation
            const commURLPrefix = await retrieveMerchantPortalCommunityURL();
            this.navigate = navigation(commURLPrefix);

            let objInit = await retrieveUserDetails();
            console.debug(objInit);
            this.isBAMUser = objInit.isBAMUser;
            if(this.isBAMUser === true) {
                this.orgId = objInit.orgId;
                this.loggedInUserContactId = objInit.contactId;

                this.currentPageNumber = 1;
                this.debouncedSearch = debounce(this.searchServerSide, 400);
                await this.searchServerSide();

                // then start the auto polling
                poll(this.searchServerSide.bind(this));
            }

            this.showLoading = false;

            /*
            const tableDisplayListData = this.formatDataForTableDisplay(JSON.parse(tableData))
            this.tableDisplayListData = tableDisplayListData
             */
        } catch (err) {
            console.error(err)
        }
    }

    async searchServerSide()
    {
        /*
        if(this.lastRunId)
        {
            clearTimeout(this.lastRunId);
        }

         */

        //this.showLoading = true;
        let objArgs = {
            'orgId': this.orgId,
            'pageSize': this.pageSize,
            'pageNumber': this.currentPageNumber,
            'searchString':this.searchString,
            'includeDeactivated':this.includeDeactivated
        };
        //console.debug('args');
        //console.debug(objArgs);

        const searchResponse = await searchContactApplicationData(objArgs);
        //console.log(searchResponse);
        this.searchResults = this.formatContactDataForDisplay(searchResponse.searchResults);
        this.totalResults = searchResponse.totalResults;
        this.updateMaxPageNumber();


        //let self = this;
        //this.lastRunId = setTimeout(async function(){await self.searchServerSide()}, this.pollInterval);
    }

    async handleSearchKeyUp(event)
    {
        /*
        const isEnterKey = event.keyCode === 13;
        if (isEnterKey) {
            this.currentPageNumber = 1;
            await this.searchServerSide();
        }
         */
    }


    handleSearchChange(event)
    {
        this.searchString = event.target.value;
        this.currentPageNumber = 1;
        this.debouncedSearch();
    }


    // Pagination Functions
    get resultsShowing()
    {
        let iStart = ((this.currentPageNumber - 1) * this.pageSize) + 1;
        let sShowing = iStart + ' - ';
        let iEnd = Math.min((iStart + this.pageSize - 1), this.totalResults);
        sShowing += iEnd;
        return sShowing;
    }

    get showPreviousButton()
    {
        if(this.currentPageNumber == 1)
            return false;
        return true;
    }

    get disablePreviousButton()
    {
        return this.currentPageNumber == 1;
    }

    get disableNextButton()
    {
        if ((this.currentPageNumber) * this.pageSize >= this.totalResults)
            return true;
        return false;
    }

    get showNextButton()
    {
        if ((this.currentPageNumber) * this.pageSize >= this.totalResults)
            return false;
        return true;
    }

    async handlePreviousPage()
    {
        this.currentPageNumber--;
        await this.searchServerSide();
    }

    async handleNextPage()
    {
        this.currentPageNumber++;
        await this.searchServerSide();
    }

    updateMaxPageNumber()
    {
        this.maxPageNumber = Math.ceil(this.totalResults / this.pageSize);
    }
    // END pagination functions



    /*
    showReinviteForContact(contact)
    {
        const hasCNumber = !!contact.OID_ID__c;
        const timeStampOfLastInvite = contact.BAMCSSOLastInvite__c || contact.CreatedDate;
        const timeOfLastRequest =  new Date(timeStampOfLastInvite);
        const now = new Date();
        // set the timeOfLastRequest to be the time after the interval has passed
        timeOfLastRequest.setSeconds(timeOfLastRequest.getSeconds() + this.reinviteTimeInterval);
        const hasIntervalElapsed = now > timeOfLastRequest;
        return !hasCNumber && (hasIntervalElapsed || !timeStampOfLastInvite);
    }

     */

    reinviteEnabledForContact(contact, latestRequestDate)
    {
        //const timeStampOfLastInvite = contact.BAMCSSOLastInvite__c || contact.CreatedDate;
        const timeStampOfLastInvite = contact.BAMCSSOLastInvite__c || latestRequestDate;
        const timeOfLastRequest =  new Date(timeStampOfLastInvite);
        const now = new Date();
        // set the timeOfLastRequest to be the time after the interval has passed
        timeOfLastRequest.setSeconds(timeOfLastRequest.getSeconds() + this.reinviteTimeInterval);
        const hasIntervalElapsed = now > timeOfLastRequest;
        return (hasIntervalElapsed || !timeStampOfLastInvite);
    }

    formatContactDataForDisplay(listContactData)
    {
        for(let iContact = 0; iContact < listContactData.length; ++iContact)
        {
            let contactData = listContactData[iContact];
            let objContact = contactData.contact;

            // if this is the currently logged in user's contact
            if(objContact.Id == this.loggedInUserContactId){
                contactData.currentlyLoggedInUserContact = true;
            }

            // contact active status
            if(objContact.Status__c.toLowerCase() !== 'active'){
                objContact.statusActive = false;
                objContact.displayStatus = 'Inactive'; // we derive the display Status from the Status__c field since we don't want the external users to be aware of the "Left Orgasnisation" status. As fas is the users are concerned, not "Active" means "Inactive".
            } else {
                objContact.statusActive = true;
                objContact.displayStatus = 'Active'; // we derive the display Status from the Status__c field since we don't want the external users to be aware of the "Left Orgasnisation" status. As fas is the users are concerned, not "Active" means "Inactive".
            }

            // contact pending status to determine whether or not to show the de/re-activate buttons
            objContact.hasPending = false;

            let latestRequestDate;

            // loop through the contact applications for this contact to set their status
            let contactApplications = contactData.contactApplications;
            for(let iApplication = 0; iApplication < contactApplications.length; ++ iApplication)
            {
                let contactApplication = contactApplications[iApplication];

                // set the status by the latest BAM External Onboarding Request
                let bamExtRequests = contactApplication.BAM_External_Onboarding_Requests__r;

                contactApplication.statusError = false;
                contactApplication.statusPending = false;
                contactApplication.statusActive = false;

                if(bamExtRequests)
                {
                    // get the first record, which should be latest from SOQL ordering
                    let lastRequest = bamExtRequests[0];
                    if(lastRequest.Status__c == 'Error')
                    {
                        contactApplication.statusError = true;
                        contactApplication.errorMessage = lastRequest.Error__c;
                    }
                    else if(lastRequest.Status__c == 'Pending')
                    {
                        objContact.hasPending = true;

                        contactApplication.statusPending = true;

                        // only show reinvite if there's at least 1 pending + C-number + last reinvite
                        //objContact.showReinvite = this.showReinviteForContact(objContact);
                        if(!objContact.OID_ID__c) {
                            objContact.showReinvite = true;
                            if(!latestRequestDate || lastRequest.Request_Date__c > latestRequestDate)
                                latestRequestDate = lastRequest.Request_Date__c;
                        }
                    }
                }

                // if status cannot be set by the requests, check the contact roles, separated here for pre-launch existing access
                let contactRoles = contactApplication.ContactRoles__r;
                if(!contactApplication.statusError
                    && !contactApplication.statusPending
                    && contactRoles)
                {
                    let role = contactRoles[0];
                    if(role.Status__c == 'Active') {
                        contactApplication.statusActive = true;
                    }
                    else if(role.Status__c == 'Pending') {
                        contactApplication.statusPending = true;

                        objContact.hasPending = true;
                    }
                }
            }

            // todo - update logic on show and enable reinvite button
            if(objContact.showReinvite == true)
            {
                //check if we need to enable the button
                objContact.enabledReinvite = this.reinviteEnabledForContact(objContact, latestRequestDate);
            }
        }

        return listContactData;
    }

    // BEGIN filter functionality
    toggleShowFilters() {
        this.showFilters = !this.showFilters;
    }

    async handleToggleDeactivatedFilter(event)
    {
        this.includeDeactivated = event.target.checked;
        this.currentPageNumber = 1;
        await this.searchServerSide();
    }

    // END filters

    handleEditAction(event) {
        const target = event.target;
        const id = target.dataset.id;
        //this.goToUserPage(id);
        this.navigate.toUserEditPage(id);
    }


    async handleReactivateAction(event)
    {
        const contactId = event.target.dataset.id;
        this.showLoading = true;
        let reactivateResponse = await reactivateContact({'contactId': contactId});
        this.reactivateResultMessage = reactivateResponse.message;
        this.showReactivateResultModal = true;
        await this.searchServerSide();
        this.showLoading = false;
    }

    handleCancelRequest(event) {
        const target = event.target
        const id = target.dataset.id

        this.selectedUserForRequestCancellation = this.findContactById(id);
        console.warn('Cancelling Request::');
        console.warn(this.selectedUserForRequestCancellation);
        this.showRequestCancellationModal();
    }

    handleDeactivateAction(event) {
        const target = event.target
        const id = target.dataset.id

        this.selectedUserForDeactivation = this.findContactById(id);
        console.warn('Deactivating user::');
        console.warn(this.selectedUserForDeactivation);
        this.showDeactivateModal();
    }

    async deactivateSelectedUser() {
        //console.warn(this.selectedUserForDeactivation);
        this.showLoading = true;

        // close the original confirm modal
        this.closeModals();

        // make apex call to commit
        let deprovResponse = await deactivateContact({'contactId': this.selectedUserForDeactivation.Id});

        // display the response message
        this.deactivateResultMessage = deprovResponse.message;
        this.showDeactivateResultModal = true;

        await this.searchServerSide();
        //poll(this.searchServerSide);

        this.showLoading = false;

    }

    async cancelRequestForSelectedUser() {
        this.showLoading = true;

        // close the original confirm modal
        this.closeModals();

        // make apex call to commit
        let cancellationResponse = await cancelContactRequest({'contactId': this.selectedUserForRequestCancellation.Id});

        // display the response message
        this.requestCancellationResultMessage = cancellationResponse.message;
        this.showRequestCancellationResultModal = true;

        await this.searchServerSide();
        //poll(this.searchServerSide);

        this.showLoading = false;
    }

    closeModals() {
        this.showConfirmDeactivateModal = false;
        this.showDeactivateResultModal = false;
        this.showReactivateResultModal = false;
        this.showConfirmRequestCancellationModal = false;
        this.showRequestCancellationResultModal = false;
    }
    closeModalCallback() {
        return this.closeModals.bind(this)
    }
    showDeactivateModal () {
        this.showConfirmDeactivateModal = true
    }
    showRequestCancellationModal () {
        this.showConfirmRequestCancellationModal = true
    }
    // closeDeactivateModal()
    // {
    //     this.showConfirmDeactivateModal = false
    // }
    // get closeDeactivateModalCallback() {
    //     return this.closeDeactivateModal.bind(this)
    // }
    // closeDeactivateResultmodal()
    // {
    //     this.showDeactivateResultModal = false;
    // }
    // get closeDeactivateResultCallback() {
    //     return this.closeDeactivateResultmodal.bind(this)
    // }
    // closeReactivateResultmodal()
    // {
    //     this.showReactivateResultModal = false;
    // }
    // get closeReactivateResultCallback() {
    //     return this.closeReactivateResultmodal.bind(this)
    // }

    // re-invite
    async handleReinviteAction(event) {
        this.showLoading = true;

        const target = event.target;
        const contactId = target.dataset.id;

        let contact = this.findContactById(contactId);
        contact.enabledReinvite = false;

        // apex call
        const objResponse = await reinviteContact({'contactId': contactId});

        if (objResponse.result == 'ok') {
            showToast('success', 'Reinvite email sent.')(this);
        } else {
            showToast('error', 'Reinvite email send was unsuccessful.')(this)
            // re-enable for a retry
            contact.enabledReinvite = true;
        }
        this.showLoading = false;
    }


    /** helper function to find the contact object from the loaded data
     *
     * @param contactId
     * @returns {BamUserPage.dynamicState.contact|{}|newState.contact}
     */
    findContactById(contactId)
    {
        for(let i = 0; i < this.searchResults.length; ++i)
        {
            let contact = this.searchResults[i].contact;
            if(contact.Id == contactId)
                return contact;
        }
    }

    inviteUser() {
        this.navigate.toUserCreatePage();
    }

    backToMerchantPortal(event)
    {
        this.navigate.toHome();
    }

    handlePlatformEvent(event) {
        const message = event.detail
        alert(JSON.stringify(message))
    }
}