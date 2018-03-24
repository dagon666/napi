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

Integration test suite will start a dedicated container running python
pretenders to mock napiprojekt.pl. The test will run in a separate container. To run the tests just invoke:

    ./run_integration_tests.sh

If you change any of napi code, these changes will have to be incorporated into
Docker container as well, for the test suite to pick it up. In order to quickly
do that without rebuilding the images, just invoke:

    ./run_integration_tests.sh -u

### Running integration tests manually

It's possible to execute only selected test fixture:

    docker-compose run --rm napiclient python -m unittest integration_tests.test_formats.FormatsConversionTest

... or a test case:

    docker-compose run --rm napiclient python -m unittest integration_tests.test_formats.FormatsConversionTest.test_ifSubotageDetectsFormatsCorrectly


In order to increase verbosity of the test suite, one can define an
environmental variable: `NAPI_INTEGRATION_TESTS_LOGLEVEL=1`. When run manually
this can be done with docker like so:

    docker-compose run --rm -e NAPI_INTEGRATION_TESTS_LOGLEVEL=1 napiclient python -m unittest integration_tests.test_formats.FormatsConversionTest.test_ifSubotageDetectsFormatsCorrectly

The integration tests suite contains some long running tests which are skipped
by default, as the total execution time may be longer than an hour. In order to
enable them, an environment variable `NAPI_INTEGRATION_TESTS_LONG_ENABLED=1`
should be defined. When ran manually this can be done exactly the same way as
in the previous example:

    docker-compose run --rm -e NAPI_INTEGRATION_TESTS_LOGLEVEL=1 -e NAPI_INTEGRATION_TESTS_LONG_ENABLED=1 napiclient python -m unittest integration_tests.test_formats.FormatsConversionTest.test_ifSubotageDetectsFormatsCorrectly
