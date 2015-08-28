# Travis CI

Our projects use [Travis CI][travis] to run their continuous integration.
The status of all the open-source projects on Travis can be seen [here][travis-sonarsource] and [here][travis-sonarcommunity].

## Configuring a project on Travis CI

To enable Travis on a given project, follow [these instructions][enable].

Basically, you have to add a `.travis.yaml` file to the project,
then configure TravisCI to build every push on that project.

Here's a sample `.travis.yaml` that builds a java project and runs its tests using maven.

```yaml
language: java
sudo: false
jdk: oraclejdk7
install: true
script: mvn verify -B -e -V
cache:
  directories:
    - '$HOME/.m2/repository'
```

Some project need to run multiple sets of tests, such as unit tests and integration tests.

Our approach is to describe the set of command for each category of tests in a `travis.sh` file at the root of the project and have travis run that script with different parameters.

```bash
#!/bin/bash

set -euo pipefail

case "$JOB" in
CI)
  mvn verify -B -e -V
  ;;
ITS)
  # Setup something before (database, files...)
  mvn verify -Pit -Dcategory=$IT_CATEGORY
  ;;
esac
```

```yaml
language: java
sudo: false
jdk: oraclejdk7
install: true
script: ./travis.sh

env:
  - JOB=CI
  - JOB=ITS IT_CATEGORY=issue
  - JOB=ITS IT_CATEGORY=analysis

cache:
  directories:
    - '$HOME/.m2/repository'
```

## Integration tests

Integration tests can setup the machine on Travis as they like given that the
build happens each time on a fresh machine with a well know blank state.
That makes it very easy to run ITs on Travis but could make it difficult
to run tests locally to debug a failure.

You can use [Docker][docker] to run a Travis build on your machine.

## Run a build with Docker

Here are the steps to follow to run a build with Docker:

 1. [Install Docker][install]
 2. Create a Dockerfile in the project. The file will most of the time be as simple as:

```Dockerfile
FROM dgageot/travis-docker
```

 3. Build the image

```bash
docker build -t ci .
```

 4. Run the travis.sh command

```bash
docker run -ti -e JOB=CI ci ./travis.sh
```

 5. Explore build artefacts in case of a build failure

```
# Search for the CONTAINER_ID of the build that just stopped
docker ps -a

# Enter that container with bash
docker --rm -ti exec [CONTAINER_ID] bash
```

An easier way of doing this, for beginners, is to start the container with `bash` command instead of `./travis.sh`.
This way, you can run `./travis.sh` inside the container and at the end of the build you'll still be inside the container, ready to list and view build output.

 6. Fix some code
 7. Goto 3. The container needs to be rebuilt before a new run is started.

## Accelerate the build

Because the build runs in a blank container, each time it runs it needs to download
all the maven dependencies (You know that maven download the Internet thing).
One way of fixing that is to share your own .m2 repository with the container
this way:

```bash
docker run -ti -v $HOME/.m2/:/root/.m2/ -e JOB=CI ci ./travis.sh
```

This is good because the build will be faster and use less bandwidth.
This is bad because you might have something in that repository that shouldn't
be here (a SNAPSHOT dependency for example) and the build might pass on
your machine and fail on Travis.

[travis]: https://travis-ci.org/
[travis-sonarsource]: https://travis-ci.org/SonarSource
[travis-sonarcommunity]: https://travis-ci.org/SonarCommunity
[enable]: http://docs.travis-ci.com/user/getting-started/
[docker]: https://www.docker.com/
[install]: https://docs.docker.com/
