cmake_minimum_required(VERSION 3.0)
project (napi NONE)

set(NAPI_VERSION_MAJOR 2)
set(NAPI_VERSION_MINOR 0)
set(NAPI_VERSION_SUB 0)

if (NOT NAPI_INSTALL_PREFIX)
    set(NAPI_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX})
endif()

configure_file(
    napi.sh.in
    napi.sh
    @ONLY
)

configure_file(
    subotage.sh.in
    subotage.sh
    @ONLY
)

configure_file(
    libs/libnapi_version.sh.in
    libnapi_version.sh
    @ONLY
)

# installation of the main entry point
install(FILES
    "${PROJECT_BINARY_DIR}/napi.sh"
    "${PROJECT_BINARY_DIR}/subotage.sh"
    DESTINATION bin
    PERMISSIONS
    OWNER_READ OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
)

# install libraries
install(DIRECTORY libs/
    DESTINATION lib/napi
    PATTERN "libs/*sh"
    PERMISSIONS
        OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ
)

# rule for installing the generated version library
install(FILES "${PROJECT_BINARY_DIR}/libnapi_version.sh"
    DESTINATION lib/napi
    PERMISSIONS
        OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ
)

# install actions
install(DIRECTORY actions/
    DESTINATION lib/napi/actions
    PATTERN "libs/*sh"
    PERMISSIONS
        OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ
)

