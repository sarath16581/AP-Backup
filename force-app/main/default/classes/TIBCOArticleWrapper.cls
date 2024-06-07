/**
 * @author Mohamed Atheek
 * @date 30.01.2014
 * @group Articles
 * @tags Cases, SSSW, Articles, Safe Drop, SAP-EM
 * @domain SSSW
 * @description
 * @changelog
 * 16.03.2016  kalpita.talwadekar@auspost.com.au   Updated to add apcn to article
 * 13.03.2017  david.e.catindoy@accenture.com Added a line of code that saves Merchant Location Id to the article record.
 * 02.05.2017  snigdha.sahu@auspost.com.au.au  Updated for REQ1070357 - addition of Customer Reference in the Article record
 * 04.02.2020  Hasantha.liyanage@auspost.com.au as part of the ICO-UK/US, updated Furtherreferences and the Attachment on Article to check for international tracking URL
 * 2020-04-01  nathan.franklin@auspost.com.au.au  Added variables for sender/receiver which are passed in through TIBCOArticleService
 * 22.05.2020 arjun.singh@auspost.com.au  Added code to capture sorting details for MyNetwork Community
 * 2020-10-22 disha.kariya@auspost.com.au Added Delivery ETA fields coming from Cognition
 * 2021-09-09	seth.heang@auspost.com.au	Uplift SF API version to 52
 * 2021-09-01 prerna.rahangdale@auspost.com.au Added parcel simplification captureId fields.
 * 2021-10-01 - Nathan Franklin - Refactor transient attributes from TIBCOArticleService
 * 2021-11-07 - Prerna Rahangdale - Addev VODV_Redirect to the Article this comes in further references when the Event Messages are MRS hold.
 * 2022-08-11 - Harry Wang - Adding Content Items as transient attribute (for ICPS)
 * 2024-05-24 - Seth Heang - Added attribute mapping for Article Status 'Delivered'
 */
public class TIBCOArticleWrapper {
	/**
	 * Transient attributes are used for mappings that are not persisted in Salesforce.
	 * We do this for attributes that are not mapped in the Subscription (S03) interface
	 */
	public ArticleTransientAttributes transientAttributes = new ArticleTransientAttributes();

	//indicates if this Article is selected for processing (e.g. in a visualforce)
	public Boolean selected { get; set; }

	public Article__c proxyArticle {
		get {
			if (proxyArticle == null) {
				proxyArticle = new Article__c();
			}
			return proxyArticle;
		}
		set;
	}

	// These contacts fields are populated in bulk when using Happy Parcel
	public Contact sender { get; set; }
	public Contact receiver { get; set; }

	public String eddImageIconName { get; set; }

	public List<TIBCOEventMessageWrapper> eventMessages { get; set; }

	public TIBCOArticleWrapper(Article__c a, Map<Id, List<EventMessage__c>> articleToEventMessages) {
		this(a, articleToEventMessages, new Map<String, Contact>());
	}
	public TIBCOArticleWrapper(Article__c a, Map<Id, List<EventMessage__c>> articleToEventMessages, Map<String, Contact> mappedContacts) {
		eventMessages = new List<TIBCOEventMessageWrapper>();
		selected = false;

		if (a != null) {
			// A clone is probably not necessary anymore since we are now using Lightning for all SAP-EM queries (no more visualforce viewstate)
			// That being said, I'll leave it here but we will now preserve the Id of the passed in object (if there was one)
			proxyArticle = a.clone(true, true);

			// store the matched contacts
			if (mappedContacts != null && mappedContacts.get('receiver') != null)
				receiver = mappedContacts.get('receiver');
			if (mappedContacts != null && mappedContacts.get('sender') != null)
				sender = mappedContacts.get('sender');

			eddImageIconName = 'error16.png';
			if (a.ExpectedDeliveryDate__c != null) {
				if (a.ExpectedDeliveryDate__c > Date.today()) {
					eddImageIconName = 'confirm16.png';
				} else if (a.ExpectedDeliveryDate__c < Date.today()) {
					eddImageIconName = 'error16.png';
				} else {
					eddImageIconName = 'warning16.png';
				}
			}

			List<EventMessage__c> emList = articleToEventMessages.get(a.Id);
			if (emList != null) {
				for (EventMessage__c em : emList) {
					eventMessages.add(new TIBCOEventMessageWrapper(em));
				}
			}
			eventMessages.sort();
		}
	}

