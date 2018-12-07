#include <string>

#ifndef DYLIBBUNDLER_CONST
#define DYLIBBUNDLER_CONST

const std::string install_name_tool =
#ifndef OSXCROSS_HOST
"install_name_tool";
#else
OSXCROSS_HOST "-install_name_tool";
#endif

const std::string otool =
#ifndef OSXCROSS_HOST
"otool";
#else
OSXCROSS_HOST "-otool";
#endif

#endif
