#
# This file is part of the GROMACS molecular simulation package.
#
# Copyright (c) 2009-2011, by the VOTCA Development Team (http://www.votca.org).
# Copyright (c) 2012,2013,2014, by the GROMACS development team, led by
# Mark Abraham, David van der Spoel, Berk Hess, and Erik Lindahl,
# and including many others, as listed in the AUTHORS file in the
# top-level source directory and at http://www.gromacs.org.
#
# GROMACS is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public License
# as published by the Free Software Foundation; either version 2.1
# of the License, or (at your option) any later version.
#
# GROMACS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with GROMACS; if not, see
# http://www.gnu.org/licenses, or write to the Free Software Foundation,
# Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA.
#
# If you want to redistribute modifications to GROMACS, please
# consider that scientific software is very special. Version
# control is crucial - bugs must be traceable. We will be happy to
# consider code for inclusion in the official distribution, but
# derived work must not be called official GROMACS. Details are found
# in the README & COPYING files - if they are missing, get the
# official version at http://www.gromacs.org.
#
# To help us fund GROMACS development, we humbly ask that you cite
# the research papers on the package. Check out http://www.gromacs.org.

# - Finds parts of GROMACS
# Find the native GROMACS components headers and libraries.
#
# If no components are requested, this macro searches for libgromacs,
# and libgmx in that order, including double and MPI variants of the
# libraries, and uses the first component found.  The order of
# precendence of the variants is MPI+double, MPI, double, and finally
# the vanilla library.
#
# If components are requested, they are filtered against the above
# white-list of components.
#
#  GROMACS_INCLUDE_DIRS   - where to find GROMACS headers.
#  GROMACS_LIBRARIES      - List of libraries when used by GROMACS.
#  GROMACS_FOUND          - True if all GROMACS components were found.
#  GROMACS_DEFINITIONS    - Extra definies needed by GROMACS
#  GROMACS_PKG            - The name of the pkg-config package needed
#  GROMACS_VERSION        - GROMACS lib interface version
#  GROMACS_MAJOR_VERSION  - GROMACS lib interface major version
#  GROMACS_MINOR_VERSION  - GROMACS lib interface minor version
#  GROMACS_PATCH_LEVEL    - GROMACS lib interface patch level
#  GROMACS_VERSION_STRING - GROMACS lib interface version string (e.g. "4.5.3")
#

########## To add Path of CMAKE_PREFIX_PATH in PKG_CONFIG_PATH ###########
include(GNUInstallDirs)
find_package(PkgConfig)
foreach(_dir $ENV{CMAKE_PREFIX_PATH})
  # In GROMACS-4.5 and 4.6
  if(IS_DIRECTORY "${_dir}/lib/pkgconfig/")
    set(ENV{PKG_CONFIG_PATH}
      "$ENV{PKG_CONFIG_PATH}:${_dir}/lib/pkgconfig")
  endif()
  # In GROMACS 5.0 and later
  if(IS_DIRECTORY "${_dir}/${CMAKE_INSTALL_LIBDIR}/pkgconfig/")
    set(ENV{PKG_CONFIG_PATH}
      "$ENV{PKG_CONFIG_PATH}:${_dir}/${CMAKE_INSTALL_LIBDIR}/pkgconfig")
  endif()
endforeach()
#########################################################################

####### To add path of GROMACS if manually given by user ################
if(DEFINED GMX_PATH)
  if(IS_DIRECTORY "${GMX_PATH}/lib/pkgconfig/")
    set(ENV{PKG_CONFIG_PATH}
      "$ENV{PKG_CONFIG_PATH}:${GMX_PATH}/lib/pkgconfig")
  endif()
  if(IS_DIRECTORY "${GMX_PATH}/${CMAKE_INSTALL_LIBDIR}/pkgconfig/")
    set(ENV{PKG_CONFIG_PATH}
      "$ENV{PKG_CONFIG_PATH}:${GMX_PATH}/${CMAKE_INSTALL_LIBDIR}/pkgconfig")
  endif()
endif()
#########################################################################

# Generate the white-list of GROMACS supported components.
#
# Prefer MPI, double variants over vanilla libraries.  We don't use
# more efficient list() macros here because we need a specific order.
set(libs gromacs gmx)
set(suffixes_mpi _mpi "")
if(GMX_DOUBLE)
  set(suffixes_d _d)
else()
  set(suffixes_d _d "")
endif()
foreach(_suffix_mpi IN LISTS suffixes_mpi)
  foreach(_suffix_d IN LISTS suffixes_d)
    list(APPEND suffixes "${_suffix_mpi}${_suffix_d}")
  endforeach()
endforeach()
foreach(_lib IN LISTS libs)
  foreach(_suffix IN LISTS suffixes)
    list(APPEND GROMACS_COMPONENTS_TO_SEARCH "${_lib}${_suffix}")
  endforeach()
