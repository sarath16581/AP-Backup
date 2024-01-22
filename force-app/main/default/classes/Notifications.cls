/**
 * @description Simple wrapper class for creating and sending in-app custom notifications (bell notifications) to users.
 *			  Allows mocking custom notification behaviour in unit tests.
 * @author Ranjeewa Silva
 * @date 2024-01-22
 * @test Notifications_Test
 * @changelog
 * 2024-01-22 - Ranjeewa Silva - Created.
 */
public inherited sharing class Notifications {

	// custom notification type configured in 'Notification Builder'.
	public static final Id DEFAULT_CUSTOM_NOTIFICATION_TYPE_ID {
		get {
			if (DEFAULT_CUSTOM_NOTIFICATION_TYPE_ID == null) {
				DEFAULT_CUSTOM_NOTIFICATION_TYPE_ID = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Custom_Notification' LIMIT 1].Id;
			}
			return DEFAULT_CUSTOM_NOTIFICATION_TYPE_ID;
		}
		set;
	}

	// collection of custom notifications added in current context. notifications in this collection will be sent when
	// 'send()' method is invoked.
	private List<Notifications.CustomNotification> notifications = new List<Notifications.CustomNotification>();

	public static Notifications getInstance() {
		return (Notifications) Application.Utilities.getInstance(Notifications.class);
	}

	/**
	 * Creates a new instance of custom notification.
	 * @return new custom notification instance
	 */
	public static Notifications.CustomNotification create() {
		return new Notifications.CustomNotification();
	}

	/**
	 * Adds a custom notification to the collection.
	 * @param notification newly created custom notification
	 *
	 * @return this instance for chaining
	 */
	public Notifications add(Notifications.CustomNotification notification) {
		this.notifications.add(notification);
		return this;
	}

	/**
	 * Sends custom notifications added in current context. Notifications are removed after they are sent.
	 */
	public void send() {
		for (Notifications.CustomNotification notification: this.notifications)  {
			notification.send();
		}
		this.notifications.clear();
	}

	/**
	 * Simple wrapper class for Messaging.CustomNotification(https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_Messaging_CustomNotification.htm).
	 */
	public class CustomNotification {
		private Id notificationTypeId;
		private Id senderId;
		private String title;
		private String body;
		private Id targetId;
		private String targetPageRef;
		private Set<Id> recipientIds;

		private CustomNotification() {
		}

		/**
		 * Sets the type of the custom notification configured in 'Notification Builder'.
		 * @param notificationTypeId The ID of the Custom Notification Type being used for the notification.
		 *						   A notification type is required to send a custom notification.
		 *
		 * @return this instance (for method chaining)
		 */
		public Notifications.CustomNotification setNotificationTypeId(Id notificationTypeId) {
			this.notificationTypeId = notificationTypeId;
			return this;
		}

		/**
		 * Sets the sender of the custom notification.
		 * @param senderId The User ID of the sender of the notification.
		 *
		 * @return this instance (for method chaining)
		 */
		public Notifications.CustomNotification setSenderId(Id senderId) {
			this.senderId = senderId;
			return this;
		}

		/**
		 * Sets the title of the custom notification.
		 * @param title The title of the notification (mandatory), as it will be seen by recipients. Please refer Apex docs on the max character limit.
		 *
		 * @return this instance (for method chaining)
		 */
		public Notifications.CustomNotification setTitle(String title) {
			this.title = title;
			return this;
		}

		/**
		 * Sets the body of the custom notification.
		 * @param body The body of the notification (mandatory), as it will be seen by recipients. Please refer Apex docs on the max character limit.
		 *
		 * @return this instance (for method chaining)
		 */
		public Notifications.CustomNotification setBody(String body) {
			this.body = body;
			return this;
		}

		/**
		 * Sets the target record of the custom notification.
		 * @param targetId The Id for the target record of the notification.
		 *
		 * @return this instance (for method chaining)
		 */
		public Notifications.CustomNotification setTargetId(Id targetId) {
			this.targetId = targetId;
			return this;
		}

		/**
		 * Sets the target page of the custom notification.
		 * @param targetPageRef The PageReference for the navigation target of the notification.
		 *
		 * @return this instance (for method chaining)
		 */
		public Notifications.CustomNotification setTargetPageRef(String targetPageRef) {
			this.targetPageRef = targetPageRef;
			return this;
		}

		/**
		 * Sets the recipients of the custom notification.
		 * @param recipientIds A set of recipient Ids (mandatory). Each recipient Id corresponds to a recipient or
		 *					  recipient type that the notification should be sent to. Please refer Apex docs on valid recipient type values:
		 *					  https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_Messaging_CustomNotification.htm#apex_Messaging_CustomNotification_send
		 *
		 * @return this instance (for method chaining)
		 */
		public Notifications.CustomNotification setRecipientIds(Set<Id> recipientIds) {
			this.recipientIds = recipientIds;
			return this;
		}

		/**
		 * Sends custom notification to the specified users.
		 */
		public void send() {
			Messaging.CustomNotification customNotification = new Messaging.CustomNotification();
			customNotification.setNotificationTypeId(this.notificationTypeId);
			customNotification.setBody(this.body);
			customNotification.setTitle(this.title);
			customNotification.setSenderId(this.senderId);
			customNotification.setTargetId(this.targetId);
			customNotification.setTargetPageRef(this.targetPageRef);
			customNotification.send(this.getRecipientIdStrings());
		}

		/**
		 * Transform recipient ids (Set<Id>) to the form required by Apex (Set<String>).
		 * @return recipient ids transformed in to a set of strings.
		 */
		private Set<String> getRecipientIdStrings() {
			return new Set<String>((List<String>)new List<Id>(recipientIds));
		}
	}
}