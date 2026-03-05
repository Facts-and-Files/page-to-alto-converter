<div align="right">
	
[![Run tests](https://github.com/Facts-and-Files/page-to-alto-converter/actions/workflows/run-tests.yml/badge.svg)](https://github.com/Facts-and-Files/page-to-alto-converter/actions/workflows/run-tests.yml)
 
</div>

# Transkribus PAGE XML to ALTO XML converter

Docker image that exposes an endpoint for converting PAGE XML (Transkribus flavor and PRImA v2019) to ALTO XML.
It basically bundles the already available Python scripts:

* https://github.com/OCR-D/page-to-alto
* https://github.com/kba/transkribus-to-prima

## Using the image

Pull the image

    $ docker pull schmuckerffds/page-to-alto-converter:latest

Start the container:

    $ docker run -d --rm \
        --name page2alto-converter \
        -p 8000:8000 \
        -e ENVIRONMENT=production \
        -e UPLOAD_KEY=upload-token \
        page-to-alto-server:latest

## API routes

By default the local PHP container will serve the API via http://localhost:8000/.
A static health check can be reached at http://localhost:8000/health.txt

## Documentation

Access to the route requires a bearer token. So add a 'Authorization: Bearer <upload-token>' header.

Send your PAGE XML as multipart/form-data. ALTO XML will be returned on success otherwise a JSON with some error data.

## Building for development/local docker

Clone the Github repository: https://github.com/Facts-and-Files/page-to-alto-converter.

Copy .env.example to .env and make your changes.

### Starting locally

Either you can use

	$ make serve

and

	$ make stop

to start and stop the app or with 

    $ docker compose up -d

for starting and 

    $ docker compose down

for stopping the container.

## Development helpers

### Makefile

A Makefile is included for managing some of the processes as starting/stoping the docker container and run tests etc. See help:

    $ make help
