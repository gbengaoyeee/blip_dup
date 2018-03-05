# WMTOATaxonomyApi

All URIs are relative to *https://api.walmartlabs.com/v1/*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getCategoryTaxonomy**](WMTOATaxonomyApi.md#getcategorytaxonomy) | **GET** /taxonomy | Get the category taxonomy used by walmart.com to categorize items.


# **getCategoryTaxonomy**
```objc
-(NSNumber*) getCategoryTaxonomyWithApiKey: (NSString*) apiKey
    format: (NSString*) format
        completionHandler: (void (^)(WMTOACategoryTaxonomy* output, NSError* error)) handler;
```

Get the category taxonomy used by walmart.com to categorize items.

Category taxonomy describes three levels - Departments, Categories and Sub-categories as available on Walmart.com. It is possible to specify the exact category as a parameter when using any of the API's below:  Search Data feeds  Special feeds - [Pre-order, Best sellers, Rollbacks, Clearance and Special buys] For example, Search API can be restricted to search within a category by supplying id as per the taxonomy. Similarly, Feed API can be used to download category specific feeds by specifying a category id.

### Example 
```objc

NSString* apiKey = @"apiKey_example"; // Your API access key.
NSString* format = @"json"; // Type of response required, allowed values [json, xml]. (optional) (default to json)

@try
{ 
    WMTOATaxonomyApi *apiInstance = [[WMTOATaxonomyApi alloc] init];

    // Get the category taxonomy used by walmart.com to categorize items.
    [apiInstance getCategoryTaxonomyWithApiKey:apiKey
                  format:format
              completionHandler: ^(WMTOACategoryTaxonomy* output, NSError* error) {
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
    NSLog(@"Exception when calling WMTOATaxonomyApi->getCategoryTaxonomy: %@ ", exception.name);
    NSLog(@"Reason: %@ ", exception.reason);
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **apiKey** | **NSString***| Your API access key. | 
 **format** | **NSString***| Type of response required, allowed values [json, xml]. | [optional] [default to json]

### Return type

[**WMTOACategoryTaxonomy***](WMTOACategoryTaxonomy.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/xml

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

