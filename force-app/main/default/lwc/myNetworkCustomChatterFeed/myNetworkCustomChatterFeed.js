/**
  * @author       : dattaraj.deshmukh@auspost.com.au
  * @date         : 29/11/2022
  * @description  : Generic component to list chatter feed.
--------------------------------------- History --------------------------------------------------
29.11.2022    dattaraj.deshmukh@auspost.com.au    Created
*/

import { LightningElement, api } from 'lwc';

export default class MyNetworkCustomChatterFeed extends LightningElement {
	@api feedItems;
	
}