#
# Copyright © Olivier Le Doeuff <olivier.ldff@gmail.com>
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# add_qt_mac_app helps you deploy macOs application with Qt.
#

# find the Qt root directory
# todo : support Qt6
if(NOT Qt5Core_DIR)
  find_package(Qt5 COMPONENTS Core REQUIRED)
endif()
get_filename_component(QT_MAC_QT_ROOT "${Qt5Core_DIR}/../../.." ABSOLUTE)
message(STATUS "Found Qt for Mac: ${QT_MAC_QT_ROOT}")

set(QT_MAC_QT_ROOT ${QT_MAC_QT_ROOT})
set(QT_MAC_SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR})

if(NOT QT_MAC_DEPLOY_APP)
  find_program(QT_MAC_DEPLOY_APP macdeployqt PATHS ${QT_MAC_QT_ROOT}/bin)
  if(QT_MAC_DEPLOY_APP)
    message(STATUS "Found macdeployqt : ${QT_MAC_DEPLOY_APP}")
  else()
    message(WARNING "Fail to find macdeployqt. add_qt_mac_app won't have any effect."
      "Make sure macdeployqt is located in your ${Qt5_DIR}/bin")
  endif()
endif()

# This little function lets you set any Xcode specific property.
# This is from iOs CMake Toolchain
function(qt_mac_set_xcode_property TARGET XCODE_PROPERTY XCODE_VALUE)
  set_property(TARGET ${TARGET} PROPERTY XCODE_ATTRIBUTE_${XCODE_PROPERTY} "${XCODE_VALUE}")
endfunction()

include(CMakeParseArguments)

