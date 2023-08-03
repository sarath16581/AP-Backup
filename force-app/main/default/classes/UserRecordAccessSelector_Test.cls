/**
 * @author Paul Perry
 * 
 * Test method for UserRecordAccess Selector providing coverage
 *  - Contains some utility method overloads for easy UserRecordAccess record mocking
 * 
 
 * Mocking Example:
  
 		UserRecordAccessSelector mockURASelector = (UserRecordAccessSelector)MockUtility.mockSelector(
			UserRecordAccessSelector.class
		);
	
		MockUtility.Mocks.startStubbing();

		MockUtility.Mocks.when(
			mockURASelector.selectById((Id)fflib_Match.eq(recordId))
		).thenReturn(
			(UserRecordAccess)UserRecordAccessSelector_Test.mockUserRecordAccess(
				recordId,
				UserRecordAccessSelector_Test.ACCESS_FULL
			)
		);

		MockUtility.Mocks.stopStubbing();

 */
@IsTest
public with sharing class UserRecordAccessSelector_Test {

	public static final Set<RecordAccess>
		ACCESS_FULL = new Set<RecordAccess>(RecordAccess.values()),
		ACCESS_RO = new Set<RecordAccess>{ RecordAccess.HasReadAccess };

	// Basic coverage for USerRecordAccessSelector class.
	@IsTest
	static void testSelector() {
		// Covering newInstance overloads
		UserRecordAccessSelector.newInstance(0);
		UserRecordAccessSelector.newInstance(0, new Set<SObjectField>());
		UserRecordAccessSelector.newInstance(0, new Map<SObjectType,Set<SObjectField>>());

		// Requesting UserRecordAccess for and by Current User record
		UserRecordAccess ura = UserRecordAccessSelector.newInstance().selectById(
			UserInfo.getUserId()
		);
		
		System.assert(ura != null, 'Should return record');		
		System.assert(ura.HasReadAccess, 'User always has read access to its own user record');
	}

	/**
	 * Generates mock response with provided recordId for the CurrentUser having full access
	 * @param recordId 
	 * @return UserRecordAccess record
	 */
	public static UserRecordAccess mockUserRecordAccess(Id recordId) {
		return mockUserRecordAccess(recordId, ACCESS_FULL);
	}

	/**
	 * Generates mock response with provided recordId for the CurrentUser having provided access
	 * @param recordId 
	 * @return UserRecordAccess record
	 */
	public static UserRecordAccess mockUserRecordAccess(Id recordId, Set<RecordAccess> access) {
		return mockUserRecordAccess(
			new Set<Id>{ recordId },
			access
		).get(recordId);
	}

	/**
	 * Generates mock response with provided recordIds for the CurrentUser with provided access
	 * @param recordIds - Set containing all recordIds
	 * @param access - level of access for all records
	 * @return Map of UserRecordAccess by recordId
	 */
	public static Map<Id,UserRecordAccess> mockUserRecordAccess(Set<Id> recordIds, Set<RecordAccess> access) {
		return mockUserRecordAccess(recordIds, access, UserInfo.getUserId());
	}

	/**
	 * Generates mock response with provided recordIds for given userId with provided access
	 * @param recordIds - Set containing all recordIds
	 * @param access - level of access for all records
	 * @param userId - User for which the access is mocked
	 * @return Map of UserRecordAccess by recordId
	 */
	public static Map<Id,UserRecordAccess> mockUserRecordAccess(Set<Id> recordIds, Set<RecordAccess> access, Id userId) {
		Map<Id,Set<RecordAccess>> accessByRecordId = new Map<Id,Set<RecordAccess>>();

		for (Id recordId :recordIds) {
			accessByRecordId.put(recordId, access);
		}

		return mockUserRecordAccess(accessByRecordId, userId);
	}

	/**
	 * Generates mock response with provided access by recordId for given userId
	 * @param accessByRecordId - Map providing access level by each recordId
	 * @param userId - User for which the access is mocked
	 * @return Map of UserRecordAccess by recordId
	 */
	public static Map<Id,UserRecordAccess> mockUserRecordAccess(Map<Id,Set<RecordAccess>> accessByRecordId, Id userId) {
		List<Map<String,Object>> accessList = new List<Map<String,Object>>();

		for (Id recordId :accessByRecordId.keySet()) {
			Map<String,Object> accessMap = new Map<String,Object>{
				'Id' => recordId, // for map conversion
				'RecordId' => recordId,
				'UserId' => userId
			};

			Set<RecordAccess> access = accessByRecordId.get(recordId);

			if (access == null) {
				access = ACCESS_FULL;
			}

			for (RecordAccess ra :RecordAccess.values()) {
				accessMap.put(ra.name(), access.contains(ra));
			}

			accessList.add(accessMap);
		}

		return new Map<Id,UserRecordAccess>(
			(List<UserRecordAccess>)JSON.deserialize(
				JSON.serialize(accessList),
				List<UserRecordAccess>.class
			)
		);
	}

	// Keep enum names equal to field names for easy conversion
	public Enum RecordAccess {
		HasReadAccess,
		HasEditAccess,
		HasDeleteAccess,
		HasTransferAccess,
		HasAllAccess
	}
}