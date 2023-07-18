/**
  * @author       : Sameed Khan<sameed.khan@mav3rik.com>
  * @date         : 01/07/2019
  * @description  : User Page in BAM UI
  * 
--------------------------------------- History --------------------------------------------------
01.07.2019    Sameed Khan(Mav3rik)    Created
21.10.2019 hasantha.liyanage@auspost.com.au Modified : Added Super Admins Section
2020-05-25 - Nathan Franklin - Changed the dual listbox to the multi billing account selector
2023-07-17 - Mahesh Parvathaneni - Updated the logic to include billing accounts filtered at app level
**/

/* eslint-disable no-undef */
import { LightningElement, track } from 'lwc';
import retrieveContactData from '@salesforce/apex/BAMUserController.retrieveContactData';
import saveAccessChanges from '@salesforce/apex/BAMUserController.saveAccessChanges';
import savePrimaryBillingAccount from '@salesforce/apex/BAMUserController.savePrimaryBillingAccount';
import retrieveAplicationData from '@salesforce/apex/BAMUserController.retrieveAplicationData';
import retrieveSuperAdmins from '@salesforce/apex/BAMUserController.retrieveSuperAdmins';
import retrieveUserInformation from '@salesforce/apex/BAMUserController.retrieveUserInformation';
import retrieveMerchantPortalCommunityURL from '@salesforce/apex/BAMUserController.retrieveMerchantPortalCommunityURL';
import retrieveContactApplicationsWithLatestExternalOnboardingRequests from '@salesforce/apex/BAMUserController.retrieveContactApplicationsWithLatestExternalOnboardingRequests';
import retrieveActiveContactApplicationsWithLatestExternalOnboardingRequests  from '@salesforce/apex/BAMUserController.retrieveActiveContactApplicationsWithLatestExternalOnboardingRequests';
import retrieveExistingAccessAndRolesWithLinkedEntitiesForContact from '@salesforce/apex/BAMUserController.retrieveExistingAccessAndRolesWithLinkedEntitiesForContact';
import retrieveActiveAccessAndRolesWithLinkedEntitiesForContact from '@salesforce/apex/BAMUserController.retrieveActiveAccessAndRolesWithLinkedEntitiesForContact';
import { getParamsFromURL, showToast, poll, get, find, keyBy, generateLabelForBillingAccount } from 'c/bamUtils';
import { navigation } from 'c/bamNavigationUtils';

export default class BamUserPage extends LightningElement {
    orgId // the id of the organisation that the logged in user belongs to
    navigate // instance of the navigation utility
    billingAccountsMap = {} // map of billing account options keyed by their ID used for rendering the billing account labels in the juicy cart box
    
    @track billingAccountsOptions // options for the billing account options to render
    @track billingAccounts // options for the billing account options to render

