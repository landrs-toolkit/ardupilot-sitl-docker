FROM ubuntu:20.04 as builder

# Image Configuration
EXPOSE 5760/tcp
ARG COPTER_TAG=Copter-4.0.3
ARG PYTHON_V=python3
ARG SITLCFML_VERSION=2.5
ARG SITLFML_VERSION=2.5

# Default variables for simulator
ENV INSTANCE 0
ENV LAT 42.3898
ENV LON -71.1476
ENV ALT 14
ENV DIR 270
ENV MODEL hexa
ENV SPEEDUP 5
ENV VEHICLE ArduCopter

RUN ln -s /usr/bin/python3 /usr/bin/python & \
    ln -s /usr/bin/pip3 /usr/bin/pip

ENV DEBIAN_FRONTEND=noninteractive
# install git 
RUN apt-get update 

#Install requirements for ardupilot.  
##Note: conventionally an install script in the ardupilot repos would be most convenient but this script is currently broken in Ubuntu 20.04, the follow takes its place for now but is less future proof.
RUN apt-get install -y lsb-release tzdata \
    build-essential ccache g++ gawk git make wget cmake \
    g++-arm-linux-gnueabihf pkg-config-arm-linux-gnueabihf \
    libtool libxml2-dev libxslt1-dev lcov gcovr \
    ${PYTHON_V}-dev ${PYTHON_V}-pip ${PYTHON_V}-setuptools ${PYTHON_V}-numpy ${PYTHON_V}-pyparsing \
    xterm ${PYTHON_V}-matplotlib ${PYTHON_V}-serial ${PYTHON_V}-scipy ${PYTHON_V}-opencv \
    libcsfml-dev libcsfml-audio${SITLCFML_VERSION} libcsfml-dev libcsfml-graphics${SITLCFML_VERSION} \
    libsfml-audio${SITLFML_VERSION} libsfml-dev libsfml-graphics${SITLFML_VERSION} libsfml-network${SITLFML_VERSION} \
    libsfml-system${SITLFML_VERSION} libsfml-window${SITLFML_VERSION} ${PYTHON_V}-yaml \
    libcsfml-network${SITLCFML_VERSION} libcsfml-system${SITLCFML_VERSION} libcsfml-window${SITLCFML_VERSION} \
    && apt-get autoremove \
    && apt-get clean && rm -rf /var/lib/apt/lists/*  

RUN pip install pygame==2.0.0.dev6 intelhex future lxml pymavlink MAVProxy pexpect

#Build Ardupilot
FROM builder as APbuild

RUN git clone https://github.com/ArduPilot/ardupilot.git ardupilot

WORKDIR ardupilot
RUN git checkout ${COPTER_TAG} && git submodule update --init --recursive

RUN ./waf distclean
RUN ./waf configure --board sitl
RUN ./waf copter
RUN ./waf plane
RUN ./waf rover 
RUN ./waf sub
RUN echo "Finished setup and Build"

FROM APbuild as SITL_Executable

# Finally the command
ENTRYPOINT /ardupilot/Tools/autotest/sim_vehicle.py --vehicle ${VEHICLE} -I${INSTANCE} --custom-location=${LAT},${LON},${ALT},${DIR} -w --frame ${MODEL} --no-rebuild --no-mavproxy --speedup ${SPEEDUP}
