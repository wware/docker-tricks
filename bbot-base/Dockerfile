# docker build -t bbot_base .

# Set up the virtualenv here, abandon python-dependencies directory later
FROM centos:7.5.1804 as intermediate

RUN yum install -y python-virtualenv python-setuptools gcc gcc-c++ mysql-devel \
    libxml2 libxml2-devel libxslt libxslt-devel
RUN virtualenv /python-sandbox ; \
    source /python-sandbox/bin/activate; \
    pip install --upgrade pip ; \
    pip install --upgrade setuptools
COPY python-dependencies /python-dependencies
RUN source /python-sandbox/bin/activate; \
    pip install -r /python-dependencies/requirements.txt --no-index --find-links /python-dependencies

# Copy the virtualenv but jettison python-dependencies
FROM centos:7.5.1804

RUN yum install -y epel-release
RUN yum update -y
RUN yum install -y ncdu

# Development Tools group is broken on CentOS, do them individually
RUN yum install -y openssh-server sudo ecdsautils python-virtualenv mysql mlocate php \
    byacc cscope ctags cvs diffstat gcc gcc-c++ strace doxygen flex gettext indent \
    curl-devel expat-devel gettext-devel openssl-devel zlib-devel perl-ExtUtils-MakeMaker \
    intltool libtool patch patchutils rcs redhat-rpm-config rpm-build swig systemtap \
    ruby ruby-devel perl perl-Digest-MD5 mysql mysql-devel python-wheel python-devel \
    python-setuptools vim telnet centos-release-scl ant bison \
    llvm-toolset-7-clang llvm-toolset-7-cmake-data ncurses-devel \
    java-1.8.0-openjdk java-1.8.0-openjdk-devel

COPY --from=intermediate /python-sandbox /python-sandbox
COPY test.sh /
