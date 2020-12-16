//
//  NSObject-internal.c
//  KernelKit
//
//  Created by jasenhuang on 2020/12/16.
//

#include "NSObject-internal.h"
#include "KKMacros.h"
#include <malloc/malloc.h>
#include <stdint.h>
#include <stdbool.h>

typedef pthread_key_t tls_key_t;

/* ObjC runtime tls key */
#define TLS_DIRECT_KEY        ((tls_key_t)__PTK_FRAMEWORK_OBJC_KEY0)
#define SYNC_DATA_DIRECT_KEY  ((tls_key_t)__PTK_FRAMEWORK_OBJC_KEY1)
#define SYNC_COUNT_DIRECT_KEY ((tls_key_t)__PTK_FRAMEWORK_OBJC_KEY2)
#define AUTORELEASE_POOL_KEY  ((tls_key_t)__PTK_FRAMEWORK_OBJC_KEY3)
#define RETURN_DISPOSITION_KEY ((tls_key_t)__PTK_FRAMEWORK_OBJC_KEY4)

static inline bool is_valid_direct_key(tls_key_t k) {
    return (   k == SYNC_DATA_DIRECT_KEY
            || k == SYNC_COUNT_DIRECT_KEY
            || k == AUTORELEASE_POOL_KEY
            || k == RETURN_DISPOSITION_KEY
            );
}

void* tls_get_direct(tls_key_t key) {
    if (!is_valid_direct_key(key)) return NULL;
    return pthread_getspecific(key);
}

void tls_set_direct(tls_key_t key, void* value) {
    if (!is_valid_direct_key(key)) return;
    pthread_setspecific(key, value);
}

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

void * _Nonnull objc_autoreleasePoolPush(void);

void objc_autoreleasePoolPop(void * _Nonnull context);

class AutoreleasePoolPage : private AutoreleasePoolPageData
{
    friend struct thread_data_t;

public:
    static size_t const SIZE =
#if PROTECT_AUTORELEASEPOOL
        PAGE_MAX_SIZE;  // must be multiple of vm page size
#else
        PAGE_MIN_SIZE;  // size and alignment, power of 2
#endif
    
private:
    static pthread_key_t const key = AUTORELEASE_POOL_KEY;
    static uint8_t const SCRIBBLE = 0xA3;  // 0xA3A3A3A3 after releasing
    static size_t const COUNT = SIZE / sizeof(id);

    // EMPTY_POOL_PLACEHOLDER is stored in TLS when exactly one pool is
    // pushed and it has never contained any objects. This saves memory
    // when the top level (i.e. libdispatch) pushes and pops pools but
    // never uses them.
#   define EMPTY_POOL_PLACEHOLDER ((id*)1)

#   define POOL_BOUNDARY nil

    // SIZE-sizeof(*this) bytes of contents follow

    static void * operator new(size_t size) {
        return malloc_zone_memalign(malloc_default_zone(), SIZE, SIZE);
    }
    static void operator delete(void * p) {
        return free(p);
    }

    inline void protect() {
#if PROTECT_AUTORELEASEPOOL
        mprotect(this, SIZE, PROT_READ);
        check();
#endif
    }

    inline void unprotect() {
#if PROTECT_AUTORELEASEPOOL
        check();
        mprotect(this, SIZE, PROT_READ | PROT_WRITE);
#endif
    }

    AutoreleasePoolPage(AutoreleasePoolPage *newParent) :
        AutoreleasePoolPageData(begin(),
                                pthread_self(),
                                newParent,
                                newParent ? 1+newParent->depth : 0,
                                newParent ? newParent->hiwat : 0)
    {
        if (parent) {
            parent->check();
            ASSERT(!parent->child);
            parent->unprotect();
            parent->child = this;
            parent->protect();
        }
        protect();
    }

