#pragma once

#if defined (_MSC_VER)
#if defined(EXPORTING_DLL)
#define MYTHIC_EXPORT __declspec(dllexport)
#else
#define MYTHIC_EXPORT __declspec(dllimport)
#endif /* MyLibrary_EXPORTS */
#else /* defined (_WIN32) */
#define MYTHIC_EXPORT
#endif