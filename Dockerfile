FROM ubuntu:16.04

MAINTAINER Paulo Prado <pvsprado@gmail.com>

# Installing all the tools necessary to build and run tensorflow with cmake
RUN apt-get update \
	&& apt-get install -y --no-install-recommends software-properties-common \
	&& apt-get install -y -q autoconf automake libtool curl make g++ unzip git \
	&& apt-get install -y -q python-numpy swig python-dev python-wheel


# Installing Bazel, 3 steps. From Bazel installing documentation

#Step 1: Install JDK 8
RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  apt-get install -y oracle-java8-installer && \
  rm -rf /var/lib/apt/lists/* && \
rm -rf /var/cache/oracle-jdk8-installer

#Step 2: Add Bazel distribution URI as a package source
RUN echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" | tee /etc/apt/sources.list.d/bazel.list \
	&& curl https://bazel.io/bazel-release.pub.gpg | apt-key add -

#Step 3: Update, install and upgrade Bazel
RUN apt-get update && apt-get install -y -q bazel \
	&& apt-get upgrade -y -q bazel

#Installing and Setting up TensorFlow

#Dependencies and clone

RUN git clone https://github.com/tensorflow/tensorflow

#Configuring BUILD file and build it
RUN cd tensorflow \
	&& sed -i '$ a\cc_binary(\n    name = \"libtensorflow_all.so\",\n    linkshared = 1,\n    linkopts = [\"-Wl,--version-script=tensorflow/tf_version_script.lds\"],\n    deps = [\n        \"//tensorflow/cc:cc_ops\",\n        \"//tensorflow/core:framework_internal\",\n        \"//tensorflow/core:tensorflow\",\n    ],\n)' tensorflow/BUILD \
	&& printf '/usr/bin/python\nN\nN\n/usr/local/lib/python2.7/dist-packages\nN\n' | ./configure  \
	&& bazel build tensorflow:libtensorflow_all.so

#Copy files, .so and dependencies
RUN cp /tensorflow/bazel-bin/tensorflow/libtensorflow_all.so /usr/local/lib \
	&& mkdir -p /usr/local/include/google/tensorflow \
	&& cp -r /tensorflow/tensorflow /usr/local/include/google/tensorflow/ \
	&& find /usr/local/include/google/tensorflow/tensorflow -type f  ! -name "*.h" -delete \
	&& cp /tensorflow/bazel-genfiles/tensorflow/core/framework/*.h  /usr/local/include/google/tensorflow/tensorflow/core/framework \
	&& cp /tensorflow/bazel-genfiles/tensorflow/core/kernels/*.h  /usr/local/include/google/tensorflow/tensorflow/core/kernels \
	&& cp /tensorflow/bazel-genfiles/tensorflow/core/lib/core/*.h  /usr/local/include/google/tensorflow/tensorflow/core/lib/core \
	&& cp /tensorflow/bazel-genfiles/tensorflow/core/protobuf/*.h  /usr/local/include/google/tensorflow/tensorflow/core/protobuf \
	&& cp /tensorflow/bazel-genfiles/tensorflow/core/util/*.h  /usr/local/include/google/tensorflow/tensorflow/core/util \
	&& cp /tensorflow/bazel-genfiles/tensorflow/cc/ops/*.h  /usr/local/include/google/tensorflow/tensorflow/cc/ops \
	&& cp -r /tensorflow/third_party /usr/local/include/google/tensorflow/ \
	&& rm -r /usr/local/include/google/tensorflow/third_party/py 

ADD example /example