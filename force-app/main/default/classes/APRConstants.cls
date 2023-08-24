/**
 * @description Class to store all constants for APR
 * @author Naveen Rajanna
 * @date 2022-04-15
 * @group Constants
 * @domain Core
 * @changelog
 * @Test StarTrackAPRAutomationModule_Test
 * 2022-04-15	Naveen Rajanna	REQ2811129 - created
 * 2023-08-18 Jacob Isaac REQ3267427- Inactivating status values that are removed
 */

public class APRConstants {
	public static final String RECTYPE_DEV_NAME_STARTRACK = 'StarTrack';

	public static Id RECTYPE_ID_STARTRACK {
		get {
			if (RECTYPE_ID_STARTRACK == null) {
				RECTYPE_ID_STARTRACK = RecordTypesSelector.newInstance()
						.selectByDeveloperName('APR__c', new Set<String>{ RECTYPE_DEV_NAME_STARTRACK })
						.values()[0]
					.Id;
			}
			return RECTYPE_ID_STARTRACK;
		}
		private set;
	}

	public static final String STATUS_OPEN = 'Open';
	//public static final String STATUS_UNRESOLVED = 'Unresolved';
	//public static final String STATUS_ACCEPTED = 'Accepted';
	public static final String STATUS_ACCOUNTLOST = 'Account Lost';
	//public static final String STATUS_REDUCTION = 'Reduction';
	//public static final String STATUS_EXEMPTION = 'Exemption';

	//public static final Set<String> STATUS_OPEN_UNRESOLVED = new Set<String>{ STATUS_OPEN, STATUS_UNRESOLVED };
	public static final Set<String> STATUS_OPEN_UNRESOLVED = new Set<String>{ STATUS_OPEN };
	// public static final Set<String> STATUS_VERFIED_MULTIPLE = new Set<String>{
	// 	STATUS_ACCEPTED,
	// 	STATUS_ACCOUNTLOST,
	// 	STATUS_REDUCTION,
	// 	STATUS_EXEMPTION
	// };
	public static final Set<String> STATUS_VERFIED_MULTIPLE = new Set<String>{
		STATUS_ACCOUNTLOST
	};
}