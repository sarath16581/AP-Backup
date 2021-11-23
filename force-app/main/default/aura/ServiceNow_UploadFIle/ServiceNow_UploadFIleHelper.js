/**
 * Created by hasantha on 15/5/19.
 */
({
    MAX_FILE_SIZE: 4000000,
    CHUNK_SIZE: 950000,

    /**
     * validate and prepare to save the file
     * @param component
     * @param helper
     */
    save : function(component, helper) {

        var files = component.get("v.fileToBeUploaded");
        // we do not handle more than one file at a time.
        if(files[0].length > 1) {
            alert('You cannot upload more than one file at a time!');
            return;
        }

        var file = files[0][0];

        // check for any special chars in the name
        if (!file.name.match(/^[0-9a-zA-Z\.]*$/)) {
            alert('File name should only contains letters and numbers, please rename the file and upload!');
            return;
        }

        // file extension are hard coded at the moment, we can bring this from a custom metadata or custom settings later, if required
        var allowedExtensions = /(\.jpg|\.jpeg|\.pdf|\.doc|\.docx)$/i;
        if(!allowedExtensions.exec(file.name)){
            alert('Please upload file having extensions PDF, JPEG or DOC only.');
            return;
        }

        // validate for the maximum file size
        if (file.size > this.MAX_FILE_SIZE) {
            alert('File size cannot exceed ' + this.MAX_FILE_SIZE/1000000 + 'MB.\n' +
                'Selected file size: ' + Math.round(file.size/1000000)  +'MB');
            return;
        }

        // read the file and extract the content
        var reader = new FileReader();
        var self = helper;
        reader.onload = function() {
            var fileContents = reader.result;
            var base64 = 'base64,';
            var dataStart = fileContents.indexOf(base64) + base64.length;
            fileContents = fileContents.substring(dataStart);
            // start uploading the file
            self.upload(component, self, file, fileContents);
        };

        reader.readAsDataURL(file);
    },

    /**
     * Initiate the upload process
     *
     * @param component
     * @param helper
     * @param file
     * @param fileContents
     */
    upload: function(component, helper, file, fileContents) {
        var fromPos = 0;
        var toPos = Math.min(fileContents.length, fromPos + this.CHUNK_SIZE);
        // start with the initial chunk
        helper.uploadChunk(component, helper, file, fileContents, fromPos, toPos, '');
    },


    /**
     * upload the first chunk and then start sending the following chunks via chunkSend method,
     * file needs to be chucked in order to pass through aura.
     *
     * @param component
     * @param helper
     * @param file
     * @param fileContents
     * @param fromPos
     * @param toPos
     * @param attachId
     */
    uploadChunk : function (component, helper, file, fileContents, fromPos, toPos, attachId) {
        // parameters to be passed to chunkSend method
        var paramObj = {
            file: file,
            fileContents: fileContents,
            fromPos: fromPos,
            toPos: toPos,
            attachId: attachId
        };

        // registering a promise and wait for the chunk to complete uploading, and then move to next chunk
        window.AP_LIGHTNING_UTILS.helperPromise(component, helper, paramObj, helper.chunkSend)
            .then($A.getCallback(function(result) {
                // get the version document id, and pass it in the next chunk upload request,
                // this will allow to pull the exisitng document verion and push the second chunk to the versionContent
                attachId = result;
                paramObj.fromPos = paramObj.toPos;
                paramObj.toPos = Math.min(paramObj.fileContents.length, paramObj.fromPos + helper.CHUNK_SIZE);
                // keep sending the chunks if the file size is more than the remaining size.
                if (paramObj.fromPos < paramObj.toPos) {
                    helper.uploadChunk(component, helper, paramObj.file, paramObj.fileContents, paramObj.fromPos, paramObj.toPos, attachId);
                } else {
                    // once all the chunks are uploaded, now it the time to notify the apex to start uploading the file to service now.
                    helper.notifyServNow(component, helper, attachId);

                }
            }))
            .catch($A.getCallback(function(result) {
                console.log('ERROR:  ServiceNow_UploadFile : uploadChunk()', result);
                alert('ERROR:  Failed, upload file', result);
            }));
    },

    /**
     *  send chunks of the file to append, this method is to use inside the promise
     * @param component
     * @param helper
     * @param paramObj
     * @param resolve
     * @param reject
     */
    chunkSend: function(component, helper, paramObj, resolve, reject) {
        var file = paramObj.file;
        var fileContents = paramObj.fileContents;
        var fromPos = paramObj.fromPos;
        var toPos = paramObj.toPos;
        var attachId = paramObj.attachId;
        var chunk = fileContents.substring(fromPos, toPos);

        // set parameters
        var params = {
            fileName: file.name,
            base64Data: encodeURIComponent(chunk),
            contentType: file.type,
            fileId: attachId
        };

        // resolve the promise on success
        var callBack = function(rslt) {
            resolve(rslt);
        };

        // reject on error
        var errCallBack = function(rslt) {
            console.log('ERROR chunkSend()',rslt);
            reject(rslt);
        }
        var loader = component.find('loader');
        window.AP_LIGHTNING_UTILS.invokeController(component, "saveTheChunk", params, callBack, errCallBack, false, loader);
    },

    /**
     * once the file chinks upload completed send the file to servicenow.
     * this method is to grab the full file from ContentVesionDocument and pass it to service now attach file endpoint,
     * once the response is success, we delete the file.
     *
     * @param component
     * @param helper
     * @param attachId
     */
    notifyServNow: function(component, helper, attachId) {
        var params = {
            attachId: attachId,
            parentId: component.get("v.parentId")
        };

        var callBack = function(rslt) {
            if(rslt) {
                alert('Success, Upload attachment completed');
            } else {
                alert('Error, Upload attachment failed!');
            }
        };

        var errCallBack = function(rslt) {
            console.log('ERROR notifyServNow()',rslt);
        }
        var loader = component.find('loader');
        window.AP_LIGHTNING_UTILS.invokeController(component, "uploadToServNow", params, callBack, errCallBack, false, loader);
    },

})