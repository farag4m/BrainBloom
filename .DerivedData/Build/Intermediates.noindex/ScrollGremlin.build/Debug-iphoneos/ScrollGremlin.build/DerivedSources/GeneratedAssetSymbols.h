#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "Gremlin" asset catalog image resource.
static NSString * const ACImageNameGremlin AC_SWIFT_PRIVATE = @"Gremlin";

/// The "Gremlin_Annoyed" asset catalog image resource.
static NSString * const ACImageNameGremlinAnnoyed AC_SWIFT_PRIVATE = @"Gremlin_Annoyed";

#undef AC_SWIFT_PRIVATE
