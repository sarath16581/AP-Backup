/**
 * Handles the persona switching capability for a community user persona.
 * This is based on the proprietary CSSO implementation in the Aus Post network
 */
import {LightningElement, wire, track, api} from 'lwc';
import getPersonaList from '@salesforce/apex/BAMPersonaController.getCurrentUserPersonas';
import getIdPInitUrl from '@salesforce/apex/BAMPersonaController.getIdPInitUrl';
import switchPersona from '@salesforce/apex/BAMPersonaController.switchPersona';
import uId from '@salesforce/user/Id';


export default class BamPersonaSelector extends LightningElement {

    @track personas;
    @track error;
    @track loggedInUserId = uId;
    @track displayName;
    @track menuOpen;

    idpInitUrl;

    connectedCallback() {
        this.getPersonas();
        this.getLoginUrl();
    }

    async getPersonas() {
        this.personas = await getPersonaList();
        this.personas = this.personas.map(persona => {
            let p = {...persona};
            p.accountDisplay = persona.accountName + (persona.accountNumber ? ' - ' + persona.accountNumber : '');
            if(p.userId === this.loggedInUserId) {
                this.displayName = p.accountDisplay;
                p.isCurrent = true;
            } else {
                p.isCurrent = false;
            }
            return p;
        });

        // only display the persona selector if the current logged in user is already one of the valid personas
        if(!this.displayName) {
            this.personas = null;
        } else if(this.personas.length <= 1) {
            // we should only display the persona selector if there are more than 1 personas
            this.personas = null;
        }
    }

    async getLoginUrl() {
        this.idpInitUrl = await getIdPInitUrl();
    }

    toggleMenu() {
        this.menuOpen = !this.menuOpen;
    }

    /**
     * TODO: Documentation
     */
    doPersonaSwitch(event) {
        let userId = event.currentTarget.dataset.userId;
        console.log('Setting the persona', userId);

        if(this.loggedInUserId !== userId) {
            const promiseSpinner = this.template.querySelector('c-promise-spinner');
            promiseSpinner.addPromise(switchPersona({userId}).then(result => {
                if (result === true) {
                    // the persona was successfully switched
                    // now we redirect the user to idp init login
                    console.log('Persona switched', result);
                    this.reLogin();
                } else {
                    // there was a problem switching the Persona... (might not have found the persona for example)
                    console.log('Persona was not switched', result);
                }
            }).catch(error => {
                // handle error
                console.log('ERROR with Persona Switch', error);
            }));
        }
    }

    reLogin() {
        //console.log(this.idpInitUrl);
        window.location = this.idpInitUrl;
    }

}