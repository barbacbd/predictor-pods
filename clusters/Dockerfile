# MIT License
#
# Copyright (c) 2022 Brent Barbachem
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

from fedora:latest
MAINTAINER "barbacbd@dukes.jmu.edu"

# Update all packages
RUN dnf update -y

RUN dnf install -y \
    python3-devel \
    python3-pip \
    git \
    emacs \
    vim \
    gcc \
    gcc-c++

# upgrade pip
RUN python3 -m pip install pip --upgrade

# install the latest package for cluster-crit
RUN python3 -m pip install jenkspy kmeans1d numpy pandas scipy sklearn

# copy over the executable that will run the Internal Criteria algorithm(s)
COPY ./Clusters /Clusters

# Expected use:
# Clusters {file} -a K_MEANS --min_k 2 --max_k 50
CMD ["/Clusters"]