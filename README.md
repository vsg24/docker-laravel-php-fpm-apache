### A Debian based PHP (mod_fpm) + Apache (MPM events) Docker workflow

#### ⚠ This project is work in progress! Use with caution!

### Follow the steps to set up the development environment
1- Clone or generate a Laravel (or any PHP code) project inside `src`

2- Run `docker build -t "your_prefered_name" .` to build the image. Name the Docker image accordingly.

3- Depending on your operating system:

<small>For Windows: `docker run -p 80:80 --name your_prefered_name -v %cd%/src:/var/www/html your_prefered_name`</small>

<small>For Linux: `docker run -p 80:80 --name your_prefered_name -v $PWD/src:/var/www/html your_prefered_name`</small>


_Notes:_

In case you need to extract a file from inside an image to the host environment you can do the following:
`docker run --rm httpd:2.4 cat /et~~~~c/apache2/sites-available/000-default.conf > my-httpd.conf`