/**************************************************
Description:    Simulate call

 This can be used by including these lines in AP_CTIConnector.page

// THIS IS FOR TESTING
// jQuery('#completeCall').click(function() {
// 	//fakeIt.simulateEnd('tracking');
//     //fakeIt.simulateEnd('case');
//     fakeIt.simulateEnd('callback');
// 	//fakeIt.simulateEnd();
// });
//
// (function() {
//     setTimeout(function() {
// 		//fakeIt.simulateStart('tracking');
//         //fakeIt.simulateStart('case');
//         fakeIt.simulateStart('callback');
// 		//fakeIt.simulateStart();
// 	}, 2000);
// })(fakeIt);

 And also for ending a call:
 <!--<button id="completeCall" type="button">Complete Call</button>-->

History:
--------------------------------------------------
2018-08-20	nathan.franklin@auspost.com.au	Created
**************************************************/
define(['util'],
	function (util) {

		var getTrackingPayLoad = function() {
			var e = {
			  	source: "0481133933",
				calltype: "Inbound",
				destination: "EXPR075_SYD",
				isConsult: false,
				action: "OpenObject",
				fieldName: "\"Phone\"",
				fieldValue:"",
				id:"03AD02B5C88A29C2",
				type: "Voice",
				mediaType: "voiceInbound",
			  	userData:{"r_IVRMode":"TST","r_Origin":"Test","IWS_CustomerSegment":"Consumer","r_CustomerIdentified":"true","r_LastAgentTimeLimit":"604800","PhoneNumber":"0481133933","r_LAR":"skipped","CustomerSegment":"Consumer","r_IWS_CustomerSegment":"Consumer","ENG_Service":"Engage_IVR_Consumer","ENG_DimAttribute_2":"General Enquiry","ENG_DimAttribute_1":"Tracking","ServiceType":"Domestic Parcels","r_IWS_ServiceType":"Domestic Parcels","ServiceSubType":"Parcel Post","r_IWS_ServiceSubType":"Parcel Post","r_SmartSpeakDest":"20","ENG_Environment":"1.1.1","r_Tracking":"Domestic","r_Source":"Consumer","CallUUID":"QLR5PMVPMH5T7277A6GP3EH47G002QPR","UData_ssani":"0481133933","UData_sstrackingid":"JDQ028430201000605000","GVP-Session-ID":"ACCF1263-3A83-43ED-F3BD-EBD344FE168E;gvp.rm.datanodes=1;gvp.rm.tenant-id=1_0286076320","CallInfo":"routed","ENG_Origin":"Test","r_INFO_TrunkName":"Internal_MGW_mel_1","GVP-Session-Data":"callsession=ACCF1263-3A83-43ED-F3BD-EBD344FE168E;1;0;;;;Environment;0286076320;;0;outofservice","X-Genesys-UData_sstrackingid":"JDQ028430201000605000","r_INFO_CustomerANI":"0481133933","r_IVRListName":"LC_External_Consumer2","r_MessagePersonality":"30","r_CUSTOM_NextAction":"","r_LC_Subroutines":"OC:EngageModule_OpenCloseCheck_v04|MSG:EngageModule_Message_v04|MENU:EngageModule_Menu_v04|REP:EngageModule_Reporting_v04|CUSTOM:EngageModule_Custom_v04|TGT:EngageModule_Target_v04|ATGT:EngageModule_AdvancedTarget_v04|PRI:EngageModule_Priority_v04|SPLAY:EngageModule_Splay_v04|CSL:EngageModule_CalculateSkillLevel_v04|EWT:EngageModule_EWT_v04|CB:EngageModule_CB_v04|DIGITS:EngageModule_Digits_v04|IDENTIFY:EngageModule_IdentifyCustomer_v04|SMSG:EngageModule_ScheduledMessage_v04","ENG_Mode":"TST","r_DNIS":"0396401019","r_SplayAction":"1","r_RecoveryAction":"TGT","r_RecoveryActionNumber":"Local_Track_157_TGT","EWT_ProductionEWT":"0","ENG_Custom_N_10":"0","r_INFO_EWTPlayed":"true","r_CSL_Running":"True","r_TGT_InputString":"r_TGT_IN_Skill:Local_Track_157|r_TGT_IN_MSGHold:|r_TGT_IN_MSGPrivacy:157934330|r_TGT_IN_MessageString:Music:Delivery_Support|r_TGT_IN_NoAgents:ClosedConsumerEmergency|r_TGT_IN_TargetFail:loop|r_TGT_IN_UseInQueueMessage:list|r_TGT_IN_StatServer:|r_AA_CalculateSkill:true|r_AA_PlayEWT:CON_EWT|r_TGT_IN_MessageString:list|r_TGT_IN_CallbackList:Consumer_Callback|r_TGT_IN_OverrideList:|_str_L_CFG_Skill:1","r_TGT_MessageString":"Music:Delivery_Support","r_CB_Identifier":"Consumer_Callback","r_OC_ReasonFlag":"none","r_OC_Status":"Open","ENG_CB_Status":"Not Qualified","r_RequestedSkill":"Local_Track_157","TGT_ProductionSkill":"Local_Track_157","TGT_ProductionVQ":"Local_Track_157_VQ_AustraliaPost_CSS_157_Voice_MEL","ENG_VirtualQueue":"Local_Track_157_VQ_AustraliaPost_CSS_157_Voice_MEL","RRequestedSkills":{"Test_157":"1"},"RTargetAgentGroup":"?:Test_157 >= 1","RPVQID":"00I8E3MU2OD67FGKUCIH4PTAES01GP0M","RVQID":"00I8E3MU2OD67FGKUCIH4PTAES01GP0M","RVQDBID":"23367","RTargetTypeSelected":"2","RTargetRuleSelected":"","RTargetObjectSelected":"?:Test_157 >= 1","RTargetObjSelDBID":"","RTargetAgentSelected":"moorhouses@APCSS1","RTargetAgSelDBID":"10925","RTargetPlaceSelected":"AUD7380FZG_Dr","RTargetPlSelDBID":"13060","RTenant":"AustraliaPost_CSS","RTenantDBID":"157","RStrategyName":"EngageListConfigurator_v4","RStrategyDBID":"4381","CBR-actual_volume":"","CBR-Interaction_cost":"","CBR-contract_DBIDs":"","CBR-IT-path_DBIDs":"","RRequestedSkillCombination":"Test_157=1","RTargetRequested":"?:Test_157 >= 1","PegAG?:Test_157 >= 1":1}
   			};
   			return e;
  		};

        var getCallbackPayLoad = function() {
            var e = {
                action: "OpenObject",
                calltype: "Outbound",
                destination: "157980481133933",
                fieldName: "\"Phone\"",
                fieldValue: "",
                id: "03AD02C994840DA5",
                isConsult: false,
                source: "ORS_Callback",
                type: "Voice",
                userData: {"CB_ProductionEWT":"0","CallInfo":"routed","CallUUID":"NFCLB930J51V1FLK692J7POG1K00445V","CustomerSegment":"Consumer","ENG_Custom_N_10":"0","ENG_Custom_S_10":"012UJRL8T4DPV7TS28IH4PTAES00AFB1","ENG_DimAttribute_1":"Tracking","ENG_DimAttribute_2":"General Enquiry","ENG_Environment":"1.1.1","ENG_Origin":"Test","ENG_Service":"Engage_IVR_Consumer","EWT_ProductionEWT":"0","GVP-Session-Data":"callsession=BC609FD8-529D-49B8-2481-6E1C11A36BD0;1;0;;;;Environment;0286076320;;0;outofservice","GVP-Session-ID":"BC609FD8-529D-49B8-2481-6E1C11A36BD0;gvp.rm.datanodes=1;gvp.rm.tenant-id=1_0286076320","IWS_CustomerSegment":"Consumer","PhoneNumber":"0481133933","ServiceSubType":"Parcel Post","ServiceType":"Domestic Parcels","UData_ssani":"0481133933","r_CB_Identifier":"Consumer_Callback","r_CB_ReturnAction":"850","r_CB_ReturnNumber":"0396401019","r_CFG_CB_CallbackDestination":"IRD_Callback","r_CFG_CB_CallbackIdentifier":"Consumer_Callback","r_CFG_CB_CallbackNumber":"157980481133933","r_CFG_CB_CallbackPriorityIncrement":"","r_CFG_CB_CallbackPriorityInitial":"","r_CFG_CB_CallbackPriorityInterval":"","r_CFG_CB_CallbackTenant":"AustraliaPost_CSS","r_CFG_CB_CallbackTime":"30","r_CFG_CB_ConnID":"*03ad02c994840da4","r_CFG_CB_IVRMode":"TST","r_CFG_CB_PresentationMessage":"157969230","r_CFG_CB_StatServer":"stat_server_reporting_a.australiapost","r_CFG_CB_TargetQueue":"Test_157_VQ_AustraliaPost_CSS_157_Voice_MEL_Callback","r_CFG_CB_TargetSkillExpression":"Local_Track_157>=100","r_CFG_CB_TargetTenant":"AustraliaPost_CSS","r_CSL_Running":"True","r_CallbackAttempt":"1","r_CustomerIdentified":"true","r_INFO_CustomerANI":"0481133933","r_INFO_TrunkName":"Internal_MGW_mel_1","r_IVRListName":"LC_External_Consumer2","r_IVRMode":"TST","r_IWS_CustomerSegment":"Consumer","r_IWS_ServiceSubType":"Parcel Post","r_IWS_ServiceType":"Domestic Parcels","r_LAR":"skipped","r_LastAgentTimeLimit":"604800","r_MessagePersonality":"30","r_NUM_NumberType":"Digit","r_NUM_ReadNumber":"0481133933","r_OC_ReasonFlag":"none","r_OC_Status":"Closed","r_Origin":"Test","r_ReturningCallback":"r_TGT_IN_Skill:Local_Track_157|r_TGT_IN_MSGHold:|r_TGT_IN_MSGPrivacy:157934330|r_TGT_IN_MessageString:Music:Delivery_Support|r_TGT_IN_NoAgents:ClosedConsumerEmergency|r_TGT_IN_TargetFail:loop|r_TGT_IN_UseInQueueMessage:list|r_TGT_IN_StatServer:|r_AA_CalculateSkill:true|r_AA_PlayEWT:CON_EWT|r_TGT_IN_MessageString:list|r_TGT_IN_CallbackList:Consumer_Callback|r_TGT_IN_OverrideList:|_str_L_CFG_Skill:1","r_SmartSpeakDest":"20","r_Source":"Consumer","r_SplayAction":"1","r_Tracking":"Domestic","r_CBReturn":"CBSUCCESS","r_CUSTOM_NextAction":"","r_LC_Subroutines":"OC:EngageModule_OpenCloseCheck_v04|MSG:EngageModule_Message_v04|MENU:EngageModule_Menu_v04|REP:EngageModule_Reporting_v04|CUSTOM:EngageModule_Custom_v04|TGT:EngageModule_Target_v04|ATGT:EngageModule_AdvancedTarget_v04|PRI:EngageModule_Priority_v04|SPLAY:EngageModule_Splay_v04|CSL:EngageModule_CalculateSkillLevel_v04|EWT:EngageModule_EWT_v04|CB:EngageModule_CB_v04|DIGITS:EngageModule_Digits_v04|IDENTIFY:EngageModule_IdentifyCustomer_v04|SMSG:EngageModule_ScheduledMessage_v04","ENG_Mode":"TST","r_DNIS":"157980481133933","r_RecoveryAction":"CBSUCCESS","r_RecoveryActionNumber":"857","r_CB_Status":"SUCCESS","r_CB_Step":"Returned","r_TGT_MessageString":"Music:Delivery_Support","ENG_CB_Status":"Success","r_RequestedSkill":"Local_Track_157","TGT_ProductionSkill":"Local_Track_157","TGT_ProductionVQ":"Local_Track_157_VQ_AustraliaPost_CSS_157_Voice_MEL","ENG_VirtualQueue":"Local_Track_157_VQ_AustraliaPost_CSS_157_Voice_MEL","RRequestedSkills":{"Test_157":"1"},"RPVQID":"00U1Q6JP3SDQN2STUCIH4PTAES004SFF","RVQID":"00U1Q6JP3SDQN2STUCIH4PTAES004SFF","RVQDBID":"23367","RTargetTypeSelected":"2","RTargetRuleSelected":"","RTargetObjectSelected":"?:Test_157 >= 1","RTargetObjSelDBID":"","RTargetAgentSelected":"64557713","RTargetAgSelDBID":"10887","RTargetPlaceSelected":"AUD7380FZG","RTargetPlSelDBID":"13059","RTenant":"AustraliaPost_CSS","RTenantDBID":"157","RStrategyName":"EngageListConfigurator_v4","RStrategyDBID":"4381","CBR-actual_volume":"","CBR-Interaction_cost":"","CBR-contract_DBIDs":"","CBR-IT-path_DBIDs":"","RRequestedSkillCombination":"Test_157=1","RTargetRequested":"?:Test_157 >= 1","PegAG?:Test_157 >= 1":1,"IWS_CallUuid":"012UJRL8T4DPV7TS28IH4PTAES00AFB2","IWS_ConnID":"03AD02C994840DA5","IWS_ANI":"ORS_Callback","IWS_DNIS":"157980481133933","IWS_ThisDN":"1575862"}
            };
            return e;
        };

        var getCasePayLoad = function() {
            var e = {
                source: "0481133933",
                calltype: "Inbound",
                destination: "EXPR075_SYD",
                isConsult: false,
                action: "OpenObject",
                fieldName: "\"Phone\"",
                fieldValue:"",
                id:"03AD02B5C88A29C2",
                type: "Voice",
                mediaType: "voiceInbound",
                userData: {"CaseNumber":"38322542","r_INFO_CustomerANI":"0481133933","r_INFO_TrunkName":"Internal_MGW_mel_2","r_INFO_OriginationSwitch":"AustraliaPost_CSS_157_Voice_MEL","r_IVRMode":"TST","r_IVRListName":"LC_Consumer","r_MessagePersonality":"30","r_CUSTOM_NextAction":"","r_LC_Subroutines":"OC:EngageModule_OpenCloseCheck_v04|MSG:EngageModule_Message_v04|MENU:EngageModule_Menu_v04|REP:EngageModule_Reporting_v04|CUSTOM:EngageModule_Custom_v04|TGT:EngageModule_Target_v04|ATGT:EngageModule_AdvancedTarget_v04|PRI:EngageModule_Priority_v04|SPLAY:EngageModule_Splay_v04|CSL:EngageModule_CalculateSkillLevel_v04|EWT:EngageModule_EWT_v04|CB:EngageModule_CB_v04|DIGITS:EngageModule_Digits_v04|IDENTIFY:EngageModule_IdentifyCustomer_v04|SMSG:EngageModule_ScheduledMessage_v04","r_Origin":"Test","ENG_Origin":"Test","ENG_Mode":"TST","r_DNIS":"0396401019","IWS_CustomerSegment":"Consumer","r_CustomerIdentified":"true","r_LastAgentTimeLimit":"604800","PhoneNumber":"0481133933","r_LAR":"skipped","CustomerSegment":"Consumer","r_IWS_CustomerSegment":"Consumer","ENG_Service":"Engage_IVR_Consumer","ENG_DimAttribute_2":"General Enquiry","ServiceType":"Domestic Parcels","r_IWS_ServiceType":"Domestic Parcels","ServiceSubType":"Parcel Post","r_IWS_ServiceSubType":"Parcel Post","ENG_DimAttribute_1":"Tracking","ENG_Environment":"1.2","r_RecoveryAction":"TGT","r_RecoveryActionNumber":"Track_Help_157_TGT","EWT_ProductionEWT":"253","ENG_Custom_N_10":"253","r_INFO_EWTPlayed":"true","r_CSL_Running":"True","r_TGT_InputString":"r_TGT_IN_Skill:Track_Help_157|r_TGT_IN_MSGHold:88888|r_TGT_IN_MSGPrivacy:157934330|r_TGT_IN_MessageString:Music:Track_Help|r_TGT_IN_NoAgents:800|r_TGT_IN_TargetFail:loop|r_TGT_IN_UseInQueueMessage:list|r_TGT_IN_StatServer:stat_server_routing_a.s02|r_AA_CalculateSkill:true|r_AA_PlayEWT:CON_EWT|r_TGT_IN_MessageString:list|r_TGT_IN_CallbackList:Consumer_Callback|r_TGT_IN_OverrideList:|_str_L_CFG_Skill:1","r_TGT_MessageString":"Music:Track_Help","r_CB_Identifier":"Consumer_Callback","r_OC_ReasonFlag":"none","r_OC_Status":"Open","ENG_CB_Status":"Not Qualified","r_RequestedSkill":"Track_Help_157","TGT_ProductionSkill":"Track_Help_157","TGT_ProductionVQ":"Track_Help_157_VQ_AustraliaPost_CSS_157_Voice_MEL","ENG_VirtualQueue":"Track_Help_157_VQ_AustraliaPost_CSS_157_Voice_MEL","RRequestedSkills":{"Test_157":"1"},"RTargetAgentGroup":"?:Test_157 >= 1","RPVQID":"00I8E3MU2OD67FGKUCIH4PTAES01FMO3","RVQID":"00I8E3MU2OD67FGKUCIH4PTAES01FMO3","RVQDBID":"23361","RTargetTypeSelected":"2","RTargetRuleSelected":"","RTargetObjectSelected":"?:Test_157 >= 1","RTargetObjSelDBID":"","RTargetAgentSelected":"moorhouses@APCSS1","RTargetAgSelDBID":"10925","RTargetPlaceSelected":"5CG7082RRS_Dr","RTargetPlSelDBID":"9941","RTenant":"AustraliaPost_CSS","RTenantDBID":"157","RStrategyName":"EngageListConfigurator_v4","RStrategyDBID":"4381","CBR-actual_volume":"","CBR-Interaction_cost":"","CBR-contract_DBIDs":"","CBR-IT-path_DBIDs":"","RRequestedSkillCombination":"Test_157=1","RTargetRequested":"?:Test_157 >= 1","PegAG?:Test_157 >= 1":1}
            };

            return e;
        };

		var getPayload = function() {
		    var e = {
				source: "0481133933",
				calltype: "Inbound",
				destination: "EXPR075_SYD",
				isConsult: false,
				action: "OpenObject",
				fieldName: "\"Phone\"",
				fieldValue:"",
				id:"03AD02B5C88A29C2",
				type: "Voice",
				mediaType: "voiceInbound",
				userData: {"r_INFO_CustomerANI":"0481133933","r_INFO_TrunkName":"Internal_MGW_mel_2","r_INFO_OriginationSwitch":"AustraliaPost_CSS_157_Voice_MEL","r_IVRMode":"TST","r_IVRListName":"LC_Consumer","r_MessagePersonality":"30","r_CUSTOM_NextAction":"","r_LC_Subroutines":"OC:EngageModule_OpenCloseCheck_v04|MSG:EngageModule_Message_v04|MENU:EngageModule_Menu_v04|REP:EngageModule_Reporting_v04|CUSTOM:EngageModule_Custom_v04|TGT:EngageModule_Target_v04|ATGT:EngageModule_AdvancedTarget_v04|PRI:EngageModule_Priority_v04|SPLAY:EngageModule_Splay_v04|CSL:EngageModule_CalculateSkillLevel_v04|EWT:EngageModule_EWT_v04|CB:EngageModule_CB_v04|DIGITS:EngageModule_Digits_v04|IDENTIFY:EngageModule_IdentifyCustomer_v04|SMSG:EngageModule_ScheduledMessage_v04","r_Origin":"Test","ENG_Origin":"Test","ENG_Mode":"TST","r_DNIS":"0396401019","IWS_CustomerSegment":"Consumer","r_CustomerIdentified":"true","r_LastAgentTimeLimit":"604800","PhoneNumber":"0481133933","r_LAR":"skipped","CustomerSegment":"Consumer","r_IWS_CustomerSegment":"Consumer","ENG_Service":"Engage_IVR_Consumer","ENG_DimAttribute_2":"General Enquiry","ServiceType":"Domestic Parcels","r_IWS_ServiceType":"Domestic Parcels","ServiceSubType":"Parcel Post","r_IWS_ServiceSubType":"Parcel Post","ENG_DimAttribute_1":"Tracking","ENG_Environment":"1.2","r_RecoveryAction":"TGT","r_RecoveryActionNumber":"Track_Help_157_TGT","EWT_ProductionEWT":"253","ENG_Custom_N_10":"253","r_INFO_EWTPlayed":"true","r_CSL_Running":"True","r_TGT_InputString":"r_TGT_IN_Skill:Track_Help_157|r_TGT_IN_MSGHold:88888|r_TGT_IN_MSGPrivacy:157934330|r_TGT_IN_MessageString:Music:Track_Help|r_TGT_IN_NoAgents:800|r_TGT_IN_TargetFail:loop|r_TGT_IN_UseInQueueMessage:list|r_TGT_IN_StatServer:stat_server_routing_a.s02|r_AA_CalculateSkill:true|r_AA_PlayEWT:CON_EWT|r_TGT_IN_MessageString:list|r_TGT_IN_CallbackList:Consumer_Callback|r_TGT_IN_OverrideList:|_str_L_CFG_Skill:1","r_TGT_MessageString":"Music:Track_Help","r_CB_Identifier":"Consumer_Callback","r_OC_ReasonFlag":"none","r_OC_Status":"Open","ENG_CB_Status":"Not Qualified","r_RequestedSkill":"Track_Help_157","TGT_ProductionSkill":"Track_Help_157","TGT_ProductionVQ":"Track_Help_157_VQ_AustraliaPost_CSS_157_Voice_MEL","ENG_VirtualQueue":"Track_Help_157_VQ_AustraliaPost_CSS_157_Voice_MEL","RRequestedSkills":{"Test_157":"1"},"RTargetAgentGroup":"?:Test_157 >= 1","RPVQID":"00I8E3MU2OD67FGKUCIH4PTAES01FMO3","RVQID":"00I8E3MU2OD67FGKUCIH4PTAES01FMO3","RVQDBID":"23361","RTargetTypeSelected":"2","RTargetRuleSelected":"","RTargetObjectSelected":"?:Test_157 >= 1","RTargetObjSelDBID":"","RTargetAgentSelected":"moorhouses@APCSS1","RTargetAgSelDBID":"10925","RTargetPlaceSelected":"5CG7082RRS_Dr","RTargetPlSelDBID":"9941","RTenant":"AustraliaPost_CSS","RTenantDBID":"157","RStrategyName":"EngageListConfigurator_v4","RStrategyDBID":"4381","CBR-actual_volume":"","CBR-Interaction_cost":"","CBR-contract_DBIDs":"","CBR-IT-path_DBIDs":"","RRequestedSkillCombination":"Test_157=1","RTargetRequested":"?:Test_157 >= 1","PegAG?:Test_157 >= 1":1}
			};

			return e;
  		};

		var simulateStart = function(type) {
		    var e = getPayload();
		    if(type == 'tracking') {
		        e = getTrackingPayLoad();
      		} else if(type == 'case') {
		    	//38322542
                e = getCasePayLoad();
            } else if(type == 'callback') {
                e = getCallbackPayLoad();
            }


			var fakeMessage = {
				channel: "/v2/me/calls",
				data: {
					notificationType: "StatusChange",
					call: {
						id: e.id,
						state: "Established",
						ani: e.source,
						dnis: e.destination,
						callType: e.calltype,
						userData: e.userData
					},
					messageType: "CallStateChangeMessage",
					fieldName: e.fieldName,
					fieldValue: e.fieldValue
				}
			};

			util.getInstance('genesys.message').publish(fakeMessage);
		};

		var simulateEnd = function(type) {
			var e = getPayload();
			if(type === 'tracking') {
				e = getTrackingPayLoad();
			} else if(type === 'case') {
                e = getCasePayLoad();
            } else if(type == 'callback') {
                e = getCallbackPayLoad();
            }

			var fakeMessage = {
				channel: "/v2/me/calls",
				data: {
					notificationType: "StatusChange",
					call: {
						id: e.id,
						state: "Completed",
						ani: e.source,
						dnis: e.destination,
						callType: e.calltype,
						userData: e.userData
					},
					messageType: "CallStateChangeMessage",
					fieldName: e.fieldName,
					fieldValue: e.fieldValue
				}
			};

			util.getInstance('genesys.message').publish(fakeMessage);
		};

		return {
		 	simulateStart: simulateStart,
		 	simulateEnd: simulateEnd
  		}
	}
);