    ~AutoreleasePoolPage()
    {
        check();
        unprotect();
        ASSERT(empty());

        // Not recursive: we don't want to blow out the stack
        // if a thread accumulates a stupendous amount of garbage
        ASSERT(!child);
    }
    
    __attribute__((noinline, cold, noreturn))
    void
    busted_die() const
    {
        //busted(_objc_fatal);
        __builtin_unreachable();
    }

    inline void
    check(bool die = true) const
    {
        if (!magic.check() || thread != pthread_self()) {
            if (die) {
                busted_die();
            } else {
                //busted(_objc_inform);
            }
        }
    }

    inline void
    fastcheck() const
    {
#if CHECK_AUTORELEASEPOOL
        check();
#else
        if (! magic.fastcheck()) {
            busted_die();
        }
#endif
    }


    id * begin() {
        return (id *) ((uint8_t *)this+sizeof(*this));
    }

    id * end() {
        return (id *) ((uint8_t *)this+SIZE);
    }

    bool empty() {
        return next == begin();
    }

    bool full() {
        return next == end();
    }

    bool lessThanHalfFull() {
        return (next - begin() < (end() - begin()) / 2);
    }

    id *add(id obj)
    {
        ASSERT(!full());
        unprotect();
        id *ret = next;  // faster than `return next-1` because of aliasing
        *next++ = obj;
        protect();
        return ret;
    }

    void releaseAll()
    {
        releaseUntil(begin());
    }

    void releaseUntil(id *stop)
    {
        // Not recursive: we don't want to blow out the stack
        // if a thread accumulates a stupendous amount of garbage
        
        while (this->next != stop) {
            // Restart from hotPage() every time, in case -release
            // autoreleased more objects
            AutoreleasePoolPage *page = hotPage();

            // fixme I think this `while` can be `if`, but I can't prove it
            while (page->empty()) {
                page = page->parent;
                setHotPage(page);
            }

            page->unprotect();
            id obj = *--page->next;
            memset((void*)page->next, SCRIBBLE, sizeof(*page->next));
            page->protect();

            if (obj != POOL_BOUNDARY) {
                //objc_release(obj); //TODO:
            }
        }

        setHotPage(this);

#if DEBUG
        // we expect any children to be completely empty
        for (AutoreleasePoolPage *page = child; page; page = page->child) {
            ASSERT(page->empty());
        }
#endif
    }

    void kill()
    {
        // Not recursive: we don't want to blow out the stack
        // if a thread accumulates a stupendous amount of garbage
        AutoreleasePoolPage *page = this;
        while (page->child) page = page->child;

        AutoreleasePoolPage *deathptr;
        do {
            deathptr = page;
            page = page->parent;
            if (page) {
                page->unprotect();
                page->child = nil;
                page->protect();
            }
            delete deathptr;
        } while (deathptr != this);
    }

    static void tls_dealloc(void *p)
    {
        if (p == (void*)EMPTY_POOL_PLACEHOLDER) {
            // No objects or pool pages to clean up here.
            return;
        }

        // reinstate TLS value while we work
        setHotPage((AutoreleasePoolPage *)p);

        if (AutoreleasePoolPage *page = coldPage()) {
            if (!page->empty()) objc_autoreleasePoolPop(page->begin());  // pop all of the pools
            page->kill();  // free all of the pages
        }
        
        // clear TLS value so TLS destruction doesn't loop
        setHotPage(nil);
    }

    static AutoreleasePoolPage *pageForPointer(const void *p)
    {
        return pageForPointer((uintptr_t)p);
    }

    static AutoreleasePoolPage *pageForPointer(uintptr_t p)
    {
        AutoreleasePoolPage *result;
        uintptr_t offset = p % SIZE;

        ASSERT(offset >= sizeof(AutoreleasePoolPage));

        result = (AutoreleasePoolPage *)(p - offset);
        result->fastcheck();

        return result;
    }


    static inline bool haveEmptyPoolPlaceholder()
    {
        id *tls = (id *)tls_get_direct(key);
        return (tls == EMPTY_POOL_PLACEHOLDER);
    }

