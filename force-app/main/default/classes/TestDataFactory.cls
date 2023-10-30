/**
* @author
* @date
* @group TestData
* @domain Test
* @description Test data factory
* 2023-08-07 - hasantha.liyanage@auspost.com.au Modified added InsertUsersQueueable
*/
@isTest
public class TestDataFactory {

	public static void createStandardUser(){
		Profile stdUserProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
		User testUser = new User(Alias = 'testusr', Email='testusr@testorg.com',
				EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
				LocaleSidKey='en_US', ProfileId = stdUserProfile.Id,
				TimeZoneSidKey='America/Los_Angeles', UserName='testusr@testorg.com');
		insert testUser;
	}

	public static void createCommunityUser(){
		Profile communityUserProfile = [SELECT Id FROM Profile WHERE Name = 'Customer Community Login User'];

		Account acc = new Account(Name='TestCommunity', OwnerId = UserInfo.getUserId());
		insert acc;

		Contact communityUserContact = new Contact(
				FirstName = 'Test',
				LastName = 'Community',
				AccountId = acc.Id,
				Email = 'testcommunity@example.com'
		);
		insert communityUserContact;

		User testCommunityUser = new User(Alias = 'testcomm', Email='testcommunityusr@testorg.com',
				EmailEncodingKey='UTF-8', LastName='Community', LanguageLocaleKey='en_US',
				LocaleSidKey='en_US', ProfileId = communityUserProfile.Id, IsActive=true,
				TimeZoneSidKey='America/Los_Angeles', UserName='testcommunityusr@testorg.com', ContactId=communityUserContact.Id);
		insert testCommunityUser;
	}

	//.. Creating LPO Community User. @auther: rajesh.punjabi@mav3rik.com
	public static User createLPOCommunityUser(){
		Profile communityUserProfile = [SELECT Id FROM Profile WHERE Name = 'LPO Partner Community User'];

		Account acc = new Account(Name='TestCommunity', OwnerId = UserInfo.getUserId());
		insert acc;

		Contact communityUserContact = new Contact(
				FirstName = 'Test',
				LastName = 'Community',
				AccountId = acc.Id,
				Email = 'testcommunity@example.com'
		);
		insert communityUserContact;

		User testCommunityUser = new User(Alias = 'testcomm', Email='testcommunityusr@testorg.com',
				EmailEncodingKey='UTF-8', LastName='Community', LanguageLocaleKey='en_US',
				LocaleSidKey='en_US', ProfileId = communityUserProfile.Id, IsActive=true,
				TimeZoneSidKey='America/Los_Angeles', UserName='testcommunityusr@testorg.com', ContactId=communityUserContact.Id);
		insert testCommunityUser;
		
		return testCommunityUser;
	}

	/**
	 * Queueable insertion of users with permissionSets to avoid mixed dml operations issues in unit tests
	 * pass a list of UserDTOs will generate the users with permission set assignments
	 */
	public class InsertUsersQueueable implements Queueable {
		private List<UserDTO> userDTOs;
		public InsertUsersQueueable(List<UserDTO> userDTOs) {
			this.userDTOs = userDTOs;
		}

		public void execute(QueueableContext context) {
			List<User> usersToInsert = new List<User>();
			List<PermissionSetAssignment> permissionSetAssignmentList = new List<PermissionSetAssignment>();
			// get permission sets to be assigned
			List<String> permissionSetNames = new List<String>();
			List<String> profiles = new List<String>();
			List<String> roles = new List<String>();
			for (UserDTO userDTO : userDTOs) {
				if(userDTO.permissionSetNames != null) {
					permissionSetNames.addAll(userDTO.permissionSetNames);
				}
				profiles.add(userDTO.profileName);
				roles.add(userDTO.role);
			}

			// Get profiles using Name-to-Profile map
			Map<String, Id> profileNameToId = new Map<String, Id>();
			for (Profile profile : [SELECT Id, Name FROM Profile WHERE Name IN :profiles]) {
				profileNameToId.put(profile.Name, profile.Id);
			}

			// Get roles using Name-to-UserRole map
			Map<String, Id> roleNameToId = new Map<String, Id>();
			for (UserRole role : [SELECT Id, Name FROM UserRole WHERE Name IN :roles]) {
				roleNameToId.put(role.Name, role.Id);
			}

			// Get permissionSets using Name-to-ps map
			Map<String, PermissionSet> permissionSetNameToRecord = new Map<String, PermissionSet>();
			for (PermissionSet permSet : [SELECT Id, Name FROM PermissionSet WHERE Name IN :permissionSetNames]) {
				permissionSetNameToRecord.put(permSet.Name, permSet);
			}

			// prepare users
			for (UserDTO userDTO : userDTOs) {
				User futureUser = new User(
						FirstName = userDTO.userName,
						LastName = userDTO.userName,
						Alias = 'future',
						DefaultGroupNotificationFrequency = 'N',
						DigestFrequency = 'N',
						Email = 'test@test.org',
						EmailEncodingKey = 'UTF-8',
						LanguageLocaleKey = 'en_US',
						LocaleSidKey = 'en_US',
						ProfileId = profileNameToId.get(userDTO.profileName),
						TimeZoneSidKey = 'America/Los_Angeles',
						Username = userDTO.userName + '@test.org',
						UserPermissionsMarketingUser = false,
						UserPermissionsOfflineUser = false,
						UserRoleId = roleNameToId.get(userDTO.role),
						ContactId = userDTO.contactId
				);
				usersToInsert.add(futureUser);
			}
			insert usersToInsert;

			// once users are created assign the perm sets
			for (User usr : usersToInsert) {
				for (UserDTO userDTO : userDTOs) {
					if (userDTO.permissionSetNames != null && !userDTO.permissionSetNames.isEmpty() && userDTO.userName == usr.FirstName) {
						for (String permSetName : userDTO.permissionSetNames) {
							permissionSetAssignmentList.add(new PermissionSetAssignment(PermissionSetId = permissionSetNameToRecord.get(permSetName).Id, AssigneeId = usr.Id));
						}
					}
				}
			}
			insert permissionSetAssignmentList;
		}
	}

	public class UserDTO {
		public String profileName { get; set; }
		public Set<String> permissionSetNames { get; set; }
		public String userName { get; set; }
		public String role { get; set; }
		public Id contactId { get; set; }
	}
}