LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE    := ${target}
LOCAL_SRC_FILES :=${target_sources}
LOCAL_STATIC_LIBRARIES := ${target_libraries}
LOCAL_C_INCLUDES :=${target_includes}
LOCAL_CFLAGS := ${target_defines}

include $(BUILD_STATIC_LIBRARY)