    @track contact = {} // contact record of the user whose access is being edited
    @track primaryBillingAccountBSP = ''// BSP specific logic. primary billing account on the contact record
    @track isDirty = false // flag to keep track of if threre were changes made by the user's access so that we can prompt them to ensure that they want to discard their changes when navigating away from the page once changes have been made.
    /*
        this part of the state contains the data about the applications belonging to the organisation, and the level of access the user has to eache app(their role, selected billing accouts, etc.)
        Each element of the array have the following shape:

        {
            ... application, // properties of the BAMApplication__c subject record on server
            isPending, // boolean that is set to "true" pending provisioning or deprovisiong request for this app
            hasError, // boolean that is set to "true" if the last provisioning or deprovisiong request came back with an error
            errorMessage, // error message from recently unsuccessful provisioning or deprovisiong request
            rolePickerOptions, // the options for the role picker for this application. This is basically, The child Application role records for the application with the _no-access option appended at the end
            selectedAppRole, // currently seleceted Applicaiton role fore the application
            selectedAppRoleId, // Id of the selected Application role record, if no role is selected, it defaults to "_no-access"
            isRoleSelected, // boolean that is true if a role is currently selected for  the application
            showBillingAccount, // boolean that is set to true if the currently selected application role allows billing accounts to be selected
            selectedRoleOption, // the role option that is currently selected (this is for rendeirng purposes as the roleOptions property is waht is used to render the role selection button group)
            selectedBillingAccountIds, // currently selected billing account Ids
            selectedBillingAccounts, // the currently selected billing account options (used to render the seleceted billing account list in the juicy cart box)
            allowBSPConsignmentSearch, // value for the "BSP Allow Consignment Serarch" checkbox
            isBSPWithAccess, // boolean set to true if the application is BSP and its access has a role selected
            displayIfRoleHasShowBillingAccounts, // html class string. Set to "slds-hide" if the billing account selecter does not need to be displayed
            displayIfAppIsBSPWithAccess, // html class string. Set to "slds-hide" if the current app is not BSP with a role selected
            displayIfAppIsBSPWithAccessButNotSuperAdmin, // html class string. Set to "slds-hide" if the current app is not BSP with a role selected that is not super admion
            disabledInput, // boolean set to true if the page is in "my access" mode or if the application has pending changes i.e isPending is set to true
            displayErrorMessage, // boolean set to true if the page is not in "my access" mode or if the application has error messages form an unsuccessful provisioning/deprovisioning request i.e hasError is set to true
            disabledClass, // html class string used for stying the disabled radio button group from the theme component
        } 

     */
    @track applications = []

    // flags used for display
    @track userInputsDisabled = false
    @track isLoggedInUser = false
    @track myAccessMode = true
    @track editMode = false
    @track dataLoaded = false
    @track showModal = false
    @track isBamUser = true
    @track isActiveContact = true
    @track superAdmins = []
	@track appBillingAccountDataWrapper = []; //wrapper to store the filtered billing accounts related to app

    get hasBamCSSOError () {
        return !!this.contact.BAMCSSOError__c
    }

    get bamCSSOErrorMessage() {
        // if the BAMCSSOError__c checkbox on the contact is checked we display an error message, empty string otherwise. This error message is contained in the BAMCSSOErrorMessage__c field (if however the error message field is empty despite the checkbox being checked, we display a generic error message).
        return this.contact.BAMCSSOError__c ? this.contact.BAMCSSOErrorMessage__c || 'The user provisioning process failed' : ''
    }

    get isCreateMode() {
        return !this.editMode
    }

    get pageHeader() {
        return this.dataLoaded && this.myAccessMode ? 'My Access' : this.editMode ? 'Edit user' : 'Add new user';
    }

    get provisionButtonLabel() {
        // display 'Save Changes' if we are in editmode and the user doesn't have a c-number or any panding changes. Show 'Invite user' otherwise
        return this.editMode && (this.contact.OID_ID__c || this.hasPendingChanges()) ? 'Save changes' : 'Invite user'
    }

    get hasPageAccess() {
        // logged in user has access to BAM
        // the contact whose page is being edited has an 'Active' status
        // however, if the user in viewing this page in myAccessMode, he should be able to see his level of access even if he doesnt have access to BAM
        return this.myAccessMode || (this.isBamUser && this.isActiveContact)
    }

    get noAccessMessage() {
        return  !this.isBamUser ? 'You do not have access to Access Management.' :
                !this.isActiveContact ? 'The contact you are trying to view is currently inactive.':
                'You do not have the required permissions to view this page.'
    }

    get isEmailInputDisabled() {
        // the email address is only editable if there is no c-number on the contact and no pending app on the page (OR logic)
        return this.hasPendingChanges() || !!this.contact.OID_ID__c
    }

    get isEmailInputRequired () {
        // email input is required if it's not disabled
        return !this.isEmailInputDisabled
    }

    get isNamePopulated() {
        return this.contact.FirstName || this.contact.LastName || this.contact.Email
    }
    get contactName() {
        return `${this.contact.FirstName || ''} ${this.contact.LastName || ''}`
    }
    get contactEmail() {
        return this.contact.Email
    }
    get hasAtLeastOneApplicationAccess() {
        const isRoleSelected = this.applications.filter(app => app.isRoleSelected).length > 0
        return isRoleSelected
    }

