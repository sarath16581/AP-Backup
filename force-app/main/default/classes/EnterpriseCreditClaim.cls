/**Consumable returns	*		Date Version	Owner					Desription
 * 07-Feb-17					1.0  			Bharat P				Initial Version - Handles Enterprise Credit Claim Form
 * 20-Feb-17					1.1				Bharat P				Added functionality for adding and deleting Disputed Item rows
 * 24-Mar-17					1.2				Bharat P				Added code for Success Popup message on submission
 * 29-Mar-17					1.3				Bharat P				Added functionality for using reCAPTCHA before form submission
 * 06-Jul-17					1.4				AP Rivera				Added functionality for multiple file attachments
 * 02-Dec-20					1.5				SaiSwetha Pingali		INC1699783 - Fix to address the issue raised after the activation of critical update 'Assign Records Created by Guest Users to a Default Owner'.  
 * 02-Jun-23					1.6				Pratyush Chalasani		Added getter for dispute reasons list
 * 24-Oct-23					1.7				Thang Nguyen			SB-213: Update the reason help text
 * 20-Feb-24					1.8				Thang Nguyen			SB-272: Enable the redirect the new BSP credit claim form
*/
public without sharing class EnterpriseCreditClaim {
		public Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Enterprise Credit Dispute Claim').getRecordTypeId();
		public string selectedBusinessUnit {get;set;}
		public string selectedDisputeType {get;set;}
		public string selectedReason {get;set;}
		public string description {get;set;}
		public List<DisputedItemWrapper> lstDisputedItems{get;set;}
		public integer rowToDelete {get;set;}
		public string popupMessage {get;set;}
		public blob file {get; set;}
		public String fN {get; set;}
		public Integer fileToRemove {get;set;}
		public List<ContentVersion> versions{get;set;}
		public Boolean refreshDI {get;set;}   
		public Credit_Claim_Setting__c objCCSetting;
		public string dataSiteKey {get;set;}
		public string secretKey {get;set;}
		private static string baseUrl = 'https://www.google.com/recaptcha/api/siteverify';
		public string response {get;set;} {response = null;}
		public Boolean correctResponse {get;private set;} {correctResponse = false;}
		public Boolean caseComplete {get;set;}
		public Credit_Claim_Setting__c redirectNewCreditFormSettings;
		public Boolean enableRedirectNewCreditForm {get;set;}
		public string redirectURLNewCreditForm {get;set;}
		
		public Case entCreditClaim{
				get{
						if(entCreditClaim==null){
								entCreditClaim = new Case();
						}
						return entCreditClaim;
				}
				set;
		}

		/* START - APRIVERA - Resolved view state Error. Added Input file functionality */
		public Set<String> setDocNames;
		public Document tempDocument;
		public Set<Id> setDocId;
		public Integer fileSize {get;set;}
		public String errorMessage {get;set;}
		public Boolean errorIndicator {get;set;}
		public FileObject fObj{get;set;}
		public List<FileObject> lstFileObj{get;set;}
		public String tempDesc;
		public String strDocTypes {get;set;}
		public List<AllowedSupportingDocTypes__c> lstDocTypes;
		public Set<String> setDocNamesTemp;
		public List<String> setTempDocTypes {get;set;}
		public Set<String> setFileNames {get;set;}
		public Boolean startrackBU {get;set;}
		public Boolean auspostBU {get;set;}
		/* END - APRIVERA - Resolved view state Error. Added Input file functionality */

		
		/* Constructor */
		public EnterpriseCreditClaim(ApexPages.StandardController stdController){
				setPageHeaders();
				this.versions = new List<ContentVersion>();
				if(caseComplete == null){
						caseComplete = false;
				}
				
				if(('Guest').equalsIgnoreCase(UserInfo.getUserType())){
						entCreditClaim.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Enterprise Credit Dispute Claim Guest').getRecordTypeId();
				}else{
						entCreditClaim.RecordTypeId = recordTypeId;
				}   
				if(!Test.isRunningTest()){
						objCCSetting = Credit_Claim_Setting__c.getValues('ReCaptcha');
						dataSiteKey = objCCSetting.Data_Site_Key__c;
						secretKey = objCCSetting.Secret_Key__c;
						
						//get the redirect new credit form url
						redirectNewCreditFormSettings = Credit_Claim_Setting__c.getValues('RedirectNewCreditForm');
						redirectURLNewCreditForm = redirectNewCreditFormSettings !=null ? redirectNewCreditFormSettings.Redirect_URL__c: '';
						if (String.isEmpty(redirectURLNewCreditForm)){
							enableRedirectNewCreditForm = false;
						}else{
							enableRedirectNewCreditForm = true;
						}					
				}  
				this.lstDisputedItems = new list<DisputedItemWrapper>();
				addRow();

				/* START - APRIVERA - Resolved view state Error. Added Input file functionality */
				lstFileObj = new List<FileObject>();
				setDocNames = new Set<String>();
				setDocId = new Set<Id>();
				tempDesc = 'TemporaryDocument_'+UserInfo.getUserId();
				setTempDocTypes = new List<String>(); 
				setDocNamesTemp = new  Set<String>();
				setFileNames = new  Set<String>();

				lstDocTypes = AllowedSupportingDocTypes__c.getall().values();
				if(!lstDocTypes.isEmpty()){
						for(AllowedSupportingDocTypes__c dTypes : lstDocTypes){
								setTempDocTypes.add('.' + dTypes.File_Type__c);
						}
						setTempDocTypes.sort();
						strDocTypes = string.join(setTempDocTypes,', ');
				}
				/* END - APRIVERA - Resolved view state Error. Added Input file functionality */
		}
		
		/* Method for making request body for reCaptcha response */
		public static HttpResponse makeRequest(string url, string body){
				HttpRequest req = new HttpRequest();
				HttpResponse response = null;
				req.setEndpoint( url );
				req.setMethod('POST');
				req.setBody ( body);
				try{
						Http http = new Http();
						response = http.send(req);
				}catch( System.Exception e){
						ApexPages.addMessages(e);
				}
				return response;
		}
		
		/* Remote Host for reCaptcha */
		public string remoteHost{
				get{
						string ret = '127.0.0.1';
						Map<string , string> hdrs = ApexPages.currentPage().getHeaders();
						if (hdrs.get('x-original-remote-addr') != null){
								ret = hdrs.get('x-original-remote-addr');
						} else if ( hdrs.get('X-Salesforce-SIP') != null){
								ret = hdrs.get('X-Salesforce-SIP');
						}
						return ret;
				}
		}
		
		/* Inner Class Wrapper for Disputed Item Record */
		public without sharing class DisputedItemWrapper{
				public Integer index {get;set;}
				public Disputed_Item__c entDisputedItem {get;set;}  
		}
		
		/* Method for adding Disputed Item Row */
		public PageReference addRow(){
				DisputedItemWrapper diWrapp = new DisputedItemWrapper();
				Disputed_Item__c newDIRecord = new Disputed_Item__c();
				diWrapp.entDisputedItem = newDIRecord;
				diWrapp.index = lstDisputedItems.size();
				lstDisputedItems.add(diWrapp);
				return null;
		}
		
		/* Method for deleting Disputed Item Row */
		public void deleteRow(){
				lstDisputedItems.remove(rowToDelete);
		}  

		/* START - APRIVERA - Resolved view state Error. Added Input file functionality */
		public void uploadFile(){
				errorIndicator = false;
				try
				{
						if(file==null){  
								errorMessage = 'Please select a file first.';
								errorIndicator = True;
						}else{
								String fSize;
								if(fileSize < 1048576){
										fSize = String.valueOf( Decimal.valueOf(fileSize/1024).setScale(2)) + ' Kb';
								}else{
										Decimal fileSizeMB = Decimal.valueOf(fileSize)/1024/1024;
										fSize = String.valueOf(fileSizeMB.setScale(2)) + ' Mb';
								} 
								
								fObj = new FileObject();

								if(!setFileNames.contains(fN)){ 
										fObj.fileName = fN;
								}else{
										Integer ctr = 1;
										for(String s : setFileNames){
												if(fN.substringBeforeLast('.') == s.substringBeforeLast('(')){
														ctr = ctr + 1;
												}
										}
										fObj.fileName = fN.substringBeforeLast('.') + '(' + ctr + ').' + fN.substringAfterLast('.');
								}   
								fObj.fileSize = fSize;

								setFileNames.add(fObj.fileName);

								lstFileObj.add(fObj);   

								tempDocument = new Document();
								tempDocument.AuthorId = UserInfo.getUserId();
								tempDocument.FolderId = UserInfo.getUserId(); // put it in running user's folder
								tempDocument.Body = file;
								String docname = 'TemporaryDocument_' + fObj.fileName;
								tempDocument.Name = docname;  
								tempDocument.Description = tempDesc;
								tempdocument.IsInternalUseOnly = true;
								
								insert tempDocument;
								setDocNames.add(docname);
								Id docId = [Select id from Document where id =: tempDocument.Id].Id;
								setDocId.add(docId);
								file = null;
								tempDocument.Body = null;

								if(entCreditClaim.Business_Unit__c != null){
										refreshDI = true;
										if(entCreditClaim.Business_Unit__c == 'Australia Post'){
												auspostBU = true;
												startrackBU = false;
										} else{
												startrackBU = true;
												auspostBU = false;
										}
								} else{
										refreshDI = false;
								}
								
						}
				}
				catch (DMLException e)
				{
						errorMessage = 'Error uploading Document in Library';
						errorIndicator = True;
				}
		}   
		
		/* Method to remove attached files*/
		public void removeFile(){
				if(setDocNames.size()>0){
						setDocNames.remove('TemporaryDocument_' + lstFileObj[fileToRemove].fileName);
						setDocNamesTemp.add('TemporaryDocument_' + lstFileObj[fileToRemove].fileName);
						setFileNames.remove(lstFileObj[fileToRemove].fileName);

						if(lstFileObj.size()>0){
								lstFileObj.remove(fileToRemove);   
						}
				}
		}

		/* Wrapper class for temporary files to be stored to salesforce as document */
		public class FileObject{
				public String fileName{get;set;}
				public String fileSize{get;set;}
		}
		/* END - APRIVERA - Resolved view state Error. Added Input file functionality */
		
		/* Method for redirecting the URL based on Business Unit(Account Held With) selected */
		public PageReference submitRedirect(){
				if(String.isNotBlank(selectedBusinessUnit)){
						objCCSetting = Credit_Claim_Setting__c.getValues(selectedBusinessUnit);
						return new PageReference(objCCSetting.Redirect_URL__c);
				}
				return null;
		}
		
		/* Method for validating reCaptcha response and submitting the Credit Claim to create a Case Record */
		public PageReference submitCreditClaim(){
				try{
						if (response != null){
								HttpResponse resp = makeRequest(baseUrl ,'secret='+ secretKey + '&remoteip=' + remoteHost +
																								'&response=' + response + '&error=Incorrect reCaptcha Solution');
								if(Test.isRunningTest()){
										resp = new HttpResponse();
								}
								if (resp != null){
										correctResponse = (resp.getBody().contains('true'));
										if(Test.isRunningTest()){
												correctResponse = true;
										}
										if(correctResponse == true){
												//Fetching the assignment rules on case
												AssignmentRule assignRule = new AssignmentRule();
												assignRule = [select id from AssignmentRule where SobjectType = 'Case' and Active = true limit 1];
												//Creating the DMLOptions for "Assign using active assignment rules" checkbox
												Database.DMLOptions dmlOptions = new Database.DMLOptions();
												dmlOptions.assignmentRuleHeader.assignmentRuleId = assignRule.id;
												entCreditClaim.Description = description;
												entCreditClaim.Origin = 'Web';
												entCreditClaim.setOptions(dmlOptions);
												entCreditClaim.RecordTypeId = recordTypeId;
												insert entCreditClaim;

												List<Disputed_Item__c> disputedItemsToBeInserted = new List<Disputed_Item__c>();
												if(lstDisputedItems !=null && !lstDisputedItems.isEmpty()){
														for(EnterpriseCreditClaim.DisputedItemWrapper eachDisputedItem : lstDisputedItems){
																Disputed_Item__c diRecord = eachDisputedItem.entDisputedItem;
																diRecord.Case__c = entCreditClaim.Id;
																disputedItemsToBeInserted.add(diRecord);
														}
														insert disputedItemsToBeInserted;   
												}


												/* START - APRIVERA - Resolved view state Error. Added Input file functionality */
												if(!lstFileObj.isEmpty()){
													insertContentVersions(setDocId, tempDesc);
												}
												if(File != null){
														File = null;
												}

												if(!setDocNamesTemp.isEmpty()){
														List<Document> lstDocToDelete = [select Body, Id , Name from Document where Name in: setDocNamesTemp
																																and AuthorId =: UserInfo.getUserId() and Description =: tempDesc];
														Delete lstDocToDelete;
												}
												/* END - APRIVERA - Resolved view state Error. Added Input file functionality */

												Case caseNoRetrieved = [Select Id, CaseNumber from Case where Id = :entCreditClaim.Id];
												popupMessage = System.Label.Dispute_Credit_Claim_Case_Success + ' ' + caseNoRetrieved.CaseNumber + '.';
												caseComplete = true;
												refreshDI = true;
										}
								}
						}
				}catch(exception ex){
						ApexPages.addMessages(ex);
				}
				Pagereference pg = new Pagereference(Page.EnterpriseCreditClaim.getUrl());
				return pg.setRedirect(false);
		}
		
		/* START - APRIVERA - Resolved view state Error. Added Input file functionality */
		/* Method to insert Content versions */
		public void insertContentVersions(Set<Id> setDocId, String tempDesc){
				
					//spingali - INC1699783 - Removed  condition 'and AuthorId =: UserInfo.getUserId()' from the below SOQL as guest user is not the Author .
				/*List<Document> lstDocToRetrieve = [select Body, Id, Name from Document where Name in: setDocNames and AuthorId =: UserInfo.getUserId()
																						and Id in: setDocId and Description =: tempDesc]; */
				List<Document> lstDocToRetrieve = [select Body, Id, Name from Document where Name in: setDocNames and Id in: setDocId and Description =: tempDesc];
																		
				List<ContentVersion> lstCVToBeInserted = new List<ContentVersion>();
				ContentVersion cv = new ContentVersion();
				if(!lstDocToRetrieve.isEmpty()){
						
						for(Document d : lstDocToRetrieve){
								cv = new ContentVersion();
								String dName = d.name; 

								cv.VersionData = d.body;
								cv.PathOnClient = dName.substring(18, dName.length());
								cv.Title = dName.substring(18, dName.length());
								lstCVToBeInserted.add(cv); 
						}

						if(!lstCVToBeInserted.isEmpty()){
								insert lstCVToBeInserted;

								Set<Id> conVerIdSet = new Set<Id>();
								Map<Id, Id> conDocMap = new Map<Id, Id>(); 
								List<ContentDocumentLink> contentDocLink = new List<ContentDocumentLink>();
								ContentDocumentLink cdl = new ContentDocumentLink(); 

								for(ContentVersion contentVersion : lstCVToBeInserted){
										conVerIdSet.add(contentVersion.Id);
								}

								//spingali - INC1699783 Replaced the below code with SOQL on contentVersion as Guest users doesn't have access to ContentDocument object   
								/*
								for(ContentDocument cd : [Select Id,LatestPublishedVersionId From ContentDocument Where LatestPublishedVersionId IN :conVerIdSet]){
										conDocMap.put(cd.LatestPublishedVersionId, cd.Id);
								}
								*/
							//spingali - INC1699783 Added the below code with SOQL on contentVersion to get the ContentDocumentId .   
								for(ContentVersion cd : [Select Id,ContentDocumentId From ContentVersion Where Id IN :conVerIdSet]){
										conDocMap.put(cd.Id, cd.ContentDocumentId);
								}

								for(ContentVersion contentVersion : lstCVToBeInserted){
										cdl = new ContentDocumentLink();   
										cdl.LinkedEntityId  = entCreditClaim.Id;
										cdl.ContentDocumentId = conDocMap.get(contentVersion.Id);
										cdl.ShareType = 'V';
										contentDocLink.add(cdl);
								}

								if(!contentDocLink.isEmpty()){
										insert contentDocLink; 

										delete lstDocToRetrieve;
								}  
						}
				}   
		}
		/* END - APRIVERA - Resolved view state Error. Added Input file functionality */

		// Query and generate map of credit dispute reasons to their descriptions
		public String getCreditClaimReasonDescriptions() {
				Map<String, String> reasonDescriptionMap = new Map<String, String>();

				List<Picklist_Entry_Helptext__mdt> helptextEntries = PicklistEntryHelptextSelector.newInstance().selectByObjectAndField(Case.SObjectType, Case.ReasonforCreditClaim__c);

				for (Picklist_Entry_Helptext__mdt reason: helptextEntries) {
						Component.Apex.OutputText description = new Component.Apex.OutputText();
						description.value = reason.Message__c != null? reason.Message__c: '';
						String key = reason.BusinessUnit__c != null? reason.Label + '_' + reason.BusinessUnit__c: reason.Label;
						reasonDescriptionMap.put(key.toLowerCase(), String.valueOf(description.value));
				}

				return JSON.serialize(reasonDescriptionMap);
		}
		
		/* Setting Page Headers */
		private void setPageHeaders(){
				Apexpages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=edge,chrome=1');
				Apexpages.currentPage().getHeaders().put('X-Frame-Options', 'SameOrigin'); // To prevent clickjacking
				Apexpages.currentPage().getHeaders().put('Cache-control', 'no-store'); // To prevent the browser to store personal information into its cache
				Apexpages.currentPage().getHeaders().put('Pragma', 'no-cache');
		}
}