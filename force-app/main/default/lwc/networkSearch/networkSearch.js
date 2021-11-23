/**
  * @author       : Gnana <gnana.muruganantham@auspost.com.au>
  * @date         : 30/05/2019
  * @description  : Component that searches Networks to provides auto complete
--------------------------------------- History --------------------------------------------------
30.05.2019    Gnana   Created
**/

import { LightningElement, api } from 'lwc'

export default class NetworkSearch extends LightningElement {
    @api networkSearchResultSelectHandler
    @api label = 'Select facility/outlet'
    @api fieldLevelHelp = 'Enter network name'
    @api required = false

}