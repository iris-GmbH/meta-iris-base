This README file contains information on the contents of the meta-iris-base layer.

Please see the corresponding sections below for details.

Dependencies
============
 -

Patches
=======

Please submit any patches against the meta-iris-base layer via github pull requests

Maintainers: 
- Jasper Orschulko <Jasper [dot] Orschulko [at] iris-sensing.com>
- Erik Schumacher <Erik [dot] Schumacher [at] iris-sensing.com>

Table of Contents
=================

   I. Adding the meta-iris-base layer to your build
  II. Misc


I. Adding the meta-iris-base layer to your build
=================================================

Run 'bitbake-layers add-layer meta-iris-base'

III. Misc
========

This repository contains the configuration, recipes and modifications for building the iris custom Linux distribution (the irma6-base image), minus our proprietary platform application.

The Maintainers of this layer focus on supporting the current Yocto LTS release.
However, feel free to add support for other layers via pull requests.
In the future we plan to include all currently supported Yocto releases in a CI workflow.
