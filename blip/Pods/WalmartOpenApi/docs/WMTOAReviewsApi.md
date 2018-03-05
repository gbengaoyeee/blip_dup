# WMTOAReviewsApi

All URIs are relative to *https://api.walmartlabs.com/v1/*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getReviews**](WMTOAReviewsApi.md#getreviews) | **GET** /reviews/{itemId} | Get the item reviews on Walmart


# **getReviews**
```objc
-(NSNumber*) getReviewsWithItemId: (NSString*) itemId
    apiKey: (NSString*) apiKey
    format: (NSString*) format
    lsPublisherId: (NSString*) lsPublisherId
        completionHandler: (void (^)(WMTOAReviewResponse* output, NSError* error)) handler;
```

Get the item reviews on Walmart

Reviews API gives you access to the extensive item reviews on Walmart that have been written by the users of Walmart.com. This is great content for enriching item descriptions. You are free to showcase this content on your application provided you link back to the original content page on Walmart.com, as specified in the response parameter "productUrl".

### Example 
```objc

NSString* itemId = @"itemId_example"; // 
NSString* apiKey = @"apiKey_example"; // Your API access key.
NSString* format = @"json"; // Type of response required, allowed values [json, xml]. (optional) (default to json)
NSString* lsPublisherId = @"lsPublisherId_example"; // Your Linkshare access key (optional)

@try
{ 
    WMTOAReviewsApi *apiInstance = [[WMTOAReviewsApi alloc] init];

    // Get the item reviews on Walmart
    [apiInstance getReviewsWithItemId:itemId
                  apiKey:apiKey
                  format:format
                  lsPublisherId:lsPublisherId
              completionHandler: ^(WMTOAReviewResponse* output, NSError* error) {
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
    NSLog(@"Exception when calling WMTOAReviewsApi->getReviews: %@ ", exception.name);
    NSLog(@"Reason: %@ ", exception.reason);
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **itemId** | **NSString***|  | 
 **apiKey** | **NSString***| Your API access key. | 
 **format** | **NSString***| Type of response required, allowed values [json, xml]. | [optional] [default to json]
 **lsPublisherId** | **NSString***| Your Linkshare access key | [optional] 

### Return type

[**WMTOAReviewResponse***](WMTOAReviewResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/xml

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

