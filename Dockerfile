FROM ubuntu:14.04

MAINTAINER Paulo Prado <pvsprado@gmail.com>

# Installing Bazel, 3 steps. From Bazel installing documentation

#Step 1: Install JDK 8
RUN add-apt-repository ppa:webupd8team/java \
	&& apt-get update \
	&& apt-get install oracle-java8-installer

#Step 2: Add Bazel distribution URI as a package source
RUN echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" | tee /etc/apt/sources.list.d/bazel.list \
	&& curl https://bazel.io/bazel-release.pub.gpg | apt-key add -

#Step 3: Update, install and upgrade Bazel
RUN apt-get update && sudo apt-get install bazel \
	&& apt-get upgrade bazel

#Installing and Setting up TensorFlow

#Dependencies and clone
RUN apt-get install autoconf automake libtool curl make g++ unzip \
	&& apt-get install python-numpy swig python-dev python-wheel \
	&& git clone https://github.com/tensorflow/tensorflow

#Configuring BUILD file and build it
RUN cd tensorflow \
	&& sed -i '$ a\cc_binary(\n    name = \"libtensorflow_all.so\",\n    linkshared = 1,\n    linkopts = [\"-Wl,--version-script=tensorflow/tf_version_script.lds\"],\n    deps = [\n        \"//tensorflow/cc:cc_ops\",\n        \"//tensorflow/core:framework_internal\",\n        \"//tensorflow/core:tensorflow\",\n    ],\n)' tensorflow/tensorflow/BUILD \
	&& ./configure \
	&& bazel build tensorflow:libtensorflow_all.so

#Copy files, .so and dependencies
RUN cp bazel-bin/tensorflow/libtensorflow_all.so /usr/local/lib \
	&& mkdir -p /usr/local/include/google/tensorflow \
	&& cp -r tensorflow /usr/local/include/google/tensorflow/ \
	&& find /usr/local/include/google/tensorflow/tensorflow -type f  ! -name "*.h" -delete \
	&& cp bazel-genfiles/tensorflow/core/framework/*.h  /usr/local/include/google/tensorflow/tensorflow/core/framework \
	&& cp bazel-genfiles/tensorflow/core/kernels/*.h  /usr/local/include/google/tensorflow/tensorflow/core/kernels \
	&& cp bazel-genfiles/tensorflow/core/lib/core/*.h  /usr/local/include/google/tensorflow/tensorflow/core/lib/core \
	&& cp bazel-genfiles/tensorflow/core/protobuf/*.h  /usr/local/include/google/tensorflow/tensorflow/core/protobuf \
	&& cp bazel-genfiles/tensorflow/core/util/*.h  /usr/local/include/google/tensorflow/tensorflow/core/util \
	&& cp bazel-genfiles/tensorflow/cc/ops/*.h  /usr/local/include/google/tensorflow/tensorflow/cc/ops \
	&& cp -r third_party /usr/local/include/google/tensorflow/ \
	&& rm -r /usr/local/include/google/tensorflow/third_party/py \
	&& rm -r /usr/local/include/google/tensorflow/third_party/avro