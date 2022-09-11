/**
 * @description Class that should store all the Local Business Partner specific constants
 * @author Nathan Franklin
 * @date 2022-08-29
 * @changelog
 */
public inherited sharing class LBPConstants {

	public static final String COMMUNITY_PROFILE_NAME = 'LPO Partner Community User';

	public static final Id COMMUNITY_PROFILE_ID {
		get {
			if(COMMUNITY_PROFILE_ID == null) {
				COMMUNITY_PROFILE_ID = Application.Cache.profileIds.get(COMMUNITY_PROFILE_NAME);
			}
			return COMMUNITY_PROFILE_ID;
		}
		private set;
	}

}