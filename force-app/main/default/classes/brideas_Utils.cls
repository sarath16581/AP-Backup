global class brideas_Utils {

    global static String generateToken(Integer len){
        len = len < 44 ? len : 44;

        Blob blobKey = crypto.generateAesKey(256);
        String key = EncodingUtil.base64encode(blobKey);

        return key.substring(0, len);
    }
}