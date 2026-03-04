<div align="right">
	
[![Run tests](https://github.com/Facts-and-Files/page-to-alto-converter/actions/workflows/run-tests.yml/badge.svg)](https://github.com/Facts-and-Files/page-to-alto-converter/actions/workflows/run-tests.yml)
 
</div>

# Transkribus PAGE XML to ALTO XML converter

Docker image that exposes an endpoint for converting PAGE XML (Transkribus flavor and PRImA v2019) to ALTO XML.
It basically bundles the already available Python scripts:

* https://github.com/OCR-D/page-to-alto
* https://github.com/kba/transkribus-to-prima

## Building for development/local docker

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

## API routes

By default the local PHP container will serve the API via http://localhost:8000/.
A static health check can be reached at http://localhost:8000/health.txt

## Documentation

Access to the route require a bearer token.

Send your PAGE XML as multipart/form-data. ALTO XML will be returned on success otherwise a JSON with some error data.

## Deployment

Deployment is done by Github actions.

