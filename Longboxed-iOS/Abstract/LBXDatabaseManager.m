//
//  DatabaseManager.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/7/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "RestKit/RestKit.h"
#import <RestKit/CoreData.h>
#import "CoreData+MagicalRecord.h"

#import "LBXDatabaseManager.h"
#import "LBXClient.h"
#import "LBXMap.h"
#import "LBXEndpoints.h"
#import "LBXDescriptors.h"

@interface LBXDatabaseManager ()

@property (nonatomic, strong) RKManagedObjectStore *managedObjectStore;

@end

// Use a class extension to expose access to MagicalRecord's private setter methods
@interface NSManagedObjectContext ()
+ (void)MR_setRootSavingContext:(NSManagedObjectContext *)context;
+ (void)MR_setDefaultContext:(NSManagedObjectContext *)moc;
@end

@implementation LBXDatabaseManager

+ (void)flushDatabase{
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        NSManagedObjectContext *managedObjectContext = [RKManagedObjectStore defaultStore].mainQueueManagedObjectContext;
        [managedObjectContext performBlockAndWait:^{
            NSError *error = nil;
            for (NSEntityDescription *entity in [RKManagedObjectStore defaultStore].managedObjectModel) {
                NSFetchRequest *fetchRequest = [NSFetchRequest new];
                [fetchRequest setEntity:entity];
                [fetchRequest setIncludesSubentities:NO];
                NSArray *objects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
                if (! objects) RKLogWarning(@"Failed execution of fetch request %@: %@", fetchRequest, error);
                for (NSManagedObject *managedObject in objects) {
                    [managedObjectContext deleteObject:managedObject];
                }
            }
            
            BOOL success = [managedObjectContext save:&error];
            if (!success) RKLogWarning(@"Failed saving managed object context: %@", error);
        }];
    }];
    [operation setCompletionBlock:^{
        // Do stuff once the truncation is complete
    }];
    [operation start];
}

+ (void)setupRestKit {
//    if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.longboxed.Longboxed-iOSDebug"]) {
//        RKLogConfigureByName("RestKit*", RKLogLevelDebug); // set all RestKit logs to warning (leaving the app-specific log untouched).
//        RKLogConfigureByName("RestKit/CoreData", RKLogLevelDebug);
//    }
//    else {
//        RKLogConfigureByName("*", RKLogLevelOff)
//    }
    
    // Initialize RestKit
    RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:[LBXEndpoints baseURLString]]];
    
    // Auth
    [LBXClient setAuth];
    
    NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:managedObjectModel];
    manager.managedObjectStore = managedObjectStore;
    
    RKObjectMapping *errorMapping = [RKObjectMapping mappingForClass:[RKErrorMessage class]];
    
    [errorMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:nil toKeyPath:@"errorMessage"]];
    
    RKResponseDescriptor *errorDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:errorMapping
                                                                                         method:RKRequestMethodAny
                                                                                    pathPattern:nil
                                                                                        keyPath:@"error"
                                                                                    statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassClientError)];
    
    [manager addResponseDescriptorsFromArray:@[errorDescriptor]];
    [manager addResponseDescriptorsFromArray:[LBXDescriptors GETResponseDescriptors]];
    
    /**
     Complete Core Data stack initialization
     */
    [managedObjectStore createPersistentStoreCoordinator];
    
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"Longboxed-iOS.sqlite"];
    
    NSError *error;
    
    NSPersistentStore *persistentStore = [managedObjectStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:nil  withConfiguration:nil options:@{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES} error:&error];
    
    NSAssert(persistentStore, @"Failed to add persistent store with error: %@", error);
    
    // Create the managed object contexts
    [managedObjectStore createManagedObjectContexts];
    
    // Configure MagicalRecord to use RestKit's Core Data stack
    [NSPersistentStoreCoordinator MR_setDefaultStoreCoordinator:managedObjectStore.persistentStoreCoordinator];
    [NSManagedObjectContext MR_setRootSavingContext:managedObjectStore.persistentStoreManagedObjectContext];
    [NSManagedObjectContext MR_setDefaultContext:managedObjectStore.mainQueueManagedObjectContext];
    
    // Configure a managed object cache to ensure we do not create duplicate objects
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    
}

@end
