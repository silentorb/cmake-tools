#pragma once

#define MYTHIC_STRING2(x) #x
#define MYTHIC_STRING(x) MYTHIC_STRING2(x)

#if defined (_MSC_VER)
#if defined(EXPORTING_DLL)
#define MANUAL_SYMBOL_EXPORTING
#define MYTHIC_EXPORT __declspec(dllexport)
#else
#define MYTHIC_EXPORT __declspec(dllimport)
#endif /* MyLibrary_EXPORTS */
#else /* defined (_WIN32) */
#define MYTHIC_EXPORT
#endif

class no_copy {
public:
    no_copy(no_copy const &) = delete;
    no_copy &operator=(no_copy const &) = delete;

    no_copy() { }

    no_copy(no_copy &&) { }
};

class no_copy_minimal {
public:
    no_copy_minimal &operator=(no_copy const &) = delete;
};

inline void Assert(bool expression) {
  if (!expression)
    throw "";
}