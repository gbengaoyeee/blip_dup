# WMTOASearchApi

All URIs are relative to *https://api.walmartlabs.com/v1/*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getSearchResponse**](WMTOASearchApi.md#getsearchresponse) | **GET** /search | Perform text search on the Walmart.com catalogue and get matching items available for sale online.


# **getSearchResponse**
```objc
-(NSNumber*) getSearchResponseWithApiKey: (NSString*) apiKey
    query: (NSString*) query
    lsPublisherId: (NSString*) lsPublisherId
    categoryId: (NSString*) categoryId
    start: (NSNumber*) start
    sort: (NSString*) sort
    order: (NSString*) order
    numItems: (NSNumber*) numItems
    format: (NSString*) format
    responseGroup: (NSString*) responseGroup
    facet: (NSString*) facet
    facetFilter: (NSString*) facetFilter
    facetRange: (NSString*) facetRange
        completionHandler: (void (^)(WMTOASearchResponse* output, NSError* error)) handler;
```

Perform text search on the Walmart.com catalogue and get matching items available for sale online.

Return Item results which are paginated, with up to 25 items displayed per page (using the numItems parameter)

### Example 
```objc

NSString* apiKey = @"apiKey_example"; // Your API access key.
NSString* query = @"query_example"; // Search text - whitespace separated sequence of keywords to search for.
NSString* lsPublisherId = @"lsPublisherId_example"; // Your Linkshare access key. (optional)
NSString* categoryId = @"categoryId_example"; // Category id of the category for search within a category. This should match the id field from Taxonomy API. (optional)
NSNumber* start = @1; // Starting point of the results within the matching set of items - upto 10 items will be returned starting from this item. (optional) (default to 1)
NSString* sort = @"relevance"; // Sorting criteria (optional) (default to relevance)
NSString* order = @"asc"; // Sort ordering criteria.This parameter is needed only for the sort types [price, title, customerRating]. (optional) (default to asc)
NSNumber* numItems = @10; // Number of matching items to be returned, max value 25. (optional) (default to 10)
NSString* format = @"json"; // Type of response required, allowed values [json, xml]. (optional) (default to json)
NSString* responseGroup = @"base"; // Specifies the item fields returned in the response.Refer Item Response Groups for details of exact fields returned by each response group. (optional) (default to base)
NSString* facet = @"off"; // Boolean flag to enable facets.Set this to on to enable facets. (optional) (default to off)
NSString* facetFilter = @"facetFilter_example"; // Filter on the facet attribute values. This parameter can be set to <facet-name>:<facet-value> (without the angles). Here facet-name and facet-value can be any valid facet picked from the search API response when facets are on. (optional)
NSString* facetRange = @"facetRange_example"; // Range filter for facets which take range values, like price. (optional)

@try
{ 
    WMTOASearchApi *apiInstance = [[WMTOASearchApi alloc] init];

    // Perform text search on the Walmart.com catalogue and get matching items available for sale online.
    [apiInstance getSearchResponseWithApiKey:apiKey
                  query:query
                  lsPublisherId:lsPublisherId
                  categoryId:categoryId
                  start:start
                  sort:sort
                  order:order
                  numItems:numItems
                  format:format
                  responseGroup:responseGroup
                  facet:facet
                  facetFilter:facetFilter
                  facetRange:facetRange
              completionHandler: ^(WMTOASearchResponse* output, NSError* error) {
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
    NSLog(@"Exception when calling WMTOASearchApi->getSearchResponse: %@ ", exception.name);
    NSLog(@"Reason: %@ ", exception.reason);
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **apiKey** | **NSString***| Your API access key. | 
 **query** | **NSString***| Search text - whitespace separated sequence of keywords to search for. | 
 **lsPublisherId** | **NSString***| Your Linkshare access key. | [optional] 
 **categoryId** | **NSString***| Category id of the category for search within a category. This should match the id field from Taxonomy API. | [optional] 
 **start** | **NSNumber***| Starting point of the results within the matching set of items - upto 10 items will be returned starting from this item. | [optional] [default to 1]
 **sort** | **NSString***| Sorting criteria | [optional] [default to relevance]
 **order** | **NSString***| Sort ordering criteria.This parameter is needed only for the sort types [price, title, customerRating]. | [optional] [default to asc]
 **numItems** | **NSNumber***| Number of matching items to be returned, max value 25. | [optional] [default to 10]
 **format** | **NSString***| Type of response required, allowed values [json, xml]. | [optional] [default to json]
 **responseGroup** | **NSString***| Specifies the item fields returned in the response.Refer Item Response Groups for details of exact fields returned by each response group. | [optional] [default to base]
 **facet** | **NSString***| Boolean flag to enable facets.Set this to on to enable facets. | [optional] [default to off]
 **facetFilter** | **NSString***| Filter on the facet attribute values. This parameter can be set to &lt;facet-name&gt;:&lt;facet-value&gt; (without the angles). Here facet-name and facet-value can be any valid facet picked from the search API response when facets are on. | [optional] 
 **facetRange** | **NSString***| Range filter for facets which take range values, like price. | [optional] 

### Return type

[**WMTOASearchResponse***](WMTOASearchResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/xml

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

