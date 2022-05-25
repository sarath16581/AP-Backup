/**
 * @author Mahesh Parvathaneni
 * @date 2022-04-14
 * @group Utilities
 * @description Service class for handling Location functions
 * @changelog
*/

public inherited sharing class LocationsService {

    //CONSTANTS
    public static final String DISTANCE_UNIT_KM = 'km';
    public static final String DISTANCE_UNIT_MILE = 'mi';

    /**
	 * Grabs a new instance of this class
	 * Using Application.Utilities allows us to override this interface with a mock class for unit testing
	 */
	public static LocationsService getInstance() {
		return (LocationsService)Application.Utilities.getInstance(LocationsService.class);
	}

    /**
     * Returns the distance between two specified locations in kms
     */
    public Double getDistanceBetweenLocations(Location firstLocation, Location secondLocation) {
        return getDistanceBetweenLocations(firstLocation, secondLocation, DISTANCE_UNIT_KM);
    }

    /**
     * Calculates the distance between two specified locations with the specified unit using Location class.
     */
    public Double getDistanceBetweenLocations(Location firstLocation, Location secondLocation, String unit) {
        return Location.getDistance(firstLocation, secondLocation, unit);
    }
}