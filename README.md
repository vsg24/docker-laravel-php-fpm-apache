### A Debian based PHP (mod_fpm) + Apache (MPM events) Docker workflow

### Using Dockerfile directly
1- Clone this project then generate a Laravel (or any PHP code) project inside `src`

2- Run the build script, `sh docker_build_dev.sh` for development or `sh docker_build_prod.sh` for a production optimized version.

3- Bring up the container using `sh docker_container_run.sh`

### Using Docker Compose
#### This approach adds a database (MariaDB) and also makes it easier to bring up/down PHP/Apache
1- Clone this project

2- Run `docker-compose build` to build the services. Optionally you may pass build time arguments like `--build-arg APP_DEBUG=false` or otherwise change their value inside `.env` file.
This could be particularly useful if you are using docker-compose to deploy for production on a single server.

3- Bring up all services using `docker-compose up`

_Notes:_

- In case you need to extract a file from inside the image to the host environment you can easily achieve it like the following example:

`docker run --rm laravel-php-fpm-apache cat /etc/apache2/sites-available/000-default.conf > my-httpd.conf`
- The document root is set to `src/public` so if that folder doesn't exist, Apache won't start, of course you can always change that in `host.conf` file