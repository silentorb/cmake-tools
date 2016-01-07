LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE    := ${target}
LOCAL_SRC_FILES :=${target_sources}
LOCAL_LDLIBS    := -llog -landroid${target_system_libraries}
LOCAL_STATIC_LIBRARIES := ${target_libraries}
LOCAL_C_INCLUDES :=${target_includes}

include $(BUILD_SHARED_LIBRARY)

