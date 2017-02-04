//
//  Store+Extra.h
//  MatListan
//
//  Created by Yan Zhang on 08/09/14.
//  Copyright (c) 2014 Flame Soft. All rights reserved.
//

#import "Store.h"
#import "SearchedStore+Extra.h"
#import "DataStore.h"
#import "SuperObject.h"

@interface Store (Extra)<SuperObject>
+(BOOL)fakeDeleteById:(NSNumber*)storeId;
+(Store*) createStoreWithResponse:(id) response forContext: (NSManagedObjectContext*)context;
+(void)insertStores:(id)responseObject;
+(NSArray*)getAllStores;
+(void)deleteAllItems;
+(Store*)getFavoriteStore;
+(Store*)getStoreByID:(NSNumber*)storeID;
+(void)setFavorite:(BOOL)isFavorite forStore:(Store*)store;
+(NSArray*)getAllStoresByStatus:(SYNC_STATUS)status;
+(void)changeSyncStatus:(SYNC_STATUS)status for:(NSNumber*)storeID;
+(void)insertSearchedStores:(id)responseObject;
+(NSArray*)getStoresCloseby;
+(void)insertSearchedStore:(SearchedStore*)store;
+(NSArray*)getFavouriteStoresArray;
+(BOOL)checkIfOneOftheFavouriteStoresWithName:(NSString *)storeNameIn;
+(Store *)getFavoriteStoreWithName:(NSString *)nameIn;
+(int) getNumberOfFavouriteStores;
+(Store *)insertSearchedStore:(NSString*)storeTitle storeCity:(NSString *)storeCity postalAddress:(NSString *)postalAddress postalCode:(NSNumber *)postalCode  name:(NSString *)name distance:(NSNumber *)distance isFavorite:(NSNumber *)isFavorite itemsSortedPercent:(NSNumber *)itemsSortedPercent storeID:(NSNumber *)storeID address:(NSString *)address;
@end