    get cardCssClass() {
        return (this.myAccessMode ? 'no-footer' : '');
    }

    async connectedCallback() {
        try {
            // retrieve the community prefix and initialise the navigation
            const commURL = await retrieveMerchantPortalCommunityURL()
            this.navigate = navigation(commURL)

            // use URL parameters to determine what 'mode' the component should render in. If the userId is present in the URL
            // we determine that the component is being used to edit that user's access. If the createUser flag is set we deduce 
            // that the page is being used to create a new user. If neither param is present in the URL the page is in 'My Access' 
            // mode. which is the default mode.
            const {userId, createUser} = getParamsFromURL(window.location.href)
            const contactId = userId
            if (createUser) {
                this.myAccessMode = false
            } else if(contactId) {
                this.myAccessMode = false
                this.editMode = true
            }
            this.contact.Id = userId
            // retrieve information about the logged in user to determine the organisation they belong to, whther they have access 
            // to BAM and waht's the id of the contact associated with the logged in user
            const { orgId, loggedInUserContactId, isBAMUser } = JSON.parse(await retrieveUserInformation())
            this.orgId = orgId
            this.isBamUser = isBAMUser 
            this.isLoggedInUser = loggedInUserContactId === userId
            if (this.myAccessMode) {
                await this.retrieveDataAndSetState(orgId, loggedInUserContactId, true)
            } else if (this.isBamUser){
                if(this.editMode) {
                    await this.retrieveDataAndSetState(orgId, contactId)
                    // START POLLING IF user has access to view this page
                    if (this.hasPageAccess) {
                        poll(this.reloadDataToReflectChangesInPendingApps)
                    }
                } else {
                    await this.retrieveDataAndSetStateForCreateMode(orgId)
                }
            }
            this.dataLoaded = true
        } catch (er) {
            console.error(er)
        }
    }

    /** 
     *  This method is called repeatedly to retrieve data from the server for live updates. 
     *  Since the user is allowed to make changes in the same page while the updates from the server is being polled for,
     *  we only update the display state for applications whose access chnages are currently pending and are therefore 
     *  locked from editing. For most cases, this means merely checking for the latest External Onboarding Request record to 
     *  determine if the UI for that application's access should be unlocked. The exception is when a deprovisioning request 
     *  for an app fails. For such a case we need to reset the applications access state to be what it was previously before 
     *  the deprovision request was made.  
     */
    reloadDataToReflectChangesInPendingApps = async () => {
        try {
            // if data is not loaded (this means thre is an ongoing request fetching the data, may be inital load or from a invite/save request) then return early as there's no need to reload data
            if (!this.dataLoaded) {
                return
            }
            // retrieve the access data and the latest external onboarding requests
            const [contactDataStr, contactApplicationsWithLatestExternalOnboardingRequestsStr, accessDataStr] = await Promise.all([
                retrieveContactData({ contactId: this.contact.Id }),
                retrieveContactApplicationsWithLatestExternalOnboardingRequests({contactId: this.contact.Id}),
                retrieveExistingAccessAndRolesWithLinkedEntitiesForContact({contactId: this.contact.Id})
            ])
            // generate initial state from data retrieved from server
            // update contact with CSSO Error fields so we we can update the display with error messages if need be
            const contact = JSON.parse(contactDataStr)
            this.contact.OID_ID__c = contact.OID_ID__c
            this.contact.BAMCSSOLastInvite__c = contact.BAMCSSOLastInvite__c
            this.contact.BAMCSSOError__c = contact.BAMCSSOError__c
            this.contact.BAMCSSOErrorMessage__c = contact.BAMCSSOErrorMessage__c

            const accessData = this.formatAccessData(JSON.parse(accessDataStr))
            
            const contactApplicationsWithLatestExternalOnboardingRequests = JSON.parse(contactApplicationsWithLatestExternalOnboardingRequestsStr)

            // reconcile the changes found in the database with the current page state (which may have been changed due to user input). 
            // But only do so for the pending apps as those are the ones for which the UI has to be updated with the latest data fetched from the server
            // set the component's state with data retrieved from the server
            const pendingApps = this.applications.filter(app => app.isPending)
            pendingApps.forEach(app => this.generateAppState(app, contactApplicationsWithLatestExternalOnboardingRequests, accessData))
        } catch (er) {
            console.error(er)
        }
    }

