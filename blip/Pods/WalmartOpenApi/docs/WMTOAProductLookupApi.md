# WMTOAProductLookupApi

All URIs are relative to *https://api.walmartlabs.com/v1/*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getItem**](WMTOAProductLookupApi.md#getitem) | **GET** /items/{itemId} | Get real time item status including price and availability
[**getItems**](WMTOAProductLookupApi.md#getitems) | **GET** /items | Get real time item status including price and availability


# **getItem**
```objc
-(NSNumber*) getItemWithItemId: (NSString*) itemId
    apiKey: (NSString*) apiKey
    lsPublisherId: (NSString*) lsPublisherId
    format: (NSString*) format
        completionHandler: (void (^)(WMTOAItem* output, NSError* error)) handler;
```

Get real time item status including price and availability

Returns item details

### Example 
```objc

NSString* itemId = @"itemId_example"; // 
NSString* apiKey = @"apiKey_example"; // Your API access key
NSString* lsPublisherId = @"lsPublisherId_example"; // Your Linkshare access key (optional)
NSString* format = @"json"; // Type of response required, allowed values [json, xml] (optional) (default to json)

@try
{ 
    WMTOAProductLookupApi *apiInstance = [[WMTOAProductLookupApi alloc] init];

    // Get real time item status including price and availability
    [apiInstance getItemWithItemId:itemId
                  apiKey:apiKey
                  lsPublisherId:lsPublisherId
                  format:format
              completionHandler: ^(WMTOAItem* output, NSError* error) {
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
    NSLog(@"Exception when calling WMTOAProductLookupApi->getItem: %@ ", exception.name);
    NSLog(@"Reason: %@ ", exception.reason);
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **itemId** | **NSString***|  | 
 **apiKey** | **NSString***| Your API access key | 
 **lsPublisherId** | **NSString***| Your Linkshare access key | [optional] 
 **format** | **NSString***| Type of response required, allowed values [json, xml] | [optional] [default to json]

### Return type

[**WMTOAItem***](WMTOAItem.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/xml

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getItems**
```objc
-(NSNumber*) getItemsWithApiKey: (NSString*) apiKey
    ids: (NSString*) ids
    lsPublisherId: (NSString*) lsPublisherId
    upc: (NSString*) upc
    format: (NSString*) format
        completionHandler: (void (^)(WMTOAItems* output, NSError* error)) handler;
```

Get real time item status including price and availability

Returns item details

### Example 
```objc

NSString* apiKey = @"apiKey_example"; // Your API access key
NSString* ids = @"ids_example"; // Comma separated list of Walmart Item IDs (optional)
NSString* lsPublisherId = @"lsPublisherId_example"; // Your Linkshare access key (optional)
NSString* upc = @"upc_example"; // Universal Product Code (optional)
NSString* format = @"json"; // Type of response required, allowed values [json, xml] (optional) (default to json)

@try
{ 
    WMTOAProductLookupApi *apiInstance = [[WMTOAProductLookupApi alloc] init];

    // Get real time item status including price and availability
    [apiInstance getItemsWithApiKey:apiKey
                  ids:ids
                  lsPublisherId:lsPublisherId
                  upc:upc
                  format:format
              completionHandler: ^(WMTOAItems* output, NSError* error) {
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
    NSLog(@"Exception when calling WMTOAProductLookupApi->getItems: %@ ", exception.name);
    NSLog(@"Reason: %@ ", exception.reason);
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **apiKey** | **NSString***| Your API access key | 
 **ids** | **NSString***| Comma separated list of Walmart Item IDs | [optional] 
 **lsPublisherId** | **NSString***| Your Linkshare access key | [optional] 
 **upc** | **NSString***| Universal Product Code | [optional] 
 **format** | **NSString***| Type of response required, allowed values [json, xml] | [optional] [default to json]

### Return type

[**WMTOAItems***](WMTOAItems.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/xml

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