	public TIBCOArticleWrapper(String trackingId, AuspostQueryTrackEventsSchema.ArticleDetails_element articleDetails) {
		this(articleDetails != null ? articleDetails.ArticleEnvelope : null, null);
		this.proxyArticle.TrackingID__c = trackingId;
	}

	public TIBCOArticleWrapper(AuspostQueryTrackEventsSchema.ArticleDetails_element articleDetails) {
		this(articleDetails != null ? articleDetails.ArticleEnvelope : null, null);
	}

	public TIBCOArticleWrapper(AuspostQueryTrackEventsSchema.ArticleEnvelope articleEnvelope, TIBCOConsignmentWrapper cw) {
		System.debug('articleEnvelope >>>>>>>>:' + articleEnvelope.MailEvent);
		eddImageIconName = 'error16.png';
		eventMessages = new List<TIBCOEventMessageWrapper>();
		selected = false;
		if (articleEnvelope != null) {
			if (articleEnvelope.CommunicationEvent != null) {
				for (AuspostEventSchema.CommunicationEvent ce : articleEnvelope.CommunicationEvent) {
					eventMessages.add(new TIBCOEventMessageWrapper(ce));
				}
			}

			if (articleEnvelope.DeviceEvent != null) {
				for (AuspostEventSchema.DeviceEvent de : articleEnvelope.DeviceEvent) {
					eventMessages.add(new TIBCOEventMessageWrapper(de));
				}
			}

			if (articleEnvelope.MailEvent != null) {
				for (AuspostEventSchema.MailEvent me : articleEnvelope.MailEvent) {
					eventMessages.add(new TIBCOEventMessageWrapper(me));
				}
			}

			eventMessages.sort();

			//Start Change by Snigdha :REQ1070357

			if (articleEnvelope.MailEvent != null) {
				for (AuspostEventSchema.MailEvent artme : articleEnvelope.MailEvent) {
					if (artme.FurtherReference != null) {
						for (AuspostEventSchema.FurtherReferences fr : artme.FurtherReference) {
							if (fr.ReferenceCodeSet == 'CUST_REF1') {
								proxyArticle.Customer_Ref__c = fr.ReferenceID;
							}
							if (fr.ReferenceCodeSet == 'CUST_REF2') {
								proxyArticle.Customer_Ref__c = proxyArticle.Customer_Ref__c + fr.ReferenceID;
							}
							if (fr.ReferenceCodeSet == 'CONSIGNMENT_ID') {
								proxyArticle.ConsignmentTrackingNumber__c = fr.ReferenceID;
							}
						}
					}
				}
			}

			//End Change by Snigdha : REQ1070357
			//
			if (articleEnvelope.Article != null) {
				AuspostMailProductSchema.Article article = articleEnvelope.Article;

				proxyArticle.ArticleID__c = article.ArticleId;
				proxyArticle.MLID__c = article.MerchantLocationId; //Added by David Catindoy (March 13, 2017) - StarTrack SSC5.1
				String proxyArticleMLID = '';
				proxyArticleMLID = article.MerchantLocationId;
				if (cw != null && String.isNotBlank(cw.proxyConsignment.Billing_Account__c)) {
					//Added by David Catindoy (March 22, 2017) - StarTrack SSC5.1
					proxyArticle.Billing_Account__c = cw.proxyConsignment.Billing_Account__c;
				} else if (String.isNotBlank(proxyArticleMLID)) {
					try {
						Billing_Account__c billAccount = [SELECT Id FROM Billing_Account__c WHERE MLID__c = :proxyArticleMLID LIMIT 1];
						proxyArticle.Billing_Account__c = billAccount.Id;
					} catch (Exception ex) {
						System.debug(ex);
					}
				}

				if (article.MeasurementData != null) {
					proxyArticle.ActualWeight__c = article.MeasurementData.WeightKG;
					proxyArticle.ArticleCount__c = article.MeasurementData.Quantity;
				}

				if (article.FurtherReferences != null) {
					Map<String, String> references = getFurtherReferenceAttributes(article.FurtherReferences);

					proxyArticle.ArticleLodgementDate__c = (!String.isEmpty(references.get('LODGEMENT_DATE')) ? TIBCOUtils.parseDateYYYYMMDD(references.get('LODGEMENT_DATE')) : null);
					proxyArticle.ExpectedDeliveryDate__c = (!String.isEmpty(references.get('DELIVERED_BY_DATE')) ? TIBCOUtils.parseDateYYYYMMDD(references.get('DELIVERED_BY_DATE')) : null);

					//INTERNAT_TRACK_ID = international track id (not a spelling mistake)
					proxyArticle.ExternalTrackingID__c = references.get('INTERNAT_TRACK_ID');

					//ETA Details
					// Uses cognition data to predict the delivery window for a delivery
					// Each request to the endpoint triggers a reprediction and when there is an update the original will remain in tact
					transientAttributes.predictedWindowStart = references.get('PREDICT_WIN_START');
					transientAttributes.predictedWindowEnd = references.get('PREDICT_WIN_END');
					transientAttributes.initialPredictedWindowStart = references.get('INIT_PRED_WIN_START');
					transientAttributes.initialPredictedWindowEnd = references.get('INIT_PRED_WIN_END');

					// PARSIM CI-105 <-- it's ok to leave this comment as long as you also comment as per below
					// TODO: What it is, What it does, Why it's there
					proxyArticle.CaptureID_receiveronly__c = ('X'.equalsIgnoreCase(references.get('MATCH_ID')) ? true : false);
					proxyArticle.CaptureID_anyoneataddress__c = ('X'.equalsIgnoreCase(references.get('CAPTURE_ID')) ? true : false);

					//VODV Details
					//When the Article is redirected or held, The VODV_REDIRECT further references gets the value
					// The redirection address would be masked on customer facing portals, and agents would be warned to avoid sharing information to customers.
					if ('X'.equalsIgnoreCase(references.get('VODV_REDIRECT'))) {
						proxyArticle.VODV_Redirect__c = true;
					}
				}

				if (article.Attachments != null && article.Attachments.Attachment != null && article.Attachments.Attachment.size() > 0) {
					// check the article for attachments
					for (AuspostCommonSchema.AttachmentType att : article.Attachments.Attachment) {
						// iterate trough found attachments
						if ('ExternalTrackingURL'.equalsIgnoreCase(att.AttachmentType)) {
							// read for the attachment type = URL
							proxyArticle.ExternalTrackingURL__c = att.URL; // store the URL found in article
						}
					}
				}

				if (proxyArticle.ExpectedDeliveryDate__c != null) {
					if (proxyArticle.ExpectedDeliveryDate__c > Date.today()) {
						eddImageIconName = 'confirm16.png';
					} else if (proxyArticle.ExpectedDeliveryDate__c < Date.today()) {
						eddImageIconName = 'error16.png';
					} else {
						eddImageIconName = 'warning16.png';
					}
				}

				proxyArticle.ArticleTransitAmountValue__c = article.TransitAmount;
				proxyArticle.EligibleForRedirect__c = false;

				// Redirect / Recall Eligibility
				if (article.Status != null) {
					for (AuspostMailProductSchema.ArticleStatus status : article.Status) {
						if (status.StatusAttributeName == 'Redirect Allowed Status' && status.StatusAttributeValue == 'Available') {
							proxyArticle.EligibleForRedirect__c = true;
						}
						if (status.StatusAttributeName == 'Delivery Status of Article' && status.StatusAttributeValue == 'Delivered') {
							proxyArticle.IsDelivered__c = true;
						}
					}
				}

				if (article.DeliveryContacts != null) {
					for (AuspostMailProductSchema.DeliveryContact dc : article.DeliveryContacts) {
						if ('DELIVERY'.equalsIgnoreCase(dc.DeliveryContactType) || 'RETURN'.equalsIgnoreCase(dc.DeliveryContactType)) {
							proxyArticle.DeliveryInstructions__c = dc.Comments;
							if (dc.Customer != null) {
								//added by Kalpita for capturing apcn on track events for reciever
								proxyArticle.Receiver_APCN__c = !String.isBlank(proxyArticle.Receiver_APCN__c) ? proxyArticle.Receiver_APCN__c : !String.isBlank(dc.Customer.CustomerID) ? dc.Customer.CustomerID : '';

								if (dc.Customer.Address != null) {
									for (AuspostLocationSchema.AddressType addType : dc.Customer.Address) {
										proxyArticle.ReceiverAddress__c = '';
										if (addType.AddressDetails != null && addType.AddressDetails.AustralianAddress != null) {
											proxyArticle.DestinationPostCode__c = addType.AddressDetails.AustralianAddress.PostCode;

											if (addType.AddressDetails.AustralianAddress.UnstructuredAddress != null && addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine != null) {
												for (String s : addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine) {
													proxyArticle.ReceiverAddress__c += s + ',';
												}

												if (addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine.size() > 0) {
													proxyArticle.ReceiverAddressLine1__c = addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine[0];
												}
												if (addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine.size() > 1) {
													proxyArticle.ReceiverAddressLine2__c = addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine[1];
												}
												if (addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine.size() > 2) {
													proxyArticle.ReceiverAddressLine3__c = addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine[2];
												}
												if (addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine.size() > 3) {
													proxyArticle.ReceiverAddressLine4__c = addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine[3];
												}
											}

											proxyArticle.ReceiverAddress__c += TIBCOUtils.removeNull(addType.AddressDetails.AustralianAddress.SuburbOrPlaceOrLocality) + ',';
											proxyArticle.ReceiverAddress__c += TIBCOUtils.removeNull(addType.AddressDetails.AustralianAddress.StateOrTerritory) + ' ';
											proxyArticle.ReceiverAddress__c += TIBCOUtils.removeNull(addType.AddressDetails.AustralianAddress.PostCode) + ',';
											if (addType.AddressDetails.AustralianAddress.Country != null) {
												proxyArticle.ReceiverAddress__c += TIBCOUtils.removeNull(addType.AddressDetails.AustralianAddress.Country.CountryCode);
												proxyArticle.ReceiverCountry__c = addType.AddressDetails.AustralianAddress.Country.CountryCode;
											}
											proxyArticle.ReceiverCity__c = addType.AddressDetails.AustralianAddress.SuburbOrPlaceOrLocality;
											proxyArticle.ReceiverState__c = addType.AddressDetails.AustralianAddress.StateOrTerritory;
											proxyArticle.ReceiverPostcode__c = addType.AddressDetails.AustralianAddress.PostCode;
										} else if (addType.AddressDetails != null && addType.AddressDetails.InternationalAddress != null) {
											proxyArticle.DestinationPostCode__c = addType.AddressDetails.InternationalAddress.PostCode;

											if (addType.AddressDetails.InternationalAddress.UnstructuredAddress != null && addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine != null) {
												for (String s : addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine) {
													proxyArticle.ReceiverAddress__c += s + ',';
												}

												if (addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine.size() > 0) {
													proxyArticle.ReceiverAddressLine1__c = addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine[0];
												}
												if (addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine.size() > 1) {
													proxyArticle.ReceiverAddressLine2__c = addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine[1];
												}
												if (addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine.size() > 2) {
													proxyArticle.ReceiverAddressLine3__c = addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine[2];
												}
												if (addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine.size() > 3) {
													proxyArticle.ReceiverAddressLine4__c = addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine[3];
												}
											}

											proxyArticle.ReceiverAddress__c += TIBCOUtils.removeNull(addType.AddressDetails.InternationalAddress.SuburbOrPlaceOrLocality) + ',';
											proxyArticle.ReceiverAddress__c += TIBCOUtils.removeNull(addType.AddressDetails.InternationalAddress.StateOrTerritory) + ' ';
											proxyArticle.ReceiverAddress__c += TIBCOUtils.removeNull(addType.AddressDetails.InternationalAddress.PostCode) + ',';
											if (addType.AddressDetails.InternationalAddress.Country != null) {
												proxyArticle.ReceiverAddress__c += TIBCOUtils.removeNull(addType.AddressDetails.InternationalAddress.Country.CountryCode);
												proxyArticle.ReceiverCountry__c = addType.AddressDetails.InternationalAddress.Country.CountryCode;
											}
											proxyArticle.ReceiverCity__c = addType.AddressDetails.InternationalAddress.SuburbOrPlaceOrLocality;
											proxyArticle.ReceiverState__c = addType.AddressDetails.InternationalAddress.StateOrTerritory;
											proxyArticle.ReceiverPostcode__c = addType.AddressDetails.InternationalAddress.PostCode;
										}
									}
								}

								if (dc.Customer.ElectronicContact != null) {
									for (AuspostCommonSchema.ElectronicContactType ec : dc.Customer.ElectronicContact) {
										if (ec.Internet != null && ec.Internet.ContactType == 'EMAIL') {
											proxyArticle.ReceiverEmail__c = ec.Internet.ContactDetail;
											break;
										}
									}
								}

								if (dc.Customer.Individual != null && dc.Customer.Individual.Name != null) {
									for (AuspostInvolvedPartSchema.IndividualName ind : dc.Customer.Individual.Name) {
										if (ind.NameUsage == 'IND') {
											proxyArticle.ReceiverName__c = ind.FullName;
											break; //Reading only the first value
										}
									}

									for (AuspostInvolvedPartSchema.IndividualName ind : dc.Customer.Individual.Name) {
										if (ind.NameUsage == 'ORG') {
											proxyArticle.ReceiverCompany__c = ind.FullName;
											break; //Reading only the first value
										}
									}
								}

								//Communication Decision
								if (dc.Customer.CommunicationDecision != null) {
									String cdCodes = '';
									for (AuspostCustomerSchema.CommunicationDecision cd : dc.Customer.CommunicationDecision) {
										cdCodes += cd.DecisionCode + '|';
									}
									proxyArticle.CustCommDecisionCode__c = ArticleUtil.removeAtEnd(cdCodes, '|');
									ArticleUtil.setCommunicationDecisionDescription(proxyArticle);
								}

								//Delivery Prefernce

								if (dc.Customer.DeliveryPreference != null && dc.Customer.DeliveryPreference.Options != null) {
									String dpCodes = '';
									for (AuspostCustomerSchema.Options_element op : dc.Customer.DeliveryPreference.Options) {
										dpCodes += op.OptionCode + '|';
									}
									proxyArticle.CustDelPrefOptionCode__c = ArticleUtil.removeAtEnd(dpCodes, '|');
									ArticleUtil.setDeliveryPreferenceOptionDescription(proxyArticle);
								}
							}
						}

						if ('PICKUP'.equalsIgnoreCase(dc.DeliveryContactType) || 'SENDER'.equalsIgnoreCase(dc.DeliveryContactType)) {
							if (dc.Customer != null) {
								//added by Kalpita for capturing apcn on track events for reciever
								proxyArticle.Sender_APCN__c = !String.isBlank(proxyArticle.Sender_APCN__c) ? proxyArticle.Sender_APCN__c : !String.isBlank(dc.Customer.CustomerID) ? dc.Customer.CustomerID : '';

								if (dc.Customer.Address != null) {
									for (AuspostLocationSchema.AddressType addType : dc.Customer.Address) {
										proxyArticle.SenderAddress__c = '';
										if (addType.AddressDetails != null && addType.AddressDetails.AustralianAddress != null) {
											if (addType.AddressDetails.AustralianAddress.UnstructuredAddress != null && addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine != null) {
												for (String s : addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine) {
													proxyArticle.SenderAddress__c += s + ',';
												}

												if (addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine.size() > 0) {
													proxyArticle.SenderAddressLine1__c = addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine[0];
												}
												if (addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine.size() > 1) {
													proxyArticle.SenderAddressLine2__c = addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine[1];
												}
												if (addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine.size() > 2) {
													proxyArticle.SenderAddressLine3__c = addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine[2];
												}
												if (addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine.size() > 3) {
													proxyArticle.SenderAddressLine4__c = addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine[3];
												}
											}

											proxyArticle.SenderAddress__c += TIBCOUtils.removeNull(addType.AddressDetails.AustralianAddress.SuburbOrPlaceOrLocality) + ',';
											proxyArticle.SenderAddress__c += TIBCOUtils.removeNull(addType.AddressDetails.AustralianAddress.StateOrTerritory) + ' ';
											proxyArticle.SenderAddress__c += TIBCOUtils.removeNull(addType.AddressDetails.AustralianAddress.PostCode) + ',';
											if (addType.AddressDetails.AustralianAddress.Country != null) {
												proxyArticle.SenderAddress__c += TIBCOUtils.removeNull(addType.AddressDetails.AustralianAddress.Country.CountryCode);
												proxyArticle.SenderCountry__c = addType.AddressDetails.AustralianAddress.Country.CountryCode;
											}
											proxyArticle.SenderCity__c = addType.AddressDetails.AustralianAddress.SuburbOrPlaceOrLocality;
											proxyArticle.SenderState__c = addType.AddressDetails.AustralianAddress.StateOrTerritory;
											proxyArticle.SenderPostcode__c = addType.AddressDetails.AustralianAddress.PostCode;
										} else if (addType.AddressDetails != null && addType.AddressDetails.InternationalAddress != null) {
											if (addType.AddressDetails.InternationalAddress.UnstructuredAddress != null && addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine != null) {
												for (String s : addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine) {
													proxyArticle.SenderAddress__c += s + ',';
												}

												if (addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine.size() > 0) {
													proxyArticle.SenderAddressLine1__c = addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine[0];
												}
												if (addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine.size() > 1) {
													proxyArticle.SenderAddressLine2__c = addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine[1];
												}
												if (addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine.size() > 2) {
													proxyArticle.SenderAddressLine3__c = addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine[2];
												}
												if (addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine.size() > 3) {
													proxyArticle.SenderAddressLine4__c = addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine[3];
												}
											}

											proxyArticle.SenderAddress__c += TIBCOUtils.removeNull(addType.AddressDetails.InternationalAddress.SuburbOrPlaceOrLocality) + ',';
											proxyArticle.SenderAddress__c += TIBCOUtils.removeNull(addType.AddressDetails.InternationalAddress.StateOrTerritory) + ' ';
											proxyArticle.SenderAddress__c += TIBCOUtils.removeNull(addType.AddressDetails.InternationalAddress.PostCode) + ',';
											if (addType.AddressDetails.InternationalAddress.Country != null) {
												proxyArticle.SenderAddress__c += TIBCOUtils.removeNull(addType.AddressDetails.InternationalAddress.Country.CountryCode);
												proxyArticle.SenderCountry__c = addType.AddressDetails.InternationalAddress.Country.CountryCode;
											}
											proxyArticle.SenderCity__c = addType.AddressDetails.InternationalAddress.SuburbOrPlaceOrLocality;
											proxyArticle.SenderState__c = addType.AddressDetails.InternationalAddress.StateOrTerritory;
											proxyArticle.SenderPostcode__c = addType.AddressDetails.InternationalAddress.PostCode;
										}
									}
								}

								if (dc.Customer.ElectronicContact != null) {
									for (AuspostCommonSchema.ElectronicContactType ec : dc.Customer.ElectronicContact) {
										if (ec.Internet != null && ec.Internet.ContactType == 'EMAIL') {
											proxyArticle.SenderEmail__c = ec.Internet.ContactDetail;
											break;
										}
									}
								}

								if (dc.Customer.Individual != null && dc.Customer.Individual.Name != null) {
									for (AuspostInvolvedPartSchema.IndividualName ind : dc.Customer.Individual.Name) {
										if (ind.NameUsage == 'IND') {
											proxyArticle.SenderName__c = ind.FullName;
											break; //Reading only the first value
										}
									}

									for (AuspostInvolvedPartSchema.IndividualName ind : dc.Customer.Individual.Name) {
										if (ind.NameUsage == 'ORG') {
											proxyArticle.SenderCompany__c = ind.FullName;
											break; //Reading only the first value
										}
									}
								}
							}
						}
					}
				}

				proxyArticle.ProductCategory__c = article.ProductName;

				proxyArticle.ServiceCode__c = article.BaseServiceCode;

				proxyArticle.SubProduct__c = article.SubProductName;
				proxyArticle.ProductID__c = article.ProductID;
				proxyArticle.SubProductID__c = article.SubProductID;

				//serviceQualifier
				String sq = '';
				if (article.AdditionalServices != null && article.AdditionalServices.ServiceCodeGroup != null) {
					for (AuspostProductSchema.ServiceCodeGroup_element scg : article.AdditionalServices.ServiceCodeGroup) {
						if (scg.ServiceCodes != null) {
							for (AuspostProductSchema.ServiceCodes_element sce : scg.ServiceCodes) {
								if (sce.ServiceQualifier != null) {
									for (AuspostProductSchema.ServiceQualifier_element sqe : sce.ServiceQualifier) {
										if (sqe.ServiceAttributeName == 'SIG-OPTION') {
											for (String s : sqe.ServiceAttributeQualifier) {
												sq += s + ',';
											}
										}
									}
								}
							}
						}
					}
				}
				if (sq.endsWith(',')) {
					proxyArticle.ServiceQualifier__c = sq.substring(0, sq.length());
				}

				//Content Items
				ArticleUtil.setContentsItems(article.ContentsItem, proxyArticle);

				//Passing content items attributes as transient attributes
				if (article.ContentsItem != null) {
					transientAttributes.contentItems = new List<ArticleContentItem>();
					for (AuspostMailProductSchema.ArticleContentsItemType item : article.ContentsItem) {
						transientAttributes.contentItems.add(new ArticleContentItem(item));
					}
				}

				if (article.Insurance != null) {
					proxyArticle.InsuranceRequired__c = article.Insurance.InsuranceRequired != null ? article.Insurance.InsuranceRequired : false;
					proxyArticle.InsuranceAmount__c = article.Insurance.InsuranceAmount;
					proxyArticle.InsuranceChargeAmount__c = article.Insurance.InsuranceChargeAmount;
					proxyArticle.InsuranceSDR__c = article.Insurance.InsuranceSDR;
				}

				proxyArticle.CTCDollarAmount__c = article.CTCDollarAmount;

				//Additional Services
				if (article.AdditionalServices != null) {
					ArticleUtil.setAdditionalServices(article.AdditionalServices, proxyArticle, eventMessages);
				} else if (cw != null) {
					proxyArticle.AdditionalServices__c = cw.proxyConsignment.AdditionalServices__c;
					proxyArticle.Notification__c = cw.proxyConsignment.Notification__c;
				}
			}

			for (TIBCOEventMessageWrapper em : eventMessages) {
				if (em.proxyEM.EventType__c == 'CE-EN01' || em.proxyEM.EventType__c == 'CE-EN02') {
					proxyArticle.Notification__c = true;
				}
			}

			copySenderReceiverDetails(this, cw);
		}
	}