    static inline id* setEmptyPoolPlaceholder()
    {
        ASSERT(tls_get_direct(key) == nil);
        tls_set_direct(key, (void *)EMPTY_POOL_PLACEHOLDER);
        return EMPTY_POOL_PLACEHOLDER;
    }

    static inline AutoreleasePoolPage *hotPage()
    {
        AutoreleasePoolPage *result = (AutoreleasePoolPage *)
            tls_get_direct(key);
        if ((id *)result == EMPTY_POOL_PLACEHOLDER) return nil;
        if (result) result->fastcheck();
        return result;
    }

    static inline void setHotPage(AutoreleasePoolPage *page)
    {
        if (page) page->fastcheck();
        tls_set_direct(key, (void *)page);
    }

    static inline AutoreleasePoolPage *coldPage()
    {
        AutoreleasePoolPage *result = hotPage();
        if (result) {
            while (result->parent) {
                result = result->parent;
                result->fastcheck();
            }
        }
        return result;
    }


    static inline id *autoreleaseFast(id obj)
    {
        AutoreleasePoolPage *page = hotPage();
        if (page && !page->full()) {
            return page->add(obj);
        } else if (page) {
            return autoreleaseFullPage(obj, page);
        } else {
            return autoreleaseNoPage(obj);
        }
    }

    static __attribute__((noinline))
    id *autoreleaseFullPage(id obj, AutoreleasePoolPage *page)
    {
        // The hot page is full.
        // Step to the next non-full page, adding a new page if necessary.
        // Then add the object to that page.
        ASSERT(page == hotPage());
        ASSERT(page->full());

        do {
            if (page->child) page = page->child;
            else page = new AutoreleasePoolPage(page);
        } while (page->full());

        setHotPage(page);
        return page->add(obj);
    }

    static __attribute__((noinline))
    id *autoreleaseNoPage(id obj)
    {
        // "No page" could mean no pool has been pushed
        // or an empty placeholder pool has been pushed and has no contents yet
        ASSERT(!hotPage());

        bool pushExtraBoundary = false;
        if (haveEmptyPoolPlaceholder()) {
            // We are pushing a second pool over the empty placeholder pool
            // or pushing the first object into the empty placeholder pool.
            // Before doing that, push a pool boundary on behalf of the pool
            // that is currently represented by the empty placeholder.
            pushExtraBoundary = true;
        }
        else if (obj == POOL_BOUNDARY) {
            // We are pushing a pool with no pool in place,
            // and alloc-per-pool debugging was not requested.
            // Install and return the empty pool placeholder.
            return setEmptyPoolPlaceholder();
        }

        // We are pushing an object or a non-placeholder'd pool.

        // Install the first page.
        AutoreleasePoolPage *page = new AutoreleasePoolPage(nil);
        setHotPage(page);
        
        // Push a boundary on behalf of the previously-placeholder'd pool.
        if (pushExtraBoundary) {
            page->add(POOL_BOUNDARY);
        }
        
        // Push the requested object or pool.
        return page->add(obj);
    }


    static __attribute__((noinline))
    id *autoreleaseNewPage(id obj)
    {
        AutoreleasePoolPage *page = hotPage();
        if (page) return autoreleaseFullPage(obj, page);
        else return autoreleaseNoPage(obj);
    }

public:
    static inline id autorelease(id obj)
    {
        ASSERT(obj);
        //ASSERT(!obj->isTaggedPointer());
        id *dest __unused = autoreleaseFast(obj);
        ASSERT(!dest  ||  dest == EMPTY_POOL_PLACEHOLDER  ||  *dest == obj);
        return obj;
    }


    static inline void *push()
    {
        id *dest = autoreleaseFast(POOL_BOUNDARY);
        
        ASSERT(dest == EMPTY_POOL_PLACEHOLDER || *dest == POOL_BOUNDARY);
        return dest;
    }

