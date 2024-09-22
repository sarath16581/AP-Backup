/**
 * @description A utility class for defining and managing constant values used throughout the Apex classes in the Unified Experience.
 * @author Seth Heang
 * @changelog:
 * 2024-09-18 - Seth Heang - created
 */
public with sharing class UnifiedConstants {
	// case constants
	public static final String CASE_STATUS_NEW = 'New';
	public static final String CASE_STATUS_CLOSED = 'Closed';
	public static final String CASE_PRIORITY_NORMAL = 'Normal';
	public static final String CASE_CONTYPE_RECEIVER = 'Receiver';
	// Contact Request Status constants
	public static final String CONTACT_REQUEST_STATUS_NEW = 'New';
	public static final String CONTACT_REQUEST_STATUS_RESCHEDULED = 'Rescheduled';
	public static final String CONTACT_REQUEST_STATUS_ABANDONED = 'Abandoned';
}