	@TestVisible
	private void copySenderReceiverDetails(TIBCOArticleWrapper aw, TIBCOConsignmentWrapper cw) {
		if (cw != null) {
			proxyArticle.ReceiverAddress__c = cw.proxyConsignment.ReceiverAddress__c;
			proxyArticle.ReceiverCountry__c = cw.proxyConsignment.ReceiverCountry__c;
			proxyArticle.ReceiverAddressLine1__c = cw.proxyConsignment.ReceiverAddressLine1__c;
			proxyArticle.ReceiverAddressLine2__c = cw.proxyConsignment.ReceiverAddressLine2__c;
			proxyArticle.ReceiverAddressLine3__c = cw.proxyConsignment.ReceiverAddressLine3__c;
			proxyArticle.ReceiverAddressLine4__c = cw.proxyConsignment.ReceiverAddressLine4__c;
			proxyArticle.ReceiverCity__c = cw.proxyConsignment.ReceiverCity__c;
			proxyArticle.ReceiverState__c = cw.proxyConsignment.ReceiverState__c;
			proxyArticle.ReceiverPostcode__c = cw.proxyConsignment.ReceiverPostcode__c;
			proxyArticle.ReceiverCompany__c = cw.proxyConsignment.ReceiverCompany__c;
			proxyArticle.ReceiverEmail__c = cw.proxyConsignment.ReceiverEmail__c;
			proxyArticle.ReceiverName__c = cw.proxyConsignment.ReceiverName__c;

			proxyArticle.SenderAddress__c = cw.proxyConsignment.SenderAddress__c;
			proxyArticle.SenderCountry__c = cw.proxyConsignment.SenderCountry__c;
			proxyArticle.SenderAddressLine1__c = cw.proxyConsignment.SenderAddressLine1__c;
			proxyArticle.SenderAddressLine2__c = cw.proxyConsignment.SenderAddressLine2__c;
			proxyArticle.SenderAddressLine3__c = cw.proxyConsignment.SenderAddressLine3__c;
			proxyArticle.SenderAddressLine4__c = cw.proxyConsignment.SenderAddressLine4__c;
			proxyArticle.SenderCity__c = cw.proxyConsignment.SenderCity__c;
			proxyArticle.SenderState__c = cw.proxyConsignment.SenderState__c;
			proxyArticle.SenderPostcode__c = cw.proxyConsignment.SenderPostcode__c;
			proxyArticle.SenderCompany__c = cw.proxyConsignment.SenderCompany__c;
			proxyArticle.SenderEmail__c = cw.proxyConsignment.SenderEmail__c;
			proxyArticle.SenderName__c = cw.proxyConsignment.SenderName__c;

			if (proxyArticle.CustCommDecisionCode__c == null && proxyArticle.CustCommDecisionDescription__c == null) {
				proxyArticle.CustCommDecisionCode__c = cw.proxyConsignment.CustCommDecisionCode__c;
				proxyArticle.CustCommDecisionDescription__c = cw.proxyConsignment.CustCommDecisionDescription__c;
			}

			if (proxyArticle.CustDelPrefOptionCode__c == null && proxyArticle.CustDelPrefDescription__c == null) {
				proxyArticle.CustDelPrefOptionCode__c = cw.proxyConsignment.CustDelPrefOptionCode__c;
				proxyArticle.CustDelPrefDescription__c = cw.proxyConsignment.CustDelPrefDescription__c;
			}

			proxyArticle.SignatureRequiredFlag__c = cw.proxyConsignment.SignatureRequiredFlag__c;

			if (String.isBlank(proxyArticle.DeliveryInstructions__c)) {
				proxyArticle.DeliveryInstructions__c = cw.proxyConsignment.DeliveryInstructions__c;
			}
		}
	}

