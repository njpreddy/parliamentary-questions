#!/bin/bash
# -*- 

set -e

CONTAINERS=(assets rails)

DEFAULT_DOCKERREPO="docker.local:5000"
DEFAULT_DOCKERTAG="assets"

DOCKERREPO="${DOCKERREPO:-$DEFAULT_DOCKERREPO}"
DOCKERTAG="${DOCKERTAG:-$DEFAULT_DOCKERTAG}"


tag()
{
    # If an application prefix has been passed in via APP_PREFIX use
    # it during all docker operations
    if [ -n "${APP_PREFIX}" ]; then
        IMAGE="${APP_PREFIX}_$1"
    else
        IMAGE="$1"
    fi
    if [ -n "$2" ]; then
        TAG="${DOCKER_PREFIX}${DOCKERREPO}/${IMAGE}:$2"
    else
        TAG="${DOCKER_PREFIX}${DOCKERREPO}/${IMAGE}"
    fi
    echo $TAG
}

output()
{
    echo "$(tput setaf 1)$1$(tput sgr 0)"
}

docker_build()
{
    TAG=$(tag $1 $2)
    [ ! -d "docker" ] && output "Please run from git root" && exit 1

        rm -f .dockerignore
    [ -f "docker/$1/.dockerignore" ] && cp "docker/$1/.dockerignore" .
    cp "docker/$1/Dockerfile" .
        output "+ docker build -t ${TAG} --force-rm=true ."
        echo "BEGIN SECTION build-details"
    docker build -t ${TAG} --force-rm=true .
        RETCODE=$?
        echo "END SECTION"
    return $RETCODE
}

docker_push()
{
    TAG=$(tag $1 $2)
    # Skip push if build generates an error

    output "+ docker push --insecure-registry ${TAG}"
        echo "BEGIN SECTION push-details"
    docker push ${TAG}
    RETCODE=$?
        echo "END SECTION"
    return $RETCODE
}

docker_rmi()
{
    TAG=$(tag $1 $2)
    if [ -z "$DOCKER_NORMI" ]; then
        output "+ docker rmi ${TAG}"
        docker rmi ${TAG}
    fi
}


create_app_envvar()
{
  mkdir -p ./docker/app_env_vars
  echo "$2" > ./docker/app_env_vars/$1
}

###
###
###
if [ -n "$1" ]; then
  export APPVERSION=`echo "$1" | sed -e "s/.*release\///g"`
else
  export APPVERSION='latest'
fi

DATE=`date`

cat <<EOT >MANIFEST
Version:  $APPVERSION
Date:     $DATE
BuildTag: $BUILD_TAG
Commit:   $GIT_COMMIT

EOT

###
### Setup application envvars for docker
###
rm -f ./docker/app_env_vars/*
create_app_envvar APP_BUILD_VERSION "$APPVERSION"
create_app_envvar APP_BUILD_DATE    "$DATE"
create_app_envvar APP_BUILD_TAG     "$BUILD_TAG"
create_app_envvar APP_GIT_COMMIT    "$GIT_COMMIT"

# Generate a self contained bundle
#cd build
bundle --quiet \
       --path vendor/bundle \
       --deployment \
       --standalone \
       --without build


# Add sample envvars if present
if [ -f ".env.sample" ]; then
  set -a
  . .env.sample
  set +a
fi
rm -rf bin
bundle exec rake rails:update:bin
bundle exec rake assets:precompile RAILS_ENV=production

# Once the assets have been built add a ping to the assets server
cat <<EOT >public/assets/ping.json
{"version_number":"$APPVERSION","build_date":"$DATE","commit_id":"$GIT_COMMIT","build_tag":"$BUILD_TAG"}
EOT

# After here we capture the retcode when we need it, so turn off automatic fail on error
set +e

JENKINS_RETCODE=0

# Build containers
for i in  ${CONTAINERS[@]}; do
  docker_build $i $APPVERSION
  RETCODE=$?
  if [ "$RETCODE" -ne 0 ]; then
     JENKINS_RETCODE=$RETCODE
     DOCKER_NOPUSH=true
     output "Failed $i build with code $RETCODE - skipping further builds and disabling push"
     break
  fi
done


# Push containers only if all builds were successful and DOCKER_NOPUSH isn't specified
if [ -z "$DOCKER_NOPUSH" ]; then
    for i in  ${CONTAINERS[@]}; do
        docker_push $i $APPVERSION
        RETCODE=$?
        if [ "$RETCODE" -ne 0 ]; then
            JENKINS_RETCODE=$RETCODE
            output "Failed $i push with code $RETCODE"
        fi
    done
else
    output "Not pushing images"
fi

if [ -z "$DOCKER_NORMI" ]; then
    for i in  ${CONTAINERS[@]}; do
        docker_rmi $i $APPVERSION
    done
else
    output "Not removing images"
fi

exit $JENKINS_RETCODE

