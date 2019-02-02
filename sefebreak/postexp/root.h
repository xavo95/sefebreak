//
//  root.h
//  sefebreak
//
//  Created by Xavier Perarnau on 03/02/2019.
//  Copyright © 2019 Xavier Perarnau. All rights reserved.
//

#ifndef root_h
#define root_h

#include <stdio.h>

/*
 * save_proc_user_struct
 *
 * Description:
 *     Backup the user struct of our process.
 */
void save_proc_user_struct(uint64_t task);

/*
 * root
 *
 * Description:
 *     Modify our proc struc to get root permissions.
 */
void root(uint64_t task);

/*
 * unroot
 *
 * Description:
 *     Modify our proc struc to revert root permissions.
 */
void unroot(uint64_t task);

#endif /* root_h */
