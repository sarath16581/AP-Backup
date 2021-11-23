({
    /**
     * validate URL and making compensation call if valid
     * @param {*} component 
     */
    retrieveCompensation : function(component)  
    {
        this.validateParameters(component) && this.getCompensation(component);
    },

    retrieveNextStepsConfiguration : function(component)
    {
        this.spinnerOnFor(component);

        let getNextStepAction = component.get('c.getNextStepsMetadata');

        getNextStepAction.setParams(
            {
                mtdGroup : 'nextStepsCompensation',
            }
        );

        getNextStepAction.setCallback(this, function(response)
        {
            let status = response.getState();

            if (status === 'SUCCESS')
            {
                component.set('v.nextStepsConfiguration', this.processNextStepConfiguration(component, response.getReturnValue()));
                component.set('v.nextStepsReady', true);
            }
            else if (status === "ERROR") 
            {  
                var errors = response.getError();
                var isUserDefinedException = errors[0].isUserDefinedException;
                // errors could be user defined or system defined
                if (errors && !isUserDefinedException) {
                    this.setInvalid(component,'internal');// system errors
                } else {
                    this.setInvalid(component,'generic');// generic errors handled by AuraHandledException
                }
            } else // any other errors, default it as system errors
            {
                this.setInvalid(component,'internal');
            }
            this.spinnerOffFor(component);
        })

        $A.enqueueAction(getNextStepAction);
    },

    /**
     * 
     * @param {*} component 
     * @returns 
     */
    checkTransactionData : function(component)
    {
        // check email & case number provided
        let providedCaseNumber = component.get('v.wizardData.compensation.transaction.caseNumber');
        let providedEmail = component.get('v.wizardData.compensation.transaction.cEmail');
        let masterCaseNumber = component.get('v.wizardData.compensation.master.Case__r.CaseNumber');
        let masterEmail = component.get('v.wizardData.compensation.master.Case__r.ContactEmail');

        // mobile tend to capitalize first letter
        providedEmail = providedEmail.toLowerCase();
        providedEmail = providedEmail.trim();
        masterEmail = masterEmail.toLowerCase();
        masterEmail = masterEmail.trim();

        return ((providedCaseNumber == masterCaseNumber) && (providedEmail == masterEmail));
    },

    checkAttemps : function(component)
    {
        let attemps = component.get('v.wizardData.compensation.__attemps');
        let maxAttemps = this.getMaxAttemps(component);
        if (attemps >= maxAttemps)
            this.setInvalid(component, 'generic');
        else
            return true;
    },

    /**
     * make serve trip to increase attemps counter for this compensation
     * @param {*} component 
     */
    increaseAttemps : function(component)
    {
        // increase counter in front-end
        let attemps = component.get('v.wizardData.compensation.__attemps');
        attemps++;
        component.set('v.wizardData.compensation.__attemps', attemps);

        let recordId = component.get('v.wizardData.compensation.master.Id');

        // if the updated attempt equal the max attempt, send user to error page
        let maxAttempts = this.getMaxAttemps(component);
        if (attemps == maxAttempts)
        {
            this.registerMixAnalyticsEvent(component, {form : 'page1_out_of_attemps', interact : 'page1_and_2_button_continue', trackingType : this.FORM_NAVIGATE_TRACKING_TYPE});
            this.setInvalid(component, 'generic');
        }
        // else, show the warning
        else
        {
            this.registerMixAnalyticsEvent(component, {form : 'page1_mismatch_case_detail', interact : 'page1_and_2_button_continue'});
            this.bringErrorsToSurface(component, [{
                name : 'Incorrect data',
                label : 'We couldn\'t find any active claims matching those details.'
            }]); 
        }

        // disable the next button to avoid error from continuously clicking
        component.set('v.disablePage1NextButton', true);

        // update the counter in back-end
        let counterAction = component.get('c.increaseAttempsCounter');

        counterAction.setParams({
            recordId
        });

        counterAction.setCallback(this, function(response) {
            component.set('v.disablePage1NextButton', false);
        })

        $A.enqueueAction(counterAction);
    },

    /**
     * DDS-5820: process retrieved metadata into consumable configuration
     * @param {*} component
     * @param {*} response: response from metadata retrieving
     * @returns: next steps configuration
     */
    processNextStepConfiguration : function(component, response)
    {
        // safe escape
        if(!response)
        return [];

        // process metadata into consumable configuration
        let configuration = [];
        response.forEach(meta => {
            configuration.push({
                id : meta.Step_ID__c,
                label : this.replaceAnchorString(component, meta.Label__c),
                image : meta.Image__c,
                sublabel : this.replaceAnchorString(component, meta.Sub_Label__c),
            })
        })
        return configuration;
    },

    /**
     * validate token parameter
     * @returns 
     */
    validateParameters : function(component)
    {
        this.spinnerOnFor(component);

        let search = window.location.search;

        // early quit if no search string found
        if ($A.util.isEmpty(search))
        {
            component.set('v.invalidCompensationDetail', 'no query parameter');
            this.registerAnalyticsEvent(component, 'page1_invalid_compensation');
            return this.setInvalid(component, 'generic');
        }
            
        // check token exist
        let parameters = this.getParameters(search);
        if ($A.util.isEmpty(parameters['token']))
        {
            component.set('v.invalidCompensationDetail', 'no token parameter');
            this.registerAnalyticsEvent(component, 'page1_invalid_compensation');
            return this.setInvalid(component, 'generic');
        } else
        {
            component.set('v.token', parameters['token']);
        }
        return true;
    },

    getParameters : function(search)
    {
        let urlParameters = new URLSearchParams(search);
        let parameters = Object.fromEntries(urlParameters.entries());
        return parameters;
    },

    /**
     * enable invalid message
     * @param {*} component 
     * @param {*} detail 
     */
    setInvalid : function(component, detail)
    {
        component.set('v.errorType', detail);
        component.set('v.summonGuardian', true);
        this.clearMasterData(component);
        this.spinnerOffFor(component);
    },

    /**
     * 
     * @param {*} component 
     */
    clearMasterData : function(component)
    {
        component.set('v.wizardData.compensation.master', null);
    },

    getCompensation : function(component)
    {
        let getCompensationAction = component.get('c.getCompensationByToken');

        getCompensationAction.setParams({
            token : component.get('v.token'),
        });

        getCompensationAction.setCallback(this, function(response)
        {
            let state = response.getState();

            if (state == 'SUCCESS')
            {
                this.processCompensationRecord(component, response.getReturnValue());
            }
            else if (state === "ERROR") 
            {
                var errors = response.getError();
                let errorDetail = this.getErrorMessage(errors);
                var isUserDefinedException = errors[0].isUserDefinedException;
                // errors could be user defined or system defined
                if (errors && !isUserDefinedException) {
                    component.set('v.internalErrorDetail', errorDetail);
                    this.registerAnalyticsEvent(component, 'internal_error');
                    this.setInvalid(component,'internal');// system errors
                } else {
                    component.set('v.invalidCompensationDetail', errorDetail);
                    this.registerAnalyticsEvent(component, 'page1_invalid_compensation');
                    this.setInvalid(component,'generic');// generic errors handled by AuraHandledException
                }
            } else // any other errors, default it as system errors
            {
                this.setInvalid(component,'internal');
            }
            this.spinnerOffFor(component);
        })

        $A.enqueueAction(getCompensationAction);
    },

    processCompensationRecord : function(component, response)
    {
        component.set('v.wizardData.compensation.master', Object.assign({}, response.compensation));

        // keep counter at front end for quick check
        component.set('v.wizardData.compensation.__attemps', response.compensation.Compensation_Form_Attemps__c || 0);


        // store max attemps from setting
        component.set('v.__maxAttemps__', response.maxAttemps);

        // store time stamp
        component.set('v.__timestamp__', Date.now());

        // [DDS-6632]
        this.setInteractionListener(component);

        // [DDS-6632]
        this.stopContextMenu(component);

        // [DDS-6632]
        this.sweetBox(component);

        // process long description
        this.processLongDescription(component);

        // [DDS-8344] consolidate receiver address from case's receiver address components
        this.consolidateReceiverAddress(component);
    },

    /**
     * check that required field have data
     * @param {*} component 
     * @returns 
     */
    checkPresentOfData : function(component)
    {
        let inputs = this.asArray(component.find('chasInput'));
        let errors = [];

        let msgs = this.errorMessageRegister();

        for (let input of inputs)
        {
            // name of input
            let name = input.get('v.name');

            // error message
            let error = msgs[name] || 'Please enter a valid ' + name;

            // value of input
            let value = input.get('v.value');

            // is input required
            let isRequired = input.get('v.required');

            // perform validation
            if (isRequired && $A.util.isEmpty(value))
            {
                errors.push({
                    name : name,
                    label : name + ': ' + error
                });

                // set the error on the input box as well
                input.set('v.showError', true);
                input.set('v.error', msgs[name]);
            }
        }

        // display errors
        if (!$A.util.isEmpty(errors))
        {
            this.accumulateErrors(component, errors);
            return false;
        }
        else return true;
    },

    /**
     * check provided data against validation method
     * @param {*} component 
     * @returns 
     */
    checkDataFormat : function(component)
    {
        let inputs = this.asArray(component.find('chasInput'));
        let validations = this.validationRegister();
        let errorMessages = this.errorMessageRegister();
        let errors = [];
        for (let input of inputs)
        {
            // name of input
            let name = input.get('v.name');

            // [DDS-8344] trim case number & email before passing to validation
            // other inputs are not subject to this trimming since they need to strictly follow required format
            // TODO: put this trimming option on validateEmail method of ss_UiWizardPage. Since this is a fast update we will only handle the input from here.
            if (name == 'Case number'|| name == 'Email address')
            {
                let value = input.get('v.value') || '';
                value = value.trim();
                input.set('v.value', value);
            }

            // get validation method
            let validation = validations[name];

            // get custom error message
            // fall back error message is defined in validating method
            let errorMessage = errorMessages[name];

            // perform validation
            validation && validation.bind(this)(input, true, errorMessage);

            // get error if validation fail
            let error = input.get('v.error');

            // accumulate error for displaying on surface
            !$A.util.isEmpty(error) && errors.push({
                name : name,
                label : name + ': ' + error
            });
        }

        // display errors
        if (!$A.util.isEmpty(errors))
        {
            this.accumulateErrors(component, errors);
            return false;
        }
        else return true;
    },

    /**
     * register of validation for each input
     * @returns 
     */
    validationRegister : function()
    {
        return {
            'First Name' : this.validateGivenName,
            'Last Name' : this.validateSurname,
            'Case number' : this.validateCaseNumber,
            'Email address' : this.validateEmail,
            'Account name' : this.validateAccountName,
            'BSB number' : this.validateBSBNumber,
            'Account number' : this.validateAccountNumber,
        }
    },

    /**
     * central register for error message of inputs
     */
    errorMessageRegister : function()
    {
        return {
            'First Name' : 'Enter given name',
            'Last Name' : 'Enter surname',
            'Case number' : 'Please enter a valid case number',
            'Email address' : 'Please enter a valid email address',
            'Account name' : 'Please enter an account name',
            'BSB number' : 'Please enter a valid 6-digit BSB number',
            'Account number' : 'Please enter the account number',
        };
    },

    /**
     * check if string represent numeric format
     * @param {*} input
     * @param {*} showError
     * @returns 
     */
    validateCaseNumber : function(input, showError)
    {
        // safe escape
        if (!input)
        {
            return;
        }
            
        input.set('v.showError', showError);
        
        // value of input
        let value = input.get('v.value');
        
        if(value && !value.match(/^[0-9]+$/i))
            input.set('v.error', 'Please enter a valid case number');
            
        return ($A.util.isEmpty(input.get('v.error')));
    },

    validateBSBNumber : function(input, showError)
    {
        if (!input)
        {
            return;
        }
            
        input.set('v.showError', showError);

        // value of input
        let value = input.get('v.value');

        if(value && !value.match(/^[0-9]{6}$/i))
            input.set('v.error', 'Please enter a valid 6-digit BSB number');
            
        return ($A.util.isEmpty(input.get('v.error')));
    },

    validateAccountName : function(input, showError)
    {
        if (!input)
        {
            return;
        }
            
        input.set('v.showError', showError);

        // value of input
        let value = input.get('v.value');

        if(value && value.match(/\d/))
        {
            input.set('v.error', 'Please enter an account name');
        }
            
        return ($A.util.isEmpty(input.get('v.error')));
    },

    validateAccountNumber : function(input, showError)
    {
        if (!input)
        {
            return;
        }
            
        input.set('v.showError', showError);

        // value of input
        let value = input.get('v.value');

        if(value && !value.match(/^[0-9]{4,12}$/i))
            input.set('v.error', 'Please enter the account number');
            
        return ($A.util.isEmpty(input.get('v.error')));
    },

    /**
     * enable error summary
     * @param {*} component 
     * @param {*} errors 
     */
    bringErrorsToSurface : function(component, errors)
    {
        !$A.util.isEmpty(errors) && component.set('v.errors', errors);   
        this.showErrorSummary(component);
    },

    genericErrorProcess : function(component, error)
    {
        // aura handle exception
        if (Array.isArray(error))
        {
            let msg = '';
            error.forEach(detail => {
                msg += detail.message + '.';
            })

            this.setInvalid(component, msg);
        }
        else
            this.setInvalid(component, 'Error')
    },

    /**
     * turn spinner on
     * @param {*} component 
     */
    spinnerOnFor : function(component)
    {
        component.set('v.spin', true);
    },

    /**
     * turn spinner off
     * @param {*} component 
     */
    spinnerOffFor : function(component)
    {
        component.set('v.spin', false);
    },

    flipToPage : function(component, page)
    {
        switch(page) {
            case 1:
                component.set('v.screen1', true);
                component.set('v.screen2', false);
                component.set('v.screen3', false);
                component.set('v.screen4', false);
                this.registerAnalyticsEvent(component, 'page1');
                break;
            case 2:
                component.set('v.screen1', false);
                component.set('v.screen2', true);
                component.set('v.screen3', false);
                component.set('v.screen4', false);
                this.registerAnalyticsEvent(component, 'page2');
                break;
            case 3:
                component.set('v.screen1', false);
                component.set('v.screen2', false);
                component.set('v.screen3', true);
                component.set('v.screen4', false);
                this.registerAnalyticsEvent(component, 'page3');
                break;
            case 4:
                component.set('v.screen1', false);
                component.set('v.screen2', false);
                component.set('v.screen3', false);
                component.set('v.screen4', true);
                this.registerAnalyticsEvent(component, 'page4');
                break;
            default:
                //
                break;
        }
    },

    /**
     * @param {*} component
     * @param {*} text: text to replace
     * @returns: replaced text
     */
    replaceAnchorString : function(component, text)
    {
        // safe escape
        if ($A.util.isEmpty(text))
            return text;
        
        let regex = new RegExp('\\{!(.*?)\\}','g');
        let allMatches = text.match(regex) || [];
        for (let anchorString of allMatches)
        {
            let actualValue = component.get(anchorString.substring(2, anchorString.length - 1)) || '';  // strip the {!} part
            text = text.replace(anchorString, actualValue);
        }
        return text;
    },

    setInteractionListener : function(component)
    {
        let device = $A.get('$Browser.formFactor');

        let options = {
            once : true
        };

        window.addEventListener('keydown', this.interactionHandler.bind(this, component), options);

        if (device == 'PHONE')
        {
            window.addEventListener('touchmove', this.interactionHandler.bind(this, component), options);
        }
        else if (device == 'DESKTOP')
        {
            window.addEventListener('mousemove', this.interactionHandler.bind(this, component), options);
        }
        else
        {
            component.set('v.disablePage1NextButton', false);
        }
    },

    interactionHandler : function(component, options)
    {
        // enable next button on page 1 and set the interact flag so it won't be set again by other event
        if (!component.get('v.__interact__'))
        {
            component.set('v.disablePage1NextButton', false);
            component.set('v.__interact__', true);
        }
    },

    innocent : function(component)
    {
        let delta = Date.now() - component.get('v.__timestamp__');

        if (delta < 2000)
        {
            return this.setInvalid(component, 'generic');
        }

        let sweetBox = component.find('sweetBox');

        if (!sweetBox) return true;
        
        let honey = sweetBox.reportInputValue() || sweetBox.get('v.value');
        
        if (!$A.util.isEmpty(honey))
        {
            return this.setInvalid(component, 'generic');
        }

        return true;
    },

    /**
     * everything about you is right, except the click
     * @param {*} component 
     */
    stopContextMenu : function(component)
    {
        document.addEventListener('contextmenu', $A.getCallback((e) => {
            e.preventDefault();
        }), false);
    },

    sweetBox : function(component)
    {
        let pot = component.find('customerIdentity');
        if (!pot) return;
        pot.getElement().style.position = 'absolute';
        pot.getElement().style.top = '-3000px';
        pot.getElement().style.left = '-3000px';

        $A.createComponent('c:ChasInput', {
            'aura:id': 'sweetBox',
            'name': 'Compensation Amount',
            'label': 'Compensation Amount',
            'type': 'text',
        }, function(newCmp, status, err) {
            if (status === 'SUCCESS')
            {
                let pot = component.find('customerIdentity');
                let body = pot.get('v.body') || [];
                body.push(newCmp);
                pot.set('v.body', body);
            }
            else if (status === 'INCOMPLETE')
            {
                console.log("No response from server or client is offline.")
            }
            else if (status === 'ERROR')
            {
                console.log("Error: " + err);
            }
        })
    },

    /**
     * process long case description and put them into a map for later reference
     * @param {*} component 
     * @returns 
     */
    processLongDescription : function(component)
    {
        let compensation = component.get('v.wizardData.compensation.master');

        let caseDescription = compensation.Case__r.DescriptionofContents__c;

        if ($A.util.isEmpty(caseDescription))
            return;

        this.compact(component, 'CaseDescription', caseDescription);
    },

    /**
     * concatenate receiver address components into single rich text for displaying
     * @param {*} component 
     */
    consolidateReceiverAddress : function(component)
    {
        let address1 = component.get('v.wizardData.compensation.master.Case__r.Address4__c') || '';
        let address2 = component.get('v.wizardData.compensation.master.Case__r.Address4Line2__c') || '';
        let suburb = component.get('v.wizardData.compensation.master.Case__r.Address4Suburb__c') || '';
        let state = component.get('v.wizardData.compensation.master.Case__r.Address4State__c') || '';
        let postCode = component.get('v.wizardData.compensation.master.Case__r.Address4Postcode__c') || '';
        let country = component.get('v.wizardData.compensation.master.Case__r.Address4Country__c') || '';

        // remove <*> characters before passing to rich text component
        let RICHTEXT_ELEMENTS = ['a', 'abbr', 'acronym', 'address', 'b', 'br', 'big', 'blockquote', 'caption', 
                                'cite', 'code', 'col', 'colgroup', 'del', 'div', 'dl', 'dd', 'dt', 'em', 
                                'font', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'hr', 'i', 'img', 'ins', 'kbd', 
                                'li', 'ol', 'mark', 'p', 'param', 'pre', 'q', 's', 'samp', 'small', 'span', 
                                'strong', 'sub', 'sup', 'table', 'tbody', 'td', 'tfoot', 'th', 'thead', 'tr', 
                                'tt', 'u', 'ul', 'var', 'strike'];
        for (let element of RICHTEXT_ELEMENTS)
        {
            address1 = address1.replaceAll(`<${element}>`, '');
            address2 = address2.replaceAll(`<${element}>`, '');
            suburb = suburb.replaceAll(`<${element}>`, '');
            state = state.replaceAll(`<${element}>`, '');
            postCode = postCode.replaceAll(`<${element}>`, '');
            country = country.replaceAll(`<${element}>`, '');
        }

        let result = '';

        // address line 1
        address1? result += address1 + '<br>' : null;

        // address line 2
        address2? result += address2 + '<br>': null;

        // address line 3: suburb, state & postcode
        let address3 = [];
        suburb? address3.push(suburb) : null;
        state? address3.push(state) : null;
        postCode? address3.push(postCode) : null;
        address3.length > 0? result+= address3.join(' ') + '<br>' : null;

        // address line 4
        country? result += country : null;
        
        component.set('v.receiverAddress', result);
    },

    commitAndNext : function(component, event)
    {
        let accountName = component.get('v.wizardData.compensation.transaction.bAccountName');
        let BSB = component.get('v.wizardData.compensation.transaction.bBSBNumber');
        let accountNumber = component.get('v.wizardData.compensation.transaction.bAccountNumber');

        // sanitazation
        accountName = this.sanitize(accountName);

        let bankUpdateAction = component.get('c.updateBankDetails');

        this.spinnerOnFor(component);

        let compensationId = component.get('v.wizardData.compensation.master.Id');

        bankUpdateAction.setParams({
            compensationId, accountName, BSB, accountNumber
        });

        bankUpdateAction.setCallback(this, function(response)
        {
            let state = response.getState();

            if (state == 'SUCCESS')
            {
                $A.enqueueAction(component.get('c.next'));
            }
            else if (state === "ERROR") 
            {  
                var errors = response.getError();
                var isUserDefinedException = errors[0].isUserDefinedException;
                
                let errorDetail = this.getErrorMessage(errors);
                component.set('v.internalErrorDetail', errorDetail);
                this.registerAnalyticsEvent(component, 'internal_error');
                
                // errors could be user defined or system defined
                if (errors && !isUserDefinedException) {
                    
                    this.setInvalid(component,'internal');// system errors
                } else {
                    this.setInvalid(component,'generic');// generic errors handled by AuraHandledException
                }
            } else // any other errors, default it as system error
            {
                this.setInvalid(component,'internal');
            }
                
            this.spinnerOffFor(component);
        })

        $A.enqueueAction(bankUpdateAction);
    },

    /**
     * HTML escape than JS escape
     * @param {*} data 
     * @returns 
     */
    sanitize : function(data)
    {
        let htmlEscape = this.htmlEscape;
        let jsEscape = this.jsEscape;
        let that = this;

        return String(data).replace(new RegExp('<\/?([a-zA-Z0-9]+)*(.*?)\/?>', 'igm'), function(s) {
            s = htmlEscape.call(that, s)
            return jsEscape.call(that, s, true);
        })
    },

    /**
     * escape HTML entities
     * @param {*} data : the data to escape
     * @param {*} unique : escape unique HTML entities
     * @returns 
     */
    htmlEscape : function(data, unique)
    {
        let htmlEscapeMap = unique? this.entityMap().getUniqueHtmlEscapeMap() : this.entityMap().getHtmlEscapeMap();
        
        return String(data).replace(new RegExp('[&<>"\'`=\/]', "g"), function(s) {
            // replace if have value in escape map
            return htmlEscapeMap[s]? htmlEscapeMap[s] : s;
        });
    },

    /**
     * unescape escaped HTML entities
     * @param {*} data 
     */
    htmlUnescape : function(data)
    {
        let htmlEscapeMap = this.entityMap().getHtmlEscapeMap();

        for (let entity of Object.keys(htmlEscapeMap))
        {
            data = String(data).replaceAll(htmlEscapeMap[entity], entity);
        }

        return data;
    },

    /**
     * escape some JS entities. Don't use escape() since some characters need to be kept like Johnson & Johnson should not become Johnson%20%26%20Johnson
     * @param {*} data 
     * @param {*} unique : escape unique JS entities
     * @returns 
     */
    jsEscape : function(data, unique)
    {
        let jsEscapeMap = unique? this.entityMap().getUniqueJsEscapeMap() : this.entityMap().getJsEscapeMap();

        // escape Unicode encoded javascript \uxxxx
        data = String(data).replace(new RegExp('\\\\u....', 'g'), '');

        return data.replace(new RegExp('[\\$%\\?()=:"\'\\\\<>~\\[\\]{}`!#\\^&]', 'g'), function(s) {
            // replace if have value in escape map
            return jsEscapeMap[s]? jsEscapeMap[s] : s;
        });
    },

    /**
     * unescape escaped JS entities
     * @param {*} data 
     */
    jsUnescape : function(data)
    {
        let jsEscapeMap = this.entityMap().getJsEscapeMap();

        for (let entity of Object.keys(jsEscapeMap))
        {
            data = String(data).replaceAll(jsEscapeMap[entity], entity);
        }

        return data;
    },

    /**
     * encode for URI
     * @param {*} data 
     * @returns 
     */
    urlEscape : function(data)
    {
        return encodeURI(data);
    },

    entityMap : function()
    {
        return {
            getHtmlEscapeMap : function() {
                return {
                    '&': '&amp;',
                    '<': '&lt;',
                    '>': '&gt;',
                    '"': '&quot;',
                    "'": '&#39;',
                    '/': '&#x2F;',
                    '`': '&#x60;',
                    '=': '&#x3D;',
                };
            },

            getJsEscapeMap : function() {
                return {
                    '$': '%24',
                    '%': '%25',
                    '(': '%28',
                    ')': '%29',
                    '=': '%3D',
                    ':': '%3A',
                    '"': '%22',
                    "'": '%27',
                    '\\': '%5C',
                    '?': '%3F',
                    '<': '%3C',
                    '>': '%3E',
                    '~': '%7E',
                    '[': '%5B',
                    ']': '%5D',
                    '{': '%7B',
                    '}': '%7D',
                    '`': '%6O',
                    '!': '%21',
                    '#': '%23',
                    '^': '%5E',
                    '&': '%26'
                };
            },

            // escape map of JS that is not overlap with HTML
            getUniqueJsEscapeMap : function()
            {
                let jsEscapeMap = this.getJsEscapeMap();

                let jsEntities = Object.keys(jsEscapeMap);
                
                let htmlEntities = Object.keys(this.getHtmlEscapeMap());

                if (jsEntities == null || htmlEntities == null || jsEntities.length == 0 || htmlEntities.length == 0)
                {
                    return jsEscapeMap;
                }
                
                let result = {};
                
                for (let entity of jsEntities)
                {
                    if (!htmlEntities.includes(entity))
                    {
                        result[entity] = jsEscapeMap[entity];
                    }
                }
                return result;
            },

            // escape map of HTML that is not overlap with JS
            getUniqueHtmlEscapeMap : function()
            {
                let htmlEscapeMap = this.getHtmlEscapeMap();

                let htmlEntities = Object.keys(htmlEscapeMap);

                let jsEntities = Object.keys(this.getJsEscapeMap());

                if (jsEntities == null || htmlEntities == null || jsEntities.length == 0 || htmlEntities.length == 0)
                {
                    return htmlEscapeMap;
                }
                
                let result = {};
                
                for (let entity of htmlEntities)
                {
                    if (!jsEntities.includes(entity))
                    {
                        result[entity] = htmlEscapeMap[entity];
                    }
                }

                return result;
            },
        }
    },

    /**
     * provide a fallback value in case the setting of max value having error
     * @param {*} component 
     */
    getMaxAttemps : function(component)
    {
        let maxAttempts = component.get('v.__maxAttemps__') || 5;
        return maxAttempts;
    },

    /**
     * accumulate the errors for later displaying
     * duplicate error message should not be accumulated
     * @param {*} component 
     * @param {*} errors 
     * @returns 
     */
    accumulateErrors : function(component, errors)
    {
        if ($A.util.isEmpty(errors))
        {
            return;
        }

        let errors_ = component.get('v.errors') || [];

        for (let error of errors)
        {
            !this.haveDuplicateErrorMessage(errors_, error) && errors_.push(error);
        }

        component.set('v.errors', errors_);
    },

    /**
     * 
     * @param {*} errors_ : current errors
     * @param {*} error : new error to check against
     */
    haveDuplicateErrorMessage : function(errors_, error)
    {
        for (let error_ of errors_)
        {
            if (error_['name'] == error['name'] && error_['label'] == error['label'])
            {
                return true;
            }
        }
        return false;
    },

    /**
     * clear error panel
     * @param {*} component 
     */
    clearErrorPanel : function(component)
    {
        // clear error panel on top
        component.set('v.showErrorSummary', false);
        component.set('v.errors', []);

        // clear error in input fields
        let inputs = this.asArray(component.find('chasInput'));
        if (!$A.util.isEmpty(inputs))
        {
            for (let input of inputs)
            {
                // clear error on input to prevent dilluting
                input.set('v.showError', false);
                input.set('v.error', '');
            }
        }
    },

    /**
     * compactor for long text
     * @param {*} component 
     * @returns 
     */
    compact : function(component, field, value)
    {
        let compact = {
            full : value,
            display : value,
            expanded : true
        };

        if (value.length > 90)
        {
            let short = value.substring(0, 90);
            compact.short = short;
            compact.display = short;
            compact.expanded = false;
            compact.mode = 'compact';
        }

        let compacts = component.get('v.compacts');
        compacts[field] = compact;
        component.set('v.compacts', compacts);
    },

    /**
     * register the analytics event in the queue and execute after 500 miliseconds timeout
     * the timeout is for waiting relevant events to be registered
     * set @immediately to true for not using timeout
     * @param {*} component 
     * @param {*} name : name of event
     * @param {*} immediately : fire the analytics event immediately without setTimeout
     */
    registerAnalyticsEvent : function(component, name, immediately)
    {
        let payload = this.analyticsEventPayload(component)[name];

        if (!payload) return;

        let pendingMessages = component.get('v.pendingMessages');

        pendingMessages.push(payload);

        if (immediately)
        {
            this.handleQueueMessages(component);
        }
        else
        {
            this.handleQueueMessagesAsync(component, 500);
        }
    },

    /**
     * register analytics event that is mixed between page measurement event and page interact event
     * a use case is when user click Continue button and there is inline error message, instead of firing 2 consecutive event we will fire a mix event that contain information of both
     * not supported mix event of same type
     * mixed events is fired immediately
     * @param {*} component 
     * @param {*} mixes : receive a map of format {form : this.page_measurement_event, interact : this.page_interact_event}
     */
    registerMixAnalyticsEvent : function(component, mixes)
    {
        let pageInteractPayload = this.analyticsEventPayload(component)[mixes.interact];

        let pageMeasurementPayload = this.analyticsEventPayload(component)[mixes.form];

        let payload = {
            trackingType: mixes.trackingType || pageInteractPayload.trackingType,       // tracking type fall back to interact event's if no specify
            interactionCategory : pageInteractPayload.interactionCategory,
            interactionDescription : pageInteractPayload.interactionDescription,
            componentAttributes: {
                form : pageMeasurementPayload
            },
            category_ : this.PAGE_MIXED_EVENT
        }

        this.fireAnalyticEvent(component, payload);
    },

    /**
     * process the queued message
     * if queue has single item, fire the event immediately
     * if queue has more than one item, fire each item 200ms after each other to prevent tangled events
     * tangled events is when we fire multiple subsequent events, Adobe will take the content of last message to be the content of all messages
     * @param {*} component 
     * @returns 
     */
    handleQueueMessages : function(component)
    {
        let pendingMessages = component.get('v.pendingMessages');

        if (!pendingMessages || pendingMessages.length === 0) return;   // DO NOT REMOVE THIS TO PREVENT INFINITE LOOP
        
        let message = pendingMessages.shift();
        
        this.fireAnalyticEvent(component, message);

        // timeout 200ms before firing next message in queue so that the message content is not tangled
        if (pendingMessages.length > 0)
        {
            this.handleQueueMessagesAsync(component, 200);
        }
    },

    handleQueueMessagesAsync : function(component, timeout)
    {
        window.setTimeout($A.getCallback(function() {
            $A.enqueueAction(component.get('c.handlePendingQueueMessages'));
        }), timeout); 
    },

    /**
     * common trigger point for both page measurement & page interact event
     * @param {*} component 
     * @param {*} message 
     */
    fireAnalyticEvent : function(component, message)
    {
        // non-critic function, should not be a show stopper
        try {
            message['category_'] === this.PAGE_MEASUREMENT_EVENT && this.firePageMeasurementEvent(component, message);
            message['category_'] === this.PAGE_INTERACT_EVENT && this.firePageInteractEvent(component, message);
            message['category_'] === this.PAGE_MIXED_EVENT && this.fireMixedEvent(component, message);
        } catch(e)
        {
            console.log('FAE', e);
        }
        
    },

    fireMixedEvent : function(component, message)
    {
        let stage = message.componentAttributes.form.stage;
        if (stage === this.LANDING_PAGE_ERROR || stage === this.SAME_PAGE_ERROR || stage === this.CLEAR_ERROR)
        {
            component.set('v.isPageMeasurementErrorEvent', true);
        }
        window.AP_ANALYTICS_HELPER.trackByObject(message);
    },

    /**
     * fire page measurement event
     * @param {*} component 
     * @param {*} message 
     */
    firePageMeasurementEvent : function(component, message)
    {
        // if event come from an error landing page, turn off the page view auto-tracking to not fire subsequent page view event
        if (message.stage === this.LANDING_PAGE_ERROR)
        {
            component.set('v.analyticsPageViewAutoTracking', false);
        }

        // if event come from an error current page, set the flag to true so that when going to new page an clear error event is fired
        if (message.stage === this.LANDING_PAGE_ERROR || message.stage === this.SAME_PAGE_ERROR || message.stage === this.CLEAR_ERROR)
        {
            component.set('v.isPageMeasurementErrorEvent', true);
        }

        window.AP_ANALYTICS_HELPER.analyticsTrackFormAction(
            message.trackingType || this.FORM_INTERACT_TRACKING_TYPE,
            message.name,
            message.step,
            message.stage,
            message.detail,
            message.product,
            message.referenceId
        )
    },

    /**
     * fire page interaction event
     * @param {*} component 
     * @param {*} message 
     */
    firePageInteractEvent : function(component, message)
    {
        window.AP_ANALYTICS_HELPER.analyticsTrackInteraction(
            message.trackingType,
            message.interactionCategory,
            message.interactionDescription
        )
    },

    FORM_NAVIGATE_TRACKING_TYPE : 'helpsupport-form-navigate',
    FORM_INTERACT_TRACKING_TYPE : 'site-interact',
    FORM_NAME : 'form:compensation claim',
    PAGE_MEASUREMENT_EVENT : 'page_measurement_event',
    PAGE_INTERACT_EVENT : 'page_interact_event',
    PAGE_MIXED_EVENT : 'mixed_event',
    SAME_PAGE_ERROR : 'compensation_error_current_page',
    LANDING_PAGE_ERROR : 'compensation_error_landing_page',
    CLEAR_ERROR : 'compensation_clear_error',

    /**
     * centralize payload register for page measurement analytics event
     */
    analyticsEventPayload : function(component)
    {
        // detail of invalid compensation
        let invalidCompensationDetail = component.get('v.invalidCompensationDetail');

        // detail of generic error
        let internalErrorDetail = component.get('v.internalErrorDetail');
        
        return {
            'page1' : {
                trackingType : this.FORM_NAVIGATE_TRACKING_TYPE,
                name : this.FORM_NAME,
                step : 'step 1:confirm your details',
                stage : 'start',
                category_ : this.PAGE_MEASUREMENT_EVENT,
            },
            'page2' : {
                trackingType : this.FORM_NAVIGATE_TRACKING_TYPE,
                name : this.FORM_NAME,
                step : 'step 2:compensation case details',
                stage : '',
                category_ : this.PAGE_MEASUREMENT_EVENT,
            },
            'page3' : {
                trackingType : this.FORM_NAVIGATE_TRACKING_TYPE,
                name : this.FORM_NAME,
                step : 'step 3:review and submit',
                stage : '',
                category_ : this.PAGE_MEASUREMENT_EVENT,
            },
            'page4' : {
                trackingType : this.FORM_NAVIGATE_TRACKING_TYPE,
                name : this.FORM_NAME,
                step : 'step 4:payment details received',
                stage : 'submit',
                category_ : this.PAGE_MEASUREMENT_EVENT,
            },
            'page1_invalid_compensation' : {
                trackingType : this.FORM_NAVIGATE_TRACKING_TYPE,
                name : 'invalid compensation',
                step : 'landing',
                detail : invalidCompensationDetail,
                stage : this.LANDING_PAGE_ERROR,
                category_ : this.PAGE_MEASUREMENT_EVENT,
            },
            'page1_missing_field' : {
                trackingType : this.FORM_INTERACT_TRACKING_TYPE,
                name : this.FORM_NAME,
                step : 'step 1:confirm your details',
                detail : 'missing field',
                stage : this.SAME_PAGE_ERROR,
                category_ : this.PAGE_MEASUREMENT_EVENT,
            },
            'page1_invalid_field_format' : {
                trackingType : this.FORM_INTERACT_TRACKING_TYPE,
                name : this.FORM_NAME,
                step : 'step 1:confirm your details',
                detail : 'invalid field format',
                stage : this.SAME_PAGE_ERROR,
                category_ : this.PAGE_MEASUREMENT_EVENT,
            },
            'page1_mismatch_case_detail' : {
                trackingType : this.FORM_INTERACT_TRACKING_TYPE,
                name : this.FORM_NAME,
                step : 'step 1:confirm your details',
                detail : 'mismatch case detail',
                stage : this.SAME_PAGE_ERROR,
                category_ : this.PAGE_MEASUREMENT_EVENT,
            },
            'page1_out_of_attemps' : {
                trackingType : this.FORM_NAVIGATE_TRACKING_TYPE,
                name : 'invalid compensation',
                step : 'landing',
                detail : 'out of attemps',
                stage : this.LANDING_PAGE_ERROR,
                category_ : this.PAGE_MEASUREMENT_EVENT,
            },
            'page1_bot_detected' : {
                trackingType : this.FORM_NAVIGATE_TRACKING_TYPE,
                name : 'invalid compensation',
                step : 'landing',
                detail : 'bot detected',
                stage : this.LANDING_PAGE_ERROR,
                category_ : this.PAGE_MEASUREMENT_EVENT,
            },
            'page2_missing_field' : {
                trackingType : this.FORM_INTERACT_TRACKING_TYPE,
                name : this.FORM_NAME,
                step : 'step 2:compensation case details',
                detail : 'missing field',
                stage : this.SAME_PAGE_ERROR,
                category_ : this.PAGE_MEASUREMENT_EVENT,
            },
            'page2_invalid_field_format' : {
                trackingType : this.FORM_INTERACT_TRACKING_TYPE,
                name : this.FORM_NAME,
                step : 'step 2:compensation case details',
                detail : 'invalid field format',
                stage : this.SAME_PAGE_ERROR,
                category_ : this.PAGE_MEASUREMENT_EVENT,
            },
            'internal_error' : {
                trackingType : this.FORM_NAVIGATE_TRACKING_TYPE,
                name : 'server error',
                step : 'landing',
                detail : internalErrorDetail,
                stage : this.LANDING_PAGE_ERROR,
                category_ : this.PAGE_MEASUREMENT_EVENT,
            },
            'page1_clear_error' : {
                trackingType : this.FORM_NAVIGATE_TRACKING_TYPE,
                name : this.FORM_NAME,
                step : 'step 1:confirm your details',
                detail : "",
                stage : this.CLEAR_ERROR,
                category_ : this.PAGE_MEASUREMENT_EVENT,
            },
            'page2_clear_error' : {
                trackingType : this.FORM_NAVIGATE_TRACKING_TYPE,
                name : this.FORM_NAME,
                step : 'step 2:compensation case details',
                detail : "",
                stage : this.CLEAR_ERROR,
                category_ : this.PAGE_MEASUREMENT_EVENT,
            },
            'page1_and_2_button_continue' : {
                interactionCategory : 'button',
                interactionDescription : 'continue',
                category_ : this.PAGE_INTERACT_EVENT,
            },
            'page2_button_back' : {
                interactionCategory : 'button',
                interactionDescription : 'back',
                category_ : this.PAGE_INTERACT_EVENT,
            },
            'page3_button_edit' : {
                interactionCategory : 'button',
                interactionDescription : 'edit',
                category_ : this.PAGE_INTERACT_EVENT,
            },
            'page3_button_confirm' : {
                interactionCategory : 'button',
                interactionDescription : 'confirm',
                category_ : this.PAGE_INTERACT_EVENT,
            },
        };
    },

    getErrorMessage : function(errors)
    {
        let result = '';

        if ($A.util.isArray(errors))
        {
            errors.forEach(function(error)
            {
                // AuraHandledException message
                if (error.message)
                {
                    result += `AuraHandledException: ${error.message}. `
                }

                // page error message
                if (error.pageErrors && error.pageErrors.length > 0)
                {
                    error.pageErrors.forEach(function(pageError)
                    {
                        pageError.message && (result += `Page_Error: ${pageError.message} `);
                    })
                }

                // field error message
                if (error.fieldErrors && error.fieldErrors.length > 0)
                {
                    error.fieldErrors.forEach(function(fieldError)
                    {
                        fieldError.message && (result += `Field_Error: ${fieldError.message} `);
                    })
                }
            })
        }
        else
        {
            result = JSON.stringify(errors);
        }
        return result || JSON.stringify(errors);
    },
})