    hasPendingChanges() {
        const hasPendingChanges = Array.isArray(this.applications) && this.applications.filter(app => app.isPending).length > 0 // check if the user has pending changes for any app   
        return hasPendingChanges
    }

    // loads data from server for 'Edit mode' and sets up the components state
    // If "activeRecordsOnly" flag is tes to true, the function retrieves data for when the component is in 'My Access' mode. Only the "active" application access is fetched 
    // for the contact and for the applications belonging to the organization of that contact
    
    async retrieveDataAndSetState(orgId, contactId, activeRecordsOnly = false) {
        let contactApplicationsRetrievalFunction = retrieveContactApplicationsWithLatestExternalOnboardingRequests
        let exisitingAccessRetrievalFunction = retrieveExistingAccessAndRolesWithLinkedEntitiesForContact
        if (activeRecordsOnly) {
            contactApplicationsRetrievalFunction = retrieveActiveContactApplicationsWithLatestExternalOnboardingRequests
            exisitingAccessRetrievalFunction = retrieveActiveAccessAndRolesWithLinkedEntitiesForContact
        }
        try {
            // fetch data from server
            const [contactDataStr, contactApplicationsWithLatestExternalOnboardingRequestsStr, accessDataStr, appDataStr, superAdminsDataStr] = await Promise.all([
                retrieveContactData({ contactId }),
                contactApplicationsRetrievalFunction({ contactId }),
                exisitingAccessRetrievalFunction({ contactId }),
                retrieveAplicationData({ orgId, contactId }),
                retrieveSuperAdmins({ orgId }),
            ])
            // parse data
            const contact = JSON.parse(contactDataStr)
            const contactApplicationsWithLatestExternalOnboardingRequests = JSON.parse(contactApplicationsWithLatestExternalOnboardingRequestsStr)
            const accessData = this.formatAccessData(JSON.parse(accessDataStr))
            const { applicationsWithRoles, appBillingAccountDataWrapper } = JSON.parse(appDataStr);
			this.appBillingAccountDataWrapper = appBillingAccountDataWrapper;
            const superAdmins = JSON.parse(superAdminsDataStr);

            // BSP specific logic to support legacy functionality
            this.primaryBillingAccountBSP = contact.BillingAccount__c
            contact.primaryBillingAccountId = contact.BillingAccount__c

            // generate state            
            const appList = this.generatePageState(applicationsWithRoles, contactApplicationsWithLatestExternalOnboardingRequests, accessData)

            // set state
            this.applications = appList
            this.isloggedInUser = !!contactId && this.loggedInUserContactId === contactId 
            this.contact = contact
            this.isActiveContact = contact.Status__c === 'Active'
            this.userInputsDisabled = true
            this.superAdmins = superAdmins;
        } catch (er) {
            console.error(er)
        }
    }

    // this is done to get around the SOQL query Limit
    // TODO: document this
    formatAccessData(wrappedAccessData){
       return Object.values(wrappedAccessData).map(wrappedRecord => ({
            ...wrappedRecord.record,
            LinkedEntities__r: {
               records : wrappedRecord.childList
            }
       }))
    }


    generatePageState(applicationsWithRoles, contactApplicationsWithLatestExternalOnboardingRequests = [], accessData = []) {
        applicationsWithRoles.forEach(app => this.generateAppState(app, contactApplicationsWithLatestExternalOnboardingRequests, accessData))
        return applicationsWithRoles
    }

