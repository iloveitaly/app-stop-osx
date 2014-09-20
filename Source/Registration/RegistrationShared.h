/*
 *  RegistrationShared.h
 *  App Stop
 *
 *  Created by Michael Bianco on 9/7/06.
 *  Copyright 2006 __MyCompanyName__. All rights reserved.
 *
 */

#define REGISTRATION_DEBUG 0

#define HIDDEN_FILES /* hide license files and other data files */
#define HIDDEN_LICENSE_FUNCTIONS /* use zfunky names for license related functions and use define to map the old names to the new names */

#define ASLicenseFileExtension @"appstoplicense"
#ifdef HIDDEN_FILES
#define ASLicenseFileName [NSString stringWithFormat:@"%c%c%c%c%c%c%c%c", '.','l','i','c','e','n','s','e']
#else
#define ASLicenseFileName @"license"
#endif

//notification that the app has been registered
#define MABAppRegisteredNotification @"applicationRegistered"
