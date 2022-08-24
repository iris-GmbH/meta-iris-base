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
  II. Contributing   
 III. Misc   


I. Adding the meta-iris-base layer to your build
=================================================

Run 'bitbake-layers add-layer meta-iris-base'

II. Contributing
================

After developing, the code has to be transformed into patches and merged into one of the yocto layer repositories (iris-kas, meta-iris, meta-iris-base).   
Following formal rules and points have to be respected:   
1. First, create a new (local) branch in that repository which is intended to be changed [and later used by yocto recipes (e.g. uboot-imx for bootloader code)].    
2. Before implementing code changes, all other patches which have been committed so far (e.g. in meta-iris-base) have to be applied onto the newly created branch ("git am *.patch").   
   1. If there is more than one patch folder, it is important to apply the generic/common patches first and after them the machine specific ones.   
3. For patches, the "Single Source of Truth" rule is applied: Only the patches in the Yocto Layer repositories (e.g. meta-iris-base) are valid!    
4. The commit to be added as a patch has to be *signed off*:   
   1. The patch bases onto a commit in a repository.   
   2. This commit has to be done as "signed off":   
   3. On command line, use "git commit --signoff [...]"   
   4. With SmartGit, use the context menu for "commit..." and additionally choose the box "Add 'Signed-off-by' signature"   
5. Summarize the commits in a reasonable way (see also iris coding guidelines) and resort them.   
6. For creation of a patch, the local branch in the repository from which the patch is created ("git format-patch") doesn't have to be pushed.   
7. The new patch has to be added after all older patches in the meta-iris-base repository.   
8. After committing the new patches, fill in the changelog.md and commit as last/latest.   
9. On the committed branch in the meta-iris-base repository, a pull request has to be created.   
10. For a successful review, an additional pipeline run (Jenkins, gitlab etc.) has to be closed successfully.   
11. Test all those hardware platforms for which the firmware contains changes.   


III. Misc
========

This repository contains the configuration, recipes and modifications for building the iris custom Linux distribution (the irma6-base image), minus our proprietary platform application.

The Maintainers of this layer focus on supporting the current Yocto LTS release.
However, feel free to add support for other layers via pull requests.
In the future we plan to include all currently supported Yocto releases in a CI workflow.