# CMake function that wrap macdeployqt (https://doc.qt.io/qt-5.9/osx-deployment.html)
function(add_qt_mac_app TARGET)

  set(QT_MAC_OPTIONS
    ALL
    DMG
    PKG
    PKG_UPLOAD_SYMBOLS
    NO_STRIP
    NO_PLUGINS
    VERBOSE
    HARDENED_RUNTIME
    APPSTORE_COMPLIANT
    SECURE_TIMESTAMP
  )

  set(QT_MAC_ONE_VALUE_ARG
    QML_DIR
    NAME
    BUNDLE_IDENTIFIER
    VERSION
    SHORT_VERSION
    LONG_VERSION
    CUSTOM_ENTITLEMENTS
    CUSTOM_PLIST
    CODE_SIGN_IDENTITY
    SIGN_FOR_NOTARIZATION_IDENTITY
    TEAM_ID
    PROVISIONING_PROFILE_SPECIFIER
    COPYRIGHT
    APPLICATION_CATEGORY_TYPE
    CATALOG_APPICON
    DMG_FS
    PKG_DISTRIBUTION_METHOD
    ITS_ENCRYPTION_EXPORT_COMPLIANCE_CODE
    MAC_DEPLOY_QT_VERBOSE_LEVEL
  )

  set(QT_MAC_MULTI_VALUE_ARG
    DEPENDS
    RESOURCES
  )

  # parse the function arguments
  cmake_parse_arguments(ARGMAC "${QT_MAC_OPTIONS}" "${QT_MAC_ONE_VALUE_ARG}" "${QT_MAC_MULTI_VALUE_ARG}" ${ARGN})

  set(QT_MAC_VERBOSE ${ARGMAC_VERBOSE})

  if(ARGMAC_NAME)
    set(QT_MAC_NAME ${ARGMAC_NAME})
  else()
    set(QT_MAC_NAME ${TARGET})
    if(QT_MAC_VERBOSE)
      message(STATUS "NAME not provided when calling add_qt_ios_app. Name will be default to ${QT_MAC_NAME}")
    endif()
  endif()

  # Warning if no default BUNDLE_IDENTIFIER is set
  if(ARGMAC_BUNDLE_IDENTIFIER)
    set(QT_MAC_BUNDLE_IDENTIFIER ${ARGMAC_BUNDLE_IDENTIFIER})
  else()
    set(QT_MAC_BUNDLE_IDENTIFIER "com.${CMAKE_PROJECT_NAME}.${TARGET}")
    if(QT_MAC_VERBOSE)
      message(STATUS "BUNDLE_IDENTIFIER not set when calling add_qt_ios_app. "
        "You can fix this by hand in XCode. "
        "The BUNDLE_IDENTIFIER is defaulted to ${ARGMAC_BUNDLE_IDENTIFIER}")
    endif()
  endif()

  set(QT_MAC_VERSION ${ARGMAC_VERSION})
  set(QT_MAC_SHORT_VERSION ${ARGMAC_SHORT_VERSION})
  set(QT_MAC_LONG_VERSION ${ARGMAC_LONG_VERSION})
  set(QT_MAC_APPLICATION_CATEGORY_TYPE ${ARGMAC_APPLICATION_CATEGORY_TYPE} PARENT_SCOPE)
  if(NOT QT_MAC_APPLICATION_CATEGORY_TYPE)
    set(QT_MAC_APPLICATION_CATEGORY_TYPE "public.app-category.developer-tools" PARENT_SCOPE)
    message(STATUS "Default APPLICATION_CATEGORY_TYPE to ${QT_MAC_APPLICATION_CATEGORY_TYPE}")
  endif()

  # Allow user to override QT_MAC_CODE_SIGN_IDENTITY from cache/command line
  if(NOT QT_MAC_CODE_SIGN_IDENTITY)
    set(QT_MAC_CODE_SIGN_IDENTITY ${ARGMAC_CODE_SIGN_IDENTITY})
  endif()
  if("${QT_MAC_CODE_SIGN_IDENTITY}" STREQUAL "")
    set(QT_MAC_CODE_SIGN_IDENTITY "Mac Development")
  endif()

  # Allow user to override QT_MAC_SIGN_FOR_NOTARIZATION_IDENTITY from cache/command line
  if(NOT QT_MAC_SIGN_FOR_NOTARIZATION_IDENTITY)
    set(QT_MAC_SIGN_FOR_NOTARIZATION_IDENTITY ${ARGMAC_SIGN_FOR_NOTARIZATION_IDENTITY})
  endif()

  # Allow user to override QT_MAC_TEAM_ID from cache/command line
  if(NOT QT_MAC_TEAM_ID)
    set(QT_MAC_TEAM_ID ${ARGMAC_TEAM_ID})
  endif()
  if(NOT QT_MAC_TEAM_ID)
    message(WARNING "No TEAM_ID specified. You will need to fix that in xcode if want need to sign the app."
      "TEAM_ID can also be provided by setting QT_MAC_TEAM_ID in command line")
  endif()

  # Allow user to override QT_MAC_PROVISIONING_PROFILE_SPECIFIER from cache/command line
  if(NOT QT_MAC_PROVISIONING_PROFILE_SPECIFIER AND ARGMAC_PROVISIONING_PROFILE_SPECIFIER)
    set(QT_MAC_PROVISIONING_PROFILE_SPECIFIER ${ARGMAC_PROVISIONING_PROFILE_SPECIFIER})
  endif()
  set(QT_MAC_COPYRIGHT ${ARGMAC_COPYRIGHT})
  set(QT_MAC_QML_DIR ${ARGMAC_QML_DIR})
  set(QT_MAC_CATALOG_APPICON ${ARGMAC_CATALOG_APPICON})

  # Allow user to override QT_MAC_DMG from cache/command line
  if(NOT QT_MAC_DMG)
    set(QT_MAC_DMG ${ARGMAC_DMG})
  endif()

  if(NOT QT_MAC_DMG_FS)
    set(QT_MAC_DMG_FS ARGMAC_DMG_FS)
  endif()

  if(QT_MAC_DMG)
    if("${QT_MAC_DMG_FS}" STREQUAL "")
      set(QT_MAC_DMG_FS "HFS+")
      if(QT_MAC_VERBOSE)
        message(STATUS "Default dmg")
      endif()
    endif()
  endif()

  # Allow user to override QT_MAC_PKG from cache/command line
  if(NOT QT_MAC_PKG)
    set(QT_MAC_PKG ${ARGMAC_PKG})
  endif()

  # Allow user to override QT_MAC_PKG from cache/command line
  if(NOT QT_MAC_PKG_UPLOAD_SYMBOLS)
    set(QT_MAC_PKG_UPLOAD_SYMBOLS ${ARGMAC_PKG_UPLOAD_SYMBOLS})
  endif()
  # Allow user to override QT_MAC_PKG_DISTRIBUTION_METHOD from cache/command line
  if(NOT QT_MAC_PKG_DISTRIBUTION_METHOD)
    set(QT_MAC_PKG_DISTRIBUTION_METHOD ${ARGMAC_PKG_DISTRIBUTION_METHOD})
  endif()
  if("${QT_MAC_PKG_DISTRIBUTION_METHOD}" STREQUAL "")
    set(QT_MAC_PKG_DISTRIBUTION_METHOD "app-store")
  endif()

  if(NOT QT_MAC_PKG_DISTRIBUTION_METHOD STREQUAL "app-store")
    message(WARNING "Distribution method ${QT_MAC_PKG_DISTRIBUTION_METHOD} is untested yet.")
  endif()

  # Allow user to override QT_MAC_ITS_ENCRYPTION_EXPORT_COMPLIANCE_CODE from cache/command line
  if(NOT QT_MAC_ITS_ENCRYPTION_EXPORT_COMPLIANCE_CODE)
    set(QT_MAC_ITS_ENCRYPTION_EXPORT_COMPLIANCE_CODE ${ARGMAC_ITS_ENCRYPTION_EXPORT_COMPLIANCE_CODE})
  endif()
  # QT_MAC_ITS_ENCRYPTION_KEYS is used in Info.plist.in
  if(QT_MAC_ITS_ENCRYPTION_EXPORT_COMPLIANCE_CODE)
    set(QT_MAC_ITS_ENCRYPTION_KEYS "<key>ITSAppUsesNonExemptEncryption</key><true/>\n    <key>ITSEncryptionExportComplianceCode</key>\n    <string>${QT_MAC_ITS_ENCRYPTION_EXPORT_COMPLIANCE_CODE}</string>" PARENT_SCOPE)
  else()
    set(QT_MAC_ITS_ENCRYPTIONKEYS "<key>ITSAppUsesNonExemptEncryption</key><false/>" PARENT_SCOPE)
  endif()

  # Warning if no version
  if(NOT ARGMAC_VERSION)
    set(QT_MAC_VERSION ${CMAKE_PROJECT_VERSION})
    if("${QT_MAC_VERSION}" STREQUAL "")
      set(QT_MAC_VERSION "1.0.0")
    endif()
    if(QT_MAC_VERBOSE)
      message(STATUS "VERSION not set when calling add_qt_ios_app. "
        "Default VERSION to ${QT_MAC_VERSION}")
    endif()
  endif()

  # Default value for SHORT_VERSION
  if(NOT QT_MAC_SHORT_VERSION)
    set(QT_MAC_SHORT_VERSION ${QT_MAC_VERSION})
    if(QT_MAC_VERBOSE)
      message(STATUS "SHORT_VERSION not specified, default to ${QT_MAC_SHORT_VERSION}")
    endif()
  endif()

  # Default value for long version
  if(NOT QT_MAC_LONG_VERSION)
    set(QT_MAC_LONG_VERSION ${QT_MAC_VERSION})
    if(QT_MAC_VERBOSE)
      message(STATUS "LONG_VERSION not specified, default to ${QT_MAC_LONG_VERSION}")
    endif()
  endif()

  # Default value for plist file
  set(QT_MAC_CUSTOM_PLIST ${ARGMAC_CUSTOM_PLIST})
  if(NOT QT_MAC_CUSTOM_PLIST)
    set(QT_MAC_CUSTOM_PLIST ${QT_MAC_SOURCE_DIR}/Info.plist.in)
    if(QT_MAC_VERBOSE)
      message(STATUS "Use default plist file: ${QT_MAC_CUSTOM_PLIST}. "
        "It is recommanded for you to copy this file to your project and add missing entries."
        "Then supply the path to the file with CUSTOM_PLIST argument.")
    endif()
  endif()

  set(QT_MAC_CUSTOM_ENTITLEMENTS ${ARGMAC_CUSTOM_ENTITLEMENTS})
  if(NOT QT_MAC_CUSTOM_ENTITLEMENTS)
    set(QT_MAC_CUSTOM_ENTITLEMENTS ${QT_MAC_SOURCE_DIR}/Default.entitlements)
    if(QT_MAC_VERBOSE)
      message(STATUS "Use default entitlements file: ${QT_MAC_CUSTOM_ENTITLEMENTS}. "
        "It is recommanded for you to copy this file to your project and add missing entries."
        "Then supply the path to the file with CUSTOM_ENTITLEMENTS argument.")
    endif()
  endif()

  if(NOT QT_MAC_CATALOG_APPICON)
    set(QT_MAC_CATALOG_APPICON "AppIcon")
    if(QT_MAC_VERBOSE)
      message(STATUS "CATALOG_APPICON not specified, default to ${QT_MAC_CATALOG_APPICON}.")
    endif()
  endif()

  # Called when "cmake --build ." is called
  if(ARGMAC_ALL)
    set(QT_MAC_ALL ALL)
  endif()

  set(QT_MAC_TARGET_APP ${TARGET}App)
  set(QT_MAC_TARGET_DMG ${TARGET}Dmg)
  set(QT_MAC_TARGET_ARCHIVE ${TARGET}Archive)
  set(QT_MAC_TARGET_PKG ${TARGET}Pkg)

  if(QT_MAC_VERBOSE)
    message(STATUS "------ QtMacCMake ${TARGET} Configuration ------")

    message(STATUS "TARGET                              : ${TARGET}")
    message(STATUS "NAME                                : ${QT_MAC_NAME}")
    message(STATUS "BUNDLE_IDENTIFIER                   : ${QT_MAC_BUNDLE_IDENTIFIER}")
    message(STATUS "VERSION                             : ${QT_MAC_VERSION}")
    message(STATUS "SHORT_VERSION                       : ${QT_MAC_SHORT_VERSION}")
    message(STATUS "LONG_VERSION                        : ${QT_MAC_LONG_VERSION}")
    message(STATUS "CUSTOM_PLIST                        : ${QT_MAC_CUSTOM_PLIST}")
    message(STATUS "CUSTOM_ENTITLEMENTS                 : ${QT_MAC_CUSTOM_ENTITLEMENTS}")
    message(STATUS "CODE_SIGN_IDENTITY                  : ${QT_MAC_CODE_SIGN_IDENTITY}")
    message(STATUS "SIGN_FOR_NOTARIZATION_IDENTITY      : ${QT_MAC_SIGN_FOR_NOTARIZATION_IDENTITY}")
    message(STATUS "TEAM_ID                             : ${QT_MAC_TEAM_ID}")
    if(QT_MAC_PROVISIONING_PROFILE_SPECIFIER)
      message(STATUS "PROVISIONING_PROFILE_SPECIFIER      : ${QT_MAC_PROVISIONING_PROFILE_SPECIFIER}")
    endif()
    message(STATUS "APPSTORE_COMPLIANT                  : ${ARGMAC_APPSTORE_COMPLIANT}")
    message(STATUS "SECURE_TIMESTAMP                    : ${ARGMAC_SECURE_TIMESTAMP}")
    message(STATUS "HARDENED_RUNTIME                    : ${ARGMAC_HARDENED_RUNTIME}")
    message(STATUS "QML_DIR                             : ${QT_MAC_QML_DIR}")
    message(STATUS "COPYRIGHT                           : ${QT_MAC_COPYRIGHT}")
    message(STATUS "APPLICATION_CATEGORY_TYPE           : ${QT_MAC_APPLICATION_CATEGORY_TYPE}")
    message(STATUS "CATALOG_APPICON                     : ${QT_MAC_CATALOG_APPICON}")
    message(STATUS "ENCRYPTION_EXPORT_COMPLIANCE_CODE   : ${QT_MAC_ITS_ENCRYPTION_EXPORT_COMPLIANCE_CODE}")
    if(QT_MAC_PKG)
      message(STATUS "PKG_UPLOAD_SYMBOLS                  : ${QT_MAC_PKG_UPLOAD_SYMBOLS}")
      message(STATUS "PKG_DISTRIBUTION_METHOD             : ${QT_MAC_PKG_DISTRIBUTION_METHOD}")
    endif()

    message(STATUS "add_qt_mac_app generated target for ${TARGET}:")
    message(STATUS "QT_MAC_TARGET_APP      : ${QT_MAC_TARGET_APP}")
    if(QT_MAC_DMG)
      message(STATUS "QT_MAC_TARGET_DMG      : ${QT_MAC_TARGET_DMG}")
    endif()
    if(QT_MAC_PKG)
      message(STATUS "QT_MAC_TARGET_ARCHIVE  : ${QT_MAC_TARGET_ARCHIVE}")
      message(STATUS "QT_MAC_TARGET_PKG      : ${QT_MAC_TARGET_PKG}")
    endif()
  endif()

  # Bundle executable.
  if(QT_MAC_VERBOSE)
    message(STATUS "Set property MACOSX_BUNDLE to ${TARGET}")
  endif()
  set_target_properties(${TARGET} PROPERTIES MACOSX_BUNDLE ON)

  if(ARGMAC_RESOURCES)
    foreach(_resources ${ARGMAC_RESOURCES})
      if(QT_MAC_VERBOSE)
        message(STATUS "Add resource to ${TARGET} : ${_resources}")
      endif()
      target_sources(${TARGET} PRIVATE ${_resources})
      set_source_files_properties(${_resources} PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
    endforeach()
  endif()

  if(QT_MAC_CODE_SIGN_IDENTITY)
    qt_mac_set_xcode_property(${TARGET} CODE_SIGN_IDENTITY ${QT_MAC_CODE_SIGN_IDENTITY})
  endif()
  if(QT_MAC_TEAM_ID)
    qt_mac_set_xcode_property(${TARGET} DEVELOPMENT_TEAM ${QT_MAC_TEAM_ID})
    set(CMAKE_XCODE_ATTRIBUTE_DEVELOPMENT_TEAM ${QT_MAC_TEAM_ID} CACHE INTERNAL "" FORCE)
  endif()

  # Set XCode property for automatic code sign if QT_MAC_PROVISIONING_PROFILE_SPECIFIER isn't specified
  if(QT_MAC_PROVISIONING_PROFILE_SPECIFIER)
    qt_mac_set_xcode_property(${TARGET} PROVISIONING_PROFILE_SPECIFIER ${QT_MAC_PROVISIONING_PROFILE_SPECIFIER})
  endif()

  # Set AppIcon Catalog
  if(QT_MAC_CATALOG_APPICON)
    qt_mac_set_xcode_property (${TARGET} ASSETCATALOG_COMPILER_APPICON_NAME ${QT_MAC_CATALOG_APPICON})
  endif()

  # Make sure a publish dialog is set in XCode.
  # If INSTALL_PATH is empty it won't be possible to deploy to App Store
  qt_mac_set_xcode_property(${TARGET} INSTALL_PATH "/Applications")

  # Set CMake variables for plist
  set(MACOSX_BUNDLE_EXECUTABLE_NAME ${QT_MAC_NAME} PARENT_SCOPE)
  set(MACOSX_BUNDLE_INFO_STRING ${QT_MAC_NAME} PARENT_SCOPE)
  set(MACOSX_BUNDLE_GUI_IDENTIFIER ${QT_MAC_BUNDLE_IDENTIFIER} PARENT_SCOPE)
  set(MACOSX_BUNDLE_BUNDLE_NAME ${QT_MAC_NAME} PARENT_SCOPE)
  #set(MACOSX_BUNDLE_ICON_FILE "${PROJECT_SOURCE_DIR} PARENT_SCOPE/platform/ios/Assets.xcassets/AppIcon.appiconset")
  set(MACOSX_BUNDLE_BUNDLE_VERSION ${QT_MAC_VERSION} PARENT_SCOPE)
  set(MACOSX_BUNDLE_SHORT_VERSION_STRING ${QT_MAC_SHORT_VERSION} PARENT_SCOPE)
  set(MACOSX_BUNDLE_LONG_VERSION_STRING ${QT_MAC_LONG_VERSION} PARENT_SCOPE)
  set(MACOSX_BUNDLE_COPYRIGHT ${QT_MAC_COPYRIGHT} PARENT_SCOPE)

  # Set Custom pList
  set_target_properties(${TARGET} PROPERTIES MACOSX_BUNDLE_INFO_PLIST ${QT_MAC_CUSTOM_PLIST})

  # Entitlements
  qt_mac_set_xcode_property(${TARGET} CODE_SIGN_ENTITLEMENTS ${QT_MAC_CUSTOM_ENTITLEMENTS})

  # -no-strip
  if(ARGMAC_NO_STRIP)
    set(QT_MAC_STRIP_OPT -no-strip)
  endif()

  # -no-plugins
  if(ARGMAC_NO_PLUGINS)
    set(QT_MAC_PLUGINS_OPT -no-plugins)
  endif()

  # -appstore-compliant
  if(ARGMAC_APPSTORE_COMPLIANT)
    set(QT_MAC_APPSTORE_COMPLIANT_OPT -appstore-compliant)
  endif()

  # -hardened-runtime
  if(ARGMAC_HARDENED_RUNTIME)
    set(QT_MAC_HARDENED_RUNTIME_OPT -hardened-runtime)
  endif()

  # -timestamp
  if(ARGMAC_SECURE_TIMESTAMP)
    set(QT_MAC_SECURE_TIMESTAMP_OPT -timestamp)
  endif()

  # -qmldir
  if(QT_MAC_QML_DIR)
    set(QT_MAC_QML_DIR_OPT -qmldir=${QT_MAC_QML_DIR})
  endif()

  # -verbose
  if(ARGMAC_MAC_DEPLOY_QT_VERBOSE_LEVEL)
    set(QT_MAC_VERBOSE_OPT -verbose=${ARGMAC_MAC_DEPLOY_QT_VERBOSE_LEVEL})
  endif()

  if(QT_MAC_TEAM_ID)
    # Find private key associated with QT_MAC_TEAM_ID/QT_MAC_CODE_SIGN_IDENTITY
    execute_process(COMMAND security find-identity -v
      OUTPUT_VARIABLE XCODE_CODE_SIGNING_IDENTITIES
      ERROR_QUIET
      OUTPUT_STRIP_TRAILING_WHITESPACE)

    # Find signing certificate to sign libraries deployed by macdeployqt
    string(REGEX MATCH "([0-9A-Z]+) \"[ :.@\"a-zA-Z0-9]*${QT_MAC_CODE_SIGN_IDENTITY}[ :.@\"a-zA-Z0-9]*\\(${QT_MAC_TEAM_ID}\\)\"" CODESIGN_LINE "${XCODE_CODE_SIGNING_IDENTITIES}")

    if("${CMAKE_MATCH_1}" STREQUAL "")
      message(WARNING "Fail to find private key for codesign matching TEAM_ID ${QT_MAC_TEAM_ID} and identity ${QT_MAC_CODE_SIGN_IDENTITY}")
    else()
      set(QT_MAC_CODESIGN_OPT "-codesign=${CMAKE_MATCH_1}")
    endif()

    if(NOT "${QT_MAC_SIGN_FOR_NOTARIZATION_IDENTITY}" STREQUAL "")
      # Find notarization certificate to sign libraries deployed by macdeployqt
      string(REGEX MATCH "([0-9A-Z]+) \"[ :.@\"a-zA-Z0-9]*${QT_MAC_SIGN_FOR_NOTARIZATION_IDENTITY}[ :.@\"a-zA-Z0-9]*\\(${QT_MAC_TEAM_ID}\\)\"" CODESIGN_LINE "${XCODE_CODE_SIGNING_IDENTITIES}")

      if("${CMAKE_MATCH_1}" STREQUAL "")
        message(WARNING "Fail to find private key for notarization signing matching TEAM_ID ${QT_MAC_TEAM_ID} and identity ${QT_MAC_SIGN_FOR_NOTARIZATION_IDENTITY}")
      else()
        set(QT_MAC_SIGN_FOR_NOTARIZATION_OPT "-sign-for-notarization=${CMAKE_MATCH_1}")
      endif()
    else()
      message(WARNING "The app won't be signed for notarization because QT_MAC_SIGN_FOR_NOTARIZATION_IDENTITY isn't set")
    endif()

    # Find signing certificate to create ipa
    string(REGEX MATCH "([0-9A-Z]+) \"[ :.@\"a-zA-Z0-9]*Mac Distribution Installer[ :.@\"a-zA-Z0-9]*\\(${QT_MAC_TEAM_ID}\\)\"" INSTALLER_CERTIFICATE_LINE "${XCODE_CODE_SIGNING_IDENTITIES}")

    if("${CMAKE_MATCH_1}" STREQUAL "")
      string(REGEX MATCH "([0-9A-Z]+) \"[ :.@\"a-zA-Z0-9]*Mac Developer Installer[ :.@\"a-zA-Z0-9]*\\(${QT_MAC_TEAM_ID}\\)\"" INSTALLER_CERTIFICATE_LINE "${XCODE_CODE_SIGNING_IDENTITIES}")
    endif()

    if("${CMAKE_MATCH_1}" STREQUAL "")
      message(WARNING "Fail to find private key for installerSigningCertificate matching TEAM_ID ${QT_MAC_TEAM_ID}. Pkg export might fail.")
    else()
      set(QT_MAC_INSTALLER_SIGNING_CERTIFICATE ${CMAKE_MATCH_1})
    endif()
  endif()

  set(QT_MAC_OPT
    ${QT_MAC_QML_DIR_OPT}
    ${QT_MAC_PLUGINS_OPT}
    ${QT_MAC_STRIP_OPT}
    ${QT_MAC_VERBOSE_OPT}
    ${QT_MAC_APPSTORE_COMPLIANT_OPT}
    ${QT_MAC_HARDENED_RUNTIME_OPT}
    ${QT_MAC_SECURE_TIMESTAMP_OPT}
    ${QT_MAC_CODESIGN_OPT}
    ${QT_MAC_SIGN_FOR_NOTARIZATION_OPT}
  )

  # Call macdeployqt
  add_custom_target(${QT_MAC_TARGET_APP}
    ${QT_MAC_ALL}
    DEPENDS ${TARGET} ${ARGMAC_DEPENDS}
    WORKING_DIRECTORY $<TARGET_BUNDLE_DIR:${TARGET}>/..
    COMMAND ${QT_MAC_DEPLOY_APP}
      $<TARGET_FILE_NAME:${TARGET}>.app
      ${QT_MAC_OPT}

    COMMENT "Deploy app with ${QT_MAC_DEPLOY_APP}"
  )

  if(QT_MAC_DMG)

    add_custom_target(${QT_MAC_TARGET_DMG}
      ${QT_MAC_ALL}
      DEPENDS ${TARGET} ${ARGMAC_DEPENDS}
      WORKING_DIRECTORY $<TARGET_BUNDLE_DIR:${TARGET}>/..
      # Make sure previous dmg file is removed
      COMMAND ${CMAKE_COMMAND} -E rm -f $<TARGET_FILE_NAME:${TARGET}>.dmg
      COMMAND ${QT_MAC_DEPLOY_APP}
        $<TARGET_FILE_NAME:${TARGET}>.app
        ${QT_MAC_OPT}
        -dmg

      COMMENT "Deploy dmg with ${QT_MAC_DEPLOY_APP}"
    )

  endif()

  if(QT_MAC_PKG)

    # Generate archive
    add_custom_target(${QT_MAC_TARGET_ARCHIVE}
      ${QT_MAC_ALL}
      DEPENDS ${TARGET}
      COMMAND xcodebuild
        -project ${PROJECT_BINARY_DIR}/${CMAKE_PROJECT_NAME}.xcodeproj
        -scheme ${TARGET}
        -archivePath $<TARGET_BUNDLE_DIR:${TARGET}>/../$<TARGET_FILE_NAME:${TARGET}>.xcarchive
        archive
    )

    # Generate PKG
    if(QT_MAC_PROVISIONING_PROFILE_SPECIFIER)
      set(QT_MAC_EXPORT_SIGNING_TYPE "manual")
    else()
      set(QT_MAC_EXPORT_SIGNING_TYPE "automatic")
    endif()

    set(QT_MAC_PROVISIONING_PROFILES_KEY
      "<key>provisioningProfiles</key>\n    <dict>\n        <key>${QT_MAC_BUNDLE_IDENTIFIER}</key>\n        <string>${QT_MAC_PROVISIONING_PROFILE_SPECIFIER}</string>\n     </dict>"
    )

    if(QT_MAC_PKG_UPLOAD_SYMBOLS)
      set(QT_MAC_PKG_UPLOAD_SYMBOLS_KEY "<key>uploadSymbols</key><true/>")
    else()
      set(QT_MAC_PKG_UPLOAD_SYMBOLS_KEY "")
    endif()

    if(QT_MAC_INSTALLER_SIGNING_CERTIFICATE)
      set(QT_MAC_INSTALLER_SIGNING_CERTIFICATE_KEY "<key>installerSigningCertificate</key>\n    <string>${QT_MAC_INSTALLER_SIGNING_CERTIFICATE}</string>")
    endif()

    set(QT_MAC_EXPORT_OPTIONS_FILE ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}ExportOptions.plist)
    configure_file(${QT_MAC_SOURCE_DIR}/ExportOptions.plist.in ${QT_MAC_EXPORT_OPTIONS_FILE})

    add_custom_target(${QT_MAC_TARGET_PKG}
      ${QT_MAC_ALL}
      DEPENDS ${QT_MAC_TARGET_ARCHIVE}
      COMMAND xcodebuild -exportArchive
      -archivePath $<TARGET_BUNDLE_DIR:${TARGET}>/../$<TARGET_FILE_NAME:${TARGET}>.xcarchive
      -exportOptionsPlist ${QT_MAC_EXPORT_OPTIONS_FILE}
      -exportPath $<TARGET_BUNDLE_DIR:${TARGET}>/..
    )

  endif()

endfunction()
