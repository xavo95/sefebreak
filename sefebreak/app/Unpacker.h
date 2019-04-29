//
//  Unpacker.h
//  sefebreak
//
//  Created by Xavier Perarnau on 03/04/2019.
//  Copyright © 2019 Xavier Perarnau. All rights reserved.
//

#ifndef Unpacker_h
#define Unpacker_h

#include <stdio.h>
#import <stdbool.h>
#import <mach/mach.h>

/*
 * clean_up_previous
 *
 * Description:
 *     Clean up previous installation if specific file is not present.
 */
bool clean_up_previous(bool force_reinstall, cpu_subtype_t cpu_subtype);

/*
 * unpack_binaries
 *
 * Description:
 *     Unpack the binaries.
 */
void unpack_binaries(cpu_subtype_t cpu_subtype);

/*
 * prepare_dropbear
 *
 * Description:
 *     Prepare motd and profile for dropbear.
 */
void prepare_dropbear(void);

/*
 * unpack_launchdeamons
 *
 * Description:
 *     Unpack the LaunchDaemons.
 */
void unpack_launchdeamons();

/*
 * enable_tweaks
 *
 * Description:
 *     Enable tweaks.
 */
void enable_tweaks(void);

#endif /* Unpacker_h */
