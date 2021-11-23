/**
 * JS Utility class for Cognition google Map and report VF pages
 * History:
 *	 12-09-2018: Created - H Liyanage : Cognition Phase 2 changes
 *  --------------------------------------------------
 **/

    //function CognitionUtil() {}
    function CognitionUtil() {}
    CognitionUtil.refreshInterval;
    CognitionUtil.$j = $.noConflict();
    CognitionUtil.timeout;
    CognitionUtil.origin;

    /**
     * Enable the timer for VF pages to maintain the refresh intervals
     * when the user mouse move then stopped for 1 second,
     * message is sent to the main timmer sits in the CognitionVF page
     * @type {Function}
     */
    CognitionUtil.enableTimer = (function(lexOrigin) {
        CognitionUtil.$j(document).mousemove(function(){

            if(typeof CognitionUtil.timeout != 'undefined'){
                clearTimeout(CognitionUtil.timeout);
            }
            CognitionUtil.timeout = setTimeout(function(){
                CognitionUtil.initRefreshTimer();
            },1000);
        });
    });

    /**
     * initialize the refresh timer, the message will be caught at CognitionVF
     */
    CognitionUtil.initRefreshTimer = function() {
        CognitionUtil.sendToParent({
            'state': 'INIT_REFRESH_TIMER',
            'interval' : CognitionUtil.refreshInterval
        });
    }

    /**
     * Fire the refresh lightning event
     */
    CognitionUtil.doFire = function() {
        CognitionUtil.sendToParent({
            'state': 'FIRE_REFRESH'
        });
    }

    /**
     * Post message call to the parent
     * @param message
     */
    CognitionUtil.sendToParent = function(message) {
        if (typeof(CognitionUtil.origin) != 'undefined') {
            parent.postMessage(message, CognitionUtil.origin);
        }
    }

    /**
     * Creates a table row with label and value with two coloumns
     * @param label
     * @param value
     * @returns {string}
     */
    CognitionUtil.tableRow = function(label, value) {
        return '<tr>' +
            '<td>' + label + '</td>' +
            '<td>' + value + '</td>' +
            '</tr>';
    }

    /**
     * generate case link if there is a case linked to the consignemnt
     * note: case link will not be deployed in this release as there will be more changes to the requirement,
     * keeping this method for future use
     * @param SFCaseNumber
     * @returns {string}
     */
    CognitionUtil.getCaseLink = function(result, url, isInternalUser) {
        if (CognitionUtil.isCaseAvailable(result)) {
            var url = url+"/bsp/EnquiryDetail/" + result.SFCaseNumber;
            // link will not be visibe to internal users
            if (isInternalUser === true) {
                return  result.SFCaseNumber;
                //return '<a href=/console#/'+result.SFCaseId+' target="_blank">' + result.SFCaseNumber + '</a>';
                //return '<a href=/'+result.SFCaseId+' target="_blank">' + result.SFCaseNumber + '</a>';
            } else {
                //only BSP users are allowed to see a link
                return '<a href=' + url + ' target="_blank">' + result.SFCaseNumber + '</a>';
            }
        } else {
            return '-';
        }
    }

    /**
     * Search the consignment number in BSP, suto refresh should be triggered
     * note: consignment link will not be deployed in this release as there will be more changes to the requirement,
     * keeping this method for future use
     * @param result
     * @param url
     * @returns {*}
     */
    CognitionUtil.getConsignmentLink = function(result, url, isInternalUser, displayText, isPopup) {
        // nothing is visible if the user is internal
        if(isPopup === true && isInternalUser === true) {
            return '';
        }

        var url = url+"/bsp/BSPConsignmentSearch?caseRT=ST&consignmentNumber=" + result.Consignment;
        // if there is a prefered display text
        displayText = (displayText+'' === '' ? result.Consignment :  displayText);
        // link will not be visible to internal users
        if (isInternalUser === true) {
            return  result.Consignment;
        } else {
            //only BSP users are allowed to see a link
            return '<a href=' + url + ' target="_blank">' + displayText+ '</a>';
        }
    }

    /**
     * is case available for the consignment
     * @param result
     * @returns {boolean}
     */
    CognitionUtil.isCaseAvailable = function(result) {
        if (typeof result.SFCaseNumber !== 'undefined' && result.SFCaseNumber !== null ) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * Return the style class for case record if a case available
     * this has to apply for each <td> in the table as there are some style classes changing when sorting the columns
     * @param result
     * @returns {string}
     */
    CognitionUtil.highlightCaseRecord = function(result) {
        if (CognitionUtil.isCaseAvailable(result)) {
            return 'report-column-case';
        } else {
            return '';
        }
    }

    /**
     * if the type of the consignment is an exception type
     * @param result
     * @returns {boolean}
     */
    CognitionUtil.isanExceptionType = function(result) {
          if(result.Type === 2 || result.Type === 4) {
              return true;
          }  else {
              return false;
          }
    }

    /**
     * generate the title for pop-up screen
     * @param result
     * @returns {*}
     */
    CognitionUtil.getTitle = function(result) {
        //if the type is 14 display the Category enum string (still outstanding - )
        if (result.Type === 14) {
            return result.Category_EnumString;
        } else {
            return result.Type_EnumString;
        }
    }

    /**
     * Identify;
     *  Pickup reports
     * @param reportCategory
     * @returns {boolean}
     */
    CognitionUtil.isPickupCategory = function(reportCategory) {
        var reportCategoryNum = Number(reportCategory);
        if (reportCategoryNum === 30 || reportCategoryNum === 31 || reportCategoryNum == 32) {
            return true;
        } else {
            return false
        }
    }


    /**
     * Identify;
     *  Exception,
     *  Still outstanding reports
     * @param reportCategory
     * @returns {boolean}
     */
    CognitionUtil.isOutstandingCategory = function(reportCategory) {
        var availableCategories = [19, 34, 35, 36, 37];
        var reportCategoryNum = Number(reportCategory);
        // 19 Onboard for Delivery
        // 34 Held at Facility
        // 35 Not Received
        // 36 At Delivery Depot
        // 37 Not at Delivery Depot

        if (availableCategories.includes(reportCategoryNum)) {
            console.log('reportCategory :' +reportCategory);
            return true;
        } else {
            return false
        }
    }

    CognitionUtil.isExceptionCategory = function(reportCategory) {
        var availableCategories = [8, 20];
        var reportCategoryNum = Number(reportCategory);
        // 8 Not Onboard for Delivery
        // 20 Delivering Early

        if (availableCategories.includes(reportCategoryNum)) {
            console.log('reportCategory :' +reportCategory);
            return true;
        } else {
            return false
        }
    }

    // display Receiver Suburb based on the availabiliity
    CognitionUtil.getReceiverSuburb = function(reportData) {
        var receiverSuburb = 'Not Found';
        if (reportData.ReceiverSuburb) {
            receiverSuburb = reportData.ReceiverSuburb;
        }
        // if a suburb found
        if (reportData.ReceiverSuburbName) {
            receiverSuburb += ' - ' + reportData.ReceiverSuburbName;
        }
        return receiverSuburb;
    }

    // Display the LPO if the consignment is Carded
    CognitionUtil.getLPOWithLastEvent = function(reportData) {
        if (reportData.CardedDepot && reportData.Category === 'Carded') {
            return reportData.LastEvent + ' (' + reportData.CardedDepot + ')';
        } else {
            return reportData.LastEvent
        }
    }

    // get the case row highlighted in red (if there a case available)
    CognitionUtil.getCaseRowHighlighted = function(SFCaseNumber) {
        if (typeof SFCaseNumber !== 'undefined' && SFCaseNumber !== null) {
            return '<tr class="report-column-case" >';
        } else {
            return '<tr>';
        }
    }

    // if the logged in user is an internal user, let's show them the live tracking link
    CognitionUtil.getLiveTrackingURL = function(result, isInternalUser) {
        var html = '';
        console.log('result.TruckLink & isInternalUser =',result.TruckLink+' '+isInternalUser);
        if (typeof result.TruckLink != 'undefined' && isInternalUser === true) {
            html = '<tr>' +
                '<td colspan="2"><a href=' + result.TruckLink + ' target="_blank">Live Tracking of Trucks</a> </td>' +
                '</tr>';
        }
        return html;
    }

    // if the consignment is carded, do not show the signature, show the LPO instead
    CognitionUtil.cardedConsignmentOrSignature = function(result) {
        if (result.Type !== 7) {
            var signData = 'Not Available';
            // if a signature image is available
            if(typeof result.SignatureImageBase64 !== 'undefined' && result.SignatureImageBase64 !== null ) {
                signData = '<img src=data:image/png;base64,' +
                    result.SignatureImageBase64 + ' height="40" width="40" align="left"/>';
            }

            html = '<tr>' +
                '<td>Signature: </td>' +
                '<td style="float: left;">' + signData + '</td>' +
                '</tr>';
        } else {
            html = '<tr>' +
                '<td>Licensed Post Office: </td>' +
                '<td>' + result.CardedDepot + '</td>' +
                '</tr>';
        }
        return html;
    }

    /**
     * get event date time if the pickup is success or a failure
     *
     */
    CognitionUtil.getEventDateTime = function(dateTime, pickupType) {
        var htmlText = '';
        if (pickupType === 11 || pickupType === 12) {
            htmlText = '<tr>' +
                '<td>Event Date/Time:</td>' +
                '<td>' + dateTime + '</td>' +
                '</tr>';
        }

        return htmlText;

    }

    /**
     * display event reason when a pickup failure
     * @param result
     * @returns {string}
     */
    CognitionUtil.getReason = function(result) {
        if (result.EventReason + '' != '') {
            return '<tr>' +
                '<td>Reason:</td>' +
                '<td>' + cleanseText(result.EventReason) + '</td>' +
                '</tr>';
        } else {
            return '';
        }
    }

    /**
     * get the address formatted to display
     *
     **/
    CognitionUtil.getAddress = function(result) {
        var addressData = result.Address1 + ',<br>';

        if (result.Address2 + '' != '') {
            addressData += result.Address2 + ',<br>';
        }

        if (result.Address3 + '' != '') {
            addressData += result.Address2 + ',<br>';
        }

        if (result.Suburb + '' != '') {
            addressData += result.Suburb + ',<br>';
        }

        if (result.Postcode + '' != '') {
            addressData += result.Postcode + ',<br>';
        }

        if (result.State + '' != '') {
            addressData += result.State + ',<br>';
        }

        if (addressData === '') {
            addressData = '-';
        } else {
            addressData = addressData.slice(0, -1) + '.';
        }

        return addressData;

    }