endforeach()

# Use find_package COMPONENTS if provided, filtering by valid
# components.  Assume we only want one of each component.
list(LENGTH GROMACS_FIND_COMPONENTS GROMACS_NUM_COMPONENTS_WANTED)
if(${GROMACS_NUM_COMPONENTS_WANTED})
  list(FILTER GROMACS_COMPONENTS_TO_SEARCH
    INCLUDE REGEX
    string(REPLACE ; | "(${GROMACS_VALID_LIBRARY_NAMES})"))
  list(LENGTH GROMACS_COMPONENTS_TO_SEARCH GROMACS_NUM_COMPONENTS_VALID)
  if(${GROMACS_NUM_COMPONENTS_VALID LESS 1)
    message(FATAL_ERROR "\
Requested GROMACS component(s) not yet implemented.
Requested component(s): ${GROMACS_FIND_COMPONENTS}
Allowed: ${GROMACS_LIBRARY_NAMES}")
  endif()
endif()

# Search for first available package.
foreach(GROMACS_LIB_NAME IN LISTS GROMACS_COMPONENTS_TO_SEARCH)
  set(GROMACS_PKG "lib${GROMACS_LIB_NAME}")
  pkg_check_modules(PC_GROMACS "${GROMACS_PKG}")
  find_library(GROMACS_LIBRARY
    NAMES ${GROMACS_LIB_NAME}
    HINTS ${PC_GROMACS_LIBRARY_DIRS} ${PC_GROMACS_STATIC_LIBRARY_DIRS})
  if(PC_GROMACS_FOUND)
    break()
  endif()
endforeach()
if(NOT PC_GROMACS_FOUND)
  message(FATAL_ERROR "Could not find any of the GROMACS libraries")
endif()

# Definition flags
if(GMX_DOUBLE)
  list(APPEND GMX_DEFS "-DGMX_DOUBLE")
endif()
if(PC_GROMACS_CFLAGS_OTHER)
  foreach(DEF ${PC_GROMACS_CFLAGS_OTHER})
    if(${DEF} MATCHES "^-D")
      list(APPEND GMX_DEFS ${DEF})
    endif()
  endforeach()
  list(REMOVE_DUPLICATES GMX_DEFS)
endif()
set(GROMACS_DEFINITIONS "${GMX_DEFS}" CACHE STRING "extra GROMACS definitions")

# GROMACS version
set(GROMACS_VERSION "${PC_GROMACS_VERSION}")
string(REPLACE "." ";" VERSION_LIST ${GROMACS_VERSION})
list(GET VERSION_LIST 0 GROMACS_MAJOR_VERSION)
list(GET VERSION_LIST 1 GROMACS_MINOR_VERSION)
list(LENGTH VERSION_LIST LEN_GMX_VER_LIST)
# Not available after 2016 versions
if(${LEN_GMX_VER_LIST} MATCHES "3")
  list(GET VERSION_LIST 2 GROMACS_PATCH_LEVEL)
endif()
set(GROMACS_VERSION_STRING "${GROMACS_VERSION}")

# GROMACS include directories
if("${GROMACS_PKG}" MATCHES "libgmx")
  if(${GROMACS_VERSION} VERSION_GREATER "4.5.0"
      OR ${GROMACS_VERSION} VERSION_EQUAL "4.5.0")
    find_path(GROMACS_INCLUDE_DIR gromacs/tpxio.h
      HINTS ${PC_GROMACS_INCLUDE_DIRS})
  elseif(${GROMACS_VERSION} VERSION_GREATER "4.6.0"
      OR ${GROMACS_VERSION} VERSION_EQUAL "4.6.0")
    find_path(GROMACS_INCLUDE_DIR gromacs/tpxio.h
      HINTS ${PC_GROMACS_INCLUDE_DIRS})
  endif()
elseif("${GROMACS_PKG}" MATCHES "libgromacs"
    OR "${GROMACS_PKG}" MATCHES "libgromacs_mpi")
  find_path(GROMACS_INCLUDE_DIR gromacs/version.h
    HINTS ${PC_GROMACS_INCLUDE_DIRS})
endif()

set(GROMACS_LIBRARIES "${GROMACS_LIBRARY}")
set(GROMACS_INCLUDE_DIRS ${GROMACS_INCLUDE_DIR})

include(FindPackageHandleStandardArgs)
# handle the QUIETLY and REQUIRED arguments and set GROMACS_FOUND to TRUE
# if all listed variables are TRUE
find_package_handle_standard_args(GROMACS DEFAULT_MSG GROMACS_LIBRARY
GROMACS_INCLUDE_DIR)

mark_as_advanced(GROMACS_INCLUDE_DIR GROMACS_LIBRARY
GROMACS_DEFINITIONS GROMACS_PKG GROMACS_VERSION GROMACS_DEP_LIBRARIES)
