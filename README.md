### A Debian based PHP (mod_fpm) + Apache (MPM events) Docker workflow

#### ⚠ This project is work in progress! Use with caution!

### Follow the steps to set up the development environment
1- Clone this project then generate a Laravel (or any PHP code) project inside `src`

2- Run the build script, `sh docker_build_dev.sh` for development or `sh docker_build_prod.sh` for a production optimized version.

3- Bring up the container using `sh docker_container_run.sh`


_Notes:_

- In case you need to extract a file from inside the image to the host environment you can easily achieve it like the following example:

`docker run --rm laravel-php-fpm-apache cat /etc/apache2/sites-available/000-default.conf > my-httpd.conf`
- The document root is set to `src/public` so if that folder doesn't exist, Apache won't start, of course you can always change that in `host.conf` file