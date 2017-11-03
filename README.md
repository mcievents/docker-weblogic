# WebLogic 12c Docker image

This image is intended to enable simple development and deployment for a single-server WebLogic environment.  While it can probably be used as the basis for more complex deployments (clustering, etc.), no special provisions for such a setup have been taken.

## Settings

The following settings control the build and the resulting image.

### Build arguments

*   `JAVA_DOWNLOAD_URL`: The URL from which to download a compatible JDK.  Get the JDK from Oracle's site and put it somewhere that it can be downloaded by the build process.
*   `JAVA_DOWNLOAD_SHASUM`: The SHA-256 checksum for the Java download.
*   `JAVA_VERSION`: The Java version string with patch release (ex. `"1.7.0_80"`).
*   `WEBLOGIC_DOWNLOAD_URL`: The URL from which to download the WebLogic installer.  Download the installer from Oracle's site and put it somwhere that it can be downloaded by the build process.
*   `WEBLOGIC_DOWNLOAD_SHASUM`: The SHA-256 checksum for the WebLogic download.

### Environment variables

The built image contains just the Java and WebLogic binaries with no WebLogic domain configured.  A WebLogic domain will be created and configured on first run.  The following environment variables control that domain.

*   `WEBLOGIC_DOMAIN`: The name of the WebLogic domain (default `"mydomain"`).
*   `WEBLOGIC_PWD`: The WebLogic domain admin password.  If left empty, the password will be read from a secret named `weblogic_admin_password`.  If no such secret exists, then a random password will be generated and echoed to standard output.  (default empty)
*   `WEBLOGIC_MEM_ARGS`: Java memory-related arguments to be used for the WebLogic server process.
*   `WEBLOGIC_PRE_CLASSPATH`: A colon-separated list of library files to be prepended to the WebLogic server classpath.

### User scripts

After the domain is created on first run, the image will run scripts provided by the user at `/opt/weblogic/scripts/setup`.  These scripts may be added by a child image or mounted as a volume.  Shell scripts with names ending in `.sh` will be sourced into the running setup script.  Python scripts with names ending in `.py` will be run by the WebLogic Scripting Tool (WLST).  Scripts are run in lexical order, so name them appropriately if the run order matters.

### Volumes

*   `/opt/weblogic/scripts/setup`: Location for user setup scripts used to customize the WebLogic domain.
*   `/srv/weblogic`: WebLogic domain directories are created here.  If the domain indicated by the `WEBLOGIC_DOMAIN` environment variable already exists here, then the container will not try to create a domain.

### Secrets

*   `weblogic_admin_password`: The WebLogic admin password set at domain creation.  Override this with the `WEBLOGIC_PWD` environment variable.  If both password sources are unset, then a random password will be generated and echoed to standard output.