	/**
	 * Map all the further references to get easy access to the values
	 */
	private Map<String, String> getFurtherReferenceAttributes(List<AuspostCommonSchema.FurtherReferences> furtherReferences) {
		Map<String, String> output = new Map<String, String>();

		if (furtherReferences == null) {
			return output;
		}

		for (AuspostCommonSchema.FurtherReferences furtherReference : furtherReferences) {
			output.put(furtherReference.ReferenceCodeSet, furtherReference.ReferenceID);
		}
		return output;
	}

	/*
	 * Class to store transient variables which are not saved in Salesforce
	 */
	public class ArticleTransientAttributes {
		@AuraEnabled
		public String predictedWindowStart;
		@AuraEnabled
		public String predictedWindowEnd;
		@AuraEnabled
		public String initialPredictedWindowStart;
		@AuraEnabled
		public String initialPredictedWindowEnd;
		public ArticleContentItem[] contentItems;
	}

	/*
	 * Class to store content item attributes
	 */
	public class ArticleContentItem {
		public String description;
		public String weight;
		public Integer quantity;
		public String unitValue;
		public String value;

		public ArticleContentItem(AuspostMailProductSchema.ArticleContentsItemType itemType) {
			description = itemType.Description;
			weight = itemType.Weight;
			quantity = itemType.Quantity;
			unitValue = itemType.UnitValue;
			value = itemType.Value;
		}
	}
}