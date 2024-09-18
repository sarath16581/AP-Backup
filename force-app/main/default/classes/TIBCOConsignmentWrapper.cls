/**
 * @author Mohamed Atheek
 * @date 30.01.2014
 * @group Articles
 * @tags Cases, SSSW, Articles, Safe Drop, SAP-EM
 * @domain SSSW
 * @description
 * @changelog
 * 13.03.2017  david.e.catindoy@accenture.com Added a line of code that saves Merchant Location Id to the consignment record.
 * 2020-04-01  nathan.franklin@auspost.com.au.au  Added variables for sender/receiver which are passed in through TIBCOArticleService
 * 2021-09-09	seth.heang@auspost.com.au	Uplift SF API version to 52
 * 2021-10-01 - Nathan Franklin - Refactoring transient attributes + further references
 */
public class TIBCOConsignmentWrapper {
	/**
	 * Transient attributes are used for mappings that are not persisted in Salesforce.
	 * We do this for attributes that are not mapped in the Subscription (S03) interface
	 * NOTE: consignmentTransientAttributes are currently not implemented! See implementation of how this is done in TIBCOArticleWrapper
	 *		  To implement this, an update to TIBCOArticleService.mergeTransientsIntoResult/getTransientAttributesFromResult will be required too
	 */
	//public ConsignmentTransientAttributes transientAttributes = new ConsignmentTransientAttributes();

	public Article__c proxyConsignment {
		get {
			if (proxyConsignment == null) {
				proxyConsignment = new Article__c();
			}
			return proxyConsignment;
		}
		set;
	}

	public List<TIBCOArticleWrapper> articles { get; set; }

	public List<TIBCOEventMessageWrapper> eventMessages { get; set; }

	// These contacts fields are populated in bulk when using Happy Parcel
	public Contact sender { get; set; }
	public Contact receiver { get; set; }

	public TIBCOConsignmentWrapper(Article__c c, List<Article__c> cArticles, Map<Id, List<EventMessage__c>> articleToEventMessages) {
		this(c, cArticles, new Map<Id, List<EventMessage__c>>(), new Map<Id, Map<String, Contact>>());
	}

	public TIBCOConsignmentWrapper(Article__c c, List<Article__c> cArticles, Map<Id, List<EventMessage__c>> articleToEventMessages, Map<Id, Map<String, Contact>> contactArticleMappings) {
		articles = new List<TIBCOArticleWrapper>();
		eventMessages = new List<TIBCOEventMessageWrapper>();

		if (c != null) {
			// A clone is probably not necessary anymore since we are now using Lightning for all SAP-EM queries (no more visualforce viewstate)
			// That being said, I'll leave it here but we will now preserve the Id of the passed in object (if there was one)
			proxyConsignment = c.clone(true, true);

			// store the matched contacts
			if (contactArticleMappings != null && contactArticleMappings.get(c.Id) != null && contactArticleMappings.get(c.Id).get('receiver') != null) receiver = contactArticleMappings.get(c.Id).get('receiver');
			if (contactArticleMappings != null && contactArticleMappings.get(c.Id) != null && contactArticleMappings.get(c.Id).get('sender') != null) sender = contactArticleMappings.get(c.Id).get('sender');

			if (cArticles != null) {
				for (Article__c a : cArticles) {
					articles.add(new TIBCOArticleWrapper(a, articleToEventMessages, contactArticleMappings.get(a.Id)));
				}
			}

			List<EventMessage__c> emList = articleToEventMessages.get(c.Id);
			if (emList != null) {
				for (EventMessage__c em : emList) {
					eventMessages.add(new TIBCOEventMessageWrapper(em));
				}
			}
		}
	}

	public TIBCOConsignmentWrapper(String trackingId, AuspostQueryTrackEventsSchema.ConsignmentDetails_element consignmentDetails) {
		this(consignmentDetails);
		this.proxyConsignment.TrackingID__c = trackingId;
	}

