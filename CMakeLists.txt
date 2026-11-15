# CMakeLists.txt 맨 위에 추가
cmake_minimum_required(VERSION 3.10)
project(wxshadow C)

# KernelPatch의 CMake 모듈 경로 추가 (KP_DIR 변수 활용)
list(APPEND CMAKE_MODULE_PATH "${KP_DIR}/tools/cmake")
# 또는 KernelPatch 내 .cmake 파일이 있는 정확한 경로


add_kpm_module(wxshadow
    wxshadow.c
    wxshadow_pgtable.c
    wxshadow_handlers.c
    wxshadow_bp.c
    wxshadow_scan.c
)

# Build client tool (userspace)
add_executable(wxshadow_client wxshadow_client.c)
target_link_options(wxshadow_client PRIVATE -static -s)