    generateAppState(app, contactApplicationsWithLatestExternalOnboardingRequests, accessData) {
        // check latest external onboarding request status to see if the application access is pending or in Error
        const contactApplicationRecord = find(contactApplicationsWithLatestExternalOnboardingRequests, {'Application__c': app.Id})
        const latestPendingExternalRequestRecords = contactApplicationRecord && get(contactApplicationRecord, 'BAM_External_Onboarding_Requests__r.records')
        const latestPendingExternalRequest = latestPendingExternalRequestRecords && latestPendingExternalRequestRecords.length>0 && latestPendingExternalRequestRecords[0]// There will only ever be one record since we query for the latest EOB
        const isAccessPendingRemoval = contactApplicationRecord && contactApplicationRecord.Pending_Delete__c

        let isPending = false
        let hasError = false
        let errorMessage = ''
        if (latestPendingExternalRequest && latestPendingExternalRequest.Status__c === 'Pending') {
            isPending = true
        } else if (latestPendingExternalRequest && latestPendingExternalRequest.Status__c === 'Error') {
            hasError = true
            errorMessage = latestPendingExternalRequest.Error__c || 'an error has occurred'
        }

        const selectedRole = find(accessData, role => get(role,'ContactApplication__r.Application__c') === app.Id)
        const selectedBillingAccountIds = selectedRole ? get(selectedRole, 'LinkedEntities__r.records',[]).map(le => le.BillingAccount__c) : []
        
        // setting up role picker options
        const noAccessOption = { label: 'No Access', value: '_no-access', description: `This user will not have access to ${app.Name}` }
        const applicationRoleOptions = app.ApplicationRoles__r.records.map(role => ({ 
            'value': role.Id, 
            'label': role.Role__c, 
            'showBillingAccounts': role.ShowBillingAccount__c,
            'description': role.RoleDescription__c,
            ...role,
        }))
        const rolePickerOptions = [...applicationRoleOptions, noAccessOption]

		//get the billing accounts by app
		app.billingAccountOptions = [];
		let billingAccountWrapperData = this.appBillingAccountDataWrapper.find(billingAccountData => app.Id === billingAccountData.bamApplicationId);
		if(billingAccountWrapperData){
			app.billingAccounts = billingAccountWrapperData.billingAccounts;
			app.billingAccountsOptions = app.billingAccounts.map(billingAccount => ({ value: billingAccount.Id, label: generateLabelForBillingAccount(billingAccount) }))
            app.billingAccountsMap = keyBy(app.billingAccountsOptions, 'value')
		}
                

        app.isPending = isPending
        app.hasError = hasError
        app.errorMessage = errorMessage
        app.rolePickerOptions = rolePickerOptions
        app.selectedAppRole = (!isAccessPendingRemoval && selectedRole && selectedRole.ApplicationRole__r )? selectedRole.ApplicationRole__r : {}
        app.selectedAppRoleId = (!isAccessPendingRemoval && selectedRole && selectedRole.ApplicationRole__r && selectedRole.ApplicationRole__r.Id )? selectedRole.ApplicationRole__r.Id : '_no-access'
        app.isRoleSelected = app.selectedAppRoleId !== '_no-access'
        app.showBillingAccount = !!app.selectedAppRole.ShowBillingAccount__c
        app.selectedRoleOption = find(app.rolePickerOptions, {'value' : app.selectedAppRoleId}) || {}
        app.selectedBillingAccountIds = selectedBillingAccountIds
        app.selectedBillingAccounts = selectedBillingAccountIds.map(baId => app.billingAccountsMap[baId])
        app.allowBSPConsignmentSearch = !!(contactApplicationRecord && contactApplicationRecord.BSPCanViewAllConsignments__c)
        app.isBSPWithAccess = app.AppKey__c === 'BSP' && app.selectedRoleOption.value !== '_no-access'
        app.displayIfRoleHasShowBillingAccounts = app.selectedRoleOption.showBillingAccounts ? '' : 'slds-hide'
        app.displayIfAppIsBSPWithAccess = app.isBSPWithAccess ? '' : 'slds-hide'
        app.displayIfAppIsBSPWithAccessButNotSuperAdmin = app.isBSPWithAccess && app.selectedRoleOption.label !== 'Super Admin' ? '' : 'slds-hide'
        app.disabledInput = (this.myAccessMode || app.isPending)
        app.displayErrorMessage = (!this.myAccessMode && app.hasError)
        app.disabledClass = (this.myAccessMode || app.isPending) ? 'disabled' : ''
    }

