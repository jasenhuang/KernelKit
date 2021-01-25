//
//  KKObject.h
//  KernelKit
//
//  Created by 黄栩生 on 2020/12/31.
//


#ifndef _KKOBJECT_H
#define _KKOBJECT_H

/***********************************************************************
   Autorelease pool implementation

   A thread's autorelease pool is a stack of pointers.
   Each pointer is either an object to release, or POOL_BOUNDARY which is
	 an autorelease pool boundary.
   A pool token is a pointer to the POOL_BOUNDARY for that pool. When
	 the pool is popped, every object hotter than the sentinel is released.
   The stack is divided into a doubly-linked list of pages. Pages are added
	 and deleted as necessary.
   Thread-local storage points to the hot page, where newly autoreleased
	 objects are stored.
**********************************************************************/

// structure version number. Only bump if ABI compatability is broken
#define AUTORELEASEPOOL_VERSION 1

// Set this to 1 to mprotect() autorelease pool contents
#define PROTECT_AUTORELEASEPOOL 0

// Set this to 1 to validate the entire autorelease pool header all the time
// (i.e. use check() instead of fastcheck() everywhere)
#define CHECK_AUTORELEASEPOOL (DEBUG)

#ifdef __cplusplus
#include <string.h>
#include <assert.h>
#include <objc/objc.h>
#include <pthread.h>


#ifndef C_ASSERT
	#if __has_feature(cxx_static_assert)
		#define C_ASSERT(expr) static_assert(expr, "(" #expr ")!")
	#elif __has_feature(c_static_assert)
		#define C_ASSERT(expr) _Static_assert(expr, "(" #expr ")!")
	#else
		#define C_ASSERT(expr)
	#endif
#endif

// Make ASSERT work when objc-private.h hasn't been included.
#ifndef ASSERT
#define ASSERT(x) assert(x)
#endif

struct magic_t {
	static const uint32_t M0 = 0xA1A1A1A1;
#   define M1 "AUTORELEASE!"
	static const size_t M1_len = 12;
	uint32_t m[4];

	magic_t() {
		ASSERT(M1_len == strlen(M1));
		ASSERT(M1_len == 3 * sizeof(m[1]));

		m[0] = M0;
		strncpy((char *)&m[1], M1, M1_len);
	}

	~magic_t() {
		// Clear magic before deallocation.
		// This prevents some false positives in memory debugging tools.
		// fixme semantically this should be memset_s(), but the
		// compiler doesn't optimize that at all (rdar://44856676).
		volatile uint64_t *p = (volatile uint64_t *)m;
		p[0] = 0; p[1] = 0;
	}

	bool check() const {
		return (m[0] == M0 && 0 == strncmp((char *)&m[1], M1, M1_len));
	}

	bool fastcheck() const {
#if CHECK_AUTORELEASEPOOL
		return check();
#else
		return (m[0] == M0);
#endif
	}

#   undef M1
};

class AutoreleasePoolPage;
struct AutoreleasePoolPageData
{
	magic_t const magic;
	__unsafe_unretained id *next;
	pthread_t const thread;
	AutoreleasePoolPage * const parent;
	AutoreleasePoolPage *child;
	uint32_t const depth;
	uint32_t hiwat;

	AutoreleasePoolPageData(__unsafe_unretained id* _next, pthread_t _thread, AutoreleasePoolPage* _parent, uint32_t _depth, uint32_t _hiwat)
		: magic(), next(_next), thread(_thread),
		  parent(_parent), child(nil),
		  depth(_depth), hiwat(_hiwat)
	{
	}
};


struct thread_data_t
{
#ifdef __LP64__
	pthread_t const thread;
	uint32_t const hiwat;
	uint32_t const depth;
#else
	pthread_t const thread;
	uint32_t const hiwat;
	uint32_t const depth;
	uint32_t padding;
#endif
};
C_ASSERT(sizeof(thread_data_t) == 16);

#undef C_ASSERT

#endif
#endif