    __attribute__((noinline, cold))
    static void badPop(void *token)
    {
        // Error. For bincompat purposes this is not
        // fatal in executables built with old SDKs.
    }

    static void
    popPage(void *token, AutoreleasePoolPage *page, id *stop)
    {
        page->releaseUntil(stop);

        // memory: delete empty children
        if (page->child) {
            // hysteresis: keep one empty child if page is more than half full
            if (page->lessThanHalfFull()) {
                page->child->kill();
            }
            else if (page->child->child) {
                page->child->child->kill();
            }
        }
    }

    __attribute__((noinline, cold))
    static void
    popPageDebug(void *token, AutoreleasePoolPage *page, id *stop)
    {
        popPage(token, page, stop);
    }

    static inline void
    pop(void *token)
    {
        AutoreleasePoolPage *page;
        id *stop;
        if (token == (void*)EMPTY_POOL_PLACEHOLDER) {
            // Popping the top-level placeholder pool.
            page = hotPage();
            if (!page) {
                // Pool was never used. Clear the placeholder.
                return setHotPage(nil);
            }
            // Pool was used. Pop its contents normally.
            // Pool pages remain allocated for re-use as usual.
            page = coldPage();
            token = page->begin();
        } else {
            page = pageForPointer(token);
        }

        stop = (id *)token;
        if (*stop != POOL_BOUNDARY) {
            if (stop == page->begin()  &&  !page->parent) {
                // Start of coldest page may correctly not be POOL_BOUNDARY:
                // 1. top-level pool is popped, leaving the cold page in place
                // 2. an object is autoreleased with no pool
            } else {
                // Error. For bincompat purposes this is not
                // fatal in executables built with old SDKs.
                return badPop(token);
            }
        }

        return popPage(token, page, stop);
    }
//
//    static void init()
//    {
//        int r __unused = pthread_key_init_np(AutoreleasePoolPage::key,
//                                             AutoreleasePoolPage::tls_dealloc);
//        ASSERT(r == 0);
//    }

//    __attribute__((noinline, cold))
//    void print()
//    {
//        _objc_inform("[%p]  ................  PAGE %s %s %s", this,
//                     full() ? "(full)" : "",
//                     this == hotPage() ? "(hot)" : "",
//                     this == coldPage() ? "(cold)" : "");
//        check(false);
//        for (id *p = begin(); p < next; p++) {
//            if (*p == POOL_BOUNDARY) {
//                _objc_inform("[%p]  ################  POOL %p", p, p);
//            } else {
//                _objc_inform("[%p]  %#16lx  %s",
//                             p, (unsigned long)*p, object_getClassName(*p));
//            }
//        }
//    }
//
//    __attribute__((noinline, cold))
//    static void printAll()
//    {
//        _objc_inform("##############");
//        _objc_inform("AUTORELEASE POOLS for thread %p", pthread_self());
//
//        AutoreleasePoolPage *page;
//        ptrdiff_t objects = 0;
//        for (page = coldPage(); page; page = page->child) {
//            objects += page->next - page->begin();
//        }
//        _objc_inform("%llu releases pending.", (unsigned long long)objects);
//
//        if (haveEmptyPoolPlaceholder()) {
//            _objc_inform("[%p]  ................  PAGE (placeholder)",
//                         EMPTY_POOL_PLACEHOLDER);
//            _objc_inform("[%p]  ################  POOL (placeholder)",
//                         EMPTY_POOL_PLACEHOLDER);
//        }
//        else {
//            for (page = coldPage(); page; page = page->child) {
//                page->print();
//            }
//        }
//
//        _objc_inform("##############");
//    }

#undef POOL_BOUNDARY
};

void *
objc_autoreleasePoolPush(void)
{
    return AutoreleasePoolPage::push();
}

void
objc_autoreleasePoolPop(void *ctxt)
{
    AutoreleasePoolPage::pop(ctxt);
}