    // loads data from server for 'Create mode' and sets up the components state
    async retrieveDataAndSetStateForCreateMode(orgId) {
        try {
            const appDataStr = await retrieveAplicationData({orgId, contactId})
            const { applicationsWithRoles, appBillingAccountDataWrapper } = JSON.parse(appDataStr);
			this.appBillingAccountDataWrapper = appBillingAccountDataWrapper;
            const appList = this.generatePageState(applicationsWithRoles);
            this.applications = appList
            this.contact.orgId = orgId
        } catch (er) {
            console.error(er)
        }
    }

    handleRoleChange(event) {
        this.isDirty = true
        const { name, value } = event.target
        const appId = name
        const roleId = value

        const app = find(this.applications, {'Id': appId})   
        const selectedRole = find(app.ApplicationRoles__r.records, {'Id': roleId}) || {}

        // check if the logged in user is trying to remove their own access from BAM, if so, don;t let them do it
        if (app.AppKey__c === 'BAM' && this.isLoggedInUser && event.target.value === '_no-access') {
            showToast('error', "You can't remove your own access", 'dismissable')(this)
            // we reset the value in asynchronously as the lightning-radio-group base component does not rerender if its 'value' is changes synchronously
            const prevRoleId = app.selectedAppRoleId
            app.selectedAppRoleId = roleId
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => {
                app.selectedAppRoleId = prevRoleId
            }, 50) // the 10 ms delay is so that the user can see it switch back(nicer user experience than it not seeing the value change when clicked)
        } else {
            app.selectedAppRole = selectedRole
            app.selectedAppRoleId = (selectedRole && selectedRole.Id) ? selectedRole.Id : '_no-access'
            app.isRoleSelected = app.selectedAppRoleId !== '_no-access'
            app.showBillingAccount = !!app.selectedAppRole.ShowBillingAccount__c     
            app.selectedRoleOption = find(app.rolePickerOptions, {'value' : roleId}) || {}
            app.isBSPWithAccess = app.AppKey__c === 'BSP' && app.selectedRoleOption.value !== '_no-access'
            app.displayIfRoleHasShowBillingAccounts = app.selectedRoleOption.showBillingAccounts ? '' : 'slds-hide'
            app.displayIfAppIsBSPWithAccess = app.isBSPWithAccess ? '' : 'slds-hide'
            app.displayIfAppIsBSPWithAccessButNotSuperAdmin = app.isBSPWithAccess && app.selectedRoleOption.label !== 'Super Admin' ? '' : 'slds-hide'
            app.disabledInput = (this.myAccessMode || app.isPending)
            app.displayErrorMessage = (!this.myAccessMode && app.hasError)
            app.disabledClass = (this.myAccessMode || app.isPending) ? 'disabled' : ''
        }
    }

    // Event handlers
    handlePrimaryBillingAccountChange(event) {
        this.isDirty = true
        this.primaryBillingAccountBSP = event.target.value
    }

    handleToggleAllowBSPConsignmentSearch(event) {
        this.isDirty = true
        const { name, checked } = event.target
        const appId = name
        const app = find(this.applications, {'Id': appId}) 
        app.allowBSPConsignmentSearch = checked
    }

    handleBillingAccountSelect(event) {
        this.isDirty = true;

        const appId = event.detail.applicationId
        const selectedBillingAccountIds = event.detail.selected

        const app = find(this.applications, {'Id': appId})   
        app.selectedBillingAccountIds = selectedBillingAccountIds
        app.selectedBillingAccounts = selectedBillingAccountIds.map(baId => app.billingAccountsMap[baId])
    }

    handleRecepientChange(event) {
        this.isDirty = true
        const { name, value } = event.target
        this.contact[name] = value
    }

    // iterates through all the imput components that have a "form-input" class and checks if they are valid. Returns true if all are valid, false if even one of them are invalid
    validateInputs() {
        const inputComponents = this.template.querySelectorAll(".form-input");
        const inputsArray = inputComponents ? [...inputComponents] : [];
        return inputsArray.reduce((acc, inputCmp) => {
            inputCmp.reportValidity();
            return acc && inputCmp.checkValidity();
        }, true)
    }

    /**
     *  Sends invite when a user and their access is created or edited
     * 
     *  This function first validates that all the required inputs are populated. Next it sends the page state in the 
     *  applications list to the server. The server then performs the server side validations and reconciles the difference 
     *  between the current page state the users existing level of access for each app and sends back success message or an 
     *  aurahandled exception. This function then displays relevant toast with eror or success messages.
     */
    async sendInvite() {
        try { 
            // validate that the required input fields have been filled
            const isValid = this.validateInputs()
            if (!isValid) {
                showToast('error', 'Complete all required fields')(this)
                return
            }
            // for create mode, ensure that the users access has been changed before sending server request
            // this is so that they can't create a user/contact without giving them access to an application
            // we do this bu cheking that at least one role is seceted
            const hasAtLeastOneRoleSelected = this.applications.filter(app => app.selectedAppRoleId !== '_no-access').length > 0;
            if (!this.editMode && !hasAtLeastOneRoleSelected) {
                showToast('error', 'Select application for the new user')(this)
                return
            }
            
            //show spinner
            this.dataLoaded = false
            let accessChangeResult

            /* 
            BSP specific logic to support legacy primary billing account feature.
            This operation of whether primary account has been changed has been implemented differently than the other changes (where we compute the change operations in the computeDiff function) 
            as this solely exists for the purpose of supporting legacy feature and there is no plan of doing something similar for other apps and this may even be removed later
            */
            
            // If in editMode and the primary billing account has been changed, we enable them to change it even though no other change is present  
            const hasPrimaryBillingAccountChanged = this.primaryBillingAccountBSP && this.primaryBillingAccountBSP !== this.contact.primaryBillingAccountId
            if (this.editMode){
                if (hasPrimaryBillingAccountChanged) {
                    // savePrimaryBilling acc in server
                    const billingAccSaveSuccess = await savePrimaryBillingAccount({
                        primaryBillingAccountId: this.primaryBillingAccountBSP, 
                        contactId: this.contact.Id,
                    })
                    if (!billingAccSaveSuccess){
                        this.contact.primaryBillingAccountId = this.primaryBillingAccountBSP    
                    }
                }
            } else { // If in create mode, we need to pass the primaryBillingAccountBSP in the contact payload so that the neyly created contact has a billing account
                this.contact.primaryBillingAccountId = this.primaryBillingAccountBSP || null
            }

            const contactData = this.contact
            const accessChangeResultsStr = await saveAccessChanges({ 
                contactDataJSON: JSON.stringify(contactData),
                pageState: this.applications
            })
            accessChangeResult = JSON.parse(accessChangeResultsStr)
            if(accessChangeResult.success){
                showToast('success', accessChangeResult.message)(this)
                this.isDirty = false
        
                // if we are in create mode we navigate to the newly created user's view
                if (this.editMode) {
                    await this.retrieveDataAndSetState(this.orgId, this.contact.Id)
                } else {
                    this.navigateToEditPage(accessChangeResult.contactId)
                }
            } else {
                throw new Error(accessChangeResult.message)
            }
        } catch(err) {
            console.log(err)
            showToast('error', get(err,'body.message') || get(err,'message'))(this)
        } finally {
            // hide spinner
            this.dataLoaded = true
        }
    }

    navigateToUsers() {
        this.navigate.toUsers()
    }

    navigateToHome() {
        this.navigate.toHome()
    }

    navigateToEditPage(userId) {
        this.navigate.toUserEditPage(userId)
    }

    showConfirmDiscardModal() {
        if (this.isDirty) {
            this.openModal()
        } else {
            this.navigate.toUsers()
        }
    }

    openModal = () => {
        this.showModal = true
    }

    closeModal = () => {
        this.showModal = false
    }
}