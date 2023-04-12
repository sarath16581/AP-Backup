/**
 * Created by nmain on 28/05/2018.
 */
({
    validationMap: function() {
        return {
            'ChasGivenName': this.validateGivenName,
            'ChasSurname': this.validateSurname,
            'ChasEmail': this.validateEmail,
            'ChasPhone': this.validatePhone
        };
    },
})