# WMTOAStoreLocatorApi

All URIs are relative to *https://api.walmartlabs.com/v1/*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getNearestStore**](WMTOAStoreLocatorApi.md#getneareststore) | **GET** /stores | Find nearest Walmart stores


# **getNearestStore**
```objc
-(NSNumber*) getNearestStoreWithApiKey: (NSString*) apiKey
    format: (NSString*) format
    lat: (NSNumber*) lat
    lon: (NSNumber*) lon
    city: (NSString*) city
    zip: (NSNumber*) zip
        completionHandler: (void (^)(NSArray<WMTOAStore>* output, NSError* error)) handler;
```

Find nearest Walmart stores

Returns list of nearest Walmart stores

### Example 
```objc

NSString* apiKey = @"apiKey_example"; // Your API access key
NSString* format = @"json"; // Type of response required, allowed values [json, xml] (optional) (default to json)
NSNumber* lat = @1.2; // Latitude (optional)
NSNumber* lon = @1.2; // Longitude (optional)
NSString* city = @"city_example"; // City (optional)
NSNumber* zip = @56; // Zip code (optional)

@try
{ 
    WMTOAStoreLocatorApi *apiInstance = [[WMTOAStoreLocatorApi alloc] init];

    // Find nearest Walmart stores
    [apiInstance getNearestStoreWithApiKey:apiKey
                  format:format
                  lat:lat
                  lon:lon
                  city:city
                  zip:zip
              completionHandler: ^(NSArray<WMTOAStore>* output, NSError* error) {
                            if (output) {
                                NSLog(@"%@", output);
                            }
                            if (error) {
                                NSLog(@"Error: %@", error);
                            }
                        }];
}
@catch (NSException *exception)
{
    NSLog(@"Exception when calling WMTOAStoreLocatorApi->getNearestStore: %@ ", exception.name);
    NSLog(@"Reason: %@ ", exception.reason);
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **apiKey** | **NSString***| Your API access key | 
 **format** | **NSString***| Type of response required, allowed values [json, xml] | [optional] [default to json]
 **lat** | **NSNumber***| Latitude | [optional] 
 **lon** | **NSNumber***| Longitude | [optional] 
 **city** | **NSString***| City | [optional] 
 **zip** | **NSNumber***| Zip code | [optional] 

### Return type

[**NSArray<WMTOAStore>***](WMTOAStore.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/xml

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

