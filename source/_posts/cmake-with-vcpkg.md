---
title: cmake with vcpkg
date: 2024-06-14 18:36:23
tags:
---
vcpkg 可以非常方便的管理c++的库，配合cmake，整个使用会比较轻松，可以实现类似maven之于java的效果。这里做一下记录

##  vcpkg 安装

```
git clone https://github.com/microsoft/vcpkg

./vcpkg/bootstrap-vcpkg.sh

# 安装成功后，配置vcpkg的路径到path上，方便使用vcpkg安装
# 在非x86环境下需要配置这个环境变量
export VCPKG_FORCE_SYSTEM_BINARIES=1
PATH=$HOME/vcpkg/:$PATH

cmake -B ./build/ -S . "-DCMAKE_TOOLCHAIN_FILE=/home/lima.linux/vcpkg/scripts/buildsystems/vcpkg.cmake"

cmake -B ./build/

# 也可以直接在cmakelist.txt 文件中主动制定CMAKE_TOOLCHAIN_FILE的内容  `# include(/home/lima.linux/vcpkg/scripts/buildsystems/vcpkg.cmake)`

```

demo cmakelists.txt 


```

cmake_minimum_required(VERSION 3.8)
project(c C CXX)

# include(/home/lima.linux/vcpkg/scripts/buildsystems/vcpkg.cmake)

find_package(Threads REQUIRED)

option(protobuf_MODULE_COMPATIBLE TRUE)
find_package(Protobuf REQUIRED)
message(STATUS "Using protobuf ${Protobuf_VERSION}")

set(_PROTOBUF_LIBPROTOBUF protobuf::libprotobuf)
set(_REFLECTION gRPC::grpc++_reflection)
find_program(_PROTOBUF_PROTOC protoc)

  # Find gRPC installation
  # Looks for gRPCConfig.cmake file installed by gRPC's cmake installation.
# find_package(PkgConfig REQUIRED)
# pkg_check_modules(grpc REQUIRED grpc>=1.22.0)
find_package(GRPC REQUIRED)
message(STATUS "Using gRPC ${gRPC_VERSION}")

set(_GRPC_GRPCPP gRPC::grpc++)
find_program(_GRPC_CPP_PLUGIN_EXECUTABLE grpc_cpp_plugin)

get_filename_component(hw_proto "./protos/helloworld.proto" ABSOLUTE)
get_filename_component(hw_proto_path "${hw_proto}" PATH)

message("${CMAKE_CURRENT_BINARY_DIR}, ${_PROTOBUF_PROTOC} , ${hw_proto} , ")

set(hw_proto_srcs "${CMAKE_CURRENT_BINARY_DIR}/helloworld.pb.cc")
set(hw_proto_hdrs "${CMAKE_CURRENT_BINARY_DIR}/helloworld.pb.h")
set(hw_grpc_srcs "${CMAKE_CURRENT_BINARY_DIR}/helloworld.grpc.pb.cc")
set(hw_grpc_hdrs "${CMAKE_CURRENT_BINARY_DIR}/helloworld.grpc.pb.h")


add_custom_command(
    OUTPUT "${hw_proto_srcs}" "${hw_proto_hdrs}" "${hw_grpc_srcs}" "${hw_grpc_hdrs}"
      COMMAND ${_PROTOBUF_PROTOC}
      ARGS --grpc_out "${CMAKE_CURRENT_BINARY_DIR}"
        --cpp_out "${CMAKE_CURRENT_BINARY_DIR}"
        -I "${hw_proto_path}"
        --plugin=protoc-gen-grpc="${_GRPC_CPP_PLUGIN_EXECUTABLE}"
        "${hw_proto}"
      DEPENDS "${hw_proto}"
)

# message("${hw_proto_path} ${_GRPC_CPP_PLUGIN_EXECUTABLE} ${hw_proto_srcs} , ${hw_proto_hdrs}, ${hw_grpc_srcs}, ${hw_grpc_hdrs}")

include_directories("${CMAKE_CURRENT_BINARY_DIR}")

add_library(hw_grpc_proto
  ${hw_grpc_srcs}
  ${hw_grpc_hdrs}
  ${hw_proto_srcs}
  ${hw_proto_hdrs})


target_link_libraries(hw_grpc_proto
  absl::check
  ${_REFLECTION}
  ${_GRPC_GRPCPP}
  ${_PROTOBUF_LIBPROTOBUF})

# Targets greeter_[async_](client|server)
foreach(_target
  greeter_client greeter_server
  # greeter_callback_client greeter_callback_server
  # greeter_async_client greeter_async_client2 greeter_async_server
  )
  add_executable(${_target} "${_target}.cc")
  target_link_libraries(${_target}
    hw_grpc_proto
    absl::check
    absl::flags
    absl::flags_parse
    absl::log
    ${_REFLECTION}
    ${_GRPC_GRPCPP}
    ${_PROTOBUF_LIBPROTOBUF})
endforeach()

```
vcpkg.json 


```
{
    "name" : "c",
    "version" : "0.1.0",
    "dependencies" : [  {
      "name" : "grpc",
      "version>=" : "1.51.1#2"
    } ,
    {
      "name" : "protobuf",
      "version>=" : "3.21.12#1"
    }],
    "builtin-baseline" : "9765877106f7c179995e8010bb7427a865a6bd1d"
}
```