	public TIBCOConsignmentWrapper(AuspostQueryTrackEventsSchema.ConsignmentDetails_element consignmentDetails) {
		articles = new List<TIBCOArticleWrapper>();
		eventMessages = new List<TIBCOEventMessageWrapper>();
		String consignmentMLID = ''; //Added by David Catindoy (March 22, 2017) - StarTrack SSC5.1

		if (consignmentDetails != null && consignmentDetails.ConsignmentEnvelope != null) {
			if (consignmentDetails.ConsignmentEnvelope.CommunicationEvent != null) {
				for (AuspostEventSchema.CommunicationEvent ce : consignmentDetails.ConsignmentEnvelope.CommunicationEvent) {
					eventMessages.add(new TIBCOEventMessageWrapper(ce));
				}
			}

			if (consignmentDetails.ConsignmentEnvelope.DeviceEvent != null) {
				for (AuspostEventSchema.DeviceEvent de : consignmentDetails.ConsignmentEnvelope.DeviceEvent) {
					eventMessages.add(new TIBCOEventMessageWrapper(de));
				}
			}

			if (consignmentDetails.ConsignmentEnvelope.MailEvent != null) {
				for (AuspostEventSchema.MailEvent me : consignmentDetails.ConsignmentEnvelope.MailEvent) {
					eventMessages.add(new TIBCOEventMessageWrapper(me));
				}
			}


			if (consignmentDetails.ConsignmentEnvelope.Consignment != null) {
				AuspostMailProductSchema.Consignment c = consignmentDetails.ConsignmentEnvelope.Consignment;

				proxyConsignment.ArticleID__c = c.ConsignmentId;
				proxyConsignment.MLID__c = c.MerchantLocationId; //Added by David Catindoy (March 13, 2017) - StarTrack SSC5.1
				consignmentMLID = c.MerchantLocationId; //Added by David Catindoy (March 22, 2017) - StarTrack SSC5.1
				if (String.isNotBlank(consignmentMLID)) {
					try {
						Billing_Account__c billAccount = [SELECT Id FROM Billing_Account__c WHERE MLID__c = :consignmentMLID LIMIT 1];
						proxyConsignment.Billing_Account__c = billAccount.Id;
					} catch (Exception ex) {
						System.debug(ex);
					}
				}
				proxyConsignment.ConsignmentParcelCount__c = c.ParcelCount;

				System.debug('---c.DeliveryContacts:' + c.DeliveryContacts);
				if (c.DeliveryContacts != null) {
					for (AuspostMailProductSchema.DeliveryContact dc : c.DeliveryContacts) {
						if (dc.DeliveryContactType == 'DELIVERY' || dc.DeliveryContactType == 'RETURN') {
							proxyConsignment.DeliveryInstructions__c = dc.Comments;

							if (dc.Customer != null) {
								if (dc.Customer.Address != null) {
									for (AuspostLocationSchema.AddressType addType : dc.Customer.Address) {
										proxyConsignment.ReceiverAddress__c = '';
										if (addType.AddressDetails != null && addType.AddressDetails.AustralianAddress != null) {
											proxyConsignment.DestinationPostCode__c = addType.AddressDetails.AustralianAddress.PostCode;

											if (addType.AddressDetails.AustralianAddress.UnstructuredAddress != null
													&& addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine != null) {
												for (String s : addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine) {
													proxyConsignment.ReceiverAddress__c += s + ', ';
												}

												if (addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine.size() > 0) {
													proxyConsignment.ReceiverAddressLine1__c = addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine[0];
												}
												if (addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine.size() > 1) {
													proxyConsignment.ReceiverAddressLine2__c = addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine[1];
												}
												if (addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine.size() > 2) {
													proxyConsignment.ReceiverAddressLine3__c = addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine[2];
												}
												if (addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine.size() > 3) {
													proxyConsignment.ReceiverAddressLine4__c = addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine[3];
												}
											}

											proxyConsignment.ReceiverAddress__c += TIBCOUtils.removeNull(addType.AddressDetails.AustralianAddress.SuburbOrPlaceOrLocality) + ', ';
											proxyConsignment.ReceiverAddress__c += TIBCOUtils.removeNull(addType.AddressDetails.AustralianAddress.StateOrTerritory) + ' ';
											proxyConsignment.ReceiverAddress__c += TIBCOUtils.removeNull(addType.AddressDetails.AustralianAddress.PostCode) + ', ';
											if (addType.AddressDetails.AustralianAddress.Country != null) {
												proxyConsignment.ReceiverAddress__c += TIBCOUtils.removeNull(addType.AddressDetails.AustralianAddress.Country.CountryCode);
												proxyConsignment.ReceiverCountry__c = addType.AddressDetails.AustralianAddress.Country.CountryCode;
											}
											proxyConsignment.ReceiverCity__c = addType.AddressDetails.AustralianAddress.SuburbOrPlaceOrLocality;
											proxyConsignment.ReceiverState__c = addType.AddressDetails.AustralianAddress.StateOrTerritory;
											proxyConsignment.ReceiverPostcode__c = addType.AddressDetails.AustralianAddress.PostCode;
										} else if (addType.AddressDetails != null && addType.AddressDetails.InternationalAddress != null) {
											proxyConsignment.DestinationPostCode__c = addType.AddressDetails.InternationalAddress.PostCode;

											if (addType.AddressDetails.InternationalAddress.UnstructuredAddress != null
													&& addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine != null) {
												for (String s : addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine) {
													proxyConsignment.ReceiverAddress__c += s + ', ';
												}

												if (addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine.size() > 0) {
													proxyConsignment.ReceiverAddressLine1__c = addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine[0];
												}
												if (addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine.size() > 1) {
													proxyConsignment.ReceiverAddressLine2__c = addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine[1];
												}
												if (addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine.size() > 2) {
													proxyConsignment.ReceiverAddressLine3__c = addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine[2];
												}
												if (addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine.size() > 3) {
													proxyConsignment.ReceiverAddressLine4__c = addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine[3];
												}
											}

											proxyConsignment.ReceiverAddress__c += TIBCOUtils.removeNull(addType.AddressDetails.InternationalAddress.SuburbOrPlaceOrLocality) + ', ';
											proxyConsignment.ReceiverAddress__c += TIBCOUtils.removeNull(addType.AddressDetails.InternationalAddress.StateOrTerritory) + ' ';
											proxyConsignment.ReceiverAddress__c += TIBCOUtils.removeNull(addType.AddressDetails.InternationalAddress.PostCode) + ', ';
											if (addType.AddressDetails.InternationalAddress.Country != null) {
												proxyConsignment.ReceiverAddress__c += TIBCOUtils.removeNull(addType.AddressDetails.InternationalAddress.Country.CountryCode);
												proxyConsignment.ReceiverCountry__c = addType.AddressDetails.InternationalAddress.Country.CountryCode;
											}
											proxyConsignment.ReceiverCity__c = addType.AddressDetails.InternationalAddress.SuburbOrPlaceOrLocality;
											proxyConsignment.ReceiverState__c = addType.AddressDetails.InternationalAddress.StateOrTerritory;
											proxyConsignment.ReceiverPostcode__c = addType.AddressDetails.InternationalAddress.PostCode;
										}
									}
								}

								if (dc.Customer.ElectronicContact != null) {
									for (AuspostCommonSchema.ElectronicContactType ec : dc.Customer.ElectronicContact) {
										if (ec.Internet != null && ec.Internet.ContactType == 'EMAIL') {
											proxyConsignment.ReceiverEmail__c = ec.Internet.ContactDetail;
											break;
										}
									}
								}

								if (dc.Customer.Individual != null && dc.Customer.Individual.Name != null) {
									for (AuspostInvolvedPartSchema.IndividualName ind : dc.Customer.Individual.Name) {
										if (ind.NameUsage == 'IND') {
											proxyConsignment.ReceiverName__c = ind.FullName;
											break;//Reading only the first value
										}
									}

									for (AuspostInvolvedPartSchema.IndividualName ind : dc.Customer.Individual.Name) {
										if (ind.NameUsage == 'ORG') {
											proxyConsignment.ReceiverCompany__c = ind.FullName;
											break;//Reading only the first value
										}
									}
								}

								//Communication Decision
								if (dc.Customer.CommunicationDecision != null) {
									String cdCodes = '';
									for (AuspostCustomerSchema.CommunicationDecision cd : dc.Customer.CommunicationDecision) {
										cdCodes += cd.DecisionCode + '|';
									}
									proxyConsignment.CustCommDecisionCode__c = ArticleUtil.removeAtEnd(cdCodes, '|');
									ArticleUtil.setCommunicationDecisionDescription(proxyConsignment);
								}

								//Delivery Prefernce								 
								if (dc.Customer.DeliveryPreference != null && dc.Customer.DeliveryPreference.Options != null) {
									String dpCodes = '';
									for (AuspostCustomerSchema.Options_element op : dc.Customer.DeliveryPreference.Options) {
										dpCodes += op.OptionCode + '|';
									}
									proxyConsignment.CustDelPrefOptionCode__c = ArticleUtil.removeAtEnd(dpCodes, '|');
									ArticleUtil.setDeliveryPreferenceOptionDescription(proxyConsignment);
								}
							}
						}


						if (dc.DeliveryContactType == 'PICKUP' || dc.DeliveryContactType == 'SENDER') {
							if (dc.Customer != null) {
								if (dc.Customer.Address != null) {
									for (AuspostLocationSchema.AddressType addType : dc.Customer.Address) {
										proxyConsignment.SenderAddress__c = '';
										if (addType.AddressDetails != null && addType.AddressDetails.AustralianAddress != null) {
											if (addType.AddressDetails.AustralianAddress.UnstructuredAddress != null
													&& addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine != null) {
												for (String s : addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine) {
													proxyConsignment.SenderAddress__c += s + ', ';
												}

												if (addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine.size() > 0) {
													proxyConsignment.SenderAddressLine1__c = addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine[0];
												}
												if (addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine.size() > 1) {
													proxyConsignment.SenderAddressLine2__c = addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine[1];
												}
												if (addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine.size() > 2) {
													proxyConsignment.SenderAddressLine3__c = addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine[2];
												}
												if (addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine.size() > 3) {
													proxyConsignment.SenderAddressLine4__c = addType.AddressDetails.AustralianAddress.UnstructuredAddress.AddressLine[3];
												}
											}

											proxyConsignment.SenderAddress__c += TIBCOUtils.removeNull(addType.AddressDetails.AustralianAddress.SuburbOrPlaceOrLocality) + ', ';
											proxyConsignment.SenderAddress__c += TIBCOUtils.removeNull(addType.AddressDetails.AustralianAddress.StateOrTerritory) + ' ';
											proxyConsignment.SenderAddress__c += TIBCOUtils.removeNull(addType.AddressDetails.AustralianAddress.PostCode) + ', ';
											if (addType.AddressDetails.AustralianAddress.Country != null) {
												proxyConsignment.SenderAddress__c += TIBCOUtils.removeNull(addType.AddressDetails.AustralianAddress.Country.CountryCode);
												proxyConsignment.SenderCountry__c = addType.AddressDetails.AustralianAddress.Country.CountryCode;
											}
											proxyConsignment.SenderCity__c = addType.AddressDetails.AustralianAddress.SuburbOrPlaceOrLocality;
											proxyConsignment.SenderState__c = addType.AddressDetails.AustralianAddress.StateOrTerritory;
											proxyConsignment.SenderPostcode__c = addType.AddressDetails.AustralianAddress.PostCode;
										} else if (addType.AddressDetails != null && addType.AddressDetails.InternationalAddress != null) {
											if (addType.AddressDetails.InternationalAddress.UnstructuredAddress != null
													&& addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine != null) {
												for (String s : addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine) {
													proxyConsignment.SenderAddress__c += s + ', ';
												}

												if (addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine.size() > 0) {
													proxyConsignment.SenderAddressLine1__c = addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine[0];
												}
												if (addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine.size() > 1) {
													proxyConsignment.SenderAddressLine2__c = addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine[1];
												}
												if (addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine.size() > 2) {
													proxyConsignment.SenderAddressLine3__c = addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine[2];
												}
												if (addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine.size() > 3) {
													proxyConsignment.SenderAddressLine4__c = addType.AddressDetails.InternationalAddress.UnstructuredAddress.AddressLine[3];
												}
											}

											proxyConsignment.SenderAddress__c += TIBCOUtils.removeNull(addType.AddressDetails.InternationalAddress.SuburbOrPlaceOrLocality) + ', ';
											proxyConsignment.SenderAddress__c += TIBCOUtils.removeNull(addType.AddressDetails.InternationalAddress.StateOrTerritory) + ' ';
											proxyConsignment.SenderAddress__c += TIBCOUtils.removeNull(addType.AddressDetails.InternationalAddress.PostCode) + ', ';
											if (addType.AddressDetails.InternationalAddress.Country != null) {
												proxyConsignment.SenderAddress__c += TIBCOUtils.removeNull(addType.AddressDetails.InternationalAddress.Country.CountryCode);
												proxyConsignment.SenderCountry__c = addType.AddressDetails.InternationalAddress.Country.CountryCode;
											}
											proxyConsignment.SenderCity__c = addType.AddressDetails.InternationalAddress.SuburbOrPlaceOrLocality;
											proxyConsignment.SenderState__c = addType.AddressDetails.InternationalAddress.StateOrTerritory;
											proxyConsignment.SenderPostcode__c = addType.AddressDetails.InternationalAddress.PostCode;
										}
									}
								}

								if (dc.Customer.ElectronicContact != null) {
									for (AuspostCommonSchema.ElectronicContactType ec : dc.Customer.ElectronicContact) {
										if (ec.Internet != null && ec.Internet.ContactType == 'EMAIL') {
											proxyConsignment.SenderEmail__c = ec.Internet.ContactDetail;
											break;
										}
									}
								}

								if (dc.Customer.Individual != null && dc.Customer.Individual.Name != null) {
									for (AuspostInvolvedPartSchema.IndividualName ind : dc.Customer.Individual.Name) {
										if (ind.NameUsage == 'IND') {
											proxyConsignment.SenderName__c = ind.FullName;
											break;//Reading only the first value
										}
									}

									for (AuspostInvolvedPartSchema.IndividualName ind : dc.Customer.Individual.Name) {
										if (ind.NameUsage == 'ORG') {
											proxyConsignment.SenderCompany__c = ind.FullName;
											break;//Reading only the first value
										}
									}
								}
							}
						}
					}
				}

				if (c.FurtherReferences != null) {
					// map all the further attributes for easy access
					Map<String, String> references = getFurtherReferenceAttributes(c.FurtherReferences);

					proxyConsignment.ArticleLodgementDate__c = (!String.isEmpty(references.get('LODGEMENT_DATE')) ? TIBCOUtils.parseDateYYYYMMDD(references.get('LODGEMENT_DATE')) : null);
					proxyConsignment.ExpectedDeliveryDate__c = (!String.isEmpty(references.get('DELIVERED_BY_DATE')) ? TIBCOUtils.parseDateYYYYMMDD(references.get('DELIVERED_BY_DATE')) : null);
				}

				proxyConsignment.ActualWeight__c = c.TotalActualWeight;
				proxyConsignment.SignatureRequiredFlag__c = c.SignatureRequired != null ? c.SignatureRequired : false;

				ArticleUtil.setAdditionalServices(c.AdditionalServices, proxyConsignment, eventMessages);
			}
			
            System.debug('>>>>>> TIBCOConsignmentWrapper ArticleEnvelopes: ' + consignmentDetails.ConsignmentEnvelope.ArticleEnvelope);
            
			if (consignmentDetails.ConsignmentEnvelope.ArticleEnvelope != null) {
				for (AuspostQueryTrackEventsSchema.ArticleEnvelope ae : consignmentDetails.ConsignmentEnvelope.ArticleEnvelope) {
                    
					if (String.isNotBlank(consignmentMLID) && ae.Article != null && consignmentMLID.equals(ae.Article.MerchantLocationId)) { //Added by David Catindoy (March 22, 2017) - StarTrack SSC5.1
						articles.add(new TIBCOArticleWrapper(ae, this));																	 //It validates if child article has the same MLID with the parent consignment.
					} else if (String.isBlank(consignmentMLID)) {
						articles.add(new TIBCOArticleWrapper(ae, this));
					}                    
				}
			}
			
            System.debug('>>>>>> TIBCOConsignmentWrapper Articles: ' + articles);
            
			for (TIBCOEventMessageWrapper em : eventMessages) {
				if (em.proxyEM.EventType__c == 'CE-EN01' || em.proxyEM.EventType__c == 'CE-EN02') {
					proxyConsignment.Notification__c = true;
				}
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
	public class ConsignmentTransientAttributes {
	}
}