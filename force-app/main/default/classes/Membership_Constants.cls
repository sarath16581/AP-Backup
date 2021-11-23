/*------------------------------------------------------------
Author:        Adrian Recio (adrian.recio@auspost.com.au)
Description:   Constant class for membership related apex components

History
05/07/2018     Adrian Recio (adrian.recio@auspost.com.au)         Created constant class for Membership components
05/05/2020     Disha Kariya     Added constants for Membership record types
------------------------------------------------------------*/

public with sharing class Membership_Constants {
    public static final string METHOD_EXPIRESIBLING='expireSiblingAndActivateMembership';
    public static final string CALLOUTEXCEPTION='MembershipTriggerHandler Exception';
    public static final string CLASS_MEMBERSHIPTRIGGERHANDLER='MembershipTriggerHandler';
    public static final string METHODEXCEPTION='METHODEXCEPTION';
    public static final string ERROR='ERROR';
    public static final string APLICATION_NAME='MembershipHandler';

    //Record Types Name
    public static final String APLAC_RECORD_TYPE = 'APLAC_Membership';
//    public static final String AUSTRAC_RECORD_TYPE = 'AUSTRAC Registration';
}