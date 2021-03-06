cmake_minimum_required (VERSION 2.8)
project(Rocprop)

load_cache(../)
IF(NOT ENABLE_MPI)
  add_definitions( -DDUMMY_MPI )
ELSE()
  FIND_PACKAGE(MPI REQUIRED)
  add_definitions( -DMPICH_IGNORE_CXX_SEEK )
#  IF(MPI_CXX_COMPILER)
#    set (CMAKE_CXX_COMPILER ${MPI_CXX_COMPILER})
#  ENDIF(MPI_CXX_COMPILER)
ENDIF()

#INCLUDE(CTest)
find_path(ROCCOM_INC roccom.h HINTS ../Roccom/include) 

set (LIB_SRCS src/Propagation_3.C src/MarkerParticles_3.C src/FaceOffset_3.C src/Rocprop.C
              src/NuLaplacian.C src/cons_diff.C src/AnisotropicSmoothing.C src/quadric_analysis.C 
              src/detect_features.C)
set (TEST_SRCS test/proptest.C test/mptest.C test/compare_normals.C test/rotate.C 
               test/advectest.C test/detectfeas.C test/PointPropagate.C)
set (ALL_SRCS ${LIB_SRCS} ${TEST_SRCS})

set_source_files_properties(${ALL_SRCS} PROPERTIES COMPILE_FLAGS "-fPIC" )
#set(TEST_SRCS src/MANTest.C)

# rpath settings
SET(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib")
SET(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

include_directories(include ${ROCCOM_INC})


IF(NOT BUILD_STATIC)
  add_library(Rocprop SHARED ${LIB_SRCS})
ELSE()
  add_library(Rocprop STATIC ${LIB_SRCS})
  add_definitions( -DSTATIC_LINK )
ENDIF()
target_link_libraries(Rocprop Rocsurf Rocmap Rocblas Roccom)

add_executable(proptest test/proptest.C)
add_executable(mptest test/mptest.C)
add_executable(compare_normals test/compare_normals.C)
add_executable(rotate test/rotate.C)
add_executable(advectest test/advectest.C test/PointPropagate.C)
add_executable(detectfeas test/detectfeas.C)
target_link_libraries(proptest Rocprop)
target_link_libraries(mptest Rocprop)
target_link_libraries(compare_normals Rocprop)
target_link_libraries(rotate Rocprop)
target_link_libraries(advectest Rocprop)
target_link_libraries(detectfeas Rocprop)

#ADD_TEST(RunAllTests ${EXECUTABLE_OUTPUT_PATH}/testx testresults.txt)
#ADD_TEST(TestObject:ValidHandle ${TEST_RESULTS} TestObject:ValidHandle testresults.txt)
#ADD_TEST(TestObject:Exists ${TEST_RESULTS} TestObject:Exists testresults.txt)

INSTALL(TARGETS Rocprop RUNTIME DESTINATION bin LIBRARY DESTINATION lib ARCHIVE DESTINATION lib)
