# WMTOAProductRecommendationsApi

All URIs are relative to *https://api.walmartlabs.com/v1/*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getNextBestProducts**](WMTOAProductRecommendationsApi.md#getnextbestproducts) | **GET** /nbp | Get the next best product recommendations
[**getPostBrowseProducts**](WMTOAProductRecommendationsApi.md#getpostbrowseproducts) | **GET** /postbrowse | Get the post browsed products recommendations
[**getTrendingItems**](WMTOAProductRecommendationsApi.md#gettrendingitems) | **GET** /trends | Get the trending products recommendations


# **getNextBestProducts**
```objc
-(NSNumber*) getNextBestProductsWithApiKey: (NSString*) apiKey
    itemId: (NSString*) itemId
    format: (NSString*) format
    lsPublisherId: (NSString*) lsPublisherId
        completionHandler: (void (^)(NSArray<WMTOAItem>* output, NSError* error)) handler;
```

Get the next best product recommendations

The Product recommendation API is an extension driven by the science that powers the recommended products container on Walmart.com. We have parsed 100s of millions of transactions over our product catalog of more than 6 million products to be able to deliver, with accuracy, the items in this response. Some example use cases where a partner might be interested in utilizing this data:  A recommended products advertising widget via e-mail delivered right after a transaction has been verified Retargeting on an ecommerce storefront anchored on a shared UPC between multiple merchants An upsell to an existing customer presenting an array of products due to knowing their order history The endpoint returns a maximum of 10 item responses, being ordered from most relevant to least relevant for the customer.

### Example 
```objc

NSString* apiKey = @"apiKey_example"; // Your API access key.
NSString* itemId = @"itemId_example"; // Walmart item id
NSString* format = @"json"; // Type of response required, allowed values [json, xml]. (optional) (default to json)
NSString* lsPublisherId = @"lsPublisherId_example"; // Your Linkshare access key (optional)

@try
{ 
    WMTOAProductRecommendationsApi *apiInstance = [[WMTOAProductRecommendationsApi alloc] init];

    // Get the next best product recommendations
    [apiInstance getNextBestProductsWithApiKey:apiKey
                  itemId:itemId
                  format:format
                  lsPublisherId:lsPublisherId
              completionHandler: ^(NSArray<WMTOAItem>* output, NSError* error) {
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
    NSLog(@"Exception when calling WMTOAProductRecommendationsApi->getNextBestProducts: %@ ", exception.name);
    NSLog(@"Reason: %@ ", exception.reason);
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **apiKey** | **NSString***| Your API access key. | 
 **itemId** | **NSString***| Walmart item id | 
 **format** | **NSString***| Type of response required, allowed values [json, xml]. | [optional] [default to json]
 **lsPublisherId** | **NSString***| Your Linkshare access key | [optional] 

### Return type

[**NSArray<WMTOAItem>***](WMTOAItem.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/xml

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPostBrowseProducts**
```objc
-(NSNumber*) getPostBrowseProductsWithApiKey: (NSString*) apiKey
    itemId: (NSString*) itemId
    format: (NSString*) format
    lsPublisherId: (NSString*) lsPublisherId
        completionHandler: (void (^)(NSArray<WMTOAItem>* output, NSError* error)) handler;
```

Get the post browsed products recommendations

The post browsed products API allows you to recommend products to someone based on their product viewing history. Similar to the Product Recommendation API, this endpoint uses one item ID as the anchor for the output. For instance, if you know that one of your customers has recently viewed an Xbox one, it is likely that they may be also interested in purchasing a PlayStation 4, or Nintento Wii. Some example use cases for this data:  Retargeting to your customers based on knowing their recent viewing history. Understanding what other similar items a customer might purchase if the initial item they were interested in has gone out of stock. The endpoint returns a maximum of 10 item responses, being ordered from most relevant to least relevant for the customer.

### Example 
```objc

NSString* apiKey = @"apiKey_example"; // Your API access key.
NSString* itemId = @"itemId_example"; // Walmart item id
NSString* format = @"json"; // Type of response required, allowed values [json, xml]. (optional) (default to json)
NSString* lsPublisherId = @"lsPublisherId_example"; // Your Linkshare access key (optional)

@try
{ 
    WMTOAProductRecommendationsApi *apiInstance = [[WMTOAProductRecommendationsApi alloc] init];

    // Get the post browsed products recommendations
    [apiInstance getPostBrowseProductsWithApiKey:apiKey
                  itemId:itemId
                  format:format
                  lsPublisherId:lsPublisherId
              completionHandler: ^(NSArray<WMTOAItem>* output, NSError* error) {
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
    NSLog(@"Exception when calling WMTOAProductRecommendationsApi->getPostBrowseProducts: %@ ", exception.name);
    NSLog(@"Reason: %@ ", exception.reason);
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **apiKey** | **NSString***| Your API access key. | 
 **itemId** | **NSString***| Walmart item id | 
 **format** | **NSString***| Type of response required, allowed values [json, xml]. | [optional] [default to json]
 **lsPublisherId** | **NSString***| Your Linkshare access key | [optional] 

### Return type

[**NSArray<WMTOAItem>***](WMTOAItem.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/xml

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getTrendingItems**
```objc
-(NSNumber*) getTrendingItemsWithApiKey: (NSString*) apiKey
    format: (NSString*) format
    lsPublisherId: (NSString*) lsPublisherId
        completionHandler: (void (^)(WMTOATrendingItems* output, NSError* error)) handler;
```

Get the trending products recommendations

Trending API is designed to give the information on what is bestselling on Walmart.com right now. The items are curated on the basis of user browse activity and sales activity, and updated multiple times a day. Expect a high clickthrough and conversion rate on these items if you choose to advertise them.  

### Example 
```objc

NSString* apiKey = @"apiKey_example"; // Your API access key.
NSString* format = @"json"; // Type of response required, allowed values [json, xml]. (optional) (default to json)
NSString* lsPublisherId = @"lsPublisherId_example"; // Your Linkshare access key (optional)

@try
{ 
    WMTOAProductRecommendationsApi *apiInstance = [[WMTOAProductRecommendationsApi alloc] init];

    // Get the trending products recommendations
    [apiInstance getTrendingItemsWithApiKey:apiKey
                  format:format
                  lsPublisherId:lsPublisherId
              completionHandler: ^(WMTOATrendingItems* output, NSError* error) {
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
    NSLog(@"Exception when calling WMTOAProductRecommendationsApi->getTrendingItems: %@ ", exception.name);
    NSLog(@"Reason: %@ ", exception.reason);
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **apiKey** | **NSString***| Your API access key. | 
 **format** | **NSString***| Type of response required, allowed values [json, xml]. | [optional] [default to json]
 **lsPublisherId** | **NSString***| Your Linkshare access key | [optional] 

### Return type

[**WMTOATrendingItems***](WMTOATrendingItems.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/xml

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

