# Test suite

bashnapi comes with a comprehensive test suite and test environment. In order
to use it you'll need [Docker](https://www.docker.com).

## Containers

In order to support the environment you'll need to build images for the
_Docker_ containers. The following _Docker_ files have been provided:

- `Dockerfile-napitester` - an image containing all the dependencies and
libraries for unit testing.

- `Dockerfile-napiserver` - an image running
[Pretenders](https://github.com/pretenders/pretenders) used for integration
testing and acting as [napiprojekt.pl](http://napiprojekt.pl) mock.

- `Dockerfile-napiclient` - this image is extending a napi image from the main
directory - (you'll have to build it first), and is used for integration
testing. It contains an installation of napi.sh along with integration tests
dependencies.

## Preparations

Assuming that the current working directory is the root of the project, build
the napi _Docker_ image:

    docker build -t napi .

Once that's done, proceed to the `tests` directory to build the rest of the
images:

    cd tests
    docker-compose build

If the last step was successful, all the required images have been built and
are ready to use.

## Unit tests

To run all unit tests, simply invoke

    ./run_unit_tests.sh

in the `tests` directory. It's possible to run a selected test only as well.
Just provide the file name:

    ./run_unit_tests.sh libnapi_http_test.sh

Each unit tests execution generates coverage report which can be found in
`tests/converage` directory. Navigate your browser there to get more details.

## Integration tests

TODO update this section
