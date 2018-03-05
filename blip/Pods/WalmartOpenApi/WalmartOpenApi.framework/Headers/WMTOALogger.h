#import <Foundation/Foundation.h>

/**
 * NOTE: This class is auto generated by the swagger code generator program.
 * https://github.com/swagger-api/swagger-codegen
 * Do not edit the class manually.
 */

#ifndef WMTOADebugLogResponse
#define WMTOADebugLogResponse(response, responseObject,request, error) [[WMTOALogger sharedLogger] logResponse:response responseObject:responseObject request:request error:error];
#endif

/**
 * Log debug message macro
 */
#ifndef WMTOADebugLog
#define WMTOADebugLog(format, ...) [[WMTOALogger sharedLogger] debugLog:[NSString stringWithFormat:@"%s", __PRETTY_FUNCTION__] message: format, ##__VA_ARGS__];
#endif

@interface WMTOALogger : NSObject

+(instancetype)sharedLogger;

/**
 * Enabled switch, default NO - default set by WMTOAConfiguration debug property
 */
@property (nonatomic, assign, getter=isEnabled) BOOL enabled;

/**
 * Debug file location, default log in console
 */
@property (nonatomic, strong) NSString *loggingFile;

/**
 * Log file handler, this property is used by sdk internally.
 */
@property (nonatomic, strong, readonly) NSFileHandle *loggingFileHandler;

/**
 * Log debug message
 */
-(void)debugLog:(NSString *)method message:(NSString *)format, ...;

/**
 * Logs request and response
 *
 * @param response NSURLResponse for the HTTP request.
 * @param responseObject response object of the HTTP request.
 * @param request   The HTTP request.
 * @param error     The error of the HTTP request.
 */
- (void)logResponse:(NSURLResponse *)response responseObject:(id)responseObject request:(NSURLRequest *)request error:(NSError *)error;

@end
