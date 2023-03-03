find_library(Avahi_COMMON_LIBRARY NAMES avahi-common)
find_library(Avahi_CLIENT_LIBRARY NAMES avahi-client)
find_path(Avahi_CLIENT_INCLUDE_DIRS avahi-client/publish.h)

if (Avahi_COMMON_LIBRARY AND Avahi_CLIENT_LIBRARY AND Avahi_CLIENT_INCLUDE_DIRS)
  set(Avahi_FOUND ON)
  set(Avahi_COMMON_FOUND ON)
  set(Avahi_CLIENT_FOUND ON)

  if (NOT TARGET "Avahi::common")
    add_library("Avahi::common" UNKNOWN IMPORTED)
    set_target_properties("Avahi::common"
      PROPERTIES
      INTERFACE_INCLUDE_DIRECTORIES "${Avahi_CLIENT_INCLUDE_DIRS}"
      IMPORTED_LOCATION "${Avahi_COMMON_LIBRARY}"
    )

  endif()

  if(NOT TARGET "Avahi::client")
    add_library("Avahi::client" UNKNOWN IMPORTED)
    set_target_properties("Avahi::client"
      PROPERTIES
      INTERFACE_INCLUDE_DIRECTORIES "${Avahi_CLIENT_INCLUDE_DIRS}"
      IMPORTED_LOCATION "${Avahi_CLIENT_LIBRARY}"
      INTERFACE_LINK_LIBRARIES "Avahi::common"
    )
    get_filename_component(AVAHI_LIB_DIR "${Avahi_COMMON_LIBRARY}" DIRECTORY CACHE)

  endif()
endif()

if(Avahi_FOUND)
  set(Avahi_LIBRARIES ${Avahi_COMMON_LIBRARY} ${Avahi_CLIENT_LIBRARY})
  set(Avahi_INCLUDE_DIRS ${Avahi_CLIENT_INCLUDE_DIRS})
endif()
