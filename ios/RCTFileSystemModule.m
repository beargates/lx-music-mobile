#import "RCTFileSystemModule.h"

NSString *const STORAGE_BACKED_UP = @"BACKED_UP";
NSString *const STORAGE_IMPORTANT = @"IMPORTANT";
NSString *const STORAGE_AUXILIARY = @"AUXILIARY";
NSString *const STORAGE_TEMPORARY = @"TEMPORARY";

@implementation RCTFileSystemModule

+ (BOOL)requiresMainQueueSetup {
    return NO;
}

- (NSDictionary<NSString *, NSString *> *)constantsToExport {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSURL *docsDir = [fileManager URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
  NSURL *cachesDir = [fileManager URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
  NSURL *tempDir = [NSURL fileURLWithPath:NSTemporaryDirectory()];
  return @{
    STORAGE_BACKED_UP: [[RCTFileSystemModule baseDirForStorage:STORAGE_BACKED_UP] path],
    STORAGE_IMPORTANT: [[RCTFileSystemModule baseDirForStorage:STORAGE_IMPORTANT] path],
    STORAGE_AUXILIARY: [[RCTFileSystemModule baseDirForStorage:STORAGE_AUXILIARY] path],
    STORAGE_TEMPORARY: [[RCTFileSystemModule baseDirForStorage:STORAGE_TEMPORARY] path],
    @"CacheDir": [cachesDir path],
    @"DocumentDir": [docsDir path],
    @"SDCardDir": [docsDir path]
  };
}


+ (NSURL*)baseDirForStorage:(NSString*)storage {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  if ([storage isEqual:STORAGE_BACKED_UP]) {
    NSURL *docsDir = [fileManager URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
    return [docsDir URLByAppendingPathComponent:@"RNFS-BackedUp"];
  } else if ([storage isEqual:STORAGE_IMPORTANT]) {
    NSURL *cachesDir = [fileManager URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
    return [cachesDir URLByAppendingPathComponent:@"RNFS-Important"];
  } else if ([storage isEqual:STORAGE_AUXILIARY]) {
    NSURL *cachesDir = [fileManager URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
    return [cachesDir URLByAppendingPathComponent:@"RNFS-Auxiliary"];
  } else if ([storage isEqual:STORAGE_TEMPORARY]) {
    NSURL *tempDir = [NSURL fileURLWithPath:NSTemporaryDirectory()];
    return [tempDir URLByAppendingPathComponent:@"RNFS-Temporary"];
  } else {
    [NSException raise:@"InvalidArgument" format:[NSString stringWithFormat:@"Storage type not recognized: %@", storage]];
    return nil;
  }
}

+ (void)createDirectoriesIfNeeded:(NSURL*)path {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *directory = [[path URLByDeletingLastPathComponent] path];
  [fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
  
}

+ (void)writeToFile:(NSString*)relativePath content:(NSString*)content inStorage:(NSString*)storage {
  NSURL *baseDir = [RCTFileSystemModule baseDirForStorage:storage];
  NSURL *fullPath = [baseDir URLByAppendingPathComponent:relativePath];
  [RCTFileSystemModule createDirectoriesIfNeeded:fullPath];

  [content writeToFile:[fullPath path] atomically:YES encoding:NSUTF8StringEncoding error:nil];
  if ([storage isEqual:STORAGE_IMPORTANT]) {
    [RCTFileSystemModule addSkipBackupAttributeToItemAtPath:[fullPath path]];
  }
}

//+ (NSString*)readFile:(NSString*)relativePath inStorage:(NSString*)storage error:(NSError**)error {
//  NSURL *baseDir = [RCTFileSystemModule baseDirForStorage:storage];
//  NSURL *fullPath = [baseDir URLByAppendingPathComponent:relativePath];
//  NSFileManager *fileManager = [NSFileManager defaultManager];
//  BOOL fileExists = [fileManager fileExistsAtPath:[fullPath path]];
//  if (!fileExists) {
//    NSString* errorMessage = [NSString stringWithFormat:@"File '%@' does not exist in storage: %@", relativePath, storage];
//    NSDictionary *errorDetail = @{NSLocalizedDescriptionKey: errorMessage};
//    *error = [NSError errorWithDomain:@"FSComponent" code:1 userInfo:errorDetail];
//    return nil;
//  }
//  return [NSString stringWithContentsOfFile:[fullPath path] encoding:NSUTF8StringEncoding error:nil];
//}

+ (BOOL)fileExists:(NSString*)relativePath inStorage:(NSString*)storage {
  NSURL *baseDir = [RCTFileSystemModule baseDirForStorage:storage];
  NSURL *fullPath = [baseDir URLByAppendingPathComponent:relativePath];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  BOOL isDirectory;
  BOOL exists = [fileManager fileExistsAtPath:[fullPath path] isDirectory:&isDirectory];
  return exists & !isDirectory;
}

+ (BOOL)directoryExists:(NSString*)relativePath inStorage:(NSString*)storage {
  NSURL *baseDir = [RCTFileSystemModule baseDirForStorage:storage];
  NSURL *fullPath = [baseDir URLByAppendingPathComponent:relativePath];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  BOOL isDirectory;
  BOOL exists = [fileManager fileExistsAtPath:[fullPath path] isDirectory:&isDirectory];
  return exists & isDirectory;
}

+ (BOOL)deleteFileOrDirectory:(NSString*)relativePath inStorage:(NSString*)storage {
  NSURL *baseDir = [RCTFileSystemModule baseDirForStorage:storage];
  NSURL *fullPath = [baseDir URLByAppendingPathComponent:relativePath];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  BOOL fileExists = [fileManager fileExistsAtPath:[fullPath path]];
  if (!fileExists) {
    return NO;
  }
  [fileManager removeItemAtPath:[fullPath path] error:nil];
  return YES;
}

+ (BOOL)addSkipBackupAttributeToItemAtPath:(NSString *) filePathString
{
  NSURL* URL= [NSURL fileURLWithPath: filePathString];
  assert([[NSFileManager defaultManager] fileExistsAtPath: [URL path]]);
  
  NSError *error = nil;
  BOOL success = [URL setResourceValue: [NSNumber numberWithBool: YES]
                                forKey: NSURLIsExcludedFromBackupKey error: &error];
  if(!success){
    NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
  }
  return success;
}

+ (NSString*)absolutePath:(NSString*)relativePath inStorage:(NSString*)storage {
  NSURL *baseDir = [RCTFileSystemModule baseDirForStorage:storage];
  return [[baseDir URLByAppendingPathComponent:relativePath] path];
}

// Extra method for integration from other modules / native code
+ (NSString*)moveFileFromUrl:(NSURL*)location toRelativePath:(NSString*)relativePath inStorage:(NSString*)storage {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSURL *baseDir = [RCTFileSystemModule baseDirForStorage:storage];
  NSURL *fullPath = [baseDir URLByAppendingPathComponent:relativePath];
  [RCTFileSystemModule createDirectoriesIfNeeded:fullPath];
  [fileManager moveItemAtURL:location toURL:fullPath error:nil];
  if ([storage isEqual:STORAGE_IMPORTANT]) {
    [RCTFileSystemModule addSkipBackupAttributeToItemAtPath:[fullPath path]];
  }
  return [fullPath path];
}





+ (NSArray<NSString *> *) getAllExternalStoragePaths {
  NSString *documentDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
  NSMutableArray *stringArray = [[NSMutableArray alloc] init];
  [stringArray addObject: documentDirectoryPath];
  return stringArray;
}

+ (NSMutableArray<NSDictionary *> *) ls: (NSString*)path {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSArray *directoryContents = [fileManager contentsOfDirectoryAtPath:path error:nil];
  NSMutableArray *array = [[NSMutableArray alloc] init];
  for (id d in directoryContents) {
    NSString* completePath = [@[path, @"/", d] componentsJoinedByString:@""];
    [array addObject: [RCTFileSystemModule readAsFile:completePath encoding:@"utf-8"]];
  }
  return array;
}

+ (BOOL) unlink:(NSString *)path {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  return [fileManager removeItemAtPath: path error:nil];
}

+ (void) mkdir:(NSString*)path {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
}

+ (NSDictionary*) readAsFile:(NSString*)path encoding:(NSString*)encoding {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString* data = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
  BOOL isFile = data != nil;
  NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:path error:nil];
  return @{
    @"name": path.lastPathComponent,
    @"path": path,
    @"isDirectory": [NSNumber numberWithBool:!isFile],
    @"isFile": [NSNumber numberWithBool:isFile],
    @"lastModified": [NSNumber numberWithDouble:[[fileAttributes fileModificationDate] timeIntervalSince1970] * 1000],
    @"canRead": @YES,
    @"data": isFile ? data : @"",
    @"mimeType": [RCTFileSystemModule getMIMETypeForFileAtPath: path],
    @"size": [NSNumber numberWithUnsignedLong: data.length]
  };
}
+ (NSString*) readFile:(NSString*)path encoding:(NSString*)encoding {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  return [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
}

+ (void)writeFile:(NSString*)path content:(NSString*)content encoding:(NSString*)encoding {
  [content writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

+ (void)cp:(NSString*)from to:(NSString*)to {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  [fileManager copyItemAtPath:from toPath:to error:nil];
}

+ (BOOL)mv:(NSString*)from to:(NSString*)to {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  return [fileManager moveItemAtPath:from toPath:to error:nil];
}

+ (BOOL)exists:(NSString*)path {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  return [fileManager fileExistsAtPath:path];
}
// todo stat
// todo appendFile
// todo rename

+ (NSString *)getMIMETypeForFileAtPath:(NSString*)filePath {
    NSString *extension = [[filePath pathExtension] lowercaseString];
    NSString *mimeType = nil;
 
    // 通过扩展名获取MIME类型
    if ([extension isEqualToString:@"jpg"]) {
        mimeType = @"image/jpeg";
    } else if ([extension isEqualToString:@"png"]) {
        mimeType = @"image/png";
    } else if ([extension isEqualToString:@"txt"] || [extension isEqualToString:@"js"]) {
        mimeType = @"text/plain";
    } else if ([extension isEqualToString:@"pdf"]) {
        mimeType = @"application/pdf";
    } else if ([extension isEqualToString:@"doc"]) {
        mimeType = @"application/msword";
    } else if ([extension isEqualToString:@"docx"]) {
        mimeType = @"application/vnd.openxmlformats-officedocument.wordprocessingml.document";
    } else if ([extension isEqualToString:@"xls"]) {
        mimeType = @"application/vnd.ms-excel";
    } else if ([extension isEqualToString:@"xlsx"]) {
        mimeType = @"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
    } else if ([extension isEqualToString:@"ppt"]) {
        mimeType = @"application/vnd.ms-powerpoint";
    } else if ([extension isEqualToString:@"pptx"]) {
        mimeType = @"application/vnd.openxmlformats-officedocument.presentationml.presentation";
    } else if ([extension isEqualToString:@"zip"]) {
        mimeType = @"application/zip";
    } else if ([extension isEqualToString:@"mp3"] || [extension isEqualToString:@"m4a"]) {
        mimeType = @"audio/mpeg";
    } else if ([extension isEqualToString:@"mp4"]) {
        mimeType = @"video/mp4";
    } else {
        mimeType = @"text/unknown";
    }
 
    return mimeType;
}

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(getAllExternalStoragePaths: resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  NSArray* arr = [RCTFileSystemModule getAllExternalStoragePaths];
  resolve(arr);
}
RCT_EXPORT_METHOD(ls:(NSString*)path resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  NSArray* arr = [RCTFileSystemModule ls:path];
  resolve(arr);
}
RCT_EXPORT_METHOD(unlink:(NSString*)path: resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  [RCTFileSystemModule unlink:path];
  resolve([NSNumber numberWithBool:YES]);
}
RCT_EXPORT_METHOD(mkdir:(NSString*)path) {
  [RCTFileSystemModule mkdir:path];
}
RCT_EXPORT_METHOD(readFile:(NSString*)path encoding:(NSString*)encoding resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  resolve([RCTFileSystemModule readFile:path encoding: encoding]);
}
RCT_EXPORT_METHOD(writeFile:(NSString*)path content:(NSString*)content encoding:(NSString*)encoding) {
  [RCTFileSystemModule writeFile:path content:(NSString*)content encoding: encoding];
}
RCT_EXPORT_METHOD(cp:(NSString*)from to:(NSString*)to) {
  [RCTFileSystemModule cp:from to:to];
}
RCT_EXPORT_METHOD(mv:(NSString*)from to:(NSString*)to resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  [RCTFileSystemModule mv:from to:to];
  resolve([NSNumber numberWithBool:YES]);
}
RCT_EXPORT_METHOD(exists:(NSString*)path: resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  BOOL e = [RCTFileSystemModule exists:path];
  resolve([NSNumber numberWithBool:e]);
}


RCT_EXPORT_METHOD(writeToFile:(NSString*)relativePath content:(NSString*)content inStorage:(NSString*)storage resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  [RCTFileSystemModule writeToFile:relativePath content:content inStorage:storage];
  resolve([NSNumber numberWithBool:YES]);
}


//RCT_EXPORT_METHOD(readFile:(NSString*)relativePath inStorage:(NSString*)storage resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
//  NSError *error;
//  NSString *content = [RCTFileSystemModule readFile:relativePath inStorage:storage error:&error];
//  if (error != nil) {
//    reject(@"RNFileSystemError", [error localizedDescription], error);
//  } else {
//    resolve(content);
//  }
//}

RCT_EXPORT_METHOD(fileExists:(NSString*)relativePath inStorage:(NSString*)storage resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  BOOL fileExists = [RCTFileSystemModule fileExists:relativePath inStorage:storage];
  resolve([NSNumber numberWithBool:fileExists]);
}

RCT_EXPORT_METHOD(directoryExists:(NSString*)relativePath inStorage:(NSString*)storage resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  BOOL folderExists = [RCTFileSystemModule directoryExists:relativePath inStorage:storage];
  resolve([NSNumber numberWithBool:folderExists]);
}

RCT_EXPORT_METHOD(delete:(NSString*)relativePath inStorage:(NSString*)storage resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
  BOOL deleted = [RCTFileSystemModule deleteFileOrDirectory:relativePath inStorage:storage];
  resolve([NSNumber numberWithBool:deleted]);
}


RCT_EXPORT_METHOD(unlink:(NSString*)relativePath resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
  BOOL deleted = [RCTFileSystemModule unlink:relativePath];
  resolve([NSNumber numberWithBool:deleted]);
}

@end
