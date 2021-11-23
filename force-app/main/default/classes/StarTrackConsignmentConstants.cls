/*------------------------------------------------------------
Author:        Jen Karen Tan
Company:       Cloud Sherpas
Description:   Constants class for Consignment
History:
    April 4, 2016 - Jen Karen Tan - Created
------------------------------------------------------------*/
public class StarTrackConsignmentConstants {

	//Track & Trace Event Types
	public static final String EVENT_TYPE_TRTR_OUTG = 'OUTG';
	public static final String EVENT_TYPE_TRTR_PKUP = 'PKUP';
	public static final String EVENT_TYPE_TRTR_DELV = 'DELV';
	public static final String EVENT_TYPE_TRTR_ATL = 'ATL';
	public static final String EVENT_TYPE_TRTR_ADA = 'ADA';
	public static final String EVENT_TYPE_TRTR_INCG = 'INCG';
	public static final String EVENT_TYPE_TRTR_HATB = 'HATB';
	public static final String EVENT_TYPE_TRTR_TRSF = 'TRSF';
	public static final String EVENT_TYPE_TRTR_ASN = 'ASN';
	public static final String EVENT_TYPE_TRTR_FMMF = 'FMMF';
	public static final String EVENT_TYPE_TRTR_CUBE = 'CUBE';

	//Team Event Types
	public static final String EVENT_TYPE_TEAM_MANIFESTED = 'MANIFESTED';
	public static final String EVENT_TYPE_TEAM_PICKED_UP = 'PICKED-UP';
	public static final String EVENT_TYPE_TEAM_DELIVERED = 'DELIVERED';
	public static final String EVENT_TYPE_TEAM_SHORTAGE = 'SHORTAGE';
	public static final String EVENT_TYPE_TEAM_RETURNED = 'RETURNED';
	public static final String EVENT_TYPE_TEAM_CONN_RET = 'CONN-RETURNED-TO-DEPO';
	public static final String EVENT_TYPE_TEAM_BOOKIN = 'BOOKIN';
	public static final String EVENT_TYPE_TEAM_HELD = 'HELD';
	public static final String EVENT_TYPE_TEAM_RET_SENDER = 'RETURN-TO-SENDER';
	public static final String EVENT_TYPE_TEAM_REG_BMS = 'REGISTERED-BMS';
	public static final String EVENT_TYPE_TEAM_RECONSIGNED = 'RECONSIGNED';
	public static final String EVENT_TYPE_TEAM_NZ_SCANNING = 'NZ-SCANNING';
	public static final String EVENT_TYPE_TEAM_UNSGND_AIR_SAT = 'UNSIGNED-AIR-SATCHEL';
	public static final String EVENT_TYPE_TEAM_TRANSFER = 'TRANSFER';
	public static final String EVENT_TYPE_TEAM_REFSD_PEND = 'REFUSED-PENDING';
	public static final String EVENT_TYPE_TEAM_REDELIVER = 'REDELIVER';
	public static final String EVENT_TYPE_TEAM_FINAL_SHORTGE = 'FINAL-SHORTAGE';
	public static final String EVENT_TYPE_TEAM_POD_FILED = 'POD-FILED';
	public static final String EVENT_TYPE_TEAM_LBL_SCN_TRNST = 'LABEL-SCAN-IN-TRANSIT';
	public static final String EVENT_TYPE_TEAM_SCNND_IN_TRNST = 'SCANNED-IN-TRANSIT';
	public static final String EVENT_TYPE_TEAM_TRUCK_OUT = 'TRUCK-OUT';

	//Event Message Record Type Names
	public static final String REC_TYPE_EVENT_MESSAGE_ST_PICKUP_EVENT = 'StarTrack Pickup Event';
	public static final String REC_TYPE_EVENT_MESSAGE_ST_OTHR_EVENT = 'StarTrack Other Event';
	public static final String REC_TYPE_EVENT_MESSAGE_ST_INCG_HATB_TRSF_EVNT = 'StarTrack INCG/HATB/TRSF Event';
	public static final String REC_TYPE_EVENT_MESSAGE_ST_DELIVERY_ATL_NHCL_MANFEVNT = 'StarTrack Delivery/ATL/NHCL/Manifest Event';
	public static final String REC_TYPE_EVENT_MESSAGE_ST_CUBE_EVENT = 'StarTrack Cube Event';
}